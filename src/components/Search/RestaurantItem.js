import React from 'react';
import { Link } from 'react-router-dom';

// result = {rid, raddress, rmincost, rname, rimage, fid, fname, fprice, favailable, flimit, fimage}
export default function RestaurantItem({ result, userId }) {
  return (
    <Link to={`/restaurant/${result.rid}/${result.fid}/${userId}`}>
      <h1>
        Restaurant Name: {result.rname}, Food Name: {result.fname}
      </h1>
    </Link>
  );
}
