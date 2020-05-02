// Both routes are not tested and probably don't work

// Add a new part-time schedule

router.route('/api/schedule/part_time').post((req, res) => {
    // time_array need to be ordered s.t time_array[0] is earliest 
    const time_array = JSON.parse(req.param.timestamps).cards; //array of pairs of timestamps e.g [2016-06-25 18:00:25-07, 2016-06-25 19:00:25-07] for block 6-7pm
    const rid = req.params.rid;

    /* insert each time block into Schedule_PT_Hours */
    for (var i = 0; i < time_array.length; i++) {
        if (i <  time_array.length -1) {
            pool
            .query(
            `INSERT INTO Schedule_PT_Hours("rid", "wkday", "start_time", "end_time", "is_last_shift")
            VALUES(${rid}, EXTRACT(DOW FROM TIMESTAMP '${time_array[i][0]}'), '${time_array[i][0]}',
            '${time_array[i][0]}', 'False');`)
            .then(() => console.log("Successfully added new timeslot"))
            .catch(err => res.status(400).json('Error' + err));
        } else {
            /* insert last hour block */
            pool
            .query(
            `INSERT INTO Schedule_PT_Hours("rid", "wkday", "start_time", "end_time", "is_last_shift")
            VALUES(${rid}, EXTRACT(DOW FROM TIMESTAMP '${time_array[i][0]}'), '${time_array[i][0]}',
            '${time_array[i][0]}', 'True');`)
            .then(() => console.log("Successfully added new timeslot"))
            .catch(err => res.status(400).json('Error' + err));
        }
    }

    /* the 3 blobs below are to ensure we still have at least 5 person per hr */

    /* update schedule_count which is a catalougue of timeslots + number of available riders at that slot */
    for (var i = 0; i < time_array.length; i++) {

        pool
        .query(
        `UPDATE Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '${time_array[i][0]}') 
        AND wkday =  EXTRACT(DOW FROM TIMESTAMP '${time_array[i][0]}') SET num_avail = num_avail + 1;`)
        .then(() => console.log("Successfully updated schedule"))
        .catch(err => res.status(400).json('Error' + err));
        
    }
    
     /* triggers schedule_count to decrease the number of available riders at the old slots */
    pool
    .query(
    `DELETE FROM Current_Schedule WHERE rid = ${rid};`)
    .then(() => console.log("Successfully deleted old schedule"))
    .catch(err => res.status(400).json('Error' + err));

    /* renews entries in Current_Schedule for this rider */
    for (var i = 0; i < time_array.length; i++) {

        pool
        .query(
        `INSERT INTO Current_Schedule (rid, scid, curr_wk)
        SELECT ${rid}, (SELECT scid FROM Schedule_Count WHERE start_time = EXTRACT(HOUR FROM TIMESTAMP '${time_array[i][0]}'), 
        wks FROM Part_Timer WHERE rid = ${rid};`)
        .then(() => console.log("Successfully updated schedule"))
        .catch(err => res.status(400).json('Error' + err));
        
    }  
  
});

// Add a new full-time schedule

router.route('/api/schedule/full_time').post((req, res) => {
    // only one timestamp from each day is necessary, can be in any order
    const time_array = JSON.parse(req.param.timestamps).cards; //array of timestamps/shift no. pairs e.g [2016-06-25 10:00:25-07, 1], 
    const rid = req.params.rid;
    

    /* insert each time block into Schedule_FT_Hours */
    for (var i = 0; i < time_array.length; i++) {
        if (i <  time_array.length -1) {
            pool
            .query(
            `INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
            VALUES(${rid}, '${time_array[i][0]}', True, False, '${time_array[i][1]}');`)
            .then(() => console.log("Successfully added new timeslot"))
            .catch(err => res.status(400).json('Error' + err));
        } else {
            /* insert last hour block */
            pool
            .query(
            `INSERT INTO Schedule_FT_Hours(rid, wkdate, is_prev, is_last_shift, shift)
            VALUES(${rid}, '${time_array[i][0]}', 'True', 'True', '${time_array[i][1]}');`)
            .then(() => console.log("Successfully added new timeslot"))
            .catch(err => res.status(400).json('Error' + err));
        }
    }

    /* the 3 blobs below are to ensure we still have at least 5 person per hr */

    /* update schedule_count which is a catalougue of timeslots + number of available riders at that slot */
    for (var i = 0; i < time_array.length; i++) {

        pool
        .query(
        `UPDATE Schedule_Count WHERE shift = '${time_array[i][1]}'
        AND wkday =  EXTRACT(DOW FROM TIMESTAMP '${time_array[i][0]}') SET num_avail = num_avail + 1;`)
        .then(() => console.log("Successfully updated schedule"))
        .catch(err => res.status(400).json('Error' + err));
        
    }
    
    /* triggers schedule_count to decrease the number of available riders at the old slots */
    pool
    .query(
    `DELETE FROM Current_Schedule WHERE rid = ${rid};`)
    .then(() => console.log("Successfully deleted old schedule"))
    .catch(err => res.status(400).json('Error' + err));

    /* renews entries in Current_Schedule for this rider */
    for (var i = 0; i < time_array.length; i++) {

        pool
        .query(
        `INSERT INTO Current_Schedule (rid, scid, curr_wk)
        SELECT ${rid}, scid, (SELECT mth FROM Full_Timer WHERE rid = 1) 
        FROM Schedule_Count WHERE shift = '${time_array[i][1]}' 
        AND wkday =  EXTRACT(DOW FROM TIMESTAMP '${time_array[i][0]}');`)
        .then(() => console.log("Successfully updated schedule"))
        .catch(err => res.status(400).json('Error' + err));
        
    }  
});
