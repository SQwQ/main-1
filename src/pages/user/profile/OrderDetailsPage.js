import React, { useEffect, useState } from 'react';
import * as apiRoute from '../../../components/Api/route.js';
import Axios from 'axios';

// match.params = {userid, ocid}
// reviewDetails = {rest_rating, review_text, ocid, rid, cid}
export default function OrderDetailsPage({ match, location }) {
  const [reviewDetails, setReviewDetails] = useState({});
  const [orderDetails, setOrderDetails] = useState({});
  const [rid, setRid] = useState(null);
  const [restRating, setRestRating] = useState(null);
  const [restReview, setRestReview] = useState(null);


  useEffect(() => {
    // Get order details from previous page
    setOrderDetails(location.state.pastOrderDetails);

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
    const newRestRating = {
        "rest_rating": restRating
    }

    Axios.patch(apiRoute.UPDATE_RATING + '/' + match.params.ocid, newRestRating)
    .then((res) => {
        setReviewDetails({...reviewDetails, rest_rating: restRating})
    })
    .catch((error) => {
      console.log('Error updating delivery rating!');
      console.log(error);
    });
  }

  function handleReviewRestaurant() {
    const newRestReview = {
        "review_text": restReview
    }

    console.log("newrestreview", newRestReview);

    Axios.patch(apiRoute.UPDATE_REVIEW + '/' + match.params.ocid, newRestReview)
    .then((res) => {
        setReviewDetails({...reviewDetails, review_text: restReview})
    })
    .catch((error) => {
      console.log('Error updating restaurant review rating!');
      console.log(error);
    });
  }

  function renderRatingsSection() {
    return (
      <>
        Your rating for the restaurant:{' '}
        {reviewDetails.rest_rating == null
          ? <div><h1>You have not rated the restaurant yet</h1><input onChange={e => setRestRating(parseInt(e.target.value))} type="number"/><button onClick={handleRateRider}>submit rating</button></div>
          : reviewDetails.rest_rating}
      </>
    );
  }

  function renderReviewSection() {
    return (
      <>
        <div>Your review for the restaurant's food:</div>
        {reviewDetails.review_text == "null"    
          ? <div><h1>You have not reviewed the restaurant's food yet</h1><input onChange={e => setRestReview(e.target.value)} type="text"/><button onClick={handleReviewRestaurant}>submit review</button></div>
          : reviewDetails.review_text}
      </>
    );
  }

  return (
    <div className="wrapper_content_section">
      <p>this is order detail page(can list all order details here, fetch data from list_order)</p>
      <p>order id: {match.params.ocid}</p>
      <p>restaurant id: {rid}</p>
      {renderRatingsSection()}
      {renderReviewSection()}
    </div>
  );
}
