//
//  SessionBlock.swift
//  ticket-for-cc
//
//  Model for 5-hour billing session blocks
//

import Foundation

/// Represents a session block (5-hour billing period) with usage data
struct SessionBlock: Identifiable {
    let id: String // ISO string of block start time
    let startTime: Date
    let endTime: Date // startTime + 5 hours (for normal blocks) or gap end time (for gap blocks)
    let actualEndTime: Date? // Last activity in block
    let isActive: Bool
    let isGap: Bool // True if this is a gap block between sessions
    let entries: [UsageEntry]
    let tokenCounts: TokenCounts
    let costUSD: Double
    let models: [String]
    
    /// Duration of this block in hours
    var durationHours: Double {
        endTime.timeIntervalSince(startTime) / 3600
    }
    
    /// Elapsed time from start to last activity (or current time if active)
    var elapsedMinutes: Double {
        let referenceTime = isActive ? Date() : (actualEndTime ?? endTime)
        return referenceTime.timeIntervalSince(startTime) / 60
    }
    
    /// Calculate burn rate for this session
    var burnRate: BurnRate? {
        guard elapsedMinutes > 0, !isGap else { return nil }
        
        return BurnRate(
            tokensPerMinute: Double(tokenCounts.totalTokens) / elapsedMinutes,
            costPerHour: (costUSD / elapsedMinutes) * 60
        )
    }
    
    /// Project usage for remaining time in session
    var projectedUsage: ProjectedUsage? {
        guard isActive, let rate = burnRate else { return nil }
        
        let remainingMinutes = max(0, (5 * 60) - elapsedMinutes)
        let projectedTokens = Int(rate.tokensPerMinute * remainingMinutes)
        let projectedCost = (rate.costPerHour / 60) * remainingMinutes
        
        return ProjectedUsage(
            totalTokens: tokenCounts.totalTokens + projectedTokens,
            totalCost: costUSD + projectedCost,
            remainingMinutes: remainingMinutes
        )
    }
    
    // MARK: - Backward Compatibility Properties
    
    /// Duration in seconds for backward compatibility
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    /// Total tokens for backward compatibility
    var totalTokens: Int {
        tokenCounts.totalTokens
    }
    
    /// Total cost for backward compatibility
    var totalCost: Double {
        costUSD
    }
    
    /// Billing block start for backward compatibility (same as startTime floored to hour)
    var billingBlockStart: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: startTime)
        return calendar.date(from: components) ?? startTime
    }
}

/// Aggregated token counts for different token types
struct TokenCounts: Codable {
    let inputTokens: Int
    let outputTokens: Int
    let cacheCreationInputTokens: Int
    let cacheReadInputTokens: Int
    
    var totalTokens: Int {
        inputTokens + outputTokens + cacheCreationInputTokens + cacheReadInputTokens
    }
    
    static func zero() -> TokenCounts {
        TokenCounts(inputTokens: 0, outputTokens: 0, cacheCreationInputTokens: 0, cacheReadInputTokens: 0)
    }
    
    static func from(entries: [UsageEntry]) -> TokenCounts {
        var input = 0
        var output = 0
        var cacheCreation = 0
        var cacheRead = 0
        
        for entry in entries {
            // Only process entries with valid usage data
            guard let usage = entry.message.usage, usage.isValid else { continue }
            input += usage.inputTokens ?? 0
            output += usage.outputTokens ?? 0
            cacheCreation += usage.cacheCreationInputTokens ?? 0
            cacheRead += usage.cacheReadInputTokens ?? 0
        }
        
        return TokenCounts(
            inputTokens: input,
            outputTokens: output,
            cacheCreationInputTokens: cacheCreation,
            cacheReadInputTokens: cacheRead
        )
    }
}