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
    FOREIGN KEY (scid) REFERENCES Schedule_Count
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


UPDATE Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-25 18:00:25-07') 
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-25 18:00:25-07') SET num_avail = num_avail + 1;

UPDATE Schedule_Count WHERE shift = 'SHIFT'
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-25 18:00:25-07') SET num_avail = num_avail + 1;


DELETE FROM Current_Schedule WHERE rid = 1;

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 2, scid, 
(SELECT wks FROM Part_Timer WHERE rid = 2)
FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-25 18:00:25-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-25 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 1, scid, 
(SELECT mth FROM Full_Timer WHERE rid = 1) 
FROM Schedule_Count WHERE shift = 'shift' 
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-25 18:00:25-07'); 



/* SALARY TRIGGER to update mthly/wkly salary after each delivery */

CREATE OR REPLACE FUNCTION update_order_salary()
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

DROP TRIGGER IF EXISTS update_order_salary ON Order_List;
CREATE TRIGGER update_order_salary
  AFTER UPDATE
  ON Order_List
  FOR EACH ROW
  EXECUTE PROCEDURE update_order_salary();

/* SALARY TRIGGER to update mthly salary after full time base salary change */

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

/* SALARY TRIGGER to update mthly/wkly salary after part time base salary change */

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


update Full_Timer set base_salary = 1500, mth =1 WHERE rid = 1;
select * from rider;  
select * from Full_Timer;
select * from Part_Timer;
update Part_Timer set base_salary = 250 WHERE rid = 15;  
select * from rider where rid = 2;  
insert into Order_List (oorder_arrives_customer, odelivery_fee, ofinal_price) VALUES(CURRENT_TIMESTAMP,33,90)