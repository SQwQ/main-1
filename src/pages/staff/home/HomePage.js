import React, {Component} from 'react';

import AppBar from '@material-ui/core/AppBar';
import Toolbar from '@material-ui/core/Toolbar';
import Typography from '@material-ui/core/Typography';
import TextField from '@material-ui/core/TextField';
import {Row, Col, Card, Button, Form} from 'react-bootstrap';

import * as apiRoute from '../../../components/Api/route';
import Axios from 'axios';

import {withStyles} from '@material-ui/core/styles';
const drawerWidth = 240;

const styles = theme => ({
  root: {
    display: 'flex',
  },
  appBar: {
    width: `calc(100% - ${drawerWidth}px)`,
    marginLeft: drawerWidth,
  },
  drawer: {
    width: drawerWidth,
    flexShrink: 0,
  },
  drawerPaper: {
    width: drawerWidth,
  },
  // necessary for content to be below app bar
  toolbar: theme.mixins.toolbar,
  content: {
    flexGrow: 1,
    backgroundColor: theme.palette.background.default,
    padding: theme.spacing (0, 0),
  },
});

class MainPage extends Component {
  constructor (props) {
    super (props);
    this.state = {
      edit: false,
      rname: '',
      raddress: '',
      rmincost: '',
    };
  }

  componentDidMount () {
    console.log (
      'These are my restaurant details: ',
      this.props.restaurantDetails
    );
    this.setState ({
      rname: this.props.restaurantDetails.rname,
      raddress: this.props.restaurantDetails.raddress,
      rmincost: this.props.restaurantDetails.rmincost,
    });
  }

  componentDidUpdate (prevProps) {
    if (this.props.restaurantDetails !== prevProps.restaurantDetails) {
      console.log ('This is my restaurant: ', this.props.restaurantDetails);
      this.setState ({
        rname: this.props.restaurantDetails.rname,
        raddress: this.props.restaurantDetails.raddress,
        rmincost: this.props.restaurantDetails.rmincost,
      });
    }
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

  setEdit (value) {
    this.setState ({
      edit: value,
    });
  }

  _handleRegister = () => {
    // Check if unspecified or empty
    if (!this.state.rname.trim ()) {
      return;
    } else if (!this.state.raddress.trim ()) {
      return;
    } else if (!this.state.rmincost.trim ()) {
      return;
    }

    let restaurant = {
      rname: this.state.rname.trim (),
      raddress: this.state.raddress.trim (),
      rmincost: this.state.rmincost.trim (),
    };
    Axios.put (apiRoute.GET_RESTAURANT_API + '/' + this.props.restaurantDetails.rid, restaurant, {
      withCredentials: false,
    })
      .then (response => {
        console.log (response);
        this._showSuccess ();
        this.props.fetchRestaurants ();
        this.setEdit (false);
      })
      .catch (error => {
        console.log (error);
      });
  };

  render () {
    return (
      <div>
        <AppBar position="fixed" className={this.props.classes.appBar}>
          <Toolbar>
            <Typography variant="h6" noWrap>
              {/* Conditional Title */}
              Welcome, {this.props.rsname}!
            </Typography>
          </Toolbar>
        </AppBar>

        <main className={this.props.classes.content}>
          <div className={this.props.classes.toolbar} />
        </main>
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
          disabled={this.state.edit ? false : true}
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
          disabled={this.state.edit ? false : true}
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
          disabled={this.state.edit ? false : true}
        />
        {this.state.edit
          ? <Button onClick={this._handleClose} color="primary">
              Cancel
            </Button>
          : null}
        {this.state.edit
          ? <Button onClick={this._handleRegister} color="primary">
              Update
            </Button>
          : <Button onClick={() => this.setEdit (true)} color="primary">
              Edit
            </Button>}
      </div>
    );
  }
}

export default withStyles (styles, {withTheme: true}) (MainPage);
