var User = require("./User");

function Version(props) {
    this.tweakVersion = props.latest;
    this.iOSVersion = props.iOSVersion;
    this.repository = props.repository;
    this.date = props.date || new Date();
    this.outcome = {
        calculatedStatus: "",
        percentage: 0,
        good: 0,
        bad: 0
    };

    this.users = [];
    this.users.push(new User(props));

}

module.exports = Version;
