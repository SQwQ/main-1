const router = require ('express').Router ();
const pool = require ('../../config/pool');

router.route ('/api/manager/:mid').get (async (req, res) => {
    console.log("Function ran!");
  const mid = req.params.mid;

  const result = await pool.query (`SELECT * FROM Manager WHERE mid=${mid}`);
  res.setHeader ('content-type', 'application/json');
  res.send (JSON.stringify (result.rows[0]));
});

module.exports = router;
