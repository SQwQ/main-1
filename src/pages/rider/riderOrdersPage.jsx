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
            assignedOrders: [],       
        }
        //getAllAcceptedOrders()
        this.getAllOrders()
        
        this._handleAccept = this._handleAccept.bind(this);
    }

    getAllOrders() {
        Axios.get(apiRoute.RIDER_GET_ORDERS + '/assigned/' + this.props.id , {
            withCredentials: false,
        })
            .then(
                response => {
                    this.setState({
                        assignedOrders: response.data
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

    _handleAcceptEnrouteR(e, id){ 

    }
    _handleAcceptArrivedR(e, id){ 

    }
    _handleAcceptEnrouteC(e, id){ 

    }
    _handleAcceptArrivedC(e, id){ 
        
    }

    render() {
        return (
            <div className="OrdersPage">
                <center>
                    <h2>Assigned Orders</h2>
                    <Table className="openOrders">
                        <TableHead>
                            <TableRow>
                            <TableCell>Order Id</TableCell>
                            <TableCell>Order Created</TableCell>
                            <TableCell>Total Price</TableCell>
                            <TableCell>Restaurant Address</TableCell>
                            <TableCell>Customer Zipcode</TableCell>
                            <TableCell>Enroute to Restaurant</TableCell>  
                            <TableCell>Arrived at Restaurant</TableCell> 
                            <TableCell>Enroute to Customer</TableCell> 
                            <TableCell>Food Delivered</TableCell>   
                            </TableRow>
                        </TableHead>
                        <TableBody>
                            {this.state.assignedOrders.map((order) => (
                                <TableRow key={order.ocid}>
                            <TableCell align="center">{order.ocid}</TableCell>
                            <TableCell align="center">{order.oorder_place_time}</TableCell>
                            <TableCell align="center">${order.ofinal_price}</TableCell>
                            <TableCell align="center">{order.raddress}</TableCell>
                            <TableCell align="center">{order.ozipcode}</TableCell>
                            <TableCell align="center"><Button
                                    variant="contained"
                                    id={order.ocid + "-enroute-R"} 
                                    color="primary"
                                    size="small"
                                    className="enrouteRButton"
                                    startIcon={<ArrowForwardIcon />}
                                    disabled={order.oorder_enroute_restaurant}
                                    onClick={e => this._handleAcceptEnrouteR(e, order.ocid)}
                                >
                                On my way!
                                </Button></TableCell>
                            <TableCell align="center"><Button
                                    variant="contained"
                                    id={order.ocid + "-arrived-R"} 
                                    color="primary"
                                    size="small"
                                    className="arrivedRButton"
                                    startIcon={<RestaurantIcon />}
                                    disabled={order.oorder_arrives_restaurant}
                                    onClick={e => this._handleAcceptArrivedR(e, order.ocid)}
                                >Picked Up!
                                </Button></TableCell>
                            <TableCell align="center"><Button
                                    variant="contained"
                                    id={order.ocid + "-enroute-C"} 
                                    color="primary"
                                    size="small"
                                    className="enrouteCButton"
                                    startIcon={<ArrowForwardIcon />}
                                    disabled={order.oorder_enroute_customer}
                                    onClick={e => this._handleAcceptEnrouteC(e, order.ocid)}
                                >
                                On my way!
                                </Button></TableCell>
                            <TableCell align="center"><Button
                                    variant="contained"
                                    id={order.ocid + "-arrived-C"} 
                                    color="primary"
                                    size="small"
                                    className="arrivedCButton"
                                    startIcon={<LocalMallIcon />}
                                    disabled={order.oorder_arrives_customer}
                                    onClick={e => this._handleAcceptArrivedC(e, order.ocid)}
                                >
                                Done!
                                </Button></TableCell>
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

