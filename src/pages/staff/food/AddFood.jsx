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
    this._showSuccess = this._showSuccess.bind (this);
  }

  componentDidMount () {}

  componentDidUpdate (prevProps) {
    if (this.props.setOpen !== prevProps.setOpen) {
      console.log ('This is my status: ', this.props.status);
      console.log ('This is my food: ', this.props.singleFood);
      if (this.props.status === 'Edit') {
        this.setState ({
          fname: this.props.singleFood[3],
          fprice: this.props.singleFood[4],
          favailable: this.props.singleFood[2],
          flimit: this.props.singleFood[2],
        });
      }
    }
  }

  _handleClose = () => {
    this.setState ({
      success: false,
      showError: '',
      fname: '',
      fprice: '',
      favailable: '',
      flimit: '',
    });
    this.props.updateSetOpen (false);
  };

  _handleRegister = () => {
    let food = {
      fname: this.state.fname.trim (),
      fprice: this.state.fprice.trim (),
      favailable: this.state.favailable.trim (),
      flimit: this.state.flimit.trim (),
    };
    if (this.props.status === 'Create') {
      Axios.post (apiRoute.FOOD_API + '/post/' + this.props.rid, food, {
        withCredentials: false,
      })
        .then (response => {
          console.log (response);
          this._showSuccess ();
          this.props.fetchFood ();
        })
        .catch (error => {
          console.log (error);
        });
    } else {
      Axios.put (
        apiRoute.FOOD_API + '/update/' + this.props.singleFood.fid + '/' + this.props.rid,
        food,
        {
          withCredentials: false,
        }
      )
        .then (response => {
          console.log (response);
          this._showSuccess ();
          this.props.fetchFood ();
        })
        .catch (error => {
          console.log (error);
          this._showError ('nameTaken');
        });
    }
  };

  _showSuccess () {
    this.setState ({
      success: true,
      showError: '',
    });
  }

  updateFname (event) {
    this.setState ({
      fname: event.target.value,
    });
  }

  updateFprice (event) {
    this.setState ({
      fprice: event.target.value,
    });
  }

  updateFavailable (event) {
    this.setState ({
      favailable: event.target.value,
    });
  }

  updateFlimit (event) {
    this.setState ({
      flimit: event.target.value,
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
              value={this.state.fname}
              onChange={e => this.updateFname (e)}
              id="fullname"
              label="Food Name"
              variant="outlined"
              inputProps={{maxLength: 50}}
              required
              fullWidth
            />
            <TextField
              margin="dense"
              value={this.state.fprice}
              onChange={e => this.updateFprice (e)}
              id="username"
              label="Food Price"
              type="number"
              variant="outlined"
              inputProps={{maxLength: 50}}
              required
              fullWidth
            />
            <TextField
              margin="dense"
              value={this.state.favailable}
              onChange={e => this.updateFavailable (e)}
              id="password"
              label="Food Availability (true or false)"
              type="boolean"
              variant="outlined"
              inputProps={{maxLength: 50}}
              required
              fullWidth
            />
            <TextField
              margin="dense"
              value={this.state.flimit}
              onChange={e => this.updateFlimit (e)}
              id="password"
              label="Food Limit"
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
              {this.props.status === 'Create' ? 'Create' : 'Update'}
            </Button>
          </DialogActions>
        </Dialog>
      </div>
    );
  }
}
