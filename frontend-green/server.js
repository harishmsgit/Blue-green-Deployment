require('dotenv').config();
const express = require('express');
const path = require('path');
const { createProxyMiddleware } = require('http-proxy-middleware');

const app = express();

// Middleware
app.use(express.static(path.join(__dirname, 'public')));

// Proxy API requests to backend
const backendUrl = process.env.BACKEND_URL || 'http://localhost:5000';
console.log(`Frontend proxy target: ${backendUrl}`);

// Local frontend environment endpoint should be processed before the proxy
app.get('/api/environment', (req, res) => {
  res.status(200).json({
    environment: 'green',
    message: 'You are on the Green Frontend',
    timestamp: new Date().toISOString(),
  });
});

app.use('/api', createProxyMiddleware({
  target: backendUrl,
  changeOrigin: true,
  pathRewrite: {
    '^/api': '/api',
  },
  onError(err, req, res) {
    console.error('Proxy error:', err);
    if (!res.headersSent) {
      res.writeHead(502, { 'Content-Type': 'application/json' });
    }
    res.end(JSON.stringify({ error: 'Unable to proxy request to backend', details: err.message }));
  },
}));

// Routes
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', environment: 'green', message: 'Frontend Green is running' });
});

// Serve index.html for root path
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Catch all routes and serve index.html for SPA routing
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

// Start server
const PORT = process.env.PORT || 3004;
app.listen(PORT, () => {
  console.log(`Green Frontend server is running on http://localhost:${PORT}`);
});
