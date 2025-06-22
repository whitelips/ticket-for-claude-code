import Foundation

struct ClaudeLogEntry: Codable {
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
                
                // Parse timestamp
                guard let date = dateFormatter.date(from: logEntry.timestamp) else { continue }
                
                let usageEntry = UsageEntry(
                    timestamp: date,
                    model: logEntry.model,
                    inputTokens: logEntry.inputTokens,
                    outputTokens: logEntry.outputTokens
                )
                
                entries.append(usageEntry)
            } catch {
                // Skip malformed entries
                print("Failed to parse line: \(error)")
                continue
            }
        }
        
        return entries.sorted { $0.timestamp < $1.timestamp }
    }
    
    static func getAllJSONLFiles() -> [URL] {
        let fileManager = FileManager.default
        let homeURL = fileManager.homeDirectoryForCurrentUser
        
        // Check multiple possible locations
        let possiblePaths = [
            ".config/claude",
            ".claude-code",
            "Library/Application Support/Claude",
            "Library/Application Support/claude-code",
            ".local/share/claude",
            ".cache/claude"
        ]
        
        for path in possiblePaths {
            let claudeURL = homeURL.appendingPathComponent(path)
            
            if fileManager.fileExists(atPath: claudeURL.path) {
                print("Found Claude directory at: \(claudeURL.path)")
                
                do {
                    let fileURLs = try fileManager.contentsOfDirectory(
                        at: claudeURL,
                        includingPropertiesForKeys: nil,
                        options: .skipsHiddenFiles
                    )
                    
                    let jsonlFiles = fileURLs.filter { $0.pathExtension == "jsonl" }
                        .sorted { $0.lastPathComponent < $1.lastPathComponent }
                    
                    if !jsonlFiles.isEmpty {
                        print("Found \(jsonlFiles.count) JSONL files")
                        return jsonlFiles
                    }
                } catch {
                    print("Failed to list files in \(claudeURL.path): \(error)")
                }
            }
        }
        
        print("No Claude data directory found. Checked paths: \(possiblePaths)")
        return []
    }
}