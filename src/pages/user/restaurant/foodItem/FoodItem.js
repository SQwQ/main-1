import React from 'react';
import "./foodItem.css"

export default function FoodItem({foodName, incrementFoodCount, favailable, fprice, flimit, fimage, categoryName}) {
  return (
    <div className="wrapper_food_item flex_food_item">
      <p className="food_name_text">{foodName}</p>
      <p className="food_price_text">${fprice}</p>
      <p className="category_text">{categoryName}</p>
      <p className="food_avail_text">{favailable ? "Available" : "Sold out"}</p>
      <button className="add_to_card_btn" onClick={incrementFoodCount} disabled={!favailable} >Add to cart</button>
    </div>
  );
}
