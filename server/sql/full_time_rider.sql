/* FULL-TIME RIDERS */

/*add new full-time rider + update Full_Timer table*/
 WITH ins1 AS 
 (INSERT INTO  Rider (rname, rusername, rpassword, rtotal_salary) 
  VALUES ('a', 'bb', 'c', 999)
  RETURNING rid AS T_RID)
  INSERT INTO Full_Timer (rid, base_salary, mth)
  SELECT T_RID, 45, 0 FROM ins1;

CREATE TABLE Schedule_FT_Hours (
    sfid SERIAL NOT NULL PRIMARY KEY,
    rid SERIAL NOT NULL,
    wkdate TIMESTAMP NOT NULL,
    is_prev BOOLEAN NOT NULL,
    is_last_shift BOOLEAN NOT NULL,
    shift INT NOT NULL,
    FOREIGN KEY (rid) REFERENCES Full_Timer, 
    CHECK (0 < shift <= 4)
);

/* Trigger to ensure 5-consecutive day work week
 * NEED DATES TO BE IN ORDER FROM EARLIEST TO LATEST */

CREATE OR REPLACE FUNCTION check_consecutive()
  RETURNS trigger AS

$BODY$
DECLARE prev_date TIMESTAMP
DECLARE id INT
BEGIN
    SELECT sfid, wkdate INTO id, prev_date FROM Schedule_FT_Hours 
    WHERE is_prev = True;

    IF NEW.wkdate - prev_date > INTERVAL '1 days' THEN
    RAISE EXCEPTION USING MESSAGE = 'WORK DAYS MUST BE CONSECUTIVE';

    ELSEIF NEW.wkdate - prev_date <= INTERVAL '1 days' THEN
    UPDATE Schedule_FT_Hours WHERE sfid = id
    SET is_prev = False

    END IF;
    RETURN NULL;

END;
$BODY$
LANGUAGE plpgsql ;

DROP TRIGGER IF EXISTS check_consecutive ON Schedule_FT_Hours;
CREATE TRIGGER check_consecutive
  AFTER INSERT
  ON Schedule_FT_Hours
  FOR EACH ROW
  EXECUTE PROCEDURE check_consecutive();

/* Trigger to ensure 5 day work week */

CREATE OR REPLACE FUNCTION check_day_num()
  RETURNS trigger AS
$BODY$
DECLARE total_days INT;
BEGIN
    SELECT SUM(sfid) INTO total_days FROM Schedule_FT_Hours 
    WHERE rid = NEW.rid AND NEW.mth = mth;

    IF NEW.is_last_shift = True AND 
    (total_days != 5) THEN
    DELETE FROM Schedule_FT_Hours 
    WHERE rid = NEW.rid AND NEW.wkdate - wkdate <= INTERVAL '7 days';

    RAISE WARNING USING MESSAGE = 'You can only work 5 days a week!';

    ELSEIF NEW.is_last_shift = True THEN
    UPDATE Full_Timer WHERE rid = NEW.rid
    SET mth = mth + 1;

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


/* TESTING FULL-TIME RIDERS SCHEDULING */

SELECT * FROM Schedule_FT_Hours

DELETE FROM Schedule_FT_Hours

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, shift)
VALUES(2, '2016-06-22 18:00:25-07', True, 1);