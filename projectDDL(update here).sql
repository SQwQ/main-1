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
	cid SERIAL NOT NULL,
	current BOOLEAN NOT NULL,
	PRIMARY KEY(card_number),
	FOREIGN KEY (cid) REFERENCES Customer(cid)
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
    WHERE rid = NEW.rid AND latest_day - wkdate < INTERVAL '7 days'
    AND is_prev = False;

    IF NEW.is_last_shift = True AND
    ((total_days_in_range != 5) OR (total_days > 5)) THEN
    DELETE FROM Schedule_FT_Hours
    WHERE rid = NEW.rid AND is_prev = False;

    RAISE WARNING USING MESSAGE = 'Your work schedule must be 5 consecutive days!';

    ELSEIF NEW.is_last_shift = True THEN
    UPDATE Full_Timer
    SET mth = mth + 1
    WHERE rid = NEW.rid;

    UPDATE Schedule_FT_Hours
    SET is_prev = True
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
    start_time TIMESTAMP NOT NULL,
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
DECLARE prev_last TIMESTAMP;
BEGIN

    SELECT MAX(end_time) INTO prev_last FROM (SELECT * FROM Schedule_PT_Hours
    WHERE rid = NEW.rid AND is_last_shift = True) AS curr_wk;

    IF prev_last IS NULL THEN
    SELECT MIN(start_time) INTO prev_last FROM (SELECT * FROM Schedule_PT_Hours
    WHERE rid = NEW.rid) AS all_wks;
    END IF;

    SELECT SUM(EXTRACT(HOURS FROM end_time) - EXTRACT(HOURS FROM start_time)) INTO total_hrs FROM Schedule_PT_Hours
    WHERE rid = NEW.rid AND start_time >= prev_last;

    IF NEW.is_last_shift = True AND
    (total_hrs > 48 OR total_hrs < 10) THEN
    DELETE FROM Schedule_PT_Hours
    WHERE rid = NEW.rid AND start_time >= prev_last;

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
(21,7,4,5);

/* Populate Schedules for each rider*/

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

/* 20 restaurants */
insert into Restaurant (rname , raddress , rminCost ) values ('Lakin Inc', '8 Mitchell Plaza', 34);
insert into Restaurant (rname , raddress , rminCost ) values ('Daugherty LLC', '17554 Melby Place', 12);
insert into Restaurant (rname , raddress , rminCost ) values ('Gislason-Hintz', '8 Myrtle Avenue', 11);
insert into Restaurant (rname , raddress , rminCost ) values ('Bauch Group', '24080 Morrow Lane', 12);
insert into Restaurant (rname , raddress , rminCost ) values ('Feeney, Schuppe and Davis', '334 Comanche Pass', 24);
insert into Restaurant (rname , raddress , rminCost ) values ('Lubowitz, Smitham and Bruen', '6 Michigan Lane', 33);
insert into Restaurant (rname , raddress , rminCost ) values ('Towne LLC', '45934 Delladonna Plaza', 34);
insert into Restaurant (rname , raddress , rminCost ) values ('Schiller and Sons', '688 Bobwhite Avenue', 37);
insert into Restaurant (rname , raddress , rminCost ) values ('Aufderhar-Pouros', '58228 Bultman Drive', 47);
insert into Restaurant (rname , raddress , rminCost ) values ('Christiansen-Kassulke', '073 Hanover Avenue', 18);
insert into Restaurant (rname , raddress , rminCost ) values ('Hodkiewicz Group', '5502 Reinke Lane', 37);
insert into Restaurant (rname , raddress , rminCost ) values ('Schmeler-Brakus', '2282 Saint Paul Crossing', 40);
insert into Restaurant (rname , raddress , rminCost ) values ('Wehner Inc', '2 Hintze Road', 19);
insert into Restaurant (rname , raddress , rminCost ) values ('Hermann-McClure', '122 Kropf Drive', 49);
insert into Restaurant (rname , raddress , rminCost ) values ('Paucek Group', '79805 Crescent Oaks Circle', 10);
insert into Restaurant (rname , raddress , rminCost ) values ('Gorczany, Feil and Morissette', '0 Brickson Park Avenue', 28);
insert into Restaurant (rname , raddress , rminCost ) values ('Kuhic, Nolan and Daniel', '387 Northview Place', 37);
insert into Restaurant (rname , raddress , rminCost ) values ('Dooley-Hammes', '49038 Golf Center', 31);
insert into Restaurant (rname , raddress , rminCost ) values ('DuBuque-Bartoletti', '389 Knutson Crossing', 26);
insert into Restaurant (rname , raddress , rminCost ) values ('Konopelski, Champlin and Sawayn', '40 Delaware Circle', 34);
/* 100 restaurant staff */
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Katuscha Winfindale', 'staff', 'kwinfindale0', 'lunxqH', 7);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Eugenio MacIlwrick', 'staff', 'emacilwrick1', 'EsdGQWrXnwW6', 2);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Dalston MacBean', 'staff', 'dmacbean2', 'Leg79ZkYfQ', 9);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Gar Peye', 'staff', 'gpeye3', 'V8uE0dID', 16);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Enid Dollimore', 'staff', 'edollimore4', 'iIfN7b', 11);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Gasparo Tapping', 'staff', 'gtapping5', '3RR0WRPXfaq', 18);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Margaretha Vize', 'staff', 'mvize6', 'dTZ0Yn73IB', 3);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Josy Laurens', 'staff', 'jlaurens7', 'Ig6KdKSoH', 9);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Anica Endacott', 'staff', 'aendacott8', 'ILunVYYt4oP', 4);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Raquela Flintiff', 'staff', 'rflintiff9', '3sz2ac0', 6);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Townsend Adriaens', 'staff', 'tadriaensa', 'cxfrlJicpZ', 6);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Marcello Sussans', 'staff', 'msussansb', '3qRHa0kOwiKo', 13);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Hewitt Edgson', 'staff', 'hedgsonc', 'XdKhQNDu', 4);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Fan Anfrey', 'staff', 'fanfreyd', 'Lcu6l1fXa', 7);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Sophronia Scamp', 'staff', 'sscampe', 'B38NsVSqaD9', 11);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Felizio Vise', 'staff', 'fvisef', 'umDziZ', 19);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Ruy Marguerite', 'staff', 'rmargueriteg', 'fQkEF7s', 17);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Richie Grenshields', 'staff', 'rgrenshieldsh', 'YfyXa4UVp', 8);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Kennie Joney', 'staff', 'kjoneyi', 'bv5jBd', 2);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Karly Ciani', 'staff', 'kcianij', 'acD2WHw5i', 16);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Lurlene Klazenga', 'staff', 'lklazengak', 'wiidskk', 2);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Sarena Engelmann', 'staff', 'sengelmannl', '7RHoTnv', 12);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Fonsie Lincke', 'staff', 'flinckem', 'wln9nWiIN', 2);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Prudy Freiberg', 'staff', 'pfreibergn', 'FdIAEqI1Pp', 2);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Seana Grelka', 'staff', 'sgrelkao', 'kEUTBw8J', 18);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Mireielle Pilmore', 'staff', 'mpilmorep', 'Zsx2enNc4', 8);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Finlay Soro', 'staff', 'fsoroq', 'd4t1xcGUyYLZ', 5);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Evelina Menpes', 'staff', 'emenpesr', 'aJYDIgLigPdi', 2);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Ottilie Cail', 'staff', 'ocails', 'PLjWMmp', 2);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Arnaldo Gonzalo', 'staff', 'agonzalot', '0IGxip', 16);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Guntar Cray', 'staff', 'gcrayu', 'MS2slWLXH5qI', 19);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Tiena Getley', 'staff', 'tgetleyv', 'E5Ta4fIe', 17);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Tore Edgson', 'staff', 'tedgsonw', 'l3nlG8GHP7T', 4);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Garreth Janatka', 'staff', 'gjanatkax', 'GV8qaasQ2f', 7);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Donna Claessens', 'staff', 'dclaessensy', 'zeUnfO8FHisf', 20);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Evangelina Blakely', 'staff', 'eblakelyz', 'f5GHHiQTj', 8);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Lelah Auston', 'staff', 'lauston10', 'Udm95kx7IE79', 14);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Arny Hoult', 'staff', 'ahoult11', 'BCDEbTrb6m', 3);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Noell Story', 'staff', 'nstory12', 'OfRTGzcHSMG', 4);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Barclay Lebreton', 'staff', 'blebreton13', 'dnYMDvPNc', 9);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Rey Elgar', 'staff', 'relgar14', 'e06o6xVSKT9', 3);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Zebulen Matthessen', 'staff', 'zmatthessen15', '9lQkQIenFKf', 14);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Junie Asaaf', 'staff', 'jasaaf16', 'caGYSFhgrpI', 11);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Clark Oldknow', 'staff', 'coldknow17', 'iTXbhzYFeml', 14);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Celeste Appleford', 'staff', 'cappleford18', '1l0yxIiNtgsL', 14);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Allina Edginton', 'staff', 'aedginton19', 'YiZ1XWwX', 9);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Kessiah Sanderson', 'staff', 'ksanderson1a', 'Dgff4L0B04', 3);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Vinny Cazalet', 'staff', 'vcazalet1b', 'pFDfLyJpKG', 10);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Neila Wensley', 'staff', 'nwensley1c', 'Q0Mt4J', 3);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Tessy Tanguy', 'staff', 'ttanguy1d', 'RdujAhBs', 12);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Quintana Dewing', 'staff', 'qdewing1e', 'Qbm09oWflQ6', 2);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Trisha McGilroy', 'staff', 'tmcgilroy1f', 'zlYZD5WWbnpU', 11);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Fawn Grundey', 'staff', 'fgrundey1g', 'R3vDPbh1K', 15);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Elle Woodyer', 'staff', 'ewoodyer1h', 'Kakes7BSpt', 11);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Jayson Mongin', 'staff', 'jmongin1i', 'A4koZPUlxm', 12);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Robert Cayette', 'staff', 'rcayette1j', 'FEhocO', 15);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Simonne Pringell', 'staff', 'springell1k', 'vN5BXhixUZ', 19);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Corette Kidney', 'staff', 'ckidney1l', 'JYJBt3hlk', 13);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Marylinda Wilkie', 'staff', 'mwilkie1m', 'bq6fswIfvG', 4);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Vikki Larrington', 'staff', 'vlarrington1n', 'DhA3WYcl', 11);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Tiler Mullender', 'staff', 'tmullender1o', 'YvpEN5il', 6);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Brigid Normanvill', 'staff', 'bnormanvill1p', 'zdE19tl', 11);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Marga Mingardi', 'staff', 'mmingardi1q', 'RoR3D9UYE', 19);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Anne-marie Harlick', 'staff', 'aharlick1r', 'SnTxCR', 13);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Rahal Antoniades', 'staff', 'rantoniades1s', 'vNWBLq6v4', 15);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Mirella Rasor', 'staff', 'mrasor1t', 'bhUSHK3NxFj', 19);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Ysabel Goble', 'staff', 'ygoble1u', 'u0Bsr0UVaZLw', 19);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Alexis Hinken', 'staff', 'ahinken1v', '8vdQLKM', 11);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Bard Navarijo', 'staff', 'bnavarijo1w', '7reD46rfO', 8);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Moe Lejeune', 'staff', 'mlejeune1x', 'okbSIPWrcCO', 20);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Angie Duncan', 'staff', 'aduncan1y', 'NsiRQCdb', 7);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Robers Bartels', 'staff', 'rbartels1z', '21rbS3', 17);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Halsy Lindmark', 'staff', 'hlindmark20', 'BwdjJ3yKa', 14);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Maryjane Loch', 'staff', 'mloch21', 'uYF6EJAbbYA', 9);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Ludwig Baskwell', 'staff', 'lbaskwell22', 'FpOgdT2', 8);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Cthrine Jacobovitch', 'staff', 'cjacobovitch23', 'y4MQYMKC', 16);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Gayelord Ashbridge', 'staff', 'gashbridge24', 'B0j4HS27nGF', 19);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Hugues Eisak', 'staff', 'heisak25', 'k4g4lWV', 20);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Cy Coneau', 'staff', 'cconeau26', 'PxMdMw', 7);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Seka Gorton', 'staff', 'sgorton27', 'Ejs2Fxi6VeWv', 6);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Pauli Hayford', 'staff', 'phayford28', 'lCxQnWkf6Jp', 7);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Ricardo Hitzke', 'staff', 'rhitzke29', 'sB8KXyHP', 11);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Giselle McKimm', 'staff', 'gmckimm2a', 'yBYgmcBR5BDn', 17);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Avigdor Gustus', 'staff', 'agustus2b', 'e7znXL', 11);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Dean Rosgen', 'staff', 'drosgen2c', 'kPukfjCROTZM', 3);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Marni Huggens', 'staff', 'mhuggens2d', 'drP6At4cxjEh', 19);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Xylina Tatlow', 'staff', 'xtatlow2e', 'JzrQtArAfzD', 2);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Estele Blackater', 'staff', 'eblackater2f', '1uwdJbQuqJ', 20);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Stinky Whitehead', 'staff', 'swhitehead2g', 'cId2Bwe6Jx', 5);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Mitchel Lancashire', 'staff', 'mlancashire2h', 'fTxKBKt', 1);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Tad Whebell', 'staff', 'twhebell2i', 'RxncAO', 6);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Justin Rispin', 'staff', 'jrispin2j', 'vX08YUb5', 3);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Koenraad MacQuist', 'staff', 'kmacquist2k', 'k1djIzpT5w', 12);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Mycah Chesser', 'staff', 'mchesser2l', 'ek046prJn', 18);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Dukie Gilders', 'staff', 'dgilders2m', 'GiGKc4diJG', 7);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Felipe Fishenden', 'staff', 'ffishenden2n', '33r2kk', 15);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Brigida Twells', 'staff', 'btwells2o', 'Ylqxs5AJ5ey', 10);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Hastings Farleigh', 'staff', 'hfarleigh2p', 'Nxl7L0g', 5);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Fitz Biagioni', 'staff', 'fbiagioni2q', 'ofSDD7NG3AZ', 17);
insert into Restaurant_Staff  (rsname , rsposition , rsusername , rspassword , rid ) values ('Lelia Scurlock', 'staff', 'lscurlock2r', 'D1VuSkDq', 10);

