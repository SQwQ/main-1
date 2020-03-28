import React, {Component} from 'react';
import {TextField, Button} from '@material-ui/core';
import './css/index.css';
import UserRegisterForm from '../components/RegistrationForms/UserRegisterForm';
import RiderRegisterForm
  from '../components/RegistrationForms/RiderRegisterForm';
import StaffRegisterForm
  from '../components/RegistrationForms/StaffRegisterForm';
import LoginModal from '../components/Login/LoginModal';

import {Link as RouterLink} from 'react-router-dom';

export default class MainPage extends Component {
  constructor (props) {
    super (props);
    this.onChange = this.onChange.bind (this);
    this.state = {
      id: 0,
    };
  }

  render () {
    return (
      <div class="MainPageBody">
        <h1>tapau.</h1>
        <h3>Main Page</h3>
        <div>
          <LoginModal />
        </div>
        {/* For user to enter ID: DEBUG ONLY - Current workaround for login system */}
        <br /><br />
        <div>
          <UserRegisterForm />
          <RiderRegisterForm />
          <StaffRegisterForm />
        </div>
      </div>
    );
  }
}
