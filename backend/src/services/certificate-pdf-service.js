'use strict';

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const PDFDocument = require('pdfkit');
const { privateFilePath } = require('./file-storage-service');

function certificateStorageKey(certificateCode) {
  return path.join('certificates', `${certificateCode}.pdf`);
}

function configuredFontPath() {
  const candidates = [
    process.env.CERTIFICATE_FONT_PATH,
    'C:\\Windows\\Fonts\\arial.ttf',
    '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
    '/Library/Fonts/Arial Unicode.ttf',
  ].filter(Boolean);
  return candidates.find((candidate) => fs.existsSync(candidate)) || null;
}

function displayDate(value) {
  return new Intl.DateTimeFormat('vi-VN', { dateStyle: 'long', timeZone: 'Asia/Ho_Chi_Minh' }).format(value);
}

function safeText(value, maximum = 500) {
  return String(value || '').replace(/[\r\n]+/g, ' ').trim().slice(0, maximum);
}

async function generateCertificatePdf({ certificateCode, studentName, courseName, issuedAt }) {
  const storageKey = certificateStorageKey(certificateCode);
  const targetPath = privateFilePath(storageKey);
  const temporaryPath = `${targetPath}.${crypto.randomUUID()}.tmp`;
  await fs.promises.mkdir(path.dirname(targetPath), { recursive: true });

  try {
    await new Promise((resolve, reject) => {
      const document = new PDFDocument({ size: 'A4', margin: 54, info: { Title: `Certificate ${certificateCode}`, Author: 'EduMarket' } });
      const output = fs.createWriteStream(temporaryPath, { flags: 'wx' });
      const fontPath = configuredFontPath();
      if (fontPath) document.font(fontPath);
      document.pipe(output);
      document.fillColor('#17324d').fontSize(28).text('CHỨNG NHẬN HOÀN THÀNH', { align: 'center' });
      document.moveDown(1.4).fontSize(14).fillColor('#243b53').text('EduMarket xác nhận học viên', { align: 'center' });
      document.moveDown(0.5).fontSize(24).fillColor('#0b5cab').text(safeText(studentName), { align: 'center' });
      document.moveDown(0.9).fontSize(14).fillColor('#243b53').text('đã hoàn thành khóa học', { align: 'center' });
      document.moveDown(0.45).fontSize(20).fillColor('#17324d').text(safeText(courseName), { align: 'center' });
      document.moveDown(1.6).fontSize(12).fillColor('#243b53').text(`Ngày cấp: ${displayDate(issuedAt)}`, { align: 'center' });
      document.moveDown(0.35).text(`Mã chứng nhận: ${certificateCode}`, { align: 'center' });
      document.moveDown(0.35).fontSize(10).fillColor('#52606d').text(`Xác thực: /api/certificates/${certificateCode}/verify`, { align: 'center' });
      document.moveDown(3).fontSize(11).fillColor('#243b53').text('EduMarket', { align: 'center' });
      document.end();
      output.once('finish', resolve);
      output.once('error', reject);
      document.once('error', reject);
    });
    await fs.promises.rename(temporaryPath, targetPath);
    return storageKey;
  } catch (error) {
    await fs.promises.rm(temporaryPath, { force: true }).catch(() => {});
    throw error;
  }
}

module.exports = { certificateStorageKey, generateCertificatePdf };
