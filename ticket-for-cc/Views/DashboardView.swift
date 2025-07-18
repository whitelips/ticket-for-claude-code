//
//  DashboardView.swift
//  ticket-for-cc
//
//  Main dashboard view showing Claude usage overview
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var usageService = ClaudeUsageService()
    @State private var selectedTimeframe: TimeFrame = .today
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with timeframe selector
            HeaderView(selectedTimeframe: $selectedTimeframe)
            
            if usageService.isLoading {
                LoadingView()
            } else if usageService.analytics.sessionBlocks.isEmpty {
                EmptyStateView()
            } else {
                // Main content
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Current session overview
                        if let activeBlock = usageService.activeSessionBlock {
                            ActiveSessionOverview(block: activeBlock)
                        }
                        
                        // Usage statistics cards
                        UsageStatisticsGrid(
                            blocks: filteredBlocks,
                            timeframe: selectedTimeframe
                        )
                        
                        // Burn rate chart
                        if !filteredBlocks.isEmpty {
                            BurnRateChartView(blocks: filteredBlocks)
                                .frame(height: 350)
                        }
                        
                        // Session history
                        SessionHistoryView(blocks: filteredBlocks)
                    }
                    .padding()
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { usageService.refreshData() }) {
                    Image(systemName: "arrow.clockwise")
                }
                
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gear")
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
        .onAppear {
            // Monitoring starts automatically in ClaudeUsageService init
        }
        .sheet(isPresented: $showingSettings) {
            AppSettingsView()
        }
    }
    
    private var filteredBlocks: [SessionBlock] {
        let now = Date()
        
        let filtered: [SessionBlock]
        switch selectedTimeframe {
        case .today:
            // Use UTC calendar for consistent comparison since session blocks use UTC
            var utcCalendar = Calendar.current
            utcCalendar.timeZone = TimeZone(identifier: "UTC")!
            let startOfDayUTC = utcCalendar.startOfDay(for: now)
            filtered = usageService.analytics.sessionBlocks.filter { $0.startTime >= startOfDayUTC }
        case .thisWeek:
            var utcCalendar = Calendar.current
            utcCalendar.timeZone = TimeZone(identifier: "UTC")!
            let startOfWeek = utcCalendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            filtered = usageService.analytics.sessionBlocks.filter { $0.startTime >= startOfWeek }
        case .thisMonth:
            var utcCalendar = Calendar.current
            utcCalendar.timeZone = TimeZone(identifier: "UTC")!
            let startOfMonth = utcCalendar.dateInterval(of: .month, for: now)?.start ?? now
            filtered = usageService.analytics.sessionBlocks.filter { $0.startTime >= startOfMonth }
        case .all:
            filtered = usageService.analytics.sessionBlocks
        }
        
        return filtered
    }
}

// MARK: - Supporting Views

struct HeaderView: View {
    @Binding var selectedTimeframe: TimeFrame
    
    var body: some View {
        HStack {
            Text("🎫 Ticket for Claude Code")
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            Picker("Timeframe", selection: $selectedTimeframe) {
                ForEach(TimeFrame.allCases, id: \.self) { timeframe in
                    Text(timeframe.displayName).tag(timeframe)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 320)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading Claude usage data...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No Claude usage data found")
                .font(.title)
                .fontWeight(.medium)
            
            Text("Make sure Claude Code is installed and has been used.\nUsage data should be available in ~/.config/claude/ or ~/.claude/")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
            
            Button("Refresh") {
                // Trigger refresh
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct ActiveSessionOverview: View {
    let block: SessionBlock
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("🟢 Active Session")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                Spacer()
                
                Text("Started \(block.startTime, style: .time)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 32) {
                // Current tokens
                VStack(alignment: .leading) {
                    Text("\(block.tokenCounts.totalTokens)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("total tokens")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Burn rate
                if let burnRate = block.burnRate {
                    VStack(alignment: .leading) {
                        Text(burnRate.formattedTokensPerHour)
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        Text("tokens/hour")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Cost
                VStack(alignment: .leading) {
                    Text(String(format: "$%.4f", block.costUSD))
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    Text("current cost")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Progress bar for session (5 hours)
            let progress = min(1.0, block.elapsedMinutes / (5 * 60))
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Session Progress")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(block.elapsedMinutes))m / 300m")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle())
            }
            
            // Projected usage
            if let projected = block.projectedUsage {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.blue)
                    Text("Projected total: \(projected.totalTokens) tokens (\(projected.formattedTotalCost)) in \(projected.formattedRemainingTime)")
                        .font(.callout)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
}

struct UsageStatisticsGrid: View {
    let blocks: [SessionBlock]
    let timeframe: TimeFrame
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(
                title: "Total Tokens",
                value: "\(totalTokens)",
                icon: "number.circle",
                color: .blue
            )
            
            StatCard(
                title: "Total Cost",
                value: String(format: "$%.3f", totalCost),
                icon: "dollarsign.circle",
                color: .green
            )
            
            StatCard(
                title: "Sessions",
                value: "\(sessionCount)",
                icon: "clock.circle",
                color: .orange
            )
        }
    }
    
    private var totalTokens: Int {
        blocks.reduce(0) { $0 + $1.tokenCounts.totalTokens }
    }
    
    private var totalCost: Double {
        blocks.reduce(0.0) { $0 + $1.costUSD }
    }
    
    private var sessionCount: Int {
        blocks.filter { !$0.isGap }.count
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}


// MARK: - Enums

enum TimeFrame: CaseIterable {
    case today, thisWeek, thisMonth, all
    
    var displayName: String {
        switch self {
        case .today: return "Today"
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        case .all: return "All Time"
        }
    }
}