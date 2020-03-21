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

//Post a food
router.route ('/api/food/:rid').post (async (req, res) => {
  const rid = req.params.rid;

  const fname = req.body.fname;
  const fprice = req.body.fprice;
  const favailable = req.body.favailable;
  const flimit = req.body.flimit;
  const fimage = req.body.fimage;
  const cid = req.body.cid;
  console.log (req.body);
  console.log (req.params.rid);

  pool
    .query (
      `INSERT INTO Food (fname, fprice, favailable, flimit, fimage, rid, cid) 
      VALUES('${fname}', ${fprice}, ${favailable}, ${flimit}, '${fimage}', ${rid}, ${cid});`
    )
    .then (res.status (201).json ())
    .catch (err => res.status (400).json ('Error' + err));
});

module.exports = router;
