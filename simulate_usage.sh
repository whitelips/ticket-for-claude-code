#!/bin/bash

# Simulate Claude Code usage by appending new entries to the JSONL file
# Run this script to test real-time updates in the app

CLAUDE_DIR="$HOME/.config/claude"
TODAY=$(date +%Y-%m-%d)
USAGE_FILE="$CLAUDE_DIR/usage_$TODAY.jsonl"

# Create directory if it doesn't exist
mkdir -p "$CLAUDE_DIR"

# Models to randomly choose from
MODELS=("claude-3-5-sonnet-20241022" "claude-3-5-haiku-20241022")

echo "Simulating Claude Code usage..."
echo "Writing to: $USAGE_FILE"
echo "Press Ctrl+C to stop"

while true; do
    # Generate random token counts
    INPUT_TOKENS=$((RANDOM % 3000 + 500))
    OUTPUT_TOKENS=$((RANDOM % 5000 + 1000))
    
    # Pick a random model
    MODEL=${MODELS[$RANDOM % ${#MODELS[@]}]}
    
    # Generate conversation ID
    CONV_ID="conv_sim_$(date +%s)"
    
    # Create timestamp
    TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    # Create JSON entry
    JSON_ENTRY="{\"timestamp\":\"$TIMESTAMP\",\"conversation_id\":\"$CONV_ID\",\"input_tokens\":$INPUT_TOKENS,\"output_tokens\":$OUTPUT_TOKENS,\"model\":\"$MODEL\"}"
    
    # Append to file
    echo "$JSON_ENTRY" >> "$USAGE_FILE"
    
    echo "Added entry: $INPUT_TOKENS input, $OUTPUT_TOKENS output tokens at $TIMESTAMP"
    
    # Wait 5-15 seconds before next entry
    WAIT_TIME=$((RANDOM % 11 + 5))
    sleep $WAIT_TIME
done