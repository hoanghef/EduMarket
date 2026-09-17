'use strict';

const { PrismaClient } = require('../generated/prisma');

/** @type {import('../generated/prisma').PrismaClient} */
let prisma;

if (process.env.NODE_ENV === 'production') {
  prisma = new PrismaClient();
} else {
  // Prevent multiple instances in development with Node --watch
  if (!global._prisma) {
    global._prisma = new PrismaClient({
      log: ['query', 'error', 'warn'],
    });
  }
  prisma = global._prisma;
}

module.exports = prisma;
