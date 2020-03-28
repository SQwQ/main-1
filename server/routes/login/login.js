const router = require ('express').Router ();
const pool = require ('../../config/pool');

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
router.route ('/api/login').post ((req, res) => {
  console.log ('Request', req.body);

  pool
    .query (
      `SELECT * FROM Restaurant_Staff WHERE rsusername = '${req.body.rsusername}' AND rspassword = '${req.body.rspassword}'`
    )
    .then (result => {
      console.log ('RESULTQUEY', result);
    });
  //   if (result) {
  //     console.log ('Result', result);
  //     res.send (JSON.stringify (result.rows[0]));
  //     return res.status (200).json ();
  //   } else {
  //     return res.status (404).json ('Invalid login credentials');
  //   }
});

module.exports = router;
