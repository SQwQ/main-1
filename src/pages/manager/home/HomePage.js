import React, {Component} from 'react';
import {Row, Col, Card, Button} from 'react-bootstrap';
import AppBar from '@material-ui/core/AppBar';
import Toolbar from '@material-ui/core/Toolbar';
import Typography from '@material-ui/core/Typography';
import {createMuiTheme, MuiThemeProvider} from '@material-ui/core/styles';
import MUIDataTable from 'mui-datatables';
import * as apiRoute from '../../../components/Api/route';
import Axios from 'axios';
import restaurantPicture from '../../../images/restaurant.jpg';

import {withStyles} from '@material-ui/core/styles';
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
    padding: theme.spacing (0, 0),
  },
});

class MainPage extends Component {
  constructor (props) {
    super (props);
  }
  state = {
    monthlyNewCustomers: 0,
    monthlyTotalOrders: 0,
    monthlyTotalOrderCost: 0,
  };

  componentDidMount () {
    this.calculateNewCustomers ();
  }

  calculateNewCustomers () {
    console.log(apiRoute.MANAGER_API + 's/newCustomers');
    Axios.get (apiRoute.MANAGER_API + 's/newCustomers', {
      withCredentials: false,
    })
      .then (res => {
        console.log ('These are my number of new customers: ', res.data);
        this.setState ({
          monthlyNewCustomers: res.data,
        });
      })
      .catch (error => {
        console.log (error);
      });
  }

  calculateTotalOrder () {
    console.log(apiRoute.MANAGER_API + 's/orders');
    Axios.get (apiRoute.MANAGER_API + 's/orders', {
      withCredentials: false,
    })
      .then (res => {
        console.log ('These are my number of orders: ', res.data);
        this.setState ({
          monthlyTotalOrders: res.data,
        });
      })
      .catch (error => {
        console.log (error);
      });
  }

  render () {
    return (
      <div>
        <AppBar position="fixed" className={this.props.classes.appBar}>
          <Toolbar>
            <Typography variant="h6" noWrap>
              {/* Conditional Title */}
              Dashboard Data Summary
            </Typography>
          </Toolbar>
        </AppBar>

        <main className={this.props.classes.content}>
          <div className={this.props.classes.toolbar} />
        </main>
        <Row>
          <Card style={{margin: 'auto', float: 'none', marginBottom: '10px'}}>
            <Card.Body>
              <Row>
                <p>Monthly New Customers: {this.state.monthlyNewCustomers}</p>
                <p>Monthly Orders: {this.state.monthlyTotalOrders}</p>
                <p>Monthly Orders Cost: {this.state.monthlyTotalOrderCost}</p>
              </Row>
            </Card.Body>
          </Card>
        </Row>
      </div>
    );
  }
}

export default withStyles (styles, {withTheme: true}) (MainPage);
