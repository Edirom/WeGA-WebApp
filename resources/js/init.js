/* Init functions */

$('.dropdown-secondlevel-nav').dropdownHover();

$("h1").fitText(1.4, {minFontSize: '42px', maxFontSize: '70px'});
$("h1.document").fitText(1.4, {minFontSize: '32px', maxFontSize: '40px'});

/* A wrapper function for creating select boxes */
/* Needs to be placed before the invoking call */
$.fn.facets = function ()
{
     this.selectize({
        plugins: ['remove_button'],
        hideSelected: true,
        onDropdownClose: function(e){
            var params = [];
            /* Set filters */
            $('.allFilter:visible option:selected').each(function() {
                var facet = $(this).parent().attr('name');
                var value = $(this).attr('value');
                /*console.log(facet + '=' + value);*/
                params.push(facet + '=' + value)
            })
            
            /* AJAX call for personal writings etc. */
            if($('li.resp-tab-active').length === 1) {
                var url = $('li.resp-tab-active a').attr('data-target') + '?'+params.join('&');
                var container = $('li.resp-tab-active a').attr('href')
                ajaxCall(container, url)
            }
            /* Refresh page for indices */
            else {
                self.location='?'+params.join('&')
            }
        }
    })
};

/*function facetsDropdownClose(facet) {
    console.log('foo')
};*/

/* only needed after ajax calls?!? --> see later */
/* needed on index page for the search box, as well */
//$('select').selectize({});
$('.allFilter select').facets();

/* hide tabs with no respective div content */
$('li').has('a.deactivated').hide();

/* Responsive Tabs für person.html */
$('#details').easyResponsiveTabs({
    activate: function() {
        var activeTab = $('li.resp-tab-active a');
        var container = activeTab.attr('href');
        var url = activeTab.attr('data-target');
/*        console.log(url);*/

        // Do not load the page twice
        if ($(container).contents()[1].nodeType !== 1) {
            ajaxCall(container, url)
        }
        /* update facets */
/*        $('select').selectpicker({});*/
/*        $(href).unmask;*/
    }
});

function ajaxCall(container,url) {
    $(container).mask();
    $(container).load(url, function(response, status, xhr) {
        if ( status == "error" ) {
            console.log(xhr.status + ": " + xhr.statusText);
        }
        else {
            /* update facets */
            $('.allFilter select').facets();
            /* Listen for click events on pagination */
            $('.page-link').on('click', 
                function() {
                    var activeTab = $('li.resp-tab-active a');
                    var baseUrl = activeTab.attr('data-target');
                    var url = baseUrl + $(this).attr('data-url');
                    console.log(url);
                    ajaxCall(container,url);
                }
            );
        }
    });
};

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
