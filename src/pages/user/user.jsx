import React, { Component } from 'react';
import { BrowserRouter as Router, Route, Switch } from 'react-router-dom';
import { withStyles } from '@material-ui/core/styles';

// Styles
import CssBaseline from '@material-ui/core/CssBaseline';
import '../css/user.css';

// Routing
import * as apiRoute from '../../components/Api/route.js';
import Axios from 'axios';
import SideBar from './SideBar';

// Subpages
import RestaurantPage from "./restaurant/RestaurantPage";
import HomePage from "./home/HomePage";
import UserProfile from "./profile/UserProfile";
import OrderDetailsPage from "./profile/OrderDetailsPage";


const drawerWidth = 240;
const styles = (theme) => ({
  root: {
    display: 'flex',
  },
  drawer: {
    width: drawerWidth,
    flexShrink: 0,
  },
  drawerPaper: {
    width: drawerWidth,
  },
  // necessary for content to be below app bar
  toolbar: theme.mixins.toolbar
});

class UserPage extends Component {
  constructor(props) {
    super(props);
    this.state = {};
    this.id = this.props.match.params.id;
    this.fetchUserData();
  }

  // Fetch user information upon login
  fetchUserData() {
    Axios.get(apiRoute.CUSTOMER_API + '/' + this.id, {
      withCredentials: false,
    })
      .then((response) => {
        let {
          cname,
          ccontact_number,
          crewards_points,
          cusername,
          cpassword,
          cjoin_time,
        } = response.data;

        // Add user details to state
        this.setState({
          cname: cname,
          ccontact_number: ccontact_number,
          crewards_points: crewards_points,
          cusername: cusername,
          cpassword: cpassword,
          cjoin_time: cjoin_time,
        });
      })
      .catch((error) => {
        console.log('Error getting customer details!');
        console.log(error);
      });
  }

  render() {

    return (
      <div className='pageContainer'>
        <div className={this.props.classes.root}>
          <Router>
              <SideBar
                classes={this.props.classes}
                userid={this.id}
                rewardPoints={this.state.crewards_points}
                unauthenticate={this.props.unauthenticate}
              />
              <CssBaseline />
              <Switch>
                <Route exact path='/user/:id' render={() => <HomePage userid={this.id} cname={this.state.cname} /> } />
                <Route exact path='/restaurant/:rid/:fid/:userId' render={() => <RestaurantPage incrementRewardPoints={(points) => {
                   this.setState({
                    crewards_points: this.state.crewards_points + points,
                  });
                }} />} />
                <Route exact path='/profile/:userid' component={UserProfile} />
                <Route exact path='/profile/:userid/order/:ocid' component={OrderDetailsPage} />
              </Switch>
          </Router>
        </div>
      </div>
    );
  }
}

export default withStyles(styles, { withTheme: true })(UserPage);
