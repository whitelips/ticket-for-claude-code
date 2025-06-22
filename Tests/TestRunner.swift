#!/usr/bin/env swift

import Foundation

// MARK: - Test Framework

class TestCase {
    var passed = 0
    var failed = 0
    var currentTest = ""
    
    func test(_ name: String, _ block: () throws -> Void) {
        currentTest = name
        print("🧪 Testing: \(name)")
        
        do {
            try block()
            passed += 1
            print("   ✅ Passed")
        } catch {
            failed += 1
            print("   ❌ Failed: \(error)")
        }
    }
    
    func assertEqual<T: Equatable>(_ actual: T, _ expected: T, file: String = #file, line: Int = #line) throws {
        if actual != expected {
            throw TestError.assertionFailed("Expected \(expected), got \(actual) at \(file):\(line)")
        }
    }
    
    func assertGreaterThan<T: Comparable>(_ actual: T, _ expected: T, file: String = #file, line: Int = #line) throws {
        if actual <= expected {
            throw TestError.assertionFailed("Expected \(actual) > \(expected) at \(file):\(line)")
        }
    }
    
    func assertNotNil<T>(_ value: T?, file: String = #file, line: Int = #line) throws {
        if value == nil {
            throw TestError.assertionFailed("Expected non-nil value at \(file):\(line)")
        }
    }
    
    func printSummary() {
        print("\n📊 Test Summary")
        print("===============")
        print("✅ Passed: \(passed)")
        print("❌ Failed: \(failed)")
        print("📈 Total: \(passed + failed)")
        
        if failed == 0 {
            print("\n🎉 All tests passed!")
        } else {
            print("\n⚠️  Some tests failed!")
        }
    }
}

enum TestError: Error {
    case assertionFailed(String)
}

// MARK: - Import App Code (simplified versions for testing)

struct UsageEntry {
    let id = UUID()
    let timestamp: Date
    let model: String
    let inputTokens: Int
    let outputTokens: Int
    let sessionId: String
    let requestId: String?
    let messageId: String?
    
    var totalTokens: Int { inputTokens + outputTokens }
    
    var cost: Double {
        ModelPricingData.calculateCost(
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            model: model
        )
    }
    
    init(timestamp: Date, model: String, inputTokens: Int, outputTokens: Int, sessionId: String, requestId: String? = nil, messageId: String? = nil) {
        self.timestamp = timestamp
        self.model = model
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.sessionId = sessionId
        self.requestId = requestId
        self.messageId = messageId
    }
}

struct ModelPricingData {
    static let pricing: [String: (input: Double, output: Double)] = [
        "claude-3-5-sonnet-20241022": (input: 3.0, output: 15.0),
        "claude-sonnet-4-20250514": (input: 3.0, output: 15.0),
        "claude-3-5-haiku-20241022": (input: 0.8, output: 4.0),
        "claude-opus-4-20250514": (input: 15.0, output: 75.0),
        "default": (input: 3.0, output: 15.0)
    ]
    
    static func calculateCost(inputTokens: Int, outputTokens: Int, model: String) -> Double {
        let pricing = self.pricing[model] ?? self.pricing["default"]!
        let inputCost = (Double(inputTokens) / 1_000_000.0) * pricing.input
        let outputCost = (Double(outputTokens) / 1_000_000.0) * pricing.output
        return inputCost + outputCost
    }
}

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
}

// MARK: - Test Data

let testData = """
{"timestamp":"2025-06-22T10:00:00Z","sessionId":"test-session-1","type":"assistant","message":{"id":"msg_123","role":"assistant","model":"claude-3-5-sonnet-20241022","usage":{"input_tokens":1000,"output_tokens":2000}},"uuid":"uuid-1"}
{"timestamp":"2025-06-22T10:05:00Z","sessionId":"test-session-1","type":"user","message":{"role":"user"},"uuid":"uuid-2"}
{"timestamp":"2025-06-22T10:06:00Z","sessionId":"test-session-1","type":"assistant","message":{"id":"msg_124","role":"assistant","model":"claude-3-5-haiku-20241022","usage":{"input_tokens":500,"output_tokens":1000,"cache_creation_input_tokens":100}},"uuid":"uuid-3"}
{"timestamp":"2025-06-22T11:00:00Z","sessionId":"test-session-2","type":"assistant","message":{"id":"msg_125","role":"assistant","model":"claude-opus-4-20250514","usage":{"input_tokens":2000,"output_tokens":3000}},"uuid":"uuid-4"}
"""

