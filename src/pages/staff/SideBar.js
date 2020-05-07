import React from 'react';

// UI Components
import Drawer from '@material-ui/core/Drawer';
import List from '@material-ui/core/List';
import Divider from '@material-ui/core/Divider';
import ListItem from '@material-ui/core/ListItem';

// Routing
import {Link} from 'react-router-dom';

// Icons and Graphics
import ListItemIcon from '@material-ui/core/ListItemIcon';
import ListItemText from '@material-ui/core/ListItemText';
import MailIcon from '@material-ui/icons/Mail';
import ProfileIcon from '@material-ui/icons/AccountCircle';
import MonetizationOnIcon from '@material-ui/icons/MonetizationOn';
import LogoutIcon from '@material-ui/icons/ExitToApp';

export default function SideBar({
  classes,
  userid,
  rewardPoints,
  unauthenticate,
}) {
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
        <ListItem button key="Back" component={Link} to={`/staff/${userid}`}>
          <b>HOME</b>
        </ListItem>
        <ListItem
          button
          key="Food"
          component={Link}
          to={`/staffs/food`}
        >
          <ListItemIcon><ProfileIcon /></ListItemIcon>
          <ListItemText primary="Food" />
        </ListItem>
        {/* <ListItem button key="Vouchers">
          <ListItemIcon><MailIcon /></ListItemIcon>
          <ListItemText primary="Vouchers" />
        </ListItem> */}
      </List>
      <Divider />
      <List>
        <ListItem
          button
          key="Logout"
          component={Link}
          to="/"
          onClick={unauthenticate}
        >
          <ListItemIcon><LogoutIcon /></ListItemIcon>
          <ListItemText primary="Logout" />
        </ListItem>
      </List>
    </Drawer>
  );
}
