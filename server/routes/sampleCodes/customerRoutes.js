const router = require('express').Router();
const pool = require('../../config/pool');

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
