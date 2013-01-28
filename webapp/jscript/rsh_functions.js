function create_RSH() {
     window.dhtmlHistory.create({
       toJSON:   function(o) { return Object.toJSON(o); },
       fromJSON: function(s) { return s.evalJSON(); }
     });
}
/** Startet RSH */
function initializeRSH() {
   dhtmlHistory.initialize();                                   // initialize RSH
   dhtmlHistory.addListener(handleHistoryChange);               // add ourselves as a listener for history change events
   var initialLocation = dhtmlHistory.getCurrentLocation();     // determine our current location so we can initialize ourselves at startup
   if (initialLocation == null) initialLocation = "location1";  // if no location specified, use the default
   updateUI(initialLocation,null);                              // now initialize our starting UI   
}
/** A function that is called whenever the user presses the back or forward buttons. 
  * This function will be passed the newLocation, as well as any history data we associated with the location. */
function handleHistoryChange(newLocation, historyData) {
    updateUI(newLocation, historyData); // use the history data to update our UI                          
}
 
/** Updates our user interface using the new location. */
function updateUI(newLocation, historyData) {
    if(historyData != null) {
        if(historyData.type == 'search') {
            requestSearchResults(historyData.lang,historyData.searchString);
            $('input_0').value = historyData.searchString;
            $$('#searchOptions input').each(function(x) {                
                if(x.type=='checkbox') {
                    if(historyData.docType.match(x.value)) x.checked = true;
                    else x.checked = false;
                }
            });
        }
        else if(historyData.type == 'register') {
            var url = 'functions/updateFilterNColl.xql?docType='+historyData.docType+historyData.checked+"&cacheKey="+historyData.cacheKey;
            var uniqId = uniqid();
            
            var ajaxLoader = new Element('div', {'id': uniqId, 'class': 'ajaxLoader', 'style': 'border:2px solid #AAA;'}).update(wegaSettings.ajaxLoaderCombined);
            $('facetsFromFacetFile').update(ajaxLoader);
            
            new Ajax.Request(url, {
              onSuccess: function (t) {
                  var numberOfResults = t.responseText;
                  $('facetsFromFacetFile').update(historyData.filterMenu);
                  buildChronoAlpha(historyData.docType, historyData.id, historyData.lang);
                  showEntries(undefined,1, numberOfResults, historyData.lang, 'sessionColl'+historyData.docType);
                  if(historyData.isTitlePage) history.go(-1); // damit kein doppeltes Zurückklicken nötig ist
                  scrollToTop();
              },
              onFailure: function () {
                  alert(getErrorMessage(lang));
                  writeWeGALog('Could not get '+url);
              }
            });
        }
    }
}

function saveListToRSH(lang,type,docType,cacheKey,numberOfResults,checked,filterMenu) {
    var isTitlePage = checked=="";
    var id = getSeconds();
    dhtmlHistory.add(id,{lang:lang,type:type,docType:docType,cacheKey:cacheKey,numberOfResults:numberOfResults,checked:checked,filterMenu:filterMenu,isTitlePage:isTitlePage});
}

function saveSearchToRSH(lang,type,docType,searchString) {
    var id = getSeconds();
    dhtmlHistory.add(id,{lang:lang,type:type,searchString:searchString,docType:docType});
}

function getSeconds() { var newDate = new Date; return newDate.getTime();}