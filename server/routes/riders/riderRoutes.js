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

// Create a rider
  router.route('/api/profiles/rider/create').post(async (req, res) => {
    const rname = req.body.rname;
    const rusername = req.body.rusername;
    const rpassword = req.body.rpassword;
    const rtotal_salary = 0;
    const type = req.body.type;
    const base_salary = 0;

    console.log(rname);

    const type_table_name = type == "full_time" ? "Full_Timer" : "Part_Timer";
    

    const queryString = 
    `WITH ins1 AS 
     (INSERT INTO  Rider (rname, rusername, rpassword, rtotal_salary) 
     VALUES ('${rname}', '${rusername}', '${rpassword}', ${rtotal_salary})
     RETURNING rid AS T_RID)
     INSERT INTO  ${type_table_name}
     SELECT T_RID, ${base_salary} FROM ins1;`;
  
    const result = await pool.query(queryString);
    res.setHeader('content-type', 'application/json');
    res.send(JSON.stringify(result.rows));
  });

module.exports = router;
