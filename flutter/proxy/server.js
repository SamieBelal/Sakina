// Simple CORS proxy for Anthropic API — development only.
// Run with: node proxy/server.js
// Listens on http://localhost:8787

const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');

// Load API key from ../.env
function loadEnv() {
  try {
    const envPath = path.join(__dirname, '..', '.env');
    const lines = fs.readFileSync(envPath, 'utf8').split('\n');
    for (const line of lines) {
      const [key, ...rest] = line.split('=');
      if (key && rest.length) process.env[key.trim()] = rest.join('=').trim();
    }
  } catch (_) {}
}
loadEnv();

const API_KEY = process.env.ANTHROPIC_API_KEY;
if (!API_KEY || API_KEY === 'your-anthropic-api-key') {
  console.error('ERROR: ANTHROPIC_API_KEY not set in flutter/.env');
  process.exit(1);
}

const PORT = 8787;
const TARGET_HOST = 'api.anthropic.com';

const server = http.createServer((req, res) => {
  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', '*');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  let body = '';
  req.on('data', chunk => (body += chunk));
  req.on('end', () => {
    const options = {
      hostname: TARGET_HOST,
      port: 443,
      path: req.url,
      method: req.method,
      headers: {
        'content-type': 'application/json',
        'anthropic-version': '2023-06-01',
        'x-api-key': API_KEY,
      },
    };

    const proxy = https.request(options, (apiRes) => {
      res.writeHead(apiRes.statusCode, {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      });
      apiRes.pipe(res);
    });

    proxy.on('error', (err) => {
      console.error('Proxy error:', err.message);
      res.writeHead(502);
      res.end(JSON.stringify({ error: err.message }));
    });

    if (body) proxy.write(body);
    proxy.end();
  });
});

server.listen(PORT, () => {
  console.log(`Anthropic CORS proxy running at http://localhost:${PORT}`);
});
