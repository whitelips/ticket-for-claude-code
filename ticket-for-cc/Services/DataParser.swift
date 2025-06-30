//
//  DataParser.swift
//  ticket-for-cc
//
//  Service for parsing JSONL files containing Claude usage data
//

import Foundation
import os.log

class DataParser {
    private let logger = Logger(subsystem: "com.ticket-for-cc", category: "DataParser")
    
    /// Set to track processed entries for deduplication
    private var processedEntries = Set<String>()
    
    /// Parse a JSONL file matching ccusage format
    func parseJSONLFile(at url: URL) throws -> [UsageEntry] {
        // Ensure we have access to security-scoped resource if needed
        let shouldStopAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.split(separator: "\n", omittingEmptySubsequences: true)
        
        var entries: [UsageEntry] = []
        
        for (index, line) in lines.enumerated() {
            do {
                let entry = try UsageEntry.parse(from: String(line))
                
                // Skip if we've already processed this entry (deduplication)
                if !processedEntries.contains(entry.id) {
                    processedEntries.insert(entry.id)
                    // Only include entries that have usage data (skip conversation messages, etc.)
                    if entry.hasUsageData {
                        entries.append(entry)
                    } else {
                        logger.debug("Skipping entry without usage data at line \(index + 1) in \(url.lastPathComponent)")
                    }
                }
            } catch {
                // Log error but continue processing other lines
                logger.debug("Failed to parse line \(index + 1) in \(url.lastPathComponent): \(error)")
            }
        }
        
        logger.info("📊 Parsed \(entries.count) usage entries from \(url.lastPathComponent)")
        
        return entries.sorted { $0.timestamp < $1.timestamp }
    }
    
    /// Get Claude data directories to search (supports both ~/.config/claude and ~/.claude)
    func getClaudePaths() -> [String] {
        var paths: [String] = []
        
        // First try to use security-scoped bookmark URLs
        if let securityScopedURL = SecurityBookmarkService.shared.getClaudeFolderURL() {
            let claudePaths = findClaudeDirectoriesInSecurityScope(securityScopedURL)
            paths.append(contentsOf: claudePaths)
        }
        
        // Get real user home directory (not sandboxed)
        let homeDir = getRealHomeDirectory()
        
        // Check both new and old default paths
        let defaultPaths = [
            "\(homeDir)/.config/claude",  // New default (XDG)
            "\(homeDir)/.claude"          // Old default
        ]
        
        for path in defaultPaths {
            let projectsPath = URL(fileURLWithPath: path).appendingPathComponent("projects")
            if FileManager.default.fileExists(atPath: projectsPath.path) {
                paths.append(path)
            }
        }
        
        // Remove duplicates while preserving order
        var uniquePaths: [String] = []
        var seen = Set<String>()
        for path in paths {
            let normalized = URL(fileURLWithPath: path).standardized.path
            if !seen.contains(normalized) {
                seen.insert(normalized)
                uniquePaths.append(path)
            }
        }
        
        return uniquePaths
    }
    
    /// Get all JSONL files from Claude directories
    func getAllJSONLFiles() -> [URL] {
        let paths = getClaudePaths()
        var allJSONLFiles: [URL] = []
        
        for path in paths {
            let projectsURL = URL(fileURLWithPath: path).appendingPathComponent("projects")
            let files = scanProjectsDirectoryForJSONLFiles(at: projectsURL)
            allJSONLFiles.append(contentsOf: files)
        }
        
        // Remove duplicates based on file path
        var uniqueFiles: [URL] = []
        var seen = Set<String>()
        for file in allJSONLFiles {
            let normalized = file.standardized.path
            if !seen.contains(normalized) {
                seen.insert(normalized)
                uniqueFiles.append(file)
            }
        }
        
        return uniqueFiles.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }
    
    /// Get session ID and project path from file URL
    /// Format: ~/.config/claude/projects/{project}/{session}/{file}.jsonl
    func extractSessionInfo(from url: URL) -> (sessionId: String, projectPath: String)? {
        let pathComponents = url.pathComponents
        
        // Find the index of "projects" directory
        guard let projectsIndex = pathComponents.firstIndex(of: "projects"),
              projectsIndex + 2 < pathComponents.count else {
            return nil
        }
        
        let projectName = pathComponents[projectsIndex + 1]
        let sessionId = pathComponents[projectsIndex + 2]
        
        return (sessionId: sessionId, projectPath: projectName)
    }
    
