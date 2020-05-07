import React, { useState } from 'react';
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
import RestaurantReviewsPage from "./restaurant/reviews/RestaurantReviewsPage";
import { useEffect } from 'react';

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

function UserPage({match, classes, unauthenticate}) {
  const [id, setId] = useState();
  const [userDetails, setUserDetails] = useState({});
  const [rewardPoints, setRewardPoints] = useState(0);


  useEffect(() => {
    setId(match.params.id);

    Axios
    .get(apiRoute.CUSTOMER_API + '/' + match.params.id, {withCredentials: false})
    .then((res) => {
      setUserDetails(res.data);
      setRewardPoints(res.data.crewards_points);
    })
    .catch((error) => {
      console.log('Error getting customer details!');
      console.log(error);
    });

  }, []);

  return (
    <div className='pageContainer'>
      <div className={classes.root}>
        <Router>
            <SideBar
              classes={classes}
              userid={id}
              rewardPoints={rewardPoints}
              unauthenticate={unauthenticate}
            />
            <CssBaseline />
            <Switch>
              <Route exact path='/user/:id' render={() => <HomePage userid={id} cname={userDetails.cname} /> } />
              <Route exact path='/restaurant/:rid/:fid/:userId' render={() => <RestaurantPage incrementRewardPoints={(points) => setRewardPoints(rewardPoints + points)} />} />
              <Route exact path='/profile/:userid' render={() => <UserProfile userDetails={userDetails} rewardPoints={rewardPoints} /> } />
              <Route exact path='/profile/:userid/order/:ocid' component={OrderDetailsPage} />
              <Route exact path='/restaurant/reviews/:rid' component={RestaurantReviewsPage} />
            </Switch>
        </Router>
      </div>
    </div>
  );
}

export default withStyles(styles, { withTheme: true })(UserPage);
