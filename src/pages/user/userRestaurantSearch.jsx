import React, { Component } from 'react';
import Typography from '@material-ui/core/Typography';
import TextField from '@material-ui/core/TextField';
import * as apiRoute from '../../components/Api/route.js';
import Axios from 'axios';
import RestaurantItem from '../../components/Search/RestaurantItem';

class userRestaurantSearch extends Component {
  constructor(props) {
    super(props);
    this.state = {
      searchValue: '',
      searchSubmission: '',
      searchResults: []
    };

    this.handleSearch = this.handleSearch.bind(this);
    this.renderRestaurant = this.renderRestaurant.bind(this);
  }

  // Handles the change from the search bar
  handleChange(e) {
    this.setState({
      searchValue: e.target.value,
    });
  }

  // Handles search entry submission
  handleSearch(e) {
    Axios.get(apiRoute.SEARCH_RESTAURANT_API + '/' + e.target.value)
      .then((res) => {
          this.setState({
            searchResults: res.data,
            searchSubmission: this.state.searchValue,
          });
      })
      .catch((error) => {
        console.log('Error getting search results!');
        console.log(error);
      });
  }

  renderRestaurant() {
    return this.state.searchResults.map(result => < RestaurantItem key={result.fid} result={result} userId={this.props.userId}/>);
  }

  render() {
    return (
      <div>
        <div className='searchBarBanner'>
          <div className='searchBarTitle'>
            <Typography variant='h4' noWrap>
              Search for your next meal!
            </Typography>
          </div>
          <div className='searchBarDiv'>
            <TextField
              className='searchBar'
              defaultValue=''
              placeholder='Search by food, restaurant or category!'
              onChange={(e) => this.handleChange(e)}
              onKeyPress={(ev) => {
                if (ev.key === 'Enter') {
                  this.handleSearch(ev);
                }
              }}
              variant='filled'
              fullWidth
            />
          </div>
        </div>
        <div className='mainContent'>
          {/* Card List */}
          You searched for {this.state.searchSubmission}
          {this.renderRestaurant()}
        </div>
      </div>
    );
  }
}

export default userRestaurantSearch;
