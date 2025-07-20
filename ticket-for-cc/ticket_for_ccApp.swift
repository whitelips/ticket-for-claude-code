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
        // Configure app activation policy based on settings
        if Settings.shared.showDockIcon {
            NSApp.setActivationPolicy(.regular)
        } else {
            NSApp.setActivationPolicy(.accessory)
        }
        
        // Initialize menu bar controller
        menuBarController = MenuBarController()
        menuBarController?.startMonitoring()
        
        // Respect user's default view setting
        DispatchQueue.main.async {
            // First, hide any automatically shown windows
            for window in NSApp.windows {
                if window.title == "Dashboard" {
                    window.orderOut(nil)
                }
            }
            
            // Then show dashboard window only if user wants it
            switch Settings.shared.defaultView {
            case .dashboard:
                // Show dashboard window
                if let window = NSApp.windows.first(where: { $0.title == "Dashboard" }) {
                    window.makeKeyAndOrderFront(nil)
                }
            case .menuBar:
                // Menu bar only - don't show any window
                break
            case .minimized:
                // Start minimized - don't show any window
                break
            }
        }
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
                .frame(minWidth: 800, idealWidth: 900, maxWidth: .infinity, minHeight: 600, idealHeight: 650, maxHeight: .infinity)
        }
        .handlesExternalEvents(matching: Set(arrayLiteral: "dashboard"))
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    if let appDelegate = NSApp.delegate as? AppDelegate {
                        appDelegate.menuBarController?.openSettings()
                    }
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}
