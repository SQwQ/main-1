/*add new part-time rider + update part_timer table*/
 WITH ins1 AS 
 (INSERT INTO  Rider (rname, rusername, rpassword, rtotal_salary) 
  VALUES ('a', 'b', 'c', 999)
  RETURNING rid AS T_RID)
  INSERT INTO Part_Timer (rid, base_salary)
  SELECT T_RID, 33 FROM ins1;

/*add new full-time rider + update part_timer table*/
 WITH ins1 AS 
 (INSERT INTO  Rider (rname, rusername, rpassword, rtotal_salary) 
  VALUES ('a', 'bb', 'c', 999)
  RETURNING rid AS T_RID)
  INSERT INTO Full_Timer (rid, base_salary)
  SELECT T_RID, 45 FROM ins1;

CREATE TABLE Schedule_PT_Hours (
    sdid SERIAL NOT NULL PRIMARY KEY,
    rid SERIAL NOT NULL,
    wkday INT NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    FOREIGN KEY (rid) REFERENCES Part_Timer,
    CHECK (end_time - start_time <= INTERVAL '4 hours')
);

/*scheduling*/
CREATE TABLE Schedule_FT_Hours (
    sdid SERIAL NOT NULL PRIMARY KEY,
    rid SERIAL NOT NULL,
    wkday INT NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    FOREIGN KEY (rid) REFERENCES Full_Timer,
    CHECK (end_time - start_time <= INTERVAL '4 hours'),
    CHECK (EXTRACT(HOUR FROM start_time) = 10 AND EXTRACT(HOUR FROM end_time) = 14 
     OR EXTRACT(HOUR FROM start_time) = 11 AND EXTRACT(HOUR FROM end_time) = 3)  
);

CREATE TABLE Schedule_Days (
    did SERIAL NOT NULL PRIMARY KEY,
    rid SERIAL NOT NULL,
    wkday INT NOT NULL,
    hrs INT NOT NULL,
    FOREIGN KEY (rid) REFERENCES Riders
);


INSERT INTO Schedule_Hours(rid, wkday, start_time, end_time)
VALUES('rid', EXTRACT(DOW FROM TIMESTAMP '2016-06-22 16:00:25-07'), '2016-06-22 16:00:25-07',
      '2016-06-22 18:00:25-07');
INSERT INTO Schedule_Days(rid, wkday, hrs)
VALUES('rid', EXTRACT(DOW FROM TIMESTAMP '2016-06-22 16:00:25-07'),
EXTRACT(HOUR FROM TIMESTAMP ('2016-06-22 18:00:25-07' - '2016-06-22 16:00:25-07')))

CREATE OR REPLACE FUNCTION merge_continuous_rows()
  RETURNS trigger AS
$BODY$
BEGIN
   IF NEW.start_time <> OLD.end_time AND NEW.rid <> OLD.rid THEN
       UPDATE Schedule_Hours
       SET OLD.end_time = NEW.end_time;
       DELETE FROM Schedule_Hours
       WHERE start_time = NEW.start_time 
       AND rid = NEW.rid;
  
   END IF;
   RETURN NEW;
END;
$BODY$

CREATE TRIGGER merge_new_schedule
  BEFORE INSERT
  ON Schedule_Hours
  FOR EACH ROW
  EXECUTE PROCEDURE merge_continuous_rows();
