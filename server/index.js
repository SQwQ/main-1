const express = require ('express');
const cors = require ('cors');

// Generate a application that runs expressnpm
const app = express ();

// Middlewares
app.use (cors ()); // CORS is a node.js package to allow cross site request.
app.use (express.json ()); // express.json() is a method inbuilt in express to recognize the incoming Request Object as a JSON Object

// Setup route handling
const listingRoutes = require ('./routes/sampleCodes/listingRoutes.js');
const customerRoutes = require ('./routes/customers/customerRoutes.js');
const riderRoutes = require ('./routes/riders/riderRoutes.js');
const foodRoutes = require ('./routes/foods/foodRoutes.js');
const categoryRoutes = require ('./routes/foods/categoryRoutes.js');
const restaurantRoutes = require ('./routes/restaurants/restaurantRoutes.js');
const restaurantStaffRoutes = require ('./routes/restaurantStaffs/restaurantStaffRoutes.js');
const orderListRoutes = require ('./routes/orderLists/orderListRoutes.js');
const creditCardRoutes = require ('./routes/customers/creditCardRoutes.js');
app.use (listingRoutes);
app.use (customerRoutes);
app.use (riderRoutes);
app.use (foodRoutes);
app.use (categoryRoutes);
app.use (restaurantRoutes);
app.use (restaurantStaffRoutes);
app.use (orderListRoutes);
app.use (creditCardRoutes);

// Start server
const PORT = process.env.PORT || 5000;
app.listen (PORT, () => {
  console.log (`Server is now running on port ${PORT}...`);
});
