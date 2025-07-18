//
//  Settings.swift
//  ticket-for-cc
//
//  User settings and preferences management
//

import Foundation
import SwiftUI

enum MenuBarDisplayMode: String, CaseIterable {
    case tokens = "tokens"
    case cost = "cost"
    
    var displayName: String {
        switch self {
        case .tokens: return "Tokens"
        case .cost: return "Cost"
        }
    }
}

class Settings: ObservableObject {
    static let shared = Settings()
    
    // MARK: - Menu Bar Settings
    
    @AppStorage("MenuBarDisplayMode") var menuBarDisplayMode: MenuBarDisplayMode = .tokens {
        didSet { objectWillChange.send() }
    }
    
    @AppStorage("menuBarRefreshInterval") var menuBarRefreshInterval: Double = 3.0 {
        didSet { objectWillChange.send() }
    }
    
    @AppStorage("showMenuBarBurnRate") var showMenuBarBurnRate: Bool = true {
        didSet { objectWillChange.send() }
    }
    
    // MARK: - Dashboard Settings
    
    @AppStorage("dashboardRefreshInterval") var dashboardRefreshInterval: Double = 5.0 {
        didSet { objectWillChange.send() }
    }
    
    @AppStorage("showInactiveSessionsByDefault") var showInactiveSessionsByDefault: Bool = false {
        didSet { objectWillChange.send() }
    }
    
    @AppStorage("tokenDisplayFormat") var tokenDisplayFormat: TokenDisplayFormat = .abbreviated {
        didSet { objectWillChange.send() }
    }
    
    @AppStorage("costDecimalPlaces") var costDecimalPlaces: Int = 3 {
        didSet { objectWillChange.send() }
    }
    
    @AppStorage("chartTimeRange") var chartTimeRange: ChartTimeRangeSetting = .last4Hours {
        didSet { objectWillChange.send() }
    }
    
    // MARK: - Notification Settings
    
    @AppStorage("enableUsageAlerts") var enableUsageAlerts: Bool = true {
        didSet { objectWillChange.send() }
    }
    
    @AppStorage("dailyLimitWarningThreshold") var dailyLimitWarningThreshold: Double = 0.8 {
        didSet { objectWillChange.send() }
    }
    
    @AppStorage("monthlyLimitWarningThreshold") var monthlyLimitWarningThreshold: Double = 0.8 {
        didSet { objectWillChange.send() }
    }
    
    @AppStorage("highBurnRateThreshold") var highBurnRateThreshold: Int = 100000 {
        didSet { objectWillChange.send() }
    }
    
    @AppStorage("enableSessionEndNotifications") var enableSessionEndNotifications: Bool = false {
        didSet { objectWillChange.send() }
    }
    
    // MARK: - Data Settings
    
    @AppStorage("dataRetentionDays") var dataRetentionDays: Int = 30 {
        didSet { objectWillChange.send() }
    }
    
    @AppStorage("autoExportEnabled") var autoExportEnabled: Bool = false {
        didSet { objectWillChange.send() }
    }
    
    @AppStorage("autoExportPath") var autoExportPath: String = "" {
        didSet { objectWillChange.send() }
    }
    
    @AppStorage("exportFormat") var exportFormat: ExportFormat = .csv {
        didSet { objectWillChange.send() }
    }
    
    // MARK: - Behavior Settings
    
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false {
        didSet { 
            objectWillChange.send()
            updateLaunchAtLogin()
        }
    }
    
    @AppStorage("showDockIcon") var showDockIcon: Bool = true {
        didSet { 
            objectWillChange.send()
            updateDockIconVisibility()
        }
    }
    
    @AppStorage("defaultView") var defaultView: DefaultView = .dashboard {
        didSet { objectWillChange.send() }
    }
    
    @AppStorage("minimizeToMenuBarOnClose") var minimizeToMenuBarOnClose: Bool = true {
        didSet { objectWillChange.send() }
    }
    
    // MARK: - Advanced Settings
    
    @AppStorage("debugMode") var debugMode: Bool = false {
        didSet { objectWillChange.send() }
    }
    
    @AppStorage("customClaudePath") var customClaudePath: String = "" {
        didSet { objectWillChange.send() }
    }
    
    // MARK: - Methods
    
    private init() {
        // Initialize any necessary settings
    }
    
    func resetToDefaults() {
        menuBarDisplayMode = .tokens
        menuBarRefreshInterval = 3.0
        showMenuBarBurnRate = true
        
        dashboardRefreshInterval = 5.0
        showInactiveSessionsByDefault = false
        tokenDisplayFormat = .abbreviated
        costDecimalPlaces = 3
        chartTimeRange = .last4Hours
        
        enableUsageAlerts = true
        dailyLimitWarningThreshold = 0.8
        monthlyLimitWarningThreshold = 0.8
        highBurnRateThreshold = 100000
        enableSessionEndNotifications = false
        
        dataRetentionDays = 30
        autoExportEnabled = false
        autoExportPath = ""
        exportFormat = .csv
        
        launchAtLogin = false
        showDockIcon = true
        defaultView = .dashboard
        minimizeToMenuBarOnClose = true
        
        debugMode = false
        customClaudePath = ""
    }
    
    private func updateLaunchAtLogin() {
        // TODO: Implement launch at login functionality
        // This would use SMLoginItemSetEnabled or the newer Service Management API
    }
    
    private func updateDockIconVisibility() {
        if showDockIcon {
            NSApp.setActivationPolicy(.regular)
        } else {
            NSApp.setActivationPolicy(.accessory)
        }
    }
    
