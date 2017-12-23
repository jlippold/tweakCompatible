function User(props) {
    this.status = props.userChosenStatus;
    this.device = props.deviceId;
    this.issues = props.userNotes;
    this.date = props.date;
    this.userName = props.userName;
}

module.exports = User;
