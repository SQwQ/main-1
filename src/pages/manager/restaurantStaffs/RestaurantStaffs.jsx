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
import AddRestaurantStaff from './AddRestaurantStaff';

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

class RestaurantStaffs extends Component {
  constructor (props) {
    super (props);
    let pathArray = this.props.location.pathname.split ('/');
    this.state = {
      restaurants: [],
      restaurant: [],
      setOpen: false,
      rid: pathArray[3],
      status: '',
      columns: [
        {
          name: 'rsid',
          label: 'Id',
          options: {
            filter: false,
            sort: false,
          },
        },
        {
          name: 'rsimage',
          label: 'Image',
          options: {
            filter: true,
            sort: true,
            customBodyRender: (value, tableMeta, updateValue) => {
              return (
                <div>
                  <img
                    src={
                      value && value.length > 0 ? value[0] : restaurantPicture
                    }
                    style={{width: 50}}
                  />
                </div>
              );
            },
          },
        },
        {
          name: 'rsname',
          label: 'Name',
          options: {
            filter: false,
            sort: false,
          },
        },
        {
          name: 'rsusername',
          label: 'Username',
          options: {
            filter: false,
            sort: false,
          },
        },
        {
          name: 'rsposition',
          label: 'Position',
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
                  {/* <div>
                    <button
                      className="btn btn-outline-danger"
                      onClick={() => {
                        this.editHandler (tableMeta.rowData);
                      }}
                    >
                      <span class="fa fa-edit" /> &nbsp; Edit
                    </button>
                  </div> */}
                </div>
              );
            },
          },
        },
      ],
    };
  }

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
    console.log ('This is my rid: ', this.state.rid);
    this.fetchRestaurantStaffs (this.state.rid);
  }

  updateSetOpen (value) {
    this.setState ({
      setOpen: value,
    });
  }

  deleteHandler (rowData) {
    Axios.delete (apiRoute.STAFF_API + '/' + rowData[0], {
      withCredentials: false,
    })
      .then (res => {
        console.log ('These are my list of restaurants: ', res.data);
        this.fetchRestaurantStaffs (this.state.rid);
      })
      .catch (error => {
        console.log (error);
      });
  }

  createRestaurantStaff () {
    this.setState ({
      rid: null,
      status: 'Create',
      staff: [],
      setOpen: true,
    });
  }

  editHandler (rowData) {
    this.setState ({
      rid: rowData[0],
      staff: rowData,
      status: 'Edit',
      setOpen: true,
    });
  }

  fetchRestaurantStaffs (rid) {
    console.log ('Fetching restaurant staff! ' + rid);
    Axios.get (apiRoute.STAFF_API + 's/' + rid, {
      withCredentials: false,
    })
      .then (res => {
        console.log ('These are my list of restaurantStaffs: ', res.data);
        this.setState ({
          restaurantStaffs: res.data,
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
              These are my list of restaurant staffs
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
                    onClick={() => this.createRestaurantStaff ()}
                  >
                    Create Restaurant Staff
                  </Button>
                </Col>
              </Row>
              <Row>
                <MuiThemeProvider theme={this.getMuiTheme ()}>
                  <MUIDataTable
                    title={`List of Restaurant Staffs of ${this.props.location.restaurant.rname}`}
                    data={this.state.restaurantStaffs}
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

        <AddRestaurantStaff
          fetchRestaurantStaffs={this.fetchRestaurantStaffs.bind (this)}
          setOpen={this.state.setOpen}
          updateSetOpen={this.updateSetOpen.bind (this)}
          rid={this.state.rid}
          status={this.state.status}
          staff={this.state.staff}
        />
      </div>
    );
  }
}

export default withStyles (styles, {withTheme: true}) (RestaurantStaffs);
