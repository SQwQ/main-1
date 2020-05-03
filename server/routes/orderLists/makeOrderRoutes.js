const router = require('express').Router();
const pool = require('../../config/pool');

// Get all past orders of a user
//  [
//    { "rest_rating": null, 
//      "review_text": "null", 
//       "ocid": 38, 
//       "rid": 2, 
//       "cid": 36",
//       "oorder_place_time": "2020-05-03T06:16:22.504Z", 
//       "oorder_enroute_restaurant": null, 
//       "oorder_arrives_restaurant": null, 
//       "oorder_enroute_customer": null, 
//       "oorder_arrives_customer": null,
//       "odelivery_fee": "5", 
//       "ofinal_price": "5", 
//       "opayment_type": "null", 
//       "orating": 7, 
//       "ostatus": "null"},
//    {...}
//    
//  ]
router
  .route('/api/all_order/:cid')
  .get(async (req, res) => {
    const cid = req.params.cid;

    const queryString = `
      SELECT * FROM make_order
      JOIN order_list on order_list.ocid = make_order.ocid
      WHERE cid = ${cid};
    `;

    pool
      .query(queryString)
      .then(result => {
        res.setHeader('content-type', 'application/json');
        res.send(JSON.stringify(result.rows));
      })
      .catch(err => console.log('Error', err));
  });

// Get rating and text review from a makeOrder row
// {
//   "rest_rating": null,
//   "review_text": "null",
//   "ocid": 43,
//   "rid": 2,
//   "cid": 36
// }
router
  .route('/api/makeOrder/rating_review/:ocid')
  .get(async (req, res) => {
    const ocid = req.params.ocid;

    const queryString = `
      SELECT * FROM make_order 
      WHERE ocid = ${ocid};
    `;

    pool
      .query(queryString)
      .then(result => {
        res.setHeader('content-type', 'application/json');
        res.send(JSON.stringify(result.rows[0]));
      })
      .catch(err => console.log('Errorr', err));
  });

// Update rating(for delivery service) for a makeOrder row
router
  .route('/api/makeOrder/rating/update/:ocid')
  .patch((req, res) => {
    const ocid = req.params.ocid;
    const rest_rating = req.body.rest_rating;

    const queryString = 
    `
      UPDATE make_order
      SET rest_rating=${rest_rating}
      WHERE ocid = ${ocid};
    `;

    pool
      .query(queryString)
      .then(() => res.status(200).json())
      .catch(err => res.status(400).json('Error' + err));
  });

  // Update review(for restaurant's food) for a makeOrder row
router
.route('/api/makeOrder/review/update/:ocid')
.patch((req, res) => {
  const ocid = req.params.ocid;
  const review_text = req.body.review_text;

  const queryString = 
  `
    UPDATE make_order
    SET review_text='${review_text}'
    WHERE ocid = ${ocid};
  `;

  pool
    .query(queryString)
    .then(() => res.status(200).json())
    .catch(err => res.status(400).json('Error' + err));
});

module.exports = router;
