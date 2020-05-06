/* Drop any existing tables in database (on user init, this database should be empty anyway.)*/

DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;

/*****************************************************************************************************/
/************************************* Data Schema Definition ****************************************/
/*****************************************************************************************************/
/*
    FDS Manager
*/
CREATE TABLE FDS_Manager (
    fmid SERIAL NOT NULL PRIMARY KEY,
    fmname VARCHAR(50) UNIQUE NOT NULL,
    fmusername VARCHAR(50) UNIQUE NOT NULL,
    fmpassword VARCHAR(50) NOT NULL
);

/* Default FDS_Manager Account FIXED. */
INSERT INTO FDS_Manager (fmname, fmusername, fmpassword) VALUES ('John Smith', 'admin', 'password');

/*
	Restaurant
*/
CREATE TABLE Restaurant (
	rid SERIAL NOT NULL PRIMARY KEY,
	rname VARCHAR(50) UNIQUE NOT NULL,
	raddress VARCHAR(255) NOT NULL,
	rminCost NUMERIC NOT NULL,
	rimage TEXT
);

CREATE TABLE Restaurant_Staff (
	rsid SERIAL NOT NULL PRIMARY KEY,
	rsname VARCHAR(50) NOT NULL,
	rsposition VARCHAR(50) NOT NULL,
	rsusername VARCHAR(50) NOT NULL UNIQUE,
	rspassword VARCHAR(50) NOT NULL,
	rid SERIAL NOT NULL,
	FOREIGN KEY (rid) REFERENCES Restaurant ON DELETE CASCADE
);

/*
	Food
*/
CREATE TABLE Food (
	fid SERIAL NOT NULL PRIMARY KEY,
	fname VARCHAR(255) NOT NULL,
	fprice NUMERIC NOT NULL CHECK (fprice >= 0),
	favailable BOOLEAN NOT NULL,
	flimit INT NOT NULL CHECK (flimit >= 0),
	fimage TEXT,
	rid SERIAL NOT NULL,
	FOREIGN KEY (rid) REFERENCES Restaurant(rid)
);

CREATE TABLE Category (
	cid SERIAL NOT NULL PRIMARY KEY,
	cname VARCHAR(50)
);

CREATE TABLE food_categorized (
	fid SERIAL NOT NULL,
	cid SERIAL NOT NULL,
	FOREIGN KEY (fid) REFERENCES Food(fid),
	FOREIGN KEY (cid) REFERENCES Category(cid)
);

/*
	Orders and Customer
*/
CREATE TABLE Order_List (
	ocid SERIAL NOT NULL PRIMARY KEY,
	oorder_place_time TIMESTAMP NOT NULL,
	oorder_enroute_restaurant TIMESTAMP,
	oorder_arrives_restaurant TIMESTAMP,
	oorder_enroute_customer TIMESTAMP,
	oorder_arrives_customer TIMESTAMP,
	odelivery_fee NUMERIC NOT NULL CHECK (odelivery_fee >= 0),
	ofinal_price NUMERIC NOT NULL CHECK (ofinal_price >= 0),
	ozipcode NUMERIC NOT NULL,
	odelivery_address TEXT,
	opayment_type TEXT NOT NULL
);

CREATE TABLE order_contains (
	unit_price NUMERIC NOT NULL CHECK (unit_price >= 0),
	quantity INTEGER NOT NULL CHECK (quantity > 0),
	total_price NUMERIC NOT NULL CHECK (total_price >= 0),
	fid SERIAL NOT NULL,
	ocid SERIAL NOT NULL,
	PRIMARY KEY (fid, ocid),
	FOREIGN KEY (fid) REFERENCES Food(fid),
	FOREIGN KEY (ocid) REFERENCES Order_List(ocid)
);

/* Apply promo to food price */

CREATE OR REPLACE FUNCTION apply_promo()
  RETURNS trigger AS

$BODY$
DECLARE promo INT;
BEGIN
    SELECT pid INTO promo FROM Offer_On WHERE fid = NEW.fid;
	IF promo IS NOT NULL 
	AND CURRENT_TIMESTAMP >= (SELECT pdatetime_active_from FROM Promotion WHERE pid = promo)
	AND CURRENT_TIMESTAMP <= (SELECT pdatetime_active_to FROM Promotion WHERE pid = promo)
	THEN
	UPDATE order_contains
	SET unit_price = unit_price - (SELECT pdiscount_val FROM Promotion WHERE pid = promo),
	total_price = total_price - 
	(SELECT pdiscount_val FROM Promotion WHERE pid = promo) * quantity
	WHERE ocid = NEW.ocid AND fid = NEW.fid;
	
    END IF;

    RETURN NULL;

END; 
$BODY$
LANGUAGE plpgsql ;

DROP TRIGGER IF EXISTS apply_promo ON order_contains;
CREATE TRIGGER apply_promo
  AFTER INSERT
  ON order_contains
  FOR EACH ROW
  EXECUTE PROCEDURE apply_promo();

/* Enforce quantity/availability constraint */

CREATE OR REPLACE FUNCTION food_limit()
  RETURNS trigger AS

$BODY$
DECLARE order_limit INT;
BEGIN
    SELECT flimit INTO order_limit FROM Food WHERE fid = NEW.fid;
    
    IF NEW.quantity > order_limit THEN
    DELETE FROM order_contains WHERE ocid = NEW.ocid AND fid = NEW.fid; 
    RAISE EXCEPTION USING MESSAGE = 'You ordered too much food!';
    
    ELSEIF (SELECT favailable FROM Food WHERE fid = NEW.fid) = False THEN
    DELETE FROM order_contains WHERE ocid = NEW.ocid AND fid = NEW.fid; 
    RAISE EXCEPTION USING MESSAGE = 'The item is currently unavailable';
    
    ELSEIF (SELECT rid FROM Food WHERE fid = NEW.fid) NOT IN 
    (SELECT rid FROM Food WHERE fid IN (SELECT fid FROM order_contains WHERE ocid = NEW.ocid)) THEN
    DELETE FROM order_contains WHERE ocid = NEW.ocid AND fid = NEW.fid; 
    RAISE EXCEPTION USING MESSAGE = 'You can only order food from the same restaurant';			
    
    END IF;
    UPDATE Food SET flimit = order_limit - NEW.quantity WHERE fid = NEW.fid;

    RETURN NULL;

END; 
$BODY$
LANGUAGE plpgsql ;

DROP TRIGGER IF EXISTS food_limit ON order_contains;
CREATE TRIGGER food_limit
  AFTER INSERT
  ON order_contains
  FOR EACH ROW
  EXECUTE PROCEDURE food_limit();

/* Update food order_limit if order is cancelled */
CREATE OR REPLACE FUNCTION cancel_order()
  RETURNS trigger AS

$BODY$
DECLARE order_limit INT;
BEGIN
    SELECT flimit INTO order_limit FROM Food WHERE fid = OLD.fid;
    UPDATE Food SET flimit = order_limit + OLD.quantity WHERE fid = OLD.fid;
    RETURN NULL;
END; 
$BODY$
LANGUAGE plpgsql ;

DROP TRIGGER IF EXISTS cancel_order ON order_contains;
CREATE TRIGGER cancel_order
  AFTER DELETE
  ON order_contains
  FOR EACH ROW
  EXECUTE PROCEDURE cancel_order();

CREATE TABLE Customer (
	cid SERIAL NOT NULL PRIMARY KEY,
	cname VARCHAR(50) NOT NULL,
	ccontact_number INT,
	cusername VARCHAR(50) NOT NULL UNIQUE,
	cpassword VARCHAR(50) NOT NULL,
	cjoin_time TIMESTAMP NOT NULL,
	crewards_points INT NOT NULL
);

