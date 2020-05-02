import React from 'react';
import { Link } from 'react-router-dom';

// result = {rid, raddress, rmincost, rname, rimage, fid, fname, fprice, favailable, flimit, fimage}
// TODO: design the restaurant item
export default function RestaurantItem({ result }) {
  return (
    <Link to={`/restaurant/${result.rid}/${result.fid}`}>
      <h1>
        Restaurant Name: {result.rname}, Food Name: {result.fname}
      </h1>
    </Link>
  );
}
