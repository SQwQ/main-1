import React from 'react';

// foodItems = [{ fid, fname, fprice, favailable, flimit, fimage, rid }, {..}]
export default function CartItem({foodName, foodCount}) {
  return (
    <div>
      <p>
        food id: {foodName} X{foodCount}
      </p>
    </div>
  );
}
