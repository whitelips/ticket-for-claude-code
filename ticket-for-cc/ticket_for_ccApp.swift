//
//  ticket_for_ccApp.swift
//  ticket-for-cc
//
//  Ticket for Claude Code - macOS menu bar app for monitoring Claude usage
//

import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarController: MenuBarController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure app to run as menu bar app
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize menu bar controller
        menuBarController = MenuBarController()
        menuBarController?.startMonitoring()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up
        menuBarController = nil
    }
}

@main
struct ticket_for_ccApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Main dashboard window (hidden by default for menu bar app)
        WindowGroup("Dashboard") {
            DashboardView()
                .frame(minWidth: 1000, minHeight: 700)
        }
        .handlesExternalEvents(matching: Set(arrayLiteral: "dashboard"))
        .defaultSize(width: 1200, height: 800)
        
        // Settings window
        Settings {
            SettingsView()
                .frame(width: 400, height: 300)
        }
    }
}
