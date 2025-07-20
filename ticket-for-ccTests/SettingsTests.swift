//
//  SettingsTests.swift
//  ticket-for-ccTests
//
//  Unit tests for Settings functionality
//

import XCTest
import SwiftUI
@testable import ticket_for_cc

class SettingsTests: XCTestCase {
    
    var settings: ticket_for_cc.Settings!
    
    override func setUp() {
        super.setUp()
        settings = ticket_for_cc.Settings.shared
        settings.resetToDefaults()
    }
    
    override func tearDown() {
        settings.resetToDefaults()
        super.tearDown()
    }
    
    // MARK: - Menu Bar Settings Tests
    
    func testMenuBarDisplayMode() {
        XCTAssertEqual(settings.menuBarDisplayMode, .tokens, "Default should be tokens")
        
        settings.menuBarDisplayMode = .cost
        XCTAssertEqual(settings.menuBarDisplayMode, .cost, "Should update to cost")
        
        settings.menuBarDisplayMode = .tokens
        XCTAssertEqual(settings.menuBarDisplayMode, .tokens, "Should update back to tokens")
    }
    
    func testMenuBarRefreshInterval() {
        XCTAssertEqual(settings.menuBarRefreshInterval, 3.0, "Default should be 3 seconds")
        
        settings.menuBarRefreshInterval = 5.5
        XCTAssertEqual(settings.menuBarRefreshInterval, 5.5, "Should update to 5.5 seconds")
        
        settings.menuBarRefreshInterval = 10.0
        XCTAssertEqual(settings.menuBarRefreshInterval, 10.0, "Should accept maximum value")
        
        settings.menuBarRefreshInterval = 1.0
        XCTAssertEqual(settings.menuBarRefreshInterval, 1.0, "Should accept minimum value")
    }
    
    func testShowMenuBarBurnRate() {
        XCTAssertTrue(settings.showMenuBarBurnRate, "Default should be true")
        
        settings.showMenuBarBurnRate = false
        XCTAssertFalse(settings.showMenuBarBurnRate, "Should update to false")
        
        settings.showMenuBarBurnRate = true
        XCTAssertTrue(settings.showMenuBarBurnRate, "Should update back to true")
    }
    
    // MARK: - Dashboard Settings Tests
    
    func testDashboardRefreshInterval() {
        XCTAssertEqual(settings.dashboardRefreshInterval, 5.0, "Default should be 5 seconds")
        
        settings.dashboardRefreshInterval = 15.0
        XCTAssertEqual(settings.dashboardRefreshInterval, 15.0, "Should update to 15 seconds")
        
        settings.dashboardRefreshInterval = 30.0
        XCTAssertEqual(settings.dashboardRefreshInterval, 30.0, "Should accept maximum value")
        
        settings.dashboardRefreshInterval = 1.0
        XCTAssertEqual(settings.dashboardRefreshInterval, 1.0, "Should accept minimum value")
    }
    
    func testShowInactiveSessionsByDefault() {
        XCTAssertFalse(settings.showInactiveSessionsByDefault, "Default should be false")
        
        settings.showInactiveSessionsByDefault = true
        XCTAssertTrue(settings.showInactiveSessionsByDefault, "Should update to true")
        
        settings.showInactiveSessionsByDefault = false
        XCTAssertFalse(settings.showInactiveSessionsByDefault, "Should update back to false")
    }
    
    func testTokenDisplayFormat() {
        XCTAssertEqual(settings.tokenDisplayFormat, .abbreviated, "Default should be abbreviated")
        
        settings.tokenDisplayFormat = .full
        XCTAssertEqual(settings.tokenDisplayFormat, .full, "Should update to full")
        
        settings.tokenDisplayFormat = .scientific
        XCTAssertEqual(settings.tokenDisplayFormat, .scientific, "Should update to scientific")
        
        settings.tokenDisplayFormat = .abbreviated
        XCTAssertEqual(settings.tokenDisplayFormat, .abbreviated, "Should update back to abbreviated")
    }
    
    func testCostDecimalPlaces() {
        XCTAssertEqual(settings.costDecimalPlaces, 3, "Default should be 3")
        
        settings.costDecimalPlaces = 4
        XCTAssertEqual(settings.costDecimalPlaces, 4, "Should update to 4")
        
        settings.costDecimalPlaces = 6
        XCTAssertEqual(settings.costDecimalPlaces, 6, "Should accept maximum value")
        
        settings.costDecimalPlaces = 2
        XCTAssertEqual(settings.costDecimalPlaces, 2, "Should accept minimum value")
    }
    
