/* 5 RIDERS PER HOUR */

CREATE TABLE Current_Schedule (
    csid SERIAL NOT NULL PRIMARY KEY,
    rid INT NOT NULL,
    scid INT NOT NULL,
    curr_wk INT NOT NULL DEFAULT 0,
    curr_mth INT NOT NULL DEFAULT 0,
    FOREIGN KEY (rid) REFERENCES Rider ON DELETE CASCADE, 
    FOREIGN KEY (rid) REFERENCES Schedule_Count, 
);

CREATE TABLE Schedule_Count (
  scid SERIAL NOT NULL PRIMARY KEY,
  start_time INT UNIQUE NOT NULL,
  wkday INT UNIQUE NOT NULL,
  shift INT NOT NULL,
  num_avail INT NOT NULL,
  CHECK (-1 < shift <= 4),
  CHECK  (num_avail > 5)
);


UPDATE Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '') SET num_avail = num_avail + 1;

UPDATE Schedule_Count WHERE shift = 1 SET num_avail = num_avail + 1;

UPDATE Schedule_Count WHERE scid IN SELECT scid FROM Current_Schedule WHERE rid = 'rid'
SET num_avail = num_avail - 1;

DELETE FROM Current_Schedule WHERE rid = 'rid';

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 'rid', (SELECT scid FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP ''), 
wks FROM Part_Timer WHERE rid = 'rid';

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 'rid', (SELECT scid FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP ''), 
mth FROM Full_Timer WHERE rid = 'rid';



/* SALARY TRIGGER */

CREATE OR REPLACE FUNCTION update_salary()
  RETURNS trigger AS

$BODY$
DECLARE rider INT
BEGIN
    SELECT rid INTO rider FROM make_order 
    WHERE oicd = NEW.ocid;

    IF NEW.oorder_arrives_customer IS NOT NULL AND rider IN Part_Timer THEN

    UPDATE Weekly_Past_Salaries 
    WHERE week_no = (SELECT curr_wk FROM Current_Schedule WHERE rid = rider)
    AND rid = rider
    SET salary = salary + NEW.odelivery_fee;

    ELSEIF  NEW.oorder_arrives_customer IS NOT NULL AND rider IN Full_Timer THEN

    UPDATE Monthly_Past_Salaries
    WHERE month_no = (SELECT curr_mth FROM Current_Schedule WHERE rid = rider)
    AND rid = rider
    SET salary = salary + NEW.odelivery_fee;


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
