import React, {Component} from 'react';
import Button from '@material-ui/core/Button';
import TextField from '@material-ui/core/TextField';
import Dialog from '@material-ui/core/Dialog';
import DialogActions from '@material-ui/core/DialogActions';
import DialogContent from '@material-ui/core/DialogContent';
import DialogContentText from '@material-ui/core/DialogContentText';
import DialogTitle from '@material-ui/core/DialogTitle';
import moment from 'moment';

import * as apiRoute from '../Api/route.js';
import Axios from 'axios';

export default class UserRegisterForm extends Component {
  constructor () {
    super ();
    this.state = {
      setOpen: false,
      success: false,
      showError: '',
      fullName: '',
      username: '',
      password: '',
      contactNumber: '',
    };

    this._handleClickOpen = this._handleClickOpen.bind(this);
    this._handleClose = this._handleClose.bind(this);
    this._handleRegister = this._handleRegister.bind(this);
    this._showError = this._showError.bind(this);
    this._showSuccess = this._showSuccess.bind(this);
  }

  _handleClickOpen = () => {
    this.setState ({setOpen: true});
  };

  _handleClose = () => {
    this.setState ({
        setOpen: false,
        showError: '',
        fullName: '',
        username: '',
        password: '',
        contactNumber: '',
        success: false,
    });
  };

  _handleRegister = () => {
    // Check if unspecified or empty
    if (!this.state.fullName.trim()) {
        this._showError("nameEmpty")
        return
    } else if (!this.state.username.trim()) {
        this._showError("usernameEmpty")
        return
    } else if (!this.state.password.trim()) {
        this._showError("passwordEmpty")
        return
    } else if (!this.state.contactNumber.trim()) {
        this._showError("contactNumberEmpty")
        return
    }

    let joinTime = moment(new Date()).format('YYYY-MM-DD hh:mm:ss');
    console.log ('User registered at: ', joinTime);
    let user = {
      cname: this.state.fullName.trim(),
      cusername: this.state.username.trim(),
      cpassword: this.state.password.trim(),
      ccontact_number: parseInt(this.state.contactNumber.trim()),
      cjoin_time: joinTime,
      crewards_points: 0,
    };
    Axios.post (apiRoute.CUSTOMER_API, user, {
      withCredentials: false,
    })
      .then (response => {
        console.log (response);
        this._showSuccess();
      })
      .catch (error => {
        console.log (error);
        this._showError("usernameTaken")
      });
  };

  _showError(errorStr) {
    switch(errorStr) {
        case "nameEmpty":
            this.setState({
                showError: "Please specify a name.",
                success: false
            });
        break;
        case "usernameEmpty":
            this.setState({
                showError: "Please specify a username.",
                success: false
            });
        break;
        case "passwordEmpty":
            this.setState({
                showError: "Please specify a password.",
                success: false
            });
        break;
        case "contactNumberEmpty":
            this.setState({
                showError: "Please specify a contact number.",
                success: false
            });
        break;
        default:
            this.setState({
                showError: "Username taken! Please try another username.",
                success: false
            });
        break;
    }
  }

  _showSuccess() {
      this.setState({
          success: true,
          showError: ""
      })
  }

  updateFullName (event) {
    this.setState ({
      fullName: event.target.value,
    });
  }

  updateUsername (event) {
    this.setState ({
      username: event.target.value,
    });
  }

  updatePassword (event) {
    this.setState ({
      password: event.target.value,
    });
  }

  updateContactNumber (event) {
    this.setState ({
      contactNumber: event.target.value,
    });
  }

  render () {
    return (
      <div>
        <Button
          variant="outlined"
          color="primary"
          onClick={this._handleClickOpen}
        >
          Register (Customer)
        </Button>
        <Dialog
          open={this.state.setOpen}
          onClose={this._handleClose}
          aria-labelledby="form-dialog-title"
        >
          <DialogTitle id="form-dialog-title">
            Register as a tapao-er!
          </DialogTitle>
          <DialogContent>
            <DialogContentText>
              You're one step away from enjoying the convenience of food right at your doorstep!
            </DialogContentText>
            {this.state.showError ? <DialogContentText className="registrationError">{this.state.showError}</DialogContentText> : ""}
            {this.state.success ? <DialogContentText className="registrationSuccess">Registration success!</DialogContentText> : ""}
            <TextField
              autoFocus
              margin="dense"
              value={this.state.fullName}
              onChange={e => this.updateFullName (e)}
              id="fullname"
              label="Full Name"
              variant="outlined"
              inputProps={{ maxLength: 50 }}
              required
              fullWidth
            />
            <TextField
              margin="dense"
              value={this.state.username}
              onChange={e => this.updateUsername (e)}
              id="username"
              label="Username"
              variant="outlined"
              inputProps={{ maxLength: 50 }}
              required
              fullWidth
            />
            <TextField
              margin="dense"
              value={this.state.password}
              onChange={e => this.updatePassword (e)}
              id="password"
              label="Password"
              type="password"
              variant="outlined"
              inputProps={{ maxLength: 50 }}
              required
              fullWidth
            />
            <TextField
              margin="dense"
              value={this.state.contactNumber}
              onChange={e => this.updateContactNumber (e)}
              id="contact_number"
              label="Contact Number"
              type="tel"
              variant="outlined"
              required
              fullWidth
            />
          </DialogContent>
          <DialogActions>
            <Button onClick={this._handleClose} color="primary">
              Cancel
            </Button>
            <Button onClick={this._handleRegister} color="primary">
              Register
            </Button>
          </DialogActions>
        </Dialog>
      </div>
    );
  }
}