CREATE TABLE make_order (
	rest_rating INTEGER,
	review_text TEXT,
	ocid SERIAL NOT NULL UNIQUE,
	rid SERIAL NOT NULL,
	cid SERIAL NOT NULL,
	FOREIGN KEY (ocid) REFERENCES Order_List(ocid),
	FOREIGN KEY (rid) REFERENCES Restaurant(rid),
	FOREIGN KEY (cid) REFERENCES Customer(cid)
);


/*
	Promotions and coupons
*/
CREATE TABLE Promotion (
	pid SERIAL NOT NULL PRIMARY KEY,
	prid SERIAL NOT NULL,
	percentage NUMERIC NOT NULL,
	pdatetime_active_from TIMESTAMP NOT NULL,
	pdatetime_active_to TIMESTAMP NOT NULL CHECK (pdatetime_active_to > pdatetime_active_from),
	pminSpend NUMERIC NOT NULL CHECK (pminSpend >= 0),
	pdiscount_val NUMERIC NOT NULL,
	pname TEXT NOT NULL,
	pdescription TEXT NOT NULL,
	FOREIGN KEY (prid) REFERENCES Restaurant(rid)

);

CREATE TABLE Coupon (
	cid SERIAL NOT NULL,
	PRIMARY KEY (cid),
	couponCode VARCHAR(10) NOT NULL UNIQUE,
	FOREIGN KEY (cid) REFERENCES Promotion(pid) ON DELETE CASCADE
);

CREATE TABLE coupon_wallet (
	custid SERIAL NOT NULL,
	cid SERIAL NOT NULL,
	FOREIGN KEY (custid) REFERENCES Customer(cid) ON DELETE CASCADE,
	FOREIGN KEY (cid) REFERENCES Coupon(cid) ON DELETE CASCADE
);

CREATE TABLE Campaign (
	pid SERIAL NOT NULL PRIMARY KEY,
	FOREIGN KEY (pid) REFERENCES Promotion(pid) ON DELETE CASCADE,
	cMon BOOLEAN NOT NULL,
	cTue BOOLEAN NOT NULL,
	cWed BOOLEAN NOT NULL,
	cThu BOOLEAN NOT NULL,
	cFri BOOLEAN NOT NULL,
	cSat BOOLEAN NOT NULL,
	cSun BOOLEAN NOT NULL
);

CREATE TABLE Offer_On (
	fid SERIAL NOT NULL,
	pid SERIAL NOT NULL,
	FOREIGN KEY (fid) REFERENCES Food(fid),
	FOREIGN KEY (pid) REFERENCES Campaign(pid)
);

/*
	Customer Details
*/
-- Omitted due to redundancy
--
--CREATE TABLE Address (
--	address_line TEXT NOT NULL,
--	zipcode INT NOT NULL,
--	cid SERIAL,
--	FOREIGN KEY (cid) REFERENCES Customer(cid) ON DELETE CASCADE
-- );
--

CREATE TABLE Credit_Card (
	card_number BIGINT NOT NULL,
	expiry_date DATE NOT NULL,
	cvv INT NOT NULL,
	PRIMARY KEY(card_number, expiry_date, cvv)
);

CREATE TABLE register_cc (
	card_number BIGINT NOT NULL,
	expiry_date DATE NOT NULL,
	cvv INT NOT NULL,
	cid SERIAL,
	FOREIGN KEY (card_number, expiry_date, cvv) REFERENCES Credit_Card(card_number, expiry_date, cvv),
	FOREIGN KEY (cid) REFERENCES Customer(cid)
);

/*
	Riders
*/
CREATE TABLE Rider (
	rid SERIAL NOT NULL PRIMARY KEY,
	rname VARCHAR(255) NOT NULL,
	rusername VARCHAR(50) NOT NULL UNIQUE,
	rpassword VARCHAR(50) NOT NULL,
	rtotal_salary NUMERIC NOT NULL
);

/* added wks */
CREATE TABLE Part_Timer (
	rid SERIAL NOT NULL PRIMARY KEY,
	base_salary NUMERIC NOT NULL,
	wks INT NOT NULL,
	FOREIGN KEY (rid) REFERENCES Rider ON DELETE CASCADE
);

CREATE TABLE Weekly_Past_Salaries (
	rid SERIAL NOT NULL,
	week_no INTEGER NOT NULL,
	salary NUMERIC NOT NULL,
	base_salary NUMERIC NOT NULL,
	PRIMARY KEY (rid, week_no),
	FOREIGN KEY (rid) REFERENCES Part_Timer ON DELETE CASCADE
);

/* added mth */
CREATE TABLE Full_Timer (
	rid SERIAL NOT NULL PRIMARY KEY,
	base_salary NUMERIC NOT NULL,
	mth INT NOT NULL,
	FOREIGN KEY (rid) REFERENCES Rider ON DELETE CASCADE
);

CREATE TABLE Monthly_Past_Salaries (
	rid SERIAL NOT NULL,
	month_no INTEGER NOT NULL,
	salary NUMERIC NOT NULL,
	base_salary NUMERIC NOT NULL,
	PRIMARY KEY (rid, month_no),
	FOREIGN KEY (rid) REFERENCES Full_Timer ON DELETE CASCADE

);

/* SALARY TRIGGER to add delivery fee for each completed order to respective rider's salary */

CREATE OR REPLACE FUNCTION update_order_salary()
  RETURNS trigger AS

$BODY$
DECLARE curr_rider INT;
BEGIN
    SELECT rid INTO curr_rider FROM make_order 
    WHERE ocid = NEW.ocid;

    IF NEW.oorder_arrives_customer IS NOT NULL AND curr_rider IN 
	  (SELECT rid FROM Part_Timer) THEN

    UPDATE Weekly_Past_Salaries 
	  SET salary = salary + NEW.odelivery_fee
    WHERE week_no = (SELECT curr_wk FROM Current_Schedule WHERE rid = curr_rider)
    AND rid = curr_rider;

    ELSEIF  NEW.oorder_arrives_customer IS NOT NULL AND curr_rider IN 
	  (SELECT rid FROM Full_Timer) THEN

    UPDATE Monthly_Past_Salaries
	  SET salary = salary + NEW.odelivery_fee
    WHERE month_no = (SELECT curr_mth FROM Current_Schedule WHERE rid = curr_rider)
    AND rid = curr_rider;
	
	END IF;

	IF NEW.oorder_arrives_customer IS NOT NULL THEN
	UPDATE rider
	SET rtotal_salary = rtotal_salary + NEW.odelivery_fee
	WHERE rid = curr_rider;

    END IF;
    RETURN NULL;

END; 
$BODY$
LANGUAGE plpgsql ;

DROP TRIGGER IF EXISTS update_order_salary ON Order_List;
CREATE TRIGGER update_order_salary
  AFTER UPDATE
  ON Order_List
  FOR EACH ROW
  EXECUTE PROCEDURE update_order_salary();

/* SALARY TRIGGER to update mthly salary after full time base salary change. Resets total salary to base salary every mth*/

CREATE OR REPLACE FUNCTION update_ft_base_salary()
  RETURNS trigger AS

$BODY$
BEGIN

	IF NEW.mth != OLD.mth THEN
	UPDATE rider 
    SET rtotal_salary = NEW.base_salary
    WHERE rid = NEW.rid;

	INSERT INTO Monthly_Past_Salaries (rid, month_no, salary, base_salary) VALUES
	(NEW.rid, NEW.mth, NEW.base_salary, NEW.base_salary);

	ELSEIF  NEW.base_salary != OLD.base_salary THEN

    UPDATE rider 
    SET rtotal_salary = rtotal_salary + NEW.base_salary - OLD.base_salary
    WHERE rid = NEW.rid;

	UPDATE Monthly_Past_Salaries
	SET salary = salary + NEW.base_salary - OLD.base_salary
    WHERE month_no = NEW.mth
    AND rid = NEW.rid;
    
	END IF;

    RETURN NULL;

END;
$BODY$
LANGUAGE plpgsql ;

