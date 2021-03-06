/* DDL CHANGE */

DROP SCHEMA public CASCADE;
CREATE SCHEMA public;

/* Run updated DDL */

/* BASE RIDER DATA GENERATION */

/* The SQL chunk below initializes the db with 22 riders (12 FT 10 PT)
and their respective scheduling tables and current_schedule/schedule_count such that
the constraint of at least 5 delivery guy per hour is met along with all other rider constraints.

Please run this before testing any routes on work schedule if the desired behavior of
at least 5 delivery guy per hour is being tested. */

/* 22 SAMPLE RIDERS */
BEGIN;
DELETE FROM rider;
ALTER SEQUENCE rider_rid_seq RESTART WITH 1;
 /* INIT FULL TIME RIDERS x 12*/
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

/* INIT PART-TIME RIDERS x 10 */

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

WITH ins1 AS
 (INSERT INTO  Rider (rname, rusername, rpassword, rtotal_salary)
  VALUES ('Addda', 'un21', 'pw21', 50)
  RETURNING rid AS T_RID)
  INSERT INTO Part_Timer (rid, base_salary, wks)
  SELECT T_RID, 50, 0 FROM ins1;


WITH ins1 AS
 (INSERT INTO  Rider (rname, rusername, rpassword, rtotal_salary)
  VALUES ('Addaa', 'un22', 'pw22', 50)
  RETURNING rid AS T_RID)
  INSERT INTO Part_Timer (rid, base_salary, wks)
  SELECT T_RID, 50, 0 FROM ins1;


COMMIT;

/* RIDER SAMPLE CREATED */

/* Populate Schedule Count */
INSERT INTO Schedule_Count (start_time, wkday, shift, num_avail)
VALUES
(10,1,1,5),
(11,1,1,5),
(11,1,2,5),
(12,1,1,5),
(12,1,2,5),
(12,1,3,5),
(13,1,1,5),
(13,1,2,5),
(13,1,3,5),
(13,1,4,5),
(14,1,2,5),
(14,1,3,5),
(14,1,4,5),
(15,1,1,5),
(15,1,3,5),
(15,1,4,5),
(16,1,1,5),
(16,1,2,5),
(16,1,4,5),
(17,1,1,5),
(17,1,2,5),
(17,1,3,5),
(18,1,1,5),
(18,1,2,5),
(18,1,3,5),
(18,1,4,5),
(19,1,2,5),
(19,1,3,5),
(19,1,4,5),
(20,1,3,5),
(20,1,4,5),
(21,1,4,5),
(10,2,1,5),
(11,2,1,5),
(11,2,2,5),
(12,2,1,5),
(12,2,2,5),
(12,2,3,5),
(13,2,1,5),
(13,2,2,5),
(13,2,3,5),
(13,2,4,5),
(14,2,2,5),
(14,2,3,5),
(14,2,4,5),
(15,2,1,5),
(15,2,3,5),
(15,2,4,5),
(16,2,1,5),
(16,2,2,5),
(16,2,4,5),
(17,2,1,5),
(17,2,2,5),
(17,2,3,5),
(18,2,1,5),
(18,2,2,5),
(18,2,3,5),
(18,2,4,5),
(19,2,2,5),
(19,2,3,5),
(19,2,4,5),
(20,2,3,5),
(20,2,4,5),
(21,2,4,5),
(10,3,1,5),
(11,3,1,5),
(11,3,2,5),
(12,3,1,5),
(12,3,2,5),
(12,3,3,5),
(13,3,1,5),
(13,3,2,5),
(13,3,3,5),
(13,3,4,5),
(14,3,2,5),
(14,3,3,5),
(14,3,4,5),
(15,3,1,5),
(15,3,3,5),
(15,3,4,5),
(16,3,1,5),
(16,3,2,5),
(16,3,4,5),
(17,3,1,5),
(17,3,2,5),
(17,3,3,5),
(18,3,1,5),
(18,3,2,5),
(18,3,3,5),
(18,3,4,5),
(19,3,2,5),
(19,3,3,5),
(19,3,4,5),
(20,3,3,5),
(20,3,4,5),
(21,3,4,5),
(10,4,1,5),
(11,4,1,5),
(11,4,2,5),
(12,4,1,5),
(12,4,2,5),
(12,4,3,5),
(13,4,1,5),
(13,4,2,5),
(13,4,3,5),
(13,4,4,5),
(14,4,2,5),
(14,4,3,5),
(14,4,4,5),
(15,4,1,5),
(15,4,3,5),
(15,4,4,5),
(16,4,1,5),
(16,4,2,5),
(16,4,4,5),
(17,4,1,5),
(17,4,2,5),
(17,4,3,5),
(18,4,1,5),
(18,4,2,5),
(18,4,3,5),
(18,4,4,5),
(19,4,2,5),
(19,4,3,5),
(19,4,4,5),
(20,4,3,5),
(20,4,4,5),
(21,4,4,5),
(10,5,1,5),
(11,5,1,5),
(11,5,2,5),
(12,5,1,5),
(12,5,2,5),
(12,5,3,5),
(13,5,1,5),
(13,5,2,5),
(13,5,3,5),
(13,5,4,5),
(14,5,2,5),
(14,5,3,5),
(14,5,4,5),
(15,5,1,5),
(15,5,3,5),
(15,5,4,5),
(16,5,1,5),
(16,5,2,5),
(16,5,4,5),
(17,5,1,5),
(17,5,2,5),
(17,5,3,5),
(18,5,1,5),
(18,5,2,5),
(18,5,3,5),
(18,5,4,5),
(19,5,2,5),
(19,5,3,5),
(19,5,4,5),
(20,5,3,5),
(20,5,4,5),
(21,5,4,5),
(10,6,1,5),
(11,6,1,5),
(11,6,2,5),
(12,6,1,5),
(12,6,2,5),
(12,6,3,5),
(13,6,1,5),
(13,6,2,5),
(13,6,3,5),
(13,6,4,5),
(14,6,2,5),
(14,6,3,5),
(14,6,4,5),
(15,6,1,5),
(15,6,3,5),
(15,6,4,5),
(16,6,1,5),
(16,6,2,5),
(16,6,4,5),
(17,6,1,5),
(17,6,2,5),
(17,6,3,5),
(18,6,1,5),
(18,6,2,5),
(18,6,3,5),
(18,6,4,5),
(19,6,2,5),
(19,6,3,5),
(19,6,4,5),
(20,6,3,5),
(20,6,4,5),
(21,6,4,5),
(10,7,1,5),
(11,7,1,5),
(11,7,2,5),
(12,7,1,5),
(12,7,2,5),
(12,7,3,5),
(13,7,1,5),
(13,7,2,5),
(13,7,3,5),
(13,7,4,5),
(14,7,2,5),
(14,7,3,5),
(14,7,4,5),
(15,7,1,5),
(15,7,3,5),
(15,7,4,5),
(16,7,1,5),
(16,7,2,5),
(16,7,4,5),
(17,7,1,5),
(17,7,2,5),
(17,7,3,5),
(18,7,1,5),
(18,7,2,5),
(18,7,3,5),
(18,7,4,5),
(19,7,2,5),
(19,7,3,5),
(19,7,4,5),
(20,7,3,5),
(20,7,4,5),
(21,7,4,5)

