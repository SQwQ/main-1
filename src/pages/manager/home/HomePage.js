import React, { Component } from 'react';

import AppBar from '@material-ui/core/AppBar';
import Toolbar from '@material-ui/core/Toolbar';
import Typography from '@material-ui/core/Typography';

import { withStyles } from '@material-ui/core/styles';
const drawerWidth = 240;

const styles = (theme) => ({
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
    padding: theme.spacing(0, 0),
  },
});

class MainPage extends Component {
  constructor(props) {
    super(props);
  }

  render() {
    return (
      <>
        <AppBar position='fixed' className={this.props.classes.appBar}>
          <Toolbar>
            <Typography variant='h6' noWrap>
              {/* Conditional Title */}
              Welcome, {this.props.cname}!
            </Typography>
          </Toolbar>
        </AppBar>

        <main className={this.props.classes.content}>
          <div className={this.props.classes.toolbar} />
          {/* Conditional iframe */}
        </main>
      </>
    );
  }
}

export default withStyles(styles, { withTheme: true })(MainPage);