/* 400 food */
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Beef - Ox Tongue', 1, false, 51, 20);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Cookies Almond Hazelnut', 50, false, 37, 18);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Pepper - Jalapeno', 10, false, 39, 7);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Wine - Jaboulet Cotes Du Rhone', 54, true, 47, 13);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Waffle Stix', 39, false, 37, 4);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Mcgillicuddy Vanilla Schnap', 32, false, 90, 10);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Puree - Mango', 64, true, 90, 17);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Cup Translucent 9 Oz', 45, false, 74, 14);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Cardamon Ground', 51, false, 34, 9);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Wine - Red Oakridge Merlot', 18, true, 65, 2);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Onions Granulated', 63, true, 60, 14);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Wine - Magnotta - Belpaese', 26, false, 29, 3);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Miso Paste White', 96, false, 96, 15);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Spice - Onion Powder Granulated', 72, true, 46, 9);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Carbonated Water - Blackcherry', 11, true, 47, 20);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Crush - Cream Soda', 67, true, 89, 7);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Ecolab Digiclean Mild Fm', 58, true, 21, 8);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Sauce - Marinara', 25, false, 48, 9);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Aspic - Light', 62, false, 84, 18);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Potatoes - Mini White 3 Oz', 97, false, 69, 18);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Lid - 3oz Med Rec', 32, true, 43, 2);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Pork - Backfat', 16, false, 72, 9);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Cheese - Brie, Cups 125g', 72, true, 100, 9);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Mousse - Mango', 42, false, 66, 11);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Chocolate - Milk Coating', 18, false, 29, 9);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Cheese - Ermite Bleu', 105, true, 44, 18);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Apricots Fresh', 68, true, 37, 12);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Veal - Striploin', 39, false, 75, 20);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Creme De Cacao Mcguines', 72, false, 74, 16);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Bread - Roll, Calabrese', 63, true, 90, 19);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Durian Fruit', 62, false, 23, 9);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Beef Striploin Aaa', 36, true, 78, 18);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Milkettes - 2%', 52, true, 38, 19);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Chocolate Bar - Oh Henry', 89, false, 96, 8);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Pepsi - 600ml', 90, false, 58, 9);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Water - Evian 355 Ml', 44, false, 97, 10);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Food Colouring - Red', 68, true, 77, 11);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Bar - Sweet And Salty Chocolate', 45, true, 100, 3);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Chocolate - Sugar Free Semi Choc', 7, false, 84, 18);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Jolt Cola', 36, true, 89, 3);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Water, Tap', 1, false, 63, 19);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Bar Mix - Lime', 103, true, 67, 11);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Sauce - Plum', 12, false, 31, 5);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Pastry - Trippleberry Muffin - Mini', 78, false, 82, 11);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Sping Loaded Cup Dispenser', 58, true, 44, 15);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Lid - 10,12,16 Oz', 50, false, 94, 1);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Bacardi Raspberry', 98, true, 98, 19);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Lamb - Leg, Bone In', 20, true, 86, 18);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Lettuce - Radicchio', 21, true, 49, 6);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Soup - Beef, Base Mix', 8, true, 59, 2);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Clam - Cherrystone', 64, true, 50, 19);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Veal - Inside', 32, true, 25, 16);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Foam Tray S2', 22, false, 22, 2);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Chocolate - Milk, Callets', 15, false, 61, 3);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Ice Cream Bar - Hagen Daz', 39, true, 74, 10);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Zucchini - Mini, Green', 36, false, 57, 16);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Wine - Zonnebloem Pinotage', 63, false, 63, 17);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Blue Curacao - Marie Brizard', 95, true, 30, 13);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Magnotta - Bel Paese White', 87, false, 73, 15);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Pickle - Dill', 40, true, 20, 10);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Wine - Magnotta - Cab Franc', 82, false, 83, 5);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Chutney Sauce', 101, true, 72, 12);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Lid Coffeecup 12oz D9542b', 18, false, 20, 20);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Doilies - 8, Paper', 70, false, 100, 19);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Cheese - Stilton', 93, true, 54, 18);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Oven Mitt - 13 Inch', 91, true, 22, 20);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Lentils - Green Le Puy', 20, true, 78, 3);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Dr. Pepper - 355ml', 84, true, 69, 17);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Bread - Bistro Sour', 81, false, 86, 7);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Tray - 12in Rnd Blk', 47, true, 38, 13);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Bread - English Muffin', 45, true, 66, 10);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Pasta - Fettuccine, Dry', 43, true, 91, 3);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Cake Circle, Foil, Scallop', 60, false, 40, 5);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Liners - Banana, Paper', 57, false, 50, 2);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Honey - Comb', 19, false, 86, 15);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Muffin Batt - Carrot Spice', 47, true, 94, 9);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Sprouts - Peppercress', 2, true, 76, 7);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Soup - Campbells Chicken', 3, false, 37, 6);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Cup - Translucent 7 Oz Clear', 57, false, 47, 5);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Wine - Placido Pinot Grigo', 55, false, 57, 1);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Wine - Shiraz Wolf Blass Premium', 5, true, 67, 8);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Bread Bowl Plain', 90, true, 32, 1);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Fireball Whisky', 74, false, 39, 13);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Tuna - Salad Premix', 105, false, 25, 12);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Garbage Bags - Black', 90, false, 42, 18);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Chocolate - Milk Coating', 90, false, 50, 8);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Muffin - Banana Nut Individual', 93, true, 57, 9);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Red Currants', 56, true, 65, 19);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Lettuce - Romaine, Heart', 67, true, 79, 17);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Orange - Tangerine', 95, false, 64, 18);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Oyster - In Shell', 94, true, 45, 3);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Dates', 48, false, 90, 20);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Wine - Zonnebloem Pinotage', 55, true, 86, 7);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Plaintain', 67, true, 88, 12);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Table Cloth 81x81 Colour', 23, false, 53, 3);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Sobe - Orange Carrot', 98, false, 34, 8);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Lid - 0090 Clear', 75, false, 34, 12);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Flour - So Mix Cake White', 50, true, 32, 3);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Table Cloth 53x69 White', 10, false, 31, 3);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Cookies Oatmeal Raisin', 101, true, 92, 2);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Bacardi Raspberry', 7, true, 52, 4);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Rice - Brown', 100, true, 92, 20);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Gloves - Goldtouch Disposable', 31, false, 57, 9);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Pur Value', 80, false, 72, 2);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Beans - Turtle, Black, Dry', 25, true, 26, 14);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Glass - Wine, Plastic, Clear 5 Oz', 29, false, 28, 20);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Sugar - Cubes', 87, true, 72, 19);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Crab - Back Fin Meat, Canned', 19, true, 40, 2);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Mousse - Banana Chocolate', 50, false, 65, 6);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Wine - Fat Bastard Merlot', 92, true, 70, 18);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Flavouring - Rum', 95, true, 60, 13);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Nectarines', 91, true, 23, 7);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Soup - Campbells, Beef Barley', 12, false, 50, 5);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Tea - Orange Pekoe', 88, true, 78, 13);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Ice Cream Bar - Drumstick', 105, false, 47, 17);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Wine - Black Tower Qr', 44, true, 89, 13);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Cake - Box Window 10x10x2.5', 33, true, 53, 18);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Peppercorns - Pink', 71, false, 24, 13);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Octopus - Baby, Cleaned', 7, false, 45, 1);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Nut - Pumpkin Seeds', 22, true, 65, 13);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Oregano - Fresh', 91, true, 35, 12);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Foam Tray S2', 97, false, 32, 15);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Veal - Liver', 42, false, 99, 2);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Blouse / Shirt / Sweater', 81, true, 93, 7);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Mahi Mahi', 94, false, 98, 18);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Energy Drink Red Bull', 102, false, 68, 11);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Oil - Cooking Spray', 56, false, 45, 7);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Scallop - St. Jaques', 64, false, 85, 18);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Veal - Osso Bucco', 25, false, 72, 10);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Crab Meat Claw Pasteurise', 21, false, 38, 2);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Chestnuts - Whole,canned', 42, false, 78, 14);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Appetizer - Cheese Bites', 24, false, 96, 18);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Bread - Pita, Mini', 45, true, 88, 17);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Wine - Red, Lurton Merlot De', 12, false, 89, 8);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Langers - Cranberry Cocktail', 102, false, 93, 12);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Artichokes - Jerusalem', 19, true, 35, 4);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Appetiser - Bought', 45, true, 52, 11);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Coffee - Frthy Coffee Crisp', 93, false, 87, 16);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Pears - Anjou', 32, false, 100, 1);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Fish - Atlantic Salmon, Cold', 96, true, 21, 10);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Spaghetti Squash', 21, true, 62, 9);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Liners - Baking Cups', 56, false, 63, 20);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Veal - Leg, Provimi - 50 Lb Max', 79, false, 64, 3);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Chicken - White Meat, No Tender', 36, true, 78, 10);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Bread - Pita, Mini', 8, true, 46, 12);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Sprouts - Baby Pea Tendrils', 15, true, 95, 13);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Lettuce - Romaine', 47, false, 76, 13);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Appetizer - Assorted Box', 74, false, 37, 1);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Daves Island Stinger', 98, true, 85, 14);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Cilantro / Coriander - Fresh', 91, true, 42, 10);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Wine - Cave Springs Dry Riesling', 25, false, 54, 13);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Onions - White', 77, true, 69, 15);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Wiberg Cure', 77, false, 43, 8);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Cheese - Mascarpone', 51, false, 79, 17);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Oil - Avocado', 19, false, 77, 1);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Cookie Dough - Chocolate Chip', 69, true, 22, 3);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Wine - Chianti Classico Riserva', 75, false, 40, 7);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Flour - Bran, Red', 5, false, 35, 2);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Mop Head - Cotton, 24 Oz', 91, true, 39, 17);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Mousse - Mango', 44, true, 80, 6);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Vinegar - Balsamic, White', 32, true, 89, 17);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Shrimp - Prawn', 100, true, 52, 7);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Carbonated Water - Blackberry', 79, false, 65, 1);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('The Pop Shoppe - Cream Soda', 21, true, 48, 9);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Icecream - Dibs', 31, false, 94, 15);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Cup - 3.5oz, Foam', 70, false, 77, 13);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Truffle Cups - White Paper', 41, false, 24, 9);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Gatorade - Xfactor Berry', 41, false, 79, 13);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Plate - Foam, Bread And Butter', 34, true, 61, 11);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Bread Ww Cluster', 27, true, 45, 17);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Pesto - Primerba, Paste', 97, true, 93, 16);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Juice - Ocean Spray Cranberry', 85, true, 24, 8);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Puff Pastry - Sheets', 34, false, 45, 9);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Latex Rubber Gloves Size 9', 80, true, 88, 3);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Vegetable - Base', 68, false, 26, 18);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Cheese - Roquefort Pappillon', 59, true, 45, 15);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Relish', 72, false, 35, 7);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Cup - Translucent 7 Oz Clear', 29, false, 38, 19);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Pepper - Green Thai', 81, false, 29, 12);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('V8 - Vegetable Cocktail', 54, false, 81, 2);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Stock - Beef, White', 82, true, 67, 11);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Cassis', 73, true, 35, 12);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Marjoram - Fresh', 89, true, 55, 4);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Cleaner - Pine Sol', 54, true, 48, 2);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Lychee - Canned', 52, false, 35, 6);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Coke - Diet, 355 Ml', 19, true, 37, 4);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Crush - Grape, 355 Ml', 51, false, 68, 9);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Ostrich - Prime Cut', 51, false, 88, 17);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Puff Pastry - Sheets', 94, true, 44, 12);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Juice - Cranberry, 341 Ml', 12, true, 52, 6);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Wine - White, Schroder And Schyl', 41, false, 93, 12);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Container - Hngd Cll Blk 7x7x3', 32, true, 75, 19);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Rice - Brown', 1, true, 100, 17);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Veal - Ground', 61, false, 98, 19);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Lamb Tenderloin Nz Fr', 22, false, 27, 1);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Wine - Barbera Alba Doc 2001', 48, true, 36, 13);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Sardines', 82, true, 41, 20);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Wine - Zinfandel California 2002', 3, false, 70, 18);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Chocolate Bar - Smarties', 26, false, 46, 12);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Pork - Bacon, Sliced', 63, false, 43, 11);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Sauce - Bernaise, Mix', 17, false, 58, 12);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Wiberg Cure', 25, true, 37, 15);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Tequila Rose Cream Liquor', 31, true, 85, 6);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Beef - Shank', 9, false, 67, 1);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Artichokes - Jerusalem', 79, true, 55, 15);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Ecolab - Medallion', 58, false, 49, 18);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Melon - Cantaloupe', 48, false, 85, 20);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('The Pop Shoppe - Lime Rickey', 71, true, 21, 2);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Lid - 3oz Med Rec', 20, true, 51, 4);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Veal - Slab Bacon', 48, false, 22, 2);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Table Cloth 81x81 White', 17, true, 30, 7);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Wasabi Paste', 8, false, 73, 2);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Wine - Rhine Riesling Wolf Blass', 1, false, 44, 15);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Instant Coffee', 42, false, 50, 11);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Beef - Ox Tongue', 76, false, 94, 6);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Mushroom - Shitake, Dry', 18, false, 55, 4);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Wine - Baron De Rothschild', 103, false, 22, 17);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Vodka - Lemon, Absolut', 84, true, 22, 20);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Jerusalem Artichoke', 89, true, 38, 3);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Crab - Claws, 26 - 30', 27, true, 79, 20);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Compound - Orange', 85, false, 72, 19);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('C - Plus, Orange', 47, true, 64, 2);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Wine - Chateau Aqueria Tavel', 34, true, 53, 8);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Muffin Batt - Carrot Spice', 9, false, 28, 13);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Mop Head - Cotton, 24 Oz', 12, false, 33, 12);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Cheese - Goat With Herbs', 50, false, 88, 1);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Bread Cranberry Foccacia', 89, false, 34, 15);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Carrots - Purple, Organic', 6, false, 63, 4);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Chestnuts - Whole,canned', 51, true, 94, 3);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Steampan - Half Size Shallow', 33, false, 48, 13);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Carrots - Mini Red Organic', 57, true, 67, 6);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Veal - Bones', 60, false, 52, 17);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Bread - 10 Grain', 17, false, 87, 10);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Kellogs All Bran Bars', 56, true, 50, 18);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Nut - Almond, Blanched, Sliced', 24, true, 23, 14);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Wine - Rioja Campo Viejo', 30, false, 54, 7);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Oven Mitt - 13 Inch', 45, false, 83, 10);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Island Oasis - Ice Cream Mix', 82, true, 76, 10);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Spinach - Spinach Leaf', 46, false, 25, 20);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Pasta - Rotini, Dry', 65, true, 90, 7);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Quail Eggs - Canned', 25, false, 91, 11);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Beef Tenderloin Aaa', 21, false, 81, 16);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Cake Circle, Paprus', 28, true, 78, 4);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Flour - Corn, Fine', 42, false, 54, 19);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Lettuce - Curly Endive', 80, false, 25, 20);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Squid - Tubes / Tenticles 10/20', 49, true, 72, 14);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Coffee - Frthy Coffee Crisp', 89, true, 29, 1);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Beans - Long, Chinese', 61, true, 48, 2);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Lid - High Heat, Super Clear', 79, true, 30, 4);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Ham - Smoked, Bone - In', 24, true, 32, 19);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Pork - Belly Fresh', 48, true, 21, 5);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Wine - Semi Dry Riesling Vineland', 87, false, 67, 20);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Sour Cream', 57, true, 33, 9);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Basil - Fresh', 22, false, 24, 10);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Veal - Osso Bucco', 23, true, 96, 2);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Vinegar - Raspberry', 87, false, 55, 8);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Veal - Slab Bacon', 59, true, 64, 16);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Olives - Black, Pitted', 58, true, 31, 16);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Snails - Large Canned', 26, false, 27, 19);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Chick Peas - Canned', 2, false, 45, 16);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Swiss Chard', 83, false, 80, 7);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Ecolab - Orange Frc, Cleaner', 81, false, 57, 3);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Shrimp - Black Tiger 16/20', 105, false, 75, 4);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Peach - Halves', 35, true, 50, 5);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Wine - Tio Pepe Sherry Fino', 28, true, 43, 4);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Soho Lychee Liqueur', 72, false, 28, 20);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Langers - Mango Nectar', 104, false, 42, 8);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Calypso - Black Cherry Lemonade', 86, true, 49, 9);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Island Oasis - Peach Daiquiri', 43, true, 28, 14);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Pepper - Red Chili', 78, false, 67, 19);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Pepper - Chillies, Crushed', 57, false, 35, 19);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Pastry - Key Limepoppy Seed Tea', 49, true, 92, 15);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Chives - Fresh', 37, false, 75, 15);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Skirt - 24 Foot', 37, true, 85, 6);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Cookie - Oreo 100x2', 91, true, 38, 2);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Cheese - Havarti, Roasted Garlic', 30, false, 49, 17);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Beef - Rib Eye Aaa', 89, true, 22, 18);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Beans - Black Bean, Dry', 86, false, 77, 7);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Eggs - Extra Large', 3, false, 31, 2);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Godiva White Chocolate', 57, false, 92, 7);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Chicken - Livers', 67, true, 88, 4);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Juice - Clam, 46 Oz', 33, false, 89, 17);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Pork - Smoked Kassler', 19, false, 39, 17);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Wine - Zinfandel Rosenblum', 12, true, 59, 6);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Kiwano', 18, false, 97, 17);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Table Cloth 54x72 Colour', 100, false, 58, 19);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Latex Rubber Gloves Size 9', 40, false, 67, 18);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Flour - Buckwheat, Dark', 74, false, 95, 8);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Beans - Green', 84, true, 96, 2);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Pizza Pizza Dough', 18, true, 34, 7);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Crush - Grape, 355 Ml', 18, false, 42, 16);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Glass - Juice Clear 5oz 55005', 85, true, 44, 7);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Appetizer - Asian Shrimp Roll', 88, false, 84, 8);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Canadian Emmenthal', 14, false, 57, 15);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Salmon - Fillets', 96, false, 89, 17);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Oranges - Navel, 72', 36, false, 100, 1);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Halibut - Fletches', 25, false, 83, 12);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Chocolate - White', 61, false, 79, 17);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Soup - Canadian Pea, Dry Mix', 85, true, 76, 2);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Cheese - Blue', 23, true, 51, 7);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Ham Black Forest', 70, false, 55, 13);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Mustard - Seed', 103, false, 93, 10);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Carbonated Water - Orange', 2, true, 46, 3);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Beef - Eye Of Round', 26, true, 52, 20);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Smoked Tongue', 104, false, 57, 20);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Pasta - Fusili, Dry', 61, false, 66, 8);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Wine - Manischewitz Concord', 35, true, 36, 20);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Coffee - Espresso', 23, true, 61, 20);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Cheese Cloth No 100', 85, false, 75, 20);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Alize Red Passion', 91, true, 48, 3);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Pasta - Detalini, White, Fresh', 23, false, 73, 3);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Muffin Mix - Lemon Cranberry', 83, true, 59, 14);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Sunflower Seed Raw', 6, true, 25, 8);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Mushroom - Enoki, Fresh', 87, true, 66, 4);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Tomatoes - Diced, Canned', 85, false, 43, 15);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Cranberries - Dry', 54, true, 84, 17);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Lemonade - Island Tea, 591 Ml', 45, true, 55, 1);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Bar Nature Valley', 46, false, 43, 11);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Turkey - Oven Roast Breast', 18, true, 93, 1);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Veal - Leg, Provimi - 50 Lb Max', 63, true, 32, 20);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Sesame Seed Black', 21, false, 59, 18);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Chicken - Base', 33, false, 73, 15);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Garam Masala Powder', 80, false, 90, 17);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Chips - Assorted', 71, true, 27, 20);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Beer - Steamwhistle', 93, true, 40, 14);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Cookie - Oatmeal', 104, true, 90, 5);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Squash - Pattypan, Yellow', 45, true, 34, 8);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Tomatoes - Cherry, Yellow', 69, false, 49, 6);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Cheese - Provolone', 39, true, 41, 5);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Chocolate - White', 5, false, 47, 20);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Noodles - Cellophane, Thin', 56, false, 38, 5);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Juice - Lime', 35, false, 39, 4);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Puree - Kiwi', 9, true, 42, 18);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Tofu - Firm', 90, true, 57, 9);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Pork - Loin, Bone - In', 27, false, 46, 10);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Goat - Whole Cut', 4, false, 32, 18);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Juice - Apple 284ml', 35, true, 24, 17);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Chicken - Leg / Back Attach', 80, true, 53, 19);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Mustard Prepared', 23, true, 51, 7);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Wine - Lamancha Do Crianza', 105, true, 69, 6);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Sauce - Vodka Blush', 5, true, 41, 11);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Beer - Paulaner Hefeweisse', 88, true, 41, 16);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Wine - Jackson Triggs Okonagan', 60, false, 64, 10);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Flour - Rye', 85, true, 54, 9);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Tomatillo', 31, true, 21, 19);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Tequila - Sauza Silver', 43, true, 39, 4);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Tarragon - Primerba, Paste', 65, false, 26, 13);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Tortillas - Flour, 12', 58, true, 23, 12);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Vinegar - White Wine', 9, true, 63, 11);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Wine - Chenin Blanc K.w.v.', 12, true, 48, 15);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Pork - Side Ribs', 98, true, 91, 8);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Rice - Aborio', 36, true, 48, 16);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Rice - Sushi', 20, false, 80, 16);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Bread Base - Italian', 19, false, 35, 16);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Banana', 55, true, 67, 13);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Soup - Campbells Chili', 58, true, 61, 18);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Pasta - Spaghetti, Dry', 2, true, 30, 2);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Bread - Hot Dog Buns', 96, true, 22, 10);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Prunes - Pitted', 87, false, 22, 5);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Beans - Black Bean, Dry', 56, true, 35, 10);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Strawberries', 96, false, 60, 17);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Corn Syrup', 2, true, 32, 16);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Pear - Packum', 5, true, 21, 10);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Muffin - Mix - Bran And Maple 15l', 105, true, 45, 3);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Soda Water - Club Soda, 355 Ml', 74, true, 64, 20);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Truffle - Peelings', 97, false, 55, 18);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Scallops - 10/20', 102, false, 99, 7);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Bread - Pita, Mini', 20, true, 88, 14);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Beans - Turtle, Black, Dry', 52, true, 79, 4);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Wine - Tribal Sauvignon', 53, true, 74, 9);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Bread - Pain Au Liat X12', 75, true, 93, 4);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Lidsoupcont Rp12dn', 56, false, 36, 14);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Stock - Beef, White', 95, true, 65, 3);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Cake - Bande Of Fruit', 25, false, 30, 16);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Orange - Blood', 80, false, 22, 7);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Pepper - Gypsy Pepper', 58, false, 42, 5);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Energy Drink - Franks Pineapple', 28, false, 63, 12);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Tart - Pecan Butter Squares', 53, false, 98, 7);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Wine - White, Riesling, Henry Of', 18, false, 84, 5);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Potatoes - Yukon Gold 5 Oz', 60, true, 60, 4);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Tumeric', 90, false, 89, 5);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Juice - Grape, White', 12, true, 97, 1);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Ocean Spray - Kiwi Strawberry', 34, false, 40, 16);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Trout Rainbow Whole', 52, false, 78, 17);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Liners - Banana, Paper', 6, false, 96, 9);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Lamb - Leg, Diced', 100, false, 75, 2);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Beans - Yellow', 7, false, 87, 5);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Cardamon Ground', 34, true, 60, 15);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Mushroom - Morel Frozen', 6, false, 92, 15);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Wine - Cotes Du Rhone', 52, true, 83, 12);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Soup V8 Roasted Red Pepper', 34, false, 96, 15);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Split Peas - Yellow, Dry', 37, true, 29, 8);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Fennel - Seeds', 96, true, 34, 3);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Shopper Bag - S - 4', 53, true, 63, 20);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Pickle - Dill', 34, false, 57, 16);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Chicken - White Meat With Tender', 66, true, 37, 6);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Ham - Smoked, Bone - In', 65, true, 61, 3);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Star Fruit', 50, false, 67, 12);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Longos - Chicken Curried', 37, false, 52, 1);
insert into Food (fname , fprice , favailable , flimit , rid ) values ('Energy Drink Bawls', 52, true, 84, 20);
/* categories */
insert into Category (cname) values ('japanese');
insert into Category (cname) values ('western');
insert into Category (cname) values ('malay');
insert into Category (cname) values ('chinese');
insert into Category (cname) values ('indian');
insert into Category (cname) values ('vegetarian');
insert into Category (cname) values ('fast food');
/* food_categorized */
insert into food_categorized (fid, cid) values (1, 1);
insert into food_categorized (fid, cid) values (2, 2);
insert into food_categorized (fid, cid) values (3, 3);
insert into food_categorized (fid, cid) values (4, 4);
insert into food_categorized (fid, cid) values (5, 5);
insert into food_categorized (fid, cid) values (6, 6);
insert into food_categorized (fid, cid) values (7, 7);
insert into food_categorized (fid, cid) values (8, 1);
insert into food_categorized (fid, cid) values (9, 2);
insert into food_categorized (fid, cid) values (10, 3);
insert into food_categorized (fid, cid) values (11, 4);
insert into food_categorized (fid, cid) values (12, 5);
insert into food_categorized (fid, cid) values (13, 6);
insert into food_categorized (fid, cid) values (14, 7);
insert into food_categorized (fid, cid) values (15, 1);
insert into food_categorized (fid, cid) values (16, 2);
insert into food_categorized (fid, cid) values (17, 3);
insert into food_categorized (fid, cid) values (18, 4);
insert into food_categorized (fid, cid) values (19, 5);
insert into food_categorized (fid, cid) values (20, 6);
insert into food_categorized (fid, cid) values (21, 7);
insert into food_categorized (fid, cid) values (22, 1);
insert into food_categorized (fid, cid) values (23, 2);
insert into food_categorized (fid, cid) values (24, 3);
insert into food_categorized (fid, cid) values (25, 4);
insert into food_categorized (fid, cid) values (26, 5);
insert into food_categorized (fid, cid) values (27, 6);
insert into food_categorized (fid, cid) values (28, 7);
insert into food_categorized (fid, cid) values (29, 1);
insert into food_categorized (fid, cid) values (30, 2);
insert into food_categorized (fid, cid) values (31, 3);
insert into food_categorized (fid, cid) values (32, 4);
insert into food_categorized (fid, cid) values (33, 5);
insert into food_categorized (fid, cid) values (34, 6);
insert into food_categorized (fid, cid) values (35, 7);
insert into food_categorized (fid, cid) values (36, 1);
insert into food_categorized (fid, cid) values (37, 2);
insert into food_categorized (fid, cid) values (38, 3);
insert into food_categorized (fid, cid) values (39, 4);
insert into food_categorized (fid, cid) values (40, 5);
insert into food_categorized (fid, cid) values (41, 6);
insert into food_categorized (fid, cid) values (42, 7);
insert into food_categorized (fid, cid) values (43, 1);
insert into food_categorized (fid, cid) values (44, 2);
insert into food_categorized (fid, cid) values (45, 3);
insert into food_categorized (fid, cid) values (46, 4);
insert into food_categorized (fid, cid) values (47, 5);
insert into food_categorized (fid, cid) values (48, 6);
insert into food_categorized (fid, cid) values (49, 7);
insert into food_categorized (fid, cid) values (50, 1);
insert into food_categorized (fid, cid) values (51, 2);
insert into food_categorized (fid, cid) values (52, 3);
insert into food_categorized (fid, cid) values (53, 4);
insert into food_categorized (fid, cid) values (54, 5);
insert into food_categorized (fid, cid) values (55, 6);
insert into food_categorized (fid, cid) values (56, 7);
insert into food_categorized (fid, cid) values (57, 1);
insert into food_categorized (fid, cid) values (58, 2);
insert into food_categorized (fid, cid) values (59, 3);
insert into food_categorized (fid, cid) values (60, 4);
insert into food_categorized (fid, cid) values (61, 5);
insert into food_categorized (fid, cid) values (62, 6);
insert into food_categorized (fid, cid) values (63, 7);
insert into food_categorized (fid, cid) values (64, 1);
insert into food_categorized (fid, cid) values (65, 2);
insert into food_categorized (fid, cid) values (66, 3);
insert into food_categorized (fid, cid) values (67, 4);
insert into food_categorized (fid, cid) values (68, 5);
insert into food_categorized (fid, cid) values (69, 6);
insert into food_categorized (fid, cid) values (70, 7);
insert into food_categorized (fid, cid) values (71, 1);
insert into food_categorized (fid, cid) values (72, 2);
insert into food_categorized (fid, cid) values (73, 3);
insert into food_categorized (fid, cid) values (74, 4);
insert into food_categorized (fid, cid) values (75, 5);
insert into food_categorized (fid, cid) values (76, 6);
insert into food_categorized (fid, cid) values (77, 7);
insert into food_categorized (fid, cid) values (78, 1);
insert into food_categorized (fid, cid) values (79, 2);
insert into food_categorized (fid, cid) values (80, 3);
insert into food_categorized (fid, cid) values (81, 4);
insert into food_categorized (fid, cid) values (82, 5);
insert into food_categorized (fid, cid) values (83, 6);
insert into food_categorized (fid, cid) values (84, 7);
insert into food_categorized (fid, cid) values (85, 1);
insert into food_categorized (fid, cid) values (86, 2);
insert into food_categorized (fid, cid) values (87, 3);
insert into food_categorized (fid, cid) values (88, 4);
insert into food_categorized (fid, cid) values (89, 5);
insert into food_categorized (fid, cid) values (90, 6);
insert into food_categorized (fid, cid) values (91, 7);
insert into food_categorized (fid, cid) values (92, 1);
insert into food_categorized (fid, cid) values (93, 2);
insert into food_categorized (fid, cid) values (94, 3);
insert into food_categorized (fid, cid) values (95, 4);
insert into food_categorized (fid, cid) values (96, 5);
insert into food_categorized (fid, cid) values (97, 6);
insert into food_categorized (fid, cid) values (98, 7);
insert into food_categorized (fid, cid) values (99, 1);
insert into food_categorized (fid, cid) values (100, 2);
insert into food_categorized (fid, cid) values (101, 3);
insert into food_categorized (fid, cid) values (102, 4);
insert into food_categorized (fid, cid) values (103, 5);
insert into food_categorized (fid, cid) values (104, 6);
insert into food_categorized (fid, cid) values (105, 7);
insert into food_categorized (fid, cid) values (106, 1);
insert into food_categorized (fid, cid) values (107, 2);
insert into food_categorized (fid, cid) values (108, 3);
insert into food_categorized (fid, cid) values (109, 4);
insert into food_categorized (fid, cid) values (110, 5);
insert into food_categorized (fid, cid) values (111, 6);
insert into food_categorized (fid, cid) values (112, 7);
insert into food_categorized (fid, cid) values (113, 1);
insert into food_categorized (fid, cid) values (114, 2);
insert into food_categorized (fid, cid) values (115, 3);
insert into food_categorized (fid, cid) values (116, 4);
insert into food_categorized (fid, cid) values (117, 5);
insert into food_categorized (fid, cid) values (118, 6);
insert into food_categorized (fid, cid) values (119, 7);
insert into food_categorized (fid, cid) values (120, 1);
insert into food_categorized (fid, cid) values (121, 2);
insert into food_categorized (fid, cid) values (122, 3);
insert into food_categorized (fid, cid) values (123, 4);
insert into food_categorized (fid, cid) values (124, 5);
insert into food_categorized (fid, cid) values (125, 6);
insert into food_categorized (fid, cid) values (126, 7);
insert into food_categorized (fid, cid) values (127, 1);
insert into food_categorized (fid, cid) values (128, 2);
insert into food_categorized (fid, cid) values (129, 3);
insert into food_categorized (fid, cid) values (130, 4);
insert into food_categorized (fid, cid) values (131, 5);
insert into food_categorized (fid, cid) values (132, 6);
insert into food_categorized (fid, cid) values (133, 7);
insert into food_categorized (fid, cid) values (134, 1);
insert into food_categorized (fid, cid) values (135, 2);
insert into food_categorized (fid, cid) values (136, 3);
insert into food_categorized (fid, cid) values (137, 4);
insert into food_categorized (fid, cid) values (138, 5);
insert into food_categorized (fid, cid) values (139, 6);
insert into food_categorized (fid, cid) values (140, 7);
insert into food_categorized (fid, cid) values (141, 1);
insert into food_categorized (fid, cid) values (142, 2);
insert into food_categorized (fid, cid) values (143, 3);
insert into food_categorized (fid, cid) values (144, 4);
insert into food_categorized (fid, cid) values (145, 5);
insert into food_categorized (fid, cid) values (146, 6);
insert into food_categorized (fid, cid) values (147, 7);
insert into food_categorized (fid, cid) values (148, 1);
insert into food_categorized (fid, cid) values (149, 2);
insert into food_categorized (fid, cid) values (150, 3);
insert into food_categorized (fid, cid) values (151, 4);
insert into food_categorized (fid, cid) values (152, 5);
insert into food_categorized (fid, cid) values (153, 6);
insert into food_categorized (fid, cid) values (154, 7);
insert into food_categorized (fid, cid) values (155, 1);
insert into food_categorized (fid, cid) values (156, 2);
insert into food_categorized (fid, cid) values (157, 3);
insert into food_categorized (fid, cid) values (158, 4);
insert into food_categorized (fid, cid) values (159, 5);
insert into food_categorized (fid, cid) values (160, 6);
insert into food_categorized (fid, cid) values (161, 7);
insert into food_categorized (fid, cid) values (162, 1);
insert into food_categorized (fid, cid) values (163, 2);
insert into food_categorized (fid, cid) values (164, 3);
insert into food_categorized (fid, cid) values (165, 4);
insert into food_categorized (fid, cid) values (166, 5);
insert into food_categorized (fid, cid) values (167, 6);
insert into food_categorized (fid, cid) values (168, 7);
insert into food_categorized (fid, cid) values (169, 1);
insert into food_categorized (fid, cid) values (170, 2);
insert into food_categorized (fid, cid) values (171, 3);
insert into food_categorized (fid, cid) values (172, 4);
insert into food_categorized (fid, cid) values (173, 5);
insert into food_categorized (fid, cid) values (174, 6);
insert into food_categorized (fid, cid) values (175, 7);
insert into food_categorized (fid, cid) values (176, 1);
insert into food_categorized (fid, cid) values (177, 2);
insert into food_categorized (fid, cid) values (178, 3);
insert into food_categorized (fid, cid) values (179, 4);
insert into food_categorized (fid, cid) values (180, 5);
insert into food_categorized (fid, cid) values (181, 6);
insert into food_categorized (fid, cid) values (182, 7);
insert into food_categorized (fid, cid) values (183, 1);
insert into food_categorized (fid, cid) values (184, 2);
insert into food_categorized (fid, cid) values (185, 3);
insert into food_categorized (fid, cid) values (186, 4);
insert into food_categorized (fid, cid) values (187, 5);
insert into food_categorized (fid, cid) values (188, 6);
insert into food_categorized (fid, cid) values (189, 7);
insert into food_categorized (fid, cid) values (190, 1);
insert into food_categorized (fid, cid) values (191, 2);
insert into food_categorized (fid, cid) values (192, 3);
insert into food_categorized (fid, cid) values (193, 4);
insert into food_categorized (fid, cid) values (194, 5);
insert into food_categorized (fid, cid) values (195, 6);
insert into food_categorized (fid, cid) values (196, 7);
insert into food_categorized (fid, cid) values (197, 1);
insert into food_categorized (fid, cid) values (198, 2);
insert into food_categorized (fid, cid) values (199, 3);
insert into food_categorized (fid, cid) values (200, 4);
insert into food_categorized (fid, cid) values (201, 5);
insert into food_categorized (fid, cid) values (202, 6);
insert into food_categorized (fid, cid) values (203, 7);
insert into food_categorized (fid, cid) values (204, 1);
insert into food_categorized (fid, cid) values (205, 2);
insert into food_categorized (fid, cid) values (206, 3);
insert into food_categorized (fid, cid) values (207, 4);
insert into food_categorized (fid, cid) values (208, 5);
insert into food_categorized (fid, cid) values (209, 6);
insert into food_categorized (fid, cid) values (210, 7);
insert into food_categorized (fid, cid) values (211, 1);
insert into food_categorized (fid, cid) values (212, 2);
insert into food_categorized (fid, cid) values (213, 3);
insert into food_categorized (fid, cid) values (214, 4);
insert into food_categorized (fid, cid) values (215, 5);
insert into food_categorized (fid, cid) values (216, 6);
insert into food_categorized (fid, cid) values (217, 7);
insert into food_categorized (fid, cid) values (218, 1);
insert into food_categorized (fid, cid) values (219, 2);
insert into food_categorized (fid, cid) values (220, 3);
insert into food_categorized (fid, cid) values (221, 4);
insert into food_categorized (fid, cid) values (222, 5);
insert into food_categorized (fid, cid) values (223, 6);
insert into food_categorized (fid, cid) values (224, 7);
insert into food_categorized (fid, cid) values (225, 1);
insert into food_categorized (fid, cid) values (226, 2);
insert into food_categorized (fid, cid) values (227, 3);
insert into food_categorized (fid, cid) values (228, 4);
insert into food_categorized (fid, cid) values (229, 5);
insert into food_categorized (fid, cid) values (230, 6);
insert into food_categorized (fid, cid) values (231, 7);
insert into food_categorized (fid, cid) values (232, 1);
insert into food_categorized (fid, cid) values (233, 2);
insert into food_categorized (fid, cid) values (234, 3);
insert into food_categorized (fid, cid) values (235, 4);
insert into food_categorized (fid, cid) values (236, 5);
insert into food_categorized (fid, cid) values (237, 6);
insert into food_categorized (fid, cid) values (238, 7);
insert into food_categorized (fid, cid) values (239, 1);
insert into food_categorized (fid, cid) values (240, 2);
insert into food_categorized (fid, cid) values (241, 3);
insert into food_categorized (fid, cid) values (242, 4);
insert into food_categorized (fid, cid) values (243, 5);
insert into food_categorized (fid, cid) values (244, 6);
insert into food_categorized (fid, cid) values (245, 7);
insert into food_categorized (fid, cid) values (246, 1);
insert into food_categorized (fid, cid) values (247, 2);
insert into food_categorized (fid, cid) values (248, 3);
insert into food_categorized (fid, cid) values (249, 4);
insert into food_categorized (fid, cid) values (250, 5);
insert into food_categorized (fid, cid) values (251, 6);
insert into food_categorized (fid, cid) values (252, 7);
insert into food_categorized (fid, cid) values (253, 1);
insert into food_categorized (fid, cid) values (254, 2);
insert into food_categorized (fid, cid) values (255, 3);
insert into food_categorized (fid, cid) values (256, 4);
insert into food_categorized (fid, cid) values (257, 5);
insert into food_categorized (fid, cid) values (258, 6);
insert into food_categorized (fid, cid) values (259, 7);
insert into food_categorized (fid, cid) values (260, 1);
insert into food_categorized (fid, cid) values (261, 2);
insert into food_categorized (fid, cid) values (262, 3);
insert into food_categorized (fid, cid) values (263, 4);
insert into food_categorized (fid, cid) values (264, 5);
insert into food_categorized (fid, cid) values (265, 6);
insert into food_categorized (fid, cid) values (266, 7);
insert into food_categorized (fid, cid) values (267, 1);
insert into food_categorized (fid, cid) values (268, 2);
insert into food_categorized (fid, cid) values (269, 3);
insert into food_categorized (fid, cid) values (270, 4);
insert into food_categorized (fid, cid) values (271, 5);
insert into food_categorized (fid, cid) values (272, 6);
insert into food_categorized (fid, cid) values (273, 7);
insert into food_categorized (fid, cid) values (274, 1);
insert into food_categorized (fid, cid) values (275, 2);
insert into food_categorized (fid, cid) values (276, 3);
insert into food_categorized (fid, cid) values (277, 4);
insert into food_categorized (fid, cid) values (278, 5);
insert into food_categorized (fid, cid) values (279, 6);
insert into food_categorized (fid, cid) values (280, 7);
insert into food_categorized (fid, cid) values (281, 1);
insert into food_categorized (fid, cid) values (282, 2);
insert into food_categorized (fid, cid) values (283, 3);
insert into food_categorized (fid, cid) values (284, 4);
insert into food_categorized (fid, cid) values (285, 5);
insert into food_categorized (fid, cid) values (286, 6);
insert into food_categorized (fid, cid) values (287, 7);
insert into food_categorized (fid, cid) values (288, 1);
insert into food_categorized (fid, cid) values (289, 2);
insert into food_categorized (fid, cid) values (290, 3);
insert into food_categorized (fid, cid) values (291, 4);
insert into food_categorized (fid, cid) values (292, 5);
insert into food_categorized (fid, cid) values (293, 6);
insert into food_categorized (fid, cid) values (294, 7);
insert into food_categorized (fid, cid) values (295, 1);
insert into food_categorized (fid, cid) values (296, 2);
insert into food_categorized (fid, cid) values (297, 3);
insert into food_categorized (fid, cid) values (298, 4);
insert into food_categorized (fid, cid) values (299, 5);
insert into food_categorized (fid, cid) values (300, 6);
insert into food_categorized (fid, cid) values (301, 7);
insert into food_categorized (fid, cid) values (302, 1);
insert into food_categorized (fid, cid) values (303, 2);
insert into food_categorized (fid, cid) values (304, 3);
insert into food_categorized (fid, cid) values (305, 4);
insert into food_categorized (fid, cid) values (306, 5);
insert into food_categorized (fid, cid) values (307, 6);
insert into food_categorized (fid, cid) values (308, 7);
insert into food_categorized (fid, cid) values (309, 1);
insert into food_categorized (fid, cid) values (310, 2);
insert into food_categorized (fid, cid) values (311, 3);
insert into food_categorized (fid, cid) values (312, 4);
insert into food_categorized (fid, cid) values (313, 5);
insert into food_categorized (fid, cid) values (314, 6);
insert into food_categorized (fid, cid) values (315, 7);
insert into food_categorized (fid, cid) values (316, 1);
insert into food_categorized (fid, cid) values (317, 2);
insert into food_categorized (fid, cid) values (318, 3);
insert into food_categorized (fid, cid) values (319, 4);
insert into food_categorized (fid, cid) values (320, 5);
insert into food_categorized (fid, cid) values (321, 6);
insert into food_categorized (fid, cid) values (322, 7);
insert into food_categorized (fid, cid) values (323, 1);
insert into food_categorized (fid, cid) values (324, 2);
insert into food_categorized (fid, cid) values (325, 3);
insert into food_categorized (fid, cid) values (326, 4);
insert into food_categorized (fid, cid) values (327, 5);
insert into food_categorized (fid, cid) values (328, 6);
insert into food_categorized (fid, cid) values (329, 7);
insert into food_categorized (fid, cid) values (330, 1);
insert into food_categorized (fid, cid) values (331, 2);
insert into food_categorized (fid, cid) values (332, 3);
insert into food_categorized (fid, cid) values (333, 4);
insert into food_categorized (fid, cid) values (334, 5);
insert into food_categorized (fid, cid) values (335, 6);
insert into food_categorized (fid, cid) values (336, 7);
insert into food_categorized (fid, cid) values (337, 1);
insert into food_categorized (fid, cid) values (338, 2);
insert into food_categorized (fid, cid) values (339, 3);
insert into food_categorized (fid, cid) values (340, 4);
insert into food_categorized (fid, cid) values (341, 5);
insert into food_categorized (fid, cid) values (342, 6);
insert into food_categorized (fid, cid) values (343, 7);
insert into food_categorized (fid, cid) values (344, 1);
insert into food_categorized (fid, cid) values (345, 2);
insert into food_categorized (fid, cid) values (346, 3);
insert into food_categorized (fid, cid) values (347, 4);
insert into food_categorized (fid, cid) values (348, 5);
insert into food_categorized (fid, cid) values (349, 6);
insert into food_categorized (fid, cid) values (350, 7);
insert into food_categorized (fid, cid) values (351, 1);
insert into food_categorized (fid, cid) values (352, 2);
insert into food_categorized (fid, cid) values (353, 3);
insert into food_categorized (fid, cid) values (354, 4);
insert into food_categorized (fid, cid) values (355, 5);
insert into food_categorized (fid, cid) values (356, 6);
insert into food_categorized (fid, cid) values (357, 7);
insert into food_categorized (fid, cid) values (358, 1);
insert into food_categorized (fid, cid) values (359, 2);
insert into food_categorized (fid, cid) values (360, 3);
insert into food_categorized (fid, cid) values (361, 4);
insert into food_categorized (fid, cid) values (362, 5);
insert into food_categorized (fid, cid) values (363, 6);
insert into food_categorized (fid, cid) values (364, 7);
insert into food_categorized (fid, cid) values (365, 1);
insert into food_categorized (fid, cid) values (366, 2);
insert into food_categorized (fid, cid) values (367, 3);
insert into food_categorized (fid, cid) values (368, 4);
insert into food_categorized (fid, cid) values (369, 5);
insert into food_categorized (fid, cid) values (370, 6);
insert into food_categorized (fid, cid) values (371, 7);
insert into food_categorized (fid, cid) values (372, 1);
insert into food_categorized (fid, cid) values (373, 2);
insert into food_categorized (fid, cid) values (374, 3);
insert into food_categorized (fid, cid) values (375, 4);
insert into food_categorized (fid, cid) values (376, 5);
insert into food_categorized (fid, cid) values (377, 6);
insert into food_categorized (fid, cid) values (378, 7);
insert into food_categorized (fid, cid) values (379, 1);
insert into food_categorized (fid, cid) values (380, 2);
insert into food_categorized (fid, cid) values (381, 3);
insert into food_categorized (fid, cid) values (382, 4);
insert into food_categorized (fid, cid) values (383, 5);
insert into food_categorized (fid, cid) values (384, 6);
insert into food_categorized (fid, cid) values (385, 7);
insert into food_categorized (fid, cid) values (386, 1);
insert into food_categorized (fid, cid) values (387, 2);
insert into food_categorized (fid, cid) values (388, 3);
insert into food_categorized (fid, cid) values (389, 4);
insert into food_categorized (fid, cid) values (390, 5);
insert into food_categorized (fid, cid) values (391, 6);
insert into food_categorized (fid, cid) values (392, 7);
insert into food_categorized (fid, cid) values (393, 1);
insert into food_categorized (fid, cid) values (394, 2);
insert into food_categorized (fid, cid) values (395, 3);
insert into food_categorized (fid, cid) values (396, 4);
insert into food_categorized (fid, cid) values (397, 5);
insert into food_categorized (fid, cid) values (398, 6);
insert into food_categorized (fid, cid) values (399, 7);
insert into food_categorized (fid, cid) values (400, 1);