/* Populate Schedules for each rider*/
BEGIN;
/*Rider 1*/
INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(1, '2016-06-25 18:00:25-07', True, False, 1);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(1, '2016-06-27 23:59:25-07', True, False, 1);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(1, '2016-06-24 18:00:25-07', True, False, 1);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(1, '2016-06-23 00:00:25-07', True, False, 1);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(1, '2016-06-26 18:00:25-07', True, True, 1);

/* Update Rider 1's current schedule */
INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 1, scid,
(SELECT mth FROM Full_Timer WHERE rid = 1) FROM Schedule_Count WHERE shift = 1
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-23 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 1, scid,
(SELECT mth FROM Full_Timer WHERE rid = 1) FROM Schedule_Count WHERE shift = 1
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-24 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 1, scid,
(SELECT mth FROM Full_Timer WHERE rid = 1) FROM Schedule_Count WHERE shift = 1
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-25 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 1, scid,
(SELECT mth FROM Full_Timer WHERE rid = 1) FROM Schedule_Count WHERE shift = 1
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-26 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 1, scid,
(SELECT mth FROM Full_Timer WHERE rid = 1) FROM Schedule_Count WHERE shift = 1
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-27 18:00:25-07');

/*Rider 2*/
INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(2, '2016-06-25 18:00:25-07', True, False, 1);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(2, '2016-06-27 23:59:25-07', True, False, 1);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(2, '2016-06-24 18:00:25-07', True, False, 1);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(2, '2016-06-23 00:00:25-07', True, False, 1);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(2, '2016-06-26 18:00:25-07', True, True, 1);

/* Update Rider 2's current schedule */
INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 2, scid,
(SELECT mth FROM Full_Timer WHERE rid = 2) FROM Schedule_Count WHERE shift = 1
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-23 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 2, scid,
(SELECT mth FROM Full_Timer WHERE rid = 2) FROM Schedule_Count WHERE shift = 1
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-24 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 2, scid,
(SELECT mth FROM Full_Timer WHERE rid = 2) FROM Schedule_Count WHERE shift = 1
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-25 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 2, scid,
(SELECT mth FROM Full_Timer WHERE rid = 2) FROM Schedule_Count WHERE shift = 1
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-26 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 2, scid,
(SELECT mth FROM Full_Timer WHERE rid = 2) FROM Schedule_Count WHERE shift = 1
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-27 18:00:25-07');

