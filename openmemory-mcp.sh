#!/bin/bash

# OpenMemory MCP Wrapper Script
# This script ensures proper connection to the OpenMemory SSE endpoint

# Check if MCP SSE client is available
if ! command -v npx &> /dev/null; then
    echo "Error: npx is not installed. Please install Node.js and npm." >&2
    exit 1
fi

# Set the SSE endpoint URL
SSE_URL="http://localhost:8765/mcp/claude/sse/ian"

# Check if the API is running
if ! curl -s -f http://localhost:8765/health > /dev/null 2>&1; then
    echo "Error: OpenMemory API is not running on port 8765" >&2
    echo "Please start OpenMemory with: cd openmemory && make up" >&2
    exit 1
fi

# Log connection attempt to stderr (visible in Claude logs)
echo "Connecting to OpenMemory SSE endpoint: $SSE_URL" >&2

# Execute the MCP SSE client
exec npx -y @modelcontextprotocol/server-sse "$SSE_URL"
