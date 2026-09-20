'use strict';

const fs = require('fs');
const path = require('path');
const { Router } = require('express');
const prisma = require('../lib/prisma');
const { requireAuth, requireCustomer } = require('../middleware/auth');
const { privateFilePath } = require('../services/file-storage-service');

const router = Router();
const certificateCodePattern = /^EDU-\d{4}-[A-F0-9]{24}$/;

function certificateCode(value) {
  const code = String(value || '').toUpperCase();
  return certificateCodePattern.test(code) ? code : null;
}

router.get('/', requireAuth, requireCustomer, async (req, res, next) => {
  try {
    const certificates = await prisma.certificate.findMany({
      where: { userId: req.user.id }, orderBy: { issuedAt: 'desc' },
      select: { certificateCode: true, issuedAt: true, course: { select: { title: true } } },
    });
    const items = certificates.map((certificate) => ({
      certificateCode: certificate.certificateCode,
      courseTitle: certificate.course.title,
      issuedAt: certificate.issuedAt,
      verification: { verified: true, url: `/api/certificates/${certificate.certificateCode}/verify` },
    }));
    return res.json({ success: true, data: { items } });
  } catch (error) { return next(error); }
});

router.get('/:code/pdf', requireAuth, requireCustomer, async (req, res, next) => {
  try {
    const code = certificateCode(req.params.code);
    if (!code) return res.status(400).json({ success: false, code: 'INVALID_CERTIFICATE_CODE', message: 'Certificate code format is invalid.' });
    const certificate = await prisma.certificate.findFirst({ where: { certificateCode: code, userId: req.user.id }, select: { certificateCode: true, pdfStorageKey: true } });
    if (!certificate) return res.status(404).json({ success: false, code: 'CERTIFICATE_NOT_FOUND', message: 'Certificate not found.' });
    if (!certificate.pdfStorageKey) return res.status(404).json({ success: false, code: 'CERTIFICATE_FILE_NOT_FOUND', message: 'Certificate PDF is not available.' });
    const pdfPath = privateFilePath(certificate.pdfStorageKey);
    if (!fs.existsSync(pdfPath)) return res.status(404).json({ success: false, code: 'CERTIFICATE_FILE_NOT_FOUND', message: 'Certificate PDF is not available.' });
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="certificate-${path.basename(certificate.certificateCode)}.pdf"`);
    return res.sendFile(pdfPath);
  } catch (error) { return next(error); }
});

router.get('/:code/verify', async (req, res, next) => {
  try {
    const code = certificateCode(req.params.code);
    if (!code) return res.status(400).json({ success: false, code: 'INVALID_CERTIFICATE_CODE', message: 'Certificate code format is invalid.' });
    const certificate = await prisma.certificate.findUnique({
      where: { certificateCode: code },
      select: { certificateCode: true, issuedAt: true, user: { select: { fullName: true } }, course: { select: { title: true } } },
    });
    if (!certificate) return res.status(404).json({ success: false, code: 'CERTIFICATE_NOT_FOUND', message: 'Certificate not found.' });
    return res.json({ success: true, data: { verified: true, certificateCode: certificate.certificateCode, studentName: certificate.user.fullName, courseName: certificate.course.title, issuedAt: certificate.issuedAt } });
  } catch (error) { return next(error); }
});

module.exports = router;
