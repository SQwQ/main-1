const router = require ('express').Router ();
const pool = require ('../../config/pool');

// Get a specific food
router.route ('/api/food/:fid').get (async (req, res) => {
  const fid = req.params.fid;
  const queryString = `
      SELECT * FROM Food F
      JOIN food_categorized FC ON F.fid = FC.fid
      JOIN Category C ON FC.cid = C.cid
      WHERE F.fid = ${fid};
    `;

  const result = await pool.query (queryString);
  res.setHeader ('content-type', 'application/json');
  res.send (JSON.stringify (result.rows[0]));
  res.status (200).json ();
});

// Get all foods
router.route ('/api/foods').get (async (req, res) => {
  const queryString = `
      SELECT * FROM Food F
      JOIN food_categorized FC ON F.fid = FC.fid
      JOIN Category C ON FC.cid = C.cid;
    `;

  const result = await pool.query (queryString);
  res.setHeader ('content-type', 'application/json');
  res.send (JSON.stringify (result.rows));
  res.status (200).json ();
});

// Get all foods of a restaurant
router.route ('/api/restaurant_food/:rid').get (async (req, res) => {
  const rid = req.params.rid;
  const queryString = `
    SELECT * FROM Food F
    JOIN food_categorized FC ON F.fid = FC.fid
    JOIN Category C ON FC.cid = C.cid
    WHERE F.rid = ${rid};
  `;

  const result = await pool.query (queryString);
  res.setHeader ('content-type', 'application/json');
  res.send (JSON.stringify (result.rows));
  res.status (200).json ();
});

//Delete food
router.route ('/api/restaurant_food/:fid').delete (async (req, res) => {
  const fid = req.params.fid;
  const queryString = `DELETE FROM Food WHERE fid = ${fid};`;

  pool
    .query (
      `DELETE FROM Food WHERE fid = ${fid};`
    )
    .then (res.status (201).json ())
    .catch (err => res.status (400).json ('Error' + err));
});

//Post a food (to update)
router.route ('/api/food/post/:rid').post ((req, res) => {
  const rid = req.params.rid;
  const fname = req.body.fname;
  const fprice = req.body.fprice;
  const favailable = req.body.favailable;
  const flimit = req.body.flimit;

  pool
    .query (
      `INSERT INTO Food (fname, fprice, favailable, flimit, rid) 
      VALUES('${fname}', ${fprice}, ${favailable}, ${flimit}, '${rid}');`
    )
    .then (res.status (201).json ())
    .catch (err => res.status (400).json ('Error' + err));
});

//Update a food (to update)
router.route ('/api/food/update/:fid/:rid').post ((req, res) => {
  const fid = req.params.fid;
  const rid = req.params.rid;
  const fname = req.body.fname;
  const fprice = req.body.fprice;
  const favailable = (req.body.favailable === 'true');
  const flimit = req.body.flimit;

  pool
    .query (
      `UPDATE Food 
      SET fname = '${fname}', fprice = ${fprice}, favailable = ${favailable}, flimit = ${flimit}
      WHERE fid = '${fid}';`
    )
    .then (res.status (201).json ())
    .catch (err => res.status (400).json ('Error' + err));
  console.log ('completed');
});

module.exports = router;
