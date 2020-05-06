/* Make an Order */
/* 1) Insert into Order_List (ofinal_price = 0)
   2) Insert into make_order 
   3) Insert into order_contains (trigger on order_contains will auto discount food prices if promo is applicable) */

/* Update final order price */
   UPDATE Order_List SET ofinal_price = (SELECT SUM(total_price) FROM order_contains WHERE ocid = 'ocid') WHERE ocid = 'ocid';

/* Apply restaurant percentage discount if applicable */
   UPDATE Order_List SET ofinal_price = ofinal_price * 
   (1 - (SELECT SUM(percentage)/100 FROM Promotion WHERE prid = 'restaurant_id' 
   AND CURRENT_TIMESTAMP >= pdatetime_active_from 
	 AND CURRENT_TIMESTAMP <= pdatetime_active_to)) WHERE ocid = 'ocid';

/* Apply Coupons if any. Loop the queries until all the coupons the customer want to use is used up */
   UPDATE Order_List SET ofinal_price = ofinal_price - 
   (SELECT pdiscount_val FROM Promotion WHERE pid = 'coupon_id' 
   AND CURRENT_TIMESTAMP >= pdatetime_active_from 
	 AND CURRENT_TIMESTAMP <= pdatetime_active_to)) WHERE ocid = 'ocid';

   DELETE FROM Coupon WHERE couponCode = 'coupon_code';

/* Give customers reward points */
  UPDATE Customers SET crewards_points =  crewards_points + 1 WHERE cid = 'cid'; 


/* Update Base salary for riders */
UPDATE Full_Timers SET base_salary = x; /* trigger auto updates rider/ mthly past salary table. */
UPDATE Part_Timers SET base_salary = x; /* Same for part timer */

/*
*Support data access for the different users (e.g., customers could view review postings and their past orders,
*riders could view their past work schedules and salaries).
*/

/* view review */
SELECT * FROM make_order WHERE cid = "cid";

/* view past orders */
SELECT * FROM Order_List WHERE ocid in
(SELECT ocid FROM make_order WHERE cid = "cid");

/* full past work schedule */
SELECT * FROM Schedule_PT_Hours WHERE rid = "rid";

SELECT * FROM Schedule_FT_Hours WHERE rid = "rid";

/* full past salary */
SELECT * FROM Monthly_Past_Salaries WHERE rid = "rid";

SELECT * FROM Weekly_Past_Salaries WHERE rid = "rid";

/*
*Support the browsing/searching of food items by customers.
*/

/* By Restaurant */
SELECT * FROM Food WHERE rid = "rid";

/* By Category */
SELECT * FROM Food WHERE fid IN
(SELECT fid FROM food_categorized WHERE cid = "cid");

/* By Category and Price */
SELECT * FROM Food WHERE fid IN
(SELECT fid FROM food_categorized WHERE cid = "cid"
INTERSECT
SELECT fid FROM Food WHERE fprice < "x");

/* By Category and Promotion */
SELECT fid FROM Food WHERE fid IN
(SELECT fid FROM food_categorized WHERE cid = "cid"
INTERSECT
SELECT fid FROM Campaign WHERE cid = "cpid");

/*Support the browsing of summary information for FDS managers. The summary information could
include the following:*/

/*For each month, the total number of new customers, the total number of orders, and the total
cost of all orders.*/

SELECT COUNT(cid) 
FROM Customer c
WHERE c.join_time >= CURRENT_TIMESTAMP - INTERVAL'28 days' 
AND c.cid IN (SELECT cid FROM make_order);

SELECT
COUNT(oid), SUM(ofinal_price)
FROM Order_List 
WHERE oorder_arrives_customer >= CURRENT_TIMESTAMP - INTERVAL '28 days';
 

/*For each month and for each customer who has placed some order for that month,
the total number of orders placed by the customer for that month and the total cost of all
these orders.*/

/* total no. of orders by customer per mth */
SELECT COUNT(ocid) FROM make_order WHERE cid = 'cid' AND ocid IN
(Select ocid FROM 
Order_List,  
WHERE oorder_arrives_customer >= CURRENT_TIMESTAMP - INTERVAL '28 days' 
);