    func testChartTimeRange() {
        XCTAssertEqual(settings.chartTimeRange, .last4Hours, "Default should be last 4 hours")
        
        settings.chartTimeRange = .last24Hours
        XCTAssertEqual(settings.chartTimeRange, .last24Hours, "Should update to last 24 hours")
        
        settings.chartTimeRange = .last30Days
        XCTAssertEqual(settings.chartTimeRange, .last30Days, "Should update to last 30 days")
        
        settings.chartTimeRange = .last1Hour
        XCTAssertEqual(settings.chartTimeRange, .last1Hour, "Should update to last 1 hour")
    }
    
    // MARK: - Notification Settings Tests
    
    func testEnableUsageAlerts() {
        XCTAssertTrue(settings.enableUsageAlerts, "Default should be true")
        
        settings.enableUsageAlerts = false
        XCTAssertFalse(settings.enableUsageAlerts, "Should update to false")
        
        settings.enableUsageAlerts = true
        XCTAssertTrue(settings.enableUsageAlerts, "Should update back to true")
    }
    
    func testDailyLimitWarningThreshold() {
        XCTAssertEqual(settings.dailyLimitWarningThreshold, 0.8, "Default should be 80%")
        
        settings.dailyLimitWarningThreshold = 0.9
        XCTAssertEqual(settings.dailyLimitWarningThreshold, 0.9, "Should update to 90%")
        
        settings.dailyLimitWarningThreshold = 0.95
        XCTAssertEqual(settings.dailyLimitWarningThreshold, 0.95, "Should accept maximum value")
        
        settings.dailyLimitWarningThreshold = 0.5
        XCTAssertEqual(settings.dailyLimitWarningThreshold, 0.5, "Should accept minimum value")
    }
    
    func testMonthlyLimitWarningThreshold() {
        XCTAssertEqual(settings.monthlyLimitWarningThreshold, 0.8, "Default should be 80%")
        
        settings.monthlyLimitWarningThreshold = 0.85
        XCTAssertEqual(settings.monthlyLimitWarningThreshold, 0.85, "Should update to 85%")
        
        settings.monthlyLimitWarningThreshold = 0.95
        XCTAssertEqual(settings.monthlyLimitWarningThreshold, 0.95, "Should accept maximum value")
        
        settings.monthlyLimitWarningThreshold = 0.5
        XCTAssertEqual(settings.monthlyLimitWarningThreshold, 0.5, "Should accept minimum value")
    }
    
    func testHighBurnRateThreshold() {
        XCTAssertEqual(settings.highBurnRateThreshold, 100000, "Default should be 100,000")
        
        settings.highBurnRateThreshold = 50000
        XCTAssertEqual(settings.highBurnRateThreshold, 50000, "Should update to 50,000")
        
        settings.highBurnRateThreshold = 200000
        XCTAssertEqual(settings.highBurnRateThreshold, 200000, "Should update to 200,000")
    }
    
    func testEnableSessionEndNotifications() {
        XCTAssertFalse(settings.enableSessionEndNotifications, "Default should be false")
        
        settings.enableSessionEndNotifications = true
        XCTAssertTrue(settings.enableSessionEndNotifications, "Should update to true")
        
        settings.enableSessionEndNotifications = false
        XCTAssertFalse(settings.enableSessionEndNotifications, "Should update back to false")
    }
    
    // MARK: - Data Settings Tests
    
    func testDataRetentionDays() {
        XCTAssertEqual(settings.dataRetentionDays, 30, "Default should be 30 days")
        
        settings.dataRetentionDays = 60
        XCTAssertEqual(settings.dataRetentionDays, 60, "Should update to 60 days")
        
        settings.dataRetentionDays = 365
        XCTAssertEqual(settings.dataRetentionDays, 365, "Should accept maximum value")
        
        settings.dataRetentionDays = 7
        XCTAssertEqual(settings.dataRetentionDays, 7, "Should accept minimum value")
    }
    
    func testAutoExportEnabled() {
        XCTAssertFalse(settings.autoExportEnabled, "Default should be false")
        
        settings.autoExportEnabled = true
        XCTAssertTrue(settings.autoExportEnabled, "Should update to true")
        
        settings.autoExportEnabled = false
        XCTAssertFalse(settings.autoExportEnabled, "Should update back to false")
    }
    
