const router = require('express').Router();
const pool = require('../../config/pool');

// Get all riders that are full timers
router.route('/api/profiles/rider/fulltimer').get(async (req, res) => {
  const queryString = 
    `SELECT * FROM [FullTimers] as FullTimers L
     JOIN [Riders] ON `;
  const result = await pool.query(queryString);

  res.setHeader('content-type', 'application/json');
  res.send(JSON.stringify(result.rows[0]));
});

module.exports = router;
