const router = require ('express').Router ();
const pool = require ('../../config/pool');

// Get a specific food
router.route ('/api/food/:fid').get (async (req, res) => {
  const fid = req.params.fid;
  const queryString = `SELECT * FROM Food WHERE fid = '${fid}'`;

  const result = await pool.query (queryString);
  res.setHeader ('content-type', 'application/json');
  res.send (JSON.stringify (result.rows[0]));
  res.status (200).json ();
});

// Get all foods
router.route ('/api/foods').get (async (req, res) => {
  const queryString = 'SELECT * FROM Food';

  const result = await pool.query (queryString);
  res.setHeader ('content-type', 'application/json');
  res.send (JSON.stringify (result.rows));
  res.status (200).json ();
});

// Get all foods of a restaurant
router.route ('/api/restaurant_food/:rid').get (async (req, res) => {
  const rid = req.params.rid;
  const queryString = `SELECT * FROM Food where rid = ${rid}`;

  const result = await pool.query (queryString);
  res.setHeader ('content-type', 'application/json');
  res.send (JSON.stringify (result.rows));
  res.status (200).json ();
});

//Post a food
router.route ('/api/food/post/:rid').post ((req, res) => {
  const rid = req.params.rid;
  const fname = req.body.fname;
  const fprice = req.body.fprice;
  const favailable = req.body.favailable;
  const flimit = req.body.flimit;
  const fimage = req.body.fimage;

  pool
    .query (
      `INSERT INTO Food (fname, fprice, favailable, flimit, fimage, rid) 
      VALUES('${fname}', ${fprice}, ${favailable}, ${flimit}, '${fimage}', ${rid});`
    )
    .then (res.status (201).json ())
    .catch (err => res.status (400).json ('Error' + err));
  console.log('completed')
});

module.exports = router;
