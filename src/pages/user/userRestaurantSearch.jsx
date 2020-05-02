import React, { Component } from 'react'
import Typography from '@material-ui/core/Typography';
import banner from '../../images/food.jpeg';
import TextField from '@material-ui/core/TextField';

class userRestaurantSearch extends Component {
    constructor(props) {
        super(props);
        this.state = {
            searchValue: "",
            searchSubmission: "",
        }

        this.handleSearch = this.handleSearch.bind(this);
    }

    // Handles the change from the search bar
    handleChange(e) {
        this.setState({
            searchValue: e.target.value
        });
    }

    // Handles search entry submission
    handleSearch() {
        //let var = getSearchResults(this.state.searchValue)
        //populateSearchResults(var)

        // DEBUG:
        this.setState({
            searchSubmission: this.state.searchValue
        });
    }

    render() {
        return (
            <div>
                <div className="searchBarBanner">
                    <img className="banner" src={banner} alt="banner" />
                    <div className="searchBarTitle">
                        <Typography variant="h4" noWrap>
                            Search for your next meal!
                        </Typography>
                    </div>
                    <div className="searchBarDiv">
                        <TextField 
                        className="searchBar"
                        defaultValue=""
                        placeholder="Search by food, restaurant or category!" 
                        onChange={e => this.handleChange(e)}
                        onKeyPress={(ev) => {
                            if (ev.key === 'Enter') {
                                this.handleSearch()
                            }
                        }} 
                        variant="filled"
                        fullWidth
                        />
                    </div>
                </div>
                <div className="mainContent">
                    {/* Card List */}
                    You searched for {this.state.searchSubmission}
                </div>
            </div>
        )
    }
}

export default userRestaurantSearch
