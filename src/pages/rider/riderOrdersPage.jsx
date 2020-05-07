import React, { Component } from 'react'
import { Button, Table, TableCell, TableRow, TableBody, TableHead } from '@material-ui/core';
import CheckIcon from '@material-ui/icons/Check';
import ArrowForwardIcon from '@material-ui/icons/ArrowForward';
import RestaurantIcon from '@material-ui/icons/Restaurant';
import LocalMallIcon from '@material-ui/icons/LocalMall';

import * as apiRoute from '../../components/Api/route.js';
import Axios from 'axios';

export class riderOrdersPage extends Component {
    constructor(props) {
        super(props);
        this.state = {
            takenOrders: [],
            takenOrdersStatus: [],
            openOrders: [],            
        }
        //getAllAcceptedOrders()
        this.getAllOrders()
        
        this._handleAccept = this._handleAccept.bind(this);
    }

    getAllOrders() {
        Axios.get(apiRoute.RIDER_GET_ORDERS, {
            withCredentials: false,
        })
            .then(
                response => {
                    this.setState({
                        openOrders: response.data
                    })
                }
            ).catch(error => {
                console.log("Error getting rider type!")
                console.log(error);
            });
    }

    _handleAccept(event) {
        console.log(event)
    }

    render() {
        return (
            <div className="OrdersPage">
                <center>
                    {/*
                    <h2>Taken Orders</h2>
                    <Table className="openOrders">
                        <TableHead>
                            <TableRow>
                            <TableCell>Order Id</TableCell>
                            <TableCell>Enroute to Restaurant</TableCell>
                            <TableCell>Arrived to Restaurant</TableCell>
                            <TableCell>Enroute to Customer</TableCell>
                            <TableCell>Delivered!</TableCell>
                            </TableRow>
                        </TableHead>
                        <TableBody>
                            <TableRow>
                            <TableCell align="center">{ORDERID}</TableCell>
                            <TableCell align="center"><Button
                                variant="contained"
                                id="saveButton"
                                color="primary"
                                size="small"
                                startIcon={<ArrowForwardIcon />}
                            >
                            </Button>
                            </TableCell>
                            <TableCell align="center"><Button
                                variant="contained"
                                id="saveButton"
                                color="primary"
                                size="small"
                                startIcon={<RestaurantIcon />}
                            >
                            </Button>
                            </TableCell>
                            <TableCell align="center"><Button
                                variant="contained"
                                id="saveButton"
                                color="primary"
                                size="small"
                                startIcon={<ArrowForwardIcon />}
                            >
                            </Button>
                            </TableCell>
                            <TableCell align="center"><Button
                                variant="contained"
                                id="saveButton"
                                color="primary"
                                size="small"
                                startIcon={<LocalMallIcon />}
                            >
                            </Button>
                            </TableCell>
                            </TableRow>
                        </TableBody>
                    </Table>
                    */}
                    <h2>Open Orders</h2>
                    <Table className="openOrders">
                        <TableHead>
                            <TableRow>
                            <TableCell>Accept Order</TableCell>
                            <TableCell>Order Id</TableCell>
                            <TableCell>Order Created</TableCell>
                            <TableCell>Zipcode</TableCell>    
                            </TableRow>
                        </TableHead>
                        <TableBody>
                            {this.state.openOrders.map((order) => (
                                <TableRow key={order.ocid}>
                                <TableCell align="center">
                                    <Button
                                    variant="contained"
                                    id="OrderId"
                                    color="primary"
                                    size="small"
                                    className="acceptButton"
                                    startIcon={<CheckIcon />}
                                    onClick={this._handleAccept}
                                >
                                Accept
                                </Button>
                                </TableCell>
                            <TableCell align="center">{order.ocid}</TableCell>
                            <TableCell align="center">{order.oorder_place_time}</TableCell>
                            <TableCell align="center">{order.ozipcode}</TableCell>
                                </TableRow>
                            ))}
                        </TableBody>
                    </Table>
                </center>
            </div>
        )
    }
}

export default riderOrdersPage

