/*
*Support the creation/deletion/update of data for the different users (customers, restaurant staff,delivery riders, and FDS managers).
*/

INSERT INTO Restaurant_Staff (rsid, rsname, rsposition, rsusername, rspassword, rid)
VALUES (rsid, rsname, rsposition, rsusername, rspassword, rid);	

INSERT INTO Restaurant (rid, rname, raddress, rminCost, rimage)
VALUES (rid, rname, raddress, rminCost, rimage);

INSERT INTO Food (fid, fname, fprice, favailable, flimit, fimage, rid)
VALUES (fid, fname, fprice, favailable, flimit, fimage, rid);

INSERT INTO Category (cid, cname)
VALUES (cid, cname);

INSERT INTO Order (oid, oorder_place_time, oorder_enroute_restaurant, oorder_arrives_restaurant, oorder_enroute_customer, oorder_arrives_customer, odelivery_fee, ofinal_price, opayment_type, orating, ostatus)
VALUES (oid, oorder_place_time, oorder_enroute_restaurant, oorder_arrives_restaurant, oorder_enroute_customer, oorder_arrives_customer, odelivery_fee, ofinal_price, opayment_type, orating, ostatus);

INSERT INTO make_order(rest_rating, review_text, oid, rid, cid)
VALUES (rest_rating, review_text, oid, rid, cid);

INSERT INTO Promotions (pid, pisPercentage, pdatetime_active_from, pdatetime_active_to, pminSpend, pdiscount_val, pname, pdescription)
VALUES (pid, pisPercentage, pdatetime_active_from, pdatetime_active_to, pminSpend, pdiscount_val, pname, pdescription)


INSERT INTO Coupon (cid, couponCode)
VALUES (cid, couponCode)


INSERT INTO Campaign (cid, cMon, cTue, cWed, cThu, cFri, cSat, cSun)
VALUES (cid, cMon, cTue, cWed, cThu, cFri, cSat, cSun);

INSERT INTO Customer (cid, cname, ccontact_number, cusername, cpassword, cjoin_time, crewards_points)
VALUES (cid, cname, ccontact_number, cusername, cpassword, cjoin_time, crewards_points)


INSERT INTO Address (address_line, zipcode, cid)
VALUES (address_line, zipcode, cid);

INSERT INTO Credit_Card (card_number, expiry_date, cvv)
VALUES (card_number, expiry_date, cvv);

INSERT INTO  Rider (rid,  rname, rusername, rpassword, rtotal_salary)
VALUES (rid,  rname, rusername, rpassword, rtotal_salary);

/*
*Support data access for the different users (e.g., customers could view review postings and their past orders,
*riders could view their past work schedules and salaries).
*/

/* view review */
SELECT * FROM make_order WHERE mcid = "cid";

/* view past orders */
SELECT * FROM Order WHERE oid = 
(SELECT oid FROM make_order WHERE cid = "cid");

/* past work schedule */
SELECT * FROM Monthly_WS WHERE rid = "rid";

SELECT * FROM Weekly_WS WHERE rid = "rid";

/* past salary */
SELECT * FROM Monthly_Past_Salaries WHERE rid = "rid";

SELECT * FROM Weekly_Past_Salaries WHERE rid = "rid";

/*
*Support the browsing/searching of food items by customers.
*/

/* By Restaurant */
SELECT * FROM Food WHERE rid = "rid"

/* By Category */
SELECT * FROM Food WHERE fid =
(SELECT fid FROM food_categorized WHERE cid = "cid");

/* By Category and Price */
SELECT * FROM Food WHERE fid =
(SELECT fid FROM food_categorized WHERE cid = "cid"
INTERSECT
SELECT fid FROM Food WHERE fprice < "x");

/* By Category and Promotion */
SELECT fid FROM Food WHERE fid =
(SELECT fid FROM food_categorized WHERE cid = "cid"
INTERSECT
SELECT fid FROM Campaign WHERE cid = "cpid");

/*Support the browsing of summary information for FDS managers. The summary information could
include the following:*/

/*For each month, the total number of new customers, the total number of orders, and the total
cost of all orders.*/

