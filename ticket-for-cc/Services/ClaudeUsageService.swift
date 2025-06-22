import Foundation
import Combine

class ClaudeUsageService: ObservableObject {
    @Published var currentSession: Session
    @Published var analytics = UsageAnalyticsService()
    @Published var dailyLimit: Int = 5_000_000
    @Published var monthlyLimit: Int = 50_000_000
    @Published var dailyCostLimit: Double = 150.0  // $150/day limit
    @Published var monthlyCostLimit: Double = 3000.0  // $3000/month limit
    @Published var isLoading: Bool = true
    @Published var errorMessage: String?
    
    private let fileMonitor = FileMonitor()
    private var refreshTimer: Timer?
    private var allEntries: [UsageEntry] = []
    
    init() {
        self.currentSession = Session(startTime: Date())
        setupFileMonitor()
        loadData()
        startPeriodicRefresh()
    }
    
    private func setupFileMonitor() {
        fileMonitor.delegate = self
        fileMonitor.startMonitoring()
    }
    
    private func startPeriodicRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            self.loadData()
        }
    }
    
    private func loadData() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            do {
                var allEntries: [UsageEntry] = []
                let jsonlFiles = DataParser.getAllJSONLFiles()
                
                for fileURL in jsonlFiles {
                    let entries = try DataParser.parseJSONLFile(at: fileURL)
                    allEntries.append(contentsOf: entries)
                }
                
                // Sort all entries by timestamp
                allEntries.sort { $0.timestamp < $1.timestamp }
                
                DispatchQueue.main.async {
                    if allEntries.isEmpty && jsonlFiles.isEmpty {
                        self?.errorMessage = """
                        No Claude usage data found.
                        
                        Please use Claude Code to start a conversation first.
                        The app reads usage data from ~/.claude/projects/
                        
                        Make sure you have recent Claude Code sessions.
                        """
                    } else if allEntries.isEmpty && !jsonlFiles.isEmpty {
                        self?.errorMessage = """
                        Found \(jsonlFiles.count) JSONL files but no valid usage data.
                        
                        This might be because:
                        • No recent assistant responses with usage data
                        • Data format has changed
                        • All entries are from user messages only
                        
                        Try having a conversation with Claude Code first.
                        """
                    } else {
                        print("📊 Loaded \(allEntries.count) usage entries from \(jsonlFiles.count) files")
                        if let mostRecent = allEntries.last {
                            print("📅 Most recent entry: \(mostRecent.timestamp)")
                        }
                        self?.updateSession(with: allEntries)
                        self?.analytics.analyzeUsageData(allEntries)
                        self?.errorMessage = nil
                    }
                    self?.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self?.errorMessage = "Failed to load usage data: \(error.localizedDescription)"
                    self?.isLoading = false
                }
            }
        }
    }
    
    private func updateSession(with entries: [UsageEntry]) {
        guard !entries.isEmpty else {
            currentSession = Session(startTime: Date())
            allEntries = []
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Try to find today's entries first
        let startOfToday = calendar.startOfDay(for: now)
        let todayEntries = entries.filter { entry in
            entry.timestamp >= startOfToday
        }
        
        if !todayEntries.isEmpty {
            // Use today's data
            currentSession = Session(startTime: todayEntries.first?.timestamp ?? startOfToday)
            currentSession.entries = todayEntries
        } else {
            // No entries today, use the most recent session (last 7 days)
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            let recentEntries = entries.filter { entry in
                entry.timestamp >= weekAgo
            }
            
            if !recentEntries.isEmpty {
                // Use most recent day's data
                let mostRecentDate = recentEntries.map(\.timestamp).max() ?? now
                let mostRecentDay = calendar.startOfDay(for: mostRecentDate)
                let dayEntries = recentEntries.filter { entry in
                    calendar.isDate(entry.timestamp, inSameDayAs: mostRecentDay)
                }
                
                currentSession = Session(startTime: dayEntries.first?.timestamp ?? mostRecentDay)
                currentSession.entries = dayEntries
            } else {
                // No recent entries, create empty session
                currentSession = Session(startTime: startOfToday)
            }
        }
        
        allEntries = entries
    }
    
    var usagePercentage: Double {
        Double(currentSession.totalTokens) / Double(dailyLimit)
    }
    
    var dailyCostPercentage: Double {
        guard let todayUsage = analytics.todayUsage else { return 0.0 }
        return todayUsage.totalCost / dailyCostLimit
    }
    
    var monthlyCostPercentage: Double {
        guard let monthUsage = analytics.currentMonthUsage else { return 0.0 }
        return monthUsage.totalCost / monthlyCostLimit
    }
    
    var todayTotalCost: Double {
        analytics.todayUsage?.totalCost ?? 0.0
    }
    
    var monthTotalCost: Double {
        analytics.currentMonthUsage?.totalCost ?? 0.0
    }
    
    var estimatedTimeToLimit: String {
        guard currentSession.tokensPerHour > 0 else { return "N/A" }
        let remainingTokens = dailyLimit - currentSession.totalTokens
        guard remainingTokens > 0 else { return "Limit reached" }
        
        let hoursRemaining = Double(remainingTokens) / currentSession.tokensPerHour
        
        if hoursRemaining < 1 {
            let minutes = Int(hoursRemaining * 60)
            return "\(minutes) minutes"
        } else if hoursRemaining > 24 {
            return "> 24 hours"
        } else {
            return String(format: "%.1f hours", hoursRemaining)
        }
    }
    
    deinit {
        refreshTimer?.invalidate()
        fileMonitor.stopMonitoring()
    }
}

extension ClaudeUsageService: FileMonitorDelegate {
    func fileMonitorDidDetectChange() {
        loadData()
    }
}