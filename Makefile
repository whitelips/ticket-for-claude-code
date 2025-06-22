.PHONY: test verify unit-test clean help build run

# Default target
help:
	@echo "Ticket for Claude Code - Development Commands"
	@echo "==========================================="
	@echo "make test      - Run all tests"
	@echo "make verify    - Quick verification of changes"
	@echo "make unit-test - Run unit tests only"
	@echo "make build     - Build the app in Xcode"
	@echo "make run       - Build and run the app"
	@echo "make clean     - Clean build artifacts"
	@echo "make help      - Show this help"

# Run all tests
test:
	@./test.sh

# Quick verification
verify:
	@./verify.swift

# Unit tests only
unit-test:
	@swift ticket-for-cc/Tests/TestRunner.swift

# Build the app
build:
	@echo "Building app..."
	@xcodebuild -project ticket-for-cc.xcodeproj -scheme ticket-for-cc -configuration Debug build

# Build and run
run:
	@echo "Building and running app..."
	@xcodebuild -project ticket-for-cc.xcodeproj -scheme ticket-for-cc -configuration Debug build
	@open build/Debug/ticket-for-cc.app

# Clean build artifacts
clean:
	@echo "Cleaning..."
	@xcodebuild -project ticket-for-cc.xcodeproj -scheme ticket-for-cc clean
	@rm -rf build/

# Quick test before commit
pre-commit: verify unit-test
	@echo "✅ Pre-commit checks passed!"