const router = require ('express').Router ();
const pool = require ('../../config/pool');

// User Login
router.route ('/api/login/user').post (async (req, res) => {
  console.log ('Request', req.body.username, req.body.password, req.body.type);

  // Evaluate query based on user type
  var queryString = ''
  switch (req.body.type) {
    case 'Customer':
      queryString = `SELECT cid FROM Customer WHERE cusername = '${req.body.username}' AND cpassword = '${req.body.password}';`;
    break;
    case 'Rider':
      queryString = `SELECT rid FROM Rider WHERE rusername = '${req.body.username}' AND rpassword = '${req.body.password}';`;
    break;
    case 'Staff':
      queryString = `SELECT rsid FROM Restaurant_Staff WHERE rsusername = '${req.body.username}' AND rspassword = '${req.body.password}';`;
    break;
    default:
      queryString = `SELECT fmid FROM FDS_Manager WHERE fmusername = '${req.body.username}' AND fmpassword = '${req.body.password}';`;
  }

  try {
    const result = await pool.query(queryString);
    console.log(result);
    res.setHeader('content-type', 'application/json');
    res.send(JSON.stringify(result.rows[0]));
    res.status(200).json();
  } catch (err) {
    console.log(err);
    res.status(404).json('Unable to connect to server.');
  }
});

module.exports = router;
