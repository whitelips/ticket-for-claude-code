//
//  SessionHistoryView.swift
//  ticket-for-cc
//
//  View for displaying session history with detailed breakdown
//

import SwiftUI

struct SessionHistoryView: View {
    let blocks: [SessionBlock]
    @State private var sortOrder: SortOrder = .newestFirst
    @State private var showingGaps = false
    @State private var selectedSession: SessionBlock?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with controls
            HStack {
                Text("📋 Session History")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Toggle for showing gaps
                Toggle("Show gaps", isOn: $showingGaps)
                    .toggleStyle(SwitchToggleStyle())
                
                // Sort order picker
                Picker("Sort", selection: $sortOrder) {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Text(order.displayName).tag(order)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(minWidth: 150)
            }
            
            if filteredBlocks.isEmpty {
                EmptySessionsView()
            } else {
                // Session list
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredBlocks, id: \.id) { block in
                            SessionRowView(
                                block: block,
                                isSelected: selectedSession?.id == block.id
                            )
                            .onTapGesture {
                                selectedSession = selectedSession?.id == block.id ? nil : block
                            }
                        }
                    }
                }
                .frame(maxHeight: 400)
                
                // Summary
                SessionSummaryView(blocks: filteredBlocks.filter { !$0.isGap })
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .sheet(item: $selectedSession) { session in
            SessionDetailView(block: session)
        }
    }
    
    private var filteredBlocks: [SessionBlock] {
        let filtered = showingGaps ? blocks : blocks.filter { !$0.isGap }
        
        switch sortOrder {
        case .newestFirst:
            return filtered.sorted { $0.startTime > $1.startTime }
        case .oldestFirst:
            return filtered.sorted { $0.startTime < $1.startTime }
        case .highestUsage:
            return filtered.sorted { $0.tokenCounts.totalTokens > $1.tokenCounts.totalTokens }
        case .highestCost:
            return filtered.sorted { $0.costUSD > $1.costUSD }
        }
    }
}

// MARK: - Session Row

struct SessionRowView: View {
    let block: SessionBlock
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            // Session title and time info
            VStack(alignment: .leading, spacing: 4) {
                // Session title
                Text(sessionTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                // Time info
                HStack(spacing: 8) {
                    Text(block.startTime, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(block.startTime, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 140, alignment: .leading)
            
            // Duration
            VStack(alignment: .leading, spacing: 2) {
                if block.isGap {
                    Text("Gap")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatDuration(block.endTime.timeIntervalSince(block.startTime)))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("Duration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatDuration(block.elapsedMinutes * 60))
                        .font(.caption2)
                        .fontWeight(.medium)
                }
            }
            .frame(width: 60, alignment: .leading)
            
            // Usage info (only for non-gap blocks)
            if !block.isGap {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tokens")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(formatTokenCount(block.tokenCounts.totalTokens))")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .frame(width: 60, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Cost")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "$%.3f", block.costUSD))
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                .frame(width: 60, alignment: .leading)
                
                // Burn rate
                if let burnRate = block.burnRate {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Burn Rate")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(formatTokenCount(burnRate.tokensPerHour))/h")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                    .frame(width: 80, alignment: .leading)
                }
                
                // Models used
                VStack(alignment: .leading, spacing: 2) {
                    Text("Models")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack(spacing: 2) {
                        ForEach(Array(Set(block.models)).sorted().prefix(2), id: \.self) { model in
                            Text(modelDisplayName(model))
                                .font(.caption2)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(modelColor(model).opacity(0.2))
                                .foregroundColor(modelColor(model))
                                .cornerRadius(3)
                        }
                        if block.models.count > 2 {
                            Text("+\(block.models.count - 2)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Active indicator
            if block.isActive {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("Active")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
            
            // Expand indicator
            Image(systemName: isSelected ? "chevron.up" : "chevron.down")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
        )
    }
    
    private var statusColor: Color {
        if block.isGap {
            return .gray
        } else if block.isActive {
            return .green
        } else {
            return .blue
        }
    }
    
    private var sessionTitle: String {
        if block.isGap {
            return "Inactive Period"
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        if block.isActive {
            return "Current Session"
        }
        
        // Generate title based on time of day and activity level
        let hour = calendar.component(.hour, from: block.startTime)
        let tokenCount = block.tokenCounts.totalTokens
        
        var timeOfDay: String
        switch hour {
        case 5..<12:
            timeOfDay = "Morning"
        case 12..<17:
            timeOfDay = "Afternoon"
        case 17..<21:
            timeOfDay = "Evening"
        default:
            timeOfDay = "Night"
        }
        
        var activityLevel: String
        if tokenCount > 50000 {
            activityLevel = "Heavy"
        } else if tokenCount > 10000 {
            activityLevel = "Active"
        } else if tokenCount > 1000 {
            activityLevel = "Light"
        } else {
            activityLevel = "Brief"
        }
        
        // If it's today, just use time of day
        if calendar.isDateInToday(block.startTime) {
            return "\(timeOfDay) Session"
        }
        
        // If it's this week, include day
        let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now)
        if let weekInterval = weekInterval, weekInterval.contains(block.startTime) {
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEEE"
            let dayName = dayFormatter.string(from: block.startTime)
            return "\(dayName) \(timeOfDay)"
        }
        
        // For older sessions, include activity level
        return "\(activityLevel) Session"
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatTokenCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        } else {
            return "\(count)"
        }
    }
    
    private func modelDisplayName(_ model: String) -> String {
        let components = model.split(separator: "-")
        if components.count >= 2 {
            return String(components[1]).capitalized
        }
        return model
    }
    
    private func modelColor(_ model: String) -> Color {
        if model.contains("sonnet") {
            return .blue
        } else if model.contains("opus") {
            return .purple
        } else if model.contains("haiku") {
            return .green
        } else {
            return .gray
        }
    }
}

// MARK: - Supporting Views

struct EmptySessionsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("No sessions found")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Sessions will appear here as you use Claude Code")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
    }
}

struct SessionSummaryView: View {
    let blocks: [SessionBlock]
    
    var body: some View {
        HStack(spacing: 24) {
            SummaryItem(
                title: "Total Sessions",
                value: "\(blocks.count)",
                color: .blue
            )
            
            SummaryItem(
                title: "Total Tokens",
                value: formatTokenCount(totalTokens),
                color: .green
            )
            
            SummaryItem(
                title: "Total Cost",
                value: String(format: "$%.3f", totalCost),
                color: .orange
            )
            
            if let avgBurnRate = averageBurnRate {
                SummaryItem(
                    title: "Avg Burn Rate",
                    value: "\(formatTokenCount(avgBurnRate))/h",
                    color: .purple
                )
            }
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var totalTokens: Int {
        blocks.reduce(0) { $0 + $1.tokenCounts.totalTokens }
    }
    
    private var totalCost: Double {
        blocks.reduce(0.0) { $0 + $1.costUSD }
    }
    
    private var averageBurnRate: Int? {
        let rates = blocks.compactMap { $0.burnRate?.tokensPerHour }
        guard !rates.isEmpty else { return nil }
        return rates.reduce(0, +) / rates.count
    }
    
    private func formatTokenCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        } else {
            return "\(count)"
        }
    }
}

struct SummaryItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

// MARK: - Session Detail View

struct SessionDetailView: View {
    let block: SessionBlock
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text("Session Details")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Basic info
                    SessionInfoCard(block: block)
                    
                    // Token breakdown
                    if !block.isGap {
                        TokenBreakdownCard(block: block)
                        
                        // Model breakdown
                        ModelBreakdownCard(models: block.models)
                        
                        // Entries list
                        if !block.entries.isEmpty {
                            EntriesListCard(entries: Array(block.entries.prefix(10)))
                        }
                    }
                }
            }
        }
        .frame(width: 600, height: 500)
        .padding()
    }
}

