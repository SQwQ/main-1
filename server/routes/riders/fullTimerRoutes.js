const router = require('express').Router();
const pool = require('../../config/pool');

// Get all riders that are full timers
router.route('/api/profiles/rider/full_timer').get(async (req, res) => {
  const queryString = 
    'SELECT * FROM Rider JOIN Full_Timer ON Rider.rid = Full_Timer.rid';

  const result = await pool.query(queryString);
  res.setHeader('content-type', 'application/json');
  res.send(JSON.stringify(result.rows));
});

module.exports = router;