/* total cost of all orders by customer per mth */
SELECT SUM(ofinal_price) FROM Order_List 
WHERE oorder_arrives_customer >= CURRENT_TIMESTAMP - INTERVAL '28 days' AND 
ocid IN
(SELECT ocid FROM make_order WHERE cid = 'cid')

/* For restaurant staff */

/*For each month, the total number of completed orders, the total cost of all completed orders
(excluding delivery fees), and the top 5 favorite food items (in terms of the number of orders
for that item).*/

/* total num of orders per mth/restaurant */
SELECT COUNT(ocid) 
FROM make_order WHERE rid = 'rid' AND ocid IN 
(SELECT ocid FROM Order_List WHERE oorder_arrives_customer >= CURRENT_TIMESTAMP - INTERVAL '28 days') ;

/* total cost of all completed orders per mth */
SELECT SUM(ofinal_price)
FROM Order_List WHERE oorder_arrives_customer >= CURRENT_TIMESTAMP - INTERVAL '28 days' 
AND ocid IN (SELECT ocid FROM make_order WHERE rid = 'rid');

/* Top 5 fav food */
SELECT fid
FROM 
(SELECT fid, COUNT(fid) as Order_num
FROM order_contains WHERE ocid IN 
(SELECT ocid FROM make_order WHERE rid = 'rid' AND ocid IN 
(SELECT ocid FROM Order_List WHERE oorder_arrives_customer >= CURRENT_TIMESTAMP - INTERVAL '28 days')))
ORDER BY Order_num  
LIMIT 5

/*For each rider and for each month, the total number of orders delivered by the rider for that
month, the total number of hours worked by the rider for that month, the total salary earned
by the rider for that month, the average delivery time by the rider for that month, the number
of ratings received by the rider for all the orders delivered for that month, and the average
rating received by the rider for all the orders delivered for that month.*/

/* total number of orders delivered per mth */
SELECT COUNT(rid) FROM delivered_by WHERE rid = 1 AND ocid IN 
(SELECT ocid FROM Order_List WHERE oorder_arrives_customer >= CURRENT_TIMESTAMP - INTERVAL '28 days');

/* the total number of hours worked by the rider for that month */
SELECT COUNT(DISTINCT start_time, wkday)  FROM Schedule_Count WHERE scid IN 
(SELECT scid FROM Current_Schedule WHERE rid = 1);

/* total full time monthly salary */
SELECT rtotal_salary FROM rider WHERE rid = 1;

/* average delivery time per mth */
SELECT SUM(oorder_arrives_customer - oorder_place_time)/COUNT(ocid) FROM Order_List WHERE ocid IN 
(SELECT ocid FROM delivered_by WHERE rid = 1 AND ocid IN 
(SELECT ocid FROM Order_List WHERE oorder_arrives_customer >= CURRENT_TIMESTAMP - INTERVAL '28 days'));


/* the number of ratings received by the rider per mth*/
SELECT COUNT(ocid) FROM delivered_by WHERE rid = 1 AND ocid IN 
(SELECT ocid FROM Order_List WHERE oorder_arrives_customer >= CURRENT_TIMESTAMP - INTERVAL '28 days');

/* the average rating received by the rider per mth */
SELECT SUM(drating)/COUNT(ocid) FROM delivered_by WHERE rid = 1 AND ocid IN 
(SELECT ocid FROM Order_List WHERE oorder_arrives_customer >= CURRENT_TIMESTAMP - INTERVAL '28 days');


/*For each hour and for each delivery location area, the total number of orders placed at that
hour for that location area.*/
SELECT COUNT(ocid) FROM Order_List WHERE oorder_place_time - "TIMESTAMP" <= INTERVAL '1 hour' AND 
ozipcode/10000 = "sector code"


/*For each promotional campaign, the duration (in terms of the number of days/hours) of the
campaign, and the average number of orders received during the promotion (i.e., the ratio of
the total number of orders received during the campaign duration to the number of days/hours
in the campaign duration).*/

/* returns tuple of duration, average number of orders */
SELECT (p0.datetime_active_to - p0.pdatetime_active_from) AS duration,
(SELECT SUM(o.ocid) FROM Order_List o, Promotions p1
WHERE o.oorder_place_time < p1.pdatetime_active_to
AND o.oorder_place_time > p1.pdatetime_active_from
AND p1.pid = 1) / duration
FROM Promotion p0 WHERE p0.pid = 1
