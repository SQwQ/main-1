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