    func testAutoExportPath() {
        XCTAssertEqual(settings.autoExportPath, "", "Default should be empty")
        
        let testPath = "/Users/test/exports"
        settings.autoExportPath = testPath
        XCTAssertEqual(settings.autoExportPath, testPath, "Should update to test path")
        
        settings.autoExportPath = ""
        XCTAssertEqual(settings.autoExportPath, "", "Should update back to empty")
    }
    
    func testExportFormat() {
        XCTAssertEqual(settings.exportFormat, .csv, "Default should be CSV")
        
        settings.exportFormat = .json
        XCTAssertEqual(settings.exportFormat, .json, "Should update to JSON")
        
        settings.exportFormat = .xlsx
        XCTAssertEqual(settings.exportFormat, .xlsx, "Should update to XLSX")
        
        settings.exportFormat = .csv
        XCTAssertEqual(settings.exportFormat, .csv, "Should update back to CSV")
    }
    
    // MARK: - Behavior Settings Tests
    
    func testLaunchAtLogin() {
        XCTAssertFalse(settings.launchAtLogin, "Default should be false")
        
        settings.launchAtLogin = true
        XCTAssertTrue(settings.launchAtLogin, "Should update to true")
        
        settings.launchAtLogin = false
        XCTAssertFalse(settings.launchAtLogin, "Should update back to false")
    }
    
    func testShowDockIcon() {
        XCTAssertTrue(settings.showDockIcon, "Default should be true")
        
        settings.showDockIcon = false
        XCTAssertFalse(settings.showDockIcon, "Should update to false")
        
        settings.showDockIcon = true
        XCTAssertTrue(settings.showDockIcon, "Should update back to true")
    }
    
    func testDefaultView() {
        XCTAssertEqual(settings.defaultView, .dashboard, "Default should be dashboard")
        
        settings.defaultView = .menuBar
        XCTAssertEqual(settings.defaultView, .menuBar, "Should update to menu bar")
        
        settings.defaultView = .minimized
        XCTAssertEqual(settings.defaultView, .minimized, "Should update to minimized")
        
        settings.defaultView = .dashboard
        XCTAssertEqual(settings.defaultView, .dashboard, "Should update back to dashboard")
    }
    
    func testMinimizeToMenuBarOnClose() {
        XCTAssertTrue(settings.minimizeToMenuBarOnClose, "Default should be true")
        
        settings.minimizeToMenuBarOnClose = false
        XCTAssertFalse(settings.minimizeToMenuBarOnClose, "Should update to false")
        
        settings.minimizeToMenuBarOnClose = true
        XCTAssertTrue(settings.minimizeToMenuBarOnClose, "Should update back to true")
    }
    
    // MARK: - Advanced Settings Tests
    
    func testDebugMode() {
        XCTAssertFalse(settings.debugMode, "Default should be false")
        
        settings.debugMode = true
        XCTAssertTrue(settings.debugMode, "Should update to true")
        
        settings.debugMode = false
        XCTAssertFalse(settings.debugMode, "Should update back to false")
    }
    
    func testCustomClaudePath() {
        XCTAssertEqual(settings.customClaudePath, "", "Default should be empty")
        
        let customPath = "/custom/claude/path"
        settings.customClaudePath = customPath
        XCTAssertEqual(settings.customClaudePath, customPath, "Should update to custom path")
        
        settings.customClaudePath = ""
        XCTAssertEqual(settings.customClaudePath, "", "Should update back to empty")
    }
    
    // MARK: - Reset to Defaults Test
    