DROP TRIGGER IF EXISTS update_ft_base_salary ON Full_Timer;
CREATE TRIGGER update_ft_base_salary
  AFTER UPDATE
  ON Full_Timer
  FOR EACH ROW
  EXECUTE PROCEDURE update_ft_base_salary();

/* SALARY TRIGGER to update wkly salary after part time base salary change. Resets total salary to base salary every 4 wks */

CREATE OR REPLACE FUNCTION update_pt_base_salary()
  RETURNS trigger AS

$BODY$
BEGIN

    IF NEW.wks - OLD.wks < 4 THEN
	UPDATE rider 
    SET rtotal_salary = rtotal_salary + NEW.base_salary - OLD.base_salary
    WHERE rid = NEW.rid;

	INSERT INTO Weekly_Past_Salaries (rid, week_no, salary, base_salary) VALUES
	(NEW.rid, NEW.wks, NEW.base_salary, NEW.base_salary);

	ELSEIF  NEW.base_salary != OLD.base_salary THEN
	UPDATE rider 
    SET rtotal_salary = NEW.base_salary - OLD.base_salary
    WHERE rid = NEW.rid;

	UPDATE Weekly_Past_Salaries
	SET salary = salary + NEW.base_salary - OLD.base_salary
    WHERE week_no = NEW.wks
    AND rid = NEW.rid;


    END IF;
    RETURN NULL;

END;
$BODY$
LANGUAGE plpgsql ;

DROP TRIGGER IF EXISTS update_pt_base_salary ON Part_Timer;
CREATE TRIGGER update_pt_base_salary
  AFTER UPDATE
  ON Part_Timer
  FOR EACH ROW
  EXECUTE PROCEDURE update_pt_base_salary();

/*
	Work Schedules
*/

/* Full time schedule */
CREATE TABLE Schedule_FT_Hours (
    sfid SERIAL NOT NULL PRIMARY KEY,
    rid SERIAL NOT NULL,
    wkdate TIMESTAMP NOT NULL,
    is_prev BOOLEAN NOT NULL,
    is_last_shift BOOLEAN NOT NULL,
    shift INT NOT NULL,
    FOREIGN KEY (rid) REFERENCES Full_Timer, 
    CHECK (0 < shift AND shift < 5)
);

/* Trigger to ensure 5 day work week */

CREATE OR REPLACE FUNCTION check_day_num()
  RETURNS trigger AS
$BODY$
DECLARE total_days_in_range INT;
DECLARE total_days INT;
DECLARE latest_day TIMESTAMP;
BEGIN
    SELECT MAX(wkdate) INTO latest_day FROM (SELECT * FROM Schedule_FT_Hours
    WHERE rid = NEW.rid) AS curr_wk;

    SELECT COUNT(sfid) INTO total_days_in_range FROM Schedule_FT_Hours 
    WHERE rid = NEW.rid AND latest_day - wkdate < INTERVAL '5 days';

    SELECT COUNT(sfid) INTO total_days FROM Schedule_FT_Hours 
    WHERE rid = NEW.rid AND latest_day- wkdate <= INTERVAL '7 days';

    IF NEW.is_last_shift = True AND 
    ((total_days_in_range != 5) OR (total_days > 5)) THEN
    DELETE FROM Schedule_FT_Hours 
    WHERE rid = NEW.rid AND latest_day - wkdate <= INTERVAL '7 days';

    RAISE WARNING USING MESSAGE = 'Your work schedule must be 5 consecutive days!';

    ELSEIF NEW.is_last_shift = True THEN
    UPDATE Full_Timer 
    SET mth = mth + 1
    WHERE rid = NEW.rid;

    END IF;

    RETURN NULL;

END;
$BODY$
LANGUAGE plpgsql ;

DROP TRIGGER IF EXISTS check_day_num ON Schedule_FT_Hours;
CREATE TRIGGER check_day_num
  AFTER INSERT
  ON Schedule_FT_Hours
  FOR EACH ROW
  EXECUTE PROCEDURE check_day_num();

/* PART-TIME RIDER SCHEDULING */

CREATE TABLE Schedule_PT_Hours (
    spid SERIAL NOT NULL PRIMARY KEY,
    rid SERIAL NOT NULL,
    wkday INT NOT NULL,
    start_time TIMESTAMP UNIQUE NOT NULL,
    end_time TIMESTAMP NOT NULL,
    is_last_shift BOOLEAN NOT NULL,
    FOREIGN KEY (rid) REFERENCES Part_Timer,
    CHECK (EXTRACT(HOUR FROM start_time) >= 10 AND EXTRACT(HOUR FROM start_time) < 22),
    CHECK (end_time > start_time)
);

/* Trigger to ensure each shift is no more than 4 hours
 * NEED DATES TO BE IN ORDER FROM EARLIEST TO LATEST */
CREATE OR REPLACE FUNCTION merge_continuous_rows()
  RETURNS trigger AS
$BODY$
BEGIN

   IF (SELECT spid FROM Schedule_PT_Hours WHERE rid = NEW.rid AND end_time = NEW.start_time
   AND NEW.end_time - start_time <= INTERVAL '4 hours') IS NOT NULL THEN
   UPDATE Schedule_PT_Hours 
   SET end_time = NEW.end_time
   WHERE spid IN (SELECT spid FROM Schedule_PT_Hours WHERE rid = NEW.rid AND end_time = NEW.start_time
   AND NEW.end_time - start_time <= INTERVAL '4 hours');
   DELETE FROM Schedule_PT_Hours 
   WHERE spid = NEW.spid;

   ELSEIF  (SELECT spid FROM  Schedule_PT_Hours WHERE rid = NEW.rid AND end_time = NEW.start_time
   AND NEW.end_time - start_time > INTERVAL '4 hours') IS NOT NULL THEN
   RAISE EXCEPTION USING MESSAGE = 'Your work hours are too long!';
   
   END IF;
   RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql ;

DROP TRIGGER IF EXISTS merge_rows_trigger ON Schedule_PT_Hours;
CREATE TRIGGER merge_rows_trigger
  AFTER INSERT
  ON Schedule_PT_Hours
  FOR EACH ROW
  EXECUTE PROCEDURE merge_continuous_rows();


/* Trigger to make sure part-timers work at least 10hrs/wk but at most 48hrs/wk */
CREATE OR REPLACE FUNCTION net_total_hrs()
  RETURNS trigger AS
$BODY$
DECLARE total_hrs INT;
BEGIN
    SELECT SUM(EXTRACT(HOURS FROM end_time) - EXTRACT(HOURS FROM start_time)) INTO total_hrs FROM Schedule_PT_Hours 
    WHERE rid = NEW.rid AND NEW.end_time - start_time <= INTERVAL '7 days';

    IF NEW.is_last_shift = True AND 
    (total_hrs > 48 OR total_hrs < 10) THEN
    DELETE FROM Schedule_PT_Hours 
    WHERE rid = NEW.rid AND NEW.end_time - start_time <= INTERVAL '7 days';

    RAISE WARNING USING MESSAGE = 'Your working hours per week must be between 10 and 48!';

    ELSEIF NEW.is_last_shift = True THEN
    UPDATE Part_Timer 
    SET wks = wks + 1
    WHERE rid = NEW.rid;

    END IF;

    RETURN NULL;

END;
$BODY$
LANGUAGE plpgsql ;

DROP TRIGGER IF EXISTS net_total_hrs ON Schedule_PT_Hours;
CREATE TRIGGER net_total_hrs
  AFTER INSERT
  ON Schedule_PT_Hours
  FOR EACH ROW
  EXECUTE PROCEDURE net_total_hrs();

/* 5 RIDERS PER HOUR */

CREATE TABLE Schedule_Count (
  scid SERIAL NOT NULL PRIMARY KEY,
  start_time INT NOT NULL,
  wkday INT NOT NULL,
  shift INT NOT NULL,
  num_avail INT NOT NULL,
  CHECK (num_avail >= 5)
);

