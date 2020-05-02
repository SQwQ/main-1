const router = require('express').Router();
const pool = require('../../config/pool');

// Get rating and text review from a makeOrder row
router
  .route('/api/makeOrder/rating_review/:ocid/:rid/:cid')
  .get(async (req, res) => {
    const ocid = req.params.ocid;
    const rid = req.params.rid;
    const cid = req.params.cid;

    const queryString = `
      SELECT * FROM make_order 
      WHERE rid = ${rid} AND ocid = ${ocid} AND cid = ${cid};
    `;

    pool
      .query(queryString)
      .then(result => {
        res.setHeader('content-type', 'application/json');
        res.send(JSON.stringify(result.rows[0]));
      })
      .catch(err => console.log('Errorr', err));
  });

// Update rating and review for a makeOrder row
router
  .route('/api/makeOrder/rating_review/update/:ocid/:rid/:cid')
  .patch((req, res) => {
    const ocid = req.params.ocid;
    const rid = req.params.rid;
    const cid = req.params.cid;

    const rest_rating = req.body.rest_rating;
    const review_text = req.body.review_text;

    const queryString = 
    `
      UPDATE make_order
      SET review_text='${review_text}', rest_rating=${rest_rating}
      WHERE rid = ${rid} AND ocid = ${ocid} AND cid = ${cid};
    `;

    pool
      .query(queryString)
      .then(() => res.status(200).json())
      .catch(err => res.status(400).json('Error' + err));
  });

module.exports = router;
