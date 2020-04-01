/* PART-TIME RIDERS */ 

/* Add new part-time rider + update part_timer table */
 WITH ins1 AS 
 (INSERT INTO  Rider (rname, rusername, rpassword, rtotal_salary) 
  VALUES ('a', 'b', 'c', 999)
  RETURNING rid AS T_RID)
  INSERT INTO Part_Timer (rid, base_salary, wks)
  SELECT T_RID, 33, 0 FROM ins1;

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
    UPDATE Part_Timer WHERE rid = NEW.rid
    SET wks = wks + 1;

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


/* PART-TIME RIDER SCHEDULING TEST CASE COMMANDS */

SELECT * FROM Schedule_PT_Hours

DELETE FROM Schedule_PT_Hours

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(1, 1, EXTRACT(DOW FROM TIMESTAMP '2016-06-22 16:00:25-07'), '2016-06-22 16:00:25-07',
      '2016-06-22 18:00:25-07', False);

/* EXPECTED RESULT: ONLY 1 ROW IN TABLE WITH START-TIME 16:00 AND END TIME 20:00 */
INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(1, 1, EXTRACT(DOW FROM TIMESTAMP '2016-06-22 16:00:25-07'), '2016-06-22 18:00:25-07',
      '2016-06-22 20:00:25-07', False);

/* EXPECTED RESULT: ERROR ABOUT WORKING TOO LONG */
INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(1, EXTRACT(DOW FROM TIMESTAMP '2016-06-22 16:00:25-07'), '2016-06-22 20:00:25-07',
      '2016-06-22 21:00:25-07', False);

/* EXPECTED RESULT: WARNING ABOUT NOT ENOUGH TOTAL HOURS AND DELETE PREVIOUS INSERTIONS FOR SAME WK/RIDER*/
INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(1, EXTRACT(DOW FROM TIMESTAMP '2016-06-22 16:00:25-07'), '2016-06-27 20:00:25-07',
      '2016-06-27 21:00:25-07', True);
