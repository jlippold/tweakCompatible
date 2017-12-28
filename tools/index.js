
const GitHubApi = require('github');
const async = require('async');

var lib = require("./lib");
var Package = require("./Package"); //model
var User = require("./User"); //model
var Version = require("./Version"); //model

const owner = "jlippold";
const repo = "tweakCompatible";

const github = new GitHubApi();

github.authenticate({
    type: 'token',
    token: process.env.GITHUB_API_TOKEN
});

var mode;
if (process.argv.length == 2) {
    mode = "process"; //get new open issues
} else if (process.argv.length == 3) {
    if (process.argv[2] == "rebuild") {
        mode = "rebuild"; //re-import closed issues
    } else {
        return console.error("bad args");
    }
} else {
    return console.error("bad args");
}



function init(callback) {
    getIssues(function (err, issues) {
        if (mode == "rebuild") {
            //wipe out old items
            lib.wipePackages();
        }

        async.eachOfLimit(issues, 1, function (change, idx, nextIssue) {
            console.log("Working on: " + change.issueTitle);
            async.auto({
                tweaks: lib.getTweakList,
                add: ['tweaks', function (results, next) {
                    addTweaks(results.tweaks, change, next);
                }],
                calculate: ['add', function (results, next) {
                    var packages = results.add.slice();
                    packages.sort(function compare(a, b) {
                        if (a.name.toLowerCase() < b.name.toLowerCase()) return -1;
                        if (a.name.toLowerCase() > b.name.toLowerCase()) return 1;
                        return 0;
                    });
                    reCalculate(packages, next);
                }],
                save: ['calculate', function (results, next) {
                    results.tweaks.packages = results.calculate.packages.slice();
                    results.tweaks.iOSVersions = results.calculate.iOSVersions.slice();
                    lib.writeTweakList(results.tweaks, next);
                }],
                commit: ['calculate', function (results, next) {
                    if (mode == "rebuild") {
                        return next();
                    } 
                    lib.commitAgainstIssue(change.issueNumber, next);
                    //
                }]
            }, function (err, result) {
                nextIssue(err);
            });

        }, function (err) {
            callback(err);
        });
    });


}

function addTweaks(tweaks, change, callback) {
    var packages = tweaks.packages.slice();
    var package = lib.getPackageById(change.packageId, packages);

    if (!package) {
        console.log("New package creation: ", change.packageId);

        var package = new Package(change);
        
        if (!package.id) {
            console.error("Bad package Id", package, change)
            return callback("Bad package Id");
        }

        packages.push(package);
        if (mode == "rebuild") {
            return callback(null, packages);
        }
        addLabelsToIssue(change.issueNumber, ['user-submission', 'new-package'], function () {
            callback(null, packages);
        });

    } else {
        console.log("Editing package: ", package.id);
        
        //edit package info
        package.latest = change.latest;
        package.shortDescription = change.depiction || change.shortDescription;

        //find version
        var version = lib.findVersionForPackageByOS(change.latest, change.iOSVersion, package);
        if (!version) {
            console.log("Creating new version");
            //create version with review
            var v = new Version(change);
            package.versions.push(v);
            if (mode == "rebuild") {
                return callback(null, packages);
            }
            addLabelsToIssue(change.issueNumber, ['user-submission', 'new-version'], function () {
                callback(null, packages);
            });
        } else {

            //add review to version
            var user = lib.findReviewForUserInVersion(change.userName, change.deviceId, version);
            if (!user) {
                console.log("Adding review to version");
                var u = new User(change);
                version.users.push(u);
                if (mode == "rebuild") {
                    return callback(null, packages);
                }
                addLabelsToIssue(change.issueNumber, ['user-submission', 'new-review'], function () {
                    callback(null, packages);
                });
            } else {
                console.log("review already in system");
                if (mode == "rebuild") {
                    return callback(null, packages);
                }
                addLabelsToIssue(change.issueNumber, ['user-submission', 'duplicate'], function () {
                    var opts = {
                        owner, repo,
                        number: change.issueNumber,
                        state: "closed"
                    };
                    github.issues.edit(opts, function () {
                        callback(null, packages);
                    });
                });
            }

        }

    }
}

function reCalculate(packages, callback) {
    var iOSVersions = [];
    packages.forEach(function (package) {
        var reCalculated = [];
        package.versions.forEach(function (version) {

            if (iOSVersions.indexOf(version.iOSVersion) == -1) {
                iOSVersions.push(version.iOSVersion);
            }

            version.outcome.total = version.users.length;

            version.outcome.good = version.users.filter(function (user) {
                return user.status == "working" || user.status == "partial";
            }).length;

            version.outcome.bad = version.users.filter(function (user) {
                return user.status == "notworking";
            }).length;

            version.outcome.percentage =
                version.outcome.total == 0 ? 0 :
                    Math.floor((version.outcome.good / version.outcome.total) * 100);

            version.outcome.calculatedStatus = "Not working";
            if (version.outcome.total == 0) {
                version.outcome.calculatedStatus = "Unknown";
            }
            if (version.outcome.percentage > 40) {
                version.outcome.calculatedStatus = "Likely working";
            }
            if (version.outcome.percentage > 75) {
                version.outcome.calculatedStatus = "Working";
            }

            reCalculated.push(version);
        })
        package.versions = reCalculated.slice();
    });

    callback(null, {
        packages: packages,
        iOSVersions: iOSVersions.reverse()
    });
}


function addLabelsToIssue(number, labels, callback) {
    github.issues.addLabels({ owner, repo, number, labels }, callback);
}


function getIssues(callback) {
    var allIssues = [];
    var nextPage = true;

    var options = {
        owner, repo,
        per_page: 100,
        page: 1,
        state: (mode == "rebuild" ? "closed" : "open"),
        sort: "created",
        direction: (mode == "rebuild" ? "asc" : "desc")
    };

    //loop all issues
    async.until(
        function () {
            return nextPage == false
        },
        function (next) {
            github.issues.getForRepo(options, function (err, result) {
                result.data.forEach(function(issue) {
                    var shouldSkip = issue.labels.find(function(label) {
                        return label.name == "bypass"
                    });
                    if (!shouldSkip) {
                        allIssues.push(issue);
                    }
                })
                
                if (github.hasNextPage(result)) {
                    options.page++;
                    nextPage = true;
                } else {
                    nextPage = false;
                }
                next(err);
            });
        },
        function (err) {
            var validIssues = [];
            allIssues.forEach(function (issue) {
                if (issue.body.substring(0, 3) == "```" && issue.body.indexOf("packageStatusExplaination") > -1) {
                    var json = lib.parseJSON(issue.body.replace(/```/g, ""));
                    if (json) {
                        var thisIssue = lib.parseJSON(Buffer.from(json.base64, 'base64').toString());
                        if (thisIssue) {
                            thisIssue.issueId = issue.id;
                            thisIssue.issueNumber = issue.number;
                            thisIssue.date = issue.created_at;
                            thisIssue.issueTitle = issue.title;
                            thisIssue.userNotes = json.notes;
                            thisIssue.userChosenStatus = json.chosenStatus;
                            thisIssue.userName = issue.user.login;
                            validIssues.push(thisIssue);
                        }
                    }
                }
            });
            callback(null, validIssues, []);
        }
    );

}


init(function (err) {
    if (err) {
        console.error(err);
    }
});