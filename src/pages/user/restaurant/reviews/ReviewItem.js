import React from 'react';
import "./reviewItem.css"

// reviewDetails = {rest_rating, review_text, ocid, rid, cid}
export default function ReviewItem({ reviewDetail }) {


  return (
    <div className="wrapper_review_item">
      <p>Reviewer: <b>{reviewDetail.cid}</b></p>
      {reviewDetail.rest_rating == null ? "" : <p>Restaurant rating: {reviewDetail.rest_rating}</p>}
      {reviewDetail.review_text == "null" ? "" : <p>{reviewDetail.review_text}</p>}
    </div>
  );
}
