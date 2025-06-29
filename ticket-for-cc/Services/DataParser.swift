import Foundation

// Real Claude Code data structures

// New format (daily usage files)
struct ClaudeUsageLogEntry: Codable {
    let timestamp: String
    let conversationId: String
    let inputTokens: Int
    let outputTokens: Int
    let model: String
    
    enum CodingKeys: String, CodingKey {
        case timestamp
        case conversationId = "conversation_id"
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case model
    }
}

// Old format (project conversation files)
struct ClaudeMessage: Codable {
    let id: String?
    let role: String
    let model: String?
    let usage: ClaudeUsage?
}

struct ClaudeUsage: Codable {
    let inputTokens: Int
    let outputTokens: Int
    let cacheCreationInputTokens: Int?
    let cacheReadInputTokens: Int?
    
    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case cacheCreationInputTokens = "cache_creation_input_tokens"
        case cacheReadInputTokens = "cache_read_input_tokens"
    }
}

struct ClaudeLogEntry: Codable {
    let timestamp: String
    let sessionId: String
    let type: String
    let message: ClaudeMessage?
    let uuid: String
    
    enum CodingKeys: String, CodingKey {
        case timestamp
        case sessionId
        case type
        case message
        case uuid
    }
}

class DataParser {
    static func parseJSONLFile(at url: URL) throws -> [UsageEntry] {
        // Ensure we have access to security-scoped resource if needed
        let shouldStopAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
        
        var entries: [UsageEntry] = []
        let decoder = JSONDecoder()
        let dateFormatter = ISO8601DateFormatter()
        
        // Determine file format by checking the first line
        guard let firstLine = lines.first,
              let firstData = firstLine.data(using: .utf8) else {
            return []
        }
        
        let isNewFormat = firstLine.contains("conversation_id") && firstLine.contains("input_tokens")
        
        for line in lines {
            guard let data = line.data(using: .utf8) else { continue }
            
            do {
                if isNewFormat {
                    // Parse new format (daily usage files)
                    let usageEntry = try decoder.decode(ClaudeUsageLogEntry.self, from: data)
                    
                    guard let date = dateFormatter.date(from: usageEntry.timestamp) else { continue }
                    
                    let entry = UsageEntry(
                        timestamp: date,
                        model: usageEntry.model,
                        inputTokens: usageEntry.inputTokens,
                        outputTokens: usageEntry.outputTokens,
                        sessionId: usageEntry.conversationId,
                        requestId: nil,
                        messageId: nil
                    )
                    
                    entries.append(entry)
                } else {
                    // Parse old format (project conversation files)
                    let logEntry = try decoder.decode(ClaudeLogEntry.self, from: data)
                    
                    // Only process assistant messages with usage data
                    guard logEntry.type == "assistant",
                          let message = logEntry.message,
                          let usage = message.usage,
                          let model = message.model else { continue }
                    
                    // Parse timestamp
                    guard let date = dateFormatter.date(from: logEntry.timestamp) else { continue }
                    
                    let usageEntry = UsageEntry(
                        timestamp: date,
                        model: model,
                        inputTokens: usage.inputTokens + (usage.cacheCreationInputTokens ?? 0) + (usage.cacheReadInputTokens ?? 0),
                        outputTokens: usage.outputTokens,
                        sessionId: logEntry.sessionId,
                        requestId: nil, // Could extract from requestId field if needed
                        messageId: message.id
                    )
                    
                    entries.append(usageEntry)
                }
            } catch {
                // Skip malformed entries (this is normal for user messages in old format)
                continue
            }
        }
        
        return entries.sorted { $0.timestamp < $1.timestamp }
    }
    
