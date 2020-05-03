import React, { useEffect, useState } from 'react';
import * as apiRoute from '../../components/Api/route.js';
import Axios from 'axios';

// match.params = {rid, fid}
// restaurantDetails = { rid, rname, raddress, rmincost, rimage }
// foodItems = [{ fid, fname, fprice, favailable, flimit, fimage, rid }, {..}]
export default function RestaurantPage({ match }) {
  const [foodItems, setFoodItems] = useState([]);
  const [restaurantDetails, setRestaurantDetails] = useState([]);
  const [foodCount, setFoodCount] = useState([]);

  // Fetch data
  useEffect(() => {
    // fetch all restaurant food
    Axios.get(apiRoute.GET_RESTAURANT_FOOD_API + '/' + match.params.rid)
      .then((res) => {
        setFoodItems(res.data);
        let countArray = new Array(res.data.length)
        countArray.fill(0)
        setFoodCount(countArray);
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
        console.log('Error getting restaurant details!');
        console.log(error);
      });

    // fetch clicked food data here(like outline clicked food or smthg if got time)
  }, []);

  function renderFoodItems() {
    let foodItemsArray = [];
    for (let i = 0; i < foodItems.length; i++) {
      foodItemsArray.push(
        <div key={foodItems[i].fid}>
          <p>Food id: {foodItems[i].fid} Food name: {foodItems[i].fname}</p>
          <button onClick={() => {foodCount[i] += 1; setFoodCount([...foodCount]);}} >add to cart</button>
        </div>
      );
    }
    return foodItemsArray;
  }

  function renderCartItems() {
    let cartArray = [];
    for (let i = 0; i < foodItems.length; i++) {
      cartArray.push(
        <div key={i}>
          <p>food id: {foodItems[i].fid} count: {foodCount[i]}</p>
        </div>
      );
    }
    return cartArray;
  }

  function handleOrder() {
    const foodIdArray = foodItems.map(foodItem => foodItem.fid);
    const foodPriceArray = foodItems.map(foodItem => parseFloat(foodItem.fprice));
    console.log(foodIdArray)
    console.log(foodPriceArray)
    console.log(foodCount)


    const details = {
      "oorder_enroute_restaurant" : null,
      "oorder_arrives_restaurant" : null,
      "oorder_enroute_customer" : null,
      "oorder_arrives_customer" : null,
      "odelivery_fee" : 5,
      "ofinal_price" : 5,
      "opayment_type" : null,
      "orating" : 7,
      "ostatus" : null,
      "foodIdArray" : foodIdArray,
      "foodPriceArray": foodPriceArray,
      "foodCountArray" : foodCount
    }

    // make api request to create order
    Axios.post(apiRoute.CREATE_ORDER_API + '/' + match.params.rid + '/' + match.params.userId, details)
      .then((res) => {
        console.log("successful!")
        alert("Database updated");
      })
      .catch((error) => {
        console.log('Error creating an order!');
        console.log(error);
      });
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
      <h1>Menu</h1>
      {renderFoodItems()}

      <h1>Your cart:</h1>
      {renderCartItems()}
      <button onClick={handleOrder}>Order Now!</button>
    </div>
  );
}
