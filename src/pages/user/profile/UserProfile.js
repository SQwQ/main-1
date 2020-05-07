import React, { useEffect, useState } from 'react';
import * as apiRoute from '../../../components/Api/route.js';
import Axios from 'axios';
import { Link } from 'react-router-dom';
import { withRouter } from 'react-router'

// match.params = {rid, fid}
// userDetails = { cid, cname, ccontact_number, cusername, cpassword, cjoin_time, crewards_points, card_number }
// creditCards = [card_number, ..]
function UserProfile({ match, userDetails, rewardPoints }) {
  const [pastOrders, setPastOrders] = useState([]);
  const [inputNumber, setInputNumber] = useState('');
  const [inputCcv, setInputCcv] = useState('');
  const [inputExDate, setInputExDate] = useState('');
  const [defaultCreditCardNumber, setDefaultCreditCardNumber] = useState(null);
  const [creditCards, setCreditCards] = useState([]);

  // Fetch data
  useEffect(() => {
      // fetch user's past orders
      Axios.get(apiRoute.GET_PAST_ORDER_API + '/' + match.params.userid)
      .then((res) => {
        setPastOrders(res.data);
      })
      .catch((error) => {
        console.log('Error getting user past orders food!');
        console.log(error);
      });

      // fetch user's credit cards
      Axios.get(apiRoute.GET_USER_CARDS + '/' + match.params.userid)
      .then((res) => {
        setCreditCards(res.data.map(data => {
          // set user's default credit card
          if (data.current == true) {
            setDefaultCreditCardNumber(data.card_number)
          }
          return data.card_number;
        }));
      })
      .catch((error) => {
        console.log('Error getting user past orders food!');
        console.log(error);
      });

  }, []);

  function saveCardDetails() {
    console.log(inputNumber);
    // add to user's list of credit cards
    if (!validateNewCreditCard()) {
      alert("Credit card not valid");
      return;
    }
    let newCardDetails = {
      card_number : inputNumber,
      expiry_date : inputExDate,
      cvv : inputCcv,
      current : defaultCreditCardNumber == null ? true : false
    }
    Axios.post(apiRoute.POST_A_CARD + '/' + match.params.userid, newCardDetails)
    .then((res) => {
      setCreditCards([...creditCards, inputNumber])
      setDefaultCreditCardNumber(inputNumber);
      console.log("updated")
    })
    .catch((error) => {
      console.log('Error getting user past orders food!');
      console.log(error);
    })
  }

  function renderPastOrders() {
    let pastOrdersArray = []
    for (let i = 0; i < pastOrders.length; i++) {
      pastOrdersArray.push(
        <Link key={i} to={{pathname: `/profile/${match.params.userid}/order/${pastOrders[i].ocid}`, state: {pastOrderDetails: pastOrders[i]}}}>
            <p>order number: {pastOrders[i].ocid} | final price: {pastOrders[i].ofinal_price} | order time: {pastOrders[i].oorder_place_time} | order fulfiled: {pastOrders[i].oorder_arrives_customer == null ? "no" : "yes"}</p>
        </Link>
      )
    }
    return pastOrdersArray;
  }

  // creditCards = [{card_number, expiry_date, cvv, cid}, {...}]
  function renderUserCreditCards() {
    return creditCards.map(creditCard => {
      return (
        <div key={creditCard} onClick={() => changeDefaultCard(creditCard)}>
          <p>{creditCard}   <b>{defaultCreditCardNumber==creditCard ? "(Your Default Card)" : ""}</b></p>
        </div>
      )
    });
  }

  function changeDefaultCard(number) {
    // Change app state
    setDefaultCreditCardNumber(number);

    let newCardNumber = {registeredCardNumber: number}
    // Change database
    Axios.patch(apiRoute.CHANGE_DEFAULT_CARD + '/' + match.params.userid, newCardNumber)
    .then((res) => {
      console.log("changed default card")
    })
    .catch((error) => {
      console.log('Error changing default card');
      console.log(error);
    })
  }

  function validateNewCreditCard() {
    if (inputCcv == '' || inputExDate == '' || inputNumber == '') {
      return false;
    }
    return true;
  }

  return (
    <div className="wrapper_content_section">
      <h1>userID: {userDetails.cid}</h1>
      <h1>customer name: {userDetails.cname}</h1>
      <h1>join time: {userDetails.cjoin_time}</h1>
      <h1>reward points: {rewardPoints}</h1>
      <h1>Add your credit card details here for payment</h1>
      <label>Credit card number: </label>
      <input id="creditNumInput" type="number" value={inputNumber} onChange={(e) => setInputNumber(e.target.value)}/><br/>
      <label>CCV: </label>
      <input type="number" value={inputCcv} onChange={(e) => setInputCcv(e.target.value)}/><br/>
      {/* Date format DD/MM/YY */}
      <label>Expiry Date: </label>
      <input type="date" value={inputExDate} onChange={(e) => setInputExDate(e.target.value)}/><br/>
      <button onClick={saveCardDetails}>Add</button>
      <p>Your list of credit cards:</p>
      {renderUserCreditCards()}

      {/* Past orders */}
      <h1>A list of your past orders</h1>
      {renderPastOrders()}
    </div>
  );
}

export default withRouter(UserProfile);