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
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        let claudeConfigURL = homeURL.appendingPathComponent(".config/claude")
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: claudeConfigURL,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )
            
            return fileURLs.filter { $0.pathExtension == "jsonl" }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }
        } catch {
            print("Failed to list files in ~/.config/claude: \(error)")
            return []
        }
    }
}