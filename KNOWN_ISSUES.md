# Known Issues and Solutions

## Issue: "Server transport closed unexpectedly"

### Root Causes
1. **Missing OPENAI_API_KEY** - Most common cause
2. **Docker containers not running**
3. **SSE endpoint not properly implemented**
4. **MCP SSE client connection failure**

### Solutions

#### 1. Verify Environment Setup
```bash
# Check if API key is set in Docker container
docker exec openmemory-api-1 env | grep OPENAI_API_KEY

# If missing, add to openmemory/api/.env:
echo "OPENAI_API_KEY=sk-your-actual-key" >> openmemory/api/.env

# Restart containers
cd openmemory
docker-compose down
make up
```

#### 2. Check SSE Endpoint Implementation
The OpenMemory SSE endpoint should return proper SSE formatted data:
```
event: init
data: {"type":"init","capabilities":{...}}

event: ping
data: {"type":"ping"}
```

Test with:
```bash
curl -N -H "Accept: text/event-stream" \
     -H "Cache-Control: no-cache" \
     http://localhost:8765/mcp/claude/sse/ian
```

#### 3. MCP SSE Client Issues
Sometimes the npx cache gets corrupted. Clear it:
```bash
npm cache clean --force
rm -rf ~/.npm/_npx
```

## Issue: "ENOENT: no such file or directory"

### Cause
The MCP server can't find npx or the specified command in PATH.

### Solution
Ensure npx is in your PATH:
```bash
which npx
# If not found, add Node.js bin directory to PATH
export PATH="$PATH:/usr/local/bin"
```

## Issue: "EPIPE" or "write EPIPE"

### Cause
The client disconnected before the server could respond, often due to initialization timeout.

### Solution
1. Increase timeout in Claude Desktop settings (if available)
2. Use the wrapper script which checks API health first
3. Ensure fast API response by checking Docker resource allocation

## Issue: Port Already in Use

### Cause
Previous instance didn't shut down cleanly.

### Solution
```bash
# Find and kill process using port 8765
lsof -ti:8765 | xargs kill -9

# Or use Docker to stop all OpenMemory containers
docker stop $(docker ps -q --filter "name=openmemory")
```

## Issue: SSE Connection But No MCP Tools

### Cause
The SSE endpoint is working but not returning proper MCP protocol messages.

### Solution
Check that OpenMemory implements the MCP protocol correctly:
1. Must respond to `initialize` method
2. Must return tool definitions
3. Must handle tool invocations

## Issue: Authentication/Permission Errors

### Cause
File permissions or user mismatch between Docker and host.

### Solution
```bash
# Fix permissions
chmod -R 755 openmemory
chown -R $USER:$USER openmemory

# If using Docker Desktop on Mac, ensure file sharing is enabled
# Docker Desktop > Settings > Resources > File Sharing
```

## Debugging MCP Protocol

To see the actual MCP protocol messages:

1. Create a debug wrapper:
```javascript
// debug-mcp.js
const { spawn } = require('child_process');
const proc = spawn('npx', ['-y', '@modelcontextprotocol/server-sse', 'http://localhost:8765/mcp/claude/sse/ian'], {
  stdio: ['inherit', 'pipe', 'inherit']
});

proc.stdout.on('data', (data) => {
  console.error('[MCP Output]:', data.toString());
  process.stdout.write(data);
});
```

2. Use in Claude config:
```json
{
  "mcpServers": {
    "openmemory": {
      "command": "node",
      "args": ["/path/to/debug-mcp.js"]
    }
  }
}
```

## Getting Help

If none of these solutions work:

1. Run the diagnostic script and share output
2. Check Docker logs: `docker logs openmemory-api-1 --tail 100`
3. Open an issue with:
   - Diagnostic script output
   - Docker logs
   - Claude Desktop logs
   - Your configuration