    func exportSettings() -> Data? {
        let settings: [String: Any] = [
            "menuBarDisplayMode": menuBarDisplayMode.rawValue,
            "menuBarRefreshInterval": menuBarRefreshInterval,
            "showMenuBarBurnRate": showMenuBarBurnRate,
            "dashboardRefreshInterval": dashboardRefreshInterval,
            "showInactiveSessionsByDefault": showInactiveSessionsByDefault,
            "tokenDisplayFormat": tokenDisplayFormat.rawValue,
            "costDecimalPlaces": costDecimalPlaces,
            "chartTimeRange": chartTimeRange.rawValue,
            "enableUsageAlerts": enableUsageAlerts,
            "dailyLimitWarningThreshold": dailyLimitWarningThreshold,
            "monthlyLimitWarningThreshold": monthlyLimitWarningThreshold,
            "highBurnRateThreshold": highBurnRateThreshold,
            "enableSessionEndNotifications": enableSessionEndNotifications,
            "dataRetentionDays": dataRetentionDays,
            "autoExportEnabled": autoExportEnabled,
            "autoExportPath": autoExportPath,
            "exportFormat": exportFormat.rawValue,
            "launchAtLogin": launchAtLogin,
            "showDockIcon": showDockIcon,
            "defaultView": defaultView.rawValue,
            "minimizeToMenuBarOnClose": minimizeToMenuBarOnClose,
            "debugMode": debugMode,
            "customClaudePath": customClaudePath
        ]
        
        return try? JSONSerialization.data(withJSONObject: settings, options: .prettyPrinted)
    }
    
    func importSettings(from data: Data) -> Bool {
        guard let settings = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return false
        }
        
        if let value = settings["menuBarDisplayMode"] as? String,
           let mode = MenuBarDisplayMode(rawValue: value) { menuBarDisplayMode = mode }
        if let value = settings["menuBarRefreshInterval"] as? Double { menuBarRefreshInterval = value }
        if let value = settings["showMenuBarBurnRate"] as? Bool { showMenuBarBurnRate = value }
        if let value = settings["dashboardRefreshInterval"] as? Double { dashboardRefreshInterval = value }
        if let value = settings["showInactiveSessionsByDefault"] as? Bool { showInactiveSessionsByDefault = value }
        if let value = settings["tokenDisplayFormat"] as? String,
           let format = TokenDisplayFormat(rawValue: value) { tokenDisplayFormat = format }
        if let value = settings["costDecimalPlaces"] as? Int { costDecimalPlaces = value }
        if let value = settings["chartTimeRange"] as? String,
           let range = ChartTimeRangeSetting(rawValue: value) { chartTimeRange = range }
        if let value = settings["enableUsageAlerts"] as? Bool { enableUsageAlerts = value }
        if let value = settings["dailyLimitWarningThreshold"] as? Double { dailyLimitWarningThreshold = value }
        if let value = settings["monthlyLimitWarningThreshold"] as? Double { monthlyLimitWarningThreshold = value }
        if let value = settings["highBurnRateThreshold"] as? Int { highBurnRateThreshold = value }
        if let value = settings["enableSessionEndNotifications"] as? Bool { enableSessionEndNotifications = value }
        if let value = settings["dataRetentionDays"] as? Int { dataRetentionDays = value }
        if let value = settings["autoExportEnabled"] as? Bool { autoExportEnabled = value }
        if let value = settings["autoExportPath"] as? String { autoExportPath = value }
        if let value = settings["exportFormat"] as? String,
           let format = ExportFormat(rawValue: value) { exportFormat = format }
        if let value = settings["launchAtLogin"] as? Bool { launchAtLogin = value }
        if let value = settings["showDockIcon"] as? Bool { showDockIcon = value }
        if let value = settings["defaultView"] as? String,
           let view = DefaultView(rawValue: value) { defaultView = view }
        if let value = settings["minimizeToMenuBarOnClose"] as? Bool { minimizeToMenuBarOnClose = value }
        if let value = settings["debugMode"] as? Bool { debugMode = value }
        if let value = settings["customClaudePath"] as? String { customClaudePath = value }
        
        return true
    }
}

// MARK: - Supporting Types

enum TokenDisplayFormat: String, CaseIterable {
    case full = "full"
    case abbreviated = "abbreviated"
    case scientific = "scientific"
    
    var displayName: String {
        switch self {
        case .full: return "Full (1,234,567)"
        case .abbreviated: return "Abbreviated (1.2M)"
        case .scientific: return "Scientific (1.23e6)"
        }
    }
}

enum ChartTimeRangeSetting: String, CaseIterable {
    case last1Hour = "1hour"
    case last4Hours = "4hours"
    case last24Hours = "24hours"
    case last7Days = "7days"
    case last30Days = "30days"
    
    var displayName: String {
        switch self {
        case .last1Hour: return "Last 1 Hour"
        case .last4Hours: return "Last 4 Hours"
        case .last24Hours: return "Last 24 Hours"
        case .last7Days: return "Last 7 Days"
        case .last30Days: return "Last 30 Days"
        }
    }
    
    var minutes: Double {
        switch self {
        case .last1Hour: return 60
        case .last4Hours: return 240
        case .last24Hours: return 1440
        case .last7Days: return 10080
        case .last30Days: return 43200
        }
    }
}

enum ExportFormat: String, CaseIterable {
    case csv = "csv"
    case json = "json"
    case xlsx = "xlsx"
    
    var displayName: String {
        switch self {
        case .csv: return "CSV"
        case .json: return "JSON"
        case .xlsx: return "Excel (XLSX)"
        }
    }
    
    var fileExtension: String {
        return rawValue
    }
}

enum DefaultView: String, CaseIterable {
    case dashboard = "dashboard"
    case menuBar = "menubar"
    case minimized = "minimized"
    
    var displayName: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .menuBar: return "Menu Bar Only"
        case .minimized: return "Minimized"
        }
    }
}