CREATE TABLE Current_Schedule (
    csid SERIAL NOT NULL PRIMARY KEY,
    rid INT NOT NULL,
    scid INT NOT NULL,
    curr_wk INT NOT NULL DEFAULT 0,
    curr_mth INT NOT NULL DEFAULT 0,
    FOREIGN KEY (rid) REFERENCES Rider ON DELETE CASCADE, 
    FOREIGN KEY (rid) REFERENCES Schedule_Count
);

CREATE OR REPLACE FUNCTION update_schedule()
  RETURNS trigger AS
$BODY$
BEGIN
   UPDATE Schedule_Count SET num_avail = num_avail - 1
   WHERE scid = OLD.scid;
   
   RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql ;

DROP TRIGGER IF EXISTS update_schedule ON Current_Schedule;
CREATE TRIGGER update_schedule
  BEFORE DELETE
  ON Current_Schedule
  FOR EACH ROW
  EXECUTE PROCEDURE update_schedule();
 
 CREATE TABLE delivered_by (
	drating INTEGER,
	ocid SERIAL NOT NULL UNIQUE,
	rid SERIAL NOT NULL,
	cid SERIAL NOT NULL,
	FOREIGN KEY (ocid) REFERENCES Order_List(ocid),
	FOREIGN KEY (rid) REFERENCES Rider(rid),
	FOREIGN KEY (cid) REFERENCES Customer(cid)
);







/*****************************************************************************************************/
/************************************* Sample Data Definition ****************************************/
/*****************************************************************************************************/

/* BASE RIDER DATA GENERATION */

/* The SQL chunk below initializes the db with 22 riders (12 FT 10 PT) 
and their respective scheduling tables and current_schedule/schedule_count such that
the constraint of at least 5 delivery guy per hour is met along with all other rider constraints. 

Please run this before testing any routes on work schedule if the desired behavior of 
at least 5 delivery guy per hour is being tested. */

/* 22 SAMPLE RIDERS */
BEGIN;
DELETE FROM rider;
ALTER SEQUENCE rider_rid_seq RESTART WITH 1;
 /* INIT FULL TIME RIDERS x 12*/
 WITH ins1 AS 
 (INSERT INTO  Rider (rname, rusername, rpassword, rtotal_salary) 
  VALUES ('Aaren', 'un1', 'pw1', 100)
  RETURNING rid AS T_RID)
  INSERT INTO Full_Timer (rid, base_salary, mth)
  SELECT T_RID, 100, 0 FROM ins1;

 WITH ins1 AS 
 (INSERT INTO  Rider (rname, rusername, rpassword, rtotal_salary) 
  VALUES ('Aarika', 'un2', 'pw1', 100)
  RETURNING rid AS T_RID)
  INSERT INTO Full_Timer (rid, base_salary, mth)
  SELECT T_RID, 100, 0 FROM ins1;

 WITH ins1 AS 
 (INSERT INTO  Rider (rname, rusername, rpassword, rtotal_salary) 
  VALUES ('Abagael', 'un3', 'pw3', 100)
  RETURNING rid AS T_RID)
  INSERT INTO Full_Timer (rid, base_salary, mth)
  SELECT T_RID, 100, 0 FROM ins1;

 WITH ins1 AS 
 (INSERT INTO  Rider (rname, rusername, rpassword, rtotal_salary) 
  VALUES ('Abagail', 'un4', 'pw4', 100)
  RETURNING rid AS T_RID)
  INSERT INTO Full_Timer (rid, base_salary, mth)
  SELECT T_RID, 100, 0 FROM ins1;

 WITH ins1 AS 
 (INSERT INTO  Rider (rname, rusername, rpassword, rtotal_salary) 
  VALUES ('Abbe', 'un5', 'pw5', 100)
  RETURNING rid AS T_RID)
  INSERT INTO Full_Timer (rid, base_salary, mth)
  SELECT T_RID, 100, 0 FROM ins1;

 WITH ins1 AS 
 (INSERT INTO  Rider (rname, rusername, rpassword, rtotal_salary) 
  VALUES ('Abbey', 'un6', 'pw6', 100)
  RETURNING rid AS T_RID)
  INSERT INTO Full_Timer (rid, base_salary, mth)
  SELECT T_RID, 100, 0 FROM ins1;

 WITH ins1 AS 
 (INSERT INTO  Rider (rname, rusername, rpassword, rtotal_salary) 
  VALUES ('Abbi', 'un7', 'pw7', 100)
  RETURNING rid AS T_RID)
  INSERT INTO Full_Timer (rid, base_salary, mth)
  SELECT T_RID, 100, 0 FROM ins1;

 WITH ins1 AS 
 (INSERT INTO  Rider (rname, rusername, rpassword, rtotal_salary) 
  VALUES ('Abbie', 'un8', 'pw8', 100)
  RETURNING rid AS T_RID)
  INSERT INTO Full_Timer (rid, base_salary, mth)
  SELECT T_RID, 100, 0 FROM ins1;

 WITH ins1 AS 
 (INSERT INTO  Rider (rname, rusername, rpassword, rtotal_salary) 
  VALUES ('Abby', 'un9', 'pw9', 100)
  RETURNING rid AS T_RID)
  INSERT INTO Full_Timer (rid, base_salary, mth)
  SELECT T_RID, 100, 0 FROM ins1;

 WITH ins1 AS 
 (INSERT INTO  Rider (rname, rusername, rpassword, rtotal_salary) 
  VALUES ('Abbye', 'un10', 'pw10', 100)
  RETURNING rid AS T_RID)
  INSERT INTO Full_Timer (rid, base_salary, mth)
  SELECT T_RID, 100, 0 FROM ins1;

 WITH ins1 AS 
 (INSERT INTO  Rider (rname, rusername, rpassword, rtotal_salary) 
  VALUES ('Abigael', 'un11', 'pw11', 100)
  RETURNING rid AS T_RID)
  INSERT INTO Full_Timer (rid, base_salary, mth)
  SELECT T_RID, 100, 0 FROM ins1;

 WITH ins1 AS 
 (INSERT INTO  Rider (rname, rusername, rpassword, rtotal_salary) 
  VALUES ('Abigail', 'un12', 'pw12', 100)
  RETURNING rid AS T_RID)
  INSERT INTO Full_Timer (rid, base_salary, mth)
  SELECT T_RID, 100, 0 FROM ins1;

/* INIT PART-TIME RIDERS x 10 */

WITH ins1 AS 
 (INSERT INTO  Rider (rname, rusername, rpassword, rtotal_salary) 
  VALUES ('Abigale', 'un13', 'pw13', 50)
  RETURNING rid AS T_RID)
  INSERT INTO Part_Timer (rid, base_salary, wks)
  SELECT T_RID, 50, 0 FROM ins1;

WITH ins1 AS 
 (INSERT INTO  Rider (rname, rusername, rpassword, rtotal_salary) 
  VALUES ('Abra', 'un14', 'pw14', 50)
  RETURNING rid AS T_RID)
  INSERT INTO Part_Timer (rid, base_salary, wks)
  SELECT T_RID, 50, 0 FROM ins1;

WITH ins1 AS 
 (INSERT INTO  Rider (rname, rusername, rpassword, rtotal_salary) 
  VALUES ('Ada', 'un15', 'pw15', 50)
  RETURNING rid AS T_RID)
  INSERT INTO Part_Timer (rid, base_salary, wks)
  SELECT T_RID, 50, 0 FROM ins1;

WITH ins1 AS 
 (INSERT INTO  Rider (rname, rusername, rpassword, rtotal_salary) 
  VALUES ('Adah', 'un16', 'pw16', 50)
  RETURNING rid AS T_RID)
  INSERT INTO Part_Timer (rid, base_salary, wks)
  SELECT T_RID, 50, 0 FROM ins1;

