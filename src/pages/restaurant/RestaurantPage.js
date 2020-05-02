import React, { useEffect, useState } from 'react';
import * as apiRoute from '../../components/Api/route.js';
import Axios from 'axios';

// match = {rid, fid}
// restaurantDetails = { rid, rname, raddress, rmincost, rimage }
export default function RestaurantPage({ match }) {
  const [foodItems, setFoodItems] = useState([]);
  const [restaurantDetails, setRestaurantDetails] = useState([]);

  // Fetch data
  useEffect(() => {
    // fetch all restaurant food
    Axios.get(apiRoute.GET_RESTAURANT_FOOD_API + '/' + match.params.rid)
      .then((res) => {
        setFoodItems(res.data);
      })
      .catch((error) => {
        console.log('Error getting all restaurant food!');
        console.log(error);
      });

    // fetch restaurant details
    Axios.get(apiRoute.GET_RESTAURANT_API + '/' + match.params.rid)
      .then((res) => {
        setRestaurantDetails(res.data);
      })
      .catch((error) => {
        console.log('Error getting all restaurant food!');
        console.log(error);
      });

    // fetch clicked food data here(if needed)
  }, []);

  function renderFoodItems() {
    return foodItems.map((foodItem) => (
      <div key={foodItem.fid}>
        <p>Food id: {foodItem.fid} Food name: {foodItem.fname}</p>
        <button>add to cart</button>
      </div>
    ));
  }

  return (
    <div>
      <h1>This is the restaurant page</h1>
      {/* examples of restaurant details rendered out */}
      <h1>restaurant id: {match.params.rid}</h1>
      <h1>restaurant name: {restaurantDetails.rname}</h1>
      <h1>restaurant address: {restaurantDetails.raddress}</h1>

      {/* examples of clicked food details rendered out */}
      <h1>clicked food id: {match.params.fid}</h1>

      {/* all food items sold by restaurant */}
      {renderFoodItems()}
    </div>
  );
}