SELECT new_cust_num as
(SELECT COUNT(cid) 
FROM Customer c
WHERE c.join_time >= CURRENT_TIMESTAMP - INTERVAL'28 days' 
AND c.cid IN 
(SELECT cid FROM Order_List WHERE rid = 'rid')), 
COUNT(oid), SUM(ofinal_price)
FROM Order_List 
WHERE oorder_place_time >= CURRENT_TIMESTAMP - INTERVAL '28 days'
AND rid = 'rid'
 

/*For each month and for each customer who has placed some order for that month,
the total number of orders placed by the customer for that month and the total cost of all
these orders.*/

SELECT COUNT(oid), SUM(total_price) 
FROM order_contains WHERE oid =
(Select o.oid FROM 
Order_List o,  
WHERE o.oorder_place_time >= CURRENT_TIMESTAMP - INTERVAL '28 days' 
AND o.cid = 'cid')


/*For each month, the total number of completed orders, the total cost of all completed orders
(excluding delivery fees), and the top 5 favorite food items (in terms of the number of orders
for that item).*/

SELECT COUNT(oid), SUM(ofinal_price)
FROM Order_List WHERE oorder_place_time >= CURRENT_TIMESTAMP - INTERVAL '28 days' 

SELECT fid
FROM 
(SELECT fid, COUNT(fid) as Order_num
FROM Order_List WHERE oorder_place_time >= CURRENT_TIMESTAMP - INTERVAL '28 days') AS X
ORDER BY Order_num  
LIMIT 5

/*For each rider and for each month, the total number of orders delivered by the rider for that
month, the total number of hours worked by the rider for that month, the total salary earned
by the rider for that month, the average delivery time by the rider for that month, the number
of ratings received by the rider for all the orders delivered for that month, and the average
rating received by the rider for all the orders delivered for that month.*/

SELECT part_time_hr FROM
(SELECT rid, SUM(wkly.daily_hr) AS part_time_hr FROM
(SELECT dws.wid, SUM(day.shifts) AS daily_hr
FROM 
(SELECT sh.did, SUM(h.hours) AS shifts 
FROM (SELECT hid, (endTime - startTime) AS hours FROM Hour_Block) AS h, schedule_hours sh 
WHERE h.hid = sh.hid) AS day, Day_WS dws
WHERE day.did = dws.did) as wkly, Weekly_WS as wws
WHERE wkly.wid = wws.wid) as pth
WHERE pth.rid = 'rid'


SELECT full_time_hr FROM
(SELECT rid, SUM(mthly.wkly_hr) AS full_time_hr FROM
(SELECT mid, SUM(wkly.daily_hr) AS wkly_hr FROM
(SELECT dws.wid, SUM(day.shifts) AS daily_hr
FROM 
(SELECT sh.did, SUM(h.hours) AS shifts 
FROM (SELECT hid, (endTime - startTime) AS hours FROM Hour_Block) AS h, schedule_hours sh 
WHERE h.hid = sh.hid) AS day, Day_WS dws
WHERE day.did = dws.did) as wkly, Weekly_WS as wws
WHERE wkly.wid = wws.wid) as mthly, Monthly_WS as mws
WHERE mthly.mid = mws.mid) as fth
WHERE fth.rid = 'rid' 


/*For each hour and for each delivery location area, the total number of orders placed at that
hour for that location area.*/

/*INCOMPLETE NEED TO SETTLE AREA*/

SELECT COUNT(oid) FROM Order_List WHERE
oorder_place_time >= CURRENT_TIMESTAMP - INTERVAL '1 hour'

/*For each promotional campaign, the duration (in terms of the number of days/hours) of the
campaign, and the average number of orders received during the promotion (i.e., the ratio of
the total number of orders received during the campaign duration to the number of days/hours
in the campaign duration).*/

SELECT
  (p0.datetime_active_to - p0.pdatetime_active_from) AS duration,
  (
    SELECT
      SUM(o.oid)
    FROM
      Order_List o,
      Promotions p1
    WHERE
      o.oorder_place_time < p1.pdatetime_active_to
      AND o.oorder_place_time > p1.pdatetime_active_from
  ) / duration
FROM
  Promotion p0