WITH ins1 AS 
 (INSERT INTO  Rider (rname, rusername, rpassword, rtotal_salary) 
  VALUES ('Adaline', 'un17', 'pw17', 50)
  RETURNING rid AS T_RID)
  INSERT INTO Part_Timer (rid, base_salary, wks)
  SELECT T_RID, 50, 0 FROM ins1;

WITH ins1 AS 
 (INSERT INTO  Rider (rname, rusername, rpassword, rtotal_salary) 
  VALUES ('Adan', 'un18', 'pw18', 50)
  RETURNING rid AS T_RID)
  INSERT INTO Part_Timer (rid, base_salary, wks)
  SELECT T_RID, 50, 0 FROM ins1;

WITH ins1 AS 
 (INSERT INTO  Rider (rname, rusername, rpassword, rtotal_salary) 
  VALUES ('Adara', 'un19', 'pw19', 50)
  RETURNING rid AS T_RID)
  INSERT INTO Part_Timer (rid, base_salary, wks)
  SELECT T_RID, 50, 0 FROM ins1;

WITH ins1 AS 
 (INSERT INTO  Rider (rname, rusername, rpassword, rtotal_salary) 
  VALUES ('Adda', 'un20', 'pw20', 50)
  RETURNING rid AS T_RID)
  INSERT INTO Part_Timer (rid, base_salary, wks)
  SELECT T_RID, 50, 0 FROM ins1;

WITH ins1 AS 
 (INSERT INTO  Rider (rname, rusername, rpassword, rtotal_salary) 
  VALUES ('Addda', 'un21', 'pw21', 50)
  RETURNING rid AS T_RID)
  INSERT INTO Part_Timer (rid, base_salary, wks)
  SELECT T_RID, 50, 0 FROM ins1;


WITH ins1 AS 
 (INSERT INTO  Rider (rname, rusername, rpassword, rtotal_salary) 
  VALUES ('Addaa', 'un22', 'pw22', 50)
  RETURNING rid AS T_RID)
  INSERT INTO Part_Timer (rid, base_salary, wks)
  SELECT T_RID, 50, 0 FROM ins1;


COMMIT;

/* RIDER SAMPLE CREATED */

/* Populate Schedule Count */
INSERT INTO Schedule_Count (start_time, wkday, shift, num_avail)
VALUES 
(10,1,1,5),
(11,1,1,5),
(11,1,2,5),
(12,1,1,5),
(12,1,2,5),
(12,1,3,5),
(13,1,1,5),
(13,1,2,5),
(13,1,3,5),
(13,1,4,5),
(14,1,2,5),
(14,1,3,5),
(14,1,4,5),
(15,1,1,5),
(15,1,3,5),
(15,1,4,5),
(16,1,1,5),
(16,1,2,5),
(16,1,4,5),
(17,1,1,5),
(17,1,2,5),
(17,1,3,5),
(18,1,1,5),
(18,1,2,5),
(18,1,3,5),
(18,1,4,5),
(19,1,2,5),
(19,1,3,5),
(19,1,4,5),
(20,1,3,5),
(20,1,4,5),
(21,1,4,5),
(10,2,1,5),
(11,2,1,5),
(11,2,2,5),
(12,2,1,5),
(12,2,2,5),
(12,2,3,5),
(13,2,1,5),
(13,2,2,5),
(13,2,3,5),
(13,2,4,5),
(14,2,2,5),
(14,2,3,5),
(14,2,4,5),
(15,2,1,5),
(15,2,3,5),
(15,2,4,5),
(16,2,1,5),
(16,2,2,5),
(16,2,4,5),
(17,2,1,5),
(17,2,2,5),
(17,2,3,5),
(18,2,1,5),
(18,2,2,5),
(18,2,3,5),
(18,2,4,5),
(19,2,2,5),
(19,2,3,5),
(19,2,4,5),
(20,2,3,5),
(20,2,4,5),
(21,2,4,5),
(10,3,1,5),
(11,3,1,5),
(11,3,2,5),
(12,3,1,5),
(12,3,2,5),
(12,3,3,5),
(13,3,1,5),
(13,3,2,5),
(13,3,3,5),
(13,3,4,5),
(14,3,2,5),
(14,3,3,5),
(14,3,4,5),
(15,3,1,5),
(15,3,3,5),
(15,3,4,5),
(16,3,1,5),
(16,3,2,5),
(16,3,4,5),
(17,3,1,5),
(17,3,2,5),
(17,3,3,5),
(18,3,1,5),
(18,3,2,5),
(18,3,3,5),
(18,3,4,5),
(19,3,2,5),
(19,3,3,5),
(19,3,4,5),
(20,3,3,5),
(20,3,4,5),
(21,3,4,5),
(10,4,1,5),
(11,4,1,5),
(11,4,2,5),
(12,4,1,5),
(12,4,2,5),
(12,4,3,5),
(13,4,1,5),
(13,4,2,5),
(13,4,3,5),
(13,4,4,5),
(14,4,2,5),
(14,4,3,5),
(14,4,4,5),
(15,4,1,5),
(15,4,3,5),
(15,4,4,5),
(16,4,1,5),
(16,4,2,5),
(16,4,4,5),
(17,4,1,5),
(17,4,2,5),
(17,4,3,5),
(18,4,1,5),
(18,4,2,5),
(18,4,3,5),
(18,4,4,5),
(19,4,2,5),
(19,4,3,5),
(19,4,4,5),
(20,4,3,5),
(20,4,4,5),
(21,4,4,5),
(10,5,1,5),
(11,5,1,5),
(11,5,2,5),
(12,5,1,5),
(12,5,2,5),
(12,5,3,5),
(13,5,1,5),
(13,5,2,5),
(13,5,3,5),
(13,5,4,5),
(14,5,2,5),
(14,5,3,5),
(14,5,4,5),
(15,5,1,5),
(15,5,3,5),
(15,5,4,5),
(16,5,1,5),
(16,5,2,5),
(16,5,4,5),
(17,5,1,5),
(17,5,2,5),
(17,5,3,5),
(18,5,1,5),
(18,5,2,5),
(18,5,3,5),
(18,5,4,5),
(19,5,2,5),
(19,5,3,5),
(19,5,4,5),
(20,5,3,5),
(20,5,4,5),
(21,5,4,5),
(10,6,1,5),
(11,6,1,5),
(11,6,2,5),
(12,6,1,5),
(12,6,2,5),
(12,6,3,5),
(13,6,1,5),
(13,6,2,5),
(13,6,3,5),
(13,6,4,5),
(14,6,2,5),
(14,6,3,5),
(14,6,4,5),
(15,6,1,5),
(15,6,3,5),
(15,6,4,5),
(16,6,1,5),
(16,6,2,5),
(16,6,4,5),
(17,6,1,5),
(17,6,2,5),
(17,6,3,5),
(18,6,1,5),
(18,6,2,5),
(18,6,3,5),
(18,6,4,5),
(19,6,2,5),
(19,6,3,5),
(19,6,4,5),
(20,6,3,5),
(20,6,4,5),
(21,6,4,5),
(10,7,1,5),
(11,7,1,5),
(11,7,2,5),
(12,7,1,5),
(12,7,2,5),
(12,7,3,5),
(13,7,1,5),
(13,7,2,5),
(13,7,3,5),
(13,7,4,5),
(14,7,2,5),
(14,7,3,5),
(14,7,4,5),
(15,7,1,5),
(15,7,3,5),
(15,7,4,5),
(16,7,1,5),
(16,7,2,5),
(16,7,4,5),
(17,7,1,5),
(17,7,2,5),
(17,7,3,5),
(18,7,1,5),
(18,7,2,5),
(18,7,3,5),
(18,7,4,5),
(19,7,2,5),
(19,7,3,5),
(19,7,4,5),
(20,7,3,5),
(20,7,4,5),
(21,7,4,5)

