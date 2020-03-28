const router = require ('express').Router ();
const pool = require ('../../config/pool');

// Get a specific orderList
router.route ('/api/orderList/:ocid').get (async (req, res) => {
  const ocid = req.params.ocid;
  const queryString = `SELECT * FROM Order_List WHERE rid = '${rid}'`;

  const result = await pool.query (queryString);
  res.setHeader ('content-type', 'application/json');
  res.send (JSON.stringify (result.rows[0]));
  res.status (200).json ();
});

// Get all order
router.route ('/api/orderLists').get (async (req, res) => {
  const queryString = 'SELECT * FROM Order_List';

  const result = await pool.query (queryString);
  res.setHeader ('content-type', 'application/json');
  res.send (JSON.stringify (result.rows));
  res.status (200).json ();
});

//Post an orderList
router.route ('/api/orderList/:cid').post ((req, res) => {
  console.log ('ran');
  const cid = req.params.cid;
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
  const rid = req.body.rid; //restaurantId

  console.log (req.body);

  pool
    .query (
      `BEGIN;
      INSERT INTO Order_List (oorder_place_time, oorder_enroute_restaurant, oorder_arrives_restaurant, 
      oorder_enroute_customer, oorder_arrives_customer, odelivery_fee, ofinal_price, opayment_type,
      orating, ostatus) 
      VALUES(${oorder_place_time}, ${oorder_enroute_restaurant}, ${oorder_arrives_restaurant},
         ${oorder_enroute_customer}, ${oorder_arrives_customer}, ${odelivery_fee}, ${ofinal_price}, 
         '${opayment_type}', ${orating}, '${ostatus}')
      RETURNING ocid;

      WITH ocid as (SELECT ocid FROM @INSERTED)
      INSERT INTO make_order (rest_rating, review_text, ocid, rid, cid)
      VALUES (${null}, ${null}, ${ocid}, ${rid}, ${cid});

      COMMIT;`
    )
    .then (data => console.log ("I'm here" + data))
    .catch (err => res.status (400).json ('Error' + err));
});

//Update an order
router.route ('/api/orderList/:ocid').patch ((req, res) => {
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

  console.log (req.body);

  pool
    .query (
      `UPDATE Order_List 
       SET oorder_place_time=${oorder_place_time}, oorder_enroute_restaurant=${oorder_enroute_restaurant},
       oorder_arrives_restaurant=${oorder_arrives_restaurant}, oorder_enroute_customer=${oorder_enroute_customer}, 
       oorder_arrives_customer=${oorder_arrives_customer}, odelivery_fee=${odelivery_fee}, 
       ofinal_price=${ofinal_price}, opayment_type='${opayment_type}', orating=${orating},
       ostatus='${ostatus}' 
       WHERE ocid = ${ocid};`
    )
    .then (res.status (204).json ())
    .catch (err => res.status (400).json ('Error' + err));
});

//Find 5 most recent addresses by order by customer
router.route ('/api/orderList/addresses/:cid').patch ((req, res) => {
  const cid = req.params.cid;

  console.log (req.body);

  pool
    .query (
      `SELECT address Order_List 
       SET oorder_place_time=${oorder_place_time}, oorder_enroute_restaurant=${oorder_enroute_restaurant},
       oorder_arrives_restaurant=${oorder_arrives_restaurant}, oorder_enroute_customer=${oorder_enroute_customer}, 
       oorder_arrives_customer=${oorder_arrives_customer}, odelivery_fee=${odelivery_fee}, 
       ofinal_price=${ofinal_price}, opayment_type='${opayment_type}', orating=${orating},
       ostatus='${ostatus}' 
       WHERE ocid = ${ocid};`
    )
    .then (res.status (204).json ())
    .catch (err => res.status (400).json ('Error' + err));
});

module.exports = router;
