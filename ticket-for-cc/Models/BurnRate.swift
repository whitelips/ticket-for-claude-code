//
//  BurnRate.swift
//  ticket-for-cc
//
//  Model for token usage burn rate calculations
//

import Foundation

/// Represents usage burn rate calculations
struct BurnRate: Equatable {
    let tokensPerMinute: Double
    let costPerHour: Double
    
    /// Tokens per hour
    var tokensPerHour: Int {
        Int(tokensPerMinute * 60)
    }
    
    /// Cost per minute
    var costPerMinute: Double {
        costPerHour / 60
    }
    
    /// Format burn rate for display
    var formattedTokensPerHour: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: tokensPerHour)) ?? "0"
    }
    
    var formattedCostPerHour: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: costPerHour)) ?? "$0.00"
    }
}

/// Represents projected usage for remaining time
struct ProjectedUsage: Equatable {
    let totalTokens: Int
    let totalCost: Double
    let remainingMinutes: Double
    
    /// Remaining time formatted as string
    var formattedRemainingTime: String {
        let hours = Int(remainingMinutes / 60)
        let minutes = Int(remainingMinutes.truncatingRemainder(dividingBy: 60))
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var formattedTotalCost: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: totalCost)) ?? "$0.00"
    }
}