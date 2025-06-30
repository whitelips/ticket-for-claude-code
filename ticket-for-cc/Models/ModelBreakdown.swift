//
//  ModelBreakdown.swift
//  ticket-for-cc
//
//  Model for per-model usage statistics
//

import Foundation

/// Breakdown of usage statistics by model
struct ModelBreakdown: Identifiable, Equatable {
    let modelName: String
    let inputTokens: Int
    let outputTokens: Int
    let cacheCreationTokens: Int
    let cacheReadTokens: Int
    let cost: Double
    
    var id: String { modelName }
    
    /// Total tokens across all types
    var totalTokens: Int {
        inputTokens + outputTokens + cacheCreationTokens + cacheReadTokens
    }
    
    /// Formatted model name for display
    var displayName: String {
        // Extract model type from name like "claude-sonnet-4-20250514"
        let components = modelName.split(separator: "-")
        if components.count >= 2 {
            let modelType = components[1]
            return modelType.capitalized
        }
        return modelName
    }
    
    /// Create breakdown from array of usage entries
    static func from(entries: [UsageEntry], for model: String) -> ModelBreakdown {
        let modelEntries = entries.filter { $0.model == model }
        
        var inputTokens = 0
        var outputTokens = 0
        var cacheCreationTokens = 0
        var cacheReadTokens = 0
        var totalCost = 0.0
        
        for entry in modelEntries {
            // Only process entries with valid usage data
            guard let usage = entry.message.usage, usage.isValid else { continue }
            inputTokens += usage.inputTokens ?? 0
            outputTokens += usage.outputTokens ?? 0
            cacheCreationTokens += usage.cacheCreationInputTokens ?? 0
            cacheReadTokens += usage.cacheReadInputTokens ?? 0
            totalCost += entry.cost
        }
        
        return ModelBreakdown(
            modelName: model,
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            cacheCreationTokens: cacheCreationTokens,
            cacheReadTokens: cacheReadTokens,
            cost: totalCost
        )
    }
    
    /// Create breakdowns for all models in entries
    static func breakdowns(from entries: [UsageEntry]) -> [ModelBreakdown] {
        let models = Set(entries.map { $0.model })
        return models.map { model in
            ModelBreakdown.from(entries: entries, for: model)
        }.sorted { $0.totalTokens > $1.totalTokens }
    }
}