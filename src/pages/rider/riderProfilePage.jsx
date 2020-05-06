import React, { Component } from 'react'
import List from '@material-ui/core/List';
import ListItem from '@material-ui/core/ListItem';
import ListItemText from '@material-ui/core/ListItemText';
import * as apiRoute from '../../components/Api/route.js';
import Axios from 'axios';

export class riderProfilePage extends Component {
    constructor(props) {
        super(props);
        this.state = {}
        this.id = this.props.id;
        this.name = this.props.name;
        this.username = this.props.username;
        this.password = this.props.password;
    }

    render() {
        return (
            <div className="profilePage">
                <center><h2>Profile page</h2></center>

                <List>
                    <ListItem>
                        <ListItemText primary="Rider ID" secondary={this.id} />
                    </ListItem>
                    <ListItem>
                        <ListItemText primary="Name" secondary={this.name} />
                    </ListItem>
                    <ListItem>
                        <ListItemText primary="Username" secondary={this.username} />
                    </ListItem>
                    <ListItem>
                        <ListItemText primary="Password" secondary={this.password} />
                    </ListItem>
                </List>

            </div>
        )
    }
}

export default riderProfilePage
