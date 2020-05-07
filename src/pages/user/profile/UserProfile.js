import React, { useEffect, useState } from 'react';
import * as apiRoute from '../../../components/Api/route.js';
import Axios from 'axios';
import { Link } from 'react-router-dom';
import { withRouter } from 'react-router'

// match.params = {rid, fid}
// userDetails = { cid, cname, ccontact_number, cusername, cpassword, cjoin_time, crewards_points }
function UserProfile({ match, userDetails, rewardPoints }) {
  const [pastOrders, setPastOrders] = useState([]);

  // Fetch data
  useEffect(() => {
      // fetch user's past orders
      Axios.get(apiRoute.GET_PAST_ORDER_API + '/' + match.params.userid)
      .then((res) => {
        setPastOrders(res.data);
      })
      .catch((error) => {
        console.log('Error getting user past orders food!');
        console.log(error);
      });

  }, []);

  function renderPastOrders() {
    let pastOrdersArray = []
    for (let i = 0; i < pastOrders.length; i++) {
      pastOrdersArray.push(
        <Link key={i} to={{pathname: `/profile/${match.params.userid}/order/${pastOrders[i].ocid}`, state: {pastOrderDetails: pastOrders[i]}}}>
            <p>order number: {pastOrders[i].ocid} | final price: {pastOrders[i].ofinal_price} | order time: {pastOrders[i].oorder_place_time} | order fulfiled: {pastOrders[i].oorder_arrives_customer == null ? "no" : "yes"}</p>
        </Link>
      )
    }
    return pastOrdersArray;
  }

  return (
    <div className="wrapper_content_section">
      <h1>userID: {userDetails.cid}</h1>
      <h1>customer name: {userDetails.cname}</h1>
      <h1>join time: {userDetails.cjoin_time}</h1>
      <h1>reward points: {rewardPoints}</h1>

      {/* Past orders */}
      <h1>A list of your past orders</h1>
      {renderPastOrders()}
    </div>
  );
}

export default withRouter(UserProfile);