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
                devices: [],
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
                                if (data.repositories.indexOf(c.package.repository) > -1) {
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
                });
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