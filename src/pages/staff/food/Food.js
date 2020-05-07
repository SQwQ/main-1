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
import AddFood from './AddFood';
import { withRouter } from 'react-router'

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

class Food extends Component {
  constructor (props) {
    super (props);
  }
  state = {
    singleFood: [],
    food: [],
    setOpen: false,
    rid: null,
    status: '',
    columns: [
      {
        name: 'fid',
        label: 'Id',
        options: {
          filter: false,
          sort: false,
        },
      },
      {
        name: 'fimage',
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
        name: 'fname',
        label: 'Name',
        options: {
          filter: false,
          sort: false,
        },
      },
      {
        name: 'fprice',
        label: 'Price',
        options: {
          filter: false,
          sort: false,
        },
      },
      {
        name: 'flimit',
        label: 'Sales Limit',
        options: {
          filter: false,
          sort: false,
        },
      },
      {
        name: 'favailable',
        label: 'Availability',
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
      },
    });

  componentDidMount () {
    this.fetchFood ();
  }

  updateSetOpen (value) {
    this.setState ({
      setOpen: value,
    });
  }

  deleteHandler (rowData) {
    Axios.delete (apiRoute.GET_RESTAURANT_FOOD_API + '/' + rowData[0], {
      withCredentials: false,
    })
      .then (res => {
        this.fetchFood ();
      })
      .catch (error => {
        console.log (error);
      });
  }

  createFood () {
    this.setState ({
      rid: null,
      status: 'Create',
      singleFood: [],
      setOpen: true,
    });
  }

  editHandler (rowData) {
    this.setState ({
      rid: rowData[0],
      singleFood: rowData,
      status: 'Edit',
      setOpen: true,
    });
  }

  fetchFood () {
    console.log ('Getting food list!');
    Axios.get (apiRoute.GET_RESTAURANT_FOOD_API + '/' + this.props.restaurantDetails.rid, {
      withCredentials: false,
    })
      .then (res => {
        console.log ('These are my list of foods: ', res.data);
        this.setState ({
          food: res.data,
        });
      })
      .catch (error => {
        console.log (error);
      });
  }

  render () {
    return (
      <div className="wrapper_content_section">
        <Row>
          <Card style={{margin: 'auto', float: 'none', marginBottom: '10px'}}>
            <Card.Body>
              <Row>
                <Col className="text-right">
                  <Button
                    variant="outlined"
                    color="primary"
                    onClick={() => this.createFood ()}
                  >
                    Create Food
                  </Button>
                </Col>
              </Row>
              <Row>
                <MuiThemeProvider theme={this.getMuiTheme ()}>
                  <MUIDataTable
                    title={`List of Food`}
                    data={this.state.food}
                    columns={this.state.columns}
                    options={{
                      selectableRows: false, // <===== will turn off checkboxes in rows
                      print: false,
                      download: false,
                      filter: false,
                      viewColumns: false,
                    }}
                  />
                </MuiThemeProvider>
              </Row>
            </Card.Body>
          </Card>
        </Row>

        <AddFood
          fetchFood={this.fetchFood.bind (this)}
          setOpen={this.state.setOpen}
          updateSetOpen={this.updateSetOpen.bind (this)}
          rid={this.state.rid}
          status={this.state.status}
          singleFood={this.state.singleFood}
        />
      </div>
    );
  }
}

export default withRouter (Food);
