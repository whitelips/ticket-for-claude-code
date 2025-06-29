import Foundation

// Real Claude Code data structures for ~/.claude/projects/**/*.jsonl files
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
    let uuid: String?
    let parentUuid: String?
    let version: String?
    let cwd: String?
    let requestId: String?
    
    enum CodingKeys: String, CodingKey {
        case timestamp
        case sessionId
        case type
        case message
        case uuid
        case parentUuid
        case version
        case cwd
        case requestId
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
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Parse current ~/.claude/projects/**/*.jsonl format
        for line in lines {
            guard let data = line.data(using: .utf8) else { continue }
            
            do {
                let logEntry = try decoder.decode(ClaudeLogEntry.self, from: data)
                
                // Only process assistant messages with usage data
                guard logEntry.type == "assistant",
                      let message = logEntry.message,
                      let usage = message.usage,
                      let model = message.model,
                      let uuid = logEntry.uuid else { continue }
                
                // Parse timestamp
                guard let date = dateFormatter.date(from: logEntry.timestamp) else { continue }
                
                let usageEntry = UsageEntry(
                    timestamp: date,
                    model: model,
                    inputTokens: usage.inputTokens,
                    outputTokens: usage.outputTokens,
                    sessionId: logEntry.sessionId,
                    requestId: logEntry.requestId,
                    messageId: message.id,
                    cacheCreationInputTokens: usage.cacheCreationInputTokens,
                    cacheReadInputTokens: usage.cacheReadInputTokens,
                    uuid: uuid,
                    parentUuid: logEntry.parentUuid,
                    version: logEntry.version,
                    cwd: logEntry.cwd
                )
                
                entries.append(usageEntry)
            } catch {
                // Skip malformed entries (normal for user messages and other entry types)
                continue
            }
        }
        
        print("📊 Parsed \(entries.count) usage entries from \(url.lastPathComponent)")
        
        // Add summary of total tokens parsed
        let totalInputTokens = entries.reduce(0) { $0 + $1.effectiveInputTokens }
        let totalOutputTokens = entries.reduce(0) { $0 + $1.outputTokens }
        print("  Total tokens: \(totalInputTokens) input, \(totalOutputTokens) output")
        
        return entries.sorted { $0.timestamp < $1.timestamp }
    }
    
    static func getAllJSONLFiles() -> [URL] {
        let fileManager = FileManager.default
        
        // First try to use security-scoped bookmark URL for ~/.claude/projects
        if var securityScopedURL = SecurityBookmarkService.shared.getClaudeFolderURL() {
            // Ensure we're pointing to the projects subdirectory
            if !securityScopedURL.path().contains(".claude/projects") {
                securityScopedURL.append(path: ".claude/projects")
            }
            print("Using security-scoped URL: \(securityScopedURL.path())")
            // Scan for JSONL files in the projects directory structure
            return scanProjectsDirectoryForJSONLFiles(at: securityScopedURL)
        }
        
        // Fallback to direct access (won't work in sandbox without permission)
        // Get real home directory instead of sandboxed container path
        guard let realHome = getRealHomeDirectory() else {
            print("❌ Could not get real home directory")
            return []
        }
        
        // Look for ~/.claude/projects directory structure
        let projectsPath = URL(fileURLWithPath: "\(realHome)/.claude/projects")
        
        guard fileManager.fileExists(atPath: projectsPath.path) else {
            print("❌ Claude projects directory not found at: \(projectsPath.path)")
            print("🏠 Home directory resolved to: \(fileManager.homeDirectoryForCurrentUser.path)")
            return []
        }
        
        print("Found Claude projects directory at: \(projectsPath.path)")
        
        var allJSONLFiles: [URL] = []
        
        do {
            // Get all project directories in ~/.claude/projects/
            let projectDirs = try fileManager.contentsOfDirectory(
                at: projectsPath,
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
            
            print("Found \(allJSONLFiles.count) total JSONL files")
            return allJSONLFiles.sorted { $0.lastPathComponent < $1.lastPathComponent }
            
        } catch {
            print("Failed to list directories: \(error)")
            return []
        }
    }
    
    // Helper method to scan ~/.claude/projects directory for JSONL files
    private static func scanProjectsDirectoryForJSONLFiles(at projectsURL: URL) -> [URL] {
        let fileManager = FileManager.default
        var allJSONLFiles: [URL] = []
        
        print("Scanning for JSONL files in: \(projectsURL.path)")
        
        do {
            // Get all project directories
            let projectDirs = try fileManager.contentsOfDirectory(
                at: projectsURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: .skipsHiddenFiles
            ).filter { url in
                (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
            }
            
            print("Found \(projectDirs.count) project directories")
            
            // Get JSONL files from each project directory
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
            
            print("Found \(allJSONLFiles.count) total JSONL files")
        } catch {
            print("Failed to scan projects directory: \(error)")
        }
        
        return allJSONLFiles.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }
}
