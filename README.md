<h1 align="center">tapau.</h1>
<p align="center">
	<a href = "#"><img src="https://img.shields.io/badge/Powered by-Caffeine-6f4e37?logo=Buy-Me-A-Coffee"></a>
	<a href = "https://github.com/CS2102-Team-51/main/blob/master/LICENSE"><img src="https://img.shields.io/badge/License-MIT-informational"></a>
</p>

A Food Delivery Service (FDS) mock up full stack application made in fulfillment of the Project component for NUS CS2102 AY19/20 S2.
  

## Preview :sparkles:

<img src="https://raw.githubusercontent.com/CS2102-Team-51/main/blob/master/preview/preview.png" alt="tapau." width="100%">

## Getting started :space_invader:

Currently this app only runs locally. The project structure is structured as three parts:
* src/ - Node.js Server to run API's for queries to the PostgreSQL server.
* server/ - React Frontend.
* Locally hosted PostgreSQL server.

To get our project up and running please clone the repository and follow the following steps:
### Installing all dependencies
- [Node.js](https://nodejs.org/en/)

### Getting the PostgreSQL server running
1. Please download the PostgreSQL 12.2 from [here](https://www.enterprisedb.com/downloads/postgres-postgresql-downloads), and follow the installer, during which please note down the password you used for your postgres superuser account.

2. Once installed, we need to create tapauDB which will be a PostgreSQL DB for us to store our applpication data. To do this open your terminal and enter the following commands:
    ```
    createdb -h localhost -p 5432 -u postgres tapauDB
    ```
    When prompted for your password, enter your postgres superuser account password.

3. Lastly, make sure you are in the directory of the cloned repository. Enter the following commands: 
    ```
    \i 'projectDDL(update here).sql'
    \i './server/sql/more_data.sql'
    ```
    This starts creating our schema, functions, triggers, and dummy data.

### Getting the backend configured for the PostgreSQL server:
1. Open up the `pool.js` file in server/config and change the user, host, port, database name if you have configured it differently.
2. Create a file called `keys.js` in the same file and insert the following line in:
    ```
    module.exports = {
        postgresPW: "<PASSWORD>",   
    }
    ```
    replacing \<PASSWORD\> with your postgres superuser password.
3. Save the file.

### Getting the Node.js server and React Front End to run:
1. While still in the server/ folder, run the command
    ```
    npm install
    ```
2. Once done, change your directory to the root project folder (main/) and repeat the same command. These 2 steps install all the npm packages we need to run the application.
3. Finally, enter the following command to run both the client and server simultaneously:
    ```
    npm run dev
    ```
4. Visiting localhost:3000 should display the mockup website.

### Other notes:
* The only current fixed FDS Manager account has the username of '`admin`' and a password of '`password`'.
* As of right now, the dummy data is incomplete. You will have to create users through registration or through direct insertion into the tables using psql to log in.

## License :pencil:

 This project is licensed under the MIT License - see the [LICENSE](https://github.com/CS2102-Team-51/main/blob/master/LICENSE) file for details.
