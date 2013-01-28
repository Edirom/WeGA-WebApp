function requestPersonMetaData(id,lang) {
    //var url='functions/getMetaData.xql?id='+id+'&lang='+lang+'&usage=singleView';
    var url='functions/getAjax.xql?function=getMetaData&id='+id+'&lang='+lang+'&usage=singleView';
    var uniqId = uniqid();
    var ajaxLoader = new Element('span', {'id': uniqId, 'class': 'ajaxLoader'}).update(wegaSettings.ajaxLoaderCombined);
    $('personSummary').insert(ajaxLoader);
    new Ajax.Updater({success: 'personSummary'}, url, {
        onFailure: function() { 
            alert(getErrorMessage(lang));
            writeWeGALog('Could not get '+url);
            $(uniqId).remove();
        },
        onSuccess: function() { $(uniqId).remove(); }/*,
        onComplete: function() { initLytebox(lang);}*/
    });
};

function requestPersonCorrespondents(id, lang, container, correspondents, fromOffset, toOffset, undated) {
    //var url = 'functions/person_getPersonCorrespondents.xql?id='+id+'&correspondents='+correspondents+'&lang='+lang+'&fromOffset='+fromOffset+'&toOffset='+toOffset+'&undated='+undated;
    var url='functions/getAjax.xql?function=getPersonCorrespondents&id='+id+'&correspondents='+correspondents+'&lang='+lang+'&fromOffset='+fromOffset+'&toOffset='+toOffset+'&undated='+undated;
    var uniqId = uniqid();
    var ajaxLoader = new Element('span', {'id': uniqId, 'class': 'ajaxLoader'}).update(wegaSettings.ajaxLoaderCombined);
    $(container).update(ajaxLoader);
    new Ajax.Updater({success: container}, url, {
        onFailure: function() { 
            alert(getErrorMessage(lang));
            writeWeGALog('Could not get '+url);
            $(uniqId).remove();
        }
/*        onSuccess: function() { $(uniqId).remove() },*/
/*        insertion: 'bottom'*/
    });
};

function requestPersonIconography(id,pnd,lang) {
    //var url='functions/person_getIconography.xql?id='+id+'&pnd='+pnd+'&lang='+lang;
    var url='functions/getAjax.xql?function=getIconography&id='+id+'&pnd='+pnd+'&lang='+lang;
    var uniqId = uniqid();
    var ajaxLoader = new Element('span', {'id': uniqId, 'class': 'ajaxLoader'}).update(wegaSettings.ajaxLoaderCombined);
    $('iconography').insert(ajaxLoader);
    new Ajax.Updater({success: 'iconography'}, url, {
        onFailure: function() { 
            alert(getErrorMessage(lang));
            writeWeGALog('Could not get '+url);
            $(uniqId).remove()
        },
        onSuccess: function() { $(uniqId).remove();},
        onComplete: function() {
        initLytebox(lang);
        },
        insertion: 'bottom'
    });
};