/*Rider 3*/
INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(3, '2016-06-25 18:00:25-07', True, False, 1);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(3, '2016-06-27 23:59:25-07', True, False, 1);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(3, '2016-06-24 18:00:25-07', True, False, 1);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(3, '2016-06-23 00:00:25-07', True, False, 1);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(3, '2016-06-26 18:00:25-07', True, True, 1);

/* Update Rider 3's current schedule */
INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 3, scid,
(SELECT mth FROM Full_Timer WHERE rid = 3) FROM Schedule_Count WHERE shift = 1
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-23 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 3, scid,
(SELECT mth FROM Full_Timer WHERE rid = 3) FROM Schedule_Count WHERE shift = 1
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-24 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 3, scid,
(SELECT mth FROM Full_Timer WHERE rid = 3) FROM Schedule_Count WHERE shift = 1
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-25 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 3, scid,
(SELECT mth FROM Full_Timer WHERE rid = 3) FROM Schedule_Count WHERE shift = 1
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-26 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 3, scid,
(SELECT mth FROM Full_Timer WHERE rid = 3) FROM Schedule_Count WHERE shift = 1
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-27 18:00:25-07');

/*Rider 4*/
INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(4, '2016-06-25 18:00:25-07', True, False, 2);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(4, '2016-06-27 23:59:25-07', True, False, 2);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(4, '2016-06-24 18:00:25-07', True, False, 2);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(4, '2016-06-23 00:00:25-07', True, False, 2);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(4, '2016-06-26 18:00:25-07', True, True, 2);

/* Update Rider 4's current schedule */
INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 4, scid,
(SELECT mth FROM Full_Timer WHERE rid = 4) FROM Schedule_Count WHERE shift = 2
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-23 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 4, scid,
(SELECT mth FROM Full_Timer WHERE rid = 4) FROM Schedule_Count WHERE shift = 2
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-24 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 4, scid,
(SELECT mth FROM Full_Timer WHERE rid = 4) FROM Schedule_Count WHERE shift = 2
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-25 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 4, scid,
(SELECT mth FROM Full_Timer WHERE rid = 4) FROM Schedule_Count WHERE shift = 2
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-26 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 4, scid,
(SELECT mth FROM Full_Timer WHERE rid = 4) FROM Schedule_Count WHERE shift = 2
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-27 18:00:25-07');

/*Rider 5*/
INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(5, '2016-06-25 18:00:25-07', True, False, 2);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(5, '2016-06-27 23:59:25-07', True, False, 2);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(5, '2016-06-24 18:00:25-07', True, False, 2);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(5, '2016-06-23 00:00:25-07', True, False, 2);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(5, '2016-06-26 18:00:25-07', True, True, 2);

/* Update Rider 5's current schedule */
INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 5, scid,
(SELECT mth FROM Full_Timer WHERE rid = 5) FROM Schedule_Count WHERE shift = 2
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-23 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 5, scid,
(SELECT mth FROM Full_Timer WHERE rid = 5) FROM Schedule_Count WHERE shift = 2
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-24 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 5, scid,
(SELECT mth FROM Full_Timer WHERE rid = 5) FROM Schedule_Count WHERE shift = 2
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-25 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 5, scid,
(SELECT mth FROM Full_Timer WHERE rid = 5) FROM Schedule_Count WHERE shift = 2
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-26 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 5, scid,
(SELECT mth FROM Full_Timer WHERE rid = 5) FROM Schedule_Count WHERE shift = 2
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-27 18:00:25-07');

/*Rider 6*/
INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(6, '2016-06-25 18:00:25-07', True, False, 2);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(6, '2016-06-27 23:59:25-07', True, False, 2);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(6, '2016-06-24 18:00:25-07', True, False, 2);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(6, '2016-06-23 00:00:25-07', True, False, 2);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(6, '2016-06-26 18:00:25-07', True, True, 2);

/* Update Rider 6's current schedule */
INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 6, scid,
(SELECT mth FROM Full_Timer WHERE rid = 6) FROM Schedule_Count WHERE shift = 2
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-23 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 6, scid,
(SELECT mth FROM Full_Timer WHERE rid = 6) FROM Schedule_Count WHERE shift = 2
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-24 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 6, scid,
(SELECT mth FROM Full_Timer WHERE rid = 6) FROM Schedule_Count WHERE shift = 2
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-25 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 6, scid,
(SELECT mth FROM Full_Timer WHERE rid = 6) FROM Schedule_Count WHERE shift = 2
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-26 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 6, scid,
(SELECT mth FROM Full_Timer WHERE rid = 6) FROM Schedule_Count WHERE shift = 2
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-27 18:00:25-07');

/*Rider 7*/
INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(7, '2016-06-25 18:00:25-07', True, False, 3);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(7, '2016-06-27 23:59:25-07', True, False, 3);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(7, '2016-06-24 18:00:25-07', True, False, 3);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(7, '2016-06-23 00:00:25-07', True, False, 3);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(7, '2016-06-26 18:00:25-07', True, True, 3);

