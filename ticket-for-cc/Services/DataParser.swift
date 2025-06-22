import Foundation

// Real Claude Code data structure
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
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
        
        var entries: [UsageEntry] = []
        let decoder = JSONDecoder()
        let dateFormatter = ISO8601DateFormatter()
        
        for line in lines {
            guard let data = line.data(using: .utf8) else { continue }
            
            do {
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
                    outputTokens: usage.outputTokens
                )
                
                entries.append(usageEntry)
            } catch {
                // Skip malformed entries (this is normal for user messages)
                continue
            }
        }
        
        return entries.sorted { $0.timestamp < $1.timestamp }
    }
    
    static func getAllJSONLFiles() -> [URL] {
        let fileManager = FileManager.default
        let homeURL = fileManager.homeDirectoryForCurrentUser
        
        // Claude Code stores data in ~/.claude/projects/
        let claudeProjectsURL = homeURL.appendingPathComponent(".claude/projects")
        
        guard fileManager.fileExists(atPath: claudeProjectsURL.path) else {
            print("Claude projects directory not found at: \(claudeProjectsURL.path)")
            return []
        }
        
        var allJSONLFiles: [URL] = []
        
        do {
            // Get all project directories
            let projectDirs = try fileManager.contentsOfDirectory(
                at: claudeProjectsURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: .skipsHiddenFiles
            ).filter { url in
                (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
            }
            
            print("Found \(projectDirs.count) project directories")
            
            // Get all JSONL files from each project directory
            for projectDir in projectDirs {
                do {
                    let jsonlFiles = try fileManager.contentsOfDirectory(
                        at: projectDir,
                        includingPropertiesForKeys: nil,
                        options: .skipsHiddenFiles
                    ).filter { $0.pathExtension == "jsonl" }
                    
                    allJSONLFiles.append(contentsOf: jsonlFiles)
                } catch {
                    print("Failed to list files in \(projectDir.path): \(error)")
                }
            }
            
            print("Found \(allJSONLFiles.count) total JSONL files")
            return allJSONLFiles.sorted { $0.lastPathComponent < $1.lastPathComponent }
            
        } catch {
            print("Failed to list project directories: \(error)")
            return []
        }
    }
}