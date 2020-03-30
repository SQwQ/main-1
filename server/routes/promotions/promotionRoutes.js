const router = require('express').Router();
const pool = require('../../config/pool');

//Post a promotion
router.route('/api/promotion/new/:type').post((req, res) => {
  const type = req.params.type;
  const pisPercentage = req.body.pisPercentage;
  const pdatetime_active_from = req.body.pdatetime_active_from;
  const pdatetime_active_to = req.body.pdatetime_active_to;
  const pminSpend = req.body.pminSpend;
  const pdiscount_val = req.body.pdiscount_val;
  const pname = req.body.pname;
  const pdescription = req.body.pdescription;

  pool
    .query(
      `INSERT INTO Promotion (pisPercentage, pdatetime_active_from, pdatetime_active_to, pminSpend, pdiscount_val, pname, pdescription)
    VALUES(${pisPercentage}, ${pdatetime_active_from}, ${pdatetime_active_to}, ${pminSpend}, ${pdiscount_val}, 
        '${pname}', '${pdescription}') returning pid;`
    )
    .then(returnData => {
      console.log('ran');
      if (type == 'coupon') {
        console.log('ran coupon');
        const couponCode = req.body.couponCode;
        pool
          .query(
            `INSERT INTO Coupon (cid, couponCode)
                VALUES(${returnData.rows[0].pid}, '${couponCode}');`
          )
          .catch(err => res.status(400).json('Error' + err));
      } else if (type == 'campaign') {
        console.log('ran campaign');
        const cMon = req.body.cMon;
        const cTue = req.body.cTue;
        const cWed = req.body.cWed;
        const cThu = req.body.cThu;
        const cFri = req.body.cFri;
        const cSat = req.body.cSat;
        const cSun = req.body.cSun;
        pool
          .query(
            `INSERT INTO CAMPAIGN (pid, cMon, cTue, cWed, cThu, cFri, cSat, cSun)
            VALUES(${returnData.rows[0].pid}, ${cMon}, ${cTue}, ${cWed}, ${cThu}, ${cFri}, ${cSat}, ${cSun});`
          )
          .catch(err => res.status(400).json('Error' + err));
      }
      res.status(201).json();
    })
    .catch(err => res.status(400).json('Error' + err));

  //   pool
  //     .query(
  //       `INSERT INTO Customer (cname, ccontact_number, cusername, cpassword, cjoin_time, crewards_points)
  //       VALUES('${cname}', ${ccontact_number}, '${cusername}',
  //          '${cpassword}', ${cjoin_time}, ${crewards_points}) returning cid;`
  //     )
  //     .then(res => {
  //       pool.query(
  //         `INSERT INTO Customer (cname, ccontact_number, cusername, cpassword, cjoin_time, crewards_points)
  //           ALUES('worked', 98123, 'yayitworked2',
  //           'anisdkjnaskdja', null, ${res.rows[0].cid});`
  //       );
  //       res.status(201).json();
  //     })
  //     .catch(err => res.status(400).json('Error' + err));
});

//Update reward
router.route('/api/customer/:cid').patch((req, res) => {
  const cid = req.params.cid;
  const crewards_points = req.body.crewards_points;

  console.log(req.body);

  pool
    .query(
      `UPDATE Customer 
       SET crewards_points=${crewards_points}
       WHERE cid = ${cid};`
    )
    .then(res.status(204).json())
    .catch(err => res.status(400).json('Error' + err));
});

// Get a specific customer
router.route('/api/customer/:cid').get(async (req, res) => {
  const cid = req.params.cid;

  const result = await pool.query(`SELECT * FROM Customer WHERE id=${cid}`);
  res.setHeader('content-type', 'application/json');
  res.send(JSON.stringify(result.rows[0]));
});

// Get a list of all customer
router.route('/api/customers').get(async (req, res) => {
  const result = await pool.query(`SELECT * FROM Customer`);
  res.setHeader('content-type', 'application/json');
  res.send(JSON.stringify(result.rows[0]));
});

module.exports = router;
