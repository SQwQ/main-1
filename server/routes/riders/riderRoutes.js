const router = require('express').Router();
const pool = require('../../config/pool');

// Get a specific rider
router.route('/api/rider/:rid').get(async (req, res) => {
  const rid = req.params.rid;
  const queryString = `SELECT * FROM Rider WHERE rid = ${rid}`;

  const result = await pool.query(queryString);
  res.setHeader('content-type', 'application/json');
  res.send(JSON.stringify(result.rows[0]));
});

// Get if a rider has declared a schedule
// Returns 'scheduleSet' or 'scheduleNotSet accordingly'
router.route('/api/rider/scheduleSet/:rid').get(async (req, res) => {
    const rid = req.params.rid;
    const queryString1 = `SELECT * FROM Schedule_FT_Hours WHERE rid = ${rid};`;
    const queryString2 = `SELECT * FROM Schedule_PT_Hours WHERE rid = ${rid};`;
  
    const resultFT = await pool.query(queryString1);
    const resultPT = await pool.query(queryString2);

    console.log('resultFT: '+resultFT.rows.length)
    console.log('resultPT:' +resultPT.rows.length)

    const scheduleSet = (resultFT.rows.length || resultPT.rows.length) ? 'scheduleSet' : 'scheduleNotSet'

    res.setHeader('content-type', 'application/json');
    res.send(JSON.stringify(scheduleSet));
  });

// Get all riders
router.route('/api/profiles/rider').get(async (req, res) => {
  const queryString = 'SELECT * FROM Rider';

  const result = await pool.query(queryString);
  res.setHeader('content-type', 'application/json');
  res.send(JSON.stringify(result.rows));
});

// Create a rider
  router.route('/api/rider/create').post(async (req, res) => {
    const rname = req.body.rname;
    const rusername = req.body.rusername;
    const rpassword = req.body.rpassword;
    const rtotal_salary = 0;
    const type = req.body.rtype;
    const base_salary = 0;

    console.log(type);

    const type_table_name = type === "full_time" ? "Full_Timer" : "Part_Timer";
    const duration_type = type === "full_time" ? "mth" : "wks"
    
    const queryString = 
    `WITH ins1 AS 
     (INSERT INTO  Rider (rname, rusername, rpassword, rtotal_salary) 
     VALUES ('${rname}', '${rusername}', '${rpassword}', ${rtotal_salary})
     RETURNING rid AS T_RID)
     INSERT INTO ${type_table_name} (rid, base_salary, ${duration_type})
     SELECT T_RID, ${base_salary}, 0 FROM ins1;`;

    console.log(queryString)
    
    pool.query(queryString)
        .then((result) => {
        res.setHeader('content-type', 'application/json');
        res.send(JSON.stringify(result.rows));
        })
        .catch (err => res.status (400).json('Error' + err));
  });

  // Get whether a rider is full-timer or not
  router.route('/api/rider/type/:rid').get(async (req, res) => {
    const id = req.params.rid;

    const queryStringFT = `SELECT * FROM Full_Timer WHERE rid = ${id};`
    
    let resultStr = ''

    resultStr = await pool.query(queryStringFT);

    const type = resultStr.rows.length ? "full_time" : "part_time";
    
    console.log(resultStr)

    res.setHeader('content-type', 'application/json');
    res.send(JSON.stringify(type));
  });

module.exports = router;
