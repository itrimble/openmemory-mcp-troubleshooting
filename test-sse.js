const EventSource = require('eventsource');

// Test SSE connection to OpenMemory MCP
console.log('Testing OpenMemory SSE connection...\n');

const url = 'http://localhost:8765/mcp/claude/sse/ian';
const es = new EventSource(url, {
    headers: {
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache'
    }
});

let messageCount = 0;
const timeout = setTimeout(() => {
    console.log('\nTest completed. Closing connection...');
    es.close();
    process.exit(0);
}, 10000); // Run for 10 seconds

es.onopen = () => {
    console.log('✓ Connected to SSE endpoint');
    console.log(`  URL: ${url}`);
    console.log('  Waiting for messages...\n');
};

es.onmessage = (event) => {
    messageCount++;
    console.log(`Message ${messageCount}:`);
    console.log(`  Event: ${event.type || 'message'}`);
    console.log(`  Data: ${event.data}`);
    console.log(`  ID: ${event.lastEventId || 'none'}`);
    console.log('');
    
    // Try to parse JSON data
    try {
        const data = JSON.parse(event.data);
        console.log('  Parsed data:', JSON.stringify(data, null, 2));
    } catch (e) {
        // Not JSON, that's okay
    }
};

es.onerror = (err) => {
    console.error('✗ SSE Error occurred:');
    if (err.type === 'error') {
        console.error('  Connection error - is the server running?');
        console.error('  Make sure OpenMemory is running with:');
        console.error('    cd openmemory && make up');
    }
    console.error('  Error details:', err);
    clearTimeout(timeout);
    es.close();
    process.exit(1);
};

// Handle specific event types if any
es.addEventListener('ping', (event) => {
    console.log('Received ping:', event.data);
});

es.addEventListener('init', (event) => {
    console.log('Received init event:', event.data);
});

// Handle Ctrl+C gracefully
process.on('SIGINT', () => {
    console.log('\n\nInterrupted. Closing connection...');
    clearTimeout(timeout);
    es.close();
    process.exit(0);
});

console.log('Press Ctrl+C to stop\n');
