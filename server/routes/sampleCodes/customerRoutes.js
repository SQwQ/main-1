const router = require('express').Router();
const keys = require('../../config/keys');
const { Pool } = require('pg');

// Create pool to communicate with database
const pool = new Pool({
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

// Get a specific customer
router.route('/api/profiles/:customerId').get(async (req, res) => {
  const customerId = req.params.customerId;

  const result = await pool.query(
    `SELECT * FROM public."Users" WHERE "googleId" = '${customerId}'`
  );
  res.setHeader('content-type', 'application/json');
  res.send(JSON.stringify(result.rows[0]));
});

module.exports = router;
