//
//  SessionBlockManager.swift
//  ticket-for-cc
//
//  Service for managing 5-hour session blocks based on Claude's billing periods
//

import Foundation

class SessionBlockManager {
    
    /// Default session duration in hours (Claude's billing block duration)
    static let defaultSessionDurationHours = 5.0
    
    /// Identifies and creates session blocks from usage entries
    /// Groups entries into time-based blocks (5-hour periods) with gap detection
    static func identifySessionBlocks(
        from entries: [UsageEntry],
        sessionDurationHours: Double = defaultSessionDurationHours
    ) -> [SessionBlock] {
        guard !entries.isEmpty else { return [] }
        
        let sessionDurationMs = sessionDurationHours * 60 * 60 * 1000
        var blocks: [SessionBlock] = []
        let sortedEntries = entries.sorted { $0.timestamp < $1.timestamp }
        
        var currentBlockStart: Date?
        var currentBlockEntries: [UsageEntry] = []
        let now = Date()
        
        for entry in sortedEntries {
            let entryTime = entry.timestamp
            
            if let blockStart = currentBlockStart {
                let timeSinceBlockStart = entryTime.timeIntervalSince(blockStart) * 1000
                
                if let lastEntry = currentBlockEntries.last {
                    let timeSinceLastEntry = entryTime.timeIntervalSince(lastEntry.timestamp) * 1000
                    
                    if timeSinceBlockStart > sessionDurationMs || timeSinceLastEntry > sessionDurationMs {
                        // Close current block
                        let block = createBlock(
                            startTime: blockStart,
                            entries: currentBlockEntries,
                            now: now,
                            sessionDurationMs: sessionDurationMs
                        )
                        blocks.append(block)
                        
                        // Add gap block if there's a significant gap
                        if timeSinceLastEntry > sessionDurationMs {
                            if let gapBlock = createGapBlock(
                                from: lastEntry.timestamp,
                                to: entryTime,
                                sessionDurationMs: sessionDurationMs
                            ) {
                                blocks.append(gapBlock)
                            }
                        }
                        
                        // Start new block (floored to the hour)
                        currentBlockStart = floorToHour(entryTime)
                        currentBlockEntries = [entry]
                    } else {
                        // Add to current block
                        currentBlockEntries.append(entry)
                    }
                } else {
                    currentBlockEntries.append(entry)
                }
            } else {
                // First entry - start a new block (floored to the hour)
                currentBlockStart = floorToHour(entryTime)
                currentBlockEntries = [entry]
            }
        }
        
        // Close the last block
        if let blockStart = currentBlockStart, !currentBlockEntries.isEmpty {
            let block = createBlock(
                startTime: blockStart,
                entries: currentBlockEntries,
                now: now,
                sessionDurationMs: sessionDurationMs
            )
            blocks.append(block)
        }
        
        return blocks
    }
    
    /// Create a session block from entries
    private static func createBlock(
        startTime: Date,
        entries: [UsageEntry],
        now: Date,
        sessionDurationMs: Double
    ) -> SessionBlock {
        let endTime = startTime.addingTimeInterval(sessionDurationMs / 1000)
        let actualEndTime = entries.last?.timestamp
        let isActive = now.timeIntervalSince(startTime) * 1000 < sessionDurationMs &&
                      (actualEndTime.map { now.timeIntervalSince($0) < 300 } ?? false) // Active if last entry within 5 minutes
        
        let tokenCounts = TokenCounts.from(entries: entries)
        let totalCost = entries.reduce(0.0) { $0 + $1.cost }
        let models = Array(Set(entries.map { $0.model })).sorted()
        
        return SessionBlock(
            id: ISO8601DateFormatter().string(from: startTime),
            startTime: startTime,
            endTime: endTime,
            actualEndTime: actualEndTime,
            isActive: isActive,
            isGap: false,
            entries: entries,
            tokenCounts: tokenCounts,
            costUSD: totalCost,
            models: models
        )
    }
    
    /// Create a gap block between sessions
    private static func createGapBlock(
        from lastActivityTime: Date,
        to nextActivityTime: Date,
        sessionDurationMs: Double
    ) -> SessionBlock? {
        let gapDuration = nextActivityTime.timeIntervalSince(lastActivityTime) * 1000
        
        // Only create gap blocks for gaps longer than session duration
        guard gapDuration > sessionDurationMs else { return nil }
        
        // Gap starts at the end of the last session
        let gapStart = lastActivityTime.addingTimeInterval(sessionDurationMs / 1000)
        let gapEnd = nextActivityTime
        
        return SessionBlock(
            id: "gap-\(ISO8601DateFormatter().string(from: gapStart))",
            startTime: gapStart,
            endTime: gapEnd,
            actualEndTime: nil,
            isActive: false,
            isGap: true,
            entries: [],
            tokenCounts: TokenCounts.zero(),
            costUSD: 0.0,
            models: []
        )
    }
    
    /// Floor a timestamp to the beginning of the hour
    private static func floorToHour(_ timestamp: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: timestamp)
        return calendar.date(from: components) ?? timestamp
    }
    
    /// Get only recent blocks (last N days)
    static func getRecentBlocks(
        from blocks: [SessionBlock],
        days: Int = 3
    ) -> [SessionBlock] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return blocks.filter { $0.startTime >= cutoffDate }
    }
    
    /// Get the currently active block
    static func getActiveBlock(from blocks: [SessionBlock]) -> SessionBlock? {
        return blocks.first { $0.isActive }
    }
    
    /// Calculate total usage across all blocks
    static func calculateTotalUsage(from blocks: [SessionBlock]) -> (tokens: Int, cost: Double) {
        let totalTokens = blocks.reduce(0) { $0 + $1.tokenCounts.totalTokens }
        let totalCost = blocks.reduce(0.0) { $0 + $1.costUSD }
        return (tokens: totalTokens, cost: totalCost)
    }
}