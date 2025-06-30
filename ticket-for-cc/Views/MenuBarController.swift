//
//  MenuBarController.swift
//  ticket-for-cc
//
//  Controller for menu bar integration with NSStatusItem
//

import SwiftUI
import AppKit

class MenuBarController: ObservableObject {
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    @Published var currentUsage: String = "Loading..."
    @Published var burnRate: String = "--"
    @Published var isConnected: Bool = false
    
    // Usage data
    @Published var activeBlock: SessionBlock?
    @Published var recentBlocks: [SessionBlock] = []
    @Published var totalTokensToday: Int = 0
    @Published var totalCostToday: Double = 0.0
    
    init() {
        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Create popover for detailed view
        popover = NSPopover()
        popover.contentSize = NSSize(width: 400, height: 600)
        popover.behavior = .transient
        
        setupStatusItem()
        setupPopover()
        updateMenuBarDisplay()
    }
    
    private func setupStatusItem() {
        guard let button = statusItem.button else { return }
        
        // Set initial text
        button.title = "🎫 --"
        button.action = #selector(togglePopover)
        button.target = self
        
        // Add right-click menu
        let menu = createMenu()
        statusItem.menu = menu
    }
    
    private func setupPopover() {
        // Set the popover content to our dashboard view
        popover.contentViewController = NSHostingController(
            rootView: MenuBarPopoverView()
                .environmentObject(self)
        )
    }
    
    private func createMenu() -> NSMenu {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Open Dashboard", action: #selector(openDashboard), keyEquivalent: "d"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Refresh Data", action: #selector(refreshData), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        
        // Set targets
        for item in menu.items {
            item.target = self
        }
        
        return menu
    }
    
    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
    
    @objc func openDashboard() {
        // Open main dashboard window
        NSApp.activate(ignoringOtherApps: true)
        
        // Find or create main window
        if let window = NSApp.windows.first(where: { $0.contentViewController is NSHostingController<ContentView> }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            // Create new window if needed
            let contentView = ContentView()
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.center()
            window.setFrameAutosaveName("DashboardWindow")
            window.contentViewController = NSHostingController(rootView: contentView)
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    @objc func refreshData() {
        // Trigger data refresh
        updateUsageData()
    }
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
    
    func updateUsageData() {
        Task {
            do {
                // Load usage data using DataParser
                let parser = DataParser()
                let paths = parser.getClaudePaths()
                let entries = try await parser.loadAllUsageData(from: paths)
                
                // Create session blocks
                let blocks = SessionBlockManager.identifySessionBlocks(from: entries)
                
                await MainActor.run {
                    self.recentBlocks = SessionBlockManager.getRecentBlocks(from: blocks)
                    self.activeBlock = SessionBlockManager.getActiveBlock(from: blocks)
                    
                    // Calculate today's usage
                    let today = Calendar.current.startOfDay(for: Date())
                    let todaysEntries = entries.filter { $0.timestamp >= today }
                    self.totalTokensToday = todaysEntries.reduce(0) { $0 + $1.totalTokens }
                    self.totalCostToday = todaysEntries.reduce(0.0) { $0 + $1.cost }
                    
                    self.isConnected = !entries.isEmpty
                    self.updateMenuBarDisplay()
                }
            } catch {
                await MainActor.run {
                    self.isConnected = false
                    self.currentUsage = "Error"
                    self.burnRate = "--"
                    self.updateMenuBarDisplay()
                }
            }
        }
    }
    
    private func updateMenuBarDisplay() {
        guard let button = statusItem.button else { return }
        
        if !isConnected {
            button.title = "🎫 --"
            return
        }
        
        if let activeBlock = activeBlock {
            // Show current session info
            let tokens = activeBlock.tokenCounts.totalTokens
            let formattedTokens = formatTokenCount(tokens)
            
            if let burnRate = activeBlock.burnRate {
                let tokensPerHour = burnRate.tokensPerHour
                button.title = "🎫 \(formattedTokens) (\(formatTokenCount(tokensPerHour))/h)"
            } else {
                button.title = "🎫 \(formattedTokens)"
            }
        } else if totalTokensToday > 0 {
            // Show today's total if no active session
            let formattedTokens = formatTokenCount(totalTokensToday)
            button.title = "🎫 \(formattedTokens) today"
        } else {
            button.title = "🎫 Ready"
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
    
    func startMonitoring() {
        // Initial data load
        updateUsageData()
        
        // Set up timer for regular updates (every 3 seconds)
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            self.updateUsageData()
        }
    }
}

// MARK: - Popover View

struct MenuBarPopoverView: View {
    @EnvironmentObject var controller: MenuBarController
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("🎫 Claude Usage")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Button("Refresh") {
                    controller.refreshData()
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal)
            .padding(.top)
            
            Divider()
            
            if controller.isConnected {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Active session info
                        if let activeBlock = controller.activeBlock {
                            ActiveSessionCard(block: activeBlock)
                        }
                        
                        // Today's summary
                        TodaysSummaryCard(
                            tokens: controller.totalTokensToday,
                            cost: controller.totalCostToday
                        )
                        
                        // Recent sessions
                        if !controller.recentBlocks.isEmpty {
                            RecentSessionsList(blocks: controller.recentBlocks)
                        }
                    }
                    .padding(.horizontal)
                }
            } else {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("No Claude usage data found")
                        .font(.headline)
                    Text("Make sure Claude Code is installed and has been used.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            Divider()
            
            // Footer
            HStack {
                Button("Open Dashboard") {
                    controller.openDashboard()
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
                
                Button("Quit") {
                    controller.quitApp()
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(width: 400, height: 600)
    }
}

// MARK: - Helper Views

struct ActiveSessionCard: View {
    let block: SessionBlock
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🟢 Active Session")
                .font(.headline)
                .foregroundColor(.green)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(block.tokenCounts.totalTokens)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("tokens")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let burnRate = block.burnRate {
                    VStack(alignment: .trailing) {
                        Text(burnRate.formattedTokensPerHour)
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("tokens/hour")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if let projected = block.projectedUsage {
                Text("Projected: \(projected.totalTokens) tokens in \(projected.formattedRemainingTime)")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }
}

struct TodaysSummaryCard: View {
    let tokens: Int
    let cost: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("📊 Today's Usage")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(tokens)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("tokens")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(String(format: "$%.3f", cost))
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("cost")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
}

struct RecentSessionsList: View {
    let blocks: [SessionBlock]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("📈 Recent Sessions")
                .font(.headline)
            
            ForEach(blocks.filter { !$0.isGap }.prefix(3), id: \.id) { block in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(block.startTime, style: .time)
                            .font(.caption)
                            .fontWeight(.medium)
                        Text("\(block.tokenCounts.totalTokens) tokens")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(String(format: "$%.3f", block.costUSD))
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.vertical, 4)
                
                if block.id != blocks.last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}