const express = require('express');
const cors = require('cors');
const httpProxy = require('http-proxy');
require('dotenv').config();

const PORT = parseInt(process.env.PORT, 10) || 8080;
const ALLOWED_ORIGINS = (process.env.ALLOWED_ORIGINS || 'http://localhost:3000').split(',').map(s => s.trim());

// Service target URLs (overridable via .env)
const SERVICES = {
  auth:      process.env.AUTH_SERVICE_URL      || 'http://127.0.0.1:5001',
  candidat:  process.env.CANDIDAT_SERVICE_URL  || 'http://127.0.0.1:5000',
  recruiter: process.env.RECRUITER_SERVICE_URL || 'http://127.0.0.1:5002',
  offer:     process.env.OFFER_SERVICE_URL     || 'http://127.0.0.1:5003',
  trainer:   process.env.TRAINER_SERVICE_URL   || 'http://127.0.0.1:5004',
  interview: process.env.INTERVIEW_SERVICE_URL || 'http://127.0.0.1:5005',
};

// Route table: frontend path prefix → backend target
// When `rewrite` is set, the prefix is replaced before forwarding
// (needed when the backend mounts at a different path than the frontend uses)
const ROUTES = [
  { prefix: '/api/auth',      target: SERVICES.auth },

  { prefix: '/candidat',      target: SERVICES.candidat },
  { prefix: '/cv',            target: SERVICES.candidat },
  { prefix: '/quiz',          target: SERVICES.candidat },
  { prefix: '/recommend',     target: SERVICES.candidat },

  { prefix: '/recruiter',     target: SERVICES.recruiter },
  { prefix: '/uploads',       target: SERVICES.recruiter },

  { prefix: '/api/offers',    target: SERVICES.offer },
  { prefix: '/offers',        target: SERVICES.offer,   rewrite: '/api/offers' },
  { prefix: '/job',           target: SERVICES.offer,   rewrite: '/api/offers' },

  { prefix: '/api/formateur', target: SERVICES.trainer },
  { prefix: '/formateur',     target: SERVICES.trainer, rewrite: '/api/formateur' },

  { prefix: '/api/interview', target: SERVICES.interview },
];

// Proxy server
const proxy = httpProxy.createProxyServer({
  changeOrigin: true,
  proxyTimeout: 30000,
});

proxy.on('error', (err, req, res) => {
  const msg = err.code === 'ECONNREFUSED'
    ? `Service unreachable (${err.code}): ${err.address || ''}`
    : err.message || 'Unknown proxy error';
  console.error(`[Gateway] Proxy error for ${req.method} ${req.url}: ${msg}`);
  if (!res.headersSent) {
    res.writeHead(502, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Bad Gateway', message: msg }));
  }
});

// Express app
const app = express();

// CORS
app.use(cors({
  origin: (origin, callback) => {
    if (!origin) return callback(null, true);
    if (ALLOWED_ORIGINS.includes(origin)) return callback(null, true);
    callback(new Error(`CORS blocked: ${origin}`));
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
  exposedHeaders: ['Set-Cookie'],
}));
app.options('*', cors());

// Health check
app.get(['/', '/health'], (req, res) => {
  res.json({
    status: 'ok',
    service: 'SkillSpace API Gateway',
    version: '1.0.0',
    routes: ROUTES.map(r => ({
      prefix: r.prefix,
      target: r.target,
      rewrite: r.rewrite || null,
    })),
  });
});

// Proxy middleware — match path prefix and forward to the correct service
app.use((req, res, next) => {
  // Find the longest matching prefix (order in array matters: put specific before generic)
  const matched = ROUTES.find(r => req.path.startsWith(r.prefix));

  if (!matched) {
    return res.status(404).json({
      error: 'Route not found',
      path: req.path,
      availablePrefixes: ROUTES.map(r => r.prefix),
    });
  }

  const start = Date.now();
  const originalUrl = req.url;

  // Rewrite path if the backend mounts at a different prefix
  if (matched.rewrite) {
    req.url = req.url.replace(matched.prefix, matched.rewrite);
  }

  console.log(`[Gateway] ${req.method} ${originalUrl} → ${matched.target}${req.url}`);

  proxy.web(req, res, { target: matched.target }, (err) => {
    req.url = originalUrl;
    if (err) {
      const errMsg = err.message || err.code || 'Service offline';
      console.error(`[Gateway] Proxy error for ${originalUrl}: ${errMsg}`);
      if (!res.headersSent) {
        res.status(502).json({ error: 'Bad Gateway', message: errMsg });
      }
    }
  });
});

// Start
const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`\n  == SkillSpace API Gateway ==`);
  console.log(`  URL:  http://localhost:${PORT}`);
  console.log(`  CORS: ${ALLOWED_ORIGINS.join(', ')}\n`);
  console.log(`  Routes:`);
  ROUTES.forEach(r => {
    const rewrite = r.rewrite ? ` (rewrite: ${r.rewrite})` : '';
    console.log(`    ${r.prefix.padEnd(18)} -> ${r.target}${rewrite}`);
  });
  console.log('');
});

// Graceful shutdown
process.on('SIGTERM', () => server.close(() => process.exit(0)));
process.on('SIGINT', () => server.close(() => process.exit(0)));
