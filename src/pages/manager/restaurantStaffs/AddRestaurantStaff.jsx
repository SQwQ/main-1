import React, {Component} from 'react';
import Button from '@material-ui/core/Button';
import TextField from '@material-ui/core/TextField';
import Dialog from '@material-ui/core/Dialog';
import DialogActions from '@material-ui/core/DialogActions';
import DialogContent from '@material-ui/core/DialogContent';
import DialogContentText from '@material-ui/core/DialogContentText';
import DialogTitle from '@material-ui/core/DialogTitle';
import Radio from '@material-ui/core/Radio';
import RadioGroup from '@material-ui/core/RadioGroup';
import {FormControlLabel} from '@material-ui/core';

import * as apiRoute from '../../../components/Api/route';
import Axios from 'axios';

export default class AddRestaurantStaff extends Component {
  constructor (props) {
    super (props);
    this.state = {
      success: false,
      rsname: '',
      rsposition: '',
      rsusername: '',
      rspassword: '',
      rid: this.props.rid,
    };

    this._handleClose = this._handleClose.bind (this);
    this._handleRegister = this._handleRegister.bind (this);
    this._showError = this._showError.bind (this);
    this._showSuccess = this._showSuccess.bind (this);
  }

  componentDidUpdate (prevProps) {
    if (this.props.setOpen !== prevProps.setOpen) {
      if (this.props.status === 'Edit') {
        console.log ('This is my staff: ', this.props.staff);
        console.log ('This is my staffName: ', this.props.staff[2]);
        this.setState ({
          rsname: this.props.staff[2],
          rsposition: this.props.staff[4],
          rsusername: this.props.staff[3],
        });
      }
    }
  }

  _handleClose = () => {
    this.setState ({
      success: false,
      showError: '',
      rsname: '',
      rsposition: '',
      rsusername: '',
      rspassword: '',
    });
    this.props.updateSetOpen (false);
  };

  _handleRegister = () => {
    // Check if unspecified or empty
    if (!this.state.rsname.trim ()) {
      this._showError ('nameEmpty');
      return;
    } else if (!this.state.rsposition.trim ()) {
      this._showError ('positionEmpty');
      return;
    } else if (!this.state.rsusername.trim ()) {
      this._showError ('usernameEmpty');
      return;
    } else if (
      this.props.status === 'Create' &&
      !this.state.rspassword.trim ()
    ) {
      this._showError ('passwordEmpty');
      return;
    }
    let restaurantStaff = {
      rsname: this.state.rsname.trim (),
      rsposition: this.state.rsposition.trim (),
      rsusername: this.state.rsusername.trim (),
      rspassword: this.state.rspassword.trim (),
      rid: this.state.rid,
    };
    console.log("This is my restaurantStaff: ", restaurantStaff);
    if (this.props.status === 'Create') {
      Axios.post (apiRoute.STAFF_API, restaurantStaff, {
        withCredentials: false,
      })
        .then (response => {
          console.log (response);
          this._showSuccess ();
          this.props.fetchRestaurantStaffs (this.state.rid);
        })
        .catch (error => {
          console.log (error);
          this._showError ('nameTaken');
        });
    } else {
      Axios.patch (apiRoute.STAFF_API + '/' + this.props.rid, restaurantStaff, {
        withCredentials: false,
      })
        .then (response => {
          console.log (response);
          this._showSuccess ();
          this.props.fetchRestaurantStaffs (this.state.rid);
        })
        .catch (error => {
          console.log (error);
          this._showError ('nameTaken');
        });
    }
  };

  _showError (errorStr) {
    switch (errorStr) {
      case 'nameEmpty':
        this.setState ({
          showError: 'Please specify a name.',
          success: false,
        });
        break;
      case 'positionEmpty':
        this.setState ({
          showError: 'Please specify a position.',
          success: false,
        });
        break;
      case 'usernameEmpty':
        this.setState ({
          showError: 'Please specify an username.',
          success: false,
        });
        break;
      case 'passwordEmpty':
        this.setState ({
          showError: 'Please specify a password.',
          success: false,
        });
        break;
      default:
        this.setState ({
          showError: 'Restaurant name taken! Please try another name.',
          success: false,
        });
        break;
    }
  }

  _showSuccess () {
    this.setState ({
      success: true,
      showError: '',
    });
  }

  updateRsname (event) {
    this.setState ({
      rsname: event.target.value,
    });
  }

  updateRsposition (event) {
    this.setState ({
      rsposition: event.target.value,
    });
  }

  updateRsusername (event) {
    this.setState ({
      rsusername: event.target.value,
    });
  }

  updateRspassword (event) {
    this.setState ({
      rspassword: event.target.value,
    });
  }

  render () {
    return (
      <div>
        <Dialog
          open={this.props.setOpen}
          onClose={this._handleClose}
          aria-labelledby="form-dialog-title"
          maxWidth="xl"
        >
          <DialogTitle id="form-dialog-title">
            {this.props.status === 'Create'
              ? 'Create a Restaurant Staff'
              : 'Edit Restaurant Staff Details'}
          </DialogTitle>

          <DialogContent>
            <DialogContentText>
              You're one step away from bringing happiness (and food) to thousands of others!
            </DialogContentText>
            {this.state.showError
              ? <DialogContentText className="registrationError">
                  {this.state.showError}
                </DialogContentText>
              : ''}
            {this.state.success && this.props.status === 'Create'
              ? <DialogContentText className="registrationSuccess">
                  Registration success!
                </DialogContentText>
              : ''}
            {this.state.success && this.props.status === 'Edit'
              ? <DialogContentText className="registrationSuccess">
                  Update success!
                </DialogContentText>
              : ''}
            <TextField
              autoFocus
              margin="dense"
              value={this.state.rsname}
              onChange={e => this.updateRsname (e)}
              id="fullname"
              label="Staff Name"
              variant="outlined"
              inputProps={{maxLength: 50}}
              required
              fullWidth
            />
            <TextField
              margin="dense"
              value={this.state.rsposition}
              onChange={e => this.updateRsposition (e)}
              id="position"
              label="Staff Position"
              variant="outlined"
              inputProps={{maxLength: 50}}
              required
              fullWidth
            />
            <TextField
              margin="dense"
              value={this.state.rsusername}
              onChange={e => this.updateRsusername (e)}
              id="username"
              label="Staff Username"
              variant="outlined"
              inputProps={{maxLength: 50}}
              required
              fullWidth
            />
            {this.props.status === "Create" ?
            <TextField
              margin="dense"
              value={this.state.rspassword}
              onChange={e => this.updateRspassword (e)}
              id="password"
              label="Staff Password"
              type="password"
              variant="outlined"
              inputProps={{maxLength: 50}}
              required
              fullWidth
            /> : null}

          </DialogContent>
          <DialogActions>
            <Button onClick={this._handleClose} color="primary">
              Cancel
            </Button>
            <Button onClick={this._handleRegister} color="primary">
              {this.props.status === 'Create' ? 'Register' : 'Update'}
            </Button>
          </DialogActions>
        </Dialog>
      </div>
    );
  }
}
