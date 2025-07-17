//
//  BurnRateChartView.swift
//  ticket-for-cc
//
//  Chart view for visualizing token burn rates over time
//

import SwiftUI
import Charts

struct BurnRateChartView: View {
    let blocks: [SessionBlock]
    @State private var selectedMetric: ChartMetric = .tokens
    @State private var selectedTimeRange: ChartTimeRange = .last4Hours
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with controls
            HStack {
                Text("📈 Usage Trends")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Metric selector
                Picker(selection: $selectedMetric, label: EmptyView()) {
                    ForEach(ChartMetric.allCases, id: \.self) { metric in
                        Text(metric.displayName).tag(metric)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
                
                // Time range selector  
                Text("Time Range")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Picker(selection: $selectedTimeRange, label: EmptyView()) {
                    ForEach(ChartTimeRange.allCases, id: \.self) { range in
                        Text(range.displayName).tag(range)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 80)
            }
            
            // Chart
            if chartData.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No data available")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Try selecting a different time range or check if there's recent usage data")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 250)
                .frame(maxWidth: .infinity)
            } else {
                Chart {
                    ForEach(chartData, id: \.timestamp) { dataPoint in
                        switch selectedMetric {
                        case .tokens:
                            LineMark(
                                x: .value("Time", dataPoint.timestamp),
                                y: .value("Tokens", dataPoint.tokens)
                            )
                            .foregroundStyle(.blue)
                            .interpolationMethod(.catmullRom)
                            
                            PointMark(
                                x: .value("Time", dataPoint.timestamp),
                                y: .value("Tokens", dataPoint.tokens)
                            )
                            .foregroundStyle(.blue)
                            .symbolSize(60)
                            
                            AreaMark(
                                x: .value("Time", dataPoint.timestamp),
                                y: .value("Tokens", dataPoint.tokens)
                            )
                            .foregroundStyle(.blue.opacity(0.2))
                            .interpolationMethod(.catmullRom)
                            
                        case .cost:
                            LineMark(
                                x: .value("Time", dataPoint.timestamp),
                                y: .value("Cost", dataPoint.cost)
                            )
                            .foregroundStyle(.green)
                            .interpolationMethod(.catmullRom)
                            
                            PointMark(
                                x: .value("Time", dataPoint.timestamp),
                                y: .value("Cost", dataPoint.cost)
                            )
                            .foregroundStyle(.green)
                            .symbolSize(60)
                            
                            AreaMark(
                                x: .value("Time", dataPoint.timestamp),
                                y: .value("Cost", dataPoint.cost)
                            )
                            .foregroundStyle(.green.opacity(0.2))
                            .interpolationMethod(.catmullRom)
                            
                        case .burnRate:
                            if let burnRate = dataPoint.burnRate {
                                LineMark(
                                    x: .value("Time", dataPoint.timestamp),
                                    y: .value("Burn Rate", burnRate)
                                )
                                .foregroundStyle(.orange)
                                .interpolationMethod(.catmullRom)
                                
                                PointMark(
                                    x: .value("Time", dataPoint.timestamp),
                                    y: .value("Burn Rate", burnRate)
                                )
                                .foregroundStyle(.orange)
                                .symbolSize(60)
                                
                                AreaMark(
                                    x: .value("Time", dataPoint.timestamp),
                                    y: .value("Burn Rate", burnRate)
                                )
                                .foregroundStyle(.orange.opacity(0.2))
                                .interpolationMethod(.catmullRom)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: chartData.count <= 1 ? .dateTime.hour() : .dateTime.hour().minute())
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text(formatYAxisValue(intValue))
                            } else if let doubleValue = value.as(Double.self) {
                                Text(formatYAxisValue(doubleValue))
                            }
                        }
                    }
                }
                .chartYScale(domain: yAxisDomain)
                .chartXScale(domain: xAxisDomain)
                .chartLegend(position: .top, alignment: .leading)
                .frame(height: 250)
                .id("\(selectedTimeRange)-\(selectedMetric)")
            }
            
            // Summary statistics
            SummaryStatsView(
                data: chartData,
                metric: selectedMetric
            )
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var chartData: [ChartDataPoint] {
        let cutoffDate = selectedTimeRange.cutoffDate
        let filteredBlocks = blocks.filter { block in
            return block.startTime >= cutoffDate && !block.isGap
        }
        
        // For active sessions or sessions with multiple entries, show individual entries
        // Otherwise show block-level summaries
        var dataPoints: [ChartDataPoint] = []
        
        for block in filteredBlocks {
            if block.isActive || block.entries.count > 5 {
                // Use individual entries for more granular data
                var cumulativeTokens = 0
                var cumulativeCost = 0.0
                
                for entry in block.entries {
                    // Only include entries that are within the selected time range
                    if entry.timestamp >= cutoffDate {
                        cumulativeTokens += entry.totalTokens
                        cumulativeCost += entry.cost
                        
                        // Calculate burn rate based on time since session start
                        let elapsedHours = entry.timestamp.timeIntervalSince(block.startTime) / 3600
                        let burnRate = elapsedHours > 0 ? Int(Double(cumulativeTokens) / elapsedHours) : 0
                        
                        dataPoints.append(ChartDataPoint(
                            timestamp: entry.timestamp,
                            tokens: cumulativeTokens,
                            cost: cumulativeCost,
                            burnRate: burnRate > 0 ? burnRate : nil
                        ))
                    }
                }
            } else {
                // Use block summary for completed sessions with few entries
                dataPoints.append(ChartDataPoint(
                    timestamp: block.startTime,
                    tokens: block.tokenCounts.totalTokens,
                    cost: block.costUSD,
                    burnRate: block.burnRate?.tokensPerHour
                ))
            }
        }
        
        return dataPoints.sorted { $0.timestamp < $1.timestamp }
    }
    
    private var xAxisDomain: ClosedRange<Date> {
        if chartData.isEmpty {
            let now = Date()
            return now.addingTimeInterval(-3600)...now // Default 1 hour range
        }
        
        let timestamps = chartData.map { $0.timestamp }
        let minDate = timestamps.min() ?? Date()
        let maxDate = timestamps.max() ?? Date()
        
        // If we only have one data point or a very small time range
        let timeRange = maxDate.timeIntervalSince(minDate)
        if timeRange < 300 { // Less than 5 minutes
            // Extend the range to show at least 30 minutes
            return minDate.addingTimeInterval(-900)...maxDate.addingTimeInterval(900)
        }
        
        // Add 5% padding on each side
        let padding = timeRange * 0.05
        return minDate.addingTimeInterval(-padding)...maxDate.addingTimeInterval(padding)
    }
    
    private var yAxisDomain: ClosedRange<Double> {
        guard !chartData.isEmpty else { return 0...100 }
        
        let values: [Double]
        switch selectedMetric {
        case .tokens:
            values = chartData.map { Double($0.tokens) }
        case .cost:
            values = chartData.map { $0.cost }
        case .burnRate:
            values = chartData.compactMap { $0.burnRate }.map { Double($0) }
        }
        
        guard !values.isEmpty else { return 0...100 }
        
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 100
        
        // Add some padding to the range (10% on each side)
        let padding = (maxValue - minValue) * 0.1
        let adjustedMin = max(0, minValue - padding)
        let adjustedMax = maxValue + padding
        
        // Ensure we have a reasonable minimum range
        let range = adjustedMax - adjustedMin
        if range < 1 {
            return max(0, adjustedMin - 0.5)...(adjustedMax + 0.5)
        }
        
        return adjustedMin...adjustedMax
    }
    
    private func formatYAxisValue(_ value: Int) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", Double(value) / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.1fK", Double(value) / 1_000)
        } else {
            return "\(value)"
        }
    }
    
    private func formatYAxisValue(_ value: Double) -> String {
        if selectedMetric == .cost {
            return String(format: "$%.3f", value)
        } else {
            return formatYAxisValue(Int(value))
        }
    }
}

