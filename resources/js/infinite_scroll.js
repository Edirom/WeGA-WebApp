var pageHeight = document.documentElement.clientHeight;
var scrollPosition;
var thisInterval;

var pageIS = 1;

var isSearchResultIS = true;
var numberOfResultsIS = 0;
var countFromIS;
var countToIS;
var sessionNameIS;
var langIS;

function scroll() {
	if(navigator.appName == "Microsoft Internet Explorer") scrollPosition = document.documentElement.scrollTop; else scrollPosition = window.pageYOffset;
	pageHeight = document.documentElement.clientHeight;
	if((contentHeight().dim_y - pageHeight - scrollPosition) < pageHeight || ($('contentLeft') && $('contentLeft').getHeight() > $(options.containerID).getHeight())){
        //console.log('Nachladen mit contentHeight='+contentHeight().dim_y +', pageHeight='+ pageHeight +' und scrollPosition='+ scrollPosition);
        var numberOfPages = (numberOfResultsIS - 1) / options.entriesPerPage;
        //console.log(pageIS+' <= '+parseInt(numberOfPages+1));        
        if(pageIS <= parseInt(numberOfPages+1)) showMoreEntries();
        else {
            clearInterval(thisInterval);
/*            console.log('terminated infinite scroll');*/
            return;
        }
	    pageIS++;
	}
}

function startIS(sessionName, numberOfResults, lang, countFrom, countTo) {
    isSearchResultIS   = (sessionName == options.searchSessionName)?true:false;
    numberOfResultsIS  = numberOfResults;
    countFromIS        = countFrom;
    countToIS          = countTo;
    sessionNameIS      = sessionName;
    langIS             = lang;
    
    pageIS             = 2; //nur weil die erste Seite separat angezeigt wird!!
    
    clearInterval(thisInterval);
    thisInterval = setInterval(scroll, 600);
    
    /*console.log('started listening');*/
}

function showMoreEntries() {
    //console.log('functions/showEntries.xql?countFrom='+countFromIS+'&countTo='+countToIS+'&docType='+docTypeIS+'&page='+pageIS+'&entriesPerPage='+entriesPerPage+'&isSearchResult='+isSearchResultIS);
    var page = pageIS; 
    
    for(var i=1;i<=options.entriesPerPage;i++) {
        var elemId = "swheel_"+page+"_"+i;
        var spinningWheelImage = new Element('span', {'class': 'ajaxLoader'}).update(wegaSettings.ajaxLoaderCombined); 
            //new Element('img', {"src": options.baseHref+"/"+options.html_pixDir+"/ajax-loader.gif", "alt":"spinning-wheel"}); 
        spinningWheelImage.setStyle({margin:'20px'});
        
        var spinningWheelContainer = new Element('div', {'id':elemId});
        if(isSearchResultIS) spinningWheelContainer.setAttribute("class","searchResultEntry");
        else spinningWheelContainer.setAttribute("class","item");
        spinningWheelContainer.appendChild(spinningWheelImage);
        
        $(options.containerID).appendChild(spinningWheelContainer);
        
        if(!isSearchResultIS && i%2 == 0) {
            var clearer = document.createElement("br");
            clearer.setAttribute("class","clearer");
            clearer.setAttribute("id","swheel_"+page+"_"+i+"_clearer");
            $(options.containerID).appendChild(clearer);
        }
    }

    var countFrom = (page - 1) * options.entriesPerPage + parseInt(countFromIS);
    var countTo = (numberOfResultsIS + parseInt(countFromIS) > parseInt(options.entriesPerPage) + countFrom)?parseInt(options.entriesPerPage) + countFrom - 1:numberOfResultsIS + parseInt(countFromIS) - 1;
/*    console.log(numberOfResultsIS, countFrom, countTo);*/
    var url = 'functions/showEntries.xql?lang='+langIS+'&sessionName='+sessionNameIS+'&countFrom='+countFrom+'&countTo='+countTo;
    
    new Ajax.Request(url, { method: 'get',
        onSuccess: function (t) {
            // TODO:
            //infiniteSave('','');            
            for(var i=1;i<=options.entriesPerPage;i++) {
                var elemId = "swheel_"+page+"_"+i;
                if(i==1) $(elemId).replace(t.responseText); else     $(elemId).remove();
                if(i%2==0 && $(elemId+"_clearer")) $(elemId+"_clearer").remove();
            }
        },
        onFailure: function() {
            //alert(getErrorMessage());
            writeWeGALog('Could not get '+url);
        }
    });
}

/**
 * Diese Funktion gibt die Höhe des gesamten Inhalts der Seite zurück.
 */
function contentHeight(){
  var intAbsX = intAbsY = -1;
  var objBody = null;
  // Passendes Body-Objekt ermitteln
  if(document.all && !window.opera)     objBody =(window.document.compatMode == "CSS1Compat")? window.document.documentElement : window.document.body || null;
  else if(document.all && window.opera) objBody = document.body;
  else                                  objBody = document.documentElement;
  if(window.innerHeight && window.scrollMaxY){
    intAbsX = window.innerWidth + window.scrollMaxX;
    intAbsY = window.innerHeight + window.scrollMaxY;
  // Alle ausser Explorer Mac
  }else if(objBody.scrollHeight >= objBody.offsetHeight){
    intAbsX = objBody.scrollWidth;
    intAbsY = objBody.scrollHeight;
  // Explorer Mac, IE6 Strict, Mozilla, Safari
  }else{
    intAbsX = document.body.offsetWidth;
    intAbsY = document.body.offsetHeight;
  }
  return {dim_x: intAbsX, dim_y: intAbsY};
}