//
//  SettingsView.swift
//  ticket-for-cc
//
//  Settings window with tabbed interface
//

import SwiftUI

struct AppSettingsView: View {
    @StateObject private var settings = Settings.shared
    @State private var selectedTab = SettingsTab.display
    @State private var showingExportAlert = false
    @State private var showingImportAlert = false
    @State private var showingResetAlert = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with title and close button
            HStack {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Custom tab bar
            HStack(spacing: 0) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    TabButton(
                        title: tab.title,
                        icon: tab.icon,
                        isSelected: selectedTab == tab,
                        action: { selectedTab = tab }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Tab content
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    switch selectedTab {
                    case .display:
                        DisplaySettingsView()
                    case .notifications:
                        NotificationSettingsView()
                    case .data:
                        DataSettingsView()
                    case .behavior:
                        BehaviorSettingsView()
                    case .advanced:
                        AdvancedSettingsView()
                    }
                }
                .padding(20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Divider()
            
            // Bottom toolbar
            HStack {
                Button("Reset to Defaults") {
                    showingResetAlert = true
                }
                .buttonStyle(.borderless)
                
                Spacer()
                
                Button("Export...") {
                    exportSettings()
                }
                .buttonStyle(.borderless)
                
                Button("Import...") {
                    importSettings()
                }
                .buttonStyle(.borderless)
                
                Divider()
                    .frame(height: 20)
                    .padding(.horizontal, 8)
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: [])
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 600, height: 500)
        .alert("Reset Settings", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                settings.resetToDefaults()
            }
        } message: {
            Text("Are you sure you want to reset all settings to their default values?")
        }
        .environmentObject(settings)
    }
    
    private func exportSettings() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "ticket-for-cc-settings.json"
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            if let data = settings.exportSettings() {
                try? data.write(to: url)
                showingExportAlert = true
            }
        }
    }
    
    private func importSettings() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        openPanel.allowsMultipleSelection = false
        
        if openPanel.runModal() == .OK, let url = openPanel.url {
            if let data = try? Data(contentsOf: url) {
                if settings.importSettings(from: data) {
                    showingImportAlert = true
                }
            }
        }
    }
}

// MARK: - Tab Button

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .accentColor : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Display Settings

struct DisplaySettingsView: View {
    @EnvironmentObject var settings: Settings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            SettingsSection(title: "Menu Bar", description: "Configure how information appears in the menu bar") {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Display Mode:")
                        Picker("", selection: $settings.menuBarDisplayMode) {
                            ForEach(MenuBarDisplayMode.allCases, id: \.self) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 120)
                    }
                    
                    HStack {
                        Text("Refresh Interval:")
                        Slider(value: $settings.menuBarRefreshInterval, in: 1...10, step: 0.5)
                            .frame(width: 200)
                        Text("\(settings.menuBarRefreshInterval, specifier: "%.1f")s")
                            .frame(width: 50)
                    }
                    
                    Toggle("Show burn rate in menu bar", isOn: $settings.showMenuBarBurnRate)
                }
            }
            
            SettingsSection(title: "Dashboard", description: "Configure the main dashboard window") {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Refresh Interval:")
                        Slider(value: $settings.dashboardRefreshInterval, in: 1...30, step: 1)
                            .frame(width: 200)
                        Text("\(Int(settings.dashboardRefreshInterval))s")
                            .frame(width: 50)
                    }
                    
                    Toggle("Show inactive sessions by default", isOn: $settings.showInactiveSessionsByDefault)
                    
                    HStack {
                        Text("Default Chart Time Range:")
                        Picker("", selection: $settings.chartTimeRange) {
                            ForEach(ChartTimeRangeSetting.allCases, id: \.self) { range in
                                Text(range.displayName).tag(range)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 150)
                    }
                }
            }
            
            SettingsSection(title: "Number Formatting", description: "How numbers are displayed throughout the app") {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Token Display Format:")
                        Picker("", selection: $settings.tokenDisplayFormat) {
                            ForEach(TokenDisplayFormat.allCases, id: \.self) { format in
                                Text(format.displayName).tag(format)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 200)
                    }
                    
                    HStack {
                        Text("Cost Decimal Places:")
                        Stepper("\(settings.costDecimalPlaces)", value: $settings.costDecimalPlaces, in: 2...6)
                            .frame(width: 100)
                    }
                }
            }
        }
    }
}

// MARK: - Notification Settings

struct NotificationSettingsView: View {
    @EnvironmentObject var settings: Settings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            SettingsSection(title: "Usage Alerts") {
                VStack(alignment: .leading, spacing: 16) {
                    Toggle("Enable usage limit alerts", isOn: $settings.enableUsageAlerts)
                    
                    if settings.enableUsageAlerts {
                        HStack {
                            Text("Daily limit warning at:")
                            Slider(value: $settings.dailyLimitWarningThreshold, in: 0.5...0.95, step: 0.05)
                                .frame(width: 200)
                            Text("\(Int(settings.dailyLimitWarningThreshold * 100))%")
                                .frame(width: 50)
                        }
                        
                        HStack {
                            Text("Monthly limit warning at:")
                            Slider(value: $settings.monthlyLimitWarningThreshold, in: 0.5...0.95, step: 0.05)
                                .frame(width: 200)
                            Text("\(Int(settings.monthlyLimitWarningThreshold * 100))%")
                                .frame(width: 50)
                        }
                    }
                }
            }
            
