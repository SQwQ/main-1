import React from 'react';
import {Button} from '@material-ui/core';
import './css/index.css';
import UserRegisterForm from '../components/RegistrationForms/UserRegisterForm';
import RiderRegisterForm
  from '../components/RegistrationForms/RiderRegisterForm';
import StaffRegisterForm
  from '../components/RegistrationForms/StaffRegisterForm';

import {Link as RouterLink} from 'react-router-dom';

const handleLink = (reroute, id) => {
  this.props.history.push ({
    pathname: `/${reroute}/` + id,
  });
};

const MainPage = () => {
  return (
    <div class="MainPageBody">
      <h1>tapau.</h1>
      <h3>Main Page</h3>
      <div>
        <Button
          variant="contained"
          color="primary"
          onClick={() => handleLink ('user')}
        >
          Customer
        </Button>
        <Button
          variant="contained"
          color="primary"
          onClick={() => handleLink ('rider')}
        >
          Delivery Rider
        </Button>
        <Button
          variant="contained"
          color="primary"
          onClick={() => handleLink ('staff')}
        >
          Restaurant Staff
        </Button>
        <Button
          variant="contained"
          color="primary"
          onClick={() => handleLink ('manager')}
        >
          FDS Manager
        </Button>
      </div>
      <br /><br />
      <div>
        <UserRegisterForm />
        <RiderRegisterForm />
        <StaffRegisterForm />
      </div>
    </div>
  );
};

export default MainPage;
