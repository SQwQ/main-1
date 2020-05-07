import React, { Component } from 'react'
import ScheduleSelector from 'react-schedule-selector';
import { Button, Table, TableCell, TableRow, TableBody, TableHead } from '@material-ui/core';
import DeleteIcon from '@material-ui/icons/Delete';
import SaveIcon from '@material-ui/icons/Save';
import Radio from '@material-ui/core/Radio';
import RadioGroup from '@material-ui/core/RadioGroup';
import FormControlLabel from '@material-ui/core/FormControlLabel';

import * as apiRoute from '../../components/Api/route.js';
import Axios from 'axios';
import * as moment from 'moment';

import '../css/rider/schedulerPage.css';

export class riderSchedulerPage extends Component {
    constructor(props) {
        super(props);
        this.state = {
            schedule: [], //Placeholder
            ftDay: '',
            ftHour: '',
            upToDate: true,
        }
        console.log(this.props.type+"r detected!")
        if (this.props.type === "full_time") {
            
            this.getFullTimeData()
        } else {
            this.getPartTimeData()
        }
        this._handleChange = this._handleChange.bind(this)
        this.assembleLastUpdate_FT = this.assembleLastUpdate_FT.bind(this)
        this.getDayAndInterval = this.getDayAndInterval.bind(this)
        this.interpretDayFromIso = this.interpretDayFromIso.bind(this)
        this.isOverdueWeeks = this.isOverdueWeeks.bind(this)
    }

    /*
    Full Time
    */
    // Gets data about a full timer to initialize form options
    getFullTimeData() {
        console.log("getting data from db")
        Axios.get(apiRoute.FT_RIDER_API + "/shiftDayHours/" + this.props.id, {
            withCredentials: false,
        })
            .then(
                response => {
                    var day = moment(response.data[0].wkdate).isoWeekday();
                    var overdue = this.isOverdueWeeks(moment(response.data[0].wkdate));

                    this.setState({
                        lastSetDate: response.data[0].wkdate,
                        shiftSet: response.data[0].shift,
                        ftHour: response.data[0].shift,
                        ftDay: day,
                        upToDate: !overdue,
                    })
                }
            ).catch(error => {
                console.log("Error getting rider type!")
                console.log(error);
            });
    }



    // Convert interval to week and days to current moment from a
    // point of time.
    // format output: [weeks, days]
    getDayAndInterval(past) {
        var start = moment(past)
        var end = moment()
        var days_diff = end.from(start, 'days')

        var weeks_diff = days_diff / 7
        return [weeks_diff, days_diff%7]
    }

    assembleLastUpdate_FT(date) {
        var diff = this.getDayAndInterval(date)
        if (diff[0] < 4) {
            return `${diff[0]} weeks and ${diff[1]} days ago. You do not need to update your schedule.`
        } else {
            return <b>more than 4 weeks ago! Please update your schedule.</b>;
        }
    }

    isOverdueWeeks(date) {
        var diff = this.getDayAndInterval(date)
        if (diff[0] < 4) {
            return false;
        } else {
            return true;
        }
    }

    _handleFtHoursChange(e) {
        this.setState({
            ftHour: parseInt(e.target.value),
        })
    }

    _handleFtDaysChange(e) {
        this.setState({
            ftDay: parseInt(e.target.value),
        })
    }

    interpretDayFromIso(num) {
        switch (num) {
            case 1:
                return "Thursday to Monday";
            case 2:
                return "Friday to Tuesday";
            case 3:
                return "Saturday to Wednesday";
            case 4:
                return "Sunday to Thursday";
            case 5:
                return "Monday to Friday";
            case 6:
                return "Tuesday to Saturday";
            default:
                return "Wednesday to Sunday";
        }
    }

    /*
    Part Time
    */
    // Gets data about a part timer to initialize form options
    getPartTimeData() {
        return
    }

    isOverdueDays(date) {
        var diff = this.getDayAndInterval(date)
        if (diff[0] < 1) {
            return false;
        } else {
            return true;
        }
    }
    
    _handleChange(e) {
        // Debug
        console.log("Hours worked: "+e.length)
        this.setState({ schedule: e})
    }


