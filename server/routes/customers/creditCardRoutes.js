const router = require ('express').Router ();
const pool = require ('../../config/pool');

// Get a specific credit card
router.route ('/api/creditCard/:ccid').get (async (req, res) => {
  const ccid = req.params.ccid;

  const result = await pool.query (
    `SELECT * FROM Credit_Card WHERE ccid=${ccid}`
  );
  res.setHeader ('content-type', 'application/json');
  res.send (JSON.stringify (result.rows[0]));
});

// Get credit cards by customer
router.route ('/api/creditCards/:cid').get (async (req, res) => {
  const cid = req.params.cid;
  const result = await pool.query (
    `SELECT * FROM Credit_Card WHERE cid=${cid}`
  );
  res.setHeader ('content-type', 'application/json');
  res.send (JSON.stringify (result.rows));
});

//Post an credit card
router.route ('/api/creditCards/:cid').post ((req, res) => {
  console.log ('ran');
  const cid = req.params.cid;
  const card_number = req.body.card_number;
  const expiry_date = req.body.expiry_date;
  const cvv = req.body.cvv;

  console.log (req.body);

  pool
    .query (
      `INSERT INTO Credit_Card (card_number, expiry_date, cvv, cid) 
      VALUES(${card_number}, '${expiry_date}', ${cvv}, ${cid});`
    )
    .then (res.status (201).json ())
    .catch (err => res.status (400).json ('Error' + err));
});

//Delete Credit Card
router.route ('/api/creditCard/:ccid').delete ((req, res) => {
  const ccid = req.params.ccid;

  pool
    .query (`DELETE FROM Credit_Card WHERE ccid='${ccid}';`)
    .then (res.status (204).json ())
    .catch (err => res.status (400).json ('Error' + err));
});

module.exports = router;
