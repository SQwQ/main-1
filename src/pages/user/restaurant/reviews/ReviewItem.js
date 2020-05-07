import React, { useEffect, useState } from 'react';
import "./reviewItem.css"
import * as apiRoute from '../../../../components/Api/route.js';
import Axios from 'axios';

// reviewDetails = {rest_rating, review_text, ocid, rid, cid}
export default function ReviewItem({ reviewDetail }) {
  const [cname, setCName] = useState("");
  useEffect(() => {
    // Get customer's details
    Axios
    .get(apiRoute.CUSTOMER_API + '/' + reviewDetail.cid, {withCredentials: false})
    .then((res) => {
      console.log(res.data)
      setCName(res.data.cname)
    })
    .catch((error) => {
      console.log('Error getting customer details!');
      console.log(error);
    });
  }, [])


  return (
    <div className="wrapper_review_item">
      <p>Reviewer: <b>{cname}</b></p>
      {reviewDetail.rest_rating == null ? "" : <p>Restaurant rating: {reviewDetail.rest_rating}</p>}
      {reviewDetail.review_text == "null" ? "" : <p>{reviewDetail.review_text}</p>}
    </div>
  );
}
