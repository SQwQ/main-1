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
	opayment_type TEXT,
	orating INTEGER,
	ostatus TEXT
);

CREATE TABLE order_contains (
	unit_price NUMERIC NOT NULL CHECK (unit_price >= 0),
	quantity INTEGER NOT NULL CHECK (quantity > 0),
	total_price NUMERIC NOT NULL CHECK (total_price >= 0),
	fid SERIAL NOT NULL,
	ocid SERIAL NOT NULL,
	FOREIGN KEY (fid) REFERENCES Food(fid),
	FOREIGN KEY (ocid) REFERENCES Order_List(ocid)
);

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
	pisPercentage BOOLEAN NOT NULL,
	pdatetime_active_from TIMESTAMP NOT NULL,
	pdatetime_active_to TIMESTAMP NOT NULL CHECK (pdatetime_active_to > pdatetime_active_from),
	pminSpend NUMERIC NOT NULL CHECK (pminSpend >= 0),
	pdiscount_val NUMERIC NOT NULL,
	pname TEXT NOT NULL,
	pdescription TEXT NOT NULL
);

CREATE TABLE Coupon (
	cid NOT NULL,
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
	pid NOT NULL PRIMARY KEY,
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
	rid SERIAL NOT NULL PRIMARY KEY,
	week_no INTEGER NOT NULL,
	salary NUMERIC NOT NULL,
	base_salary NUMERIC NOT NULL,
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
	rid SERIAL NOT NULL PRIMARY KEY,
	month_no INTEGER NOT NULL,
	salary NUMERIC NOT NULL,
	base_salary NUMERIC NOT NULL,
	FOREIGN KEY (rid) REFERENCES Full_Timer ON DELETE CASCADE
);

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
    SET wks = wks + 1;
    WHERE rid = NEW.rid

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
   
   END IF;
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