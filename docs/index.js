var vm;
var tweakList;

$(document).ready(function () {

    var TweakList = Vue.extend({
        template: "#tweaklist-template",
        data: function () {
            return {
                data: {
                    searchTerm: "",
                    iOSVersionIndex: 0,
                    allowedCategories: [],
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
                var filtered = data.packages.filter(function (package) {
                    if (searchTerm == "") {
                        return true;
                    }
                    return (
                        package.name.toLowerCase().indexOf(searchTerm) > -1 ||
                        package.depiction.toLowerCase().indexOf(searchTerm) > -1
                    );
                });

                return filtered.map(function (package) {
                    package.iOSVersion = iOSVersion;
                    package.notes = [];
                    package.outcome = {
                        status: "",
                        percentage: 100,
                        counts: {
                            good: 0,
                            bad: 0
                        }
                    };

                    if (package.status.hasOwnProperty("good")) {
                        package.status.good.forEach(function (report) {
                            if (report.iOS == iOSVersion && report.tweakVersion == package.latest) {
                                package.outcome.counts.good += report.users.length;
                                var notes = report.users.forEach(function(userReport) {
                                    userReport.status = "Working";
                                    package.notes.push(userReport);
                                });
                            }
                        });
                    }
                    if (package.status.hasOwnProperty("bad")) {
                        package.status.bad.forEach(function (report) {
                            if (report.iOS == iOSVersion && report.tweakVersion == package.latest) {
                                package.outcome.counts.bad += report.users.length;
                                var notes = report.users.forEach(function (userReport) {
                                    userReport.status = "Not Working";
                                    package.notes.push(userReport);
                                });
                            }
                        });
                    }
                    
                    package.outcome.counts.total = package.outcome.counts.good + package.outcome.counts.bad;
                    package.outcome.percentage = package.outcome.counts.total == 0 ? 0 : Math.floor((package.outcome.counts.good / package.outcome.counts.total) * 100);

                    package.outcome.status = "Not working";

                    if (package.outcome.percentage == 0) {
                        package.outcome.status = "Unknown";
                    }
                    if (package.outcome.percentage > 40) {
                        package.outcome.status = "Likely working";
                    }
                    if (package.outcome.percentage > 75) {
                        package.outcome.status = "Working";
                    }

                    package.outcome.classObject = {
                        "label-success": (package.outcome.status == "Working"),
                        "label-danger": (package.outcome.status == "Not working"),
                        "label-warning": (package.outcome.status == "Likely working"),
                        "label-default": (package.outcome.status == "Unknown")
                    };
                    return package;
                });
            }
        },
        methods: {
            getDeviceName: function(deviceId) {
                var devices = this.data.devices;
                var found = devices.find(function(device) {
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
                    c.data.allowedCategories = data.allowedCategories.slice();
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

        //working version - for single button //
        //$('.btn:first-child').html(selText+'<span class="caret"></span>');  

        //working version - for multiple buttons //
        $(this).parents('.input-group-btn').find('.btn-search').html(selText);

    });
});