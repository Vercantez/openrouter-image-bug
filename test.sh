#!/bin/bash

# Test script to demonstrate the bug
# Requires: ANTHROPIC_API_KEY and OPENROUTER_API_KEY environment variables

set -e

if [ ! -f repro.json ]; then
    echo "repro.json not found. Run ./generate-repro.sh first"
    exit 1
fi

if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "Warning: ANTHROPIC_API_KEY not set, skipping Anthropic test"
    SKIP_ANTHROPIC=1
fi

if [ -z "$OPENROUTER_API_KEY" ]; then
    echo "Warning: OPENROUTER_API_KEY not set, skipping OpenRouter test"
    SKIP_OPENROUTER=1
fi

echo "=============================================="
echo "Testing image in tool_result handling"
echo "=============================================="
echo ""
echo "The image is: cat.jpg (an orange tabby cat)"
echo ""

if [ -z "$SKIP_ANTHROPIC" ]; then
    echo "=== ANTHROPIC API ==="
    curl -s https://api.anthropic.com/v1/messages \
        -H "content-type: application/json" \
        -H "x-api-key: $ANTHROPIC_API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -d @repro.json | jq -r '.content[0].text'
    echo ""
fi

if [ -z "$SKIP_OPENROUTER" ]; then
    echo "=== OPENROUTER API ==="
    curl -s https://openrouter.ai/api/v1/messages \
        -H "content-type: application/json" \
        -H "x-api-key: $OPENROUTER_API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -d @repro.json | jq -r '.content[0].text'
    echo ""
fi

echo "=============================================="
echo "Expected: Both should describe an orange tabby cat"
echo "Actual: OpenRouter hallucinates a different image"
echo "=============================================="
