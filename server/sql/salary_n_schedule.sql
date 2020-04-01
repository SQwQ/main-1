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


UPDATE Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-25 18:00:25-07') 
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-25 18:00:25-07') SET num_avail = num_avail + 1;

UPDATE Schedule_Count WHERE shift = 'SHIFT'
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-25 18:00:25-07') SET num_avail = num_avail + 1;


DELETE FROM Current_Schedule WHERE rid = 1;

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 2, (SELECT scid FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-25 18:00:25-07'), 
wks FROM Part_Timer WHERE rid = 2;

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 1, (SELECT scid FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-25 18:00:25-07'), 
mth FROM Full_Timer WHERE rid = 1;



/* SALARY TRIGGER */

CREATE OR REPLACE FUNCTION update_salary()
  RETURNS trigger AS

$BODY$
DECLARE rider INT;
BEGIN
    SELECT rid INTO rider FROM make_order 
    WHERE oicd = NEW.ocid;

    IF NEW.oorder_arrives_customer IS NOT NULL AND rider IN 
	  (SELECT rid FROM Part_Timer) THEN

    UPDATE Weekly_Past_Salaries 
	  SET salary = salary + NEW.odelivery_fee
    WHERE week_no = (SELECT curr_wk FROM Current_Schedule WHERE rid = rider)
    AND rid = rider;

    ELSEIF  NEW.oorder_arrives_customer IS NOT NULL AND rider IN 
	  (SELECT rid FROM Full_Timer) THEN

    UPDATE Monthly_Past_Salaries
	  SET salary = salary + NEW.odelivery_fee
    WHERE month_no = (SELECT curr_mth FROM Current_Schedule WHERE rid = rider)
    AND rid = rider;

    END IF;

    RETURN NULL;

END;
$BODY$
LANGUAGE plpgsql ;

DROP TRIGGER IF EXISTS update_salary ON Order_List;
CREATE TRIGGER update_salary
  AFTER UPDATE
  ON Order_List
  FOR EACH ROW
  EXECUTE PROCEDURE update_salary();