/* Populate Schedules for each rider*/
BEGIN;
/*Rider 1*/
INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(1, '2016-06-25 18:00:25-07', True, False, 1);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(1, '2016-06-27 23:59:25-07', True, False, 1);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(1, '2016-06-24 18:00:25-07', True, False, 1);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(1, '2016-06-23 00:00:25-07', True, False, 1);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(1, '2016-06-26 18:00:25-07', True, True, 1);

/* Update Rider 1's current schedule */
INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 1, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 1) FROM Schedule_Count WHERE shift = 1 
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-23 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 1, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 1) FROM Schedule_Count WHERE shift = 1 
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-24 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 1, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 1) FROM Schedule_Count WHERE shift = 1 
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-25 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 1, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 1) FROM Schedule_Count WHERE shift = 1 
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-26 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 1, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 1) FROM Schedule_Count WHERE shift = 1 
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-27 18:00:25-07');

/*Rider 2*/
INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(2, '2016-06-25 18:00:25-07', True, False, 1);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(2, '2016-06-27 23:59:25-07', True, False, 1);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(2, '2016-06-24 18:00:25-07', True, False, 1);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(2, '2016-06-23 00:00:25-07', True, False, 1);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(2, '2016-06-26 18:00:25-07', True, True, 1);

/* Update Rider 2's current schedule */
INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 2, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 2) FROM Schedule_Count WHERE shift = 1 
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-23 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 2, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 2) FROM Schedule_Count WHERE shift = 1 
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-24 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 2, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 2) FROM Schedule_Count WHERE shift = 1 
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-25 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 2, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 2) FROM Schedule_Count WHERE shift = 1 
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-26 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 2, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 2) FROM Schedule_Count WHERE shift = 1 
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-27 18:00:25-07');

/*Rider 3*/
INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(3, '2016-06-25 18:00:25-07', True, False, 1);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(3, '2016-06-27 23:59:25-07', True, False, 1);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(3, '2016-06-24 18:00:25-07', True, False, 1);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(3, '2016-06-23 00:00:25-07', True, False, 1);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(3, '2016-06-26 18:00:25-07', True, True, 1);

/* Update Rider 3's current schedule */
INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 3, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 3) FROM Schedule_Count WHERE shift = 1 
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-23 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 3, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 3) FROM Schedule_Count WHERE shift = 1 
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-24 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 3, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 3) FROM Schedule_Count WHERE shift = 1 
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-25 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 3, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 3) FROM Schedule_Count WHERE shift = 1 
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-26 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 3, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 3) FROM Schedule_Count WHERE shift = 1 
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-27 18:00:25-07');

/*Rider 4*/
INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(4, '2016-06-25 18:00:25-07', True, False, 2);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(4, '2016-06-27 23:59:25-07', True, False, 2);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(4, '2016-06-24 18:00:25-07', True, False, 2);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(4, '2016-06-23 00:00:25-07', True, False, 2);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(4, '2016-06-26 18:00:25-07', True, True, 2);

/* Update Rider 4's current schedule */
INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 4, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 4) FROM Schedule_Count WHERE shift = 2 
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-23 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 4, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 4) FROM Schedule_Count WHERE shift = 2 
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-24 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 4, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 4) FROM Schedule_Count WHERE shift = 2 
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-25 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 4, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 4) FROM Schedule_Count WHERE shift = 2 
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-26 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 4, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 4) FROM Schedule_Count WHERE shift = 2 
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-27 18:00:25-07');

/*Rider 5*/
INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(5, '2016-06-25 18:00:25-07', True, False, 2);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(5, '2016-06-27 23:59:25-07', True, False, 2);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(5, '2016-06-24 18:00:25-07', True, False, 2);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(5, '2016-06-23 00:00:25-07', True, False, 2);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(5, '2016-06-26 18:00:25-07', True, True, 2);

/* Update Rider 5's current schedule */
INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 5, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 5) FROM Schedule_Count WHERE shift = 2 
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-23 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 5, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 5) FROM Schedule_Count WHERE shift = 2 
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-24 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 5, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 5) FROM Schedule_Count WHERE shift = 2 
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-25 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 5, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 5) FROM Schedule_Count WHERE shift = 2 
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-26 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 5, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 5) FROM Schedule_Count WHERE shift = 2 
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-27 18:00:25-07');

/*Rider 6*/
INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(6, '2016-06-25 18:00:25-07', True, False, 2);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(6, '2016-06-27 23:59:25-07', True, False, 2);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(6, '2016-06-24 18:00:25-07', True, False, 2);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(6, '2016-06-23 00:00:25-07', True, False, 2);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(6, '2016-06-26 18:00:25-07', True, True, 2);

/* Update Rider 6's current schedule */
INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 6, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 6) FROM Schedule_Count WHERE shift = 2 
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-23 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 6, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 6) FROM Schedule_Count WHERE shift = 2 
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-24 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 6, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 6) FROM Schedule_Count WHERE shift = 2 
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-25 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 6, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 6) FROM Schedule_Count WHERE shift = 2 
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-26 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 6, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 6) FROM Schedule_Count WHERE shift = 2 
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-27 18:00:25-07');

/*Rider 7*/
INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(7, '2016-06-25 18:00:25-07', True, False, 3);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(7, '2016-06-27 23:59:25-07', True, False, 3);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(7, '2016-06-24 18:00:25-07', True, False, 3);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(7, '2016-06-23 00:00:25-07', True, False, 3);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(7, '2016-06-26 18:00:25-07', True, True, 3);

/* Update Rider 7's current schedule */
INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 7, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 7) FROM Schedule_Count WHERE shift = 3
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-23 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 7, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 7) FROM Schedule_Count WHERE shift = 3
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-24 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 7, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 7) FROM Schedule_Count WHERE shift = 3
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-25 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 7, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 7) FROM Schedule_Count WHERE shift = 3
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-26 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 7, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 7) FROM Schedule_Count WHERE shift = 3
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-27 18:00:25-07');


/*Rider 8*/
INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(8, '2016-06-25 18:00:25-07', True, False, 3);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(8, '2016-06-27 23:59:25-07', True, False, 3);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(8, '2016-06-24 18:00:25-07', True, False, 3);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(8, '2016-06-23 00:00:25-07', True, False, 3);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(8, '2016-06-26 18:00:25-07', True, True, 3);

/* Update Rider 8's current schedule */
INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 8, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 8) FROM Schedule_Count WHERE shift = 3
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-23 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 8, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 8) FROM Schedule_Count WHERE shift = 3
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-24 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 8, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 8) FROM Schedule_Count WHERE shift = 3
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-25 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 8, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 8) FROM Schedule_Count WHERE shift = 3
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-26 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 8, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 8) FROM Schedule_Count WHERE shift = 3
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-27 18:00:25-07');



/*Rider 9*/
INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(9, '2016-06-25 18:00:25-07', True, False, 3);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(9, '2016-06-27 23:59:25-07', True, False, 3);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(9, '2016-06-24 18:00:25-07', True, False, 3);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(9, '2016-06-23 00:00:25-07', True, False, 3);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(9, '2016-06-26 18:00:25-07', True, True, 3);

/* Update Rider 9's current schedule */
INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 9, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 9) FROM Schedule_Count WHERE shift = 3
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-23 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 9, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 9) FROM Schedule_Count WHERE shift = 3
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-24 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 9, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 9) FROM Schedule_Count WHERE shift = 3
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-25 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 9, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 9) FROM Schedule_Count WHERE shift = 3
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-26 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 9, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 9) FROM Schedule_Count WHERE shift = 3
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-27 18:00:25-07');

/*Rider 10*/
INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(10, '2016-06-25 18:00:25-07', True, False, 4);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(10, '2016-06-27 23:59:25-07', True, False, 4);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(10, '2016-06-24 18:00:25-07', True, False, 4);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(10, '2016-06-23 00:00:25-07', True, False, 4);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(10, '2016-06-26 18:00:25-07', True, True, 4);