    func testResetToDefaults() {
        // Change all settings
        settings.menuBarDisplayMode = .cost
        settings.menuBarRefreshInterval = 7.0
        settings.showMenuBarBurnRate = false
        settings.dashboardRefreshInterval = 20.0
        settings.showInactiveSessionsByDefault = true
        settings.tokenDisplayFormat = .scientific
        settings.costDecimalPlaces = 5
        settings.chartTimeRange = .last30Days
        settings.enableUsageAlerts = false
        settings.dailyLimitWarningThreshold = 0.9
        settings.monthlyLimitWarningThreshold = 0.95
        settings.highBurnRateThreshold = 50000
        settings.enableSessionEndNotifications = true
        settings.dataRetentionDays = 90
        settings.autoExportEnabled = true
        settings.autoExportPath = "/test/path"
        settings.exportFormat = .xlsx
        settings.launchAtLogin = true
        settings.showDockIcon = false
        settings.defaultView = .minimized
        settings.minimizeToMenuBarOnClose = false
        settings.debugMode = true
        settings.customClaudePath = "/custom/path"
        
        // Reset all
        settings.resetToDefaults()
        
        // Verify all are back to defaults
        XCTAssertEqual(settings.menuBarDisplayMode, .tokens)
        XCTAssertEqual(settings.menuBarRefreshInterval, 3.0)
        XCTAssertTrue(settings.showMenuBarBurnRate)
        XCTAssertEqual(settings.dashboardRefreshInterval, 5.0)
        XCTAssertFalse(settings.showInactiveSessionsByDefault)
        XCTAssertEqual(settings.tokenDisplayFormat, .abbreviated)
        XCTAssertEqual(settings.costDecimalPlaces, 3)
        XCTAssertEqual(settings.chartTimeRange, .last4Hours)
        XCTAssertTrue(settings.enableUsageAlerts)
        XCTAssertEqual(settings.dailyLimitWarningThreshold, 0.8)
        XCTAssertEqual(settings.monthlyLimitWarningThreshold, 0.8)
        XCTAssertEqual(settings.highBurnRateThreshold, 100000)
        XCTAssertFalse(settings.enableSessionEndNotifications)
        XCTAssertEqual(settings.dataRetentionDays, 30)
        XCTAssertFalse(settings.autoExportEnabled)
        XCTAssertEqual(settings.autoExportPath, "")
        XCTAssertEqual(settings.exportFormat, .csv)
        XCTAssertFalse(settings.launchAtLogin)
        XCTAssertTrue(settings.showDockIcon)
        XCTAssertEqual(settings.defaultView, .dashboard)
        XCTAssertTrue(settings.minimizeToMenuBarOnClose)
        XCTAssertFalse(settings.debugMode)
        XCTAssertEqual(settings.customClaudePath, "")
    }
    
    // MARK: - Export/Import Settings Tests
    
    func testExportSettings() {
        // Set some custom values
        settings.menuBarDisplayMode = .cost
        settings.dashboardRefreshInterval = 10.0
        settings.enableUsageAlerts = false
        settings.customClaudePath = "/test/path"
        
        // Export settings
        let exportedData = settings.exportSettings()
        XCTAssertNotNil(exportedData, "Export should return data")
        
        // Verify exported data is valid JSON
        if let data = exportedData {
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            XCTAssertNotNil(json, "Exported data should be valid JSON")
            
            // Verify some values
            XCTAssertEqual(json?["menuBarDisplayMode"] as? String, "cost")
            XCTAssertEqual(json?["dashboardRefreshInterval"] as? Double, 10.0)
            XCTAssertEqual(json?["enableUsageAlerts"] as? Bool, false)
            XCTAssertEqual(json?["customClaudePath"] as? String, "/test/path")
        }
    }
    
    func testImportSettings() {
        // Create test data
        let testSettings: [String: Any] = [
            "menuBarDisplayMode": "cost",
            "menuBarRefreshInterval": 8.0,
            "showMenuBarBurnRate": false,
            "dashboardRefreshInterval": 15.0,
            "tokenDisplayFormat": "scientific",
            "enableUsageAlerts": false,
            "highBurnRateThreshold": 75000,
            "exportFormat": "json",
            "launchAtLogin": true,
            "debugMode": true
        ]
        
        guard let importData = try? JSONSerialization.data(withJSONObject: testSettings) else {
            XCTFail("Failed to create test data")
            return
        }
        
        // Import settings
        let success = settings.importSettings(from: importData)
        XCTAssertTrue(success, "Import should succeed")
        
        // Verify imported values
        XCTAssertEqual(settings.menuBarDisplayMode, .cost)
        XCTAssertEqual(settings.menuBarRefreshInterval, 8.0)
        XCTAssertFalse(settings.showMenuBarBurnRate)
        XCTAssertEqual(settings.dashboardRefreshInterval, 15.0)
        XCTAssertEqual(settings.tokenDisplayFormat, .scientific)
        XCTAssertFalse(settings.enableUsageAlerts)
        XCTAssertEqual(settings.highBurnRateThreshold, 75000)
        XCTAssertEqual(settings.exportFormat, .json)
        XCTAssertTrue(settings.launchAtLogin)
        XCTAssertTrue(settings.debugMode)
    }
    
    func testImportInvalidData() {
        let invalidData = "not valid json".data(using: .utf8)!
        let success = settings.importSettings(from: invalidData)
        XCTAssertFalse(success, "Import should fail with invalid data")
    }
}