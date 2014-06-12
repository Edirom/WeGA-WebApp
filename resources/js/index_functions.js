function requestTodaysEvents(date,lang) {
    var url='functions/getAjax.xql?function=getTodaysEvents&lang='+lang+'&date='+date;
    var uniqId = uniqid();
    var ajaxLoader = new Element('span', {'id': uniqId, 'class': 'ajaxLoader'}).update(wegaSettings.ajaxLoaderCombined);
    $('todaysEvents').insert(ajaxLoader);
    new Ajax.Updater({success: 'todaysEvents'}, url, {
        onFailure: function() { 
            alert(getErrorMessage(lang));
            writeWeGALog('Could not get '+url);
            $(uniqId).remove();
        }
    });
};

function requestNewFffiID() {
    var url='functions/createNewFffiID.xql';
    var uniqId = uniqid();
    var ajaxLoader = new Element('span', {'id': uniqId, 'class': 'ajaxLoader'}).update(wegaSettings.ajaxLoaderCombined);
    $('fffi-ID').update(ajaxLoader);
    new Ajax.Updater({success: 'fffi-ID'}, url, {
        onFailure: function() { 
            alert(getErrorMessage());
            writeWeGALog('Could not get '+url);
            $(uniqId).remove()            
        }
    });
};