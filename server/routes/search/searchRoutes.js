const router = require ('express').Router ();
const pool = require ('../../config/pool');

// Get distinct restaurant such that its food related to useriput
// Returns [{rid, rname, raddress, rmincost, rimage, fid}, {..}]
router.route ('/api/search/:input').get (async (req, res) => {
    const input = req.params.input;
    const queryString = 
        `
          SELECT * FROM Food AS F
          LEFT JOIN Restaurant AS R ON R.rid = F.rid
          WHERE fname LIKE '%${input}%';
        `;
  
    const result = await pool.query (queryString);
    res.setHeader ('content-type', 'application/json');
    res.send (JSON.stringify (result.rows));
    res.status (200).json ();
  });

module.exports = router;