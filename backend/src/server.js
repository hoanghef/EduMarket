'use strict';

const app = require('./app');

const PORT = parseInt(process.env.PORT || '4000', 10);

app.listen(PORT, () => {
  console.log(`[EduMarket Backend] Server running on http://localhost:${PORT}`);
  console.log(`[EduMarket Backend] Environment: ${process.env.NODE_ENV || 'development'}`);
});
