//
//  ContentView.swift
//  ticket-for-cc
//
//  Created by 임민호 on 6/22/25.
//

import SwiftUI
import Charts

struct ContentView: View {
    // @StateObject private var dataService = MockDataService()
    @StateObject private var dataService = ClaudeUsageService()
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Claude Code Usage Monitor")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Real-time token usage tracking")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            
            // Usage Overview Cards
            HStack(spacing: 16) {
                UsageCard(
                    title: "Total Tokens",
                    value: dataService.currentSession.totalTokens.formatted(),
                    icon: "sum",
                    color: .blue
                )
                
                UsageCard(
                    title: "Burn Rate",
                    value: String(format: "%.0f/hr", dataService.currentSession.tokensPerHour),
                    icon: "flame",
                    color: .orange
                )
                
                UsageCard(
                    title: "Time to Limit",
                    value: dataService.estimatedTimeToLimit,
                    icon: "clock",
                    color: .purple
                )
            }
            .padding(.horizontal)
            
            // Progress Bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Daily Usage")
                        .font(.headline)
                    Spacer()
                    Text("\(Int(dataService.usagePercentage * 100))%")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                ProgressView(value: dataService.usagePercentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: progressColor(for: dataService.usagePercentage)))
                    .scaleEffect(y: 2)
                
                HStack {
                    Text("\(dataService.currentSession.totalTokens.formatted()) tokens")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(dataService.dailyLimit.formatted()) limit")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Token Usage Chart
            VStack(alignment: .leading, spacing: 8) {
                Text("Token Usage Over Time")
                    .font(.headline)
                    .padding(.horizontal)
                
                if dataService.currentSession.entries.count > 1 {
                    Chart(Array(dataService.currentSession.entries.suffix(20))) { entry in
                        LineMark(
                            x: .value("Time", entry.timestamp),
                            y: .value("Tokens", entry.totalTokens)
                        )
                        .foregroundStyle(.blue)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        
                        PointMark(
                            x: .value("Time", entry.timestamp),
                            y: .value("Tokens", entry.totalTokens)
                        )
                        .foregroundStyle(.blue)
                    }
                    .frame(height: 200)
                    .padding()
                } else {
                    Text("Waiting for data...")
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.secondary)
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            .padding(.horizontal)
            
            Spacer()
            
            // Error or Loading State
            if let dataService = dataService as? ClaudeUsageService {
                if dataService.isLoading {
                    ProgressView("Loading usage data...")
                        .padding()
                } else if let error = dataService.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
            }
        }
        .frame(width: 600, height: 700)
        .padding(.vertical)
    }
    
    private func progressColor(for percentage: Double) -> Color {
        switch percentage {
        case 0..<0.5:
            return .green
        case 0.5..<0.8:
            return .yellow
        default:
            return .red
        }
    }
}

struct UsageCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

#Preview {
    ContentView()
}
