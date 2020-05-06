import React, { Component } from 'react';
import { withStyles } from '@material-ui/core/styles';

// UI Components
import Drawer from '@material-ui/core/Drawer';
import AppBar from '@material-ui/core/AppBar';
import Toolbar from '@material-ui/core/Toolbar';
import List from '@material-ui/core/List';
import Typography from '@material-ui/core/Typography';
import Divider from '@material-ui/core/Divider';
import ListItem from '@material-ui/core/ListItem';

// Icons and Graphics
import ListItemIcon from '@material-ui/core/ListItemIcon';
import ListItemText from '@material-ui/core/ListItemText';
import ListIcon from '@material-ui/icons/ListAlt';
import ProfileIcon from '@material-ui/icons/AccountCircle';
import MonetizationOnIcon from '@material-ui/icons/MonetizationOn';
import CalendarIcon from '@material-ui/icons/Today';
import LogoutIcon from '@material-ui/icons/ExitToApp';

// Styles
import CssBaseline from '@material-ui/core/CssBaseline';
import '../css/user.css';

// Routing
import {Link as RouterLink, withRouter} from 'react-router-dom';
import * as apiRoute from '../../components/Api/route.js';
import Axios from 'axios';

// Subpages
import RiderProfile from './riderProfilePage';
import RiderOrders from './riderOrdersPage';
import RiderScheduler from './riderSchedulerPage';
import RiderStats from './riderStatsPage';

const drawerWidth = 240;

const styles = theme => ({
  root: {
    display: 'flex',
  },
  appBar: {
    width: `calc(100% - ${drawerWidth}px)`,
    marginLeft: drawerWidth,
  },
  drawer: {
    width: drawerWidth,
    flexShrink: 0,
  },
  drawerPaper: {
    width: drawerWidth,
  },
  // necessary for content to be below app bar
  toolbar: theme.mixins.toolbar,
  content: {
    flexGrow: 1,
    backgroundColor: theme.palette.background.default,
    padding: theme.spacing(0,0),
  },
});


class RiderPage extends Component {
    constructor(props) {
        super(props);
        this.state = {
            showProfilePage: false,
            showOrdersPage: true,
            showSchedulePage: false,
            showStatsPage: false
        };
        this.id = this.props.match.params.id;
        this.fetchUserData();

        this._handleOpenProfile = this._handleOpenProfile.bind(this)
        this._handleOpenOrders = this._handleOpenOrders.bind(this)
        this._handleOpenSchedule = this._handleOpenSchedule.bind(this)
        this._handleOpenStats = this._handleOpenStats.bind(this)
    }

    // Fetch rider information upon login
    fetchUserData() {
        // Get rider's details
        Axios.get(apiRoute.RIDER_API + "/" + this.id, {
            withCredentials: false,
        })
            .then (
                response => {
                    let { rid, 
                        rname, 
                        rusername,
                        rpassword,
                        rtotal_salary } = response.data
                    
                    // Add user details to state
                    this.setState({
                        rid: rid,
                        rname: rname,
                        rusername: rusername,
                        rpassword: rpassword,
                        rtotal_salary: rtotal_salary
                    }) 
                    
                }
            ).catch (error => {
                console.log("Error getting rider details!");
                console.log(error);
            });

        // Get if rider has set a schedule
        Axios.get(apiRoute.RIDER_API + "/scheduleSet/" + this.id, {
                withCredentials: false,
            })
                .then (
                    response => {
                        let scheduleStatus = response.data === 'scheduleSet' ? true : false 
                        // Add user details to state
                        this.setState({
                            scheduleSet: scheduleStatus,
                        })                         
                    }
                ).catch (error => {
                    console.log("Error getting rider details!");
                    console.log(error);
                });
    }


    /*
        Navigation handling
    */
    _handleOpenProfile() {
        console.log("Opening profile page")
        this.setState({
            showProfilePage: true,
            showOrdersPage: false,
            showSchedulePage: false,
            showStatsPage: false
        });
    }
    _handleOpenOrders() {
        console.log("Opening orders page")
        this.setState({
            showProfilePage: false,
            showOrdersPage: true,
            showSchedulePage: false,
            showStatsPage: false
        });
    }
    _handleOpenSchedule() {
        console.log("Opening scheduling page")
        this.setState({
            showProfilePage: false,
            showOrdersPage: false,
            showSchedulePage: true,
            showStatsPage: false
        });
    }

    _handleOpenStats() {
        console.log("Opening stats page")
        this.setState({
            showProfilePage: false,
            showOrdersPage: false,
            showSchedulePage: false,
            showStatsPage: true
        });
    }

    render() {
        const { classes }= this.props;

        return (
            <div className="pageContainer">
            <div className={classes.root}>
            <CssBaseline />
            <AppBar position="fixed" className={classes.appBar}>
                <Toolbar>
                <Typography variant="h6" noWrap>
                    {/* Conditional Title */}
                    Hello, {this.state.rname}!
                </Typography>
                </Toolbar>
            </AppBar>
            <Drawer
                className={classes.drawer}
                variant="permanent"
                classes={{
                paper: classes.drawerPaper,
                }}
                anchor="left"
            >
                <div className={classes.toolbar} />
                <Divider />
                <List>
                    <ListItem button key="Profile" onClick={this._handleOpenProfile}>
                        <ListItemIcon><ProfileIcon /></ListItemIcon>
                        <ListItemText primary="Profile" />
                    </ListItem>
                    <ListItem button key="Orders" onClick={this._handleOpenOrders}>
                        <ListItemIcon><ListIcon /></ListItemIcon>
                        <ListItemText primary="Orders" />
                    </ListItem> 
                    <ListItem button key="Schedule" onClick={this._handleOpenSchedule}>
                        <ListItemIcon><CalendarIcon /></ListItemIcon>
                        <ListItemText primary={"Schedule"} />
                    </ListItem>
                    <ListItem button key="Stats" onClick={this._handleOpenStats}>
                        <ListItemIcon><MonetizationOnIcon /></ListItemIcon>
                        <ListItemText primary={"Stats"} />
                    </ListItem>
                </List>
                <Divider />
                <List>
                    <ListItem button key="Logout" component={RouterLink} to="/"
                        onClick={this.props.unauthenticate}
                    >
                        <ListItemIcon><LogoutIcon /></ListItemIcon>
                        <ListItemText primary="Logout"/>
                    </ListItem>
                </List>
            </Drawer>
            <main className={classes.content}>
                <div className={classes.toolbar} />
                {/* Conditional iframe */}
                { !this.state.scheduleSet && "Schedule not set! Please set your schedule before fulfilling orders" }
                {/* PAGES */}
                { this.state.showProfilePage && <RiderProfile id={this.id} name={this.state.rname } username={this.state.rusername} password={this.state.rpassword} /> }
                { this.state.showOrdersPage && <RiderOrders id={this.id} /> }
                { this.state.showSchedulePage && <RiderScheduler id={this.id} /> }
                { this.state.showStatsPage && <RiderStats id={this.id} /> } 
            </main>
            </div>
            </div>
        );
    }
}

export default withStyles(styles, { withTheme: true })(withRouter(RiderPage));