/* 200 customers */
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (172, 80116057, 'acoldbreath0', '6C6ud99u3', '2019-07-09 08:09:24', 42);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (15, 95723472, 'melletson1', 'mN6Tw72aQJ', '2019-07-26 05:23:58', 180);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (226, 85822776, 'ssandels2', 'zWV2xGApAu', '2020-03-19 01:14:02', 45);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (70, 88702396, 'jllewhellin3', '0ged6Y', '2020-01-20 09:43:21', 33);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (375, 89034198, 'ctace4', 'wbSdZI06QOQ', '2020-03-29 22:37:11', 0);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (276, 95689723, 'sfeast5', 'Qz5B2bZv', '2020-01-19 03:58:18', 166);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (306, 83606645, 'boatley6', 'IcNSC0D4JOlL', '2020-02-03 14:50:45', 75);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (235, 82620870, 'cprue7', 'WPSlgJ', '2019-12-30 11:08:17', 33);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (75, 94004681, 'fmattevi8', 'z9EM11JpuoqQ', '2019-12-24 04:05:23', 185);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (12, 84995402, 'hbaelde9', 'QrJmtCTDxv', '2019-09-16 07:20:14', 103);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (109, 93743335, 'shansleya', 'u9yQodhyD', '2020-02-23 19:53:01', 118);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (70, 91540534, 'celsieb', 'HwLeabmtZm8Q', '2019-05-20 02:03:16', 39);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (373, 88433644, 'bdymickc', 'KW4SNQCzgc9', '2019-12-10 22:29:55', 14);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (181, 85644153, 'pmagaurand', 'b3b4RL', '2019-06-27 06:53:52', 112);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (95, 81006601, 'mmcphatere', 'RvdDeK', '2020-03-07 19:13:22', 185);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (399, 86277378, 'fswofferf', 'a2c0SQFgc1T', '2019-07-13 22:13:17', 88);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (213, 81243560, 'llangthorng', 'N88Rp8rI', '2020-04-18 14:09:10', 104);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (7, 98387661, 'ahastonh', '5NRe6iLUDa', '2019-12-28 01:21:50', 32);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (289, 90200185, 'mceysseni', 'IR5E4T', '2019-11-12 16:08:22', 93);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (176, 93284691, 'kporkerj', 'oMoKQLq4n79p', '2020-04-01 23:18:05', 135);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (372, 84084351, 'otemplek', 'T0HVfiI3r', '2019-09-26 12:49:47', 83);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (114, 92245928, 'lgreggersenl', 'PjJVMD', '2020-05-02 20:57:18', 139);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (216, 87000225, 'mgarfordm', 'IJgYCRgYu8', '2019-05-29 15:47:14', 139);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (108, 82509883, 'celementn', 'D0IRFG65yA2', '2019-08-31 23:43:57', 97);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (161, 93076787, 'kdredgeo', 'dGsl7PNSR5hi', '2020-02-17 23:04:25', 92);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (25, 80990957, 'lnoonp', 'aWzhDWT', '2019-08-31 06:44:27', 176);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (282, 84508582, 'bfevierq', 'AfqRdjJwx', '2019-06-28 02:12:18', 34);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (219, 96873950, 'aleeburner', 'ROvehZiOp7', '2019-05-20 13:31:18', 46);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (359, 93992941, 'zickeringills', '5HTYEZr7', '2019-10-22 02:38:27', 39);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (326, 80871676, 'ycomleyt', 'ssahoKynPZ', '2019-08-31 15:59:48', 97);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (253, 85205520, 'ffirmingeru', 'jlo5mxH', '2019-11-10 16:06:55', 140);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (205, 85732990, 'ckermanv', 'egJZOuW', '2019-07-31 02:43:38', 18);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (39, 96145295, 'fomahoneyw', 'wZRFiXD5aCGK', '2019-06-02 08:12:38', 48);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (190, 99063165, 'nhardisonx', '7bJkLkM6H4pr', '2019-07-12 15:22:14', 86);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (24, 96525793, 'cgaity', 'IoShqOYgIA6x', '2019-10-21 23:15:53', 100);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (156, 93586124, 'channyz', 'adJ5pZw0FKMP', '2019-11-06 03:27:59', 185);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (157, 85174334, 'cscourfield10', 'b3C6RG9yd', '2019-12-12 06:02:24', 60);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (17, 86523440, 'deastwell11', 'IbbJlRn', '2019-06-11 19:07:57', 57);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (162, 91958548, 'acarhart12', 'AX5C3j7ng', '2020-04-15 02:07:18', 167);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (369, 96674134, 'vhurn13', 'AA4O5yvx5v', '2019-11-21 21:00:37', 165);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (113, 85514532, 'fmcreynolds14', 'uaTrETaDE', '2019-08-30 16:57:52', 5);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (164, 83680397, 'sduckfield15', '7Vv8ytpZp4C', '2019-10-16 13:21:19', 124);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (354, 85639709, 'fstarkings16', 'cuTtW86UB4s', '2019-06-01 12:19:40', 5);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (229, 94541803, 'pllorens17', 'YDGbWcAfiik', '2019-08-17 02:18:41', 61);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (79, 86003514, 'atreves18', 'jJqb48', '2019-07-18 12:32:58', 156);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (279, 89936489, 'vclist19', 'jlFgrb00CnA0', '2019-06-23 15:29:24', 20);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (261, 90972816, 'smcgreary1a', '8WSvvSlba1Jm', '2020-04-20 10:55:14', 92);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (264, 94500288, 'maspin1b', 'o9Bq7Zj', '2020-04-13 15:23:29', 38);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (239, 89389745, 'gtremathack1c', 'zvyOcsdqa7', '2020-03-13 10:09:15', 21);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (189, 92124965, 'ehiggan1d', 'S4MSfJV3', '2019-10-19 19:18:41', 126);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (198, 95611583, 'pdart1e', 'sPotieO6U0', '2019-11-26 08:05:26', 31);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (312, 86761783, 'rfazakerley1f', 'ndj44xCprmGD', '2019-11-15 07:19:05', 9);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (131, 82954499, 'kcroke1g', 'oJcVsWS0Q', '2019-05-07 18:55:06', 58);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (286, 96898450, 'cgriffey1h', 'VfiMwlydr', '2019-06-18 05:20:20', 191);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (38, 96844363, 'blander1i', 'coWCcCidxfg', '2019-06-07 02:07:12', 82);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (240, 81067309, 'mhayler1j', 'CAaLyp', '2020-01-01 15:17:33', 32);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (262, 86680483, 'wslesser1k', 'QDfG7dG', '2019-09-28 15:53:19', 125);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (61, 84349994, 'zkoeppke1l', 'U7sedy', '2019-07-08 16:14:28', 182);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (161, 95999412, 'lcreane1m', 'H5fcnOnPErzS', '2020-05-03 10:29:58', 189);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (278, 86490912, 'wkilgannon1n', '4lVjBhYwQsX', '2019-12-07 22:30:09', 133);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (242, 91320181, 'sharlick1o', 'kI9msW', '2020-03-02 02:27:48', 55);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (388, 97819338, 'lpassmore1p', 'tkad5PEYnB2m', '2019-10-11 00:43:18', 86);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (303, 97966003, 'cannott1q', 'MFjkvgTMwxe', '2020-02-06 08:45:37', 8);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (309, 88532080, 'eclurow1r', 'hEUILs10QK', '2020-03-30 08:41:44', 126);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (154, 97520276, 'hlebourn1s', 'RSVB97s', '2019-09-10 16:42:23', 126);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (328, 91123756, 'vsinden1t', 'V4ONTpa5QkP', '2019-12-21 06:09:45', 182);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (110, 99477246, 'tbryers1u', 'YyDl2V9IZK', '2020-05-01 21:12:43', 133);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (311, 97974591, 'rsizeland1v', 'l0mzsrbFJtGy', '2019-09-22 23:38:00', 95);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (290, 94731584, 'rcosta1w', '11dSFRj', '2019-07-08 13:02:52', 21);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (123, 84303694, 'ahellin1x', '92aNEcIt', '2019-08-03 18:21:26', 15);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (34, 85079038, 'rparagreen1y', 'YUpI3Y', '2019-12-04 12:25:36', 83);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (376, 87737752, 'ebilham1z', 'yJqxesx', '2019-12-21 04:36:04', 115);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (306, 91397440, 'kbetancourt20', 'GUArkLOX', '2019-12-24 22:45:15', 165);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (120, 80600784, 'avinsen21', 'gXrndLtD', '2020-04-27 20:49:20', 58);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (68, 87716570, 'lducham22', 'R5GV9HUZ2', '2020-02-26 04:57:19', 142);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (344, 94847624, 'sgovan23', 'O2GsHNRfDK', '2019-11-06 03:22:16', 102);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (54, 88093574, 'cgent24', 'jc7GF7xB', '2019-12-07 07:31:09', 81);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (37, 96766054, 'ahurrell25', 'cQjhZhkE', '2020-04-30 00:11:56', 96);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (316, 82264517, 'aelliott26', '2EWLrG0', '2019-08-04 20:21:03', 144);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (351, 98150035, 'nstaker27', 'VpsFXVl', '2019-08-09 23:25:29', 85);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (398, 90237943, 'cspringer28', 'ruoi7sIpMs', '2019-11-26 07:11:05', 49);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (259, 80061788, 'ealliston29', 'VofyeMQMU', '2019-09-24 21:33:25', 141);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (47, 92837686, 'sfilippone2a', 'fK5F19H', '2020-04-02 23:55:48', 72);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (164, 86545796, 'zlyptrit2b', '55mV8ONS6', '2019-09-22 16:36:32', 118);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (47, 86255324, 'ucubbinelli2c', 's4XG3oX', '2019-12-09 14:00:22', 102);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (254, 91248678, 'svear2d', 'dK3ZUs1K', '2020-04-08 17:50:20', 197);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (184, 96041058, 'eroger2e', '8noDsQnDaEei', '2020-02-20 00:54:11', 22);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (189, 81094446, 'kpickover2f', 'SxjdxZKSkx8m', '2019-05-27 17:17:20', 5);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (399, 98749623, 'edermott2g', 'tloYkeBbTEvM', '2019-11-27 08:08:30', 114);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (55, 96152478, 'cledgerton2h', 'n1bdQH', '2019-07-07 23:12:24', 74);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (236, 84147586, 'tvandervelde2i', 'KDbHt7AUjs', '2020-04-17 21:24:55', 177);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (294, 80992552, 'lbaford2j', 'sHrvfMNYT1', '2019-05-11 03:24:38', 28);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (361, 95200120, 'hducket2k', 'uBN67Zh', '2019-07-16 17:11:16', 179);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (15, 83186023, 'thawarden2l', 'trmGH8', '2020-01-22 02:35:26', 23);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (144, 99674108, 'rbuzza2m', 'fRNnfL', '2020-01-06 13:07:51', 143);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (322, 81662042, 'skosel2n', 'LxeFXhmwjj', '2020-03-12 06:48:04', 86);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (213, 90423445, 'hdoumic2o', '3kLF9XrHJ', '2019-10-22 11:47:54', 38);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (12, 98035747, 'diddy2p', '1jU58j', '2020-03-25 21:05:03', 185);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (358, 87415558, 'tsurgener2q', 'pUqmxCPWvSB', '2020-01-17 21:45:21', 66);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (311, 92217100, 'tpagelsen2r', 'MZPw8aGCF', '2019-07-18 03:04:13', 169);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (316, 98020392, 'plotwich2s', 'qwcxMjUAfU8d', '2019-10-03 13:50:41', 80);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (124, 95726915, 'ablewitt2t', 'xbBf0cgrC5', '2020-04-29 06:55:59', 1);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (254, 95618402, 'bpena2u', 'jEM6JpKA', '2019-09-27 20:40:22', 96);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (217, 84558739, 'kmurname2v', '4bDkFHh6', '2019-05-26 04:51:03', 49);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (258, 86555634, 'mdafter2w', 'ITyL4rWWo9S', '2019-08-18 00:25:11', 42);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (233, 81671916, 'bwetherill2x', 'Ay8OqLe6hIJ', '2019-06-04 23:17:06', 5);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (78, 80700935, 'apatchett2y', 'F0Rqa9BIpFlA', '2019-10-16 05:35:40', 76);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (361, 93528598, 'sbarrabeale2z', 'oCrFYR', '2019-05-24 15:03:41', 110);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (68, 81097287, 'edelisle30', 'wqOtNeRC', '2019-09-20 15:33:02', 18);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (77, 99346171, 'dveart31', 'FBXZ9gPZNFyZ', '2019-11-22 13:04:41', 169);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (393, 84141036, 'eantonov32', 'DseL3R', '2020-01-16 05:59:26', 73);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (320, 89008080, 'redis33', '6twRYlBZoQ', '2020-04-11 11:47:01', 171);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (265, 90663477, 'igymlett34', 'do6pd3X', '2019-06-14 01:30:45', 104);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (199, 84535273, 'hburnall35', 'nLaF5Iq', '2020-01-12 06:37:14', 22);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (161, 93544342, 'mtedstone36', 'Bhw1965J9ZI', '2020-02-11 06:31:35', 51);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (350, 87811452, 'glinforth37', 'YsQ0l2s', '2020-01-01 04:08:52', 125);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (152, 86019014, 'ccollumbine38', 'yM3P3WqOF7', '2019-06-05 10:10:18', 93);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (128, 93013970, 'rmccaull39', '953FGu792m', '2019-09-26 09:47:25', 37);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (200, 80205885, 'hcoulthart3a', 'r6Yoc4duW2Yc', '2019-12-25 06:08:23', 21);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (125, 98843185, 'genglishby3b', 'IzwpRXwVX9', '2020-01-15 16:34:21', 81);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (358, 86989253, 'ajenkinson3c', 'XImCmC', '2020-03-09 01:01:57', 192);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (388, 97512747, 'pbrinded3d', 'LfrMqbtn', '2019-10-10 18:34:40', 76);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (99, 89633519, 'tjosovitz3e', 'feVzw7tMOp', '2019-09-11 21:17:16', 124);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (254, 90268482, 'mcoultas3f', 'pi0xw8rgnG', '2020-02-29 02:30:47', 8);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (152, 92229916, 'fsalkeld3g', 'oYENsAtMAf56', '2019-09-21 13:04:52', 0);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (236, 98305152, 'avandalen3h', 'gWFyTY', '2020-01-16 10:15:43', 198);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (73, 98187104, 'rkoch3i', 'aeWLg5YjU', '2020-01-19 00:25:25', 138);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (100, 94489105, 'cjest3j', 'bbqEQJH', '2020-01-27 23:45:53', 183);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (34, 86745337, 'lpingston3k', 'UqwypwCVPG', '2019-05-24 02:05:30', 115);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (121, 81562590, 'mferber3l', 'AYnKV2CZ3', '2019-06-21 06:54:38', 35);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (309, 80287354, 'ipeppard3m', 'UwHdMyr', '2019-09-25 23:34:48', 70);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (313, 90728257, 'kfleis3n', 'Xk9H0st1ZMi', '2019-10-02 09:17:39', 65);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (77, 81363462, 'azahor3o', 'MxPvFgTNSH5', '2019-06-15 17:18:55', 113);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (371, 90208188, 'esille3p', 'voJJzw', '2019-08-13 21:17:27', 43);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (91, 89562214, 'hholdworth3q', 'GSm2WUbFWPq8', '2020-03-26 02:39:55', 54);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (257, 81111485, 'agregon3r', 'iqugqO6tP', '2019-11-09 19:41:22', 34);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (119, 81277419, 'mwarlawe3s', 'upczGEg', '2019-07-24 13:29:29', 137);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (15, 92613349, 'fdelagua3t', 'GVYnxt', '2019-09-27 02:25:43', 21);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (104, 91439216, 'eblune3u', 'QRRFA2DItT', '2019-06-24 06:24:38', 71);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (226, 86738548, 'byurasov3v', 'NQzNM0krxcl', '2019-12-04 06:28:58', 99);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (269, 93589580, 'bkippax3w', 'P9ApDeUSblO', '2019-05-06 21:28:01', 34);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (99, 85047619, 'rallen3x', 'slN88YFja', '2020-03-23 16:29:01', 86);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (300, 85714993, 'gbarnwill3y', 'IOUXDdG', '2019-10-12 03:30:24', 58);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (41, 83966558, 'tbelfitt3z', 'n042yIEy', '2019-06-26 02:23:03', 87);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (342, 91832294, 'dleebetter40', 'vPCF64qo', '2019-11-30 21:28:24', 20);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (181, 87779781, 'sdax41', 'xvd4V6x3ba', '2019-10-03 10:52:49', 179);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (112, 88248829, 'hgatsby42', 'SebxVskwijz8', '2019-07-31 08:40:05', 21);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (167, 86827299, 'sschrei43', 'jaWwWp7', '2019-12-10 05:30:15', 114);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (389, 96277826, 'dreolfo44', 'x2yHRU', '2019-08-30 08:45:38', 195);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (141, 89793424, 'hdellcasa45', 'l8y4zU8sVk0', '2019-08-27 00:07:14', 140);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (253, 97944130, 'lbougen46', 'K0SStk6S', '2019-06-02 00:04:48', 92);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (165, 84384164, 'ebeeching47', '5mdCTIgDS', '2019-12-03 11:06:39', 36);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (328, 93798044, 'bwillas48', 'JrgiCF3T', '2020-04-08 05:46:01', 146);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (28, 98738344, 'cmaypother49', 'vlbanK', '2020-02-18 15:52:24', 135);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (267, 96412418, 'pglen4a', '3ZzVy98', '2020-04-07 03:42:50', 108);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (176, 80798790, 'tcridland4b', 'u2Cfbq', '2020-01-01 08:16:55', 100);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (267, 99612536, 'cmackintosh4c', 'jxQoFY', '2019-07-07 16:41:57', 82);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (172, 96577868, 'ckeeves4d', 'LMkHQuEy', '2020-01-20 10:02:33', 124);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (213, 91985490, 'jbullon4e', 'QA4gab1EL', '2019-11-18 22:13:45', 33);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (224, 98837215, 'mheis4f', 'MdE71W', '2019-12-08 02:18:48', 70);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (131, 91751039, 'rravilious4g', 'SMdchNiayp', '2019-09-13 00:22:03', 16);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (154, 85461383, 'mivetts4h', 'tVJ6H6mcITr', '2019-08-15 23:19:17', 188);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (192, 94439599, 'mhuddlestone4i', '7zlpdsHpob', '2019-07-11 20:46:15', 23);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (119, 85181168, 'jarkow4j', 'Au0VnNzWns5', '2019-12-22 18:57:54', 88);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (48, 86250725, 'mcolaco4k', 'S23KvxmmA', '2020-02-22 09:13:48', 173);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (319, 92207260, 'proadnight4l', 'Hc2s8KwF1t', '2019-11-27 21:24:03', 22);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (202, 92524726, 'dplumbley4m', 'gdsoUuAD9G', '2020-02-04 15:07:38', 9);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (146, 86618945, 'hspeedin4n', '186yEq', '2019-10-27 18:43:46', 28);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (165, 95790060, 'skesley4o', 'UJ7nAua0YI', '2019-12-04 08:09:30', 49);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (45, 94013259, 'hroast4p', 'W7v1jIe', '2020-04-05 14:03:39', 192);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (27, 85289812, 'lnobles4q', 'URF4r2', '2020-02-12 04:00:58', 72);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (31, 82976160, 'cslemmonds4r', 'YUDGBg1OGB', '2020-03-05 13:21:04', 134);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (152, 88444397, 'sgoning4s', 'jbeEs5oUn', '2019-05-18 22:47:22', 80);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (26, 85212148, 'mleimster4t', 'toqEopAAw', '2020-02-21 04:53:29', 93);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (301, 99384955, 'qspacy4u', '2iA0zatFnAI', '2019-07-28 01:59:04', 76);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (111, 80680023, 'goxberry4v', '4FWTP3', '2019-07-18 16:42:41', 22);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (88, 89192599, 'dkristoffersson4w', '44Oe3T395gA', '2019-08-16 19:55:21', 95);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (76, 91359541, 'dshellum4x', 'ufiBEbA', '2019-07-01 18:47:49', 66);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (78, 89427771, 'bgoodchild4y', '3EMvq16', '2019-11-15 11:42:10', 160);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (90, 97676349, 'jhentze4z', 'j74dUJ', '2020-03-13 15:04:15', 92);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (75, 96699882, 'strengrove50', 'MK65RbICiqu', '2019-09-19 04:14:38', 62);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (337, 89829184, 'raitchison51', '5mHmCoE3a4', '2019-08-27 09:24:23', 4);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (199, 90963866, 'smacpadene52', 'Sv5LYvCU', '2019-07-18 05:15:28', 118);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (119, 84090090, 'sjeskin53', 'pn1l4a7M', '2019-07-30 06:23:40', 80);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (246, 92036379, 'dbertolin54', 'FBKlTS1vdR', '2019-09-27 12:11:25', 75);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (110, 94473093, 'jczajkowski55', '42VIRpamBlt', '2020-03-06 02:20:41', 140);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (60, 99128937, 'rburkin56', 'suxaBAu', '2019-12-02 18:55:54', 40);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (28, 96254172, 'ghartington57', 'prctdf', '2019-07-07 13:28:10', 143);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (152, 89400797, 'tdimont58', 'bRRtzCwv3I', '2019-12-07 08:25:59', 4);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (229, 90811015, 'rrussen59', 'v0Hxd0', '2020-01-17 14:44:43', 97);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (42, 86383462, 'dpiscopiello5a', 'FEOcOUfp04', '2019-09-05 02:10:45', 10);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (293, 91684023, 'cmacgaughey5b', 'cezi6jaSBN8B', '2019-10-23 10:26:46', 36);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (147, 84363941, 'rrotherforth5c', 'BI2OHasy', '2019-12-27 02:59:05', 26);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (134, 96400816, 'sgraeser5d', 'WZPYIuNYi', '2019-09-17 09:51:12', 114);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (267, 89331971, 'emunnery5e', 'kEEXLWL', '2019-05-27 00:38:18', 183);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (169, 90961933, 'ejouandet5f', 'sjdSqgCeXwXi', '2020-03-10 04:13:55', 135);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (388, 87385931, 'edybbe5g', 'S8lknvZHD', '2020-03-11 21:51:32', 194);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (338, 83583987, 'qsargant5h', 'i3tfd9k', '2019-06-18 13:55:23', 51);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (62, 82146567, 'hgiacoboni5i', 'zRXKJ9i', '2019-05-19 19:35:25', 106);
insert into Customer  (cname , ccontact_number , cusername , cpassword , cjoin_time , crewards_points ) values (248, 91054134, 'eedmand5j', '1IQvck', '2020-02-14 06:42:21', 103);
/* Insert 10 credit cards */
insert into Credit_Card (card_number , expiry_date , cvv ) values ('6279897008691244', '2023-06-28', '903');
insert into Credit_Card (card_number , expiry_date , cvv ) values ('2635758762981183', '2023-11-06', '501');
insert into Credit_Card (card_number , expiry_date , cvv ) values ('6236293555109328', '2023-01-27', '427');
insert into Credit_Card (card_number , expiry_date , cvv ) values ('2775841044591945', '2022-12-30', '965');
insert into Credit_Card (card_number , expiry_date , cvv ) values ('2077074784740775', '2021-08-12', '610');
insert into Credit_Card (card_number , expiry_date , cvv ) values ('8736977535888996', '2024-04-25', '422');
insert into Credit_Card (card_number , expiry_date , cvv ) values ('3809104583708476', '2022-01-12', '656');
insert into Credit_Card (card_number , expiry_date , cvv ) values ('2336421415478093', '2021-09-02', '146');
insert into Credit_Card (card_number , expiry_date , cvv ) values ('3467341406899653', '2022-04-17', '820');
insert into Credit_Card (card_number , expiry_date , cvv ) values ('9101479422148008', '2023-12-16', '656');

