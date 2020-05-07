const router = require ('express').Router ();
const pool = require ('../../config/pool');

//Post an credit card
router.route ('/api/creditCards/:cid').post ((req, res) => {
  const cid = req.params.cid;
  const card_number = req.body.card_number;
  const expiry_date = req.body.expiry_date;
  const cvv = req.body.cvv;
  const current = req.body.current;

  pool
    .query (
      `INSERT INTO Credit_Card (card_number, expiry_date, cvv, cid, current) 
       VALUES(${card_number}, '${expiry_date}', ${cvv}, ${cid}, ${current});`
    )
    .then (res.status (201).json ())
    .catch (err => res.status (400).json ('Error' + err));
});

// Get credit card numbers owned by customer
router.route ('/api/creditCards/:cid').get (async (req, res) => {
  const cid = req.params.cid;
  const result = await pool.query (
    `SELECT * FROM Credit_Card WHERE cid=${cid}`
  );
  res.setHeader ('content-type', 'application/json');
  res.send (JSON.stringify (result.rows));
});

//Update default credit card for customer
router.route ('/api/creditCard/current/:cid').patch ((req, res) => {
  const cid = req.params.cid;
  const registeredCardNumber = req.body.registeredCardNumber;

  console.log('registerednumber', registeredCardNumber)

  console.log('cid', cid);
     
  pool
    .query (
      `
      BEGIN;
      UPDATE Credit_Card
      SET current=false
      WHERE cid=${cid} AND current=true;

      UPDATE Credit_Card 
      SET current=true
      WHERE cid=${cid} AND card_number=${registeredCardNumber};
      COMMIT;
      `
    )
    .then (res.status (204).json)
    .catch (err => res.status (400).json ('Errorr' + err));
});


//------------------------------------------------------------------------
// Haven't use yet

// Get a specific credit card of a customer
router.route ('/api/creditCard/:ccid').get (async (req, res) => {
  const ccid = req.params.ccid;

  const result = await pool.query (
    `SELECT * FROM Credit_Card WHERE ccid=${ccid}`
  );
  res.setHeader ('content-type', 'application/json');
  res.send (JSON.stringify (result.rows[0]));
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