/* Update Rider 7's current schedule */
INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 7, scid,
(SELECT mth FROM Full_Timer WHERE rid = 7) FROM Schedule_Count WHERE shift = 3
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-23 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 7, scid,
(SELECT mth FROM Full_Timer WHERE rid = 7) FROM Schedule_Count WHERE shift = 3
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-24 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 7, scid,
(SELECT mth FROM Full_Timer WHERE rid = 7) FROM Schedule_Count WHERE shift = 3
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-25 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 7, scid,
(SELECT mth FROM Full_Timer WHERE rid = 7) FROM Schedule_Count WHERE shift = 3
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-26 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 7, scid,
(SELECT mth FROM Full_Timer WHERE rid = 7) FROM Schedule_Count WHERE shift = 3
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-27 18:00:25-07');


/*Rider 8*/
INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(8, '2016-06-25 18:00:25-07', True, False, 3);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(8, '2016-06-27 23:59:25-07', True, False, 3);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(8, '2016-06-24 18:00:25-07', True, False, 3);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(8, '2016-06-23 00:00:25-07', True, False, 3);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(8, '2016-06-26 18:00:25-07', True, True, 3);

/* Update Rider 8's current schedule */
INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 8, scid,
(SELECT mth FROM Full_Timer WHERE rid = 8) FROM Schedule_Count WHERE shift = 3
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-23 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 8, scid,
(SELECT mth FROM Full_Timer WHERE rid = 8) FROM Schedule_Count WHERE shift = 3
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-24 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 8, scid,
(SELECT mth FROM Full_Timer WHERE rid = 8) FROM Schedule_Count WHERE shift = 3
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-25 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 8, scid,
(SELECT mth FROM Full_Timer WHERE rid = 8) FROM Schedule_Count WHERE shift = 3
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-26 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 8, scid,
(SELECT mth FROM Full_Timer WHERE rid = 8) FROM Schedule_Count WHERE shift = 3
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-27 18:00:25-07');



/*Rider 9*/
INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(9, '2016-06-25 18:00:25-07', True, False, 3);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(9, '2016-06-27 23:59:25-07', True, False, 3);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(9, '2016-06-24 18:00:25-07', True, False, 3);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(9, '2016-06-23 00:00:25-07', True, False, 3);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(9, '2016-06-26 18:00:25-07', True, True, 3);

/* Update Rider 9's current schedule */
INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 9, scid,
(SELECT mth FROM Full_Timer WHERE rid = 9) FROM Schedule_Count WHERE shift = 3
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-23 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 9, scid,
(SELECT mth FROM Full_Timer WHERE rid = 9) FROM Schedule_Count WHERE shift = 3
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-24 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 9, scid,
(SELECT mth FROM Full_Timer WHERE rid = 9) FROM Schedule_Count WHERE shift = 3
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-25 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 9, scid,
(SELECT mth FROM Full_Timer WHERE rid = 9) FROM Schedule_Count WHERE shift = 3
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-26 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 9, scid,
(SELECT mth FROM Full_Timer WHERE rid = 9) FROM Schedule_Count WHERE shift = 3
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-27 18:00:25-07');

/*Rider 10*/
INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(10, '2016-06-25 18:00:25-07', True, False, 4);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(10, '2016-06-27 23:59:25-07', True, False, 4);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(10, '2016-06-24 18:00:25-07', True, False, 4);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(10, '2016-06-23 00:00:25-07', True, False, 4);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(10, '2016-06-26 18:00:25-07', True, True, 4);


/* Update Rider 10's current schedule */
INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 10, scid,
(SELECT mth FROM Full_Timer WHERE rid = 10) FROM Schedule_Count WHERE shift = 4
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-23 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 10, scid,
(SELECT mth FROM Full_Timer WHERE rid = 10) FROM Schedule_Count WHERE shift = 4
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-24 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 10, scid,
(SELECT mth FROM Full_Timer WHERE rid = 10) FROM Schedule_Count WHERE shift = 4
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-25 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 10, scid,
(SELECT mth FROM Full_Timer WHERE rid = 10) FROM Schedule_Count WHERE shift = 4
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-26 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 10, scid,
(SELECT mth FROM Full_Timer WHERE rid = 10) FROM Schedule_Count WHERE shift = 4
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-27 18:00:25-07');

/*Rider 11*/
INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(11, '2016-06-25 18:00:25-07', True, False, 4);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(11, '2016-06-27 23:59:25-07', True, False, 4);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(11, '2016-06-24 18:00:25-07', True, False, 4);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(11, '2016-06-23 00:00:25-07', True, False, 4);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(11, '2016-06-26 18:00:25-07', True, True, 4);

