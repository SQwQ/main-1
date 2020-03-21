const { Pool } = require('pg');

// Create pool to communicate with database
module.exports = new Pool({
  // TODO: change to environment variable before deployment
  user: 'postgres',
  password: keys.postgresPW,
  host: 'localhost',
  port: '5432',
  database: 'myTestDB',
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 20000
});