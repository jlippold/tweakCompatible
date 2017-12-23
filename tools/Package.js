var Version = require("./Version");

function Package(props) {
    this.id = null;
    this.name = null;
    this.latest = null;
    this.repository = null;
    this.url = null;
    this.depiction = null;
    this.category = null;
    this.author = null;
    this.commercial = null;

    this.versions = [];
    this.versions.push(new Version(props));

    for (var prop in props) {
        if (this.hasOwnProperty(prop)) {
            this[prop] = props[prop];
        }
    }

}

module.exports = Package;
