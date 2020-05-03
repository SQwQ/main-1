import React, { useEffect, useState } from 'react';
import * as apiRoute from '../../components/Api/route.js';
import Axios from 'axios';

// match.params = {userid, ocid}
// reviewDetails = {rest_rating, review_text, ocid, rid, cid}
export default function OrderDetailsPage({ match }) {
  const [reviewDetails, setReviewDetails] = useState({});
  const [rid, setRid] = useState(null);
  const [restDeliveryRating, setRestDeliveryRating] = useState(null);

  useEffect(() => {
    // Fetch order review
    Axios.get(apiRoute.GET_ORDER_REVIEW_AND_RATING + '/' + match.params.ocid)
      .then((res) => {
        setReviewDetails(res.data);
        setRid(res.data.rid);
      })
      .catch((error) => {
        console.log('Error getting all ratings and reviews!');
        console.log(error);
      });
  }, []);


  function handleRateRider() {
    const newRestDeliveryRating = {
        "rest_rating": restDeliveryRating
    }

    Axios.patch(apiRoute.UPDATE_RATING + '/' + match.params.ocid, newRestDeliveryRating)
    .then((res) => {
        setReviewDetails({...reviewDetails, rest_rating: restDeliveryRating})
    })
    .catch((error) => {
      console.log('Error updating delivery rating!');
      console.log(error);
    });
  }

  function renderReviewSection() {
    return (
      <>
        Your rating:{' '}
        {reviewDetails.rest_rating == null
          ? <div><h1>You have not rated the delivery service yet</h1><input onChange={e => setRestDeliveryRating(parseInt(e.target.value))} type="number"/><button onClick={handleRateRider}>submit</button></div>
          : reviewDetails.rest_rating}
      </>
    );
  }

  return (
    <div>
      <p>this is order detail page</p>
      <p>order id: {match.params.ocid}</p>
      <p>restaurant id: {rid}</p>
      {renderReviewSection()}
    </div>
  );
}
