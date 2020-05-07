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
import AddRestaurant from './AddRestaurant';

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

class Restaurants extends Component {
  constructor (props) {
    super (props);
  }
  state = {
    restaurants: [],
    restaurant: [],
    setOpen: false,
    rid: null,
    status: '',
    columns: [
      {
        name: 'rid',
        label: 'Id',
        options: {
          filter: false,
          sort: false,
        },
      },
      {
        name: 'rimage',
        label: 'Image',
        options: {
          filter: true,
          sort: true,
          customBodyRender: (value, tableMeta, updateValue) => {
            return (
              <div>
                <img
                  src={value && value.length > 0 ? value[0] : restaurantPicture}
                  style={{width: 50}}
                />
              </div>
            );
          },
        },
      },
      {
        name: 'rname',
        label: 'Name',
        options: {
          filter: false,
          sort: false,
        },
      },
      {
        name: 'raddress',
        label: 'Address',
        options: {
          filter: false,
          sort: false,
        },
      },
      {
        name: 'rmincost',
        label: 'Minimum Cost',
        options: {
          filter: false,
          sort: false,
        },
      },
      {
        name: 'Actions',
        options: {
          filter: false,
          sort: false,
          empty: true,
          customBodyRender: (value, tableMeta, updateValue) => {
            return (
              <div>
                <div>
                  <button
                    className="btn btn-outline-danger"
                    onClick={() => {
                      this.deleteHandler (tableMeta.rowData);
                    }}
                  >
                    <span class="fa fa-trash" /> &nbsp; Delete
                  </button>
                </div>
                <div>
                  <button
                    className="btn btn-outline-danger"
                    onClick={() => {
                      this.editHandler (tableMeta.rowData);
                    }}
                  >
                    <span class="fa fa-edit" /> &nbsp; Edit
                  </button>
                </div>
              </div>
            );
          },
        },
      },
    ],
  };

  getMuiTheme = () =>
    createMuiTheme ({
      overrides: {
        MUIDataTable: {
          root: {
            backgroundColor: '#FFFFFF',
          },
          paper: {
            boxShadow: 'none',
          },
        },
        MUIDataTableHeadCell: {
          fixedHeaderCommon: {
            backgroundColor: '#f5f5f5',
          },
        },
        MUIDataTableSelectCell: {
          headerCell: {
            backgroundColor: '#e0f7fa',
          },
        },
        MuiTableRow: {
          root: {
            cursor: 'pointer',
          },
        },
      },
    });

  componentDidMount () {
    this.fetchRestaurants ();
  }

  updateSetOpen (value) {
    this.setState ({
      setOpen: value,
    });
  }

  deleteHandler (rowData) {
    Axios.delete (apiRoute.GET_RESTAURANT_API + '/' + rowData[0], {
      withCredentials: false,
    })
      .then (res => {
        console.log ('These are my list of restaurants: ', res.data);
        this.fetchRestaurants ();
      })
      .catch (error => {
        console.log (error);
      });
  }

  createRestaurant () {
    this.setState ({
      rid: null,
      status: 'Create',
      restaurant: [],
      setOpen: true,
    });
  }

  editHandler (rowData) {
    this.setState ({
      rid: rowData[0],
      restaurant: rowData,
      status: 'Edit',
      setOpen: true,
    });
  }

  onCellClick = (cellIndex, rowIndex, dataIndex) => {
    const Obj = this.state.restaurants[rowIndex.dataIndex];
    if (
      rowIndex.colIndex === 0 ||
      rowIndex.colIndex === 1 ||
      rowIndex.colIndex === 2 ||
      rowIndex.colIndex === 3
    ) {
      this.props.history.push ({
        pathname: '/manager/restaurant/' + Obj.rid,
        restaurant: Obj,
      });
    }
  };

  fetchRestaurants () {
    console.log ('Getting restaurants list!');
    Axios.get (apiRoute.GET_RESTAURANTS_API, {
      withCredentials: false,
    })
      .then (res => {
        console.log ('These are my list of restaurants: ', res.data);
        this.setState ({
          restaurants: res.data,
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
              These are my list of restaurants
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
                <Col className="text-right">
                  <Button
                    variant="outlined"
                    color="primary"
                    onClick={() => this.createRestaurant ()}
                  >
                    Create Restaurant
                  </Button>
                </Col>
              </Row>
              <Row>
                <MuiThemeProvider theme={this.getMuiTheme ()}>
                  <MUIDataTable
                    title={`List of Restaurants`}
                    data={this.state.restaurants}
                    columns={this.state.columns}
                    options={{
                      selectableRows: false, // <===== will turn off checkboxes in rows
                      print: false,
                      download: false,
                      filter: false,
                      viewColumns: false,
                      onCellClick: this.onCellClick,
                    }}
                  />
                </MuiThemeProvider>
              </Row>
            </Card.Body>
          </Card>
        </Row>

        <AddRestaurant
          fetchRestaurants={this.fetchRestaurants.bind (this)}
          setOpen={this.state.setOpen}
          updateSetOpen={this.updateSetOpen.bind (this)}
          rid={this.state.rid}
          status={this.state.status}
          restaurant={this.state.restaurant}
        />
      </div>
    );
  }
}

export default withStyles (styles, {withTheme: true}) (Restaurants);
