module.exports = {
  httpRoot: '/nodered',
  ui: { path: '/nodered/ui' },
  uiPort: process.env.PORT || 1880,
  adminAuth: null,
  httpNodeAuth: null,
  httpNodeCors: { origin: '*', methods: 'GET,PUT,POST,DELETE' },
  functionGlobalContext: {},
  logging: { console: { level: 'info', metrics: false, audit: false } }
};
