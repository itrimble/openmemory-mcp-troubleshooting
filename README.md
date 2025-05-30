# OpenMemory MCP Troubleshooting Guide

This repository contains comprehensive troubleshooting documentation for OpenMemory MCP Server integration with Claude Desktop and other MCP clients.

## Common Error: "Server transport closed unexpectedly"

This is the most common error when setting up OpenMemory MCP:

```
2025-05-30T19:18:27.723Z [info] [openmemory] Server transport closed unexpectedly, this is likely due to the process exiting early.
2025-05-30T19:18:27.724Z [error] [openmemory] Server disconnected.
```

## Prerequisites

Before troubleshooting, ensure you have:
- Docker Desktop running
- Node.js and npm installed
- OpenAI API key
- Git

## Setup Process

### 1. Clone and Setup OpenMemory

```bash
# Clone the repository
git clone https://github.com/mem0ai/mem0.git
cd openmemory

# Create and configure the .env file
cd api
cp .env.example .env
# Edit .env and add your OPENAI_API_KEY
echo "OPENAI_API_KEY=your_actual_api_key_here" > .env
cd ..

# Build Docker images
make build

# Start all services
make up

# Start the frontend
cp ui/.env.example ui/.env
make ui
```

### 2. Verify Services are Running

```bash
# Check Docker containers
docker ps | grep openmemory

# You should see:
# - openmemory-api-1
# - openmemory-postgres-1
# - openmemory-qdrant-1

# Test API endpoint
curl http://localhost:8765/health
curl http://localhost:8765/docs

# Test SSE endpoint
curl -N -H "Accept: text/event-stream" http://localhost:8765/mcp/claude/sse/ian
```

### 3. Configure Claude Desktop

Edit your Claude Desktop configuration file:
- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`

Add the OpenMemory configuration:

```json
{
  "mcpServers": {
    "openmemory": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-sse",
        "http://localhost:8765/mcp/claude/sse/ian"
      ]
    }
  }
}
```

## Troubleshooting Steps

### Step 1: Check Docker Logs

```bash
# Check API logs for errors
docker logs openmemory-api-1 --tail 50

# Check for specific errors
docker logs openmemory-api-1 2>&1 | grep -i error
```

### Step 2: Verify API Key

```bash
# Check if API key is set in the container
docker exec openmemory-api-1 env | grep OPENAI_API_KEY
```

### Step 3: Test SSE Connection

Create a test file `test-sse.js`:

```javascript
const EventSource = require('eventsource');
const es = new EventSource('http://localhost:8765/mcp/claude/sse/ian');

es.onopen = () => console.log('Connected to SSE');
es.onmessage = (event) => console.log('Message:', event.data);
es.onerror = (err) => console.error('Error:', err);

setTimeout(() => {
  es.close();
  console.log('Connection closed');
}, 10000);
```

Run it:
```bash
npm install eventsource
node test-sse.js
```

### Step 4: Alternative Configurations

If the standard configuration doesn't work, try these alternatives:

#### Option 1: Using a Wrapper Script

Create `/Users/ian/openmemory-mcp.sh`:
```bash
#!/bin/bash
exec npx -y @modelcontextprotocol/server-sse http://localhost:8765/mcp/claude/sse/ian
```

Make it executable:
```bash
chmod +x /Users/ian/openmemory-mcp.sh
```

Update Claude config:
```json
{
  "mcpServers": {
    "openmemory": {
      "command": "/Users/ian/openmemory-mcp.sh",
      "args": []
    }
  }
}
```

#### Option 2: With Environment Variables

```json
{
  "mcpServers": {
    "openmemory": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-sse@latest",
        "http://localhost:8765/mcp/claude/sse/ian"
      ],
      "env": {
        "NODE_ENV": "production",
        "DEBUG": "mcp:*"
      }
    }
  }
}
```

### Step 5: Check Port Availability

```bash
# Check if port 8765 is in use
lsof -i :8765

# Check if port 3001 is in use (UI)
lsof -i :3001
```

## Common Issues and Solutions

### Issue 1: Missing API Key
**Symptom**: Server starts but immediately disconnects
**Solution**: Ensure OPENAI_API_KEY is set in `openmemory/api/.env`

### Issue 2: Docker Not Running
**Symptom**: Connection refused errors
**Solution**: Start Docker Desktop and run `make up` again

### Issue 3: Port Conflicts
**Symptom**: Address already in use errors
**Solution**: Kill processes using ports 8765 or 3001

### Issue 4: SSE Client Not Found
**Symptom**: Command not found errors
**Solution**: Install globally: `npm install -g @modelcontextprotocol/server-sse`

### Issue 5: CORS Issues
**Symptom**: Cross-origin errors in logs
**Solution**: Ensure using `http://` not `https://` for localhost

## Quick Diagnostics Script

Create `diagnose.sh`:

```bash
#!/bin/bash

echo "=== OpenMemory MCP Diagnostics ==="
echo

echo "1. Checking Docker..."
if docker ps > /dev/null 2>&1; then
    echo "✓ Docker is running"
    echo "   OpenMemory containers:"
    docker ps | grep openmemory | awk '{print "   - " $NF}'
else
    echo "✗ Docker is not running"
fi
echo

echo "2. Checking API..."
if curl -s http://localhost:8765/health > /dev/null 2>&1; then
    echo "✓ API is responding"
else
    echo "✗ API is not responding"
fi
echo

echo "3. Checking UI..."
if curl -s http://localhost:3001 > /dev/null 2>&1; then
    echo "✓ UI is accessible"
else
    echo "✗ UI is not accessible"
fi
echo

echo "4. Checking SSE endpoint..."
timeout 2 curl -s -N -H "Accept: text/event-stream" http://localhost:8765/mcp/claude/sse/ian > /dev/null 2>&1
if [ $? -eq 124 ]; then
    echo "✓ SSE endpoint is streaming"
else
    echo "✗ SSE endpoint is not working"
fi
echo

echo "5. Checking npm/npx..."
if command -v npx > /dev/null 2>&1; then
    echo "✓ npx is available"
else
    echo "✗ npx is not found"
fi
```

Make it executable and run:
```bash
chmod +x diagnose.sh
./diagnose.sh
```

## Working Example

Once properly configured, you should see in Claude Desktop:
- OpenMemory appears in the MCP servers list
- Memory tools are available (add_memory, search_memory, etc.)
- The web UI at http://localhost:3001 shows connected clients

## Additional Resources

- [OpenMemory Documentation](https://docs.mem0.ai/openmemory)
- [MCP Documentation](https://modelcontextprotocol.io)
- [Claude Desktop MCP Guide](https://modelcontextprotocol.io/docs/tools/debugging)

## Contributing

If you find additional issues or solutions, please submit a PR to help others!
