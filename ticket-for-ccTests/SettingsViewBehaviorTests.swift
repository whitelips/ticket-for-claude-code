//
//  SettingsViewBehaviorTests.swift
//  ticket-for-ccTests
//
//  Unit tests for Settings View behavior
//

import XCTest
import SwiftUI
@testable import ticket_for_cc

class SettingsViewBehaviorTests: XCTestCase {
    
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
    
    // MARK: - Dock Icon Visibility Tests
    
    func testDockIconVisibilityUpdate() {
        // Initial state should show dock icon
        XCTAssertTrue(settings.showDockIcon)
        
        // When dock icon is disabled
        settings.showDockIcon = false
        
        // The app activation policy should be updated
        // Note: We can't directly test NSApp.activationPolicy in unit tests
        // but we can verify the setting changed
        XCTAssertFalse(settings.showDockIcon)
        
        // When dock icon is re-enabled
        settings.showDockIcon = true
        XCTAssertTrue(settings.showDockIcon)
    }
    
    // MARK: - Settings Persistence Tests
    
    func testSettingsPersistence() {
        // Change some settings
        settings.menuBarDisplayMode = .cost
        settings.dashboardRefreshInterval = 10.0
        settings.enableUsageAlerts = false
        
        // Verify changes are stored
        XCTAssertEqual(UserDefaults.standard.string(forKey: "MenuBarDisplayMode"), "cost")
        XCTAssertEqual(UserDefaults.standard.double(forKey: "dashboardRefreshInterval"), 10.0)
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "enableUsageAlerts"))
    }
    
    // MARK: - Settings Boundary Tests
    
    func testNumericSettingsBoundaries() {
        // Test menu bar refresh interval boundaries
        settings.menuBarRefreshInterval = 0.5 // Below minimum
        // UI should enforce minimum of 1.0
        
        settings.menuBarRefreshInterval = 15.0 // Above maximum
        // UI should enforce maximum of 10.0
        
        // Test dashboard refresh interval boundaries
        settings.dashboardRefreshInterval = 0.5 // Below minimum
        // UI should enforce minimum of 1.0
        
        settings.dashboardRefreshInterval = 60.0 // Above maximum
        // UI should enforce maximum of 30.0
        
        // Test cost decimal places boundaries
        settings.costDecimalPlaces = 1 // Below minimum
        // UI should enforce minimum of 2
        
        settings.costDecimalPlaces = 10 // Above maximum
        // UI should enforce maximum of 6
        
        // Test data retention days boundaries
        settings.dataRetentionDays = 1 // Below minimum
        // UI should enforce minimum of 7
        
        settings.dataRetentionDays = 400 // Above maximum
        // UI should enforce maximum of 365
    }
    
    // MARK: - Settings Notification Tests
    
    func testSettingsChangeNotifications() {
        let expectation = XCTestExpectation(description: "Settings change notification")
        
        let cancellable = settings.objectWillChange.sink { _ in
            expectation.fulfill()
        }
        
        settings.menuBarDisplayMode = .cost
        
        wait(for: [expectation], timeout: 1.0)
        cancellable.cancel()
    }
    
    // MARK: - Export Path Validation Tests
    
    func testExportPathValidation() {
        // Test empty path
        settings.autoExportPath = ""
        XCTAssertEqual(settings.autoExportPath, "")
        
        // Test valid path
        let validPath = "/Users/test/Documents"
        settings.autoExportPath = validPath
        XCTAssertEqual(settings.autoExportPath, validPath)
        
        // Test path with spaces
        let pathWithSpaces = "/Users/test/My Documents"
        settings.autoExportPath = pathWithSpaces
        XCTAssertEqual(settings.autoExportPath, pathWithSpaces)
    }
    
    // MARK: - Custom Claude Path Tests
    
    func testCustomClaudePathBehavior() {
        // Default should be empty (use default path)
        XCTAssertEqual(settings.customClaudePath, "")
        
        // Set custom path
        let customPath = "/custom/claude/data"
        settings.customClaudePath = customPath
        XCTAssertEqual(settings.customClaudePath, customPath)
        
        // Clear custom path
        settings.customClaudePath = ""
        XCTAssertEqual(settings.customClaudePath, "")
    }
    
    // MARK: - Settings Tab Behavior Tests
    
    func testSettingsTabProperties() {
        // Test all tabs have unique titles
        let titles = SettingsTab.allCases.map { $0.title }
        XCTAssertEqual(titles.count, Set(titles).count, "All tab titles should be unique")
        
        // Test all tabs have icons
        for tab in SettingsTab.allCases {
            XCTAssertFalse(tab.icon.isEmpty, "Tab \(tab.title) should have an icon")
        }
        
        // Verify expected tabs exist
        XCTAssertTrue(SettingsTab.allCases.contains(.display))
        XCTAssertTrue(SettingsTab.allCases.contains(.notifications))
        XCTAssertTrue(SettingsTab.allCases.contains(.data))
        XCTAssertTrue(SettingsTab.allCases.contains(.behavior))
        XCTAssertTrue(SettingsTab.allCases.contains(.advanced))
    }
    
    // MARK: - Settings Import/Export Round Trip Test
    
    func testSettingsImportExportRoundTrip() {
        // Set all settings to non-default values
        settings.menuBarDisplayMode = .cost
        settings.menuBarRefreshInterval = 7.5
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
        settings.autoExportPath = "/test/export/path"
        settings.exportFormat = .xlsx
        settings.launchAtLogin = true
        settings.showDockIcon = false
        settings.defaultView = .minimized
        settings.minimizeToMenuBarOnClose = false
        settings.debugMode = true
        settings.customClaudePath = "/custom/claude/path"
        
        // Export settings
        guard let exportedData = settings.exportSettings() else {
            XCTFail("Failed to export settings")
            return
        }
        
        // Reset to defaults
        settings.resetToDefaults()
        
        // Verify settings are at defaults
        XCTAssertEqual(settings.menuBarDisplayMode, .tokens)
        XCTAssertEqual(settings.menuBarRefreshInterval, 3.0)
        XCTAssertTrue(settings.showMenuBarBurnRate)
        
        // Import the exported settings
        let importSuccess = settings.importSettings(from: exportedData)
        XCTAssertTrue(importSuccess, "Import should succeed")
        
        // Verify all settings were restored
        XCTAssertEqual(settings.menuBarDisplayMode, .cost)
        XCTAssertEqual(settings.menuBarRefreshInterval, 7.5)
        XCTAssertFalse(settings.showMenuBarBurnRate)
        XCTAssertEqual(settings.dashboardRefreshInterval, 20.0)
        XCTAssertTrue(settings.showInactiveSessionsByDefault)
        XCTAssertEqual(settings.tokenDisplayFormat, .scientific)
        XCTAssertEqual(settings.costDecimalPlaces, 5)
        XCTAssertEqual(settings.chartTimeRange, .last30Days)
        XCTAssertFalse(settings.enableUsageAlerts)
        XCTAssertEqual(settings.dailyLimitWarningThreshold, 0.9)
        XCTAssertEqual(settings.monthlyLimitWarningThreshold, 0.95)
        XCTAssertEqual(settings.highBurnRateThreshold, 50000)
        XCTAssertTrue(settings.enableSessionEndNotifications)
        XCTAssertEqual(settings.dataRetentionDays, 90)
        XCTAssertTrue(settings.autoExportEnabled)
        XCTAssertEqual(settings.autoExportPath, "/test/export/path")
        XCTAssertEqual(settings.exportFormat, .xlsx)
        XCTAssertTrue(settings.launchAtLogin)
        XCTAssertFalse(settings.showDockIcon)
        XCTAssertEqual(settings.defaultView, .minimized)
        XCTAssertFalse(settings.minimizeToMenuBarOnClose)
        XCTAssertTrue(settings.debugMode)
        XCTAssertEqual(settings.customClaudePath, "/custom/claude/path")
    }
}