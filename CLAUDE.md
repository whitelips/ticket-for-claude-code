# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a macOS native app called "Ticket for Claude Code" - a Swift-based application to monitor Claude Code usage by reading local JSONL files. The project uses SwiftUI and targets macOS 14+.

## Build and Development Commands

```bash
# Build the project
xcodebuild -project ticket-for-cc.xcodeproj -scheme ticket-for-cc build

# Run tests
xcodebuild test -project ticket-for-cc.xcodeproj -scheme ticket-for-cc

# Clean build
xcodebuild clean -project ticket-for-cc.xcodeproj -scheme ticket-for-cc

# Open in Xcode (recommended for development)
open ticket-for-cc.xcodeproj
```

## Architecture

### Data Flow
1. **File System Monitor** → Watches `~/.config/claude/` for JSONL file changes using FSEventStream
2. **Data Parser** → Reads and parses JSONL files containing Claude usage data
3. **Usage Calculator** → Computes token usage, burn rates, and session analytics
4. **UI Layer** → Updates menu bar and dashboard views with real-time data

### Core Components to Implement

#### FileMonitor
- Location: Create `ticket-for-cc/Services/FileMonitor.swift`
- Responsibility: FSEventStream wrapper to watch `~/.config/claude/` directory
- Key methods: `startMonitoring()`, `stopMonitoring()`, delegate callbacks for file changes

#### DataParser  
- Location: Create `ticket-for-cc/Services/DataParser.swift`
- Responsibility: Parse JSONL files and extract token usage information
- Data structure from JSONL files includes: timestamps, token counts, model types

#### UsageCalculator
- Location: Create `ticket-for-cc/Services/UsageCalculator.swift`
- Responsibility: Calculate burn rates, predictions, and usage trends
- Key calculations: tokens per hour, estimated time to limit, session totals

#### MenuBarController
- Location: Create `ticket-for-cc/Views/MenuBarController.swift`
- Responsibility: Manage menu bar item with quick stats and app controls
- Uses NSStatusItem for menu bar integration

### UI Structure

```
WindowGroup (Main App)
├── MenuBarView (NSStatusItem)
│   ├── Quick stats display
│   └── Menu with options
└── DashboardView (Main Window)
    ├── UsageOverviewView (current session stats)
    ├── BurnRateChartView (Charts framework)
    └── SessionHistoryView (list of past sessions)
```

### Data Models

Create models in `ticket-for-cc/Models/`:
- `UsageEntry.swift` - Individual usage record from JSONL
- `Session.swift` - Aggregated session data
- `BurnRate.swift` - Calculated burn rate metrics

### Key Implementation Notes

1. **File Access**: The app already has `com.apple.security.files.user-selected.read-only` entitlement. Add read access to `~/.config/claude/` in entitlements.

2. **Refresh Timer**: Use `Timer.publish(every: 3, on: .main, in: .common)` for 3-second updates.

3. **Progress Bars**: Use SwiftUI's `ProgressView` with custom styling for token usage visualization.

4. **Charts**: Import Charts framework (`import Charts`) for burn rate visualization - available in macOS 13+.

5. **Menu Bar**: Create menu bar app using `NSStatusItem` in AppDelegate or use packages like [LaunchAtLogin](https://github.com/sindresorhus/LaunchAtLogin).

## Reference Implementation Analysis

The Python implementation (https://github.com/Maciek-roboblog/Claude-Code-Usage-Monitor) shows:
- Burn rate calculation: tokens used / time elapsed * 3600 (tokens per hour)
- Progress bars showing: current usage vs daily/monthly limits  
- Session tracking with start time and cumulative tokens
- Real-time updates every 3 seconds

## Project Structure

```
ticket-for-cc/
├── ticket_for_ccApp.swift     # Main app entry (needs menu bar setup)
├── ContentView.swift          # Replace with DashboardView
├── Models/                    # Create this directory
├── Services/                  # Create this directory  
├── Views/                     # Create this directory
└── ticket_for_cc.entitlements # Update for file access