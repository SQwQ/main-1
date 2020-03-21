const router = require('express').Router();
const pool = require('../../config/pool');

// Get a specific rider
router.route('/api/profile/rider/:rid').get(async (req, res) => {
  const rid = req.params.rid;
  const queryString = `SELECT * FROM Rider WHERE rid = ${rid}`;

  const result = await pool.query(queryString);
  res.setHeader('content-type', 'application/json');
  res.send(JSON.stringify(result.rows[0]));
});

// Get all riders
router.route('/api/profiles/rider').get(async (req, res) => {
  const queryString = 'SELECT * FROM Rider';

  const result = await pool.query(queryString);
  res.setHeader('content-type', 'application/json');
  res.send(JSON.stringify(result.rows));
});

module.exports = router;
