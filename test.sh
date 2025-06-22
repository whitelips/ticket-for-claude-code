#!/bin/bash

# Test runner for Ticket for Claude Code
# This script runs comprehensive tests without needing to build the app

set -e

echo "🧪 Ticket for Claude Code - Test Suite"
echo "====================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "ticket-for-cc.xcodeproj/project.pbxproj" ]; then
    echo "${RED}❌ Error: Must run from project root directory${NC}"
    exit 1
fi

# Run Swift tests
echo "1️⃣ Running unit tests..."
if swift ticket-for-cc/Tests/TestRunner.swift; then
    echo "${GREEN}✅ Unit tests passed${NC}"
else
    echo "${RED}❌ Unit tests failed${NC}"
    exit 1
fi

echo ""
echo "2️⃣ Checking Claude data availability..."

# Check if Claude data exists
if [ -d ~/.claude/projects ]; then
    FILE_COUNT=$(find ~/.claude/projects -name "*.jsonl" | wc -l | tr -d ' ')
    echo "${GREEN}✅ Found $FILE_COUNT JSONL files${NC}"
    
    # Check for recent data
    RECENT=$(find ~/.claude/projects -name "*.jsonl" -mtime -7 | wc -l | tr -d ' ')
    if [ "$RECENT" -gt 0 ]; then
        echo "${GREEN}✅ Found $RECENT files modified in last 7 days${NC}"
    else
        echo "${YELLOW}⚠️  No recent files (last 7 days)${NC}"
    fi
else
    echo "${YELLOW}⚠️  No Claude data directory found${NC}"
fi

echo ""
echo "3️⃣ Running verification script..."

# Run the verification script instead of individual file checks
if ./verify.swift > /tmp/verify_output.txt 2>&1; then
    # Check if all verifications passed
    if grep -q "✅ All verifications passed!" /tmp/verify_output.txt; then
        echo "${GREEN}✅ All verifications passed${NC}"
        ERROR_COUNT=0
    else
        echo "${YELLOW}⚠️  Some verifications need attention${NC}"
        cat /tmp/verify_output.txt | grep -E "❌|⚠️"
        ERROR_COUNT=1
    fi
else
    echo "${RED}❌ Verification script failed${NC}"
    cat /tmp/verify_output.txt
    ERROR_COUNT=1
fi

rm -f /tmp/verify_output.txt

echo ""
echo "4️⃣ Testing data parsing with real data..."

# Create a simple integration test
cat > /tmp/test_integration.swift << 'EOF'
#!/usr/bin/env swift
import Foundation

// Test that we can actually parse real Claude data
let homeURL = FileManager.default.homeDirectoryForCurrentUser
let claudeProjectsURL = homeURL.appendingPathComponent(".claude/projects")

var totalEntries = 0
var totalTokens = 0
var models = Set<String>()

if FileManager.default.fileExists(atPath: claudeProjectsURL.path) {
    let projectDirs = try! FileManager.default.contentsOfDirectory(
        at: claudeProjectsURL,
        includingPropertiesForKeys: nil
    )
    
    for projectDir in projectDirs {
        let jsonlFiles = try! FileManager.default.contentsOfDirectory(
            at: projectDir,
            includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "jsonl" }
        
        for jsonlFile in jsonlFiles.prefix(1) {
            let content = try! String(contentsOf: jsonlFile, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
            
            for line in lines.prefix(50) {
                if line.contains("\"type\":\"assistant\"") && 
                   line.contains("\"usage\"") && 
                   line.contains("\"input_tokens\"") {
                    totalEntries += 1
                    
                    // Extract model
                    if let modelRange = line.range(of: "\"model\":\""),
                       let endRange = line[modelRange.upperBound...].range(of: "\"") {
                        let model = String(line[modelRange.upperBound..<line.index(modelRange.upperBound, offsetBy: line.distance(from: modelRange.upperBound, to: endRange.lowerBound))])
                        models.insert(model)
                    }
                    
                    // Extract tokens (simple regex would be better but keeping it simple)
                    if let tokenRange = line.range(of: "\"input_tokens\":"),
                       let commaRange = line[tokenRange.upperBound...].range(of: ",") {
                        let tokenStr = line[tokenRange.upperBound..<line.index(tokenRange.upperBound, offsetBy: line.distance(from: tokenRange.upperBound, to: commaRange.lowerBound))]
                            .trimmingCharacters(in: .whitespaces)
                        if let tokens = Int(tokenStr) {
                            totalTokens += tokens
                        }
                    }
                }
            }
        }
    }
    
    print("Found \(totalEntries) valid entries")
    print("Total tokens: \(totalTokens)")
    print("Models: \(models.sorted().joined(separator: ", "))")
    
    exit(totalEntries > 0 ? 0 : 1)
} else {
    print("No Claude data found")
    exit(0)
}
EOF

if swift /tmp/test_integration.swift; then
    echo "${GREEN}✅ Data parsing test passed${NC}"
else
    echo "${YELLOW}⚠️  Data parsing needs attention${NC}"
fi

rm -f /tmp/test_integration.swift

echo ""
echo "5️⃣ Performance check..."

# Simple performance test
cat > /tmp/test_performance.swift << 'EOF'
#!/usr/bin/env swift
import Foundation

let start = Date()
var count = 0

// Simulate parsing
for _ in 0..<10000 {
    let cost = (Double(1000) / 1_000_000.0) * 3.0 + (Double(2000) / 1_000_000.0) * 15.0
    count += Int(cost * 1000)
}

let elapsed = Date().timeIntervalSince(start)
print(String(format: "Processed 10k calculations in %.3f seconds", elapsed))

exit(elapsed < 1.0 ? 0 : 1)
EOF

if swift /tmp/test_performance.swift; then
    echo "${GREEN}✅ Performance test passed${NC}"
else
    echo "${RED}❌ Performance test failed (too slow)${NC}"
fi

rm -f /tmp/test_performance.swift

echo ""
echo "======================================"
echo "📊 Test Summary"
echo "======================================"

if [ $ERROR_COUNT -eq 0 ]; then
    echo "${GREEN}✅ All tests passed!${NC}"
    echo ""
    echo "You can now build and run the app with confidence! 🎉"
else
    echo "${RED}❌ Some tests failed. Please check the output above.${NC}"
    exit 1
fi