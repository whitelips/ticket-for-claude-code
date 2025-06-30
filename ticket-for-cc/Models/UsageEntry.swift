//
//  UsageEntry.swift
//  ticket-for-cc
//
//  Data model for individual usage records from Claude JSONL files
//

import Foundation

/// Token usage breakdown for a single Claude interaction
struct TokenUsage: Codable {
    let inputTokens: Int?
    let outputTokens: Int?
    let cacheCreationInputTokens: Int?
    let cacheReadInputTokens: Int?
    
    private enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case cacheCreationInputTokens = "cache_creation_input_tokens"
        case cacheReadInputTokens = "cache_read_input_tokens"
    }
    
    /// Total tokens used across all types
    var totalTokens: Int {
        (inputTokens ?? 0) + (outputTokens ?? 0) + 
        (cacheCreationInputTokens ?? 0) + 
        (cacheReadInputTokens ?? 0)
    }
    
    /// Check if this usage object has valid token data
    var isValid: Bool {
        inputTokens != nil || outputTokens != nil
    }
}

/// Message details from Claude interaction
struct UsageMessage: Codable {
    let usage: TokenUsage?
    let model: String?
    let id: String?
    
    /// Fallback properties for entries without usage data
    let type: String?
    let content: FlexibleContent?
    let role: String?
    
    /// Helper to get content as string regardless of original format
    var contentString: String? {
        content?.stringValue
    }
}

/// Flexible content that can be either a string or an array
enum FlexibleContent: Codable {
    case string(String)
    case array([ContentBlock])
    
    var stringValue: String? {
        switch self {
        case .string(let str):
            return str
        case .array(let blocks):
            // Convert array of content blocks to string representation
            return blocks.compactMap { block in
                switch block {
                case .text(let text):
                    return text
                case .other:
                    return nil
                }
            }.joined(separator: " ")
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let arrayValue = try? container.decode([ContentBlock].self) {
            self = .array(arrayValue)
        } else {
            // If both fail, try to decode as a generic array and convert to strings
            if let genericArray = try? container.decode([AnyCodable].self) {
                let blocks = genericArray.compactMap { item -> ContentBlock? in
                    if let dict = item.value as? [String: Any],
                       let type = dict["type"] as? String,
                       type == "text",
                       let text = dict["text"] as? String {
                        return .text(text)
                    }
                    return .other
                }
                self = .array(blocks)
            } else {
                throw DecodingError.typeMismatch(
                    FlexibleContent.self,
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Content must be either a string or an array"
                    )
                )
            }
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let str):
            try container.encode(str)
        case .array(let blocks):
            try container.encode(blocks)
        }
    }
}

/// Content block for array-based content
enum ContentBlock: Codable {
    case text(String)
    case other
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let type = try? container.decode(String.self, forKey: .type),
           type == "text",
           let text = try? container.decode(String.self, forKey: .text) {
            self = .text(text)
        } else {
            self = .other
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let text):
            try container.encode("text", forKey: .type)
            try container.encode(text, forKey: .text)
        case .other:
            try container.encode("other", forKey: .type)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case type, text
    }
}

/// Helper for decoding arbitrary JSON values
struct AnyCodable: Codable {
    let value: Any
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Cannot decode value")
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let arrayValue as [Any]:
            let codableArray = arrayValue.map { AnyCodable(value: $0) }
            try container.encode(codableArray)
        case let dictValue as [String: Any]:
            let codableDict = dictValue.mapValues { AnyCodable(value: $0) }
            try container.encode(codableDict)
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Cannot encode value")
            )
        }
    }
    
    init(value: Any) {
        self.value = value
    }
}

/// Raw usage entry as parsed from JSONL files
/// Matches the actual Claude Code data structure
struct UsageEntry: Codable, Identifiable {
    let timestampRaw: Date?
    let version: String?
    let messageRaw: UsageMessage?
    let costUSD: Double?
    let requestId: String?
    let sessionId: String?
    let uuid: String?
    let type: String?
    
    /// Timestamp for this entry, using current time as fallback if missing
    var timestamp: Date {
        timestampRaw ?? Date()
    }
    
    /// Message for this entry, providing empty message as fallback if missing
    var message: UsageMessage {
        messageRaw ?? UsageMessage(
            usage: nil,
            model: nil,
            id: nil,
            type: "unknown",
            content: nil,
            role: nil
        )
    }
    
    private enum CodingKeys: String, CodingKey {
        case timestampRaw = "timestamp"
        case version
        case messageRaw = "message"
        case costUSD
        case requestId
        case sessionId
        case uuid
        case type
    }
    
    /// Unique identifier using UUID if available, fallback to message+request ID
    var id: String {
        uuid ?? "\(message.id ?? "unknown")-\(requestId ?? "unknown")"
    }
    
    /// Total tokens from usage data
    var totalTokens: Int {
        message.usage?.totalTokens ?? 0
    }
    
    /// Model name, defaulting to "unknown" if not specified
    var model: String {
        message.model ?? "unknown"
    }
    
    /// Calculate cost using pre-calculated costUSD or model pricing
    var cost: Double {
        if let costUSD = costUSD {
            return costUSD
        }
        // Fall back to calculated pricing if costUSD not available
        if let modelName = message.model, let usage = message.usage, usage.isValid {
            return ModelPricingData.calculateCost(
                inputTokens: (usage.inputTokens ?? 0) + (usage.cacheCreationInputTokens ?? 0) + (usage.cacheReadInputTokens ?? 0),
                outputTokens: usage.outputTokens ?? 0,
                model: modelName
            )
        }
        return 0.0
    }
    
