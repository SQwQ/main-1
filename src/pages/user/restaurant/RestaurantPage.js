import React, { useEffect, useState } from 'react';
import * as apiRoute from '../../../components/Api/route.js';
import Axios from 'axios';
import FoodItem from "./foodItem/FoodItem"
import CartItem from "./CartItem"
import { withRouter } from 'react-router'
import "./restaurantPage.css"

// match.params = {rid, fid}
// restaurantDetails = { rid, rname, raddress, rmincost, rimage }
// foodItems = [{ fid, fname, fprice, favailable, flimit, fimage, rid }, {..}]
function RestaurantPage({ match, incrementRewardPoints }) {
  const [foodItems, setFoodItems] = useState([]);
  const [restaurantDetails, setRestaurantDetails] = useState([]);
  const [foodCounts, setFoodCount] = useState([]);
  const [totalFoodCost, setTotalFoodCost] = useState(0);
  const [deliveryFee] = useState(5);

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

  useEffect(() => {
    console.log("calculate total cost")
    setTotalFoodCost(calculateTotalCost())
  }, [foodCounts]);

  function calculateTotalCost() {
    let totalFoodCost = 0;
    for (let i = 0; i < foodCounts.length; i++) {
      totalFoodCost += (foodCounts[i] * foodItems[i].fprice)
    }
    return totalFoodCost;
  }

  function renderFoodItems() {
    let foodItemsArray = [];
    for (let i = 0; i < foodItems.length; i++) {
      foodItemsArray.push(
        <FoodItem 
          key={i} 
          favailable={foodItems[i].favailable} 
          fprice={foodItems[i].fprice} 
          flimit={foodItems[i].flimit} 
          fimage={foodItems[i].fimage} 
          foodName={foodItems[i].fname}
          incrementFoodCount={() => {
            foodCounts[i] += 1;
            setFoodCount([...foodCounts]);
          }}
        />
      );
    }
    return foodItemsArray;
  }

  function renderCartItems() {
    let cartArray = [];
    for (let i = 0; i < foodItems.length; i++) {
      // If user has not added to cart, do not show it in cart section
      if (foodCounts[i] != 0) {
        cartArray.push(
          <CartItem 
            key={i} 
            foodName={foodItems[i].fname} 
            foodCount={foodCounts[i]}
          />
        );
      }
    }
    // If cart section is not empty, display it
    return cartArray.length == 0 ? <p>Your cart is empty.</p> : cartArray;
  }

  function handleOrder() {
    let finalCost = totalFoodCost + deliveryFee
    if (finalCost < restaurantDetails.rmincost) {
      alert(`Your order needs to be a minimum of $${restaurantDetails.rmincost} before proceeding.\n` +
            `You need to spend $${restaurantDetails.rmincost - (totalFoodCost + deliveryFee)} more.`);
      return;
    }
    const foodIdArray = foodItems.map(foodItem => foodItem.fid);
    const foodPriceArray = foodItems.map(foodItem => parseFloat(foodItem.fprice));

    const newOrderDetails = {
      "oorder_enroute_restaurant" : null,
      "oorder_arrives_restaurant" : null,
      "oorder_enroute_customer" : null,
      "oorder_arrives_customer" : null,
      "odelivery_fee" : 5,
      "ofinal_price" : finalCost,
      "opayment_type" : null,
      "orating" : 7,
      "ostatus" : null,
      "foodIdArray" : foodIdArray,
      "foodPriceArray": foodPriceArray,
      "foodCountArray" : foodCounts
    }

    // make api request to create order and update reward points
    Axios.post(apiRoute.CREATE_ORDER_API + '/' + match.params.rid + '/' + match.params.userId, newOrderDetails)
      .then((res) => {
        incrementRewardPoints(finalCost)
        console.log("successful!")
        alert("Database updated");
      })
      .catch((error) => {
        console.log('Error creating an order!');
        console.log(error);
      });
  }

  return (
    <div className="wrapper_content_section ">
        {/* examples of restaurant details rendered out */}
        <h1>(to remove after testing) clicked food id: {match.params.fid}</h1>
        <h1>(to remove after testing) restaurant id: {match.params.rid}</h1>
        <h1>{restaurantDetails.rname}</h1>

        {/* Menu */}
        <h1>Our Menu</h1>
        <div className="flex_food_container">
          {renderFoodItems()}
        </div>

        <h1>Your cart:</h1>
        {renderCartItems()}
        <p>Delivery Charge: ${deliveryFee}</p>
        <p>Food Cost: ${totalFoodCost}</p>
        <p>Total: ${totalFoodCost + deliveryFee}</p>
        <button onClick={handleOrder}>Order Now!</button>
    </div>
  );
}


export default withRouter(RestaurantPage);