insert into register_cc  (card_number , expiry_date , cvv , cid) values ('6279897008691244', '2023-06-28', '903', 1);
insert into register_cc  (card_number , expiry_date , cvv , cid) values ('2635758762981183', '2023-11-06', '501', 1);
insert into register_cc  (card_number , expiry_date , cvv , cid) values ('6236293555109328', '2023-01-27', '427', 2);
insert into register_cc  (card_number , expiry_date , cvv , cid) values ('2775841044591945', '2022-12-30', '965', 2);
insert into register_cc  (card_number , expiry_date , cvv , cid) values ('2077074784740775', '2021-08-12', '610', 3);
insert into register_cc  (card_number , expiry_date , cvv , cid) values ('8736977535888996', '2024-04-25', '422', 3);
insert into register_cc  (card_number , expiry_date , cvv , cid) values ('3809104583708476', '2022-01-12', '656', 4);
insert into register_cc  (card_number , expiry_date , cvv , cid) values ('2336421415478093', '2021-09-02', '146', 4);
insert into register_cc  (card_number , expiry_date , cvv , cid) values ('3467341406899653', '2022-04-17', '820', 5);
insert into register_cc  (card_number , expiry_date , cvv , cid) values ('9101479422148008', '2023-12-16', '656', 5);

/* 10 percentage promotion */
insert into Promotion (prid , percentage , pdatetime_active_from , pdatetime_active_to , pminSpend , pdiscount_val , pname , pdescription ) values (19, 26, '2019-10-14 04:32:53', '2020-06-20 09:21:51', 61, 0, 'promo', 'good deal');
insert into Promotion (prid , percentage , pdatetime_active_from , pdatetime_active_to , pminSpend , pdiscount_val , pname , pdescription ) values (5, 3, '2019-09-04 20:40:36', '2020-07-04 13:15:29', 6, 0, 'promo', 'good deal');
insert into Promotion (prid , percentage , pdatetime_active_from , pdatetime_active_to , pminSpend , pdiscount_val , pname , pdescription ) values (3, 19, '2020-03-16 11:59:19', '2020-07-02 03:30:34', 4, 0, 'promo', 'good deal');
insert into Promotion (prid , percentage , pdatetime_active_from , pdatetime_active_to , pminSpend , pdiscount_val , pname , pdescription ) values (20, 33, '2019-08-14 02:59:59', '2020-05-27 03:06:22', 69, 0, 'promo', 'good deal');
insert into Promotion (prid , percentage , pdatetime_active_from , pdatetime_active_to , pminSpend , pdiscount_val , pname , pdescription ) values (9, 42, '2019-06-28 19:45:51', '2020-05-11 15:12:57', 100, 0, 'promo', 'good deal');
insert into Promotion (prid , percentage , pdatetime_active_from , pdatetime_active_to , pminSpend , pdiscount_val , pname , pdescription ) values (8, 35, '2020-02-12 15:33:33', '2020-05-16 15:46:00', 88, 0, 'promo', 'good deal');
insert into Promotion (prid , percentage , pdatetime_active_from , pdatetime_active_to , pminSpend , pdiscount_val , pname , pdescription ) values (4, 6, '2019-08-30 21:12:27', '2020-05-23 14:48:36', 7, 0, 'promo', 'good deal');
insert into Promotion (prid , percentage , pdatetime_active_from , pdatetime_active_to , pminSpend , pdiscount_val , pname , pdescription ) values (15, 12, '2019-10-29 14:23:27', '2020-05-29 13:55:40', 89, 0, 'promo', 'good deal');
insert into Promotion (prid , percentage , pdatetime_active_from , pdatetime_active_to , pminSpend , pdiscount_val , pname , pdescription ) values (11, 39, '2019-08-10 10:36:20', '2020-05-28 21:07:28', 38, 0, 'promo', 'good deal');
insert into Promotion (prid , percentage , pdatetime_active_from , pdatetime_active_to , pminSpend , pdiscount_val , pname , pdescription ) values (9, 40, '2019-05-17 07:58:31', '2020-06-18 04:05:33', 58, 0, 'promo', 'good deal');