    // MARK: - Compatibility properties for legacy code
    
    /// Input tokens for backward compatibility
    var inputTokens: Int {
        message.usage?.inputTokens ?? 0
    }
    
    /// Output tokens for backward compatibility  
    var outputTokens: Int {
        message.usage?.outputTokens ?? 0
    }
    
    /// Cache creation tokens for backward compatibility
    var cacheCreationInputTokens: Int? {
        message.usage?.cacheCreationInputTokens
    }
    
    /// Cache read tokens for backward compatibility
    var cacheReadInputTokens: Int? {
        message.usage?.cacheReadInputTokens
    }
    
    /// Effective input tokens (including cache tokens)
    var effectiveInputTokens: Int {
        inputTokens + (cacheCreationInputTokens ?? 0) + (cacheReadInputTokens ?? 0)
    }
    
    /// Session ID from top-level field or fallback to message ID
    var sessionIdValue: String {
        sessionId ?? message.id ?? "unknown"
    }
    
    /// Check if this entry has valid usage data
    var hasUsageData: Bool {
        message.usage?.isValid == true
    }
    
    /// Parse from JSONL line with flexible date handling
    static func parse(from jsonString: String) throws -> UsageEntry {
        let decoder = JSONDecoder()
        
        // Use custom date decoding strategy to handle multiple formats
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try ISO8601 with milliseconds: "2024-06-30T14:30:45.123Z"
            let iso8601WithMs = ISO8601DateFormatter()
            iso8601WithMs.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso8601WithMs.date(from: dateString) {
                return date
            }
            
            // Try ISO8601 without milliseconds: "2024-06-30T14:30:45Z"
            let iso8601 = ISO8601DateFormatter()
            iso8601.formatOptions = [.withInternetDateTime]
            if let date = iso8601.date(from: dateString) {
                return date
            }
            
            // Try RFC3339 format: "2024-06-30T14:30:45.123+00:00"
            let rfc3339WithMs = DateFormatter()
            rfc3339WithMs.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
            rfc3339WithMs.locale = Locale(identifier: "en_US_POSIX")
            rfc3339WithMs.timeZone = TimeZone(secondsFromGMT: 0)
            if let date = rfc3339WithMs.date(from: dateString) {
                return date
            }
            
            // Try RFC3339 without milliseconds: "2024-06-30T14:30:45+00:00"
            let rfc3339 = DateFormatter()
            rfc3339.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
            rfc3339.locale = Locale(identifier: "en_US_POSIX")
            rfc3339.timeZone = TimeZone(secondsFromGMT: 0)
            if let date = rfc3339.date(from: dateString) {
                return date
            }
            
            // Try common variations: "2024-06-30 14:30:45"
            let spaceFormat = DateFormatter()
            spaceFormat.dateFormat = "yyyy-MM-dd HH:mm:ss"
            spaceFormat.locale = Locale(identifier: "en_US_POSIX")
            spaceFormat.timeZone = TimeZone(secondsFromGMT: 0)
            if let date = spaceFormat.date(from: dateString) {
                return date
            }
            
            // Try with microseconds: "2024-06-30T14:30:45.123456Z"
            let microsecondsFormat = DateFormatter()
            microsecondsFormat.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
            microsecondsFormat.locale = Locale(identifier: "en_US_POSIX")
            if let date = microsecondsFormat.date(from: dateString) {
                return date
            }
            
            // Try parsing as milliseconds since epoch
            if let timestamp = Double(dateString) {
                // Handle both seconds and milliseconds timestamps
                let date = timestamp > 1_000_000_000_000 ? 
                    Date(timeIntervalSince1970: timestamp / 1000) : // milliseconds
                    Date(timeIntervalSince1970: timestamp) // seconds
                return date
            }
            
            // If all formats fail, throw a descriptive error
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unable to parse date string: '\(dateString)'. Supported formats: ISO8601 with/without milliseconds, RFC3339, and Unix timestamps."
                )
            )
        }
        
        let data = jsonString.data(using: .utf8)!
        return try decoder.decode(UsageEntry.self, from: data)
    }
    
    /// Create a mock usage entry for testing
    static func mock(
        timestamp: Date = Date(),
        model: String = "claude-sonnet-4-20250514",
        inputTokens: Int = 1000,
        outputTokens: Int = 500,
        cacheCreationInputTokens: Int? = nil,
        cacheReadInputTokens: Int? = nil,
        costUSD: Double? = nil
    ) -> UsageEntry {
        let usage = TokenUsage(
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            cacheCreationInputTokens: cacheCreationInputTokens,
            cacheReadInputTokens: cacheReadInputTokens
        )
        
        let message = UsageMessage(
            usage: usage,
            model: model,
            id: UUID().uuidString,
            type: nil,
            content: nil,
            role: nil
        )
        
        return UsageEntry(
            timestampRaw: timestamp,
            version: "1.0.0",
            messageRaw: message,
            costUSD: costUSD,
            requestId: UUID().uuidString,
            sessionId: "test-session",
            uuid: UUID().uuidString,
            type: "assistant"
        )
    }
}