import React, { Component } from 'react'
import ScheduleSelector from 'react-schedule-selector';

export class riderSchedulerPage extends Component {
    constructor(props) {
        super(props);
        this.state = {
            schedule: [] //Placeholder
        }
        this._handleChange = this._handleChange.bind(this)
    }

    _handleChange(e) {
        console.log(e) //Placeholder
    }

    render() {
        return (
            <div className="schedulePage">
                <center><h2>Schedule page</h2></center>
                <ScheduleSelector
                    selection={this.state.schedule}
                    startDate={new Date('2020-03-22T00:00:00')} // Start on Sunday
                    dateFormat = {'ddd'}
                    numDays={7}
                    minTime={10}
                    maxTime={22}
                    selectionScheme={'linear'}
                    onChange={this._handleChange}
                    margin={2}
                />
            </div>
        )
    }
}

export default riderSchedulerPage