    render() {
        const disableControl = this.state.upToDate ? false : true;

        return (
            <div className="schedulePage">
                <center><h2>Your weekly schedule</h2></center>
                <center>
                {this.props.type === "full_time" ?
                // Full Time Rider Schedule Selector
                <div className="fullTimerSchedule">
                    <center>You last updated your schedule: {this.assembleLastUpdate_FT(this.state.lastSetDate)}</center>
                    <Table className="currentSchedule">
                        <TableHead>
                            <TableRow>
                            <TableCell>Your current Work Hours</TableCell>
                            <TableCell>Your current Work Days</TableCell>
                            </TableRow>
                        </TableHead>
                        <TableBody>
                            <TableRow>
                            <TableCell align="center"><b>Shift {this.state.shiftSet}</b></TableCell>
                            <TableCell align="center"><b>{this.interpretDayFromIso(moment(this.state.lastSetDate).isoWeekday())}</b></TableCell>
                            </TableRow>
                        </TableBody>
                    </Table>
                    <h4>Work Hours</h4>
                    <RadioGroup name="workHours" value={this.state.ftHour} onChange={e => this._handleFtHoursChange(e)}>
                        <FormControlLabel value={1} control={<Radio />} label="Shift 1 (1000-1400, 1500-1900)" disabled={this.state.upToDate}  />
                        <FormControlLabel value={2} control={<Radio />} label="Shift 2 (1100-1500, 1600-2000)" disabled={this.state.upToDate}  />
                        <FormControlLabel value={3} control={<Radio />} label="Shift 3 (1200-1600, 1700-2100)" disabled={this.state.upToDate}  />
                        <FormControlLabel value={4} control={<Radio />} label="Shift 4 (1300-1700, 1800-2200)" disabled={this.state.upToDate} />
                    </RadioGroup>
                    <h4>Work Days</h4>
                    <RadioGroup name="workDays" value={this.state.ftDay} onChange={e => this._handleFtDaysChange(e)}>
                        {/* Labelling values to account for ending day not starting */}
                        <FormControlLabel value={4} control={<Radio />} label="Sunday to Thursday" disabled={this.state.upToDate} />
                        <FormControlLabel value={5} control={<Radio />} label="Monday to Friday" disabled={this.state.upToDate} />
                        <FormControlLabel value={6} control={<Radio />} label="Tuesday to Saturday" disabled={this.state.upToDate} />
                        <FormControlLabel value={7} control={<Radio />} label="Wednesday to Sunday" disabled={this.state.upToDate} />
                        <FormControlLabel value={1} control={<Radio />} label="Thursday to Monday" disabled={this.state.upToDate} />
                        <FormControlLabel value={2} control={<Radio />} label="Friday to Tuesday" disabled={this.state.upToDate} />
                        <FormControlLabel value={3} control={<Radio />} label="Saturday to Wednesday" disabled={this.state.upToDate} />
                    </RadioGroup>
                    <Button
                        variant="contained"
                        id="saveButton"
                        color="primary"
                        size="large"
                        className="saveButton"
                        startIcon={<SaveIcon />}
                    >
                        Save
                    </Button>
                </div>  :
                
                // Part Time Rider Schedule Selector
                <div className="partTimerSchedule">
                    <ScheduleSelector
                        selection={this.state.schedule}
                        startDate={Date.now()}
                        dateFormat = {'ddd'}
                        numDays={7}
                        minTime={10}
                        maxTime={22}
                        onChange={this._handleChange}
                        margin={2}
                    />
                    <div className="buttons">
                    <Button
                        variant="contained"
                        id="clearButton"
                        color="secondary"
                        size="large"
                        className="saveButton"
                        startIcon={<DeleteIcon />}
                    >
                        Clear
                    </Button>
                    <Button
                        variant="contained"
                        id="saveButton"
                        color="primary"
                        size="large"
                        className="saveButton"
                        startIcon={<SaveIcon />}
                    >
                        Save
                    </Button>
                    </div>
                </div>
                }
                </center>
            </div>
        )
    }
}

export default riderSchedulerPage
