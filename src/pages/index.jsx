import React, {Component} from 'react';
import './css/index.css';
import UserRegisterForm from '../components/RegistrationForms/UserRegisterForm';
import RiderRegisterForm
  from '../components/RegistrationForms/RiderRegisterForm';
import StaffRegisterForm
  from '../components/RegistrationForms/StaffRegisterForm';
import LoginModal from '../components/Login/LoginModal';

export default class MainPage extends Component {
  constructor (props) {
    super (props);
    this.state = {
      id: 0,
    };
  }

  render () {
    return (
      <div className="MainPageBody">
        <h1>tapau.</h1>
        <h3>Main Page</h3>
        <div>
          <LoginModal 
            authenticate={this.props.authenticate} 
            unauthenticate={this.props.unauthenticate}
          />
        </div>
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
