import React, { useEffect, useState } from 'react';
import * as apiRoute from '../../../../components/Api/route.js';
import Axios from 'axios';
import ReviewItem from '../reviews/ReviewItem';
import { withRouter } from 'react-router';
import './restaurantReviewPage.css';


// match.params = {rid}
// reviewDetails = [{rest_rating, review_text, ocid, rid, cid}, {..}]
function RestaurantReviewsPage({ match }) {
  const [reviewDetails, setReviewDetails] = useState([]);

  useEffect(() => {
    // Fetch order review
    Axios.get(apiRoute.GET_ALL_ORDER_REVIEW_AND_RATING + '/' + match.params.rid)
      .then((res) => {
        console.log(res.data);
        setReviewDetails(res.data);
      })
      .catch((error) => {
        console.log('Error getting all ratings and reviews!');
        console.log(error);
      });
  }, []);

  function renderUserReviews() {
    return reviewDetails.map((reviewDetail) => {
        if(reviewDetail.review_text == "null" & reviewDetail.rest_rating == null) {
          return;
        }
        return <ReviewItem key={reviewDetail.ocid} reviewDetail={reviewDetail} />
    });
  }

  return (
    <div className='wrapper_content_section '>
      <b>Our Reviews</b>
      <div className="reviews_flex_container">{renderUserReviews()}</div>
    </div>
  );
}

export default withRouter(RestaurantReviewsPage);
