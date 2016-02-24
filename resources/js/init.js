/* Init functions */

$('.dropdown-secondlevel-nav').dropdownHover();

/* Adjust font size of h1 headings */
$.fn.h1FitText = function () {
    if ($(this).hasClass('document')) { $(this).fitText(1.4, {minFontSize: '32px', maxFontSize: '40px'}) }
    else if ($(this).hasClass('home')) { $(this).fitText(1.4, {minFontSize: '42px', maxFontSize: '70px'}) }
    else if ($(this).html().length > 30) { $(this).fitText(1.4, {minFontSize: '32px', maxFontSize: '40px'}) }
    else $(this).fitText(1.4, {minFontSize: '42px', maxFontSize: '70px'});
};

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
            updatePage(params);
        }
    })
};

$.fn.rangeSlider = function () 
{
    this.ionRangeSlider({
        min: +moment($(this).attr('data-min-slider')),
        max: +moment($(this).attr('data-max-slider')),
        from: +moment($(this).attr('data-from-slider')),
        to: +moment($(this).attr('data-to-slider')),
        grid: true,
        step: 100,
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
            
            updatePage(params);
        }
    });
};

$.fn.obfuscateEMail = function () {
    if($(this).length === 0) {}
    else {
        var e = $(this).html().substring(0, $(this).html().indexOf('[')).trim();
        var t = $(this).html().substring($(this).html().indexOf(']') +1).trim();
        var r = '' + e + '@' + t ;
        $(this).attr('href',' mailto:' +r).html(r);
    }
}

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

// set the right tab and location for person pages 
$.fn.toggleTab = function () {
    /* make "biographies" the default if no fragment identifier is given*/
    var tabHash = (location.hash.length == 0? '#biographies': location.hash);
    
    $(this).each(function(n,tab) {
        var tabId = tab.href.substring(tab.href.indexOf('#'));
        if(tab.href.endsWith(tabHash)) {
            $(tab).parent().addClass('resp-tab-active');
            $(tabId).addClass('resp-tab-content-active');
        }else {
            $(tab).parent().removeClass('resp-tab-active');
            $(tabId).removeClass('resp-tab-content-active');
            $(tabId).hide();
        }
    });
    if($(this).length !== 0) { activateTab(); }
};

// load and activate person tab
function activateTab() {
    var activeTab = $('li.resp-tab-active a');
        var container = activeTab.attr('href');
        var url = activeTab.attr('data-target');

        // Do not load the page twice
        if ($(container).contents()[1].nodeType !== 1) {
            ajaxCall(container, url)
        }
        /* update facets */
/*        $('select').selectpicker({});*/
/*        $(href).unmask;*/
};

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
});

/* checkbox for display of undated documents */
$(document).on('click', '.undated', function() {
    var params = active_facets();
    updatePage(params);
})

$('.allFilter').on('change', 'label', function() {
    var params = active_facets();
    updatePage(params);
})

$('.obfuscate-email').obfuscateEMail();

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
    if($('.undated:checked').length) {
      params['facets'].push('undated=true');
    }
    /* Get date values from range slider */
    if($('.rangeSlider:visible').length) {
        params['fromDate'] = $('.rangeSlider:visible').attr('data-from-slider');
        params['toDate'] = $('.rangeSlider:visible').attr('data-to-slider');
    }
    /* get values from checkboxes for docTypes at search page */
    $('.allFilter:visible :checked').each(function() {
        var facet = $(this).attr('name');
        var value = $(this).attr('value');
/*        console.log(facet + '=' + value);*/
        params['facets'].push(facet + '=' + encodeURI(value))
    })
    if($('#query-string').length) {
        params['facets'].push('q=' + $('#query-string').text());
    }
    return params;
}

/* Helper function */
/* See whether we're in a person context and need to update via AJAX
 * or on an index page and need to refresh the whole page
 */
function updatePage(params) {
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

// helper function to grab AJAX content for popovers
function details_in_popup(link, div_id){
    $.ajax({
        url: link,
        success: function(response){
            var source = $('<div>' + response + '</div>');
            $('#'+div_id).html(source.find('#meta').html());
            $('.popover-title').html('<a href="' + link + '">' + source.find('h1').text() + '</a>');
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


$('h1').h1FitText();

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
    activate: activateTab
});

/* Folgender Aufruf *nach* der Initialisierung durch easyResponsiveTabs() */
$('.resp-tab-item a').toggleTab();

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
            $('.page-link:visible').on('click', 
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

/* Fieser Hack */
$('#facsimile-tab').on('click', function() {
    setTimeout(function() {
       if ($('#map:visible')){
           initFacsimile();
       }
   }, 500);
});

function initFacsimile() {
    var map;
    var iiifLayers = {};
    
    map = L.map('map', {
        center: [0, 0],
        crs: L.CRS.Simple,
        zoom: 0
    });
    
    var manifestUrl = $('#map').attr('data-url');

    // Grab a IIIF manifest
    $.getJSON(manifestUrl, function(data) {
      // For each image create a L.TileLayer.Iiif object and add that to an object literal for the layer control
      $.each(data.sequences[0].canvases, function(_, val) {
        iiifLayers[val.label] = L.tileLayer.iiif(val.images[0].resource.service['@id'] + '/info.json');
      });
        // Add layers control to the map
        L.control.layers(iiifLayers).addTo(map);
        
        // Access the first Iiif object and add it to the map
        iiifLayers[Object.keys(iiifLayers)[0]].addTo(map);
    });
};

function jump2diary(dateText) {
    var lang = getLanguage();
    var url = $('#datePicker').attr('data-dev-url') + "?func=get-diary-by-date&format=json&date=" + dateText + "&lang=" + lang ;
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

$('#create-newID').on('click', function() {
    $('#newID-result i').show();
    var docType = $('#newID-select :selected').val();
    $.getJSON('../dev/api.xql?func=get-new-id&format=json&docType='+docType, function(response) {
        $('#newID-result span').html(response);
    });
    $('#newID-result i').hide();
    $('#newID-result span').show();
});
