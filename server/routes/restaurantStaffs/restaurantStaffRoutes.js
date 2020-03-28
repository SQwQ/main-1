const router = require ('express').Router ();
const pool = require ('../../config/pool');

// Get a specific restaurantStaff
router.route ('/api/restaurantStaff/:rsid').get (async (req, res) => {
  const rsid = req.params.rid;
  const queryString = `SELECT * FROM Restaurant_Staff WHERE rsid = '${rsid}'`;

  const result = await pool.query (queryString);
  res.setHeader ('content-type', 'application/json');
  res.send (JSON.stringify (result.rows[0]));
  res.status (200).json ();
});

// Get all restaurants
router.route ('/api/restaurantStaffs').get (async (req, res) => {
  const queryString = 'SELECT * FROM Restaurant_Staff';

  const result = await pool.query (queryString);
  res.setHeader ('content-type', 'application/json');
  res.send (JSON.stringify (result.rows));
  res.status (200).json ();
});

//Post a rsstaurantStaff
router.route ('/api/restaurantStaff').post ((req, res) => {
  console.log ('ran');
  const rsname = req.body.rsname;
  const rsposition = req.body.rsposition;
  const rsusername = req.body.rsusername;
  const rspassword = req.body.rspassword;
  const rid = req.body.rid;

  console.log (req.body);

  pool
    .query (
      `INSERT INTO Restaurant_Staff (rsname, rsposition, rsusername, rspassword, rid) 
      VALUES('${rsname}', '${rsposition}', '${rsusername}', '${rspassword}', ${rid});`
    )
    .then (res.status (201).json ())
    .catch (err => res.status (400).json ('Error' + err));
});

//Login
// router.route ('/api/restaurantStaff/login').post ((req, res) => {
//   const queryString = `SELECT rs FROM Restaurant_Staff WHERE rsusername = '${req.body.rsusername}' AND rspassword = '${req.body.rspassword}'`;

//   const result = pool.query (queryString);
//   res.setHeader ('content-type', 'application/json');
//   if (result) {
//     res.send (JSON.stringify (result.rows[0]));
//     return res.status (200).json ();
//   } else {
//     return res.status (404).json ('Invalid login credentials');
//   }
// });
router.route ('/api/restaurantStaff/login').post ((req, res) => {
  console.log ('Request', req.body);

  let result = pool.query (
    `SELECT rs FROM Restaurant_Staff WHERE rsusername = '${req.body.rsusername}' AND rspassword = '${req.body.rspassword}'`
  );
  if (result) {
    res.send (JSON.stringify (result.rows[0]));
    return res.status (200).json ();
  } else {
    return res.status (404).json ('Invalid login credentials');
  }
});

module.exports = router;
