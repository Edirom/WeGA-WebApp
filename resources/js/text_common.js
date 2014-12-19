var wegaSettings = {};
wegaSettings.ajaxLoaderImage = "<img src='" + joinPathElements([options.baseHref,options.html_pixDir,'ajax-loader.gif']) + "' alt='spinning-wheel'/>";
wegaSettings.ajaxLoaderImageBar = "<img src='" + joinPathElements([options.baseHref,options.html_pixDir,'ajax-loader2.gif']) + "' alt='spinning-wheel'/>";
wegaSettings.ajaxLoaderText = "Requesting content …";
wegaSettings.ajaxLoaderCombined = wegaSettings.ajaxLoaderImage+wegaSettings.ajaxLoaderText;

function joinPathElements(segs) {
    return segs.join('/').replace(/\/+/g, '/');
};

function metaDataToTip(id, lang){
    var uniqId = uniqid('id');
    var ajaxLoader = '<div id=\"'+uniqId+'\">'+wegaSettings.ajaxLoaderImage+'</div>';
    Tip(ajaxLoader, WIDTH, 240);
    var url='functions/getAjax.xql?function=getMetaData&id='+id+'&lang='+lang+'&usage=toolTip';
    new Ajax.Updater({success: uniqId}, url, {
        onFailure: function() {
            alert(getErrorMessage(lang));
            writeWeGALog('Could not get '+url);
        }
    });
};

function highlightSpanClassInText(htmlClass,invokingElement){
    var nodes=$$('span.'.concat(htmlClass));
    if (invokingElement.hasClassName('highlighted')) nodes.invoke('removeClassName', 'highlighted');
    else nodes.invoke('addClassName', 'highlighted');
    invokingElement.toggleClassName('highlighted');
};

function getListFromEntriesWithKey(id, lang, containerID, entry) {
    var url='functions/getAjax.xql?function=getListFromEntriesWithKey&lang='+lang+'&id='+id+'&entry='+entry;
    var uniqId = uniqid();
    var ajaxLoader = new Element('li', {'id': uniqId, 'class': 'ajaxLoader'}).update(wegaSettings.ajaxLoaderCombined);
    $(containerID).insert(ajaxLoader);
    new Ajax.Updater({success: containerID}, url, {
        onFailure: function() {
            alert(getErrorMessage(lang));
            writeWeGALog('Could not get '+url);
        },
        onSuccess: function() { $(uniqId).remove() }
    });
};

function getListFromEntriesWithoutKey(id, lang, containerID, entry) {
    var url='functions/getAjax.xql?function=getListFromEntriesWithoutKey&lang='+lang+'&id='+id+'&entry='+entry;
    var uniqId = uniqid();
    var ajaxLoader = new Element('li', {'id': uniqId, 'class': 'ajaxLoader'}).update(wegaSettings.ajaxLoaderCombined);
    $(containerID).insert(ajaxLoader);
    new Ajax.Updater({success: containerID}, url, {
        onFailure: function() {
            alert(getErrorMessage(lang));
            writeWeGALog('Could not get '+url);
        },
        onSuccess: function() { $(uniqId).remove() }
    });
};

function requestDiaryContext(contextContainer,docID,lang) {
    var url='functions/getAjax.xql?function=getDiaryContext&id='+docID+'&contextContainer='+contextContainer+'&lang='+lang;
    var uniqId = uniqid();
    var ajaxLoader = new Element('span', {'id': uniqId, 'class': 'ajaxLoader'}).update(wegaSettings.ajaxLoaderCombined);
    $(contextContainer).insert(ajaxLoader);
    new Ajax.Updater({success: contextContainer}, url, {
        onFailure: function() {
            alert(getErrorMessage(lang));
            writeWeGALog('Could not get '+url);
        },
        onSuccess: function() { $(uniqId).remove() }
    });
};

function requestNewsContext(contextContainer,docID,lang) {
    var url='functions/getAjax.xql?function=getNewsContext&id='+docID+'&contextContainer='+contextContainer+'&lang='+lang;
    var uniqId = uniqid();
    var ajaxLoader = new Element('span', {'id': uniqId, 'class': 'ajaxLoader'}).update(wegaSettings.ajaxLoaderCombined);
    $(contextContainer).insert(ajaxLoader);
    new Ajax.Updater({success: contextContainer}, url, {
        onFailure: function() {
            alert(getErrorMessage(lang));
            writeWeGALog('Could not get '+url);
        },
        onSuccess: function() { $(uniqId).remove() }
    });
};

function decEma(s) {
    var numbers = s.split(' ');
    var myString = '';
    numbers.each(function(item) {
        if(item!='')
            myString += String.fromCharCode(parseInt(item) / parseInt(options.salt));
    });
    location.href="mailto:"+myString.replace(' [at] ', '@');
};

function uniqid (prefix, more_entropy) {
    // +   original by: Kevin van Zonneveld (http://kevin.vanzonneveld.net)
    // +    revised by: Kankrelune (http://www.webfaktory.info/)
    // %        note 1: Uses an internal counter (in php_js global) to avoid collision
    // *     example 1: uniqid();
    // *     returns 1: 'a30285b160c14'
    // *     example 2: uniqid('foo');
    // *     returns 2: 'fooa30285b1cd361'
    // *     example 3: uniqid('bar', true);
    // *     returns 3: 'bara20285b23dfd1.31879087'

    if (typeof prefix == 'undefined') {
        prefix = "";
    }

    var retId;
    var formatSeed = function (seed, reqWidth) {
        seed = parseInt(seed,10).toString(16); // to hex str
        if (reqWidth < seed.length) { // so long we split
            return seed.slice(seed.length - reqWidth);
        }
        if (reqWidth > seed.length) { // so short we pad
            return Array(1 + (reqWidth - seed.length)).join('0')+seed;
        }
        return seed;
    };

    // BEGIN REDUNDANT
    if (!this.php_js) {
        this.php_js = {};
    }
    // END REDUNDANT
    if (!this.php_js.uniqidSeed) { // init seed with big random int
        this.php_js.uniqidSeed = Math.floor(Math.random() * 0x75bcd15);
    }
    this.php_js.uniqidSeed++;

    retId  = prefix; // start with prefix, add current milliseconds hex string
    retId += formatSeed(parseInt(new Date().getTime()/1000,10),8);
    retId += formatSeed(this.php_js.uniqidSeed,5); // add seed hex string

    if (more_entropy) {
        // for more entropy we add a float lower to 10
        retId += (Math.random()*10).toFixed(8).toString();
    }

    return retId;
};

/**
 * Diese Funktion wird immer dann aufgerufen, wenn eine Ajax-Anfrage fehlschlägt.
 **/

function writeWeGALog(text,logLevel) {
    if(!logLevel) logLevel = 'error';
    var url = 'functions/writeWeGALog.xql?text='+encodeURIComponent(text)+'&logLevel='+logLevel;
    new Ajax.Request(url,{});
};

function getErrorMessage(lang) {
    if(lang == 'de') return 'Ups, das hätte nicht passieren dürfen!';
    else return 'Sorry, that should not have happened!';
};

function switchActivTab(className, activeTabId) {
    var tabs = $$('div.'+className)
    tabs.each(function(x) {
        if(x.id == activeTabId) {x.show();}
        else {x.hide();}
    });
};
