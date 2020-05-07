const router = require('express').Router();
const pool = require('../../config/pool');

// Get all riders that are part timers
router.route('/api/profiles/rider/part_timer').get(async (req, res) => {
  const queryString = 
    'SELECT * FROM Rider JOIN Part_Timer ON Rider.rid = Part_Timer.rid';

  const result = await pool.query(queryString);
  res.setHeader('content-type', 'application/json');
  res.send(JSON.stringify(result.rows));
});

// // Get a part timer's schedule
// router.route('/api/profiles/rider/part_timer/schedule/:rid').get(async (req, res) => {
//     const rid = req.params.rid;
//     const queryString = `SELECT * FROM Schedule_FT_Hours WHERE rid = ${rid} UNION SELECT * FROM Schedule_PT_Hours WHERE rid = ${rid}`;
  
//     const result = await pool.query(queryString);
//     res.setHeader('content-type', 'application/json');
//     res.send(JSON.stringify(result.rows[0]));
// });

// Get {month, numDelivered, numHoursWorked, totalSalary} for FullTime
router.route('api/profiles/rider/part_timer/stats/:rid').get(async (req, res) => {
    const id = req.params.rid;

    // Assuming all deliveries are fixed at $4 as decided.
    const queryString =
    `SELECT month_no, CAST((salary-base_salary)/4 AS INTEGER) as numDelivered, salary FROM Weekly_Past_Salaries WHERE rid = ${id};`;
    

    const result = await pool.query(queryString);
    res.setHeader('content-type', 'application/json');
    res.send(JSON.stringify(result.rows));
});

module.exports = router;
