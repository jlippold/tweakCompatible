$(document).ready(function () {
    $.getJSON("tweaks.json", function (data) {
        console.log(data);
    });
});