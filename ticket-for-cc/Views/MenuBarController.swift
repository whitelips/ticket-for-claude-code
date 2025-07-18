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
    private var settingsWindow: NSWindow?
    @Published var currentUsage: String = "Loading..."
    @Published var burnRate: String = "--"
    @Published var isConnected: Bool = false
    
    // Usage data
    @Published var activeBlock: SessionBlock?
    @Published var recentBlocks: [SessionBlock] = []
    @Published var totalTokensToday: Int = 0
    @Published var totalCostToday: Double = 0.0
    
    // Display preference - now using Settings
    var displayMode: MenuBarDisplayMode {
        get { Settings.shared.menuBarDisplayMode }
        set { Settings.shared.menuBarDisplayMode = newValue }
    }
    
    init() {
        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Create popover for detailed view
        popover = NSPopover()
        popover.contentSize = NSSize(width: 400, height: 600)
        popover.behavior = .transient
        
        // Display mode is now handled by Settings
        
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
        
        // Display mode submenu
        let displayMenu = NSMenu(title: "Display")
        let displayMenuItem = NSMenuItem(title: "Display", action: nil, keyEquivalent: "")
        displayMenuItem.submenu = displayMenu
        
        for mode in MenuBarDisplayMode.allCases {
            let modeItem = NSMenuItem(title: mode.displayName, action: #selector(changeDisplayMode(_:)), keyEquivalent: "")
            modeItem.representedObject = mode
            modeItem.state = displayMode == mode ? .on : .off
            displayMenu.addItem(modeItem)
        }
        
        menu.addItem(displayMenuItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Refresh Data", action: #selector(refreshData), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        
        // Set targets
        for item in menu.items {
            item.target = self
            if let submenu = item.submenu {
                for subItem in submenu.items {
                    subItem.target = self
                }
            }
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
        
        // Find existing dashboard window
        if let window = NSApp.windows.first(where: { $0.title == "Dashboard" }) {
            // Just bring existing window to front - don't resize
            window.makeKeyAndOrderFront(nil)
        } else {
            // Create new dashboard window with initial size
            let dashboardView = DashboardView()
            let hostingController = NSHostingController(rootView: dashboardView)
            
            // Create window with initial content-appropriate size
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 900, height: 650),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Dashboard"
            window.contentViewController = hostingController
            window.center()
            window.setFrameAutosaveName("DashboardWindow")
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
    
    @objc func changeDisplayMode(_ sender: NSMenuItem) {
        guard let mode = sender.representedObject as? MenuBarDisplayMode else { return }
        displayMode = mode
        
        // Update menu states
        statusItem.menu = createMenu()
    }
    
    @objc func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        
        // Check if settings window is already open
        if let window = settingsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
        } else {
            // Create new settings window
            let settingsView = AppSettingsView()
            let hostingController = NSHostingController(rootView: settingsView)
            
            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            
            settingsWindow?.title = "Settings"
            settingsWindow?.center()
            settingsWindow?.contentViewController = hostingController
            settingsWindow?.isReleasedWhenClosed = false
            settingsWindow?.makeKeyAndOrderFront(nil)
        }
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
        
        switch displayMode {
        case .tokens:
            updateMenuBarDisplayTokens(button: button)
        case .cost:
            updateMenuBarDisplayCost(button: button)
        }
    }
    
    private func updateMenuBarDisplayTokens(button: NSStatusBarButton) {
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
    
    private func updateMenuBarDisplayCost(button: NSStatusBarButton) {
        if let activeBlock = activeBlock {
            // Show current session cost
            let cost = activeBlock.costUSD
            let formattedCost = formatCost(cost)
            
            if let burnRate = activeBlock.burnRate {
                let costPerHour = burnRate.costPerHour
                button.title = "🎫 \(formattedCost) ($\(String(format: "%.2f", costPerHour))/h)"
            } else {
                button.title = "🎫 \(formattedCost)"
            }
        } else if totalCostToday > 0 {
            // Show today's total cost if no active session
            let formattedCost = formatCost(totalCostToday)
            button.title = "🎫 \(formattedCost) today"
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
    
    private func formatCost(_ cost: Double) -> String {
        let decimalPlaces = Settings.shared.costDecimalPlaces
        if cost >= 1.0 && decimalPlaces > 2 {
            return String(format: "$%.2f", cost)
        } else {
            return String(format: "$%.\(decimalPlaces)f", cost)
        }
    }
    
    private var refreshTimer: Timer?
    
    func startMonitoring() {
        // Initial data load
        updateUsageData()
        
        // Set up timer for regular updates based on settings
        scheduleRefreshTimer()
        
        // Observe settings changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsChanged),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
    }
    
    private func scheduleRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: Settings.shared.menuBarRefreshInterval, repeats: true) { _ in
            self.updateUsageData()
        }
    }
    
    @objc private func settingsChanged() {
        // Reschedule timer if refresh interval changed
        scheduleRefreshTimer()
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
                
                // Display mode indicator
                Text("Showing: \(controller.displayMode.displayName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
                
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