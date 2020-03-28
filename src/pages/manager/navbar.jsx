import React, {Component} from 'react';
import {Nav} from 'react-bootstrap';

export class ManagerNavBar extends Component {
  render () {
    return (
      <div>
        <Nav defaultActiveKey="/home" className="flex-column">
          <Nav.Link href="/manager">Active</Nav.Link>
          <Nav.Link eventKey="link-1">Link</Nav.Link>
          <Nav.Link eventKey="link-2">Link</Nav.Link>
          <Nav.Link eventKey="disabled" disabled>
            Disabled
          </Nav.Link>
        </Nav>
      </div>
    );
  }
}

export default ManagerNavBar;