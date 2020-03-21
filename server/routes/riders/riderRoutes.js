const router = require('express').Router();
const pool = require('../../config/pool');

// Get a specific rider
router.route('/api/profile/rider/:riderId').get(async (req, res) => {
  const riderId = req.params.riderId;

  const result = await pool.query(
    `SELECT * FROM [Riders] WHERE ["riderId" = '${riderId}']`
  );
  res.setHeader('content-type', 'application/json');
  res.send(JSON.stringify(result.rows[0]));
});

// Get all riders
router.route('/api/profiles/rider').get(async (req, res) => {
  const result = await pool.query(`SELECT * FROM [Riders]`);
  res.setHeader('content-type', 'application/json');
  res.send(JSON.stringify(result.rows[0]));
});

module.exports = router;
