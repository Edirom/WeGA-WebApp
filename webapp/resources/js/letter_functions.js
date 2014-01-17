var pic;
var cont;

var MAX_WIDTH = 700;
var MAX_HEIGHT = 700;

var MIN_DISPLAY_WIDTH = parseInt(MAX_WIDTH * 0.1);
var MIN_DISPLAY_HEIGHT = parseInt(MAX_HEIGHT * 0.1);

var DEFAULT_SCALE_FACTOR = 0.2;

function requestLetterContext(id, lang) {
    var url='functions/getAjax.xql?function=requestLetterContext&id='+id+'&lang='+lang;
    var uniqId = uniqid();
    var ajaxLoader = new Element('span', {'id': uniqId, 'class': 'ajaxLoader'}).update(wegaSettings.ajaxLoaderCombined);
    $('context').insert(ajaxLoader);
    new Ajax.Updater({success: 'context'}, url, {
        onFailure: function() { 
            alert(getErrorMessage(lang));
            writeWeGALog('Could not get '+url);
            $(uniqId).remove()            
        }
    });
};

function switchActivTab(className, activeTabId) {
    var tabs = $$('div.'+className)
    for (x in tabs) {
        if(tabs[x].id == activeTabId) {tabs[x].style.display='block';}
        else {tabs[x].style.display='none';}
    };
};

function zoomIn(offsetX, offsetY, scaleFactor) {
    
    $('hiRes').hide();
    
    var scaleFactor = 1+DEFAULT_SCALE_FACTOR;

    var picLayout = new Element.Layout(pic);
    var contLayout = new Element.Layout(cont);

    var newMarginLeft;
    var newMarginTop;

    if(!offsetX || !offsetY) {
        var centerX = parseInt(MAX_WIDTH / 2) - picLayout.get('margin-left');
        var centerY = parseInt(MAX_HEIGHT / 2) - picLayout.get('margin-top');
    
        newMarginLeft = parseInt((MAX_WIDTH / 2) - (centerX * scaleFactor));
        newMarginTop = parseInt((MAX_HEIGHT / 2) - (centerY * scaleFactor));
        
    }else {
    
        var centerX = offsetX - picLayout.get('margin-left');
        var centerY = offsetY - picLayout.get('margin-top');
        
        newMarginLeft = parseInt(offsetX - (centerX * scaleFactor));
        newMarginTop = parseInt(offsetY - (centerY * scaleFactor));
    }

    var newWidth = parseInt(scaleFactor * picLayout.get('width'));
    var newHeight = parseInt(scaleFactor * picLayout.get('height'));
    
    // DR: auf externe Methoden umgestellt
    setPicSize(newWidth);
    setPicOffset(newMarginLeft, newMarginTop);
    
    callLoadHiResImage();
};

function callLoadHiResImage() {
    var timeStamp = (new Date()).getTime();
    lastHiResTimeStamp = timeStamp;
    window.setTimeout('loadHiResImage(' + timeStamp + ')', 300);
};

function loadHiResImage(timeStamp) {
    
    if(lastHiResTimeStamp && lastHiResTimeStamp > timeStamp)
        return;

    var picLayout = new Element.Layout(pic);
    var contLayout = new Element.Layout(cont);

    // abbrechen, wenn scale = 1
    if(initialLayout.get('width') >= picLayout.get('width') && initialLayout.get('height') >= picLayout.get('height')) {
        $('hiRes').hide();
        return;
    }
    
    var marginLeft = picLayout.get('margin-left');
    var marginTop = picLayout.get('margin-top');
    
    var wx = -marginLeft / picLayout.get('width');
    var wy = -marginTop / picLayout.get('height');
    
    var ww = contLayout.get('width') / picLayout.get('width');
    var wh = contLayout.get('height') / picLayout.get('height');

    var imagePath = pic.src;
/*    imagePath = imagePath.replace(/&?d[wh]=\d+/g,'');*/
    imagePath = imagePath.replace(/ww=\d+/,'ww='+ww);
    imagePath = imagePath.replace(/wh=\d+/,'wh='+wh);
    imagePath = imagePath.replace(/wx=\d+/,'wx='+wx);
    imagePath = imagePath.replace(/wy=\d+/,'wy='+wy);
    
    myHiResImage = new Image();
    myHiResImage.onload = function() {

        if(lastHiResTimeStamp && lastHiResTimeStamp > timeStamp) 
            return;
        
        $('hiRes').src = myHiResImage.src;
        
        if(lastHiResTimeStamp && lastHiResTimeStamp > timeStamp)
            return;
        
        var picLayout = new Element.Layout(pic);
        
        if(picLayout.get('margin-left') > 0)
            $('hiRes').setStyle({marginLeft: picLayout.get('margin-left')+'px'});
        else
            $('hiRes').setStyle({marginLeft: '0px'});
        
        if(picLayout.get('margin-top') > 0)
            $('hiRes').setStyle({marginTop: picLayout.get('margin-top')+'px'});
        else
            $('hiRes').setStyle({marginTop: '0px'});
        
        if(lastHiResTimeStamp && lastHiResTimeStamp > timeStamp)
            return;
        
        $('hiRes').show();
    };
    
    myHiResImage.src = imagePath;
};

