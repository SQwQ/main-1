import React, {useState} from 'react';
import {BrowserRouter as Router, Route, Switch} from 'react-router-dom';
import {withStyles} from '@material-ui/core/styles';

// Styles
import CssBaseline from '@material-ui/core/CssBaseline';
import '../css/user.css';

// Routing
import * as apiRoute from '../../components/Api/route.js';
import Axios from 'axios';
import SideBar from './SideBar';

// Subpages
import HomePage from './home/HomePage';
import Food from './food/Food';
import {useEffect} from 'react';

const drawerWidth = 240;
const styles = theme => ({
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
  toolbar: theme.mixins.toolbar,
});

function StaffPage({match, classes, unauthenticate}) {
  const [id, setId] = useState ();
  const [userDetails, setUserDetails] = useState ({});
  const [restaurantDetails, setRestaurantDetails] = useState ({});

  useEffect (() => {
    setId (match.params.id);
    console.log ('Getting my staff. This is my staffId: ', match.params.id);
    Axios.get (apiRoute.STAFF_API + '/' + match.params.id, {
      withCredentials: false,
    })
      .then (res => {
        console.log ('This is my response: ', res.data);
        setUserDetails (res.data);
        Axios.get (apiRoute.GET_RESTAURANT_API + '/' + res.data.rid, {
          withCredentials: false,
        })
          .then (res => {
            console.log ('This is my restaurant response: ', res.data);
            setRestaurantDetails (res.data);
          })
          .catch (error => {
            console.log ('Error getting restaurant details!');
            console.log (error);
          });
      })
      .catch (error => {
        console.log ('Error getting customer details!');
        console.log (error);
      });
  }, []);

  function getRestaurantDetails () {
    console.log ('This is my userDetails: ', userDetails);
    Axios.get (apiRoute.GET_RESTAURANT_API + '/' + userDetails.rid, {
      withCredentials: false,
    })
      .then (res => {
        setRestaurantDetails (res.data);
      })
      .catch (error => {
        console.log ('Error getting restaurant details!');
        console.log (error);
      });
  }

  return (
    <div className="pageContainer">
      <div className={classes.root}>
        <Router>
          <SideBar
            classes={classes}
            userid={id}
            unauthenticate={unauthenticate}
          />
          <CssBaseline />
          <Switch>
            <Route
              exact
              path="/staff/:id"
              render={() => (
                <HomePage
                  userid={id}
                  rsname={userDetails.rsname}
                  restaurantDetails={restaurantDetails}
                />
              )}
            />
            <Route
              exact
              path="/staffs/food"
              render={() => <Food restaurantDetails={restaurantDetails} />}
            />
            {/* <Route exact path='/profile/:userid' render={() => <UserProfile userDetails={userDetails} rewardPoints={rewardPoints} /> } />
              <Route exact path='/profile/:userid/order/:ocid' component={OrderDetailsPage} />
              <Route exact path='/restaurant/reviews/:rid' component={RestaurantReviewsPage} /> */}
          </Switch>
        </Router>
      </div>
    </div>
  );
}

export default withStyles (styles, {withTheme: true}) (StaffPage);
