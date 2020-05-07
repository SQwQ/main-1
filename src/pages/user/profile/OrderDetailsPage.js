import React, { useEffect, useState } from 'react';
import * as apiRoute from '../../../components/Api/route.js';
import Axios from 'axios';

// match.params = {userid, ocid}
// reviewDetails = {rest_rating, review_text, ocid, rid, cid}
export default function OrderDetailsPage({ match, location }) {
  const [reviewDetails, setReviewDetails] = useState({});
  const [foods, setFoods] = useState([]);
  const [orderDetails, setOrderDetails] = useState({});
  const [rid, setRid] = useState(null);
  const [restRating, setRestRating] = useState(null);
  const [restReview, setRestReview] = useState(null);


  useEffect(() => {
    // Get order details from previous page
    console.log(location.state.pastOrderDetails)
    setOrderDetails(location.state.pastOrderDetails);
    
    Axios.get(apiRoute.GET_FOODS_OF_ORDER + '/' + match.params.ocid)
      .then((res) => {
        console.log(res.data)
        setFoods(res.data);
      })
      .catch((error) => {
        console.log('Error getting food of the order!');
        console.log(error);
      });

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

  function renderFoodOrdered() {
    return foods.map(food => {
      return (
        <div key={food.fid}>
          <p><b>Food Name</b>: {food.fname}  <b>Quantity</b>: {food.quantity} <b>Price</b>: ${food.fprice}</p>
        </div>
        
      )
    });
  }


  function renderRatingsSection() {
    return (
      <>
        <h1>Your rating for the restaurant:</h1>
        {reviewDetails.rest_rating == null
          ? <div>You have not rated the restaurant yet  <input onChange={e => setRestRating(parseInt(e.target.value))} type="number"/><button onClick={handleRateRider}>submit rating</button></div>
          : reviewDetails.rest_rating}
      </>
    );
  }

  function renderReviewSection() {
    return (
      <>
        <h1>Your review for the restaurant's food:</h1>
        {reviewDetails.review_text == "null"    
          ? <div>You have not reviewed the restaurant's food yet  <input onChange={e => setRestReview(e.target.value)} type="text"/><button onClick={handleReviewRestaurant}>submit review</button></div>
          : reviewDetails.review_text}
      </>
    );
  }

  return (
    <div className="wrapper_content_section">
      <p><b>Order ID</b>: {match.params.ocid}</p>
      <p><b>Restaurant ID</b>: {rid}</p>
      <p><b>Order Placed at</b>: {orderDetails.oorder_place_time}</p>
      <p><b>Payment Type</b>: {orderDetails.opayment_type}</p>
      {renderFoodOrdered()}
      <p><b>Delivery Fee</b>: ${orderDetails.odelivery_fee}</p>
      <p><b>Total Price</b>: ${orderDetails.ofinal_price}</p>
      
      
      
      {renderRatingsSection()}<br/>
      {renderReviewSection()}
    </div>
  );
}