/* 10 food item discount */
insert into Promotion (prid , percentage , pdatetime_active_from , pdatetime_active_to , pminSpend , pdiscount_val , pname , pdescription ) values (8, 100, '2019-11-27 07:50:18', '2020-07-25 03:16:04', 47, 9, 'promo', 'good deal');
insert into Promotion (prid , percentage , pdatetime_active_from , pdatetime_active_to , pminSpend , pdiscount_val , pname , pdescription ) values (6, 100, '2019-08-25 22:54:04', '2020-07-11 21:53:56', 52, 7, 'promo', 'good deal');
insert into Promotion (prid , percentage , pdatetime_active_from , pdatetime_active_to , pminSpend , pdiscount_val , pname , pdescription ) values (19, 100, '2019-08-13 12:38:15', '2020-07-04 22:03:42', 2, 6, 'promo', 'good deal');
insert into Promotion (prid , percentage , pdatetime_active_from , pdatetime_active_to , pminSpend , pdiscount_val , pname , pdescription ) values (5, 100, '2019-11-01 18:22:10', '2020-05-17 03:41:39', 13, 1, 'promo', 'good deal');
insert into Promotion (prid , percentage , pdatetime_active_from , pdatetime_active_to , pminSpend , pdiscount_val , pname , pdescription ) values (6, 100, '2019-05-01 09:51:10', '2020-06-08 16:17:43', 63, 10, 'promo', 'good deal');
insert into Promotion (prid , percentage , pdatetime_active_from , pdatetime_active_to , pminSpend , pdiscount_val , pname , pdescription ) values (1, 100, '2019-08-08 16:13:21', '2020-07-05 07:31:01', 44, 10, 'promo', 'good deal');
insert into Promotion (prid , percentage , pdatetime_active_from , pdatetime_active_to , pminSpend , pdiscount_val , pname , pdescription ) values (10, 100, '2019-08-10 16:37:47', '2020-07-15 10:27:36', 87, 4, 'promo', 'good deal');
insert into Promotion (prid , percentage , pdatetime_active_from , pdatetime_active_to , pminSpend , pdiscount_val , pname , pdescription ) values (2, 100, '2019-06-17 04:35:04', '2020-07-12 10:52:49', 13, 3, 'promo', 'good deal');
insert into Promotion (prid , percentage , pdatetime_active_from , pdatetime_active_to , pminSpend , pdiscount_val , pname , pdescription ) values (8, 100, '2019-12-05 17:13:06', '2020-05-16 05:19:31', 16, 8, 'promo', 'good deal');
insert into Promotion (prid , percentage , pdatetime_active_from , pdatetime_active_to , pminSpend , pdiscount_val , pname , pdescription ) values (16, 100, '2019-09-02 13:24:09', '2020-05-25 21:13:34', 38, 8, 'promo', 'good deal');

