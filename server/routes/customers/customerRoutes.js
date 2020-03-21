const router = require ('express').Router ();
const pool = require ('../../config/pool');

// Get a specific customer
router.route ('/api/customer/:cid').get (async (req, res) => {
  const cid = req.params.cid;

  const result = await pool.query (`SELECT * FROM Customer WHERE id=${cid}`);
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
router.route ('/api/customer').post ((req, res) => {
  console.log ('ran');
  const cname = req.body.cname;
  const ccontact_number = req.body.ccontact_number;
  const cusername = req.body.cusername;
  const cpassword = req.body.cpassword;
  const cjoin_time = req.body.cjoin_time;
  const crewards_points = req.body.crewards_points;

  console.log (req.body);

  pool
    .query (
      `INSERT INTO Customer (cname, ccontact_number, cusername, cpassword, cjoin_time, crewards_points) 
      VALUES('${cname}', ${ccontact_number}, '${cusername}',
         '${cpassword}', ${cjoin_time}, ${crewards_points});`
    )
    .then (res.status (201).json ())
    .catch (err => res.status (400).json ('Error' + err));
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
