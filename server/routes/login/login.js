const router = require ('express').Router ();
const pool = require ('../../config/pool');

// Login
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

// User Login
router.route ('/api/login/user').post (async (req, res) => {
  console.log ('Request', req.body.cusername, req.body.cpassword);

  const queryString = `SELECT cid FROM Customer WHERE cusername = '${req.body.cusername}' AND cpassword = '${req.body.cpassword}'`;

  const result = await pool.query(queryString);
  console.log(result);
  res.setHeader('content-type', 'application/json');
  res.send(JSON.stringify(result.rows[0]));
  res.status(200).json();

  //   if (result) {
  //     console.log ('Result', result);
  //     res.send (JSON.stringify (result.rows[0]));
  //     return res.status (200).json ();
  //   } else {
  //     return res.status (404).json ('Invalid login credentials');
  //   }
});

module.exports = router;