insert into Campaign (pid, cMon, cTue, cWed, cThu, cFri, cSun, cSat) values (20, false, false, false, false, false, false, false);
insert into Campaign (pid, cMon, cTue, cWed, cThu, cFri, cSun, cSat) values (19, false, false, false, false, false, false, false);
insert into Campaign (pid, cMon, cTue, cWed, cThu, cFri, cSun, cSat) values (11, false, false, false, false, false, false, false);
insert into Campaign (pid, cMon, cTue, cWed, cThu, cFri, cSun, cSat) values (15, false, false, false, false, false, false, false);
insert into Campaign (pid, cMon, cTue, cWed, cThu, cFri, cSun, cSat) values (12, false, false, false, false, false, false, false);
insert into Campaign (pid, cMon, cTue, cWed, cThu, cFri, cSun, cSat) values (14, false, false, false, false, false, false, false);
insert into Campaign (pid, cMon, cTue, cWed, cThu, cFri, cSun, cSat) values (16, false, false, false, false, false, false, false);
insert into Campaign (pid, cMon, cTue, cWed, cThu, cFri, cSun, cSat) values (17, false, false, false, false, false, false, false);
insert into Campaign (pid, cMon, cTue, cWed, cThu, cFri, cSun, cSat) values (13, false, false, false, false, false, false, false);
insert into Campaign (pid, cMon, cTue, cWed, cThu, cFri, cSun, cSat) values (18, false, false, false, false, false, false, false);

