import React from 'react';

// UI Components
import Drawer from '@material-ui/core/Drawer';
import List from '@material-ui/core/List';
import Divider from '@material-ui/core/Divider';
import ListItem from '@material-ui/core/ListItem';

// Routing
import { Link } from 'react-router-dom';

// Icons and Graphics
import ListItemIcon from '@material-ui/core/ListItemIcon';
import ListItemText from '@material-ui/core/ListItemText';
import MailIcon from '@material-ui/icons/Mail';
import ProfileIcon from '@material-ui/icons/AccountCircle';
import MonetizationOnIcon from '@material-ui/icons/MonetizationOn';
import LogoutIcon from '@material-ui/icons/ExitToApp';

export default function SideBar({classes, userid, rewardPoints, unauthenticate}) {
  return (
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
                <ListItem button key="Back" component={Link} to={`/user/${userid}`} >
                    <b>HOME</b>
                </ListItem>
                <ListItem button key="Profile" component={Link} to={`/profile/${userid}`} >
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
                <ListItemText primary={rewardPoints + " Reward Point(s)"} />
            </ListItem>
            <ListItem button key="Logout" component={Link} to="/"
                onClick={unauthenticate}
            >
                <ListItemIcon><LogoutIcon /></ListItemIcon>
                <ListItemText primary="Logout"/>
            </ListItem>
        </List>
    </Drawer>
  );
}
