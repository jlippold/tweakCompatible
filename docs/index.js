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
                    iOSVersionIndex: 0,
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

                        item.current = (item.iOSVersion == iOSVersion && item.tweakVersion == package.latest);
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
            fetch: function (done) {
                var c = this;
                $.getJSON("tweaks.json", function (data) {
                    c.data.categories = data.categories.slice();
                    c.data.iOSVersions = data.iOSVersions.slice();
                    c.data.devices = data.devices.slice();
                    c.data.packages = data.packages.slice();
                    if (done) { done(); }
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

    $(".input-group-btn .dropdown-menu li a").click(function () {
        var selText = $(this).html();
        $(this).parents('.input-group-btn').find('.btn-search').html(selText);
    });


});
