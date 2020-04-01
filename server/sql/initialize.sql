/* Modify DDL to new changes */

ALTER TABLE Full_Timer ADD COLUMN mth INT;
ALTER TABLE Part_Timer ADD COLUMN wks INT;

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
  start_time INT UNIQUE NOT NULL,
  wkday INT UNIQUE NOT NULL,
  shift INT NOT NULL,
  num_avail INT NOT NULL,
  CHECK (-1 < shift AND shift < 5),
  CHECK (num_avail > 5)
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

/* DDL CHANGE COMPLETE */

/* SAMPLE DATA GENERATION */

/* 20 SAMPLE RIDERS */
BEGIN;
 /* INIT FULL TIME RIDERS */
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

/* INIT PART-TIME RIDERS */

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

COMMIT;

/* RIDER SAMPLE CREATED */

/* POPULATE SCHEDULE_COUNT TABLE incomplete

INSERT INTO Schedule_Count (start_time, wkday, num_avail)
VALUES (10,0,5),
(11,0,5),
(12,0,5),
(13,0,5),
(14,0,5),
(15,0,5),
(16,0,5),
(17,0,5),
(18,0,5),
(19,0,5),
(20,0,5),
(21,0,5),
(22,0,5),
(10,1,5),
(11,1,5),
(12,1,5),
(13,1,5),
(14,1,5),
(15,1,5),
(16,1,5),
(17,1,5),
(18,1,5),
(19,1,5),
(20,1,5),
(21,1,5),
(22,1,5),
(10,2,5),
(11,2,5),
(12,2,5),
(13,2,5),
(14,2,5),
(15,2,5),
(16,2,5),
(17,2,5),
(18,2,5),
(19,2,5),
(20,2,5),
(21,2,5),
(22,2,5),
(10,3,5),
(11,3,5),
(12,3,5),
(13,3,5),
(14,3,5),
(15,3,5),
(16,3,5),
(17,3,5),
(18,3,5),
(19,3,5),
(20,3,5),
(21,3,5),
(22,3,5),
(10,4,5),
(11,4,5),
(12,4,5),
(13,4,5),
(14,4,5),
(15,4,5),
(16,4,5),
(17,4,5),
(18,4,5),
(19,4,5),
(20,4,5),
(21,4,5),
(22,4,5),
(10,4,5),
(11,4,5),
(12,4,5),
(13,4,5),
(14,4,5),
(15,4,5),
(16,4,5),
(17,4,5),
(18,4,5),
(19,4,5),
(20,4,5),
(21,4,5),
(22,4,5),
(10,5,5),
(11,5,5),
(12,5,5),
(13,5,5),
(14,5,5),
(15,5,5),
(16,5,5),
(17,5,5),
(18,5,5),
(19,5,5),
(20,5,5),
(21,5,5),
(22,5,5),
(10,6,5),
(11,6,5),
(12,6,5),
(13,6,5),
(14,6,5),
(15,6,5),
(16,6,5),
(17,6,5),
(18,6,5),
(19,6,5),
(20,6,5),
(21,6,5),
(22,6,5);
 */


