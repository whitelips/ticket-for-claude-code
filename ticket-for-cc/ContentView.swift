//
//  ContentView.swift
//  ticket-for-cc
//
//  Created by 임민호 on 6/22/25.
//

import SwiftUI
import Charts

struct ContentView: View {
    @StateObject private var dataService = ClaudeUsageService()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            OverviewView(dataService: dataService)
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Overview")
                }
                .tag(0)
            
            AnalyticsView(dataService: dataService)
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Analytics")
                }
                .tag(1)
        }
        .frame(width: 800, height: 700)
    }
}

struct OverviewView: View {
    @ObservedObject var dataService: ClaudeUsageService
    
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
                    title: "Today's Cost",
                    value: String(format: "$%.2f", dataService.todayTotalCost),
                    icon: "dollarsign.circle",
                    color: .green
                )
                
                UsageCard(
                    title: "Total Tokens",
                    value: dataService.currentSession.totalTokens.formatted(),
                    icon: "sum",
                    color: .blue
                )
                
                UsageCard(
                    title: "Active Sessions",
                    value: "\(dataService.analytics.sessionBlocks.count)",
                    icon: "bubble.left.and.bubble.right",
                    color: .orange
                )
                
                UsageCard(
                    title: "Burn Rate",
                    value: String(format: "%.0f/hr", dataService.currentSession.tokensPerHour),
                    icon: "flame",
                    color: .purple
                )
            }
            .padding(.horizontal)
            
            // Cost Progress Bars
            VStack(spacing: 16) {
                // Daily Cost Progress
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Daily Cost Limit")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(dataService.dailyCostPercentage * 100))%")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    ProgressView(value: dataService.dailyCostPercentage)
                        .progressViewStyle(LinearProgressViewStyle(tint: progressColor(for: dataService.dailyCostPercentage)))
                        .scaleEffect(y: 2)
                    
                    HStack {
                        Text("$\(dataService.todayTotalCost, specifier: "%.2f")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("$\(dataService.dailyCostLimit, specifier: "%.0f") limit")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Monthly Cost Progress
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Monthly Cost Limit")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(dataService.monthlyCostPercentage * 100))%")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    ProgressView(value: dataService.monthlyCostPercentage)
                        .progressViewStyle(LinearProgressViewStyle(tint: progressColor(for: dataService.monthlyCostPercentage)))
                        .scaleEffect(y: 2)
                    
                    HStack {
                        Text("$\(dataService.monthTotalCost, specifier: "%.2f")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("$\(dataService.monthlyCostLimit, specifier: "%.0f") limit")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
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
