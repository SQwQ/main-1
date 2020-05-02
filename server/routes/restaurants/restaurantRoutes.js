const router = require ('express').Router ();
const pool = require ('../../config/pool');

// Get a specific restaurant
router.route ('/api/restaurant/:rid').get (async (req, res) => {
  const rid = req.params.rid;
  const queryString = `SELECT * FROM Restaurant WHERE rid = '${rid}'`;

  const result = await pool.query (queryString);
  res.setHeader ('content-type', 'application/json');
  res.send (JSON.stringify (result.rows[0]));
  res.status (200).json ();
});

// Get all restaurants
router.route ('/api/restaurants').get (async (req, res) => {
  const queryString = 'SELECT * FROM Restaurant';

  const result = await pool.query (queryString);
  res.setHeader ('content-type', 'application/json');
  res.send (JSON.stringify (result.rows));
  res.status (200).json ();
});

//Post a restaurant
router.route ('/api/restaurant').post ((req, res) => {
  const rname = req.body.rname;
  const raddress = req.body.raddress;
  const rmincost = req.body.rmincost;
  const rimage = req.body.rimage;

  pool
    .query (
      `INSERT INTO Restaurant (rname, raddress, rmincost, rimage) 
      VALUES('${rname}', '${raddress}', ${rmincost}, '${rimage}');`
    )
    .then (res.status (201).json ())
    .catch (err => res.status (400).json ('Error' + err));
});

module.exports = router;