    static func getAllJSONLFiles() -> [URL] {
        let fileManager = FileManager.default
        
        // First try to use security-scoped bookmark URL
        if let securityScopedURL = SecurityBookmarkService.shared.getClaudeFolderURL() {
            print("Using security-scoped URL: \(securityScopedURL.path)")
            // Since user selected the folder, we'll search within it
            return scanDirectoryForJSONLFiles(at: securityScopedURL)
        }
        
        // Fallback to direct access (won't work in sandbox without permission)
        // Get real home directory instead of sandboxed container path
        guard let realHome = getRealHomeDirectory() else {
            print("❌ Could not get real home directory")
            return []
        }
        
        // Use real home directory paths to avoid sandboxing issues
        let possiblePaths = [
            // New location (Claude Code v1.0.30+)
            URL(fileURLWithPath: "\(realHome)/.config/claude"),
            // Old location (previous versions)
            URL(fileURLWithPath: "\(realHome)/.claude/projects"),
            // Alternative location
            URL(fileURLWithPath: "\(realHome)/.claude")
        ]
        
        var claudeDataURL: URL?
        var isProjectsDir = false
        
        for path in possiblePaths {
            if fileManager.fileExists(atPath: path.path) {
                print("Found Claude data directory at: \(path.path)")
                claudeDataURL = path
                isProjectsDir = path.lastPathComponent == "projects"
                break
            }
        }
        
        guard let dataURL = claudeDataURL else {
            print("❌ Claude data directory not found. Checked paths:")
            for path in possiblePaths {
                let exists = fileManager.fileExists(atPath: path.path)
                print("  - \(path.path) (exists: \(exists))")
            }
            
            // Also check what the home directory actually is
            print("🏠 Home directory resolved to: \(fileManager.homeDirectoryForCurrentUser.path)")
            
            return []
        }
        
        var allJSONLFiles: [URL] = []
        
        do {
            if isProjectsDir {
                // Handle old format: ~/.claude/projects/
                let projectDirs = try fileManager.contentsOfDirectory(
                    at: dataURL,
                    includingPropertiesForKeys: [.isDirectoryKey],
                    options: .skipsHiddenFiles
                ).filter { url in
                    (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
                }
                
                // Get all JSONL files from each project directory
                print("Found \(projectDirs.count) project directories")
                for projectDir in projectDirs {
                    do {
                        let jsonlFiles = try fileManager.contentsOfDirectory(
                            at: projectDir,
                            includingPropertiesForKeys: nil,
                            options: .skipsHiddenFiles
                        ).filter { $0.pathExtension == "jsonl" }
                        
                        if !jsonlFiles.isEmpty {
                            print("  Project: \(projectDir.lastPathComponent) - \(jsonlFiles.count) JSONL files")
                        }
                        
                        allJSONLFiles.append(contentsOf: jsonlFiles)
                    } catch {
                        print("Failed to list files in \(projectDir.path): \(error)")
                    }
                }
            } else {
                // Handle new format: ~/.config/claude/ or ~/.claude/
                // Look for both project subdirectories and direct JSONL files
                let contents = try fileManager.contentsOfDirectory(
                    at: dataURL,
                    includingPropertiesForKeys: [.isDirectoryKey],
                    options: .skipsHiddenFiles
                )
                
                // Check for projects subdirectory
                let projectsDir = dataURL.appendingPathComponent("projects")
                if fileManager.fileExists(atPath: projectsDir.path) {
                    let projectDirs = try fileManager.contentsOfDirectory(
                        at: projectsDir,
                        includingPropertiesForKeys: [.isDirectoryKey],
                        options: .skipsHiddenFiles
                    ).filter { url in
                        (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
                    }
                    
                    for projectDir in projectDirs {
                        let jsonlFiles = try fileManager.contentsOfDirectory(
                            at: projectDir,
                            includingPropertiesForKeys: nil,
                            options: .skipsHiddenFiles
                        ).filter { $0.pathExtension == "jsonl" }
                        
                        allJSONLFiles.append(contentsOf: jsonlFiles)
                    }
                }
                
                // Also check for direct JSONL files (daily usage files)
                let directJSONLFiles = contents.filter { $0.pathExtension == "jsonl" }
                allJSONLFiles.append(contentsOf: directJSONLFiles)
            }
            
            print("Found \(allJSONLFiles.count) total JSONL files")
            return allJSONLFiles.sorted { $0.lastPathComponent < $1.lastPathComponent }
            
        } catch {
            print("Failed to list directories: \(error)")
            return []
        }
    }
    
    // Helper method to recursively scan a directory for JSONL files
    private static func scanDirectoryForJSONLFiles(at url: URL) -> [URL] {
        let fileManager = FileManager.default
        var allJSONLFiles: [URL] = []
        
        // Helper function to recursively scan directories
        func scanDirectory(_ directoryURL: URL, depth: Int = 0) {
            // Limit recursion depth to prevent infinite loops
            guard depth < 5 else { return }
            
            do {
                let contents = try fileManager.contentsOfDirectory(
                    at: directoryURL,
                    includingPropertiesForKeys: [.isDirectoryKey],
                    options: .skipsHiddenFiles
                )
                
                for itemURL in contents {
                    if let resourceValues = try? itemURL.resourceValues(forKeys: [.isDirectoryKey]),
                       let isDirectory = resourceValues.isDirectory {
                        if isDirectory {
                            // Recursively scan subdirectories
                            scanDirectory(itemURL, depth: depth + 1)
                        } else if itemURL.pathExtension == "jsonl" {
                            // Found a JSONL file
                            allJSONLFiles.append(itemURL)
                        }
                    }
                }
            } catch {
                print("Failed to scan directory \(directoryURL.path): \(error)")
            }
        }
        
        // Start scanning from the root URL
        print("Scanning for JSONL files in: \(url.path)")
        scanDirectory(url)
        
        // Log what we found
        if !allJSONLFiles.isEmpty {
            print("Found \(allJSONLFiles.count) JSONL files:")
            // Group by parent directory for better logging
            let groupedByParent = Dictionary(grouping: allJSONLFiles) { $0.deletingLastPathComponent().path }
            for (parent, files) in groupedByParent {
                let relativePath = parent.replacingOccurrences(of: url.path, with: ".")
                print("  \(relativePath): \(files.count) files")
            }
        }
        
        return allJSONLFiles.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }
}