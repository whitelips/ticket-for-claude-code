import Foundation

struct ModelPricing {
    let inputTokenCost: Double  // Cost per million input tokens
    let outputTokenCost: Double // Cost per million output tokens
}

struct ModelPricingData {
    static let pricing: [String: ModelPricing] = [
        // Claude 3.5 Sonnet
        "claude-3-5-sonnet-20241022": ModelPricing(inputTokenCost: 3.0, outputTokenCost: 15.0),
        "claude-sonnet-4-20250514": ModelPricing(inputTokenCost: 3.0, outputTokenCost: 15.0),
        
        // Claude 3.5 Haiku
        "claude-3-5-haiku-20241022": ModelPricing(inputTokenCost: 0.8, outputTokenCost: 4.0),
        "claude-haiku-4-20250514": ModelPricing(inputTokenCost: 0.8, outputTokenCost: 4.0),
        
        // Claude 3 Opus
        "claude-3-opus-20240229": ModelPricing(inputTokenCost: 15.0, outputTokenCost: 75.0),
        "claude-opus-4-20250514": ModelPricing(inputTokenCost: 15.0, outputTokenCost: 75.0),
        
        // Default fallback (Sonnet pricing)
        "default": ModelPricing(inputTokenCost: 3.0, outputTokenCost: 15.0)
    ]
    
    static func getCost(for model: String) -> ModelPricing {
        return pricing[model] ?? pricing["default"]!
    }
    
    static func calculateCost(inputTokens: Int, outputTokens: Int, model: String) -> Double {
        let pricing = getCost(for: model)
        let inputCost = (Double(inputTokens) / 1_000_000.0) * pricing.inputTokenCost
        let outputCost = (Double(outputTokens) / 1_000_000.0) * pricing.outputTokenCost
        return inputCost + outputCost
    }
}