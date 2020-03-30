const router = require ('express').Router ();
const pool = require ('../../config/pool');

// Get a specific customer
router.route ('/api/customer/:cid').get (async (req, res) => {
  const cid = req.params.cid;

  const result = await pool.query (`SELECT * FROM Customer WHERE cid=${cid}`);
  res.setHeader ('content-type', 'application/json');
  res.send (JSON.stringify (result.rows[0]));
});

// Get a list of all customer
router.route ('/api/customers').get (async (req, res) => {
  const result = await pool.query (`SELECT * FROM Customer`);
  res.setHeader ('content-type', 'application/json');
  res.send (JSON.stringify (result.rows[0]));
});

//Post an customer
router.route ('/api/customer').post (async (req, res) => {

  console.log (req.body);

  try {
    await pool.query (
      `INSERT INTO Customer (cname, ccontact_number, cusername, cpassword, cjoin_time, crewards_points) 
      VALUES('${req.body.cname}', ${req.body.ccontact_number}, '${req.body.cusername}',
         '${req.body.cpassword}', '${req.body.cjoin_time}', ${req.body.crewards_points});`
    );
    return res.status (201).json ();
  } catch (err) {
    console.log (err);
    return res.status (500).json ('Error' + err);
  }
});

//Update an order
router.route ('/api/customer/:cid').patch ((req, res) => {
  const cid = req.params.cid;
  const crewards_points = req.body.crewards_points;

  console.log (req.body);

  pool
    .query (
      `UPDATE Customer 
       SET crewards_points=${crewards_points}
       WHERE cid = ${cid};`
    )
    .then (res.status (204).json ())
    .catch (err => res.status (400).json ('Error' + err));
});

module.exports = router;
