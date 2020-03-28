import React, {Component} from 'react';
import {Modal} from 'react-bootstrap';
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
import ScheduleSelector from 'react-schedule-selector';

export default class RiderRegisterForm extends Component {
  constructor () {
    super ();
    this.state = {
      //schedule: [],
      setOpen: false,
    };

    //this._handleChange = this._handleChange.bind(this);
    this._handleClickOpen = this._handleClickOpen.bind (this);
    this._handleClose = this._handleClose.bind (this);
    this._handleLogin = this._handleLogin.bind (this);
    this._handleSubmit = this._handleSubmit.bind (this);
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

  // _handleChange = newSchedule => {
  //     this.setState({ schedule: newSchedule })
  // }

  _handleClickOpen = () => {
    this.setState ({setOpen: true});
  };

  _handleClose = () => {
    this.setState ({setOpen: false});
  };

  _handleLogin = () => {
    this.setState ({setOpen: false});
  };

  _handleSubmit = () => {
    if (this.state.title === 'Customer') {
        
    } else if (this.state.title === 'Rider') {

    } else if (this.state.title === 'Staff') {

    } else if (this.state.title === 'Manager') {

    }
  };

  handleLink (reroute) {
    this.props.history.push ({
      pathname: `/${reroute}/` + this.state.id,
    });
  }

  render () {
    return (
      <div>
        <div>
          <Button
            variant="contained"
            color="primary"
            onClick={() => this.setState ({setOpen: true, title: 'Customer'})}
          >
            Customer
          </Button>
          <Button
            variant="contained"
            color="primary"
            onClick={() => this.setState ({setOpen: true, title: 'Rider'})}
          >
            Delivery Rider
          </Button>
          <Button
            variant="contained"
            color="primary"
            onClick={() => this.setState ({setOpen: true, title: 'Staff'})}
          >
            Restaurant Staff
          </Button>
          <Button
            variant="contained"
            color="primary"
            onClick={() => this.setState ({setOpen: true, title: 'Manager'})}
          >
            FDS Manager
          </Button>
        </div>

        <Dialog
          open={this.state.setOpen}
          onClose={this._handleClose}
          aria-labelledby="form-dialog-title"
        >
          <DialogTitle id="form-dialog-title">
              <p>{this.state.title} Login</p>
          </DialogTitle>
          <DialogContent>
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
          </DialogContent>
          <DialogActions>
            <Button onClick={this._handleClose} color="primary">
              Cancel
            </Button>
            <Button onClick={this._handleLogin} color="primary">
              Login
            </Button>
          </DialogActions>
        </Dialog>
      </div>
    );
  }
}
