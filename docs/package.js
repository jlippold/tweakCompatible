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
                    depiction: "",
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
                $.getJSON("tweaks.json", function (data) {
                    var package = data.packages.find(function(p) {
                        return p.id == userDetails.packageId;
                    });

                    if (package) {;
                        c.package = package;
                        c.devices = data.devices.slice();
                        c.currentVersion = package.versions[0].tweakVersion;
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
