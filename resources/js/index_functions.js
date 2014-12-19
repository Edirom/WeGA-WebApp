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

function getNewID() {
    var selected = $F('select-options');
    var url='../dev/api.xql?func=get-new-id&docType='+selected;
    var uniqId = uniqid();
    var ajaxLoader = new Element('span', {'id': uniqId, 'class': 'ajaxLoader'}).update(wegaSettings.ajaxLoaderImageBar);
    $('id-value').show();
    $('id-value').update(ajaxLoader);
    new Ajax.Request(url, {
        method: 'get',
        onSuccess: function(response) {
            var foo = new Element('span').update(response.responseText);
            $('id-value').update(foo.textContent);
            $(uniqId).remove() 
        },
        onFailure: function() { 
            alert(getErrorMessage());
            writeWeGALog('Could not get '+url);
            $(uniqId).remove()            
        }
    })
};