insert into Offer_On (fid, pid) values (123, 11);
insert into Offer_On (fid, pid) values (288, 12);
insert into Offer_On (fid, pid) values (68, 13);
insert into Offer_On (fid, pid) values (246, 14);
insert into Offer_On (fid, pid) values (165, 15);
insert into Offer_On (fid, pid) values (362, 17);
insert into Offer_On (fid, pid) values (293, 16);
insert into Offer_On (fid, pid) values (93, 18);
insert into Offer_On (fid, pid) values (78, 19);
insert into Offer_On (fid, pid) values (173, 20);


/* 10 Coupons */
insert into Promotion (prid , percentage , pdatetime_active_from , pdatetime_active_to , pminSpend , pdiscount_val , pname , pdescription ) values (3, 100, '2/20/2020', '4/16/2020', 0, 11, 'coupon', 'dollar discount');
insert into Promotion (prid , percentage , pdatetime_active_from , pdatetime_active_to , pminSpend , pdiscount_val , pname , pdescription ) values (5, 100, '2/28/2020', '4/7/2020', 0, 20, 'coupon', 'dollar discount');
insert into Promotion (prid , percentage , pdatetime_active_from , pdatetime_active_to , pminSpend , pdiscount_val , pname , pdescription ) values (7, 100, '1/31/2020', '5/1/2020', 0, 14, 'coupon', 'dollar discount');
insert into Promotion (prid , percentage , pdatetime_active_from , pdatetime_active_to , pminSpend , pdiscount_val , pname , pdescription ) values (12, 100, '2/13/2020', '5/31/2020', 0, 14, 'coupon', 'dollar discount');
insert into Promotion (prid , percentage , pdatetime_active_from , pdatetime_active_to , pminSpend , pdiscount_val , pname , pdescription ) values (4, 100, '1/9/2020', '4/29/2020', 0, 16, 'coupon', 'dollar discount');
insert into Promotion (prid , percentage , pdatetime_active_from , pdatetime_active_to , pminSpend , pdiscount_val , pname , pdescription ) values (1, 100, '1/27/2020', '5/7/2020', 0, 10, 'coupon', 'dollar discount');
insert into Promotion (prid , percentage , pdatetime_active_from , pdatetime_active_to , pminSpend , pdiscount_val , pname , pdescription ) values (2, 100, '1/19/2020', '5/8/2020', 0, 16, 'coupon', 'dollar discount');
insert into Promotion (prid , percentage , pdatetime_active_from , pdatetime_active_to , pminSpend , pdiscount_val , pname , pdescription ) values (6, 100, '2/1/2020', '4/11/2020', 0, 10, 'coupon', 'dollar discount');
insert into Promotion (prid , percentage , pdatetime_active_from , pdatetime_active_to , pminSpend , pdiscount_val , pname , pdescription ) values (9, 100, '1/31/2020', '5/29/2020', 0, 14, 'coupon', 'dollar discount');
insert into Promotion (prid , percentage , pdatetime_active_from , pdatetime_active_to , pminSpend , pdiscount_val , pname , pdescription ) values (10, 100, '2/13/2020', '5/10/2020', 0, 11, 'coupon', 'dollar discount');


