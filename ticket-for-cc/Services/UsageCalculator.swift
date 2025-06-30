//
//  UsageCalculator.swift
//  ticket-for-cc
//
//  Service for calculating burn rates, projections, and usage analytics
//

import Foundation

class UsageCalculator {
    
    /// Calculate burn rate from a collection of usage entries
    static func calculateBurnRate(from entries: [UsageEntry], over timeInterval: TimeInterval? = nil) -> BurnRate? {
        guard !entries.isEmpty else { return nil }
        
        // Sort entries by timestamp
        let sortedEntries = entries.sorted { $0.timestamp < $1.timestamp }
        
        // Calculate time interval
        let interval: TimeInterval
        if let providedInterval = timeInterval {
            interval = providedInterval
        } else {
            // Use time from first to last entry
            guard let firstEntry = sortedEntries.first,
                  let lastEntry = sortedEntries.last,
                  firstEntry.timestamp != lastEntry.timestamp else {
                return nil
            }
            interval = lastEntry.timestamp.timeIntervalSince(firstEntry.timestamp)
        }
        
        // Ensure we have a meaningful time interval (at least 1 minute)
        guard interval >= 60 else { return nil }
        
        // Calculate total tokens and cost
        let totalTokens = entries.reduce(0) { $0 + $1.totalTokens }
        let totalCost = entries.reduce(0.0) { $0 + $1.cost }
        
        // Calculate rates
        let minutesElapsed = interval / 60.0
        let tokensPerMinute = Double(totalTokens) / minutesElapsed
        let costPerHour = (totalCost / minutesElapsed) * 60.0
        
        return BurnRate(
            tokensPerMinute: tokensPerMinute,
            costPerHour: costPerHour
        )
    }
    
    /// Calculate projected usage based on current burn rate
    static func calculateProjectedUsage(
        currentTokens: Int,
        currentCost: Double,
        burnRate: BurnRate,
        remainingMinutes: Double
    ) -> ProjectedUsage {
        let projectedTokens = Int(burnRate.tokensPerMinute * remainingMinutes)
        let projectedCost = burnRate.costPerMinute * remainingMinutes
        
        return ProjectedUsage(
            totalTokens: currentTokens + projectedTokens,
            totalCost: currentCost + projectedCost,
            remainingMinutes: remainingMinutes
        )
    }
    
    /// Calculate daily usage statistics
    static func calculateDailyUsage(from entries: [UsageEntry]) -> [Date: DailyUsageStats] {
        var dailyStats: [Date: DailyUsageStats] = [:]
        
        // Create calendar for date operations
        let calendar = Calendar.current
        
        for entry in entries {
            // Get start of day for grouping
            let dayStart = calendar.startOfDay(for: entry.timestamp)
            
            // Initialize or update daily stats
            if var stats = dailyStats[dayStart] {
                stats.totalTokens += entry.totalTokens
                stats.totalCost += entry.cost
                stats.entryCount += 1
                stats.models.insert(entry.model)
                dailyStats[dayStart] = stats
            } else {
                dailyStats[dayStart] = DailyUsageStats(
                    date: dayStart,
                    totalTokens: entry.totalTokens,
                    totalCost: entry.cost,
                    entryCount: 1,
                    models: Set([entry.model])
                )
            }
        }
        
        return dailyStats
    }
    
    /// Calculate monthly usage statistics
    static func calculateMonthlyUsage(from entries: [UsageEntry]) -> [MonthKey: MonthlyUsageStats] {
        var monthlyStats: [MonthKey: MonthlyUsageStats] = [:]
        
        let calendar = Calendar.current
        
        for entry in entries {
            let components = calendar.dateComponents([.year, .month], from: entry.timestamp)
            guard let year = components.year,
                  let month = components.month else { continue }
            
            let monthKey = MonthKey(year: year, month: month)
            
            if var stats = monthlyStats[monthKey] {
                stats.totalTokens += entry.totalTokens
                stats.totalCost += entry.cost
                stats.entryCount += 1
                stats.models.insert(entry.model)
                monthlyStats[monthKey] = stats
            } else {
                monthlyStats[monthKey] = MonthlyUsageStats(
                    year: year,
                    month: month,
                    totalTokens: entry.totalTokens,
                    totalCost: entry.cost,
                    entryCount: 1,
                    models: Set([entry.model])
                )
            }
        }
        
        return monthlyStats
    }
    
    /// Calculate usage progress against limits
    static func calculateUsageProgress(
        currentTokens: Int,
        tokenLimit: Int
    ) -> UsageProgress {
        let percentage = tokenLimit > 0 ? Double(currentTokens) / Double(tokenLimit) : 0.0
        let remainingTokens = max(0, tokenLimit - currentTokens)
        
        return UsageProgress(
            currentTokens: currentTokens,
            tokenLimit: tokenLimit,
            percentage: percentage,
            remainingTokens: remainingTokens,
            isNearLimit: percentage >= 0.8,
            isOverLimit: currentTokens >= tokenLimit
        )
    }
}

// MARK: - Supporting Types

struct DailyUsageStats {
    let date: Date
    var totalTokens: Int
    var totalCost: Double
    var entryCount: Int
    var models: Set<String>
}

struct MonthlyUsageStats {
    let year: Int
    let month: Int
    var totalTokens: Int
    var totalCost: Double
    var entryCount: Int
    var models: Set<String>
    
    var displayName: String {
        let dateComponents = DateComponents(year: year, month: month)
        if let date = Calendar.current.date(from: dateComponents) {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: date)
        }
        return "\(month)/\(year)"
    }
}

struct MonthKey: Hashable {
    let year: Int
    let month: Int
}

struct UsageProgress {
    let currentTokens: Int
    let tokenLimit: Int
    let percentage: Double
    let remainingTokens: Int
    let isNearLimit: Bool
    let isOverLimit: Bool
    
    var progressColor: String {
        if isOverLimit {
            return "red"
        } else if isNearLimit {
            return "orange"
        } else {
            return "green"
        }
    }
}