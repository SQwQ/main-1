const express = require('express');
const cors = require("cors");

// Generate a application that runs expressnpm
const app = express();

// Middlewares
app.use(cors()); // CORS is a node.js package to allow cross site request.
app.use(express.json()); // express.json() is a method inbuilt in express to recognize the incoming Request Object as a JSON Object

// Setup route handling
const listingRoutes = require('./routes/sampleCodes/listingRoutes.js');
const customerRoutes = require('./routes/customerRoutes.js');
app.use(listingRoutes);
app.use(customerRoutes);


// Start server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server is now running on port ${PORT}...`);
});