            SettingsSection(title: "Burn Rate Alerts") {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("High burn rate threshold:")
                        TextField("", value: $settings.highBurnRateThreshold, format: .number)
                            .frame(width: 100)
                        Text("tokens/hour")
                    }
                    Text("Alert when burn rate exceeds this threshold")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            SettingsSection(title: "Session Notifications") {
                Toggle("Notify when session ends", isOn: $settings.enableSessionEndNotifications)
            }
        }
    }
}

// MARK: - Data Settings

struct DataSettingsView: View {
    @EnvironmentObject var settings: Settings
    @State private var selectedExportPath = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            SettingsSection(title: "Data Retention") {
                HStack {
                    Text("Keep data for:")
                    Stepper("\(settings.dataRetentionDays) days", value: $settings.dataRetentionDays, in: 7...365)
                        .frame(width: 150)
                }
            }
            
            SettingsSection(title: "Auto Export") {
                VStack(alignment: .leading, spacing: 16) {
                    Toggle("Enable automatic export", isOn: $settings.autoExportEnabled)
                    
                    if settings.autoExportEnabled {
                        HStack {
                            Text("Export Path:")
                            TextField("Select folder...", text: $selectedExportPath)
                                .disabled(true)
                                .frame(width: 250)
                            Button("Choose...") {
                                chooseExportPath()
                            }
                        }
                        
                        HStack {
                            Text("Export Format:")
                            Picker("", selection: $settings.exportFormat) {
                                ForEach(ExportFormat.allCases, id: \.self) { format in
                                    Text(format.displayName).tag(format)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(width: 150)
                        }
                    }
                }
            }
            
            SettingsSection(title: "Data Management") {
                HStack(spacing: 16) {
                    Button("Export All Data...") {
                        exportAllData()
                    }
                    
                    Button("Clear All Data...") {
                        clearAllData()
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .onAppear {
            selectedExportPath = settings.autoExportPath
        }
    }
    
    private func chooseExportPath() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        
        if openPanel.runModal() == .OK, let url = openPanel.url {
            settings.autoExportPath = url.path
            selectedExportPath = url.path
        }
    }
    
    private func exportAllData() {
        // TODO: Implement data export
    }
    
    private func clearAllData() {
        // TODO: Implement data clearing with confirmation
    }
}

// MARK: - Behavior Settings

struct BehaviorSettingsView: View {
    @EnvironmentObject var settings: Settings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            SettingsSection(title: "Startup") {
                VStack(alignment: .leading, spacing: 16) {
                    Toggle("Launch at login", isOn: $settings.launchAtLogin)
                    
                    HStack {
                        Text("Default view on launch:")
                        Picker("", selection: $settings.defaultView) {
                            ForEach(DefaultView.allCases, id: \.self) { view in
                                Text(view.displayName).tag(view)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 200)
                    }
                }
            }
            
            SettingsSection(title: "Window Behavior") {
                VStack(alignment: .leading, spacing: 16) {
                    Toggle("Show dock icon", isOn: $settings.showDockIcon)
                    Toggle("Minimize to menu bar on close", isOn: $settings.minimizeToMenuBarOnClose)
                }
            }
        }
    }
}

// MARK: - Advanced Settings

struct AdvancedSettingsView: View {
    @EnvironmentObject var settings: Settings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            SettingsSection(title: "Debug") {
                Toggle("Enable debug mode", isOn: $settings.debugMode)
                if settings.debugMode {
                    Text("Debug information will be logged to Console")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            SettingsSection(title: "Claude Data Path") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Custom path:")
                        TextField("Leave empty for default", text: $settings.customClaudePath)
                            .frame(width: 300)
                    }
                    Text("Default: ~/.config/claude/")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            SettingsSection(title: "About") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ticket for Claude Code")
                        .font(.headline)
                    Text("Version 1.0.0")
                        .foregroundColor(.secondary)
                    
                    Link("View on GitHub", destination: URL(string: "https://github.com/whitelips/ticket-for-claude-code")!)
                        .foregroundColor(.accentColor)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct SettingsSection<Content: View>: View {
    let title: String
    let description: String?
    let content: Content
    
    init(title: String, description: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.description = description
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                if let description = description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            content
                .padding(.leading, 20)
        }
    }
}

// MARK: - Settings Tab

enum SettingsTab: CaseIterable {
    case display
    case notifications
    case data
    case behavior
    case advanced
    
    var title: String {
        switch self {
        case .display: return "Display"
        case .notifications: return "Notifications"
        case .data: return "Data"
        case .behavior: return "Behavior"
        case .advanced: return "Advanced"
        }
    }
    
    var icon: String {
        switch self {
        case .display: return "paintbrush"
        case .notifications: return "bell"
        case .data: return "externaldrive"
        case .behavior: return "gearshape"
        case .advanced: return "wrench.and.screwdriver"
        }
    }
}