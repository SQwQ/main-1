const { Pool } = require('pg');
const keys = require('./keys');

// Create pool to communicate with database
module.exports = new Pool({
  // TODO: change to environment variable before deployment
  user: 'postgres',
  password: keys.postgresPW,
  host: 'localhost',
  port: '5432',
  database: 'testcs2102database',
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 20000
});