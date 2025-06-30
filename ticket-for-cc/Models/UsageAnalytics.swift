import Foundation

struct DailyUsage: Identifiable {
    let id = UUID()
    let date: Date
    var entries: [UsageEntry] = []
    
    var totalInputTokens: Int { entries.reduce(0) { $0 + $1.inputTokens } }
    var totalOutputTokens: Int { entries.reduce(0) { $0 + $1.outputTokens } }
    var totalTokens: Int { totalInputTokens + totalOutputTokens }
    var totalCost: Double { 
        entries.reduce(0.0) { total, entry in
            total + ModelPricingData.calculateCost(
                inputTokens: entry.inputTokens,
                outputTokens: entry.outputTokens,
                model: entry.model
            )
        }
    }
    
    var modelBreakdown: [String: ModelUsage] {
        var breakdown: [String: ModelUsage] = [:]
        
        for entry in entries {
            if breakdown[entry.model] == nil {
                breakdown[entry.model] = ModelUsage(model: entry.model)
            }
            breakdown[entry.model]?.addEntry(entry)
        }
        
        return breakdown
    }
}

struct MonthlyUsage: Identifiable {
    let id = UUID()
    let month: Date
    var dailyUsages: [DailyUsage] = []
    
    var totalInputTokens: Int { dailyUsages.reduce(0) { $0 + $1.totalInputTokens } }
    var totalOutputTokens: Int { dailyUsages.reduce(0) { $0 + $1.totalOutputTokens } }
    var totalTokens: Int { totalInputTokens + totalOutputTokens }
    var totalCost: Double { dailyUsages.reduce(0.0) { $0 + $1.totalCost } }
    
    var averageDailyCost: Double {
        guard !dailyUsages.isEmpty else { return 0.0 }
        return totalCost / Double(dailyUsages.count)
    }
}

struct ModelUsage {
    let model: String
    var inputTokens: Int = 0
    var outputTokens: Int = 0
    var requestCount: Int = 0
    
    var totalTokens: Int { inputTokens + outputTokens }
    var cost: Double { 
        ModelPricingData.calculateCost(
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            model: model
        )
    }
    
    mutating func addEntry(_ entry: UsageEntry) {
        inputTokens += entry.inputTokens
        outputTokens += entry.outputTokens
        requestCount += 1
    }
}

// SessionBlock is now defined in Models/SessionBlock.swift