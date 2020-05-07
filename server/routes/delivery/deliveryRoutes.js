const router = require ('express').Router ();

// Get free man that is free
router.route ('/api/delivery/rider/get').get (async (req, res) => {
  // Didnt have time to complete this section
  const ocid = Math.floor(Math.random() * 22);

  res.setHeader ('content-type', 'application/json');
  res.send (JSON.stringify (ocid));
  res.status (200).json ();
});


// // Get free man that is free, sq solution (to try)
// router.route ('/api/delivery/rider/get').get (async (req, res) => {
//     const queryString = 
//       `
//         SELECT rid FROM Current_Schedule  WHERE scid IN 
//         (SELECT scid FROM Schedule_Count WHERE wkday = EXTRACT(DOW FROM TIMESTAMP [current_time]) 
//         AND start_time = EXTRACT(HOUR FROM TIMESTAMP [current_time]))
//         AND rid NOT IN (SELECT rid FROM delivered_by WHERE ocid IN 
//         (SELECT ocid FROM Order_List WHERE oorder_arrives_customer IS NULL))    
//         LIMIT 1
//       `;
  
//     const result = await pool.query (queryString);
//     res.setHeader ('content-type', 'application/json');
//     res.send (JSON.stringify (result.rows[0].rid));
//     res.status (200).json ();
//   });

module.exports = router;