/* Update Rider 11's current schedule */
INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 11, scid,
(SELECT mth FROM Full_Timer WHERE rid = 11) FROM Schedule_Count WHERE shift = 4
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-23 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 11, scid,
(SELECT mth FROM Full_Timer WHERE rid = 11) FROM Schedule_Count WHERE shift = 4
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-24 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 11, scid,
(SELECT mth FROM Full_Timer WHERE rid = 11) FROM Schedule_Count WHERE shift = 4
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-25 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 11, scid,
(SELECT mth FROM Full_Timer WHERE rid = 11) FROM Schedule_Count WHERE shift = 4
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-26 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 11, scid,
(SELECT mth FROM Full_Timer WHERE rid = 11) FROM Schedule_Count WHERE shift = 4
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-27 18:00:25-07');

/*Rider 12*/
INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(12, '2016-06-25 18:00:25-07', True, False, 4);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(12, '2016-06-27 23:59:25-07', True, False, 4);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(12, '2016-06-24 18:00:25-07', True, False, 4);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(12, '2016-06-23 00:00:25-07', True, False, 4);

INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
VALUES(12, '2016-06-26 18:00:25-07', True, True, 4);

/* Update Rider 12's current schedule */
INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 11, scid,
(SELECT mth FROM Full_Timer WHERE rid = 11) FROM Schedule_Count WHERE shift = 4
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-23 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 11, scid,
(SELECT mth FROM Full_Timer WHERE rid = 11) FROM Schedule_Count WHERE shift = 4
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-24 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 11, scid,
(SELECT mth FROM Full_Timer WHERE rid = 11) FROM Schedule_Count WHERE shift = 4
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-25 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 11, scid,
(SELECT mth FROM Full_Timer WHERE rid = 11) FROM Schedule_Count WHERE shift = 4
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-26 18:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_mth)
SELECT 11, scid,
(SELECT mth FROM Full_Timer WHERE rid = 11) FROM Schedule_Count WHERE shift = 4
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-27 18:00:25-07');

/*Rider 13*/

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(13, EXTRACT(DOW FROM TIMESTAMP '2016-06-23 10:00:00-07'), '2016-06-23 10:00:00-07',
      '2016-06-23 11:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(13, EXTRACT(DOW FROM TIMESTAMP '2016-06-24 10:00:00-07'), '2016-06-24 10:00:00-07',
      '2016-06-24 11:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(13, EXTRACT(DOW FROM TIMESTAMP '2016-06-25 10:00:00-07'), '2016-06-25 10:00:00-07',
      '2016-06-25 11:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(13, EXTRACT(DOW FROM TIMESTAMP '2016-06-26 10:00:00-07'), '2016-06-26 10:00:00-07',
      '2016-06-26 11:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(13, EXTRACT(DOW FROM TIMESTAMP '2016-06-27 10:00:00-07'), '2016-06-27 10:00:00-07',
      '2016-06-27 11:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(13, EXTRACT(DOW FROM TIMESTAMP '2016-06-23 21:00:00-07'), '2016-06-23 21:00:00-07',
      '2016-06-23 22:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(13, EXTRACT(DOW FROM TIMESTAMP '2016-06-24 21:00:00-07'), '2016-06-24 21:00:00-07',
      '2016-06-24 22:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(13, EXTRACT(DOW FROM TIMESTAMP '2016-06-25 21:00:00-07'), '2016-06-25 21:00:00-07',
      '2016-06-25 22:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(13, EXTRACT(DOW FROM TIMESTAMP '2016-06-26 21:00:00-07'), '2016-06-26 21:00:00-07',
      '2016-06-26 22:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(13, EXTRACT(DOW FROM TIMESTAMP '2016-06-27 21:00:00-07'), '2016-06-27 21:00:00-07',
      '2016-06-27 22:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(13, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 10:00:00-07'), '2016-06-28 10:00:00-07',
      '2016-06-28 14:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(13, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 15:00:00-07'), '2016-06-28 15:00:00-07',
      '2016-06-28 19:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(13, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 20:00:00-07'), '2016-06-28 20:00:00-07',
      '2016-06-28 22:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(13, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 10:00:00-07'), '2016-06-29 10:00:00-07',
      '2016-06-29 14:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(13, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 15:00:00-07'), '2016-06-29 15:00:00-07',
      '2016-06-29 19:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(13, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 20:00:00-07'), '2016-06-29 20:00:00-07',
      '2016-06-29 22:00:00-07', True);

/* Update Current_Schedule for PT-rider 13 */

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 13, scid,
(SELECT wks FROM Part_Timer WHERE rid = 13)
FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-23 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 13, scid,
(SELECT wks FROM Part_Timer WHERE rid = 13)
FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-23 21:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 13, scid,
(SELECT wks FROM Part_Timer WHERE rid = 13)
FROM Schedule_Count WHERE start_time > EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 10:00:00-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 14:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 13, scid,
(SELECT wks FROM Part_Timer WHERE rid = 13)
FROM Schedule_Count WHERE start_time > EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 10:00:00-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 14:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 13, scid,
(SELECT wks FROM Part_Timer WHERE rid = 13)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 15:00:00-07')
AND start_time <= EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 19:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 13, scid,
(SELECT wks FROM Part_Timer WHERE rid = 13)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 15:00:00-07')
AND start_time <= EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 19:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 13, scid,
(SELECT wks FROM Part_Timer WHERE rid = 13)
FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 20:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 13, scid,
(SELECT wks FROM Part_Timer WHERE rid = 13)
FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 20:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 10:00:00-07');


