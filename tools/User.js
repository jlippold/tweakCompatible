function User(props) {
    this.status = props.userChosenStatus;
    this.device = props.deviceId;
    this.issues = props.userNotes;
    this.date = props.date;
    this.userName = props.userName;
    this.issueNumber = props.issueNumber;
    this.arch32 = props.arch32;
}

module.exports = User;
