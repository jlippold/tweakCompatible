var vm;
var tweakList;
var userDetails;

$(document).ready(function () {

    checkAction();

    var Tweak = Vue.extend({
        template: "#tweak-template",
        data: function () {
            return {
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
            uniqueVersions: function() {
                return this.package.versions.map(function(v) {
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
                    devices: function (callback) {
                        $.ajax({
                            url: "devices.json",
                            dataType: 'json',
                            success: function (data) {
                                c.devices = data.devices.slice();
                                callback(null);
                            },
                            error: function (err) {
                                callback(err);
                            }
                        });
                    },
                    package: ['devices', function (callback) {
                        $.getJSON("json/packages/" + userDetails.packageId + ".json", function (data) {
                            c.package = data;
                            c.currentVersion = data.versions[0].tweakVersion;
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
