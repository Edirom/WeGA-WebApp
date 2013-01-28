/* ****************************** */
/* JaavaScript functions for      */ 
/* use in development environment */
/* ****************************** */

function generateID(lang) {
    var containerID = 'newID';
    var docType = $$('a.selected')[0].firstChild.nodeValue;
    if (!$(containerID)) return;
    var url = 'functions/getAjax.xql?function=generateID&lang='+lang+'&docType='+docType;
    var uniqId = uniqid();
    var ajaxLoader = new Element('div', {'id': uniqId, 'class': 'ajaxLoader'}).update(wegaSettings.ajaxLoaderCombined);
    $(containerID).update(ajaxLoader);
    new Ajax.Updater({success: containerID}, url, {
        onFailure: function() { 
            alert(getErrorMessage());
            writeWeGALog('Could not get '+url);
            $(uniqId).remove();
        }
    });
};

function validateIDs(lang) {
    var containerID = options.containerID;
    var docType = $$('a.selected')[0].firstChild.nodeValue;
/*    if (!$(containerID)) return;*/
    var url = 'functions/getAjax.xql?function=validateIDs&lang='+lang+'&docType='+docType;
    var uniqId = uniqid();
    var ajaxLoader = new Element('div', {'id': uniqId, 'class': 'ajaxLoader'}).update(wegaSettings.ajaxLoaderCombined);
    $(containerID).update(ajaxLoader);
    new Ajax.Updater({success: containerID}, url, {
        onFailure: function() { 
            alert(getErrorMessage());
            writeWeGALog('Could not get '+url);
            $(uniqId).remove();
        }
    });
};

function validatePNDs(lang) {
    var containerID = options.containerID;
    var docType = $$('a.selected')[0].firstChild.nodeValue;
/*    if (!$(containerID)) return;*/
    var url = 'functions/getAjax.xql?function=validatePNDs&lang='+lang+'&docType='+docType;
    var uniqId = uniqid();
    var ajaxLoader = new Element('div', {'id': uniqId, 'class': 'ajaxLoader'}).update(wegaSettings.ajaxLoaderCombined);
    $(containerID).update(ajaxLoader);
    new Ajax.Updater({success: containerID}, url, {
        onFailure: function() { 
            alert(getErrorMessage());
            writeWeGALog('Could not get '+url);
            $(uniqId).remove();
        }
    });
};

function validatePaths(lang) {
    var containerID = options.containerID;
    var docType = $$('a.selected')[0].firstChild.nodeValue;
/*    if (!$(containerID)) return;*/
    var url = 'functions/getAjax.xql?function=validatePaths&lang='+lang+'&docType='+docType;
    var uniqId = uniqid();
    var ajaxLoader = new Element('div', {'id': uniqId, 'class': 'ajaxLoader'}).update(wegaSettings.ajaxLoaderCombined);
    $(containerID).update(ajaxLoader);
    new Ajax.Updater({success: containerID}, url, {
        onFailure: function() { 
            alert(getErrorMessage());
            writeWeGALog('Could not get '+url);
            $(uniqId).remove();
        }
    });
};