/* FULL-TIME RIDERS */

/*add new full-time rider + update Full_Timer table*/
 WITH ins1 AS
 (INSERT INTO  Rider (rname, rusername, rpassword, rtotal_salary)
  VALUES ('a', 'bb', 'c', 999)
  RETURNING rid AS T_RID)
  INSERT INTO Full_Timer (rid, base_salary, mth)
  SELECT T_RID, 45, 0 FROM ins1;

/* TESTING FULL-TIME RIDERS SCHEDULING */

SELECT * FROM Schedule_FT_Hours

DELETE FROM Schedule_FT_Hours

/* Not consecutive days */
BEGIN;

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(1, '2016-06-25 18:00:25-07', True, False, 2);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(1, '2016-06-27 18:00:25-07', True, False, 2);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(1, '2016-06-22 18:00:25-07', True, False, 1);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(1, '2016-06-23 18:00:25-07', True, False, 2);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(1, '2016-06-26 18:00:25-07', True, True, 2);

COMMIT;

/* Success without warning */
BEGIN;

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(5, '2016-06-25 18:00:25-07', True, False, 2);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(5, '2016-06-27 23:59:25-07', True, False, 2);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(5, '2016-06-24 18:00:25-07', True, False, 1);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(5, '2016-06-23 00:00:25-07', True, False, 2);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(5, '2016-06-26 18:00:25-07', True, True, 2);

COMMIT;

/* More than 5 days */
BEGIN;

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(1, '2016-06-25 18:00:25-07', True, False, 2);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(1, '2016-06-27 23:59:25-07', True, False, 2);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(1, '2016-06-24 18:00:25-07', True, False, 1);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(1, '2016-06-23 00:00:25-07', True, False, 2);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(1, '2016-06-22 00:00:25-07', True, False, 2);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(1, '2016-06-21 00:00:25-07', True, False, 2);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(1, '2016-06-26 18:00:25-07', True, True, 2);

COMMIT;


/* Full time schedule DDL changes */
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
