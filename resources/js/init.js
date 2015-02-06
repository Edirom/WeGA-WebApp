/* Init functions */

$('.dropdown-secondlevel-nav').dropdownHover();

$("h1").fitText(1.4, {minFontSize: '42px', maxFontSize: '70px'});
$("h1.document").fitText(1.4, {minFontSize: '32px', maxFontSize: '40px'});


/* only needed after ajax calls?!? --> see later */
/* needed on index page for the search box, as well */
$('select').selectpicker({});

/* hide tabs with no respective div content */
$('li').has('a.deactivated').hide();

/* Responsive Tabs für person.html */
$('#details').easyResponsiveTabs({
    activate: function() {
        var activeTab = $('li.resp-tab-active a');
        var href = activeTab.attr('href');
        var url = activeTab.attr('data-target');
/*        console.log(url);*/

        // Do not load the page twice
        if ($(href).contents()[1].nodeType !== 1) { 
            $(href).mask();
            $(href).load(url, function(response, status, xhr) {
                if ( status == "error" ) {
                    console.log(xhr.status + ": " + xhr.statusText);
                }
                else {
                    $('select').selectpicker({});
                }
            });
        }
        /* update facets */
        $('select').selectpicker({});
        $(href).unmask;
    }
});


/* Farbige Support Badges im footer (page.html) */
$("[data-hovered-src]").hover(
    function(){
        $(this).data("original-src",$(this).attr("src"));
        $(this).attr("src",($(this).data("hovered-src")));
    },
    function(){
        $(this).data("hovered-src",$(this).attr("src"));
        $(this).attr("src",($(this).data("original-src")));
    } 
);

/* Various functions */
function showEntries(that)
{
    $("#filter span").removeClass("activeFilterElement");
    $(that).addClass("activeFilterElement");
};

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
};

function addSearchOption(that)
{
    $(that).closest(".col-md-9").append("<div class='searchform'>"+$(that).closest(".searchform").html()+"</div>");
}