/*Rider 14*/

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(14, EXTRACT(DOW FROM TIMESTAMP '2016-06-23 10:00:00-07'), '2016-06-23 10:00:00-07',
      '2016-06-23 11:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(14, EXTRACT(DOW FROM TIMESTAMP '2016-06-24 10:00:00-07'), '2016-06-24 10:00:00-07',
      '2016-06-24 11:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(14, EXTRACT(DOW FROM TIMESTAMP '2016-06-25 10:00:00-07'), '2016-06-25 10:00:00-07',
      '2016-06-25 11:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(14, EXTRACT(DOW FROM TIMESTAMP '2016-06-26 10:00:00-07'), '2016-06-26 10:00:00-07',
      '2016-06-26 11:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(14, EXTRACT(DOW FROM TIMESTAMP '2016-06-27 10:00:00-07'), '2016-06-27 10:00:00-07',
      '2016-06-27 11:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(14, EXTRACT(DOW FROM TIMESTAMP '2016-06-23 21:00:00-07'), '2016-06-23 21:00:00-07',
      '2016-06-23 22:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(14, EXTRACT(DOW FROM TIMESTAMP '2016-06-24 21:00:00-07'), '2016-06-24 21:00:00-07',
      '2016-06-24 22:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(14, EXTRACT(DOW FROM TIMESTAMP '2016-06-25 21:00:00-07'), '2016-06-25 21:00:00-07',
      '2016-06-25 22:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(14, EXTRACT(DOW FROM TIMESTAMP '2016-06-26 21:00:00-07'), '2016-06-26 21:00:00-07',
      '2016-06-26 22:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(14, EXTRACT(DOW FROM TIMESTAMP '2016-06-27 21:00:00-07'), '2016-06-27 21:00:00-07',
      '2016-06-27 22:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(14, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 10:00:00-07'), '2016-06-28 10:00:00-07',
      '2016-06-28 14:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(14, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 15:00:00-07'), '2016-06-28 15:00:00-07',
      '2016-06-28 19:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(14, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 20:00:00-07'), '2016-06-28 20:00:00-07',
      '2016-06-28 22:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(14, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 10:00:00-07'), '2016-06-29 10:00:00-07',
      '2016-06-29 14:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(14, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 15:00:00-07'), '2016-06-29 15:00:00-07',
      '2016-06-29 19:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(14, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 20:00:00-07'), '2016-06-29 20:00:00-07',
      '2016-06-29 22:00:00-07', True);



/* Update Current_Schedule for PT-rider 14 */

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 14, scid,
(SELECT wks FROM Part_Timer WHERE rid = 14)
FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-23 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 14, scid,
(SELECT wks FROM Part_Timer WHERE rid = 14)
FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-23 21:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 14, scid,
(SELECT wks FROM Part_Timer WHERE rid = 14)
FROM Schedule_Count WHERE start_time > EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 10:00:00-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 14:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 14, scid,
(SELECT wks FROM Part_Timer WHERE rid = 14)
FROM Schedule_Count WHERE start_time > EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 10:00:00-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 14:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 14, scid,
(SELECT wks FROM Part_Timer WHERE rid = 14)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 15:00:00-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 19:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 14, scid,
(SELECT wks FROM Part_Timer WHERE rid = 14)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 15:00:00-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 19:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 14, scid,
(SELECT wks FROM Part_Timer WHERE rid = 14)
FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 20:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 14, scid,
(SELECT wks FROM Part_Timer WHERE rid = 14)
FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 20:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 10:00:00-07');


/*Rider 15*/
INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(15, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 10:00:00-07'), '2016-06-28 10:00:00-07',
      '2016-06-28 14:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(15, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 15:00:00-07'), '2016-06-28 15:00:00-07',
      '2016-06-28 19:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(15, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 20:00:00-07'), '2016-06-28 20:00:00-07',
      '2016-06-28 22:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(15, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 10:00:00-07'), '2016-06-29 10:00:00-07',
      '2016-06-29 14:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(15, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 15:00:00-07'), '2016-06-29 15:00:00-07',
      '2016-06-29 19:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(15, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 20:00:00-07'), '2016-06-29 20:00:00-07',
      '2016-06-29 22:00:00-07', True);


