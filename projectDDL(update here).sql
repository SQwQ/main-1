Create Schema public;
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
	oorder_place_time TIMESTAMP,
	oorder_enroute_restaurant TIMESTAMP,
	oorder_arrives_restaurant TIMESTAMP,
	oorder_enroute_customer TIMESTAMP,
	oorder_arrives_customer TIMESTAMP,
	odelivery_fee NUMERIC NOT NULL CHECK (odelivery_fee >= 0),
	ofinal_price NUMERIC NOT NULL CHECK (ofinal_price >= 0),
	ozipcode NUMERIC NOT NULL,
	odelivery_address TEXT,
	opayment_type TEXT
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
    
    ELSEIF (SELECT favailable FROM Fodd WHERE fid = NEW.fid) = False THEN
    DELETE FROM order_contains WHERE ocid = NEW.ocid AND fid = NEW.fid; 
    RAISE EXCEPTION USING MESSAGE = 'The item is currently unavailable';	
    
    END IF;

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

