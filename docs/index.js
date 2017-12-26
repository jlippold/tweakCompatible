var vm;
var tweakList;
var userDetails;

$(document).ready(function () {

    var TweakList = Vue.extend({
        template: "#tweaklist-template",
        data: function () {
            return {
                data: {
                    searchTerm: "",
                    iOSVersionIndex: 2,
                    categories: [],
                    iOSVersions: [],
                    devices: [],
                    packages: []
                }
            };
        },
        mounted: function () {
            var c = this;
            this.fetch();
        },
        computed: {
            filteredPackages: function () {

                var data = this.data;
                var iOSVersion = data.iOSVersions[data.iOSVersionIndex];
                var searchTerm = data.searchTerm.toLowerCase();

                var filteredPackageList = data.packages.filter(function (package) {
                    if (searchTerm == "") {
                        return true;
                    }
                    return (
                        package.name.toLowerCase().indexOf(searchTerm) > -1 ||
                        package.depiction.toLowerCase().indexOf(searchTerm) > -1
                    );
                });


                //reformat the object for display purposes
                filteredPackageList.forEach(function (package) {
                    package.versions.forEach(function (item) {

                        item.current = (item.iOSVersion == iOSVersion &&
                            item.tweakVersion == package.latest);
                        item.classObject = {
                            "label-success": (item.outcome.calculatedStatus == "Working"),
                            "label-danger": (item.outcome.calculatedStatus == "Not working"),
                            "label-warning": (item.outcome.calculatedStatus == "Likely working"),
                            "label-default": (item.outcome.calculatedStatus == "Unknown")
                        };

                    });
                });

                return filteredPackageList;

            }
        },
        methods: {
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
                $.getJSON("tweaks.json", function (data) {
                    c.data.categories = data.categories.slice();
                    c.data.iOSVersions = data.iOSVersions.slice();
                    c.data.devices = data.devices.slice();
                    c.data.packages = data.packages.slice();
                    //detect ios version from useragent
                    var v = iOSVersion();
                    if (v) {
                        c.data.iOSVersions.forEach(function (vers, idx) {
                            if (v == vers) {
                                c.data.iOSVersionIndex = idx;
                            }
                        });
                    }
                });
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


function iOSVersion() {
    if (window.MSStream) {
        // There is some iOS in Windows Phone...
        // https://msdn.microsoft.com/en-us/library/hh869301(v=vs.85).aspx
        return false;
    }
    var match = (navigator.appVersion).match(/OS (\d+)_(\d+)_?(\d+)?/),
        version;

    if (match !== undefined && match !== null) {
        version = [
            parseInt(match[1], 10),
            parseInt(match[2], 10),
            parseInt(match[3] || 0, 10)
        ];
        return parseFloat(version.join('.'));
    }

    return false;
}