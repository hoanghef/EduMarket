'use strict';

const path = require('path');
const { Router } = require('express');
const { requireAuth, requireCustomer } = require('../middleware/auth');
const { downloadTokenLimiter } = require('../middleware/sensitive-rate-limit');
const { createDownloadToken, consumeDownloadToken } = require('../services/download-service');

const filesRouter = Router();
filesRouter.post('/:id/download-token', requireAuth, requireCustomer, downloadTokenLimiter, async (req, res, next) => {
  try {
    const { token, expiresAt } = await createDownloadToken(req.user.id, req.params.id, req);
    return res.status(201).json({ success: true, data: { downloadUrl: `/api/download/${token}`, expiresAt, maxDownloads: 1 } });
  } catch (error) { return next(error); }
});

const downloadRouter = Router();
downloadRouter.get('/:token', requireAuth, requireCustomer, async (req, res, next) => {
  try {
    const { file, filePath } = await consumeDownloadToken(req.params.token, req.user.id, req);
    res.setHeader('Content-Type', file.mimeType);
    res.setHeader('Content-Length', String(file.sizeBytes));
    res.setHeader('Cache-Control', 'private, no-store');
    res.setHeader('Content-Disposition', `attachment; filename*=UTF-8''${encodeURIComponent(path.basename(file.originalName))}`);
    return res.sendFile(filePath);
  } catch (error) { return next(error); }
});

module.exports = { downloadRouter, filesRouter };