struct SessionInfoCard: View {
    let block: SessionBlock
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Session Information")
                .font(.headline)
            
            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 8) {
                GridRow {
                    Text("Start Time:")
                        .foregroundColor(.secondary)
                    Text(block.startTime, style: .date)
                }
                
                GridRow {
                    Text("Duration:")
                        .foregroundColor(.secondary)
                    Text("\(Int(block.elapsedMinutes)) minutes")
                }
                
                GridRow {
                    Text("Status:")
                        .foregroundColor(.secondary)
                    HStack {
                        Circle()
                            .fill(block.isActive ? .green : .blue)
                            .frame(width: 8, height: 8)
                        Text(block.isActive ? "Active" : "Completed")
                    }
                }
                
                if !block.isGap {
                    GridRow {
                        Text("Total Cost:")
                            .foregroundColor(.secondary)
                        Text(String(format: "$%.4f", block.costUSD))
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct TokenBreakdownCard: View {
    let block: SessionBlock
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Token Usage")
                .font(.headline)
            
            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 8) {
                GridRow {
                    Text("Input Tokens:")
                        .foregroundColor(.secondary)
                    Text("\(block.tokenCounts.inputTokens)")
                }
                
                GridRow {
                    Text("Output Tokens:")
                        .foregroundColor(.secondary)
                    Text("\(block.tokenCounts.outputTokens)")
                }
                
                GridRow {
                    Text("Cache Creation:")
                        .foregroundColor(.secondary)
                    Text("\(block.tokenCounts.cacheCreationInputTokens)")
                }
                
                GridRow {
                    Text("Cache Read:")
                        .foregroundColor(.secondary)
                    Text("\(block.tokenCounts.cacheReadInputTokens)")
                }
                
                Divider()
                
                GridRow {
                    Text("Total:")
                        .fontWeight(.semibold)
                    Text("\(block.tokenCounts.totalTokens)")
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
}

struct ModelBreakdownCard: View {
    let models: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Models Used")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(Array(Set(models)).sorted(), id: \.self) { model in
                    HStack {
                        Circle()
                            .fill(modelColor(model))
                            .frame(width: 8, height: 8)
                        Text(model)
                            .font(.caption)
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(modelColor(model).opacity(0.1))
                    .cornerRadius(4)
                }
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func modelColor(_ model: String) -> Color {
        if model.contains("sonnet") {
            return .blue
        } else if model.contains("opus") {
            return .purple
        } else if model.contains("haiku") {
            return .green
        } else {
            return .gray
        }
    }
}

struct EntriesListCard: View {
    let entries: [UsageEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Entries (\(entries.count) shown)")
                .font(.headline)
            
            ForEach(entries, id: \.id) { entry in
                HStack {
                    Text(entry.timestamp, style: .time)
                        .font(.caption)
                        .frame(width: 60, alignment: .leading)
                    
                    Text("\(entry.totalTokens) tokens")
                        .font(.caption)
                        .frame(width: 80, alignment: .leading)
                    
                    Text(String(format: "$%.4f", entry.cost))
                        .font(.caption)
                        .foregroundColor(.green)
                        .frame(width: 60, alignment: .leading)
                    
                    Text(entry.model)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.vertical, 2)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Enums

enum SortOrder: CaseIterable {
    case newestFirst, oldestFirst, highestUsage, highestCost
    
    var displayName: String {
        switch self {
        case .newestFirst: return "Newest First"
        case .oldestFirst: return "Oldest First"
        case .highestUsage: return "Highest Usage"
        case .highestCost: return "Highest Cost"
        }
    }
}