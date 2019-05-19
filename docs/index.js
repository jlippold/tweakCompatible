
var vm;
var tweakList;
var userDetails;
var cache;

$(document).ready(function () {

    var TweakList = Vue.extend({
        template: "#tweaklist-template",
        data: function () {
            return {
                data: {
                    searchTerm: "",
                    filter: window.location.hash == "#cydia" ? "Working" : "",
                    isCydiaRequest: (window.location.hash == "#cydia"),
                    sort: "",
                    iOSVersionIndex: 0,
                    categories: [],
                    devices: [],
                    iOSVersions: [],
                    packageCache: {},
                    packages: []
                }
            };
        },
        mounted: function () {
            var c = this;
            async.auto({
                devices: function (callback) {
                    $.ajax({
                        url: "devices.json",
                        dataType: 'json',
                        success: function (data) {
                            callback(null, data.devices);
                        },
                        error: function (err) {
                            callback(err);
                        }
                    });
                },
                iOSVersions: function (callback) {
                    $.ajax({
                        url: "json/iOSVersions.json",
                        dataType: 'json',
                        success: function (data) {
                            callback(null, data.iOSVersions);
                        },
                        error: function (err) {
                            callback(err);
                        }
                    });
                },
                bans: function (callback) {
                    $.ajax({
                        url: "bans.json",
                        dataType: 'json',
                        success: function (data) {
                            callback(null, data);
                        },
                        error: function (err) {
                            callback(err);
                        }
                    });
                },
                index: ['devices', 'iOSVersions', 'bans', function (results, callback) {
                    //detect ios version from useragent
                    var v = iOSVersion();
                    var iOSVersionIndex = 0;
                    var foundVersion = false;
                    if (v) {
                        results.iOSVersions.forEach(function (vers, idx) {
                            if (v == vers) {
                                iOSVersionIndex = idx;
                                foundVersion = true;
                            }
                        });
                    }
                    if (!foundVersion) {
                        iOSVersionIndex = (results.iOSVersions.length - 1);
                    }
                    callback(null, iOSVersionIndex);
                }]
            }, function (err, results) {
                if (err) {
                    return console.error(err);
                }
                c.data.iOSVersions = results.iOSVersions;
                c.data.devices = results.devices;
                c.data.bannedRepos = results.bans.repositories;
                c.data.bannedPackages = results.bans.packages;
                c.data.iOSVersionIndex = results.index;
                c.fetch();
            });
        },
        computed: {
            searchDebounce: {
                get: function () {
                    return this.data.searchTerm;
                },
                set: _.debounce(function (newValue) {
                    this.data.searchTerm = newValue;
                }, 500)
            },
            filteredPackages: function () {

                var data = this.data;
                var iOSVersion = data.iOSVersions[data.iOSVersionIndex];
                var searchTerm = data.searchTerm.toLowerCase();


                var filteredPackageList = data.packages.filter(function (package) {
                    if (data.bannedRepos.indexOf(package.repository) > -1) {
                        return false;
                    }

                    if (data.bannedPackages.indexOf(package.id) > -1) {
                        return false;
                    }
                    if (searchTerm == "") {
                        return true;
                    }
                    return (
                        package.name.toLowerCase().indexOf(searchTerm) > -1 ||
                        package.shortDescription.toLowerCase().indexOf(searchTerm) > -1
                    );
                });

                //reformat the object for display purposes
                filteredPackageList.forEach(function (package) {
                    if (package.date) {
                        package.date = new Date(package.date);
                    } else {
                        package.date = new Date("1970-01-01T00:00:00Z");
                    }

                    package.reviewCount = 0;

                    package.versions.forEach(function (item) {
                        item.current = (item.iOSVersion == iOSVersion &&
                            item.tweakVersion == package.latest);
                        if (data.filter != "") {
                            if (data.filter != item.outcome.calculatedStatus) {
                                item.current = false;
                            }
                        }
                        if (item.current && item.date) { //set the package date to the version date
                            package.date = new Date(item.date);
                        }
                        item.classObject = {
                            "label-success": (item.outcome.calculatedStatus == "Working"),
                            "label-danger": (item.outcome.calculatedStatus == "Not working"),
                            "label-warning": (item.outcome.calculatedStatus == "Likely working"),
                            "label-default": (item.outcome.calculatedStatus == "Unknown")
                        };

                        //push up reviewCount totals to top
                        if (item.current && item.outcome.total > package.reviewCount) {
                            package.reviewCount = item.outcome.total;
                        }
                        
                    });
                });
                
                if (data.sort == "") {
                    //date sort
                    filteredPackageList.sort(function (a, b) { return (a.date > b.date) ? -1 : ((b.date > a.date) ? 1 : 0); });
                } else if (data.sort == "Top") {
                    filteredPackageList.sort(function (a, b) { return (a.reviewCount > b.reviewCount) ? -1 : ((b.reviewCount > a.reviewCount) ? 1 : 0); });
                }
                return filteredPackageList;
            }
        },
        methods: {
            relativeDate: function (dt) {
                if (dt.getTime() == 0) {
                    return "";
                }
                return moment(dt).fromNow();
            },
            getDeviceName: function (deviceId) {
                var devices = this.data.devices;
                var found = devices.find(function (device) {
                    return device.deviceId == deviceId;
                });
                return found ? found.deviceName : "Unknown device";
            },
            selectOSFilter: function (event, index) {
                this.data.iOSVersionIndex = index;
            },
            fetch: function () {
                var c = this;
                if (c.data.iOSVersions.length == 0) {
                    return;
                }
                var selectediOS = c.data.iOSVersions[c.data.iOSVersionIndex];

                if (c.data.packageCache.hasOwnProperty(selectediOS)) {
                    c.data.packages = c.data.packageCache[selectediOS].slice();

                    c.data.categories = c.data.packages.map(function (package) {
                        return package.category;
                    }).filter(function (value, index, self) {
                        return self.indexOf(value) === index;
                    });

                } else {
                    $.getJSON("json/iOS/" + selectediOS + ".json", function (data) {
                        c.data.packageCache[selectediOS] = data.packages.slice();
                        c.fetch();
                    });
                }
            }
        }
    });


    vm = new Vue({
        el: "#app",
        data: {},
        components: {
            tweaklist: TweakList
        }
    });

});

