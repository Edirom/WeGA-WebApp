function unhideChildElements(obj) {
    $('alphaChronoList').select('ul').invoke('hide');
    obj.nextSiblings().invoke('toggle');
/*            alert('Something went wrong...');*/
};

/*  
    Deprecated: 
    wird aufgelöst durch buildFacetsFromFacetsfile() und 
    buildChronoAlpha()
*/
/*function buildFilterMenu(lang,docType,id,numberOfResults,checked) {
    var url='functions/register_filterMenu.xql?docType='+docType+'&lang='+lang+'&id='+id;
    var uniqId = uniqid();
    var ajaxLoader = new Element('div', {'id': uniqId, 'class': 'ajaxLoader', 'style': 'border:2px solid #AAA;'}).update(wegaSettings.ajaxLoaderCombined);
    $('contentLeft').update(ajaxLoader); 
    new Ajax.Request(url, {
        onSuccess: function (t) {
            $('contentLeft').update(t.responseText);
            saveListToRSH(lang,'register',docType,id,numberOfResults,checked,t.responseText);
        },
        onFailure: function() { 
            alert(getErrorMessage(lang));
            writeWeGALog('Could not get '+url);
            $(uniqId).remove();
        }
    });
};
*/

/* 
	Wrapper Function: 
	creates the left hand side filter lists on list views
*/
function createListViewMenu(docType, id, countColl, lang, checked) {
	buildChronoAlpha(docType, id, lang);
	buildFacetsFromFacetsfile(docType, id, countColl, lang, checked);
};

/* 
	Wrapper Funktion: 
	Fragt lediglich die Anzahl der Kategorien ab und lässt diese von 
	buildIndividualFacetFromFacetsfile() erstellen 
*/
function buildFacetsFromFacetsfile(docType, id, countColl, lang, checked) {
    var getFacetsUrl='functions/getAjax.xql?function=getFacetCategories&docType='+docType;
    $('facetsFromFacetFile').update('');
    new Ajax.Request(getFacetsUrl, {
        onSuccess: function (t) {
            var entriesCount=parseInt(t.responseText);
            /*for (i=1; i <= entriesCount; i++) {
                buildIndividualFacetFromFacetsfile(i,docType,id,lang)
            };*/
            buildIndividualFacetFromFacetsfile(entriesCount,docType,id,lang,countColl,checked);
        },
        onFailure: function() { 
            alert(getErrorMessage(lang));
            writeWeGALog('Could not get '+getFacetsUrl);
        },
        onComplete: function() {
        	if(entryNo > 1) {buildIndividualFacetFromFacetsfile(entryNo-1, docType, id, lang,countColl,checked)}
        }
    });
};

function buildIndividualFacetFromFacetsfile(entryNo, docType, id, lang, countColl, checked) {
    var url = 'functions/getAjax.xql?function=createFacetFromFacetFile&docType='+docType+'&lang='+lang+'&id='+id+'&entryNo='+entryNo;
    var uniqId = uniqid();
    var ajaxLoader = new Element('span', {'id': uniqId, 'class': 'ajaxLoader'}).update(wegaSettings.ajaxLoaderCombined);
    $('facetsFromFacetFile').insert(ajaxLoader);
    new Ajax.Request(url, {
        onSuccess: function (t) {
            $(uniqId).replace(t.responseText);
        },
        onFailure: function() { 
            alert(getErrorMessage(lang));
            writeWeGALog('Could not get '+url);
            $(uniqId).remove();
        },
        onComplete: function() {
        	if(entryNo > 1) buildIndividualFacetFromFacetsfile(entryNo-1, docType, id, lang,countColl,checked);
        	else saveListToRSH(lang,'register',docType,id,countColl,checked,$('facetsFromFacetFile').innerHTML);
        }
    });
};