    /// Load all usage data from Claude directories
    func loadAllUsageData(from paths: [String]) async throws -> [UsageEntry] {
        var allEntries: [UsageEntry] = []
        
        for path in paths {
            let projectsPath = URL(fileURLWithPath: path).appendingPathComponent("projects")
            
            guard FileManager.default.fileExists(atPath: projectsPath.path) else {
                logger.debug("Projects directory not found at: \(projectsPath.path)")
                continue
            }
            
            let files = scanProjectsDirectoryForJSONLFiles(at: projectsPath)
            
            for file in files {
                do {
                    let entries = try parseJSONLFile(at: file)
                    allEntries.append(contentsOf: entries)
                } catch {
                    logger.error("Failed to parse file \(file.lastPathComponent): \(error)")
                }
            }
        }
        
        // Sort by timestamp
        return allEntries.sorted { $0.timestamp < $1.timestamp }
    }
    
    /// Reset processed entries set (useful for refreshing data)
    func resetDeduplication() {
        processedEntries.removeAll()
    }
    
    /// Get the real user home directory (not sandboxed container)
    private func getRealHomeDirectory() -> String {
        // First try NSHomeDirectory() which should return real home even in sandbox
        let nsHomeDir = NSHomeDirectory()
        if !nsHomeDir.contains("Containers") {
            return nsHomeDir
        }
        
        // Fallback: Use environment variable
        if let homeFromEnv = ProcessInfo.processInfo.environment["HOME"] {
            return homeFromEnv
        }
        
        // Last resort: Try to extract from current path by looking for /Users/username pattern
        let currentPath = nsHomeDir
        if let range = currentPath.range(of: "/Users/[^/]+", options: .regularExpression) {
            return String(currentPath[range])
        }
        
        // Absolute fallback
        return nsHomeDir
    }
    
    /// Find Claude directories within a security-scoped URL
    private func findClaudeDirectoriesInSecurityScope(_ securityScopedURL: URL) -> [String] {
        var claudePaths: [String] = []
        
        logger.info("🔍 Searching for Claude directories in security-scoped URL: \(securityScopedURL.path)")
        
        // Start accessing security-scoped resource
        let shouldStopAccessing = securityScopedURL.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccessing {
                securityScopedURL.stopAccessingSecurityScopedResource()
            }
        }
        
        let fileManager = FileManager.default
        let urlName = securityScopedURL.lastPathComponent
        
        // Case 1: The selected URL itself is a Claude directory
        if urlName == ".claude" || urlName == "claude" {
            let projectsPath = securityScopedURL.appendingPathComponent("projects")
            if fileManager.fileExists(atPath: projectsPath.path) {
                logger.info("✅ Security-scoped URL is Claude directory: \(securityScopedURL.path)")
                claudePaths.append(securityScopedURL.path)
                return claudePaths
            }
        }
        
        // Case 2: Search for Claude directories within the selected folder
        let candidateSubpaths = [
            ".claude",
            ".config/claude", 
            "claude",
            ".local/share/claude",
            "Library/Application Support/claude"
        ]
        
        for subpath in candidateSubpaths {
            let claudeURL = securityScopedURL.appendingPathComponent(subpath)
            let projectsURL = claudeURL.appendingPathComponent("projects")
            
            if fileManager.fileExists(atPath: projectsURL.path) {
                logger.info("✅ Found Claude directory in security scope: \(claudeURL.path)")
                claudePaths.append(claudeURL.path)
            }
        }
        
        if claudePaths.isEmpty {
            logger.warning("⚠️ No Claude directories found in security-scoped URL: \(securityScopedURL.path)")
        }
        
        return claudePaths
    }
    
    // Helper method to scan projects directory for JSONL files
    private func scanProjectsDirectoryForJSONLFiles(at projectsURL: URL) -> [URL] {
        let fileManager = FileManager.default
        var allJSONLFiles: [URL] = []
        
        logger.info("Scanning for JSONL files in: \(projectsURL.path)")
        
        // Start accessing security-scoped resource if needed
        let shouldStopAccessing = projectsURL.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccessing {
                projectsURL.stopAccessingSecurityScopedResource()
            }
        }
        
        guard FileManager.default.fileExists(atPath: projectsURL.path) else {
            logger.debug("Projects directory not found at: \(projectsURL.path)")
            return []
        }
        
        do {
            // Use enumerator for recursive search
            let enumerator = fileManager.enumerator(
                at: projectsURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            )
            
            while let url = enumerator?.nextObject() as? URL {
                if url.pathExtension == "jsonl" {
                    allJSONLFiles.append(url)
                }
            }
            
            logger.info("Found \(allJSONLFiles.count) total JSONL files")
        } catch {
            logger.error("Failed to scan projects directory: \(error)")
        }
        
        return allJSONLFiles.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }
}
