import React, {Component} from 'react';
import Button from '@material-ui/core/Button';
import TextField from '@material-ui/core/TextField';
import Dialog from '@material-ui/core/Dialog';
import DialogActions from '@material-ui/core/DialogActions';
import DialogContent from '@material-ui/core/DialogContent';
import DialogContentText from '@material-ui/core/DialogContentText';
import DialogTitle from '@material-ui/core/DialogTitle';

export default class StaffRegisterForm extends Component {
    constructor() {
        super();
        this.state = {
            setOpen: false
        };

        this._handleClickOpen = this._handleClickOpen.bind(this);
        this._handleClose = this._handleClose.bind(this);
        this._handleRegister = this._handleRegister.bind(this);
    }

    _handleClickOpen = () => {
        this.setState({setOpen: true});
    };

    _handleClose = () => {
        this.setState({setOpen: false});
    };

    _handleRegister = () => {
        this.setState({setOpen: false});
    };

    render() {
  return (
    <div>
      <Button variant="outlined" color="primary" onClick={this._handleClickOpen}>
        Register (Staff)
      </Button>
      <Dialog open={this.state.setOpen} onClose={this._handleClose} aria-labelledby="form-dialog-title">
        <DialogTitle id="form-dialog-title">Register as a tapao-er!</DialogTitle>
        <form action="/" method="POST" onSubmit={(e) => {e.preventDefault(); alert('Registered Successfully!'); this.setState({setOpen: false});}}>
        <DialogContent>
          <DialogContentText>
            You're one step away from selling your food to thousands of people!
          </DialogContentText>
          <TextField
            autoFocus
            margin="dense"
            id="fullname"
            label="Full Name"
            variant="outlined"
            required
            fullWidth
          />
          <TextField
            margin="dense"
            id="position"
            label="Position"
            variant="outlined"
            required
            fullWidth
          />
          <TextField
            margin="dense"
            id="username"
            label="Username"
            variant="outlined"
            required
            fullWidth
          />
          <TextField
            margin="dense"
            id="password"
            label="Password"
            type="password"
            variant="outlined"
            required
            fullWidth
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={this._handleClose} color="primary">
            Cancel
          </Button>
          <Button onClick={this._handleRegister} color="primary">
            Register
          </Button>
        </DialogActions>
        </form>
      </Dialog>
    </div>
  );
    }
}
