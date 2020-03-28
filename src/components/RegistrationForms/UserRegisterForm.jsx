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
      fullName: '',
      username: '',
      password: '',
      contactNumber: '',
    };

    this._handleClickOpen = this._handleClickOpen.bind (this);
    this._handleClose = this._handleClose.bind (this);
    this._handleRegister = this._handleRegister.bind (this);
  }

  _handleClickOpen = () => {
    this.setState ({setOpen: true});
  };

  _handleClose = () => {
    this.setState ({setOpen: false});
  };

  _handleRegister = () => {
    let joinTime = moment(new Date()).format('YYYY-MM-DD');
    console.log ('This is my joinTime: ', joinTime);
    let user = {
      cname: this.state.fullName,
      cusername: this.state.username,
      cpassword: this.state.password,
      ccontact_number: parseInt(this.state.contactNumber),
      cjoin_time: joinTime,
      crewards_points: 1,
    };
    Axios.post (apiRoute.CUSTOMER_API, user, {
      withCredentials: false,
    })
      .then (response => {
        console.log (response);
      })
      .catch (error => {
        console.log (error);
      });
    this.setState ({setOpen: false});
  };

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
            <TextField
              autoFocus
              margin="dense"
              value={this.state.fullName}
              onChange={e => this.updateFullName (e)}
              id="fullname"
              label="Full Name"
              variant="outlined"
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
              required
              fullWidth
            />
            <TextField
              margin="dense"
              value={this.state.contactNumber}
              onChange={e => this.updateContactNumber (e)}
              id="contact_number"
              label="Contact Number"
              type="number"
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
