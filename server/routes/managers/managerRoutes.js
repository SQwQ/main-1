const router = require ('express').Router ();
const pool = require ('../../config/pool');

router.route ('/api/manager/:mid').get (async (req, res) => {
  const mid = req.params.mid;

  const result = await pool.query (`SELECT * FROM Manager WHERE mid=${mid}`);
  res.setHeader ('content-type', 'application/json');
  res.send (JSON.stringify (result.rows[0]));
});

// Get new customers
router.route ('/api/managers/newCustomers').get (async (req, res) => {
  let date = new Date();
  date.setDate(date.getDate() - 30);
  let date2 = new Date();
  console.log(date);
  console.log(date2);
  const queryString = `SELECT COUNT(*) FROM Customer WHERE cjoin_time >= DATEADD(dd, -30, CURRENT_TIMESTAMP) AND cjoin_time <= CURRENT_TIMESTAMP;`;

  const result = await pool.query (queryString);
  res.setHeader ('content-type', 'application/json');
  res.send (JSON.stringify (result.rows[0]));
  res.status (200).json ();
});

router.route ('/api/managers/orders').get (async (req, res) => {
  let date = new Date();
  date.setDate(date.getDate() - 30);
  let date2 = new Date();
  console.log(date);
  console.log(date2);
  const queryString = `SELECT COUNT(*) FROM Order_List WHERE oorder_place_time >= DATEADD(dd, -30, CURRENT_TIMESTAMP) AND oorder_place_time <= CURRENT_TIMESTAMP;`;

  const result = await pool.query (queryString);
  res.setHeader ('content-type', 'application/json');
  res.send (JSON.stringify (result.rows[0]));
  res.status (200).json ();
});

module.exports = router;
