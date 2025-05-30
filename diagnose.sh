#!/bin/bash

# OpenMemory MCP Diagnostics Script
# This script helps diagnose common issues with OpenMemory MCP setup

echo "=== OpenMemory MCP Diagnostics ==="
echo "=================================="
echo

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
    fi
}

# 1. Check Docker
echo "1. Checking Docker..."
if docker ps > /dev/null 2>&1; then
    print_status 0 "Docker is running"
    
    # Check specific containers
    echo "   Checking OpenMemory containers:"
    for container in "api" "postgres" "qdrant"; do
        if docker ps | grep -q "openmemory-$container"; then
            echo -e "   ${GREEN}✓${NC} openmemory-$container is running"
        else
            echo -e "   ${RED}✗${NC} openmemory-$container is NOT running"
        fi
    done
else
    print_status 1 "Docker is not running - please start Docker Desktop"
fi
echo

# 2. Check API endpoint
echo "2. Checking API endpoint..."
if curl -s -f http://localhost:8765/health > /dev/null 2>&1; then
    print_status 0 "API health endpoint is responding"
    
    # Check API docs
    if curl -s -f http://localhost:8765/docs > /dev/null 2>&1; then
        print_status 0 "API documentation is accessible"
    else
        print_status 1 "API documentation is not accessible"
    fi
else
    print_status 1 "API is not responding on port 8765"
fi
echo

# 3. Check UI
echo "3. Checking Web UI..."
if curl -s -f http://localhost:3001 > /dev/null 2>&1; then
    print_status 0 "Web UI is accessible at http://localhost:3001"
else
    print_status 1 "Web UI is not accessible on port 3001"
fi
echo

# 4. Check SSE endpoint
echo "4. Checking SSE endpoint..."
SSE_RESPONSE=$(timeout 2 curl -s -N -H "Accept: text/event-stream" http://localhost:8765/mcp/claude/sse/ian 2>&1)
if [ $? -eq 124 ]; then
    print_status 0 "SSE endpoint is streaming (timeout as expected)"
elif [[ $SSE_RESPONSE == *"event:"* ]]; then
    print_status 0 "SSE endpoint is returning events"
else
    print_status 1 "SSE endpoint is not working properly"
    echo "   Response: $SSE_RESPONSE"
fi
echo

# 5. Check Node.js and npm
echo "5. Checking Node.js environment..."
if command -v node > /dev/null 2>&1; then
    NODE_VERSION=$(node -v)
    print_status 0 "Node.js is installed: $NODE_VERSION"
else
    print_status 1 "Node.js is not found"
fi

if command -v npm > /dev/null 2>&1; then
    NPM_VERSION=$(npm -v)
    print_status 0 "npm is installed: $NPM_VERSION"
else
    print_status 1 "npm is not found"
fi

if command -v npx > /dev/null 2>&1; then
    print_status 0 "npx is available"
else
    print_status 1 "npx is not found"
fi
echo

# 6. Check MCP SSE client
echo "6. Checking MCP SSE client..."
if npm list -g @modelcontextprotocol/server-sse > /dev/null 2>&1; then
    print_status 0 "MCP SSE client is installed globally"
else
    echo -e "${YELLOW}!${NC} MCP SSE client not installed globally (will use npx)"
fi
echo

# 7. Check ports
echo "7. Checking port availability..."
for port in 8765 3001; do
    if lsof -i :$port > /dev/null 2>&1; then
        print_status 0 "Port $port is in use (expected for OpenMemory)"
        echo "   Process: $(lsof -i :$port | tail -1 | awk '{print $1}')"
    else
        print_status 1 "Port $port is not in use"
    fi
done
echo

# 8. Check environment
echo "8. Checking environment..."
if [ -f openmemory/api/.env ]; then
    if grep -q "OPENAI_API_KEY=" openmemory/api/.env && ! grep -q "OPENAI_API_KEY=$" openmemory/api/.env; then
        print_status 0 "OPENAI_API_KEY is set in .env file"
    else
        print_status 1 "OPENAI_API_KEY is not set in .env file"
    fi
else
    print_status 1 ".env file not found at openmemory/api/.env"
fi
echo

# Summary
echo "=================================="
echo "Summary:"
echo
if docker ps | grep -q openmemory && curl -s -f http://localhost:8765/health > /dev/null 2>&1; then
    echo -e "${GREEN}OpenMemory appears to be running correctly!${NC}"
    echo
    echo "Next steps:"
    echo "1. Check the Web UI at http://localhost:3001"
    echo "2. Configure Claude Desktop with the provided configuration"
    echo "3. Restart Claude Desktop after configuration"
else
    echo -e "${RED}OpenMemory is not fully operational.${NC}"
    echo
    echo "Please check the errors above and:"
    echo "1. Ensure Docker is running"
    echo "2. Run 'make build' and 'make up' in the openmemory directory"
    echo "3. Check Docker logs with: docker logs openmemory-api-1"
fi
