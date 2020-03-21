const router = require('express').Router();
const pool = require('../../config/pool');

// Get all listings
router.route('/api/all_listings').get(async (req, res) => {
  const result = await pool.query(
    'SELECT * FROM public."Listings"'
  );
  res.setHeader('content-type', 'application/json');
  res.send(JSON.stringify(result.rows));
});

// Get all listings based on a keyword
router.route('/api/listings/:keyword').get(async (req, res) => {
  const keyword = req.params.keyword;
  const result = await pool.query(
    `SELECT * FROM public."Listings" WHERE "title" LIKE '%${keyword}%' OR "desc" LIKE '%${keyword}%'`
  );
  res.setHeader('content-type', 'application/json');
  res.send(JSON.stringify(result.rows));
});

// Get listings of a particular user 
router.route('/api/listings/:userId').get(async (req, res) => {
  const userId = req.params.userId;
  const result = await pool.query(
    `SELECT * FROM public."Listings" WHERE "userId" = '${userId}'`
  );
  res.setHeader('content-type', 'application/json');
  res.send(JSON.stringify(result.rows));
});

// Get a particular listing
router.route('/api/view/:id').get(async (req, res) => {
  const idToView = req.params.id;

  const result = await pool.query(
    `SELECT * FROM public."Listings" WHERE id = ${idToView}`
  );
  res.setHeader('content-type', 'application/json');
  res.send(JSON.stringify(result.rows[0]));
});

// Add a new listing
router.route('/api/new').post((req, res) => {
  const title = req.body.title;
  const desc = req.body.desc;
  const location = req.body.location;
  const price = req.body.price;
  const isGroup = req.body.isGroup;
  const role = req.body.role;
  const category = req.body.category;

  pool
    .query(
      `INSERT INTO public."Listings"("title", "desc", "location", "price", "isGroup", "role", "category", "userId") 
      VALUES('${title}', '${desc}', '${location}', ${price}, ${isGroup}, '${role}', '${category}', '${req.user.googleId}');`)
    .then(() => console.log("Successfully added new listing"))
    .catch(err => res.status(400).json('Error' + err));

});

// Delete a listing
router.route('/api/delete/:id').delete((req, res) => {
  const idToDelete = req.params.id;

  pool
    .query(
      `DELETE FROM public."Listings" WHERE "id" = '${idToDelete}'`)
    .then(() => console.log(`Successfully deleted listing of id ${idToDelete}`))
    .catch(err => res.status(400).json('Error' + err));
});

//Edit a listing

module.exports = router;
