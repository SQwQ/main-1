const express = require ('express');
const cors = require ('cors');

// Generate a application that runs expressnpm
const app = express ();

// Middlewares
app.use (cors ()); // CORS is a node.js package to allow cross site request.
app.use (express.json ()); // express.json() is a method inbuilt in express to recognize the incoming Request Object as a JSON Object

// Setup route handling
const listingRoutes = require ('./routes/sampleCodes/listingRoutes');
const customerRoutes = require ('./routes/customers/customerRoutes');
const foodRoutes = require ('./routes/foods/foodRoutes');
const categoryRoutes = require ('./routes/foods/categoryRoutes');
const restaurantRoutes = require ('./routes/restaurants/restaurantRoutes');
const restaurantStaffRoutes = require ('./routes/restaurantStaffs/restaurantStaffRoutes');
const orderListRoutes = require ('./routes/orderLists/orderListRoutes');
const creditCardRoutes = require ('./routes/customers/creditCardRoutes');
const riderRoutes = require('./routes/riders/riderRoutes');
const partTimerRoutes = require('./routes/riders/partTimerRoutes');
const fullTimerRoutes = require('./routes/riders/fullTimerRoutes');
const promotionRoutes = require('./routes/promotions/promotionRoutes');
app.use (listingRoutes);
app.use (customerRoutes);
app.use (riderRoutes);
app.use (foodRoutes);
app.use (categoryRoutes);
app.use (restaurantRoutes);
app.use (restaurantStaffRoutes);
app.use (orderListRoutes);
app.use (creditCardRoutes);
app.use(riderRoutes);
app.use(partTimerRoutes);
app.use(fullTimerRoutes);
app.use(promotionRoutes);

// Start server
const PORT = process.env.PORT || 5000;
app.listen (PORT, () => {
  console.log (`Server is now running on port ${PORT}...`);
});