/* Update Current_Schedule for PT-rider 15 */
INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 15, scid,
(SELECT wks FROM Part_Timer WHERE rid = 15)
FROM Schedule_Count WHERE start_time > EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 10:00:00-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 14:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 15, scid,
(SELECT wks FROM Part_Timer WHERE rid = 15)
FROM Schedule_Count WHERE start_time > EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 10:00:00-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 14:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 15, scid,
(SELECT wks FROM Part_Timer WHERE rid = 15)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 15:00:00-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 19:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 15, scid,
(SELECT wks FROM Part_Timer WHERE rid = 15)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 15:00:00-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 19:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 15, scid,
(SELECT wks FROM Part_Timer WHERE rid = 15)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 20:00:00-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 22:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 15, scid,
(SELECT wks FROM Part_Timer WHERE rid = 15)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 20:00:00-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 22:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 10:00:00-07');

/*Rider 16*/
INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(16, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 14:00:00-07'), '2016-06-28 14:00:00-07',
      '2016-06-28 18:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(16, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 19:00:00-07'), '2016-06-28 19:00:00-07',
      '2016-06-28 20:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(16, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 14:00:00-07'), '2016-06-29 14:00:00-07',
      '2016-06-29 18:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(16, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 19:00:00-07'), '2016-06-29 19:00:00-07',
      '2016-06-29 20:00:00-07', True);

/* Update Current_Schedule for PT-rider 16 */

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 16, scid,
(SELECT wks FROM Part_Timer WHERE rid = 16)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 14:00:25-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 18:00:25-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 14:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 16, scid,
(SELECT wks FROM Part_Timer WHERE rid = 16)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 14:00:25-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 18:00:25-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 14:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 16, scid,
(SELECT wks FROM Part_Timer WHERE rid = 16)
FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 19:00:25-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 14:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 16, scid,
(SELECT wks FROM Part_Timer WHERE rid = 16)
FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 19:00:25-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 14:00:25-07');

/*Rider 17*/
INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(17, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 14:00:00-07'), '2016-06-28 14:00:00-07',
      '2016-06-28 18:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(17, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 19:00:00-07'), '2016-06-28 19:00:00-07',
      '2016-06-28 20:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(17, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 14:00:00-07'), '2016-06-29 14:00:00-07',
      '2016-06-29 18:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(17, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 19:00:00-07'), '2016-06-29 19:00:00-07',
      '2016-06-29 20:00:00-07', True);

/* Update Current_Schedule for PT-rider 17 */

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 17, scid,
(SELECT wks FROM Part_Timer WHERE rid = 17)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 14:00:25-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 18:00:25-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 14:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 17, scid,
(SELECT wks FROM Part_Timer WHERE rid = 17)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 14:00:25-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 18:00:25-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 14:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 17, scid,
(SELECT wks FROM Part_Timer WHERE rid = 17)
FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 19:00:25-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 14:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 17, scid,
(SELECT wks FROM Part_Timer WHERE rid = 17)
FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 19:00:25-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 14:00:25-07');

/*Rider 18*/
INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(18, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 14:00:00-07'), '2016-06-28 14:00:00-07',
      '2016-06-28 18:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(18, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 19:00:00-07'), '2016-06-28 19:00:00-07',
      '2016-06-28 20:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(18, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 14:00:00-07'), '2016-06-29 14:00:00-07',
      '2016-06-29 18:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(18, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 19:00:00-07'), '2016-06-29 19:00:00-07',
      '2016-06-29 20:00:00-07', True);

/* Update Current_Schedule for PT-rider 18 */

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 18, scid,
(SELECT wks FROM Part_Timer WHERE rid = 18)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 14:00:25-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 18:00:25-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 14:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 18, scid,
(SELECT wks FROM Part_Timer WHERE rid = 18)
FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 14:00:25-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 18:00:25-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 14:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 18, scid,
(SELECT wks FROM Part_Timer WHERE rid = 18)
FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 19:00:25-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 14:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 18, scid,
(SELECT wks FROM Part_Timer WHERE rid = 18)
FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 19:00:25-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 14:00:25-07');

/*Rider 19*/
INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(19, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 14:00:00-07'), '2016-06-28 14:00:00-07',
      '2016-06-28 18:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(19, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 19:00:00-07'), '2016-06-28 19:00:00-07',
      '2016-06-28 20:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(19, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 14:00:00-07'), '2016-06-29 14:00:00-07',
      '2016-06-29 18:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(19, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 19:00:00-07'), '2016-06-29 19:00:00-07',
      '2016-06-29 20:00:00-07', True);

/* Update Current_Schedule for PT-rider 19 */

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 19, scid,
(SELECT wks FROM Part_Timer WHERE rid = 19)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 14:00:25-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 18:00:25-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 14:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 19, scid,
(SELECT wks FROM Part_Timer WHERE rid = 19)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 14:00:25-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 18:00:25-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 14:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 19, scid,
(SELECT wks FROM Part_Timer WHERE rid = 19)
FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 19:00:25-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 14:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 19, scid,
(SELECT wks FROM Part_Timer WHERE rid = 19)
FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 19:00:25-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 14:00:25-07');

