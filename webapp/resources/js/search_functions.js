function extractSyntaxTerms(string,term) {
    var result = '';
    var quotationMarkTokens = string.split('"');    
    for(var i=1;i<quotationMarkTokens.length;i+=2) {
        temp = quotationMarkTokens[i].replace(/\s/g,'_');
        string = string.replace(quotationMarkTokens[i],temp);
    }
    var quotationMarkTokens = string.split("'");    
    for(var i=1;i<quotationMarkTokens.length;i+=2) {
        temp = quotationMarkTokens[i].replace(/\s/g,'_');
        string = string.replace(quotationMarkTokens[i],temp);
    }
    if(term=='') {
        var regEx = string.replace(/(persName|persNameSender|persNameAddressee|placeName|date|id|pnd|ks|asksam|occupation):(\S*)/g,'');
        result=regEx;
    }
    else {
        var regEx = new RegExp(term+":(\\S+)");
        while(string.match(regEx)!=null) {
            result += string.match(regEx)[1]+' ';
            string = string.replace(string.match(regEx)[0],'');
        }
    }
    return result.replace(/^\s*|\s*$|^\s*|\s(?=\s)|\s*$/g, ''); // trim & normalize-space
}

/**
 * n Nummer des input-Feldes
 * value Wert des Input-Feldes (für History nötig)
 * selectIndexes optional (wird nur dann verwendet, wenn die Browser-History aufgerufen wird und die select-Boxen eingestellt werden und die "mehr..."-Schaltflächen entfert müssen) 
 */
function requestSelectRow(lang, n, value, selectIndexes) {
    //console.log(lang, n, value);
    if(n==1) value = $('input_0').value;
    
    var url='functions/search_createSelectRow.xql?lang='+lang+'&n='+n+'&value='+value;
    new Ajax.Updater({success:'searchFields'}, url,{
        insertion:'bottom',
        onSuccess: function() {
            $('input_'+n).focus;
            ///console.log('input_'+n);
            if(selectIndexes) {
                for(var i=1;i<selectIndexes.length;i++) {
                    document.getElementById("cat_"+i).selectedIndex = selectIndexes[i-1];
                    if(i<selectIndexes.length-1) document.getElementById("input_"+i).parentNode.lastChild.previousSibling.toggle();
                }
            }
        },
        onFailure: function () {
            alert(getErrorMessage(lang));
            writeWeGALog('Could not get '+url);
        }
    });
};

/**
 * Erstellt erst einen leeren Container für die Suchergebnisse (mit Spinningwheel) und lädt diese dann da hinein.
 */

function showSearchResults(page,numberOfResults,firstTime, lang) {
    var container = options.containerID;
    //console.log('Lade Seite '+page);
    var entriesPerPage = parseInt(options.entriesPerPage);
    var numberOfPages  = numberOfResults/entriesPerPage;
    var sessionName = options.searchSessionName;
    
    var elemId = "swheel_"+page;
    var spinningWheelImage = new Element('img', {"src": options.baseHref+"/"+options.html_pixDir+"/ajax-loader.gif", "alt":"spinning-wheel"}); 
    spinningWheelImage.setStyle({margin:'20px'});
    
    var spinningWheelContainer = new Element('div', {'class':'searchResultEntry', 'id':elemId});
    spinningWheelContainer.setStyle({textAlign:'center'});
    spinningWheelContainer.appendChild(spinningWheelImage);
    
    $(container).appendChild(spinningWheelContainer);
    
    var url = 'functions/showEntries.xql?countFrom=1'+'&countTo='+entriesPerPage+'&lang='+lang+'&sessionName='+sessionName;
    new Ajax.Request(url, { method: 'get',
        onSuccess: function (t) {
            //saveSearchResultInRSH(searchString,page,t.responseText,input);
/*            console.log(t.responseText);*/
            $(container).update(t.responseText);
            if(numberOfResults > entriesPerPage) {
                startIS(sessionName, numberOfResults, lang, 1, numberOfResults);
/*                console.log('started infinite scroll');*/
            }
            else {clearInterval(thisInterval);}
        },
        onFailure: function() {
            alert(getErrorMessage(lang));
            writeWeGALog('Could not get '+url);
        }
    });
}

