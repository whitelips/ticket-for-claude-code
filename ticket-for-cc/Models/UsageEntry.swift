import Foundation

struct UsageEntry: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
    let model: String
    let inputTokens: Int
    let outputTokens: Int
    
    var totalTokens: Int {
        inputTokens + outputTokens
    }
}