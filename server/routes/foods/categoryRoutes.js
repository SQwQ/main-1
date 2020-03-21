const router = require ('express').Router ();
const pool = require ('../../config/pool');

// // Get a specific category
// router.route ('/api/category/:cid').get (async (req, res) => {
//   const cid = req.params.cid;
//   const queryString = `SELECT * FROM Category WHERE cid = ${cid}`;

//   const result = await pool.query (queryString);
//   res.setHeader ('content-type', 'application/json');
//   res.send (JSON.stringify (result.rows[0]));
//   res.status(200).json()
// });

// // Get all categories
// router.route ('/api/categories').get (async (req, res) => {
//   const queryString = 'SELECT * FROM Category';

//   const result = await pool.query (queryString);
//   res.setHeader ('content-type', 'application/json');
//   res.send (JSON.stringify (result.rows));
//   res.status(200).json()
// });

// //Post a category
// router.route ('/api/category').post ((req, res) => {
//   const cname = req.body.cname;

//   pool
//     .query (`INSERT INTO Category (cname) VALUES('${cname}');`)
//     .then (res.status(201).json())
//     .catch (err => res.status (400).json ('Error' + err));
// });

// //Delete a category
// router.route ('/api/category/:cid').delete ((req, res) => {
//   const cid = req.params.cid;

//   pool
//     .query (`DELETE FROM Category WHERE cid='${cid}';`)
//     .then (res.status(204).json())
//     .catch (err => res.status (400).json ('Error' + err));
// });

// //Update a category
// router.route ('/api/category/:cid').patch ((req, res) => {
//   const cid = req.params.cid;
//   const cname = req.body.cname;
//   console.log("This is my cname: ", cname);

//   pool
//     .query (`UPDATE Category SET cname='${cname}' WHERE cid='${cid}';`)
//     .then (res.status(204).json())
//     .catch (err => res.status (400).json ('Error' + err));
// });

module.exports = router;
