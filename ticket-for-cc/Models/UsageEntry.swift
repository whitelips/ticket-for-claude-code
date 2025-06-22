import Foundation

struct UsageEntry: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
    let model: String
    let inputTokens: Int
    let outputTokens: Int
    let sessionId: String
    let requestId: String?
    let messageId: String?
    
    var totalTokens: Int {
        inputTokens + outputTokens
    }
    
    var cost: Double {
        ModelPricingData.calculateCost(
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            model: model
        )
    }
    
    init(timestamp: Date, model: String, inputTokens: Int, outputTokens: Int, sessionId: String = "", requestId: String? = nil, messageId: String? = nil) {
        self.timestamp = timestamp
        self.model = model
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.sessionId = sessionId
        self.requestId = requestId
        self.messageId = messageId
    }
}