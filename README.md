# Ticket for Claude Code
macOS native app to monitor claude code usage

## Reference
https://github.com/Maciek-roboblog/Claude-Code-Usage-Monitor

## Report for reference
⏺ Analysis: Mac Native App Feasibility for Claude Code Monitoring

Yes, creating a Mac native app in Swift is absolutely feasible. The current Python implementation provides an excellent foundation for understanding the requirements and data flow.

Key Findings:

Data Source: The monitoring relies on the ccusage npm package which reads local JSONL files from ~/.config/claude/ - no external APIs needed.

Core Architecture:
- File system monitoring of Claude's local data
- JSON parsing and token calculation
- Real-time UI updates with progress bars and burn rate analytics
- Timer-based refresh (3-second intervals)

Swift Implementation Advantages:

1. Native Performance: Better memory management and CPU efficiency
2. macOS Integration: Menu bar app, notifications, Dock integration
3. Modern UI: SwiftUI for beautiful, responsive interfaces
4. System APIs: File system watchers, notifications, background processing

Recommended Mac App Architecture:

Core Components:
- FileMonitor: Watch ~/.config/claude/ using FSEventStream
- DataParser: JSON parsing and token calculations (replacing ccusage dependency)
- UsageCalculator: Burn rate, predictions, session tracking
- ProgressTracker: Visual progress bars and analytics

UI Options:
- Menu Bar App: Discrete monitoring with quick stats
- Main Window: Detailed dashboard with charts and trends
- Notifications: Token limit warnings and session alerts

Swift Frameworks:
- Foundation for file operations and JSON parsing
- SwiftUI for modern UI components
- Charts (iOS 16+/macOS 13+) for usage visualization
- UserNotifications for alerts

The Python script at /Users/minho/workspace/side/Claude-Code-Usage-Monitor/ccusage_monitor.py:101-156 shows the burn rate calculation logic that can be directly translated to Swift, and the progress bar creation at
ccusage_monitor.py:37-72 demonstrates the UI requirements.

Conclusion: This is an excellent candidate for a Swift Mac app - the data is local, the logic is well-defined, and the native capabilities would significantly enhance the user experience.

# Requirements
- supported min macOS version: macOS 14+