/* Update Rider 10's current schedule */
INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 10, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 10) FROM Schedule_Count WHERE shift = 4
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-23 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 10, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 10) FROM Schedule_Count WHERE shift = 4
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-24 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 10, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 10) FROM Schedule_Count WHERE shift = 4
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-25 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 10, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 10) FROM Schedule_Count WHERE shift = 4
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-26 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 10, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 10) FROM Schedule_Count WHERE shift = 4
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-27 18:00:25-07');

/*Rider 11*/
INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(11, '2016-06-25 18:00:25-07', True, False, 4);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(11, '2016-06-27 23:59:25-07', True, False, 4);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(11, '2016-06-24 18:00:25-07', True, False, 4);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(11, '2016-06-23 00:00:25-07', True, False, 4);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(11, '2016-06-26 18:00:25-07', True, True, 4);

/* Update Rider 11's current schedule */
INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 11, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 11) FROM Schedule_Count WHERE shift = 4
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-23 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 11, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 11) FROM Schedule_Count WHERE shift = 4
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-24 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 11, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 11) FROM Schedule_Count WHERE shift = 4
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-25 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 11, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 11) FROM Schedule_Count WHERE shift = 4
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-26 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 11, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 11) FROM Schedule_Count WHERE shift = 4
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-27 18:00:25-07');

/*Rider 12*/
INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(12, '2016-06-25 18:00:25-07', True, False, 4);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(12, '2016-06-27 23:59:25-07', True, False, 4);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(12, '2016-06-24 18:00:25-07', True, False, 4);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(12, '2016-06-23 00:00:25-07', True, False, 4);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(12, '2016-06-26 18:00:25-07', True, True, 4);

/* Update Rider 12's current schedule */
INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 11, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 11) FROM Schedule_Count WHERE shift = 4
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-23 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 11, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 11) FROM Schedule_Count WHERE shift = 4
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-24 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 11, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 11) FROM Schedule_Count WHERE shift = 4
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-25 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 11, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 11) FROM Schedule_Count WHERE shift = 4
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-26 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 11, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 11) FROM Schedule_Count WHERE shift = 4
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-27 18:00:25-07');

/*Rider 13*/

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(13, EXTRACT(DOW FROM TIMESTAMP '2016-06-23 10:00:00-07'), '2016-06-23 10:00:00-07',
      '2016-06-23 11:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(13, EXTRACT(DOW FROM TIMESTAMP '2016-06-24 10:00:00-07'), '2016-06-24 10:00:00-07',
      '2016-06-24 11:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(13, EXTRACT(DOW FROM TIMESTAMP '2016-06-25 10:00:00-07'), '2016-06-25 10:00:00-07',
      '2016-06-25 11:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(13, EXTRACT(DOW FROM TIMESTAMP '2016-06-26 10:00:00-07'), '2016-06-26 10:00:00-07',
      '2016-06-26 11:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(13, EXTRACT(DOW FROM TIMESTAMP '2016-06-27 10:00:00-07'), '2016-06-27 10:00:00-07',
      '2016-06-27 11:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(13, EXTRACT(DOW FROM TIMESTAMP '2016-06-23 21:00:00-07'), '2016-06-23 21:00:00-07',
      '2016-06-23 22:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(13, EXTRACT(DOW FROM TIMESTAMP '2016-06-24 21:00:00-07'), '2016-06-24 21:00:00-07',
      '2016-06-24 22:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(13, EXTRACT(DOW FROM TIMESTAMP '2016-06-25 21:00:00-07'), '2016-06-25 21:00:00-07',
      '2016-06-25 22:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(13, EXTRACT(DOW FROM TIMESTAMP '2016-06-26 21:00:00-07'), '2016-06-26 21:00:00-07',
      '2016-06-26 22:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(13, EXTRACT(DOW FROM TIMESTAMP '2016-06-27 21:00:00-07'), '2016-06-27 21:00:00-07',
      '2016-06-27 22:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(13, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 10:00:00-07'), '2016-06-28 10:00:00-07',
      '2016-06-28 14:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(13, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 15:00:00-07'), '2016-06-28 15:00:00-07',
      '2016-06-28 19:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(13, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 20:00:00-07'), '2016-06-28 20:00:00-07',
      '2016-06-28 22:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(13, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 10:00:00-07'), '2016-06-29 10:00:00-07',
      '2016-06-29 14:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(13, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 15:00:00-07'), '2016-06-29 15:00:00-07',
      '2016-06-29 19:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(13, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 20:00:00-07'), '2016-06-29 20:00:00-07',
      '2016-06-29 22:00:00-07', True);

/* Update Current_Schedule for PT-rider 13 */

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 13, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 13)
FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-23 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 13, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 13)
FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-23 21:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 13, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 13)
FROM Schedule_Count WHERE start_time > EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 10:00:00-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 14:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 13, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 13)
FROM Schedule_Count WHERE start_time > EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 10:00:00-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 14:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 13, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 13)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 15:00:00-07')
AND start_time <= EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 19:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 13, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 13)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 15:00:00-07')
AND start_time <= EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 19:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 13, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 13)
FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 20:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 13, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 13)
FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 20:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 10:00:00-07');


/*Rider 14*/

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(14, EXTRACT(DOW FROM TIMESTAMP '2016-06-23 10:00:00-07'), '2016-06-23 10:00:00-07',
      '2016-06-23 11:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(14, EXTRACT(DOW FROM TIMESTAMP '2016-06-24 10:00:00-07'), '2016-06-24 10:00:00-07',
      '2016-06-24 11:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(14, EXTRACT(DOW FROM TIMESTAMP '2016-06-25 10:00:00-07'), '2016-06-25 10:00:00-07',
      '2016-06-25 11:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(14, EXTRACT(DOW FROM TIMESTAMP '2016-06-26 10:00:00-07'), '2016-06-26 10:00:00-07',
      '2016-06-26 11:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(14, EXTRACT(DOW FROM TIMESTAMP '2016-06-27 10:00:00-07'), '2016-06-27 10:00:00-07',
      '2016-06-27 11:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(14, EXTRACT(DOW FROM TIMESTAMP '2016-06-23 21:00:00-07'), '2016-06-23 21:00:00-07',
      '2016-06-23 22:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(14, EXTRACT(DOW FROM TIMESTAMP '2016-06-24 21:00:00-07'), '2016-06-24 21:00:00-07',
      '2016-06-24 22:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(14, EXTRACT(DOW FROM TIMESTAMP '2016-06-25 21:00:00-07'), '2016-06-25 21:00:00-07',
      '2016-06-25 22:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(14, EXTRACT(DOW FROM TIMESTAMP '2016-06-26 21:00:00-07'), '2016-06-26 21:00:00-07',
      '2016-06-26 22:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(14, EXTRACT(DOW FROM TIMESTAMP '2016-06-27 21:00:00-07'), '2016-06-27 21:00:00-07',
      '2016-06-27 22:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(14, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 10:00:00-07'), '2016-06-28 10:00:00-07',
      '2016-06-28 14:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(14, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 15:00:00-07'), '2016-06-28 15:00:00-07',
      '2016-06-28 19:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(14, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 20:00:00-07'), '2016-06-28 20:00:00-07',
      '2016-06-28 22:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(14, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 10:00:00-07'), '2016-06-29 10:00:00-07',
      '2016-06-29 14:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(14, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 15:00:00-07'), '2016-06-29 15:00:00-07',
      '2016-06-29 19:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(14, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 20:00:00-07'), '2016-06-29 20:00:00-07',
      '2016-06-29 22:00:00-07', True);



