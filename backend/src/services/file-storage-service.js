'use strict';

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const multer = require('multer');
const { BusinessError } = require('./order-service');

const allowedFiles = new Map([
  ['.pdf', new Set(['application/pdf'])],
  ['.zip', new Set(['application/zip', 'application/x-zip-compressed'])],
  ['.docx', new Set(['application/vnd.openxmlformats-officedocument.wordprocessingml.document'])],
  ['.xlsx', new Set(['application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'])],
  ['.pptx', new Set(['application/vnd.openxmlformats-officedocument.presentationml.presentation'])],
]);

function privateStorageRoot() {
  return path.resolve(process.cwd(), process.env.PRIVATE_STORAGE_PATH || './private_storage');
}

function privateFilePath(storageKey) {
  if (typeof storageKey !== 'string' || !storageKey) throw new BusinessError(404, 'FILE_NOT_FOUND', 'File not found.');
  const root = privateStorageRoot();
  const resolved = path.resolve(root, storageKey);
  if (resolved !== root && !resolved.startsWith(`${root}${path.sep}`)) throw new BusinessError(404, 'FILE_NOT_FOUND', 'File not found.');
  return resolved;
}

function validateFile(originalName, mimeType) {
  const baseName = path.basename(originalName || '');
  if (!baseName || baseName !== originalName || baseName.length > 255 || /[\0\r\n]/.test(baseName)) return false;
  const extension = path.extname(baseName).toLowerCase();
  return allowedFiles.get(extension)?.has(mimeType) || false;
}

function validateStoredFileContent(filePath, originalName) {
  const extension = path.extname(path.basename(originalName || '')).toLowerCase();
  let signature;
  try { signature = fs.readFileSync(filePath).subarray(0, 8); } catch { return false; }
  if (extension === '.pdf') return signature.subarray(0, 5).toString('ascii') === '%PDF-';
  // ZIP is the container format used for ZIP, DOCX, XLSX and PPTX.
  return ['.zip', '.docx', '.xlsx', '.pptx'].includes(extension)
    && signature.length >= 4
    && signature[0] === 0x50
    && signature[1] === 0x4b
    && ([0x03, 0x05, 0x07].includes(signature[2]))
    && ([0x04, 0x06, 0x08].includes(signature[3]));
}

function maxFileSizeBytes() {
  const megabytes = Number(process.env.MAX_FILE_SIZE_MB || 100);
  return Number.isFinite(megabytes) && megabytes > 0 && megabytes <= 100 ? megabytes * 1024 * 1024 : 100 * 1024 * 1024;
}

const upload = multer({
  storage: multer.diskStorage({
    destination(_req, _file, callback) {
      fs.mkdirSync(privateStorageRoot(), { recursive: true });
      callback(null, privateStorageRoot());
    },
    filename(_req, file, callback) {
      callback(null, `${crypto.randomUUID()}${path.extname(file.originalname).toLowerCase()}`);
    },
  }),
  limits: { fileSize: maxFileSizeBytes(), files: 1 },
  fileFilter(_req, file, callback) {
    if (!validateFile(file.originalname, file.mimetype)) {
      const error = new Error('Unsupported file name, extension, or MIME type.');
      error.status = 400;
      error.code = 'INVALID_FILE_UPLOAD';
      return callback(error);
    }
    return callback(null, true);
  },
});

function uploadSingleFile(req, res, next) {
  upload.single('file')(req, res, (error) => {
    if (!error) return next();
    const status = error.code === 'LIMIT_FILE_SIZE' ? 400 : error.status || 400;
    return res.status(status).json({ success: false, code: error.code || 'INVALID_FILE_UPLOAD', message: error.code === 'LIMIT_FILE_SIZE' ? 'File is too large.' : error.message });
  });
}

function removeStoredFile(storageKey) {
  try { fs.rmSync(privateFilePath(storageKey), { force: true }); } catch { /* best-effort cleanup */ }
}

module.exports = { maxFileSizeBytes, privateFilePath, privateStorageRoot, removeStoredFile, uploadSingleFile, validateFile, validateStoredFileContent };