/*
	Creates a chronological (alphabetical) menu on list views, 
	populating div@id="chronoAlphaList"
*/
function buildChronoAlpha(docType, id, lang) {
	var url = 'functions/getAjax.xql?function=createChronoAlphaMenu&docType='+docType+'&lang='+lang+'&id='+id;
	var uniqId = uniqid();
    var ajaxLoader = new Element('span', {'id': uniqId, 'class': 'ajaxLoader'}).update(wegaSettings.ajaxLoaderCombined);
    $('chronoAlphaList').update(ajaxLoader);
	new Ajax.Updater({success:'chronoAlphaList'}, url,{
        onFailure: function() { 
            alert(getErrorMessage(lang));
            writeWeGALog('Could not get '+url);
            $(uniqId).remove();
        }
    });
};

/*
	Simple AJAX Update for Chronological Submenu
*/
function toggleSubMenu(obj, entriesSessionName, orderSessionName, lang){
	var url = 'functions/getAjax.xql?function=getSubMenu&entriesSessionName='+entriesSessionName+'&lang='+lang+'&orderSessionName='+orderSessionName;
	var uniqId = uniqid();
    var ajaxLoader = new Element('div', {'id': uniqId}).update(wegaSettings.ajaxLoaderImageBar);
    if (obj.nextSibling != null) {
    	obj.nextSibling.toggle();
    	obj.parentNode.toggleClassName('collapsed');
    	obj.parentNode.toggleClassName('expanded');
    }
    else {
    	obj.parentNode.appendChild(ajaxLoader);
    	obj.parentNode.toggleClassName('collapsed');
    	obj.parentNode.toggleClassName('expanded');
		new Ajax.Updater({success:uniqId}, url,{
	        onFailure: function() { 
	            alert(getErrorMessage(lang));
	            writeWeGALog('Could not get '+url);
	            $(uniqId).remove();
	        }
	    });
    }
};

function showEntries(obj, countFrom, countMax, lang, sessionName) {
	/* 
		1. Check whether the parent element (or in case of undated items the element itself) is already checked --> nothing to do
		2. Check whether obj is undefined (given by the initial call of showEntries() by register.xql)
	*/
	var testObj = (obj === undefined)?true:!(obj.parentNode.hasClassName('checked') || obj.hasClassName('checked'));
	
	if (testObj) {
		/* 
		First, toggle className 'checked' of the parent li element and uncheck the rest
		UNLESS obj is undefined = initial call of showEntries() by register.xql
		*/
		if(!(obj === undefined)) {
	        $('chronoAlphaList').select('.checked').invoke('removeClassName', 'checked');
	        if(obj.hasClassName('undated')) {obj.addClassName('checked');}
	        else {obj.parentNode.addClassName('checked');}
	    }
	
		/* Second, populate the right hand side container with the actual entries */
	    var container = options.containerID /*getOption('ajaxContainerId')*/;
	    var countTo = (parseInt(countMax) > parseInt(options.entriesPerPage) + parseInt(countFrom))?parseInt(options.entriesPerPage) + parseInt(countFrom) - 1:parseInt(countMax);
	    var url = 'functions/showEntries.xql?countFrom='+countFrom+'&countTo='+countTo+'&lang='+lang+'&sessionName='+sessionName;
	    var uniqId = uniqid();
	    var ajaxLoader = new Element('div', {'id': uniqId, 'class': 'ajaxLoader'}).update(wegaSettings.ajaxLoaderCombined);
	    $(container).update(ajaxLoader);
	    new Ajax.Updater({success:container}, url,{
	        onSuccess: function() {        
	            var numberOfResults = countMax - countFrom + 1;
	/*            console.log(sessionName, numberOfResults, lang, countFrom, countMax);*/
	            if (parseInt(countMax) - parseInt(countFrom) > parseInt(options.entriesPerPage)) {
	                startIS(sessionName, numberOfResults, lang, countFrom, countMax);
	/*                console.log('started infiniteScroll');*/
	            }
	            else {
	                clearInterval(thisInterval);
	/*                console.log('terminated infinite scroll');*/
	                return;
	            }
	            
	        },
	        onFailure: function() { 
	            alert(getErrorMessage(lang));
	            writeWeGALog('Could not get '+url);
	            $(uniqId).remove();
	        }
	    });
    }
};

