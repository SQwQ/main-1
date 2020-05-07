import React, {useState} from 'react';
import {BrowserRouter as Router, Route, Switch} from 'react-router-dom';
import {withStyles} from '@material-ui/core/styles';

// Styles
import CssBaseline from '@material-ui/core/CssBaseline';
import '../css/user.css';

// Routing
import * as apiRoute from '../../components/Api/route.js';
import Axios from 'axios';
import ManagerSidebar from './ManagerSidebar';

// Subpages
import Restaurants from './restaurants/Restaurants';
import RestaurantStaffs from './restaurantStaffs/RestaurantStaffs';
import HomePage from './home/HomePage';
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

function ManagerPage({match, classes, unauthenticate}) {
  const [id, setId] = useState ();
  const [userDetails, setUserDetails] = useState ({});

  useEffect (() => {
    setId (match.params.id);

    Axios.get (apiRoute.MANAGER_API + '/' + match.params.id, {
      withCredentials: false,
    })
      .then (res => {
        console.log ('This is my manager data: ', res.data);
        setUserDetails (res.data);
      })
      .catch (error => {
        console.log ('Error getting customer details!');
        console.log (error);
      });
  }, []);

  return (
    <div className="pageContainer">
      <div className={classes.root}>
        <Router>
          <ManagerSidebar
            classes={classes}
            userid={id}
            unauthenticate={unauthenticate}
          />
          <CssBaseline />
          <Switch>
            <Switch>
              <Route exact path="/manager/:id" component={Restaurants} />
              {/* <Route
                exact
                path="/manager/:id"
                render={() => (
                  <HomePage userid={id} cname={userDetails.mname} />
                )}
              /> */}
              <Route
                exact
                path="/manager/restaurant/:id"
                component={RestaurantStaffs}
              />
            </Switch>
          </Switch>
        </Router>
      </div>
    </div>
  );
}

export default withStyles (styles, {withTheme: true}) (ManagerPage);
