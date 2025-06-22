import Foundation

class MockDataService: ObservableObject {
    @Published var currentSession: Session
    @Published var dailyLimit: Int = 5_000_000
    @Published var monthlyLimit: Int = 50_000_000
    
    private var timer: Timer?
    
    init() {
        self.currentSession = Session(startTime: Date())
        startMockDataGeneration()
    }
    
    private func startMockDataGeneration() {
        // Generate initial data
        generateMockEntry()
        
        // Generate new data every 3 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            self.generateMockEntry()
        }
    }
    
    private func generateMockEntry() {
        let models = ["claude-3-5-sonnet-20241022", "claude-3-5-haiku-20241022"]
        let entry = UsageEntry(
            timestamp: Date(),
            model: models.randomElement()!,
            inputTokens: Int.random(in: 100...5000),
            outputTokens: Int.random(in: 500...10000)
        )
        currentSession.entries.append(entry)
    }
    
    var usagePercentage: Double {
        Double(currentSession.totalTokens) / Double(dailyLimit)
    }
    
    var estimatedTimeToLimit: String {
        guard currentSession.tokensPerHour > 0 else { return "N/A" }
        let remainingTokens = dailyLimit - currentSession.totalTokens
        let hoursRemaining = Double(remainingTokens) / currentSession.tokensPerHour
        
        if hoursRemaining < 1 {
            let minutes = Int(hoursRemaining * 60)
            return "\(minutes) minutes"
        } else {
            return String(format: "%.1f hours", hoursRemaining)
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}