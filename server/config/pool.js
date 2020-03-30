const { Pool } = require('pg');
//const keys = require('./keys');

// Create pool to communicate with database
module.exports = new Pool({
  // TODO: change to environment variable before deployment
  user: 'postgres',
  password: 'password',//keys.postgresPW,
  host: 'localhost',
  port: '5432',
  database: 'mytestdb',
  max: 10,
  idleTimeoutMillis: 300,
  connectionTimeoutMillis: 200
});

/*
const initOptions = {
  // global event notification;
  error(error, e) {
      if (e.cn) {
          // A connection-related error;
          //
          // Connections are reported back with the password hashed,
          // for safe errors logging, without exposing passwords.
          console.log('CN:', e.cn);
          console.log('EVENT:', error.message || error);
      }
  }
};

const pgp = require('pg-promise')(initOptions);

// using an invalid connection string:
const db = pgp('postgresql://postgres:password@localhost:5432/mytestdb');

db.connect()
  .then(obj => {
      // Can check the server version here (pg-promise v10.1.0+):
      const serverVersion = obj.client.serverVersion;
      console.log('CONNECTED!');
      //obj.done(); // success, release the connection;
  })
  .catch(error => {
      console.log('ERROR:', error.message || error);
  });*/