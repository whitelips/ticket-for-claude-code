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
    private var hasLoadedInitialData = false
    
    // Computed property for active session block
    var activeSessionBlock: SessionBlock? {
        analytics.sessionBlocks.first { $0.isActive }
    }
    
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
        // Only show loading indicator for initial load, not periodic refreshes
        if !hasLoadedInitialData {
            isLoading = true
        }
        
        Task {
            await loadDataAsync()
        }
    }
    
    private func loadDataAsync() async {
        do {
            // Create DataParser instance
            let parser = DataParser()
            
            // Get Claude paths and load all usage data
            let paths = parser.getClaudePaths()
            var allEntries = try await parser.loadAllUsageData(from: paths)
            
            // Sort entries by timestamp
            allEntries.sort { $0.timestamp < $1.timestamp }
            
            // Create local copies for use in MainActor block
            let entriesCount = allEntries.count
            let pathsCount = paths.count
            let mostRecentTimestamp = allEntries.last?.timestamp
        
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                
                if allEntries.isEmpty {
                    self.errorMessage = """
                    No Claude usage data found.
                    
                    Please use Claude Code to start a conversation first.
                    The app reads usage data from ~/.config/claude/ or ~/.claude/
                    
                    Make sure you have recent Claude Code sessions.
                    """
                } else {
                    print("📊 Loaded \(entriesCount) usage entries from \(pathsCount) paths")
                    if let timestamp = mostRecentTimestamp {
                        print("📅 Most recent entry: \(timestamp)")
                    }
                    self.updateSession(with: allEntries)
                    self.analytics.analyzeUsageData(allEntries)
                    self.errorMessage = nil
                }
                self.isLoading = false
                self.hasLoadedInitialData = true
            }
        } catch {
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.errorMessage = "Failed to load usage data: \(error.localizedDescription)"
                self.isLoading = false
                self.hasLoadedInitialData = true
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

extension ClaudeUsageService {
    // Public method for manual refresh (e.g., from retry button)
    func refreshData() {
        isLoading = true
        loadData()
    }
}
