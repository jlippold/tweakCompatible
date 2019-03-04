var vm;
var userDetails;

$(document).ready(function () {

    checkAction();

    var Submission = Vue.extend({
        template: "#submission-template",
        data: function () {
            var d = {};
            d.data = {};
            if (userDetails) {
                d.data = userDetails;
            }

            d.data.chosenStatus = "working";
            d.data.notes = "";
            if (userDetails && userDetails.action) {
                if (userDetails.action != "working") {
                    d.data.chosenStatus = "notworking";
                }
            }
            return d;
        },
        methods: {
            github: function () {
                $('#github').submit();
                setTimeout(function (params) {
                    window.location.href = "thanks.html";
                }, 100);
            }
        },
        computed: {
            issueTitle: function () {
                if (this.data && this.data.action) {
                    return "`" + this.data.userInfo.packageName + "`" +
                        " " + this.data.chosenStatus +
                        " on iOS " +
                        this.data.userInfo.iOSVersion;
                }
                return "";
            },
            issueBody: function () {
                if (this.data && this.data.action) {
                    return "```\n" + JSON.stringify(this.data, null, 2) + "\n```"
                }
                return "";
            }
        }
    });

    vm = new Vue({
        el: "#app",
        data: {},
        components: {
            submission: Submission
        }
    });

});