/*Rider 20*/
INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(20, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 14:00:00-07'), '2016-06-28 14:00:00-07',
      '2016-06-28 18:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(20, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 19:00:00-07'), '2016-06-28 19:00:00-07',
      '2016-06-28 20:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(20, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 14:00:00-07'), '2016-06-29 14:00:00-07',
      '2016-06-29 18:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(20, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 19:00:00-07'), '2016-06-29 19:00:00-07',
      '2016-06-29 20:00:00-07', True);

/* Update Current_Schedule for PT-rider 19 */

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 20, scid,
(SELECT wks FROM Part_Timer WHERE rid = 20)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 14:00:25-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 18:00:25-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 14:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 20, scid,
(SELECT wks FROM Part_Timer WHERE rid = 20)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 14:00:25-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 18:00:25-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 14:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 20, scid,
(SELECT wks FROM Part_Timer WHERE rid = 20)
FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 19:00:25-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 14:00:25-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 20, scid,
(SELECT wks FROM Part_Timer WHERE rid = 20)
FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 19:00:25-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 14:00:25-07');

/*Rider 21*/
INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(21, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 15:00:00-07'), '2016-06-28 15:00:00-07',
      '2016-06-28 19:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(21, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 20:00:00-07'), '2016-06-28 20:00:00-07',
      '2016-06-28 22:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(21, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 10:00:00-07'), '2016-06-29 10:00:00-07',
      '2016-06-29 14:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(21, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 15:00:00-07'), '2016-06-29 15:00:00-07',
      '2016-06-29 19:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(21, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 20:00:00-07'), '2016-06-29 20:00:00-07',
      '2016-06-29 22:00:00-07', True);



/* Update Current_Schedule for PT-rider 21 */
INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 21, scid,
(SELECT wks FROM Part_Timer WHERE rid = 21)
FROM Schedule_Count WHERE start_time > EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 10:00:00-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 14:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 21, scid,
(SELECT wks FROM Part_Timer WHERE rid = 21)
FROM Schedule_Count WHERE start_time > EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 10:00:00-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 14:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 21, scid,
(SELECT wks FROM Part_Timer WHERE rid = 21)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 15:00:00-07')
AND start_time <= EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 19:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 21, scid,
(SELECT wks FROM Part_Timer WHERE rid = 21)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 15:00:00-07')
AND start_time <= EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 19:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 21, scid,
(SELECT wks FROM Part_Timer WHERE rid = 21)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 20:00:00-07')
AND start_time <= EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 22:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 21, scid,
(SELECT wks FROM Part_Timer WHERE rid = 21)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 20:00:00-07')
AND start_time <= EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 22:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 10:00:00-07');

/*Rider 22*/
INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(22, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 15:00:00-07'), '2016-06-28 15:00:00-07',
      '2016-06-28 19:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(22, EXTRACT(DOW FROM TIMESTAMP '2016-06-28 20:00:00-07'), '2016-06-28 20:00:00-07',
      '2016-06-28 22:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(22, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 10:00:00-07'), '2016-06-29 10:00:00-07',
      '2016-06-29 14:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(22, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 15:00:00-07'), '2016-06-29 15:00:00-07',
      '2016-06-29 19:00:00-07', False);

INSERT INTO Schedule_PT_Hours(rid, wkday, start_time, end_time, is_last_shift)
VALUES(22, EXTRACT(DOW FROM TIMESTAMP '2016-06-29 20:00:00-07'), '2016-06-29 20:00:00-07',
      '2016-06-29 22:00:00-07', True);

/* Update Current_Schedule for PT-rider 22 */
INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 22, scid,
(SELECT wks FROM Part_Timer WHERE rid = 22)
FROM Schedule_Count WHERE start_time > EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 10:00:00-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 14:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 22, scid,
(SELECT wks FROM Part_Timer WHERE rid = 22)
FROM Schedule_Count WHERE start_time > EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 10:00:00-07')
AND start_time < EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 14:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 22, scid,
(SELECT wks FROM Part_Timer WHERE rid = 22)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 15:00:00-07')
AND start_time <= EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 19:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 22, scid,
(SELECT wks FROM Part_Timer WHERE rid = 22)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 15:00:00-07')
AND start_time <= EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 19:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 22, scid,
(SELECT wks FROM Part_Timer WHERE rid = 22)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 20:00:00-07')
AND start_time <= EXTRACT(HOUR FROM TIMESTAMP '2016-06-28 22:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-28 10:00:00-07');

INSERT INTO Current_Schedule (rid, scid, curr_wk)
SELECT 22, scid,
(SELECT wks FROM Part_Timer WHERE rid = 22)
FROM Schedule_Count WHERE start_time >= EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 20:00:00-07')
AND start_time <= EXTRACT(HOUR FROM TIMESTAMP '2016-06-29 22:00:00-07')
AND wkday =  EXTRACT(DOW FROM TIMESTAMP '2016-06-29 10:00:00-07');

COMMIT;
