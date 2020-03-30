import React, { Component } from 'react';
import './App.css';

import {BrowserRouter as Router, Route, Switch, Redirect} from 'react-router-dom';

//Pages
import MainPage from "./pages/index";
import UserPage from "./pages/user";
import StaffPage from "./pages/staff";
import RiderPage from "./pages/rider";
import ManagerPage from "./pages/manager/manager";

// PrivateRoute to implement trivial auth with callbacks
const PrivateRoute = ({ component: Component, 
                        authenticateState: authenticated,
                        authenticate: authenticateCallback,
                        unauthenticate: unauthenticateCallback,
                         ...rest }) => (
    <Route {...rest} render={(props) => (
        authenticated === true
            ?   <Component {...props} 
                authenticate={authenticateCallback} 
                unauthenticate={unauthenticateCallback}
                />
            :   <Redirect to='/' />
    )}/>
);

class App extends Component {
    constructor(props) {
        super(props);
        this.state = {
            isAuthenticated: false
        }

        this.setAuth = this.setAuth.bind(this)
        this.setUnAuth = this.setUnAuth.bind(this)
    }

    setAuth() {
        console.log("Authenticated!")
        this.setState({ isAuthenticated: true });
    }

    setUnAuth() {
        console.log("Un-Authenticated!")
        this.setState({ isAuthenticated: false });
    }
    
    render() {
        return (
            <Router>
                <Switch>
                    {/* Non-private main page with auth callbacks */}
                    <Route exact 
                        path="/"
                        render={(props) => (
                            <MainPage {...props}
                            authenticate={this.setAuth} 
                            unauthenticate={this.setUnAuth}
                            />
                        )}
                    />
                    {/* Private pages for different user groups */}
                    <PrivateRoute exact path="/user/:id" component={UserPage} 
                        authenticateState={this.state.isAuthenticated}
                        authenticate={this.setAuth}
                        unauthenticate={this.setUnAuth}
                        />
                    <PrivateRoute exact path="/staff/:id" component={StaffPage} 
                        authenticateState={this.state.isAuthenticated}
                        authenticate={this.setAuth}
                        unauthenticate={this.setUnAuth}
                        />
                    <PrivateRoute exact path="/rider/:id" component={RiderPage} 
                        authenticateState={this.state.isAuthenticated}
                        authenticate={this.setAuth}
                        unauthenticate={this.setUnAuth}
                        />
                    <PrivateRoute exact path="/manager/:id" component={ManagerPage} 
                        authenticateState={this.state.isAuthenticated}
                        authenticate={this.setAuth}
                        unauthenticate={this.setUnAuth}
                        />
                </Switch>
            </Router>
        );
    }
}

export default App;
