import Foundation

// UsageEntry model optimized for real Claude Code data from ~/.claude/projects/**/*.jsonl
struct UsageEntry: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
    let model: String
    let inputTokens: Int
    let outputTokens: Int
    let cacheCreationInputTokens: Int?
    let cacheReadInputTokens: Int?
    let sessionId: String
    let requestId: String?
    let messageId: String?
    let uuid: String?
    let parentUuid: String?
    let version: String?
    let cwd: String?
    
    var totalTokens: Int {
        let baseTokens = inputTokens + outputTokens
        let cacheTokens = (cacheCreationInputTokens ?? 0) + (cacheReadInputTokens ?? 0)
        return baseTokens + cacheTokens
    }
    
    var effectiveInputTokens: Int {
        inputTokens + (cacheCreationInputTokens ?? 0) + (cacheReadInputTokens ?? 0)
    }
    
    var cost: Double {
        ModelPricingData.calculateCost(
            inputTokens: effectiveInputTokens,
            outputTokens: outputTokens,
            model: model
        )
    }
    
    init(
        timestamp: Date,
        model: String,
        inputTokens: Int,
        outputTokens: Int,
        sessionId: String = "",
        requestId: String? = nil,
        messageId: String? = nil,
        cacheCreationInputTokens: Int? = nil,
        cacheReadInputTokens: Int? = nil,
        uuid: String? = nil,
        parentUuid: String? = nil,
        version: String? = nil,
        cwd: String? = nil
    ) {
        self.timestamp = timestamp
        self.model = model
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.cacheCreationInputTokens = cacheCreationInputTokens
        self.cacheReadInputTokens = cacheReadInputTokens
        self.sessionId = sessionId
        self.requestId = requestId
        self.messageId = messageId
        self.uuid = uuid
        self.parentUuid = parentUuid
        self.version = version
        self.cwd = cwd
    }
}