function applyFilter(invokingElement, docType, cacheKey, lang) {
    $('popupMain').setStyle({visibility:'hidden'});
    
    var invokingElementValue = $(invokingElement).parentNode.readAttribute('value'); // docStatus_candidate
    var checked = (invokingElement.parentNode.hasAttribute('class'))?'':'&checked='+invokingElementValue;
    
    if($(invokingElement).parentNode.id != 'popupTabs')
        var checkList = $('facetsFromFacetFile').select('.checked') /*'#contentLeft div ul li.checked'*/;
        else var checkList = $('popupContent').select('.checked') /*'#popupContent div ul li.checked'*/;
    
    /*$$(checkList)*/ checkList.each(function(item) {
        if(item.readAttribute('value') != invokingElementValue) checked += ('&checked='+item.readAttribute('value'));
    });
    
    /*filterList.each(function(item){ if(item != invokingElementValue) checked += ('&checked='+item); });*/
/*    $('overlay').style.display="";*/
    
    var url = 'functions/updateFilterNColl.xql?docType='+docType+checked+"&cacheKey="+cacheKey;
/*    var ajaxLoader = new Element('span', {'id': uniqId, 'class': 'ajaxLoader', 'style': 'border:2px solid #AAA; display:block;'}).update(wegaSettings.ajaxLoaderCombined);*/
    new Ajax.Request(url, {
        onSuccess: function (t) {
            var numberOfResults = t.responseText;
/*            buildFilterMenu(lang,docType,cacheKey,numberOfResults,checked);*/
			createListViewMenu(docType, cacheKey, numberOfResults, lang, checked);
            showEntries(undefined, 1, numberOfResults, lang, 'sessionColl'+docType);
/*            $('overlay').style.display="none";*/
        },
        onFailure: function () {
            alert(getErrorMessage(lang));
            writeWeGALog('Could not get '+url);
/*            $('overlay').style.display="none";*/
        }
    });
};

function loadPopup(category,docType,cacheKey) {
	var ajaxLoader = new Element('span', {'class': 'ajaxLoader'}).update(wegaSettings.ajaxLoaderCombined);
	$('overlay').setStyle({display:'block'});
	
	var popupMainHeight    = (document.viewport.getHeight()*0.8)+'px';
    var popupMainWidth     = (document.viewport.getWidth()>1000)?(document.viewport.getWidth()*0.6)+'px':(document.viewport.getWidth()>700)?(document.viewport.getWidth()*0.8)+'px':'500px';
    var popupContentHeight = (document.viewport.getHeight()*0.8-100)+'px';
    var popupContentWidth  = (document.viewport.getWidth()>1000)?(document.viewport.getWidth()*0.6-20)+'px':(document.viewport.getWidth()>700)?(document.viewport.getWidth()*0.8-20)+'px':'474px';
    var popupMainLeft      = (document.viewport.getWidth()>1000)?'20%':'10%';
    
    $('popupMain').setStyle({height:popupMainHeight,width:popupMainWidth,left:popupMainLeft});
    $('popupContent').setStyle({height:popupContentHeight,width:popupContentWidth});
	
	$('popupContent').update(ajaxLoader);
	$('popupMain').setStyle({visibility:'visible'});
	
    var url = 'functions/register_loadPopup.xql?category='+category+'&docType='+docType+'&cacheKey='+cacheKey;
    new Ajax.Updater({success: 'popupMain'}, url, {
        onComplete: function() {
            $('popupContent').setStyle({height:popupContentHeight,width:popupContentWidth});
        },
        onFailure: function() { 
            alert(getErrorMessage());
            writeWeGALog('Could not get '+url);
        }
    });
};

function scrollToTop() {
    window.document.body.scrollTop = 0;
    window.document.documentElement.scrollTop = 0;
};

function clickOnPopupListElement(elem) {
    var thisValue = elem.parentNode.readAttribute('value');
    if(elem.parentNode.className != 'checked') elem.parentNode.className = 'checked';
    else elem.parentNode.className = '';
}

function clickOnPopupTab (elem,cat) {
    $$('#popupTabs li a').each(function(item) { item.className = ''; });
    elem.firstChild.className = 'selected';
    $$('#popupContent div').each(function(item) { if(item.readAttribute('id') != 'popupContent_'+cat) item.setStyle({display:'none'}); else item.setStyle({display:'block'}); });
};
