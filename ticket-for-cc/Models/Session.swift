import Foundation

struct Session: Identifiable {
    let id = UUID()
    let startTime: Date
    var entries: [UsageEntry] = []
    
    var totalInputTokens: Int {
        entries.reduce(0) { $0 + $1.inputTokens }
    }
    
    var totalOutputTokens: Int {
        entries.reduce(0) { $0 + $1.outputTokens }
    }
    
    var totalTokens: Int {
        totalInputTokens + totalOutputTokens
    }
    
    var duration: TimeInterval {
        guard let lastEntry = entries.last else { return 0 }
        return lastEntry.timestamp.timeIntervalSince(startTime)
    }
    
    var tokensPerHour: Double {
        guard duration > 0 else { return 0 }
        return Double(totalTokens) / duration * 3600
    }
}