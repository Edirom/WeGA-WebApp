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
        onChange: function(e){
            /* Get active facets to append as URL params */
            var params = active_facets();
            
            /* AJAX call for personal writings etc. */
            if($('li.resp-tab-active').length === 1) {
                var url = $('li.resp-tab-active a').attr('data-target') + params.toString();
                var container = $('li.resp-tab-active a').attr('href');
                ajaxCall(container, url);
            }
            /* Refresh page for indices */
            else {
                self.location=params.toString();
            }
        }
    })
};

$.fn.rangeSlider = function () 
{
    this.ionRangeSlider({
        min: +moment(this.attr('data-min')),
        max: +moment(this.attr('data-max')),
        from: +moment(this.attr('data-from')),
        to: +moment(this.attr('data-to')),
        grid: true,
        type: "double",
        //force_edges: true,
        grid_num: 3,
        keyboard: true,
        prettify: function (num) {
            var m = moment(num).locale("de");
            return m.format("D. MMM YYYY");
        },
        onFinish: function (data) {
            /* Get active facets to append as URL params */
            var params = active_facets();
            
            /* Overwrite date params with new values from the slider */
            params['fromDate'] = moment(data.from).locale("de").format("YYYY-MM-DD");
            params['toDate'] = moment(data.to).locale("de").format("YYYY-MM-DD");
            
            /* AJAX call for personal writings etc. */
            if($('li.resp-tab-active').length === 1) {
                var url = $('li.resp-tab-active a').attr('data-target') + params.toString();
                var container = $('li.resp-tab-active a').attr('href');
                ajaxCall(container, url)
            }
            /* Refresh page for indices */
            else {
                self.location = params.toString();
            }
        }
    });
};

// remove popovers when clicking somewhere
$('body').on('click', function (e) {
    $('[data-original-title]').each(function () {
        //the 'is' for buttons that trigger popups
        //the 'has' for icons within a button that triggers a popup
        if (!$(this).is(e.target) && $(this).has(e.target).length === 0 && $('.popover').has(e.target).length === 0) {
            $(this).popover('hide');
        }
    });
});

// create popovers for links
$('a.persons').on('click', function() {
    $(this).popover({
        "html": true,
        "trigger": "manual",
        'placement': 'auto top',
        'title': function() {
            return 'Loading …'
        },
        "content": function(){
            var div_id =  "tmp-id-" + $.now();
            link = $(this).attr('href');
            return details_in_popup(link, div_id);
        }
    });
    $(this).popover('show')
    return false;
})

/* checkbox for display of undated documents*/
$(':checkbox').on('click', function() {
    var params = active_facets();
    self.location = params.toString();
})

/* Helper function */
/* Get active facets to append as URL parameters */
function active_facets() {
    var params = {
        facets:[],
        fromDate:'',
        toDate:'',
        toString:function(){
            return '?' + this.facets.join('&') + ( this.fromDate !== '' ? '&fromDate=' + this.fromDate + '&toDate=' + this.toDate :'')
        }
     };
    /* Set filters */
    $('.allFilter:visible :selected').each(function() {
        var facet = $(this).parent().attr('name');
        var value = $(this).attr('value');
        /*console.log(facet + '=' + value);*/
        params['facets'].push(facet + '=' + encodeURI(value))
    })
    /* checkbox for display of undated documents*/
    if($('#undated:checked').length) {
      params['facets'].push('undated=true');
    }
    /* Get date values from range slider */
    if($('.rangeSlider:visible').length) {
        params['fromDate'] = $('.rangeSlider:visible').attr('data-from');
        params['toDate'] = $('.rangeSlider:visible').attr('data-to');
    }
    return params;
}

// helper function to grab AJAX content for popovers
function details_in_popup(link, div_id){
    $.ajax({
        url: link,
        success: function(response){
            var source = $('<div>' + response + '</div>');
            $('#'+div_id).html(source.find('#meta').html());
            $('.popover-title').html(source.find('h1').text());
            $('.popover-content div.iconographie').hide();
            $('.popover-content div.basicdata h2').hide();
            // remove col-classes
            $('.popover-content div.portrait').attr('class', 'portrait');
            $('.popover-content div.basicdata').attr('class', 'basicdata');
        }
    });
    return '<div id="'+ div_id +'"><div class="progress" style="min-width:244px"><div class="progress-bar progress-bar-striped active" role="progressbar" aria-valuenow="100" aria-valuemin="0" aria-valuemax="100" style="width:100%;"></div></div></div>';
}

/* only needed after ajax calls?!? --> see later */
/* needed on index page for the search box, as well */
//$('select').selectize({});

/* Initialise selectize plugin for facets on index pages */
$('.allFilter select').facets();

