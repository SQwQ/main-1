import React, { Component } from 'react';
import './App.css';

import {BrowserRouter as Router, Route, Switch, Link, Redirect} from 'react-router-dom';

//Pages
import MainPage from "./pages/index";
import UserPage from "./pages/user";
import StaffPage from "./pages/staff";
import RiderPage from "./pages/rider";
import ManagerPage from "./pages/manager/manager";

class App extends Component {
    // componentDidMount() {
    //     fetch('https://localhost:3004/restaurants')
    //         .then(restaurants => this.setState(restaurants))
    // }

    render() {
        return (
            <Router>
                <Switch>
                    <Route exact path="/" component={MainPage}/>
                    <Route exact path="/user" component={UserPage}/>
                    <Route exact path="/staff" component={StaffPage}/>
                    <Route exact path="/rider" component={RiderPage}/>
                    <Route exact path="/manager" component={ManagerPage}/>
                </Switch>
            </Router>
        );
    }
}

export default App;
