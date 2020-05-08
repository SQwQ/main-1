import React, { Component } from 'react'
import { Button, Table, TableCell, TableRow, TableBody, TableHead } from '@material-ui/core';
import * as apiRoute from '../../components/Api/route.js';
import Axios from 'axios';

export class riderStatsPage extends Component {
    constructor(props) {
        super(props);
        this.state = {
            fullTimeStats: [],
            partTimeStats: []
        }
        this.id = this.props.id;
        if (this.props.type === "full_time") {
            this.getFullTimeStats()
        } else {
            this.getPartTimeStats()
        }
    }

    getFullTimeStats() {
        Axios.get(apiRoute.FT_RIDER_API + "/stats/" + this.id, {
            withCredentials: false,
        })
            .then(
                response => {
                    this.setState({
                         fullTimeStats: response.data
                    })
                }
            ).catch(error => {
                console.log("Error getting full time stats!")
                console.log(error);
            });
    }

    getPartTimeStats() {
        Axios.get(apiRoute.PT_RIDER_API + "/stats/" + this.id, {
            withCredentials: false,
        })
            .then(
                response => {
                    this.setState({
                         partTimeStats: response.data
                    })
                }
            ).catch(error => {
                console.log("Error getting part time stats!")
                console.log(error);
            });
    }

    render() {
        return (
            <div className="statsPage">
                <center><h2>Stats page</h2></center>
                { this.props.type === "full_time" ?
                // FULL TIME STATS
                <Table className="fullTimeStats">
                        <TableHead>
                            <TableRow>
                            <TableCell>Month No.</TableCell>
                            <TableCell>Deliveries Made</TableCell>
                            <TableCell>Number of Hours Worked</TableCell>
                            <TableCell>Salary</TableCell>    
                            </TableRow>
                        </TableHead>
                        <TableBody>
                            {this.state.fullTimeStats.map((month) => (
                                <TableRow key={month.month_no}>
                                    <TableCell align="center">{month.month_no}</TableCell>
                                    <TableCell align="center">{month.numdelivered}</TableCell>
                                    <TableCell align="center">{month.numhoursworked} Hrs</TableCell>
                                    <TableCell align="center">${month.salary}</TableCell>
                                </TableRow>
                            ))}
                        </TableBody>
                    </Table>
                :
                // PART TIME STATS
                <Table className="partTimeStats">
                    <TableHead>
                        <TableRow>
                        <TableCell>Week No.</TableCell>
                        <TableCell>Deliveries Made</TableCell>
                        <TableCell>Number of Hours Worked</TableCell>
                        <TableCell>Salary</TableCell>    
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {this.state.fullTimeStats.map((month) => (
                            <TableRow key={month.month_no}>
                                <TableCell align="center">{month.month_no}</TableCell>
                                <TableCell align="center">{month.numdelivered}</TableCell>
                                <TableCell align="center">{month.numhoursworked} Hrs</TableCell>
                                <TableCell align="center">${month.salary}</TableCell>
                            </TableRow>
                        ))}
                    </TableBody>
                </Table>
                }
            </div>
        )
    }
}

export default riderStatsPage
