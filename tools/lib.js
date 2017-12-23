const jsonfile = require('jsonfile');
const path = require('path');
var spawn = require('child_process').execFile;
const tweakListPath = path.join(__dirname, "../docs/tweaks.json");

module.exports.getPackageById = function (id, packages) {
    return packages.find(function (package) {
        return package.id == id;
    });
}

module.exports.findVersionForPackageByOS = function (tweakVersion, iOSVersion, package) {
    return package.versions.find(function(version) {
        return version.tweakVersion == tweakVersion &&
            version.iOSVersion == iOSVersion;
    });
}

module.exports.findReviewForUserInVersion = function (userName, device, version) {
    return version.users.find(function(user) {
        return user.userName == userName &&
            user.device == device;
    });
}

module.exports.commitAgainstIssue = function (issueNumber, callback) {
    var args = ["commit", "-am", "fixes #" + issueNumber]
    var git = spawn("git", args, {
        cwd: path.join(__dirname, "../")
    });
    
    git.on('close', (code) => {
        console.log(code);
        callback();
    });
}

module.exports.getTweakList = function (callback) {
    var jsonfile = require('jsonfile')
    jsonfile.readFile(tweakListPath, callback);
}

module.exports.writeTweakList = function (packages, callback) {
    jsonfile.writeFile(tweakListPath, packages, { spaces: 2 }, callback);
}

module.exports.parseJSON = function (str) {
    var json;
    try {
        json = JSON.parse(str);
    } catch (err) { }
    return json;
}
