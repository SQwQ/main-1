import React, { Component } from 'react'
import { TextField, Button } from '@material-ui/core';
import './css/index.css' 
import UserRegisterForm from '../components/RegistrationForms/UserRegisterForm'
import RiderRegisterForm from '../components/RegistrationForms/RiderRegisterForm'
import StaffRegisterForm from '../components/RegistrationForms/StaffRegisterForm'

import {Link as RouterLink} from 'react-router-dom';

export default class MainPage extends Component {
    constructor(props) {
        super(props);
        this.onChange = this.onChange.bind(this);
        this.state = {id: 0}
    }

    onChange(e) {
        this.setState({id: e.target.value});
    }

    render() {
        return (
            <div class="MainPageBody">
                <h1>tapau.</h1>
                <h3>Main Page</h3>
                <div>        
                    <Button variant="contained" color="primary" component={RouterLink} to={{
                        pathname: "/user",
                        state: { userId: this.state.id }
                        }}>Customer</Button>
                    <Button variant="contained" color="primary" component={RouterLink} to="/rider">Delivery Rider</Button>
                    <Button variant="contained" color="primary" component={RouterLink} to="/staff">Restaurant Staff</Button>
                    <Button variant="contained" color="primary" component={RouterLink} to="/manager">FDS Manager</Button>
                </div>
                    {/* For user to enter ID: DEBUG ONLY - Current workaround for login system */}
                    <TextField id="user_id_number_field" type="number" label="Type ID here" defaultValue="1" onChange={this.onChange} required/>
                <br/><br/>
                <div>
                    <UserRegisterForm />
                    <RiderRegisterForm />
                    <StaffRegisterForm />
                </div>
            </div>
        );
    }
}
