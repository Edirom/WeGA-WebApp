/* Init functions */

$('.dropdown-secondlevel-nav').dropdownHover();

$("h1").fitText(1.4, {minFontSize: '42px', maxFontSize: '70px'});
$("h1.document").fitText(1.4, {minFontSize: '32px', maxFontSize: '40px'});


$('select').selectpicker({});

$('#details').easyResponsiveTabs();


$("[data-hovered-src]").hover(
        
        function(){
    $(this).data("original-src",$(this).attr("src"));
    $(this).attr("src",($(this).data("hovered-src")));
},

function(){
          $(this).data("hovered-src",$(this).attr("src"));
    $(this).attr("src",($(this).data("original-src")));
} );

function showEntries(that)
{

    $("#filter span").removeClass("activeFilterElement");
    $(that).addClass("activeFilterElement");
}

function changeIconCollapse(that)
{
    if ($(that).children("i").first().hasClass("fa-caret-up"))
    {
        $(that).children("i").first().removeClass("fa-caret-up");
        $(that).children("i").first().addClass("fa-caret-down");

        $(that).removeClass("inner-shadow-light");
        $(that).addClass("gradient-light");

    }

    else if ($(that).children("i").first().hasClass("fa-caret-down"))
    {
        $(that).children("i").first().removeClass("fa-caret-down");
        $(that).children("i").first().addClass("fa-caret-up");

        $(that).removeClass("gradient-light");
        $(that).addClass("inner-shadow-light");
    }




    else if ($(that).children("i").first().hasClass("fa-plus-circle"))
    {
        $(that).children("i").first().removeClass("fa-plus-circle");
        $(that).children("i").first().addClass("fa-minus-circle");
    }

    else if ($(that).children("i").first().hasClass("fa-minus-circle"))
    {
        $(that).children("i").first().removeClass("fa-minus-circle");
        $(that).children("i").first().addClass("fa-plus-circle");
    }
}



function addSearchOption(that)
{
    
    $(that).closest(".col-md-9").append("<div class='searchform'>"+$(that).closest(".searchform").html()+"</div>");
}
