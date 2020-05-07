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

// Get the hour shift and day shift for a full timer
router.route('/api/profiles/rider/full_timer/shiftDayHours/:rid').get(async (req, res) => {
    const id = req.params.rid;

    const queryString =
    `SELECT wkDate, shift FROM Schedule_FT_Hours WHERE rid = ${id} AND is_last_shift = True ORDER BY sfid`;
    try {
        const result = await pool.query(queryString);
        res.setHeader('content-type', 'application/json');
        res.send(JSON.stringify(result.rows));
    } catch(err) {
        res.send("error: " + err)
    }
  });

// Get {month, numDelivered, numHoursWorked, totalSalary} for FullTime
router.route('/api/profiles/rider/full_timer/stats/:rid').get(async (req, res) => {
    const id = req.params.rid;

     // Assuming all deliveries are fixed at $4 as decided.
     const queryString =
     `SELECT month_no, CAST((salary-base_salary)/4 AS INTEGER) as numDelivered, 160 as numHoursWorked, salary FROM Monthly_Past_Salaries WHERE rid = ${id};`;

    const result = await pool.query(queryString);
    res.setHeader('content-type', 'application/json');
    res.send(JSON.stringify(result.rows));
});

module.exports = router;
