var Version = require("./Version");

function Package(props) {
    this.id = props.id;
    this.name = props.name;
    this.latest = props.latest;
    this.repository = props.repository;
    this.url = props.url;
    this.shortDescription = props.depiction || props.shortDescription;
    this.category = props.category;
    this.author = props.author;
    this.commercial = props.commercial;
    this.date = props.date || new Date();

    this.versions = [];
    this.versions.push(new Version(props));

}

module.exports = Package;
