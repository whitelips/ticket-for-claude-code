# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a planning repository for a macOS native app called "Ticket for Claude Code" - a Swift-based application to monitor Claude Code usage. The project is currently in the conceptual phase with no implementation code yet.

## Project Goals

- Monitor Claude Code token usage by reading local JSONL files from `~/.config/claude/`
- Provide real-time burn rate analytics and session tracking
- Create a native macOS menu bar application with SwiftUI interface
- Replace Python-based monitoring tools with native Swift implementation

## Target Platform

- **Minimum macOS Version**: macOS 14+
- **Language**: Swift
- **UI Framework**: SwiftUI
- **Architecture**: Native macOS app with menu bar integration

## Reference Implementation

The project is based on analysis of the Python implementation at:
https://github.com/Maciek-roboblog/Claude-Code-Usage-Monitor

Key architectural components to implement:
- `FileMonitor`: Watch `~/.config/claude/` using FSEventStream
- `DataParser`: JSON parsing and token calculations  
- `UsageCalculator`: Burn rate predictions and session tracking
- `ProgressTracker`: Visual progress bars and analytics

## Development Environment

This is a Swift/Xcode project as indicated by the `.gitignore` file containing Xcode-specific patterns. When implementing:

- Use Xcode for development
- Follow Swift Package Manager conventions
- Leverage native macOS frameworks:
  - Foundation for file operations and JSON parsing
  - SwiftUI for UI components
  - Charts framework for usage visualization
  - UserNotifications for alerts
  - FSEventStream for file system monitoring

## Key Features to Implement

- 3-second refresh intervals for real-time monitoring
- Menu bar integration for discrete monitoring
- Main dashboard window with detailed analytics
- Token limit warnings and session alerts
- Progress bars showing usage against limits