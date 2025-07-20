//
//  SettingsTypesTests.swift
//  ticket-for-ccTests
//
//  Unit tests for Settings supporting types
//

import XCTest
@testable import ticket_for_cc

class SettingsTypesTests: XCTestCase {
    
    // MARK: - MenuBarDisplayMode Tests
    
    func testMenuBarDisplayModeRawValues() {
        XCTAssertEqual(MenuBarDisplayMode.tokens.rawValue, "tokens")
        XCTAssertEqual(MenuBarDisplayMode.cost.rawValue, "cost")
    }
    
    func testMenuBarDisplayModeInitFromRawValue() {
        XCTAssertEqual(MenuBarDisplayMode(rawValue: "tokens"), .tokens)
        XCTAssertEqual(MenuBarDisplayMode(rawValue: "cost"), .cost)
        XCTAssertNil(MenuBarDisplayMode(rawValue: "invalid"))
    }
    
    func testMenuBarDisplayModeDisplayNames() {
        XCTAssertEqual(MenuBarDisplayMode.tokens.displayName, "Tokens")
        XCTAssertEqual(MenuBarDisplayMode.cost.displayName, "Cost")
    }
    
    func testMenuBarDisplayModeAllCases() {
        let allCases = MenuBarDisplayMode.allCases
        XCTAssertEqual(allCases.count, 2)
        XCTAssertTrue(allCases.contains(.tokens))
        XCTAssertTrue(allCases.contains(.cost))
    }
    
    // MARK: - TokenDisplayFormat Tests
    
    func testTokenDisplayFormatRawValues() {
        XCTAssertEqual(TokenDisplayFormat.full.rawValue, "full")
        XCTAssertEqual(TokenDisplayFormat.abbreviated.rawValue, "abbreviated")
        XCTAssertEqual(TokenDisplayFormat.scientific.rawValue, "scientific")
    }
    
    func testTokenDisplayFormatInitFromRawValue() {
        XCTAssertEqual(TokenDisplayFormat(rawValue: "full"), .full)
        XCTAssertEqual(TokenDisplayFormat(rawValue: "abbreviated"), .abbreviated)
        XCTAssertEqual(TokenDisplayFormat(rawValue: "scientific"), .scientific)
        XCTAssertNil(TokenDisplayFormat(rawValue: "invalid"))
    }
    
    func testTokenDisplayFormatDisplayNames() {
        XCTAssertEqual(TokenDisplayFormat.full.displayName, "Full (1,234,567)")
        XCTAssertEqual(TokenDisplayFormat.abbreviated.displayName, "Abbreviated (1.2M)")
        XCTAssertEqual(TokenDisplayFormat.scientific.displayName, "Scientific (1.23e6)")
    }
    