/* Initialise range slider for index pages */
$('.allFilter:visible .rangeSlider').rangeSlider();


/* Initialise popovers for notes */
$('.noteMarker').popover({
  'html': true,
  'placement': 'auto top',
  'title': function(){
      var noteID=$(this).attr('data-ref');
      var note=$('#' + noteID);
      return note.attr('data-title');
  },
  'content': function() {
      var noteID=$(this).attr('data-ref');
      var note=$('#' + noteID);
      return note.html();
  }
});

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

/* Watch filters and highlight spans in text */
$('.allFilter input').change(
  function() {
    var key = $(this).attr('value');
    $('.' + key).toggleClass('hi')
  }
)

function ajaxCall(container,url) {
    $(container).mask();
    $(container).load(url, function(response, status, xhr) {
        if ( status == "error" ) {
            console.log(xhr.status + ": " + xhr.statusText);
        }
        else {
            /* update facets */
            $('.allFilter:visible select').facets();
            $('.allFilter:visible .rangeSlider').rangeSlider();
            /* Listen for click events on pagination */
            $('.page-link').on('click', 
                function() {
                    var activeTab = $('li.resp-tab-active a');
                    var baseUrl = activeTab.attr('data-target');
                    var url = baseUrl + $(this).attr('data-url');
                    //console.log(url);
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

$("#datePicker").datepicker({
    dateFormat: "yy-mm-dd",
    minDate: "1810-02-26",
    maxDate: "1826-06-03",
    defaultDate: getDiaryDate(),
    changeMonth: true,
    changeYear: true,
    onSelect: function(dateText, inst) { 
        jump2diary(dateText)
    },
    beforeShowDay: function(date) {
        return [ checkValidDiaryDate(date)  ]
    }
});

$('#map').each(function() {
    initFacsimile();
});

function initFacsimile() {
    var originalMaxSize = $('#map').attr('data-originalMaxSize');
    var url = $('#map').attr('data-url');
    var maxZoomLevel = 0;
    
    while(originalMaxSize > 256){
        originalMaxSize = originalMaxSize/2;
        maxZoomLevel++;
    }
    console.log("maxZoomLevel: "+maxZoomLevel);
    console.log("url: "+url);
    
    var map = L.map('map').setView([0, 0], 0);
    var facsimileTile =  L.tileLayer.facsimileLayer(url, {
        minZoom: 0,
        maxZoom: maxZoomLevel,
        continuousWorld : true
    });
    facsimileTile.addTo(map);
};

function jump2diary(dateText) {
    var lang = getLanguage();
    var url = "http://localhost:8080/exist/apps/WeGA-WebApp/dev/api.xql?func=get-diary-by-date&format=json&date=" + dateText + "&lang=" + lang ;
    $.getJSON(url, function(data) {
        self.location=data.url + '.html';
    })
};

/* Exclude missing diary days */
function checkValidDiaryDate(date) {
    /* 5-20 April 1814 */
    /* 26-31. Mai */
    /* 1-9 Juni */
    /* 19-30 Juni */
    /* 1-26 Juli */
    var start1 =  new Date('04/05/1814');
    var end1 =  new Date('04/20/1814');
    var start2 =  new Date('05/26/1814');
    var end2 =  new Date('05/31/1814');
    var start3 =  new Date('06/01/1814');
    var end3 =  new Date('06/09/1814');
    var start4 =  new Date('06/19/1814');
    var end4 =  new Date('06/30/1814');
    var start5 =  new Date('07/01/1814');
    var end5 =  new Date('07/26/1814');
    return !(
        (date >= start1 && date <= end1) ||
        (date >= start2 && date <= end2) ||
        (date >= start3 && date <= end3) ||
        (date >= start4 && date <= end4) ||
        (date >= start5 && date <= end5)
    )
};

/* Get the current language from the top navigation */
function getLanguage() {
    return $('#navbarCollapse li.active:last a').html().toLowerCase()
};

/* Get the current diary date from the h1 heading */
function getDiaryDate() {
    var title = $('h1.document').html();
    var lang = getLanguage();
    var format;
    if(lang === 'de') { 
        format = "DD, dd. MM yy" 
    } 
    else { 
        format = "DD, MM dd, yy" 
    } ; 
    
    try { 
        var date = 
            $.datepicker.parseDate( format, title, {
              dayNamesShort: $.datepicker.regional[ lang ].dayNamesShort,
              dayNames: $.datepicker.regional[ lang ].dayNames,
              monthNamesShort: $.datepicker.regional[ lang ].monthNamesShort,
              monthNames: $.datepicker.regional[ lang ].monthNames
            });
    }
    catch(err) { date = '' }
    return date
};

/* Get the document ID from the breadcrumb */
function getID() {
    return $('.breadcrumb li:last').html()
};

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
