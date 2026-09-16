'use strict';

const { Router } = require('express');
const router = Router();

/**
 * GET /api/health
 * Public health-check endpoint.
 * Returns server status and timestamp so Flutter can verify connectivity.
 */
router.get('/health', (_req, res) => {
  res.json({
    success: true,
    data: {
      status: 'ok',
      service: 'EduMarket API',
      version: '0.1.0',
      environment: process.env.NODE_ENV || 'development',
      timestamp: new Date().toISOString(),
    },
  });
});

module.exports = router;