function zoomOut(offsetX, offsetY, scaleFactor) {
    
    $('hiRes').hide();
    
    var scaleFactor = 1+DEFAULT_SCALE_FACTOR;
    
    var picLayout = new Element.Layout(pic);
    var contLayout = new Element.Layout(cont);
    
    // DR: Auf minimale Größe beschränkt
    var limitWidth = (picLayout.get('width') / picLayout.get('height')) >= 1;
    if(limitWidth && parseInt(picLayout.get('width') / (scaleFactor)) < MAX_WIDTH)
        scaleFactor = (picLayout.get('width') / MAX_WIDTH);
    
    else if(!limitWidth && parseInt(picLayout.get('height') / (scaleFactor)) < MAX_HEIGHT)
        scaleFactor = (picLayout.get('height') / MAX_HEIGHT);
        
    var newMarginLeft;
    var newMarginTop;

    if(!offsetX || !offsetY) {
        var centerX = parseInt(MAX_WIDTH / 2) - picLayout.get('margin-left');
        var centerY = parseInt(MAX_HEIGHT / 2) - picLayout.get('margin-top');
    
        newMarginLeft = parseInt((MAX_WIDTH / 2) - (centerX / scaleFactor));
        newMarginTop = parseInt((MAX_HEIGHT / 2) - (centerY / scaleFactor));
        
    }else {
    
        var centerX = offsetX - picLayout.get('margin-left');
        var centerY = offsetY - picLayout.get('margin-top');
        
        newMarginLeft = parseInt(offsetX - (centerX / scaleFactor));
        newMarginTop = parseInt(offsetY - (centerY / scaleFactor));
    }
    
    var newWidth =  parseInt(picLayout.get('width') / (scaleFactor));
    var newHeight = parseInt(picLayout.get('height') / (scaleFactor));
    
    // DR: auf externe Methoden umgestellt
    setPicSize(newWidth);
    setPicOffset(newMarginLeft, newMarginTop);
    
    callLoadHiResImage();
};

// DR: auf externe Methoden umgestellt
function setPicSize(width) {
    pic.setStyle({
        width: width+'px',
        });
};

function setPicOffset(x, y) {

    var picLayout = new Element.Layout(pic);

    if(x < MIN_DISPLAY_WIDTH - picLayout.get('width'))
        x = MIN_DISPLAY_WIDTH - picLayout.get('width');
    
    if(y < MIN_DISPLAY_HEIGHT - picLayout.get('height'))
        y = MIN_DISPLAY_HEIGHT - picLayout.get('height');
    
    if(x > MAX_WIDTH - MIN_DISPLAY_WIDTH)
        x = MAX_WIDTH - MIN_DISPLAY_WIDTH;
    
    if(y > MAX_HEIGHT - MIN_DISPLAY_HEIGHT)
        y = MAX_HEIGHT - MIN_DISPLAY_HEIGHT;

    pic.setStyle({
        marginLeft: x+'px',
        marginTop: y+'px'
        });
};

function initPicDrag(e) {

    $('hiRes').hide();
    $('container').setStyle({
        'user-select': 'none',
        '-moz-user-select': 'none',
        '-webkit-user-select': 'none',
        '-webkit-user-drag': 'none'
    });

    var currentPicOffsets = pic.cumulativeOffset();

    mouseOffX = e.pageX - currentPicOffsets[0];
    mouseOffY = e.pageY - currentPicOffsets[1];
    
    document.observe('mousemove', picMouseMove);
    document.observe('mouseup', picMouseUp);
};

function picMouseMove(e) {
    
    $('hiRes').hide();
    var currentContOffsets = cont.cumulativeOffset();
    
    var x = e.pageX - mouseOffX - currentContOffsets[0];
    var y = e.pageY - mouseOffY - currentContOffsets[1];

    setPicOffset(x, y);
    
};

function picMouseUp(e) {
    document.stopObserving("mousemove", picMouseMove);
    document.stopObserving("mouseup", picMouseUp);
    
    $('container').setStyle({
        'user-select': 'inherit',
        '-moz-user-select': 'inherit',
        '-webkit-user-select': 'auto',
        '-webkit-user-drag': 'auto'
    });
    
    callLoadHiResImage();
};

function initDigilib() {
    pic = $('pic');
    cont = $('picHandler');

    $('picHandler').observe('dblclick', zoomByDoubleClick);
    $('picHandler').observe('mousedown', initPicDrag);

    // DR: zentrieren
    var picLayout = new Element.Layout(pic);
    initialLayout = picLayout;
    
    setPicOffset(parseInt((MAX_WIDTH - picLayout.get("width")) / 2), parseInt((MAX_HEIGHT - picLayout.get("height")) / 2));
};

function zoomByDoubleClick(event) {
    var mouseX = event.layerX;
    var mouseY = event.layerY;
    
    zoomIn(mouseX, mouseY);
};  