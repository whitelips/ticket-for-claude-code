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
                // Main content with responsive layout
                GeometryReader { geometry in
                    ScrollView {
                        LazyVStack(spacing: DesignSystem.Spacing.xxxl) {
                            // Current session overview
                            if let activeBlock = usageService.activeSessionBlock {
                                ActiveSessionOverview(block: activeBlock)
                            }
                            
                            // Usage statistics cards in responsive grid
                            LazyVGrid(columns: statisticsGridColumns(for: geometry.size.width), spacing: DesignSystem.Spacing.lg) {
                                ForEach(Array(statisticsCards.enumerated()), id: \.offset) { index, card in
                                    card
                                }
                            }
                            
                            // Chart and Session History - responsive layout
                            chartAndHistorySection(for: geometry.size.width)
                        }
                        .padding(DesignSystem.Spacing.xl)
                    }
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
    
    // Responsive grid columns for statistics cards
    private func statisticsGridColumns(for width: CGFloat) -> [GridItem] {
        let minCardWidth: CGFloat = 200
        let spacing: CGFloat = DesignSystem.Spacing.lg
        let padding: CGFloat = DesignSystem.Spacing.xl * 2 // Left and right padding
        let availableWidth = width - padding
        
        // Calculate how many columns can fit
        let possibleColumns = max(1, Int(availableWidth / (minCardWidth + spacing)))
        let actualColumns = min(possibleColumns, statisticsCards.count)
        
        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: actualColumns)
    }
    
    // Responsive layout for chart and session history
    @ViewBuilder
    private func chartAndHistorySection(for width: CGFloat) -> some View {
        let minWidthForHorizontal: CGFloat = 1000 // Minimum width to show side by side
        
        if width >= minWidthForHorizontal {
            // Horizontal layout for wider screens
            HStack(spacing: DesignSystem.Spacing.xxxxl) {
                BurnRateChartView(blocks: filteredBlocks)
                    .frame(height: 350)
                    .frame(minWidth: 400)
                    .padding(.top, DesignSystem.Spacing.lg)
                
                SessionHistoryView(blocks: filteredBlocks)
                    .frame(minWidth: 400)
                    .padding(.top, DesignSystem.Spacing.lg)
            }
        } else {
            // Vertical layout for narrower screens
            VStack(spacing: DesignSystem.Spacing.xxxxl) {
                BurnRateChartView(blocks: filteredBlocks)
                    .frame(height: 350)
                    .padding(.top, DesignSystem.Spacing.lg)
                
                SessionHistoryView(blocks: filteredBlocks)
                    .frame(minHeight: 300)
                    .padding(.top, DesignSystem.Spacing.md)
            }
        }
    }
    
    private var statisticsCards: [some View] {
        [
            StatCard(
                title: "Total Tokens",
                value: "\(totalTokens)",
                icon: "number.circle",
                color: DesignSystem.Colors.chartBlue
            ),
            StatCard(
                title: "Total Cost",
                value: String(format: "$%.3f", totalCost),
                icon: "dollarsign.circle",
                color: DesignSystem.Colors.chartGreen
            ),
            StatCard(
                title: "Sessions",
                value: "\(sessionCount)",
                icon: "clock.circle",
                color: DesignSystem.Colors.chartOrange
            ),
            StatCard(
                title: "Avg Burn Rate",
                value: averageBurnRate > 0 ? "\(averageBurnRate)/h" : "N/A",
                icon: "flame.circle",
                color: DesignSystem.Colors.chartPurple
            )
        ]
    }
    
    private var totalTokens: Int {
        filteredBlocks.reduce(0) { $0 + $1.tokenCounts.totalTokens }
    }
    
    private var totalCost: Double {
        filteredBlocks.reduce(0.0) { $0 + $1.costUSD }
    }
    
    private var sessionCount: Int {
        filteredBlocks.filter { !$0.isGap }.count
    }
    
    private var averageBurnRate: Int {
        let rates = filteredBlocks.compactMap { $0.burnRate?.tokensPerHour }
        guard !rates.isEmpty else { return 0 }
        return rates.reduce(0, +) / rates.count
    }
}

// MARK: - Supporting Views

struct HeaderView: View {
    @Binding var selectedTimeframe: TimeFrame
    
    var body: some View {
        HStack {
            Text("🎫 Ticket for Claude Code")
                .font(DesignSystem.Typography.title2Font)
                .fontWeight(DesignSystem.Typography.boldWeight)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            Spacer()
            
            Picker("Timeframe", selection: $selectedTimeframe) {
                ForEach(TimeFrame.allCases, id: \.self) { timeframe in
                    Text(timeframe.displayName).tag(timeframe)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 320)
        }
        .headerStyle()
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
                    .font(DesignSystem.Typography.title2Font)
                    .fontWeight(DesignSystem.Typography.boldWeight)
                    .foregroundColor(DesignSystem.Colors.activeSession)
                
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
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                HStack {
                    Text("Session Progress")
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                    Spacer()
                    Text("\(Int(block.elapsedMinutes))m / 300m")
                        .font(DesignSystem.Typography.captionFont)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                EnhancedProgressView(
                    progress: progress,
                    foregroundColor: progressColor(for: progress),
                    height: 10
                )
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
        .elevatedCardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Spacing.cardCornerRadius)
                .stroke(DesignSystem.Colors.success.opacity(0.3), lineWidth: 2)
        )
    }
    
    private func progressColor(for progress: Double) -> Color {
        switch progress {
        case 0..<0.5: return DesignSystem.Colors.success
        case 0.5..<0.8: return DesignSystem.Colors.warning
        default: return DesignSystem.Colors.error
        }
    }
}


struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(DesignSystem.Typography.title2Font)
                .foregroundColor(color)
                .scaleEffect(isHovered ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
            
            Text(value)
                .font(DesignSystem.Typography.title2Font)
                .fontWeight(DesignSystem.Typography.boldWeight)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .contentTransition(.numericText())
            
            Text(title)
                .font(DesignSystem.Typography.captionFont)
                .foregroundColor(DesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
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