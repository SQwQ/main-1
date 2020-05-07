const router = require('express').Router();
const pool = require('../../config/pool');

// Create an orderList
router.route('/api/orderList/create/:rid/:cid').post((req, res) => {
  console.log("run create order")
  const rid = req.params.rid;
  const cid = req.params.cid;
  const oorder_enroute_restaurant = req.body.oorder_enroute_restaurant;
  const oorder_arrives_restaurant = req.body.oorder_arrives_restaurant;
  const oorder_enroute_customer = req.body.oorder_enroute_customer;
  const oorder_arrives_customer = req.body.oorder_arrives_customer;
  const odelivery_fee = req.body.odelivery_fee;
  const ofinal_price = req.body.ofinal_price;
  const opayment_type = req.body.opayment_type;
  const ozipcode = req.body.ozipcode;
  const odelivery_address = req.body.odelivery_address;
  const rest_rating = null;
  const review_text = null;
  const foodIdArray = req.body.foodIdArray;
  const foodPriceArray = req.body.foodPriceArray;
  const foodCountArray = req.body.foodCountArray;
  const riderId = req.body.riderId;

  // 1) Update reward points
  // 2) Insert into Order_List
  // 3) Insert into make_order
  // 4) Insert into deliver_by
  // 5) Insert into order_contains
  pool
    .query(
      `BEGIN;
      
      UPDATE Customer
      SET crewards_points=Customer.crewards_points + ${ofinal_price}
      WHERE cid = ${cid};

      WITH 
      instance1 AS (
        INSERT INTO Order_List (oorder_place_time, oorder_enroute_restaurant, oorder_arrives_restaurant, 
        oorder_enroute_customer, oorder_arrives_customer, odelivery_fee, ofinal_price, opayment_type, ozipcode, odelivery_address) 
        VALUES(NOW(), ${oorder_enroute_restaurant}, ${oorder_arrives_restaurant},
          ${oorder_enroute_customer}, ${oorder_arrives_customer}, ${odelivery_fee}, ${ofinal_price}, 
          '${opayment_type}', ${ozipcode}, '${odelivery_address}') 
        RETURNING ocid AS orderIdCreated
      ),
      instance2 AS (
        INSERT INTO make_order (ocid, rid, cid, rest_rating, review_text) 
        SELECT orderIdCreated, ${rid}, ${cid}, ${rest_rating}, '${review_text}' FROM instance1 returning ocid AS orderIdCreated2
      )

      INSERT INTO delivered_by (ocid, rid, cid)
      SELECT orderIdCreated2, ${riderId}, ${cid} FROM instance2 returning ocid;
    
      COMMIT;`
    )
    .then(returnedData => {
      // Inserting into order_contains
      let currentOcid = returnedData[2].rows[0].ocid;
      for (let i = 0; i < foodIdArray.length; i++) {
        if (foodCountArray[i] !== 0) {
          pool
            .query(
              `INSERT INTO order_contains (ocid, fid, total_price, quantity, unit_price) 
                VALUES(${currentOcid}, ${foodIdArray[i]}, ${foodCountArray[i] * foodPriceArray[i]}, ${foodCountArray[i]}, ${foodPriceArray[i]});`
            )
            .then(() => res.status(200).json())
            .catch(err => res.status(400).json('Error' + err));
        }
      }
    })
    .catch(err => res.status(400).json('Error' + err));
});


// Get a specific orderList
router.route('/api/orderList/:ocid').get(async (req, res) => {
  const ocid = req.params.ocid;
  const queryString = `SELECT * FROM Order_List WHERE ocid = '${ocid}'`;

  const result = await pool.query(queryString);
  res.setHeader('content-type', 'application/json');
  res.send(JSON.stringify(result.rows[0]));
  res.status(200).json();
});

// Get all order
router.route('/api/orderLists').get(async (req, res) => {
  const queryString = 'SELECT * FROM Order_List';

  const result = await pool.query(queryString);
  res.setHeader('content-type', 'application/json');
  res.send(JSON.stringify(result.rows));
  res.status(200).json();
});

// Update an order
router.route('/api/orderList/update/:ocid').patch((req, res) => {
  const ocid = req.params.ocid;
  const oorder_place_time = req.body.oorder_place_time;
  const oorder_enroute_restaurant = req.body.oorder_enroute_restaurant;
  const oorder_arrives_restaurant = req.body.oorder_arrives_restaurant;
  const oorder_enroute_customer = req.body.oorder_enroute_customer;
  const oorder_arrives_customer = req.body.oorder_arrives_customer;
  const odelivery_fee = req.body.odelivery_fee;
  const ofinal_price = req.body.ofinal_price;
  const opayment_type = req.body.opayment_type;
  const orating = req.body.orating;
  const ostatus = req.body.ostatus;

  pool
    .query(
      `UPDATE Order_List 
       SET oorder_place_time=${oorder_place_time}, oorder_enroute_restaurant=${oorder_enroute_restaurant},
       oorder_arrives_restaurant=${oorder_arrives_restaurant}, oorder_enroute_customer=${oorder_enroute_customer}, 
       oorder_arrives_customer=${oorder_arrives_customer}, odelivery_fee=${odelivery_fee}, 
       ofinal_price=${ofinal_price}, opayment_type='${opayment_type}', orating=${orating},
       ostatus='${ostatus}' 
       WHERE ocid = ${ocid};`
    )
    .then(() => res.status(204).json())
    .catch(err => res.status(400).json('Error' + err));
});

// Find 5 most recent addresses by order by customer (need to input timestamp for oorder_place_time columns first)
router.route('/api/orderList/addresses/:cid').patch((req, res) => {
  const cid = req.params.cid;
  console.log(req.body);

  pool
    .query(
      `SELECT address Order_List 
       SET oorder_place_time=${oorder_place_time}, oorder_enroute_restaurant=${oorder_enroute_restaurant},
       oorder_arrives_restaurant=${oorder_arrives_restaurant}, oorder_enroute_customer=${oorder_enroute_customer}, 
       oorder_arrives_customer=${oorder_arrives_customer}, odelivery_fee=${odelivery_fee}, 
       ofinal_price=${ofinal_price}, opayment_type='${opayment_type}', orating=${orating},
       ostatus='${ostatus}' 
       WHERE ocid = ${ocid};`
    )
    .then(() => res.status(204).json())
    .catch(err => res.status(400).json('Error' + err));
});

module.exports = router;