// MARK: - Supporting Types

struct ChartDataPoint {
    let timestamp: Date
    let tokens: Int
    let cost: Double
    let burnRate: Int?
}

enum ChartMetric: CaseIterable {
    case tokens, cost, burnRate
    
    var displayName: String {
        switch self {
        case .tokens: return "Tokens"
        case .cost: return "Cost"
        case .burnRate: return "Burn Rate"
        }
    }
}

enum ChartTimeRange: CaseIterable {
    case last4Hours, last12Hours, last24Hours, lastWeek
    
    var displayName: String {
        switch self {
        case .last4Hours: return "4h"
        case .last12Hours: return "12h"
        case .last24Hours: return "24h"
        case .lastWeek: return "7d"
        }
    }
    
    var cutoffDate: Date {
        let now = Date()
        // Use UTC calendar to match session block timestamps
        var utcCalendar = Calendar.current
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
        
        switch self {
        case .last4Hours:
            return utcCalendar.date(byAdding: .hour, value: -4, to: now) ?? now
        case .last12Hours:
            return utcCalendar.date(byAdding: .hour, value: -12, to: now) ?? now
        case .last24Hours:
            return utcCalendar.date(byAdding: .day, value: -1, to: now) ?? now
        case .lastWeek:
            return utcCalendar.date(byAdding: .day, value: -7, to: now) ?? now
        }
    }
}

// MARK: - Summary Statistics

struct SummaryStatsView: View {
    let data: [ChartDataPoint]
    let metric: ChartMetric
    
    var body: some View {
        HStack(spacing: 32) {
            StatisticBox(
                title: "Peak",
                value: peakValueString,
                color: .red
            )
            
            StatisticBox(
                title: "Average",
                value: averageValueString,
                color: .blue
            )
            
            StatisticBox(
                title: "Total",
                value: totalValueString,
                color: .green
            )
            
            Spacer()
        }
    }
    
    private var peakValueString: String {
        switch metric {
        case .tokens:
            let peak = data.map(\.tokens).max() ?? 0
            return formatNumber(peak)
        case .cost:
            let peak = data.map(\.cost).max() ?? 0.0
            return String(format: "$%.3f", peak)
        case .burnRate:
            let peak = data.compactMap(\.burnRate).max() ?? 0
            return "\(formatNumber(peak))/h"
        }
    }
    
    private var averageValueString: String {
        guard !data.isEmpty else { return "0" }
        
        switch metric {
        case .tokens:
            let avg = data.map(\.tokens).reduce(0, +) / data.count
            return formatNumber(avg)
        case .cost:
            let avg = data.map(\.cost).reduce(0, +) / Double(data.count)
            return String(format: "$%.3f", avg)
        case .burnRate:
            let rates = data.compactMap(\.burnRate)
            guard !rates.isEmpty else { return "0/h" }
            let avg = rates.reduce(0, +) / rates.count
            return "\(formatNumber(avg))/h"
        }
    }
    
    private var totalValueString: String {
        switch metric {
        case .tokens:
            let total = data.map(\.tokens).reduce(0, +)
            return formatNumber(total)
        case .cost:
            let total = data.map(\.cost).reduce(0, +)
            return String(format: "$%.3f", total)
        case .burnRate:
            return "N/A"
        }
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1_000_000 {
            return String(format: "%.1fM", Double(number) / 1_000_000)
        } else if number >= 1_000 {
            return String(format: "%.1fK", Double(number) / 1_000)
        } else {
            return "\(number)"
        }
    }
}

struct StatisticBox: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
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
