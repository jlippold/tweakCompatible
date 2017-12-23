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

function checkAction() {

    var hash = window.location.hash;
    var packageId, action, userInfo, base64;
    if (hash) {
        hash = hash.substring(3);
        var parts = hash.split("/");
        if (parts.length == 3) {
            packageId = parts[0];
            action = parts[1];
            userInfo;
            try {
                base64 = parts[2];
                userInfo = JSON.parse(atob(base64));
            } catch (err) {
                userInfo = null;
            }
        }
    }

    if (packageId && action && userInfo && base64) {
        userDetails = {
            packageId: packageId,
            action: action,
            userInfo: userInfo,
            base64: base64
        };
    }
}