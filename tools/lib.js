const fs = require('fs-extra');
const path = require('path');
const async = require('async');
var spawn = require('child_process').execFile;
const tweakListPath = path.join(__dirname, "../docs/tweaks.json");
const bansPath = path.join(__dirname, "../docs/bans.json");
const repoUrlsPath = path.join(__dirname, "../docs/json/repository-urls.json");
const jsonOutputPath = path.join(__dirname, "../docs/json/");
var jsonOptions = { spaces: 2 };

module.exports.getPackageById = function (id, packages) {
    return packages.find(function (package) {
        return package.id == id;
    });
};

module.exports.getPackagesByRepo = function (repo, packages) {
    var p = packages.filter(function (package) {
        return package.repository == repo;
    });
    return p;
};

module.exports.addPirateRepo = function (repo, bannedPackages, callback) {
    var bans = require("../docs/bans.json");
    if (bans.repositories.indexOf(repo) == -1) {
        bans.repositories.push(repo);
    }

    async.each(bannedPackages, function(package, next) {
        deletePackage(package, next);
    }, function(err){
        fs.outputJson(bansPath, bans, jsonOptions, function() { //save to bans file
            callback(null, true);
        });
    });
}

module.exports.addPiratePackage = function (package, callback) {
    var bans = require("../docs/bans.json");
    if (bans.packages.indexOf(package.id) == -1) {
        bans.packages.push(package.id);
    }
    deletePackage(package, function(err) { //remove the json file from disk
        fs.outputJson(bansPath, bans, jsonOptions, function() { //save to bans file
            callback(null, true);
        });
    });
}

module.exports.changeRepoAddress = function (name, url, callback) {
    var repos = require("../docs/json/repository-urls.json");
    var foundRepo = repos.repositories.find(function (repo) {
        return repo.name == name;
    });

    if (foundRepo) {
        foundRepo.url = url;
    } else {
        repos.repositories.push({
            name: name,
            url: url
        });
    }
    repos.repositories.sort(function (a, b) {
        if (a.name < b.name) return -1;
        if (a.name > b.name) return 1;
        return 0;
    });

    fs.outputJson(repoUrlsPath, repos, jsonOptions, callback);
}

module.exports.findVersionForPackageByOS = function (tweakVersion, iOSVersion, package) {
    return package.versions.find(function (version) {
        return version.tweakVersion == tweakVersion &&
            version.iOSVersion == iOSVersion;
    });
}

module.exports.findReviewForUserInVersion = function (userName, device, version) {
    return version.users.find(function (user) {
        return user.userName == userName &&
            user.device == device;
    });
}

module.exports.commitAgainstIssue = function (issueNumber, callback) {
    var add = spawn("git", ["add", ".", "-A"], { cwd: path.join(__dirname, "../") });
    add.on('close', (code) => {
        setTimeout(function () {
            var commit = spawn("git", ["commit", "-am", "fixes #" + issueNumber], {
                cwd: path.join(__dirname, "../")
            });
            commit.on('close', (code) => {
                setTimeout(function () {
                    callback();
                }, 200);
            });
        }, 200);
    });
}

module.exports.wipeJson = function () {
    fs.emptyDirSync(jsonOutputPath);
}

module.exports.writeBans = function (callback) {
    var folder = path.join(jsonOutputPath, "/packages/");
    var file = path.join(folder, package.id + ".json");
    fs.outputJson(file, package, jsonOptions, callback);
}

module.exports.writePackage = function (package, callback) {
    var folder = path.join(jsonOutputPath, "/packages/");
    var file = path.join(folder, package.id + ".json");
    fs.outputJson(file, package, jsonOptions, callback);
}

function deletePackage(package, callback) {
    var folder = path.join(jsonOutputPath, "/packages/");
    var file = path.join(folder, package.id + ".json");
    fs.unlink(file, callback);
}

module.exports.writeIOSVersionList = function (list, callback) {
    var file = path.join(jsonOutputPath, "iOSVersions.json");
    fs.outputJson(file, list, jsonOptions, callback);
}

module.exports.writeByiOS = function (output, iOSVersion, callback) {
    var folder = path.join(jsonOutputPath, "/iOS/");
    var file = path.join(folder, iOSVersion + ".json");
    fs.outputJson(file, output, jsonOptions, callback);
}

module.exports.wipePackages = function () {
    var file = fs.readJsonSync(tweakListPath);
    file.packages = [];
    fs.writeJsonSync(tweakListPath, file, jsonOptions);
}

module.exports.getTweakList = function (callback) {
    fs.readJson(tweakListPath, callback);
}

module.exports.writeTweakList = function (json, callback) {
    fs.writeJson(tweakListPath, json, jsonOptions, callback);
}



module.exports.parseJSON = function (str) {
    var json;
    try {
        json = JSON.parse(str);
    } catch (err) { }
    return json;
}