/* Update Current_Schedule for PT-rider 14 */

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 14, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 14)
FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-23 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 14, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 14)
FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-23 21:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 14, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 14)
FROM Schedule_Count WHERE start_time > EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 10:00:00-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 14:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 14, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 14)
FROM Schedule_Count WHERE start_time > EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 10:00:00-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 14:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 14, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 14)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 15:00:00-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 19:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 14, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 14)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 15:00:00-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 19:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 14, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 14)
FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 20:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 14, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 14)
FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 20:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 10:00:00-07');


/*Rider 15*/
INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(15, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 10:00:00-07'), '2016-06-28 10:00:00-07',
      '2016-06-28 14:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(15, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 15:00:00-07'), '2016-06-28 15:00:00-07',
      '2016-06-28 19:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(15, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 20:00:00-07'), '2016-06-28 20:00:00-07',
      '2016-06-28 22:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(15, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 10:00:00-07'), '2016-06-29 10:00:00-07',
      '2016-06-29 14:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(15, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 15:00:00-07'), '2016-06-29 15:00:00-07',
      '2016-06-29 19:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(15, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 20:00:00-07'), '2016-06-29 20:00:00-07',
      '2016-06-29 22:00:00-07', True);


/* Update Current_Schedule for PT-rider 15 */
INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 15, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 15)
FROM Schedule_Count WHERE start_time > EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 10:00:00-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 14:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 15, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 15)
FROM Schedule_Count WHERE start_time > EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 10:00:00-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 14:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 15, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 15)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 15:00:00-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 19:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 15, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 15)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 15:00:00-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 19:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 15, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 15)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 20:00:00-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 22:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 15, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 15)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 20:00:00-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 22:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 10:00:00-07');

/*Rider 16*/
INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(16, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 14:00:00-07'), '2016-06-28 14:00:00-07',
      '2016-06-28 18:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(16, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 19:00:00-07'), '2016-06-28 19:00:00-07',
      '2016-06-28 20:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(16, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 14:00:00-07'), '2016-06-29 14:00:00-07',
      '2016-06-29 18:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(16, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 19:00:00-07'), '2016-06-29 19:00:00-07',
      '2016-06-29 20:00:00-07', True);

/* Update Current_Schedule for PT-rider 16 */

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 16, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 16)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 14:00:25-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 18:00:25-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 14:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 16, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 16)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 14:00:25-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 18:00:25-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 14:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 16, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 16)
FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 19:00:25-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 14:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 16, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 16)
FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 19:00:25-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 14:00:25-07');

/*Rider 17*/
INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(17, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 14:00:00-07'), '2016-06-28 14:00:00-07',
      '2016-06-28 18:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(17, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 19:00:00-07'), '2016-06-28 19:00:00-07',
      '2016-06-28 20:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(17, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 14:00:00-07'), '2016-06-29 14:00:00-07',
      '2016-06-29 18:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(17, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 19:00:00-07'), '2016-06-29 19:00:00-07',
      '2016-06-29 20:00:00-07', True);

/* Update Current_Schedule for PT-rider 17 */

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 17, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 17)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 14:00:25-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 18:00:25-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 14:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 17, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 17)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 14:00:25-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 18:00:25-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 14:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 17, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 17)
FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 19:00:25-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 14:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 17, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 17)
FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 19:00:25-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 14:00:25-07');

/*Rider 18*/
INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(18, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 14:00:00-07'), '2016-06-28 14:00:00-07',
      '2016-06-28 18:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(18, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 19:00:00-07'), '2016-06-28 19:00:00-07',
      '2016-06-28 20:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(18, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 14:00:00-07'), '2016-06-29 14:00:00-07',
      '2016-06-29 18:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(18, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 19:00:00-07'), '2016-06-29 19:00:00-07',
      '2016-06-29 20:00:00-07', True);

/* Update Current_Schedule for PT-rider 18 */

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 18, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 18)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 14:00:25-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 18:00:25-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 14:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 18, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 18)
FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 14:00:25-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 18:00:25-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 14:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 18, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 18)
FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 19:00:25-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 14:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 18, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 18)
FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 19:00:25-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 14:00:25-07');

/*Rider 19*/
INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(19, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 14:00:00-07'), '2016-06-28 14:00:00-07',
      '2016-06-28 18:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(19, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 19:00:00-07'), '2016-06-28 19:00:00-07',
      '2016-06-28 20:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(19, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 14:00:00-07'), '2016-06-29 14:00:00-07',
      '2016-06-29 18:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(19, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 19:00:00-07'), '2016-06-29 19:00:00-07',
      '2016-06-29 20:00:00-07', True);

/* Update Current_Schedule for PT-rider 19 */

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 19, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 19)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 14:00:25-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 18:00:25-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 14:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 19, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 19)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 14:00:25-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 18:00:25-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 14:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 19, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 19)
FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 19:00:25-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 14:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 19, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 19)
FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 19:00:25-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 14:00:25-07');

/*Rider 20*/
INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(20, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 14:00:00-07'), '2016-06-28 14:00:00-07',
      '2016-06-28 18:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(20, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 19:00:00-07'), '2016-06-28 19:00:00-07',
      '2016-06-28 20:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(20, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 14:00:00-07'), '2016-06-29 14:00:00-07',
      '2016-06-29 18:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(20, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 19:00:00-07'), '2016-06-29 19:00:00-07',
      '2016-06-29 20:00:00-07', True);

/* Update Current_Schedule for PT-rider 19 */

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 20, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 20)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 14:00:25-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 18:00:25-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 14:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 20, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 20)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 14:00:25-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 18:00:25-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 14:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 20, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 20)
FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 19:00:25-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 14:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 20, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 20)
FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 19:00:25-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 14:00:25-07');

/*Rider 21*/
INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(21, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 15:00:00-07'), '2016-06-28 15:00:00-07',
      '2016-06-28 19:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(21, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 20:00:00-07'), '2016-06-28 20:00:00-07',
      '2016-06-28 22:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(21, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 10:00:00-07'), '2016-06-29 10:00:00-07',
      '2016-06-29 14:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(21, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 15:00:00-07'), '2016-06-29 15:00:00-07',
      '2016-06-29 19:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(21, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 20:00:00-07'), '2016-06-29 20:00:00-07',
      '2016-06-29 22:00:00-07', True);



/* Update Current_Schedule for PT-rider 21 */
INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 21, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 21)
FROM Schedule_Count WHERE start_time > EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 10:00:00-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 14:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 21, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 21)
FROM Schedule_Count WHERE start_time > EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 10:00:00-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 14:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 21, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 21)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 15:00:00-07')
AND start_time <= EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 19:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 21, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 21)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 15:00:00-07')
AND start_time <= EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 19:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 21, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 21)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 20:00:00-07')
AND start_time <= EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 22:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 21, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 21)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 20:00:00-07')
AND start_time <= EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 22:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 10:00:00-07');

/*Rider 22*/
INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(22, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 15:00:00-07'), '2016-06-28 15:00:00-07',
      '2016-06-28 19:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(22, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 20:00:00-07'), '2016-06-28 20:00:00-07',
      '2016-06-28 22:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(22, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 10:00:00-07'), '2016-06-29 10:00:00-07',
      '2016-06-29 14:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(22, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 15:00:00-07'), '2016-06-29 15:00:00-07',
      '2016-06-29 19:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(22, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 20:00:00-07'), '2016-06-29 20:00:00-07',
      '2016-06-29 22:00:00-07', True);

/* Update Current_Schedule for PT-rider 22 */
INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 22, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 22)
FROM Schedule_Count WHERE start_time > EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 10:00:00-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 14:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 22, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 22)
FROM Schedule_Count WHERE start_time > EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 10:00:00-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 14:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 22, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 22)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 15:00:00-07')
AND start_time <= EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 19:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 22, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 22)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 15:00:00-07')
AND start_time <= EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 19:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 22, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 22)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 20:00:00-07')
AND start_time <= EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 22:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 22, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 22)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 20:00:00-07')
AND start_time <= EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 22:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 10:00:00-07');

COMMIT;