insert into Coupon (cid, couponCode) values (26, 'WtsphqSm15');
insert into Coupon (cid, couponCode) values (27, 'Yk0a7CjB6L');
insert into Coupon (cid, couponCode) values (28, 'axKQsBJvb5');
insert into Coupon (cid, couponCode) values (23, 'HeItbH3Jbu');
insert into Coupon (cid, couponCode) values (29, 'r1sUk6RfUL');
insert into Coupon (cid, couponCode) values (24, 'sLjuKGLA5c');
insert into Coupon (cid, couponCode) values (30, 'I4fucIjDZy');
insert into Coupon (cid, couponCode) values (21, 'ZYokM8sS0y');
insert into Coupon (cid, couponCode) values (22, 'UywZuQ5qwq');
insert into Coupon (cid, couponCode) values (25, 'Brf4Taulwu');

insert into coupon_wallet (custid, cid) values (10, 21);
insert into coupon_wallet (custid, cid) values (9, 24);
insert into coupon_wallet (custid, cid) values (10, 23);
insert into coupon_wallet (custid, cid) values (9, 22);
insert into coupon_wallet (custid, cid) values (8, 26);
insert into coupon_wallet (custid, cid) values (1, 27);
insert into coupon_wallet (custid, cid) values (5, 29);
insert into coupon_wallet (custid, cid) values (7, 28);
insert into coupon_wallet (custid, cid) values (4, 30);
insert into coupon_wallet (custid, cid) values (2, 25);

/* 10 Orders all from restaurant id 2 food id 10 */
insert into Order_List  (oorder_place_time , oorder_arrives_customer , odelivery_fee , ofinal_price , ozipcode , opayment_type ) values ('2020-05-07 00:00:00', '2020-05-07 10:00:00', 10, 18, '012886', 'cash');
insert into Order_List  (oorder_place_time , oorder_arrives_customer , odelivery_fee , ofinal_price , ozipcode , opayment_type ) values ('2020-05-07 00:00:00', '2020-05-07 10:00:00', 10, 18, '013746', 'cash');
insert into Order_List  (oorder_place_time , oorder_arrives_customer , odelivery_fee , ofinal_price , ozipcode , opayment_type ) values ('2020-05-07 00:00:00', '2020-05-07 10:00:00', 10, 18, '012257', 'cash');
insert into Order_List  (oorder_place_time , oorder_arrives_customer , odelivery_fee , ofinal_price , ozipcode , opayment_type ) values ('2020-05-07 00:00:00', '2020-05-07 10:00:00', 10, 18, '017550', 'cash');
insert into Order_List  (oorder_place_time , oorder_arrives_customer , odelivery_fee , ofinal_price , ozipcode , opayment_type ) values ('2020-05-07 00:00:00', '2020-05-07 10:00:00', 10, 18, '013073', 'cash');
insert into Order_List  (oorder_place_time , oorder_arrives_customer , odelivery_fee , ofinal_price , ozipcode , opayment_type ) values ('2020-05-07 00:00:00', '2020-05-07 10:00:00', 10, 18, '014498', 'cash');
insert into Order_List  (oorder_place_time , oorder_arrives_customer , odelivery_fee , ofinal_price , ozipcode , opayment_type ) values ('2020-05-07 00:00:00', '2020-05-07 10:00:00', 10, 18, '010994', 'cash');
insert into Order_List  (oorder_place_time , oorder_arrives_customer , odelivery_fee , ofinal_price , ozipcode , opayment_type ) values ('2020-05-07 00:00:00', '2020-05-07 10:00:00', 10, 18, '019706', 'cash');
insert into Order_List  (oorder_place_time , oorder_arrives_customer , odelivery_fee , ofinal_price , ozipcode , opayment_type ) values ('2020-05-07 00:00:00', '2020-05-07 10:00:00', 10, 18, '013790', 'cash');
insert into Order_List  (oorder_place_time , oorder_arrives_customer , odelivery_fee , ofinal_price , ozipcode , opayment_type ) values ('2020-05-07 00:00:00', '2020-05-07 10:00:00', 10, 18, '016938', 'cash');

/* insert food items of order */
insert into order_contains  (unit_price , quantity , total_price , fid , ocid ) values (18, 1, 18, 10, 1);
insert into order_contains  (unit_price , quantity , total_price , fid , ocid ) values (18, 1, 18, 10, 4);
insert into order_contains  (unit_price , quantity , total_price , fid , ocid ) values (18, 1, 18, 10, 5);
insert into order_contains  (unit_price , quantity , total_price , fid , ocid ) values (18, 1, 18, 10, 7);
insert into order_contains  (unit_price , quantity , total_price , fid , ocid ) values (18, 1, 18, 10, 2);
insert into order_contains  (unit_price , quantity , total_price , fid , ocid ) values (18, 1, 18, 10, 3);
insert into order_contains  (unit_price , quantity , total_price , fid , ocid ) values (18, 1, 18, 10, 6);
insert into order_contains  (unit_price , quantity , total_price , fid , ocid ) values (18, 1, 18, 10, 10);
insert into order_contains  (unit_price , quantity , total_price , fid , ocid ) values (18, 1, 18, 10, 9);
insert into order_contains  (unit_price , quantity , total_price , fid , ocid ) values (18, 1, 18, 10, 8);

/* insert reviews for each order */
insert into make_order  (rest_rating , review_text , ocid , rid , cid ) values (5, 'Morbi porttitor lorem id ligula. Suspendisse ornare consequat lectus. In est risus, auctor sed, tristique in, tempus sit amet, sem. Fusce consequat. Nulla nisl. Nunc nisl. Duis bibendum, felis sed interdum venenatis, turpis enim blandit mi, in porttitor pede justo eu massa. Donec dapibus. Duis at velit eu est congue elementum.', 1, 2, 4);
insert into make_order  (rest_rating , review_text , ocid , rid , cid ) values (9, 'In hac habitasse platea dictumst. Etiam faucibus cursus urna. Ut tellus. Nulla ut erat id mauris vulputate elementum. Nullam varius. Nulla facilisi. Cras non velit nec nisi vulputate nonummy. Maecenas tincidunt lacus at velit.', 2, 2, 2);
insert into make_order  (rest_rating , review_text , ocid , rid , cid ) values (8, 'Duis ac nibh. Fusce lacus purus, aliquet at, feugiat non, pretium quis, lectus. Suspendisse potenti.', 3, 2, 1);
insert into make_order  (rest_rating , review_text , ocid , rid , cid ) values (3, 'Suspendisse ornare consequat lectus. In est risus, auctor sed, tristique in, tempus sit amet, sem. Fusce consequat. Nulla nisl. Nunc nisl. Duis bibendum, felis sed interdum venenatis, turpis enim blandit mi, in porttitor pede justo eu massa.', 4, 2, 3);
insert into make_order  (rest_rating , review_text , ocid , rid , cid ) values (6, 'Phasellus in felis. Donec semper sapien a libero. Nam dui. Proin leo odio, porttitor id, consequat in, consequat ut, nulla. Sed accumsan felis.', 5, 2, 2);
insert into make_order  (rest_rating , review_text , ocid , rid , cid ) values (2, 'Donec dapibus. Duis at velit eu est congue elementum. In hac habitasse platea dictumst. Morbi vestibulum, velit id pretium iaculis, diam erat fermentum justo, nec condimentum neque sapien placerat ante. Nulla justo. Aliquam quis turpis eget elit sodales scelerisque. Mauris sit amet eros.', 6, 2, 2);
insert into make_order  (rest_rating , review_text , ocid , rid , cid ) values (1, 'Cras in purus eu magna vulputate luctus. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Vivamus vestibulum sagittis sapien. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Etiam vel augue.', 7, 2, 5);
insert into make_order  (rest_rating , review_text , ocid , rid , cid ) values (6, 'Donec dapibus.', 9, 2, 5);
insert into make_order  (rest_rating , review_text , ocid , rid , cid ) values (2, 'In hac habitasse platea dictumst. Morbi vestibulum, velit id pretium iaculis, diam erat fermentum justo, nec condimentum neque sapien placerat ante. Nulla justo.', 10, 2, 2);
insert into make_order  (rest_rating , review_text , ocid , rid , cid ) values (1, 'Nam congue, risus semper porta volutpat, quam pede lobortis ligula, sit amet eleifend pede libero quis orci. Nullam molestie nibh in lectus. Pellentesque at nulla. Suspendisse potenti. Cras in purus eu magna vulputate luctus.', 8, 2, 1);

/* delivery rating */

insert into delivered_by  (drating , ocid , rid , cid ) values (2, 1, 1, 4);
insert into delivered_by  (drating , ocid , rid , cid ) values (1, 2, 1, 2);
insert into delivered_by  (drating , ocid , rid , cid ) values (8, 3, 1, 1);
insert into delivered_by  (drating , ocid , rid , cid ) values (6, 4, 1, 3);
insert into delivered_by  (drating , ocid , rid , cid ) values (6, 5, 1, 2);
insert into delivered_by  (drating , ocid , rid , cid ) values (10, 6, 1, 2);
insert into delivered_by  (drating , ocid , rid , cid ) values (4, 7, 1, 5);
insert into delivered_by  (drating , ocid , rid , cid ) values (10, 8, 1, 5);
insert into delivered_by  (drating , ocid , rid , cid ) values (4, 9, 1, 2);
insert into delivered_by  (drating , ocid , rid , cid ) values (2, 10, 1, 1);

COMMIT;