// MARK: - Tests

let tests = TestCase()

// Test 1: Model Pricing
tests.test("Model Pricing Calculations") {
    // Test Sonnet pricing
    let sonnetCost = ModelPricingData.calculateCost(
        inputTokens: 1_000_000,
        outputTokens: 1_000_000,
        model: "claude-3-5-sonnet-20241022"
    )
    try tests.assertEqual(sonnetCost, 18.0) // $3 + $15 = $18
    
    // Test Haiku pricing
    let haikuCost = ModelPricingData.calculateCost(
        inputTokens: 1_000_000,
        outputTokens: 1_000_000,
        model: "claude-3-5-haiku-20241022"
    )
    try tests.assertEqual(haikuCost, 4.8) // $0.8 + $4 = $4.8
    
    // Test Opus pricing
    let opusCost = ModelPricingData.calculateCost(
        inputTokens: 1_000_000,
        outputTokens: 1_000_000,
        model: "claude-opus-4-20250514"
    )
    try tests.assertEqual(opusCost, 90.0) // $15 + $75 = $90
}

// Test 2: Data Parsing
tests.test("JSONL Data Parsing") {
    let lines = testData.components(separatedBy: .newlines).filter { !$0.isEmpty }
    var parsedEntries: [UsageEntry] = []
    let decoder = JSONDecoder()
    let dateFormatter = ISO8601DateFormatter()
    
    for line in lines {
        guard let data = line.data(using: .utf8) else { continue }
        
        do {
            let logEntry = try decoder.decode(ClaudeLogEntry.self, from: data)
            
            if logEntry.type == "assistant",
               let message = logEntry.message,
               let usage = message.usage,
               let model = message.model {
                
                guard let date = dateFormatter.date(from: logEntry.timestamp) else { continue }
                
                let usageEntry = UsageEntry(
                    timestamp: date,
                    model: model,
                    inputTokens: usage.inputTokens + (usage.cacheCreationInputTokens ?? 0),
                    outputTokens: usage.outputTokens,
                    sessionId: logEntry.sessionId,
                    requestId: nil,
                    messageId: message.id
                )
                
                parsedEntries.append(usageEntry)
            }
        } catch {
            // Skip invalid entries
        }
    }
    
    try tests.assertEqual(parsedEntries.count, 3)
    try tests.assertEqual(parsedEntries[0].model, "claude-3-5-sonnet-20241022")
    try tests.assertEqual(parsedEntries[0].inputTokens, 1000)
    try tests.assertEqual(parsedEntries[0].outputTokens, 2000)
    try tests.assertEqual(parsedEntries[1].inputTokens, 600) // 500 + 100 cache
}

// Test 3: Cost Calculations
tests.test("Usage Entry Cost Calculations") {
    let entry1 = UsageEntry(
        timestamp: Date(),
        model: "claude-3-5-sonnet-20241022",
        inputTokens: 10_000,
        outputTokens: 20_000,
        sessionId: "test"
    )
    
    let expectedCost = (10_000.0 / 1_000_000.0 * 3.0) + (20_000.0 / 1_000_000.0 * 15.0)
    try tests.assertEqual(entry1.cost, expectedCost)
    
    // Test total tokens
    try tests.assertEqual(entry1.totalTokens, 30_000)
}

