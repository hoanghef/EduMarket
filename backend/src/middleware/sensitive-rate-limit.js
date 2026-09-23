'use strict';

const rateLimit = require('express-rate-limit');

function sensitiveActionLimiter({ code, productionMax }) {
  return rateLimit({
    windowMs: 15 * 60 * 1000,
    // Development tests and local workflows should not be blocked by a shared
    // localhost IP; production uses the tighter route-specific threshold.
    max: process.env.NODE_ENV === 'production' ? productionMax : 1000,
    standardHeaders: true,
    legacyHeaders: false,
    message: { success: false, code, message: 'Too many sensitive requests. Please try again later.' },
  });
}

module.exports = {
  checkoutLimiter: sensitiveActionLimiter({ code: 'CHECKOUT_RATE_LIMIT', productionMax: 30 }),
  downloadTokenLimiter: sensitiveActionLimiter({ code: 'DOWNLOAD_TOKEN_RATE_LIMIT', productionMax: 60 }),
  paymentCreationLimiter: sensitiveActionLimiter({ code: 'PAYMENT_RATE_LIMIT', productionMax: 30 }),
};
