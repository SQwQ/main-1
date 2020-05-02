import React, { useEffect, useState } from 'react';
import * as apiRoute from '../../components/Api/route.js';
import Axios from 'axios';

// match.params = {rid, fid}
// userDetails = { cid, cname, ccontact_number, cusername, cpassword, cjoin_time, crewards_points }
export default function UserProfile({ match }) {
  const [userDetails, setUserDetails] = useState([]);

  // Fetch data
  useEffect(() => {
    // fetch user details
    Axios.get(apiRoute.GET_CUSTOMER_DETAIL_API + '/' + match.params.userid)
      .then((res) => {
        setUserDetails(res.data);
      })
      .catch((error) => {
        console.log('Error getting all restaurant food!');
        console.log(error);
      });
  }, []);

  return (
    <div>
      <h1>userID: {userDetails.cid}</h1>
      <h1>customer name: {userDetails.cname}</h1>
      <h1>join time: {userDetails.cjoin_time}</h1>
      <h1>reward points: {userDetails.crewards_points}</h1>
    </div>
  );
}
