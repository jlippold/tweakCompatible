$(document).ready(function () {
    $.getJSON("tweaks.json", function (data) {
        console.log(data);
    });

    $(".input-group-btn .dropdown-menu li a").click(function () {

        var selText = $(this).html();

        //working version - for single button //
        //$('.btn:first-child').html(selText+'<span class="caret"></span>');  

        //working version - for multiple buttons //
        $(this).parents('.input-group-btn').find('.btn-search').html(selText);

    });
});