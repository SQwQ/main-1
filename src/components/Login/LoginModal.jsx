import React, {Component} from 'react';
import { withRouter } from 'react-router-dom';
import Button from '@material-ui/core/Button';
import TextField from '@material-ui/core/TextField';
import Dialog from '@material-ui/core/Dialog';
import DialogActions from '@material-ui/core/DialogActions';
import DialogContent from '@material-ui/core/DialogContent';
import DialogTitle from '@material-ui/core/DialogTitle';

import * as apiRoute from '../Api/route.js';
import Axios from 'axios';
import { DialogContentText } from '@material-ui/core';

import './LoginModal.css';

class LoginModal extends Component {
  constructor (props) {
    super (props);
    this.state = {
      setOpen: false,
      showInvalidCredentialsWarning: false,
      showConnectionErrorWarning: false
    };

    //this._handleChange = this._handleChange.bind(this);
    this._handleClickOpen = this._handleClickOpen.bind (this);
    this._handleClose = this._handleClose.bind (this);
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

  _handleClickOpen = () => {
    this.setState({
        setOpen: true,
        showInvalidCredentialsWarning: false
    });
  };

  _handleClose = () => {
    this.setState({
        setOpen: false,
        showInvalidCredentialsWarning: false,
        showConnectionErrorWarning: false
    });
  };

  handleLogin(route, user) {
    Axios.post(route, user, {
        withCredentials: false,
    })
        .then (
            response => {
                console.log(response.data)
                if (response.data.cid == null && response.data.rid == null && response.data.rsid ==null && response.data.fmid == null) {
                    console.log(this.state.title + " credentials not recognized!");
                    this.showInvalidCredentials();
                } else {
                    console.log(this.state.title + " with userID " + response.data.cid + " logged in.");
                    // 1. Set states for id, auth and close dialog
                    

                    // 2. Push history (set states first before pushing history:
                    // https://stackoverflow.com/a/57572888)
                    if (response.data.cid) {
                        this.setState({id: response.data.cid});
                        this.props.authenticate();
                        this.setState ({setOpen: false});
                        this.handleLink("user");
                    } else if (response.data.rid) {
                        this.setState({id: response.data.rid});
                        this.props.authenticate();
                        this.setState ({setOpen: false});
                        this.handleLink("rider");
                    } else if (response.data.rsid) {
                        this.setState({id: response.data.rsid});
                        this.props.authenticate();
                        this.setState ({setOpen: false});
                        this.handleLink("staff");
                    } else {
                        this.setState({id: response.data.fmid});
                        this.props.authenticate();
                        this.setState ({setOpen: false});
                        this.handleLink("manager");
                    }
                }
            }
        ).catch (error => {
            this.showConnectionError();
            console.log(error);
        });
  };

  _handleSubmit = () => {
    let user = {
        username: this.state.username,
        password: this.state.password,
        type: this.state.title
    };

    // Debugging : print user login details
    console.log("Login attempt with details", user)

    this.handleLogin(apiRoute.CUSTOMER_LOGIN_API, user);
  };

  showConnectionError() {
        this.setState({
            showConnectionErrorWarning: true,
            showInvalidCredentialsWarning: false
        });
  }

  showInvalidCredentials() {
      this.setState({
            showInvalidCredentialsWarning: true,
            showConnectionErrorWarning: false
        });
  }

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
            {this.state.showInvalidCredentialsWarning && 
                <DialogContentText className="invalidWarning">
                    Wrong username/password!
                </DialogContentText>
            }
            {this.state.showConnectionErrorWarning && 
                <DialogContentText className="connectionWarning">
                    Failed to get a connection to the server!
                </DialogContentText>
            }
          <DialogContent>
            <TextField
              margin="dense"
              value={this.state.username || ''}
              onChange={e => this.updateUsername (e)}
              id="username"
              label="Username"
              variant="outlined"
              onKeyPress={(ev) => {
                  if (ev.key === 'Enter') {
                      this._handleSubmit()
                  }
              }}
              required
              fullWidth
            />
            <TextField
              margin="dense"
              value={this.state.password || ''}
              onChange={e => this.updatePassword (e)}
              id="password"
              label="Password"
              type="password"
              variant="outlined"
              onKeyPress={(ev) => {
                if (ev.key === 'Enter') {
                    this._handleSubmit()
                }
              }}
              required
              fullWidth
            />
          </DialogContent>
          <DialogActions>
            <Button onClick={this._handleClose} color="primary">
              Cancel
            </Button>
            <Button onClick={this._handleSubmit} color="primary">
              Login
            </Button>
          </DialogActions>
        </Dialog>
      </div>
    );
  }
}

export default withRouter(LoginModal);
