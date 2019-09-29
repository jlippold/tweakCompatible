var vm;
var tweakList;
var userDetails;

$(document).ready(function () {

    checkAction();

    var Tweak = Vue.extend({
        template: "#tweak-template",
        data: function () {
            return {
                repoUrl: null,
                mod: {
                    action: "",
                    repoUrl: ""
                },
                devices: [],
                filters: {
                    iOS: [],
                    devices: []
                },
                currentVersion: "",
                package: {
                    id: "",
                    name: "",
                    latest: "",
                    repository: "",
                    url: "",
                    shortDescription: "",
                    category: "",
                    author: "",
                    commercial: false,
                    versions: []
                }
            };
        },
        mounted: function () {
            var c = this;
            this.fetch();
        },
        computed: {
            uniqueVersions: function () {
                return this.package.versions.map(function (v) {
                    return v.tweakVersion;
                }).filter(function (version, idx, self) {
                    return self.indexOf(version) === idx;
                }).reverse();
            }            
        },
        methods: {
            colorIcon: function (status) {
                var c = '#43ac6a';
                if (status == "Working") {
                    c = '#43ac6a';
                } else if (status == "Likely working") {
                    c = '#e99002';
                } else {
                    c = '#f04124';
                }
                return {
                    'vertical-align': 'baseline',
                    'color': c
                }
            },
            colorBorder: function (status) {
                var s = '4px solid #43ac6a';
                if (status == "Working") {
                    s = '4px solid #43ac6a';
                } else if (status == "Likely working") {
                    s = '4px solid #e99002';
                } else {
                    s = '4px solid #f04124';
                }
                return {
                    'margin-left': '-20px',
                    'padding-left': '16px',
                    'border-left': s
                }
            },
            getDeviceName: function (deviceId) {
                var devices = this.devices;
                var found = devices.find(function (device) {
                    return device.deviceId == deviceId;
                });
                return found ? found.deviceName : "Unknown device";
            },
            relativeDate: function (dt) {
                return moment(dt).fromNow();
            },
            submitMod: function() {
                $('#github').submit();
            },
            fetch: function () {
                var c = this;
                async.auto({
                    devices: function (next) {
                        $.ajax({
                            url: "devices.json",
                            dataType: 'json',
                            success: function (data) {
                                c.devices = data.devices.slice();
                                next(null);
                            },
                            error: function (err) {
                                next(err);
                            }
                        });
                    },
                    package: ['devices', function (results, next) {
                        $.getJSON("json/packages/" + userDetails.packageId + ".json", function (data) {
                            data.versions.sort(function compare(a, b) {
                                var aDate = a.date;
                                if (!aDate) {
                                    aDate = a.users
                                        .map(function (x) { return x.date })
                                        .reduce(function (p, v) { return (p < v ? p : v) });
                                }
                                var bDate = b.date;
                                if (!bDate) {
                                    bDate = b.users
                                        .map(function (x) { return x.date })
                                        .reduce(function (p, v) { return (p < v ? p : v) });
                                }

                                if (aDate < bDate) return 1;
                                if (aDate > bDate) return -1;
                                return 0;
                            });

                            c.package = data;

                            var hasVersion = data.versions.find(function (v) {
                                if (v.tweakVersion == userDetails.base64) {
                                    c.currentVersion = v.tweakVersion;
                                }
                                return (v.tweakVersion == userDetails.base64);
                            });
                            if (!hasVersion) {
                                c.currentVersion = data.versions[0].tweakVersion;
                            }
                            next();
                        });
                    }],
                    urls: ['package', function (results, next) {
                        $.ajax({
                            url: "json/repository-urls.json",
                            dataType: 'json',
                            success: function (data) {
                                var repoUrl = data.repositories.find(function (repo) {
                                    return repo.name == c.package.repository;
                                });
                                c.repoUrl = repoUrl ? repoUrl.url : null;
                                c.mod.repoUrl = repoUrl ? repoUrl.url : "";
                                next();
                            },
                            error: function (err) {
                                next(err);
                            }
                        });
                    }],
                    bans: ['urls', function (results, next) {
                        $.ajax({
                            url: "bans.json",
                            dataType: 'json',
                            success: function (data) {
                                if (data.repositories.indexOf(c.package.repository) > -1 || data.packages.indexOf(c.package.id) > -1 ) {
                                    c.package = {
                                        id: "",
                                        name: "",
                                        latest: "",
                                        repository: "",
                                        url: "",
                                        shortDescription: "",
                                        category: "",
                                        author: "",
                                        commercial: false,
                                        versions: []
                                    };
                                }
                                next();
                            },
                            error: function (err) {
                                next(err);
                            }
                        });
                    }]
                }, function (err, results) {
                    if (err) {
                        return console.error(err);
                    }

                    var currentIOSVersion = iOSVersion();
                    var iOS = [];
                    c.package.versions.forEach(function(v) {
                        if (iOS.indexOf(v.iOSVersion) == -1) {    
                            iOS.push(v.iOSVersion);
                        }
                    });
                    
                    c.filters.iOS = iOS.map(function (v) {
                        if (currentIOSVersion) {
                            return { version: v, selected: currentIOSVersion == v };
                        } else {
                            return { version: v, selected: (v.indexOf("11.") > -1) };
                        }
                    });
                    
                    var matched = c.filters.iOS.find(function(v) {
                        return v.selected;
                    });

                    if (!matched) {
                        console.log("no versions found, matching all ios 11");
                        c.filters.iOS = iOS.map(function (v) {
                            return { version: v, selected: (v.indexOf("11.") > -1) };
                        })
                    }

                    c.filters.iOS.sort();
                    

                    var devices = [];
                    c.package.versions.forEach(function (v) {
                        v.users.forEach(function (user) {
                            if (devices.indexOf(user.device) == -1) {
                                devices.push(user.device);
                            }
                        });
                    });
                    c.filters.devices = devices.map(function (type) {
                        var name = c.getDeviceName(type);
                        if (name == "Unknown device") {
                            name = type;
                        }
                        return { type: name, selected: true };
                    }).sort();;

                });
            }
        },
        computed: {
            issueTitle: function () {
                if (this.mod.action == "piratePackage") {
                    return "Pirate Package: `" + this.package.id + "`"
                }
                if (this.mod.action == "pirateRepo") {
                    return "Pirate Repo: `" + this.package.repository + "`"
                }
                if (this.mod.action == "changeUrl") {
                    return "Change Repo URL: `" + this.package.repository + "`"
                }
                return "";
            },
            issueBody: function () {
                var submission = {};
                submission.action = this.mod.action;
                if (submission.action == "piratePackage") {
                    submission.id = this.package.id;
                }
                if (submission.action == "pirateRepo") {
                    submission.repo = this.package.repository;
                }
                if (submission.action == "changeUrl") {
                    submission.repo = this.package.repository;
                    submission.url = this.mod.repoUrl;
                }
                return "```\n" + JSON.stringify(submission, null, 2) + "\n```"
            }
        }
    });


    vm = new Vue({
        el: "#app",
        data: {},
        components: {
            tweak: Tweak
        }
    });


});

