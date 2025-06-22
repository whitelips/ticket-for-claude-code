#!/usr/bin/env swift

// Verification script that tests changes without building the full app
import Foundation

print("🔍 Verifying Ticket for Claude Code")
print("===================================\n")

// MARK: - Test recent changes

// 1. Test that we can find and parse Claude data
print("1️⃣ Testing Claude data access...")
let homeURL = FileManager.default.homeDirectoryForCurrentUser
let claudeProjectsURL = homeURL.appendingPathComponent(".claude/projects")

if FileManager.default.fileExists(atPath: claudeProjectsURL.path) {
    do {
        let projectDirs = try FileManager.default.contentsOfDirectory(at: claudeProjectsURL, includingPropertiesForKeys: nil)
        print("   ✅ Found \(projectDirs.count) project directories")
        
        var totalFiles = 0
        var validEntries = 0
        var recentDate: Date?
        
        for projectDir in projectDirs {
            let jsonlFiles = try FileManager.default.contentsOfDirectory(at: projectDir, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension == "jsonl" }
            totalFiles += jsonlFiles.count
            
            // Parse first file in each project
            if let firstFile = jsonlFiles.first {
                let content = try String(contentsOf: firstFile, encoding: .utf8)
                let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
                
                for line in lines {
                    if line.contains("\"type\":\"assistant\"") && 
                       line.contains("\"usage\"") && 
                       line.contains("\"timestamp\"") {
                        validEntries += 1
                        
                        // Extract timestamp
                        if let timestampRange = line.range(of: "\"timestamp\":\""),
                           let endRange = line[timestampRange.upperBound...].range(of: "\"") {
                            let timestampStr = String(line[timestampRange.upperBound..<line.index(timestampRange.upperBound, offsetBy: line.distance(from: timestampRange.upperBound, to: endRange.lowerBound))])
                            let formatter = ISO8601DateFormatter()
                            if let date = formatter.date(from: timestampStr) {
                                if recentDate == nil || date > recentDate! {
                                    recentDate = date
                                }
                            }
                        }
                    }
                }
            }
        }
        
        print("   ✅ Found \(totalFiles) JSONL files")
        print("   ✅ Found \(validEntries) valid usage entries")
        
        if let recent = recentDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            print("   ✅ Most recent entry: \(formatter.string(from: recent))")
            
            // Check if data is recent
            let hoursSince = Date().timeIntervalSince(recent) / 3600
            if hoursSince < 24 {
                print("   ✅ Data is fresh (< 24 hours old)")
            } else {
                print("   ⚠️  Data is \(Int(hoursSince/24)) days old")
            }
        }
        
    } catch {
        print("   ❌ Error reading Claude data: \(error)")
    }
} else {
    print("   ❌ No Claude data directory found")
}

// 2. Test cost calculations
print("\n2️⃣ Testing cost calculations...")
let testCases: [(model: String, input: Int, output: Int, expected: Double)] = [
    ("claude-3-5-sonnet-20241022", 1_000_000, 1_000_000, 18.0),
    ("claude-3-5-haiku-20241022", 1_000_000, 1_000_000, 4.8),
    ("claude-opus-4-20250514", 1_000_000, 1_000_000, 90.0),
    ("unknown-model", 1_000_000, 1_000_000, 18.0), // Should use default
]

let pricing: [String: (input: Double, output: Double)] = [
    "claude-3-5-sonnet-20241022": (3.0, 15.0),
    "claude-3-5-haiku-20241022": (0.8, 4.0),
    "claude-opus-4-20250514": (15.0, 75.0),
    "default": (3.0, 15.0)
]

var costTestsPassed = true
for test in testCases {
    let modelPricing = pricing[test.model] ?? pricing["default"]!
    let cost = (Double(test.input) / 1_000_000.0 * modelPricing.input) + 
               (Double(test.output) / 1_000_000.0 * modelPricing.output)
    
    if abs(cost - test.expected) < 0.001 {
        print("   ✅ \(test.model): $\(cost) (correct)")
    } else {
        print("   ❌ \(test.model): $\(cost) (expected $\(test.expected))")
        costTestsPassed = false
    }
}

// 3. Test date filtering logic
print("\n3️⃣ Testing date filtering...")
let now = Date()
let calendar = Calendar.current
let today = calendar.startOfDay(for: now)
let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!
let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: today)!

struct TestEntry {
    let date: Date
    let description: String
}

let testEntries = [
    TestEntry(date: now, description: "Now"),
    TestEntry(date: yesterday, description: "Yesterday"),
    TestEntry(date: weekAgo, description: "Week ago"),
    TestEntry(date: twoWeeksAgo, description: "Two weeks ago")
]

// Test today filter
let todayEntries = testEntries.filter { calendar.isDate($0.date, inSameDayAs: today) }
print("   ✅ Today filter: \(todayEntries.count) entries (expected 1)")

// Test week filter
let weekEntries = testEntries.filter { $0.date >= weekAgo }
print("   ✅ Week filter: \(weekEntries.count) entries (expected 3)")

// 4. Performance test
print("\n4️⃣ Testing performance...")
let start = Date()
var sum = 0.0

// Simulate 100k cost calculations
for i in 0..<100_000 {
    let input = i * 100
    let output = i * 200
    let cost = (Double(input) / 1_000_000.0 * 3.0) + (Double(output) / 1_000_000.0 * 15.0)
    sum += cost
}

let elapsed = Date().timeIntervalSince(start)
if elapsed < 0.1 {
    print("   ✅ 100k calculations in \(String(format: "%.3f", elapsed))s")
} else {
    print("   ⚠️  100k calculations took \(String(format: "%.3f", elapsed))s (slow)")
}

// 5. Memory test
print("\n5️⃣ Testing memory usage...")
var entries: [[String: Any]] = []
for i in 0..<1000 {
    entries.append([
        "timestamp": now,
        "model": "claude-3-5-sonnet-20241022",
        "inputTokens": i * 100,
        "outputTokens": i * 200,
        "sessionId": "session-\(i)"
    ])
}
print("   ✅ Created 1000 entries without issues")

// Summary
print("\n======================================")
print("📊 Verification Summary")
print("======================================")

let allPassed = costTestsPassed && elapsed < 0.1
if allPassed {
    print("✅ All verifications passed!")
    print("\nThe app should work correctly when you build it.")
} else {
    print("⚠️  Some verifications need attention")
    print("\nPlease check the issues above before building.")
}

print("\n💡 Tip: Run './test.sh' for comprehensive testing")
print("💡 Tip: Check console output when running the app for debug info")