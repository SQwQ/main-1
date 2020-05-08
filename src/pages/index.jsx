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
    <center>
        <div className="MainPageBody">
            <div className="title">
                <center><div className="logo"></div></center>
                <h1>tapau.</h1>
            </div>
            <div className="caption"><h3>Enjoy food brought right up to your doorstep.</h3></div>
            <div>
            <LoginModal 
                authenticate={this.props.authenticate} 
                unauthenticate={this.props.unauthenticate}
            />
            </div>
            <br /><br />
            <center>
            <div className="registrationSection">
            <UserRegisterForm />
            <RiderRegisterForm />
            {/* <StaffRegisterForm /> */}
            </div>
            </center>
        </div>
      </center>
    );
  }
}
