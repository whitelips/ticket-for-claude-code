import SwiftUI
import Charts

struct AnalyticsView: View {
    @ObservedObject var dataService: ClaudeUsageService
    
    var body: some View {
        VStack(spacing: 20) {
            // Cost Analytics
            HStack(spacing: 16) {
                CostCard(
                    title: "Today",
                    cost: dataService.todayTotalCost,
                    limit: dataService.dailyCostLimit,
                    percentage: dataService.dailyCostPercentage,
                    color: .blue
                )
                
                CostCard(
                    title: "This Month", 
                    cost: dataService.monthTotalCost,
                    limit: dataService.monthlyCostLimit,
                    percentage: dataService.monthlyCostPercentage,
                    color: .purple
                )
            }
            
            // Model Breakdown
            ModelBreakdownView(modelBreakdown: dataService.analytics.modelBreakdown)
            
            // Session Analytics
            SessionAnalyticsView(sessions: dataService.analytics.sessionBlocks)
            
            // Usage Trend
            UsageTrendChart(dailyUsages: dataService.analytics.getUsageTrend())
        }
        .padding()
    }
}

struct CostCard: View {
    let title: String
    let cost: Double
    let limit: Double
    let percentage: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text("\(Int(percentage * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text("$\(cost, specifier: "%.2f")")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            ProgressView(value: min(percentage, 1.0))
                .progressViewStyle(LinearProgressViewStyle(tint: progressColor(for: percentage)))
            
            Text("of $\(limit, specifier: "%.0f") limit")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private func progressColor(for percentage: Double) -> Color {
        switch percentage {
        case 0..<0.5: return .green
        case 0.5..<0.8: return .yellow
        default: return .red
        }
    }
}

struct ModelBreakdownView: View {
    let modelBreakdown: [String: ModelUsage]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Model Usage Breakdown")
                .font(.headline)
            
            ForEach(Array(modelBreakdown.keys.sorted()), id: \.self) { model in
                if let usage = modelBreakdown[model] {
                    ModelUsageRow(model: model, usage: usage)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct ModelUsageRow: View {
    let model: String
    let usage: ModelUsage
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(modelDisplayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("\(usage.requestCount) requests")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("$\(usage.cost, specifier: "%.3f")")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("\(usage.totalTokens.formatted()) tokens")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var modelDisplayName: String {
        switch model {
        case let m where m.contains("sonnet"): return "Claude Sonnet"
        case let m where m.contains("haiku"): return "Claude Haiku"
        case let m where m.contains("opus"): return "Claude Opus"
        default: return model
        }
    }
}

struct SessionAnalyticsView: View {
    let sessions: [SessionBlock]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Sessions")
                    .font(.headline)
                Spacer()
                Text("\(sessions.count) total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            ForEach(sessions.suffix(5).reversed(), id: \.id) { session in
                SessionRow(session: session)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct SessionRow: View {
    let session: SessionBlock
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(session.startTime, style: .time)
                    .font(.subheadline)
                Text(formatDuration(session.duration))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("$\(session.totalCost, specifier: "%.3f")")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("\(session.totalTokens.formatted()) tokens")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct UsageTrendChart: View {
    let dailyUsages: [DailyUsage]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("7-Day Usage Trend")
                .font(.headline)
            
            if dailyUsages.count > 1 {
                Chart(dailyUsages) { usage in
                    BarMark(
                        x: .value("Date", usage.date, unit: .day),
                        y: .value("Cost", usage.totalCost)
                    )
                    .foregroundStyle(.blue)
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let cost = value.as(Double.self) {
                                Text("$\(cost, specifier: "%.1f")")
                            }
                        }
                    }
                }
            } else {
                Text("Not enough data for trend analysis")
                    .foregroundStyle(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}