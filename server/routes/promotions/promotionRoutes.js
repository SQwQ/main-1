const router = require('express').Router();
const pool = require('../../config/pool');

//Create a promotion
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
});

//Delete a promotion
router.route('/api/promotion/delete/:type/:pid').delete((req, res) => {
  const pid = req.params.pid;
  const type = req.params.type;

  if (type == 'coupon') {
    pool
      .query(
        `BEGIN;
         DELETE FROM Promotion WHERE pid = ${pid};
         DELETE FROM Coupon WHERE cid = ${pid};
         COMMIT;`
      )
      .then(res.status(201).json())
      .catch(err => res.status(400).json('Error' + err));
  } else {
    pool
      .query(
        `BEGIN;
         DELETE FROM Promotion WHERE pid = ${pid};
         DELETE FROM Campaign WHERE pid = ${pid};
         COMMIT;`
      )
      .then(res.status(201).json())
      .catch(err => res.status(400).json('Error' + err));
  }
});

// Update a Promotion
router.route('/api/promotion/update/:pid').patch((req, res) => {
  const pid = req.params.pid;
  console.log('pid', pid);

  const pisPercentage = req.body.pisPercentage;
  const pdatetime_active_from = req.body.pdatetime_active_from;
  const pdatetime_active_to = req.body.pdatetime_active_to;
  const pminSpend = req.body.pminSpend;
  const pdiscount_val = req.body.pdiscount_val;
  const pname = req.body.pname;
  const pdescription = req.body.pdescription;
  console.log('pname', pname);

  pool
    .query(
      `UPDATE Promotion
         SET pisPercentage=${pisPercentage}, pdatetime_active_from=${pdatetime_active_from}, pdatetime_active_to=${pdatetime_active_to}, 
         pminSpend=${pminSpend}, pdiscount_val=${pdiscount_val}, pname='${pname}', pdescription='${pdescription}'
         WHERE pid = ${pid};`
    )
    .then(res.status(204).json())
    .catch(err => res.status(400).json('Error' + err));
});

// Update a Coupon

// Update a Campaign

// Get a Promotion

module.exports = router;
