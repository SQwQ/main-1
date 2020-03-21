const router = require('express').Router();
const pool = require('../config/pool');

// Get a specific customer
router.route('/api/profile/customer/:customerId').get(async (req, res) => {
  const customerId = req.params.customerId;

  const result = await pool.query(
    `SELECT * FROM [Customers] WHERE ["id" = '${customerId}']`
  );
  res.setHeader('content-type', 'application/json');
  res.send(JSON.stringify(result.rows[0]));
});

// Get a list of all customer
router.route('/api/profile/customers').get(async (req, res) => {
  const result = await pool.query(
    `SELECT * FROM [Customers]`
  );
  res.setHeader('content-type', 'application/json');
  res.send(JSON.stringify(result.rows[0]));
});

module.exports = router;
