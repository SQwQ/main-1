import React from 'react';
import { makeStyles } from '@material-ui/core/styles';
import Drawer from '@material-ui/core/Drawer';
import CssBaseline from '@material-ui/core/CssBaseline';
import AppBar from '@material-ui/core/AppBar';
import Toolbar from '@material-ui/core/Toolbar';
import List from '@material-ui/core/List';
import Typography from '@material-ui/core/Typography';
import Divider from '@material-ui/core/Divider';
import ListItem from '@material-ui/core/ListItem';
import ListItemIcon from '@material-ui/core/ListItemIcon';
import ListItemText from '@material-ui/core/ListItemText';
import MailIcon from '@material-ui/icons/Mail';
import banner from '../images/food.jpeg';
import ProfileIcon from '@material-ui/icons/AccountCircle';
import MonetizationOnIcon from '@material-ui/icons/MonetizationOn';
import LogoutIcon from '@material-ui/icons/ExitToApp';
import './css/user.css';

import {Link as RouterLink} from 'react-router-dom';

const drawerWidth = 240;
const samplePoints = 999;

const useStyles = makeStyles(theme => ({
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
}));

export default function PermanentDrawerLeft() {
  const classes = useStyles();
  
  return (
    <div className={classes.root}>
      <CssBaseline />
      <AppBar position="fixed" className={classes.appBar}>
        <Toolbar>
          <Typography variant="h6" noWrap>
            tapau. User Menu
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
            <ListItem button key="Profile">
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
                <ListItemText primary="Points" />
            </ListItem>
            <ListItem button key="Logout" component={RouterLink} to="/">
                <ListItemIcon><LogoutIcon /></ListItemIcon>
                <ListItemText primary="Logout"/>
            </ListItem>
        </List>
      </Drawer>
      <main className={classes.content}>
        <div className={classes.toolbar} />
        <img className="banner" src={banner} alt="banner" />
        <div className="mainContent">
            <Typography variant="h2">
            Hungry?
            </Typography>
            {/* Search Bar */}

            {/* Card List */}
        </div>
      </main>
    </div>
  );
}