// Test 4: Session Analytics
tests.test("Session Analytics") {
    let now = Date()
    let entries = [
        UsageEntry(timestamp: now, model: "claude-3-5-sonnet-20241022", inputTokens: 1000, outputTokens: 2000, sessionId: "session-1"),
        UsageEntry(timestamp: now.addingTimeInterval(300), model: "claude-3-5-sonnet-20241022", inputTokens: 500, outputTokens: 1000, sessionId: "session-1"),
        UsageEntry(timestamp: now.addingTimeInterval(3600), model: "claude-3-5-haiku-20241022", inputTokens: 2000, outputTokens: 3000, sessionId: "session-2")
    ]
    
    // Group by session
    let sessionGroups = Dictionary(grouping: entries) { $0.sessionId }
    try tests.assertEqual(sessionGroups.count, 2)
    try tests.assertEqual(sessionGroups["session-1"]?.count, 2)
    try tests.assertEqual(sessionGroups["session-2"]?.count, 1)
    
    // Calculate session totals
    let session1Total = sessionGroups["session-1"]?.reduce(0) { $0 + $1.totalTokens } ?? 0
    try tests.assertEqual(session1Total, 4500) // 1000+2000+500+1000
}

// Test 5: Date Filtering
tests.test("Date Filtering Logic") {
    let calendar = Calendar.current
    let now = Date()
    let today = calendar.startOfDay(for: now)
    let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
    let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!
    
    let entries = [
        UsageEntry(timestamp: yesterday, model: "claude-3-5-sonnet-20241022", inputTokens: 1000, outputTokens: 2000, sessionId: "old"),
        UsageEntry(timestamp: now, model: "claude-3-5-sonnet-20241022", inputTokens: 500, outputTokens: 1000, sessionId: "new"),
        UsageEntry(timestamp: weekAgo.addingTimeInterval(-86400), model: "claude-3-5-sonnet-20241022", inputTokens: 100, outputTokens: 200, sessionId: "very-old")
    ]
    
    // Filter today's entries
    let todayEntries = entries.filter { calendar.isDate($0.timestamp, inSameDayAs: today) }
    try tests.assertEqual(todayEntries.count, 1)
    
    // Filter recent entries (last 7 days)
    let recentEntries = entries.filter { $0.timestamp >= weekAgo }
    try tests.assertEqual(recentEntries.count, 2)
}

// Test 6: Real Data File Parsing
tests.test("Real Claude Data Directory") {
    let homeURL = FileManager.default.homeDirectoryForCurrentUser
    let claudeProjectsURL = homeURL.appendingPathComponent(".claude/projects")
    
    if FileManager.default.fileExists(atPath: claudeProjectsURL.path) {
        do {
            let projectDirs = try FileManager.default.contentsOfDirectory(
                at: claudeProjectsURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: .skipsHiddenFiles
            ).filter { url in
                (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
            }
            
            try tests.assertGreaterThan(projectDirs.count, 0)
            print("   📁 Found \(projectDirs.count) project directories")
            
            // Test parsing a real file
            var foundValidEntry = false
            for projectDir in projectDirs.prefix(1) {
                let jsonlFiles = try FileManager.default.contentsOfDirectory(
                    at: projectDir,
                    includingPropertiesForKeys: nil,
                    options: .skipsHiddenFiles
                ).filter { $0.pathExtension == "jsonl" }
                
                if let firstFile = jsonlFiles.first {
                    let content = try String(contentsOf: firstFile, encoding: .utf8)
                    let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
                    
                    for line in lines.prefix(10) {
                        if line.contains("\"type\":\"assistant\"") && line.contains("\"usage\"") {
                            foundValidEntry = true
                            break
                        }
                    }
                }
            }
            
            if foundValidEntry {
                print("   ✅ Found valid assistant entries in real data")
            }
        } catch {
            print("   ⚠️  Could not access Claude data: \(error)")
        }
    } else {
        print("   ℹ️  No Claude data directory found (expected for CI/testing)")
    }
}

// Run all tests
print("🚀 Running Ticket for Claude Code Tests")
print("=====================================\n")

tests.printSummary()

// Exit with appropriate code
exit(tests.failed > 0 ? 1 : 0)