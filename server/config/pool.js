const { Pool } = require('pg');
const keys = require('./keys');

// Get current environment
const env = process.env.NODE_ENV || 'development';

// DEBUG
env === 'development' ? console.log("Development environment detected.") 
    : console.log("Production environment detected.")

let connectionString = env === 'development' ? {
    user: 'postgres',
    password: keys.postgresPW,
    host: 'localhost',
    port: '5432',
    database: 'mytestdb',
    max: 10,
    idleTimeoutMillis: 300,
    connectionTimeoutMillis: 200
} : {
    connectionString: process.env.DATABASE_URL,
    ssl: true
};

// Create pool to communicate with database
module.exports = new Pool(connectionString);