function buildSearchParameters(searchString) {
    var searchParameters = '';
    searchParameters += extractSyntaxTerms(searchString,''                  )==''?'':'&fullText='         +extractSyntaxTerms(searchString,'');
    searchParameters += extractSyntaxTerms(searchString,'persName'          )==''?'':'&persName='         +extractSyntaxTerms(searchString,'persName');
    searchParameters += extractSyntaxTerms(searchString,'persNameSender'    )==''?'':'&persNameSender='   +extractSyntaxTerms(searchString,'persNameSender');
    searchParameters += extractSyntaxTerms(searchString,'persNameAddressee' )==''?'':'&persNameAddressee='+extractSyntaxTerms(searchString,'persNameAddressee');
    searchParameters += extractSyntaxTerms(searchString,'placeName'         )==''?'':'&placeName='        +extractSyntaxTerms(searchString,'placeName');
    searchParameters += extractSyntaxTerms(searchString,'date'              )==''?'':'&date='             +extractSyntaxTerms(searchString,'date');
    searchParameters += extractSyntaxTerms(searchString,'id'                )==''?'':'&id='               +extractSyntaxTerms(searchString,'id');
    searchParameters += extractSyntaxTerms(searchString,'pnd'               )==''?'':'&pnd='              +extractSyntaxTerms(searchString,'pnd');
    searchParameters += extractSyntaxTerms(searchString,'ks'                )==''?'':'&ks='               +extractSyntaxTerms(searchString,'ks');
    searchParameters += extractSyntaxTerms(searchString,'asksam'            )==''?'':'&asksam='           +extractSyntaxTerms(searchString,'asksam');
    searchParameters += extractSyntaxTerms(searchString,'occupation'        )==''?'':'&occupation='       +extractSyntaxTerms(searchString,'occupation');
    
    return searchParameters;
}

function startSearch(container,searchString,docType,historySearch,lang) {
    //$('autoComplete').hide();
    var searchParameters = buildSearchParameters(searchString);
    var url='functions/search_getResults.xql?lang='+lang+'&page=1'+/*'&type='+*/docType+'&searchString='+searchString+searchParameters;
    
    new Ajax.Request(url, {
       onComplete: function (t) {
           $(container).update();
           clearInterval(thisInterval);
           var numberOfResults = parseInt(t.responseText);
           $('numberOfSearchResultsCount').update(numberOfResults);
           if(numberOfResults==1) { $('oneSearchResult').show(); $('manySearchResults').hide(); }
           else {                   $('oneSearchResult').hide(); $('manySearchResults').show(); }
           $('numberOfSearchResults').show();
           if(!isNaN(numberOfResults) && numberOfResults > 0) showSearchResults(1,numberOfResults,true,lang);
           window.scrollTo(0,0); // damit der nicht die gespeicherte scrolling-Höhe speichert (mit RSH muss das noch anders werden)
           $('overlaySpinningWheelContainer').toggle();
           /*document.getElementById('overlay').toggle();
           document.getElementById('overlaySpinningWheelContainer').toggle();*/
           if(historySearch == 0) saveSearchToRSH(lang,'search',docType,searchString);
       },
       onFailure: function () { 
           alert(getErrorMessage(lang));
           writeWeGALog('Could not get '+url);
           /*document.getElementById('overlay').toggle();
           document.getElementById('overlaySpinningWheelContainer').toggle();*/
       }  
    });
}

function requestSearchResults(lang,historySearch) {
    var container = options.containerID;
    
    var checkedDocTypes = $('searchForm').select('input[checked]');
    var docType = '';
    for(var i=0;i<checkedDocTypes.length;i++) { docType += '&collection='+checkedDocTypes[i].value; }
    
    var arrayPageSize  = this.getPageSize();
    /*$('overlay').setStyle({ width: arrayPageSize[0] + 'px', height: arrayPageSize[1] + 'px' });
    $('overlay').toggle();*/
    $('overlaySpinningWheelContainer').toggle();
    //$('autoComplete').style.display='none';
    
    if(historySearch != 0) var searchString = historySearch;
    else {
        if($('input_1')) {
            var searchString = '';
            var n = -1; // input_0 nicht mitzählen
            $$('.search-input').each(function(){n++});
            //console.log(n);
            for(var i=1;i<=n;i++) {
                if($('input_'+i).value.replace(/\s/g,'') != '') {
                   if($('cat_'+i).value != '') searchString += $('cat_'+i).value+':';
                   searchString += $('input_'+i).value+' ';
                }
            }
        }
        else var searchString = $('input_0').value;
    }
    
    var searchString = searchString.replace('#','');
    var searchString = searchString.replace(',','');
        
    // Eingabe einer ID abfangen
    if(searchString.match(/^A+\d{6}$/)) {
       var urlID = "functions/getAjax.xql?function=search_testID&id="+searchString+"&lang="+lang;
       new Ajax.Request(urlID, {
           onSuccess: function(t) {
               // Wenn es die Seite gibt, dann hingehen.
               var response = t.responseText;
               if(response != '') location.href = response;
               else startSearch(container,searchString,docType,historySearch,lang);
           }
       });
    }
    else startSearch(container,searchString,docType,historySearch,lang);
}

