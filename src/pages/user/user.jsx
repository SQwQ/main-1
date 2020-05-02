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
import MailIcon from '@material-ui/icons/Mail';
import ProfileIcon from '@material-ui/icons/AccountCircle';
import MonetizationOnIcon from '@material-ui/icons/MonetizationOn';
import LogoutIcon from '@material-ui/icons/ExitToApp';

// Styles
import CssBaseline from '@material-ui/core/CssBaseline';
import '../css/user.css';

// Routing
import {Link as RouterLink, withRouter} from 'react-router-dom';
import * as apiRoute from '../../components/Api/route.js';
import Axios from 'axios';

// Subpages
import UserRestaurantSearch from './userRestaurantSearch';

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


class UserPage extends Component {
    constructor(props) {
        super(props);
        this.state = {};
        this.id = this.props.match.params.id;
        this.fetchUserData();
    }

    // Fetch user information upon login
    fetchUserData() {
        Axios.get(apiRoute.CUSTOMER_API + "/" + this.id, {
            withCredentials: false,
        })
            .then (
                response => {
                    let { cname, 
                        ccontact_number, 
                        crewards_points,
                        cusername,
                        cpassword,
                        cjoin_time } = response.data
                    
                    // Add user details to state
                    this.setState({
                        cname: cname,
                        ccontact_number: ccontact_number,
                        crewards_points: crewards_points,
                        cusername: cusername,
                        cpassword: cpassword,
                        cjoin_time: cjoin_time
                    }) 
                    
                }
            ).catch (error => {
                console.log("Error getting customer details!");
                console.log(error);
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
                    Hungry, {this.state.cname}? Have your meal delivered to you.
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
                    <ListItem button key="Profile"component={RouterLink} to={`/profile/${this.id}`} >
                        <ListItemIcon><ProfileIcon /></ListItemIcon>
                        <ListItemText primary="Profile" />
                    </ListItem>
                    <ListItem button key="Vouchers">
                        <ListItemIcon><MailIcon /></ListItemIcon>
                        <ListItemText primary="Vouchers" />
                    </ListItem>
                </List>
                <Divider />
                <List>
                    <ListItem key="Reward_Points">
                        <ListItemIcon><MonetizationOnIcon /></ListItemIcon>
                        <ListItemText primary={this.state.crewards_points + " Reward Point(s)"} />
                    </ListItem>
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

                {/* ORDER PAGE */}
                <UserRestaurantSearch userId={this.id} />
            </main>
            </div>
            </div>
        );
    }
}

export default withStyles(styles, { withTheme: true })(withRouter(UserPage));
