import Foundation
import Combine

class ClaudeUsageService: ObservableObject {
    @Published var currentSession: Session
    @Published var dailyLimit: Int = 5_000_000
    @Published var monthlyLimit: Int = 50_000_000
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
                    self?.updateSession(with: allEntries)
                    self?.isLoading = false
                    self?.errorMessage = nil
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
        // Find today's entries
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        
        let todayEntries = entries.filter { entry in
            entry.timestamp >= startOfToday
        }
        
        if !todayEntries.isEmpty {
            currentSession = Session(startTime: todayEntries.first?.timestamp ?? startOfToday)
            currentSession.entries = todayEntries
        } else {
            // If no entries today, create empty session
            currentSession = Session(startTime: startOfToday)
        }
        
        allEntries = entries
    }
    
    var usagePercentage: Double {
        Double(currentSession.totalTokens) / Double(dailyLimit)
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