/* Stolen from Lightbox */
function getPageSize() {
	    var xScroll, yScroll;
		if (window.innerHeight && window.scrollMaxY) {	
			xScroll = window.innerWidth + window.scrollMaxX;
			yScroll = window.innerHeight + window.scrollMaxY;
		} else if (document.body.scrollHeight > document.body.offsetHeight){ // all but Explorer Mac
			xScroll = document.body.scrollWidth;
			yScroll = document.body.scrollHeight;
		} else { // Explorer Mac...would also work in Explorer 6 Strict, Mozilla and Safari
			xScroll = document.body.offsetWidth;
			yScroll = document.body.offsetHeight;
		}		
		var windowWidth, windowHeight;		
		if (self.innerHeight) {	// all except Explorer
			if(document.documentElement.clientWidth){ windowWidth = document.documentElement.clientWidth; }
            else { windowWidth = self.innerWidth; }
			windowHeight = self.innerHeight;
		} else if (document.documentElement && document.documentElement.clientHeight) { // Explorer 6 Strict Mode
			windowWidth = document.documentElement.clientWidth;
			windowHeight = document.documentElement.clientHeight;
		} else if (document.body) { // other Explorers
			windowWidth = document.body.clientWidth;
			windowHeight = document.body.clientHeight;
		}
		// for small pages with total height less then height of the viewport
		if(yScroll < windowHeight) { pageHeight = windowHeight; }
        else { pageHeight = yScroll; }
		// for small pages with total width less then width of the viewport
		if(xScroll < windowWidth){ pageWidth = xScroll; }
        else { pageWidth = windowWidth; }
		return [pageWidth,pageHeight];
}

/**
 * Einträge pro Seite werden auf den übergebenen Wert gesetzt.
 * @author Christian Epp
 */
/*function selectEntriesPerPage(entries) {
    //console.log("entries="+entries);
    var laC = document.getElementById(parseInt(options.entriesPerPage)).lastChild;
    if(laC.nodeName != 'BR') {
       document.getElementById('entriesPerPage').selectedIndex = entries/5-1;
       document.getElementById('entriesPerPage').removeChild(laC);
    }
}
*/
/**
 * Suchauswahloptionen werden selektiert
 * @author Christian Epp
 */
function selectSearchOptionBoxes(sOpts) {
    //console.log("sOpts="+sOpts);
    if(sOpts.match('persons'))  document.getElementsByName('auswahl')[0].checked = true;
    if(sOpts.match('letters'))  document.getElementsByName('auswahl')[1].checked = true;
    if(sOpts.match('diaries'))  document.getElementsByName('auswahl')[2].checked = true;
    if(sOpts.match('writings')) document.getElementsByName('auswahl')[3].checked = true;
    if(sOpts.match('works'))    document.getElementsByName('auswahl')[4].checked = true;
    if(sOpts.match('news'))     document.getElementsByName('auswahl')[5].checked = true;
    if(sOpts.match('biblio'))   document.getElementsByName('auswahl')[6].checked = true;
    /*if(sOpts.match('var'))     document.getElementsByName('auswahl')[7].checked = true;*/
}
/*
function initializeAutoComplete(lang) {
    //$('input_0').observe('keyup',autoComplete);
    /*var key = $('input_0').value;
    var url='functions/autoComplete.xql?key='+key+'&lang='+lang;
    new Autocomplete('input_0', { serviceUrl:url });* /
}

function selectSuggestion(text,lang) {
    $('input_0').value = text;
    $('autoComplete').style.display='none';
    requestSearchResults(lang,0)
}

/**
 * Wird gestartet, wenn ein Buchstabe getippt wurde
 * @autor Christian Epp
 * /
function autoComplete(lang) {
   //var key = e.keyCode;
   var key = $('input_0').value;

   /*$('autoComplete').update('lade');* /
   
   var timeStamp = new Date().getTime();
   
   var url='functions/autoComplete.xql?key='+key+'&lang='+lang;
   new Ajax.Request(url, {
      onSuccess: function (t) {
         var result = t.responseText;
         if($('autoComplete').readAttribute('timeStamp') < timeStamp) {
            $('autoComplete').writeAttribute('timeStamp',timeStamp);
            $('autoComplete').update(result);
         }
         $('autoComplete').show();
      },
      onFailure: function () {
         $('autoComplete').update('FEHLER! :(');
      }  
   });
}
*/