    func testTokenDisplayFormatAllCases() {
        let allCases = TokenDisplayFormat.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.full))
        XCTAssertTrue(allCases.contains(.abbreviated))
        XCTAssertTrue(allCases.contains(.scientific))
    }
    
    // MARK: - ChartTimeRangeSetting Tests
    
    func testChartTimeRangeSettingRawValues() {
        XCTAssertEqual(ChartTimeRangeSetting.last1Hour.rawValue, "1hour")
        XCTAssertEqual(ChartTimeRangeSetting.last4Hours.rawValue, "4hours")
        XCTAssertEqual(ChartTimeRangeSetting.last24Hours.rawValue, "24hours")
        XCTAssertEqual(ChartTimeRangeSetting.last7Days.rawValue, "7days")
        XCTAssertEqual(ChartTimeRangeSetting.last30Days.rawValue, "30days")
    }
    
    func testChartTimeRangeSettingInitFromRawValue() {
        XCTAssertEqual(ChartTimeRangeSetting(rawValue: "1hour"), .last1Hour)
        XCTAssertEqual(ChartTimeRangeSetting(rawValue: "4hours"), .last4Hours)
        XCTAssertEqual(ChartTimeRangeSetting(rawValue: "24hours"), .last24Hours)
        XCTAssertEqual(ChartTimeRangeSetting(rawValue: "7days"), .last7Days)
        XCTAssertEqual(ChartTimeRangeSetting(rawValue: "30days"), .last30Days)
        XCTAssertNil(ChartTimeRangeSetting(rawValue: "invalid"))
    }
    
    func testChartTimeRangeSettingDisplayNames() {
        XCTAssertEqual(ChartTimeRangeSetting.last1Hour.displayName, "Last 1 Hour")
        XCTAssertEqual(ChartTimeRangeSetting.last4Hours.displayName, "Last 4 Hours")
        XCTAssertEqual(ChartTimeRangeSetting.last24Hours.displayName, "Last 24 Hours")
        XCTAssertEqual(ChartTimeRangeSetting.last7Days.displayName, "Last 7 Days")
        XCTAssertEqual(ChartTimeRangeSetting.last30Days.displayName, "Last 30 Days")
    }
    
    func testChartTimeRangeSettingMinutes() {
        XCTAssertEqual(ChartTimeRangeSetting.last1Hour.minutes, 60)
        XCTAssertEqual(ChartTimeRangeSetting.last4Hours.minutes, 240)
        XCTAssertEqual(ChartTimeRangeSetting.last24Hours.minutes, 1440)
        XCTAssertEqual(ChartTimeRangeSetting.last7Days.minutes, 10080)
        XCTAssertEqual(ChartTimeRangeSetting.last30Days.minutes, 43200)
    }
    
    func testChartTimeRangeSettingAllCases() {
        let allCases = ChartTimeRangeSetting.allCases
        XCTAssertEqual(allCases.count, 5)
        XCTAssertTrue(allCases.contains(.last1Hour))
        XCTAssertTrue(allCases.contains(.last4Hours))
        XCTAssertTrue(allCases.contains(.last24Hours))
        XCTAssertTrue(allCases.contains(.last7Days))
        XCTAssertTrue(allCases.contains(.last30Days))
    }
    
    // MARK: - ExportFormat Tests
    
    func testExportFormatRawValues() {
        XCTAssertEqual(ExportFormat.csv.rawValue, "csv")
        XCTAssertEqual(ExportFormat.json.rawValue, "json")
        XCTAssertEqual(ExportFormat.xlsx.rawValue, "xlsx")
    }
    
    func testExportFormatInitFromRawValue() {
        XCTAssertEqual(ExportFormat(rawValue: "csv"), .csv)
        XCTAssertEqual(ExportFormat(rawValue: "json"), .json)
        XCTAssertEqual(ExportFormat(rawValue: "xlsx"), .xlsx)
        XCTAssertNil(ExportFormat(rawValue: "invalid"))
    }
    
    func testExportFormatDisplayNames() {
        XCTAssertEqual(ExportFormat.csv.displayName, "CSV")
        XCTAssertEqual(ExportFormat.json.displayName, "JSON")
        XCTAssertEqual(ExportFormat.xlsx.displayName, "Excel (XLSX)")
    }
    
    func testExportFormatFileExtensions() {
        XCTAssertEqual(ExportFormat.csv.fileExtension, "csv")
        XCTAssertEqual(ExportFormat.json.fileExtension, "json")
        XCTAssertEqual(ExportFormat.xlsx.fileExtension, "xlsx")
    }
    
    func testExportFormatAllCases() {
        let allCases = ExportFormat.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.csv))
        XCTAssertTrue(allCases.contains(.json))
        XCTAssertTrue(allCases.contains(.xlsx))
    }
    
    // MARK: - DefaultView Tests
    
    func testDefaultViewRawValues() {
        XCTAssertEqual(DefaultView.dashboard.rawValue, "dashboard")
        XCTAssertEqual(DefaultView.menuBar.rawValue, "menubar")
        XCTAssertEqual(DefaultView.minimized.rawValue, "minimized")
    }
    
    func testDefaultViewInitFromRawValue() {
        XCTAssertEqual(DefaultView(rawValue: "dashboard"), .dashboard)
        XCTAssertEqual(DefaultView(rawValue: "menubar"), .menuBar)
        XCTAssertEqual(DefaultView(rawValue: "minimized"), .minimized)
        XCTAssertNil(DefaultView(rawValue: "invalid"))
    }
    
    func testDefaultViewDisplayNames() {
        XCTAssertEqual(DefaultView.dashboard.displayName, "Dashboard")
        XCTAssertEqual(DefaultView.menuBar.displayName, "Menu Bar Only")
        XCTAssertEqual(DefaultView.minimized.displayName, "Minimized")
    }
    
    func testDefaultViewAllCases() {
        let allCases = DefaultView.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.dashboard))
        XCTAssertTrue(allCases.contains(.menuBar))
        XCTAssertTrue(allCases.contains(.minimized))
    }
}