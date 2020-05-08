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

export default class AddRestaurant extends Component {
  constructor () {
    super ();
    this.state = {
      success: false,
      rname: '',
      raddress: '',
      rmincost: '',
    };

    this._handleClose = this._handleClose.bind (this);
    this._handleRegister = this._handleRegister.bind (this);
    this._showError = this._showError.bind (this);
    this._showSuccess = this._showSuccess.bind (this);
  }

  componentDidMount () {}

  componentDidUpdate (prevProps) {
    if (this.props.setOpen !== prevProps.setOpen) {
      console.log ('This is my status: ', this.props.status);
      console.log ('This is my restaurant: ', this.props.restaurant);
      if (this.props.status === 'Edit') {
        this.setState ({
          rname: this.props.restaurant[2],
          raddress: this.props.restaurant[3],
          rmincost: this.props.restaurant[4],
        });
      }
    }
  }

  _handleClose = () => {
    this.setState ({
      success: false,
      showError: '',
      rname: '',
      raddress: '',
      rmincost: '',
    });
    this.props.updateSetOpen (false);
  };

  _handleRegister = () => {
    // Check if unspecified or empty
    if (!this.state.rname.trim ()) {
      this._showError ('nameEmpty');
      return;
    } else if (!this.state.raddress.trim ()) {
      this._showError ('addressEmpty');
      return;
    } else if (!this.state.rmincost.trim ()) {
      this._showError ('minCostEmpty');
      return;
    }

    let restaurant = {
      rname: this.state.rname.trim (),
      raddress: this.state.raddress.trim (),
      rmincost: this.state.rmincost.trim (),
    };
    if (this.props.status === 'Create') {
      Axios.post (apiRoute.GET_RESTAURANT_API, restaurant, {
        withCredentials: false,
      })
        .then (response => {
          console.log (response);
          this._showSuccess ();
          this.props.fetchRestaurants ();
        })
        .catch (error => {
          console.log (error);
          this._showError ('nameTaken');
        });
    } else {
      Axios.put (apiRoute.GET_RESTAURANT_API + '/' + this.props.rid, restaurant, {
        withCredentials: false,
      })
        .then (response => {
          console.log (response);
          this._showSuccess ();
          this.props.fetchRestaurants ();
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
      case 'addressEmpty':
        this.setState ({
          showError: 'Please specify an address.',
          success: false,
        });
        break;
      case 'minCostEmpty':
        this.setState ({
          showError: 'Please specify a minCost.',
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

  updateRname (event) {
    this.setState ({
      rname: event.target.value,
    });
  }

  updateRaddress (event) {
    this.setState ({
      raddress: event.target.value,
    });
  }

  updateRmincost (event) {
    this.setState ({
      rmincost: event.target.value,
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
              ? 'Register a Restaurant'
              : 'Edit a Restaurant'}
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
              value={this.state.rname}
              onChange={e => this.updateRname (e)}
              id="fullname"
              label="Restaurant Name"
              variant="outlined"
              inputProps={{maxLength: 50}}
              required
              fullWidth
            />
            <TextField
              margin="dense"
              value={this.state.raddress}
              onChange={e => this.updateRaddress (e)}
              id="username"
              label="Address"
              variant="outlined"
              inputProps={{maxLength: 50}}
              required
              fullWidth
            />
            <TextField
              margin="dense"
              value={this.state.rmincost}
              onChange={e => this.updateRmincost (e)}
              id="password"
              label="Min Cost"
              type="number"
              variant="outlined"
              inputProps={{maxLength: 50}}
              required
              fullWidth
            />

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
