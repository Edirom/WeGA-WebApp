//**************************************************************************************************/
//	Lytebox v5.1
//
//	 Author: Markus F. Hay
//  Website: http://dolem.com/lytebox
//	   Date: September 6, 2011
//	License: Creative Commons Attribution 3.0 License (http://creativecommons.org/licenses/by/3.0/)
//**************************************************************************************************/
function Lytebox(lang) {
	
	// Below are the default settings that the lytebox viewer will inherit (look and feel, behavior) when displaying content. Member
	// properties that start with "__" can be manipulated via the data-lyte-options attribute (i.e. data-lyte-options="theme:red").
	
	/*** Language Configuration ***/
	// Note that these values will be seen by users when mousing over buttons.
		
	if(lang=='de') {
       	this.label = new Object();
       	this.label['close']		= 'Schließen (Esc)';
       	this.label['prev'] 		= 'Zurück (\u2190)';	// Previous (left arrow)
       	this.label['next'] 		= 'Weiter (\u2192)'; 		// Next (right arrow)
       	this.label['play'] 		= 'Abspielen (Leertaste)';
       	this.label['pause'] 	= 'Pause (Leertaste)';
       	this.label['print'] 	= 'Drucken';
       	this.label['image'] 	= 'Bild'; 				// Image x of x
       	this.label['page'] 		= 'Seite'; 				// Page x of x
       	this.label['of'] 		= 'von';
	}
	else {
	    this.label = new Object();
		this.label['close']		= 'Close (Esc)';
		this.label['prev'] 		= 'Previous (\u2190)';	// Previous (left arrow)
		this.label['next'] 		= 'Next (\u2192)'; 		// Next (right arrow)
		this.label['play'] 		= 'Play (spacebar)';
		this.label['pause'] 	= 'Pause (spacebar)';
		this.label['print'] 	= 'Print';
		this.label['image'] 	= 'Image'; 				// Image x of x
		this.label['page'] 		= 'Page'; 				// Page x of x
		this.label['of'] 		= 'of';
	}
		
	/*** Configure Lytebox ***/
	
		this.theme				= 'black';		// themes: black (default), grey, red, green, blue, gold, orange
		this.innerBorder		= true;			// controls whether to show the inner border around image/html content
		this.outerBorder		= true;			// controls whether to show the outer grey (or theme) border
		this.resizeSpeed		= 5;			// controls the speed of the image resizing (1=slowest and 10=fastest)
		this.maxOpacity			= 80;			// higher opacity = darker overlay, lower opacity = lighter overlay
		this.borderSize			= 12;			// if you adjust the padding in the CSS, you will need to update this variable -- otherwise, leave this alone...
		this.appendQS			= false;		// if true, will append request_from=lytebox to the QS. Use this with caution as it may cause pages to not render
		this.fixedPosition		= true;			// if true, viewer will remain in a fixed position, otherwise page scrolling will be allowed
		
		this.__hideObjects		= true;			// controls whether or not objects (such as Flash, Java, etc.) should be hidden when the viewer opens
		this.__autoResize		= true;			// controls whether or not images should be resized if larger than the browser window dimensions
		this.__doAnimations		= true;			// controls whether or not "animate" Lytebox, i.e. resize transition between images, fade in/out effects, etc.
		this.__forceCloseClick 	= false;		// if true, users are forced to click on the "Close" button when viewing content
		this.__refreshPage		= false;		// force page refresh after closing Lytebox
		this.__showPrint		= false;		// true to show print button, false to hide
		this.__navType			= 3;			// 1 = "Prev/Next" buttons on top left and left
													// 2 = "Prev/Next" buttons in navigation bar
													// 3 = navType_1 + navType_2 (show both)
													
		// These two options control the position of the title/counter and navigation buttons. Note that for mobile devices,
		// the title is displayed on top and the navigation on the bottom. This is due to the view area being limited.
		// You can customize this for non-mobile devices by changing the 2nd condition (: false) to true (: true)
		this.__navTop			= this.isMobile() ? false : false; // true to show the buttons on the top right, false to show them on bottom right (default)
		this.__titleTop			= this.isMobile() ? true : false;  // true to show the title on the top left, false to show it on the bottom left (default)
	
	
	/*** Configure Lyteframe (html viewer) Options ***/
	
		this.__width			= '80%';		// default width of content viewer
		this.__height			= '80%';		// default height of content viewer
		this.__scrollbars		= 'auto';		// controls the content viewers scollbars -- options are auto|yes|no
		this.__loopPlayback		= false;		// controls whether or not embedded media is looped (swf, avi, mov, etc.)
		this.__autoPlay			= true;			// controls whether or not to autoplay embedded media
	
	
	/*** Configure Lyteshow (slideshow) Options ***/
	
		this.__slideInterval	= 4000;			// change value (milliseconds) to increase/decrease the time between "slides"
		this.__showNavigation	= false; 		// true to display Next/Prev buttons/text during slideshow, false to hide
		this.__showClose		= true;			// true to display the Close button, false to hide
		this.__showDetails		= true;			// true to display image details (caption, count), false to hide
		this.__showPlayPause	= true;			// true to display pause/play buttons next to close button, false to hide
		this.__autoEnd			= true;			// true to automatically close Lytebox after the last image is reached, false to keep open
		this.__pauseOnNextClick	= false;		// true to pause the slideshow when the "Next" button is clicked
		this.__pauseOnPrevClick = true;			// true to pause the slideshow when the "Prev" button is clicked
		this.__loopSlideshow	= false;		// true to continuously loop through slides, false otherwise
	
	
	/*** Configure Event Callbacks ***/
	
		this.__beforeStart		= '';			// function to call before the viewer starts
		this.__afterStart		= '';			// function to call after the viewer starts
		this.__beforeEnd		= '';			// function to call before the viewer ends (after close click)
		this.__afterEnd			= '';			// function to call after the viewer ends
	
		
	/*** Configure Lytetip (tooltips) Options ***/
		this.changeTipCursor 	= true; 		// true to change the cursor to 'help', false to leave default (inhereted)
		this.tipStyle 			= 'classic';	// sets the default tip style if none is specified via data-lyte-options. Possible values are classic, info, help, warning, error
		this.tipRelative		= true;			// if true, tips will be positioned relative to the element. if false, tips will be absolutely positioned on the page.
												// if you are having issues with tooltips not being properly positioned, then set this to false

	
	this.navTypeHash = new Object();
	this.navTypeHash['Hover_by_type_1'] = true;
	this.navTypeHash['Display_by_type_1'] = false;
	this.navTypeHash['Hover_by_type_2'] = false;
	this.navTypeHash['Display_by_type_2'] = true;
	this.navTypeHash['Hover_by_type_3'] = true;
	this.navTypeHash['Display_by_type_3'] = true;
	this.resizeWTimerArray = new Array();
	this.resizeWTimerCount = 0;
	this.resizeHTimerArray = new Array();
	this.resizeHTimerCount = 0;
	this.showContentTimerArray = new Array();
	this.showContentTimerCount = 0;
	this.overlayTimerArray = new Array();
	this.overlayTimerCount = 0;
	this.imageTimerArray = new Array();
	this.imageTimerCount = 0;
	this.timerIDArray = new Array();
	this.timerIDCount = 0;
	this.slideshowIDArray = new Array();
	this.slideshowIDCount = 0;
	this.imageArray = new Array();
	this.activeImage = null;
	this.slideArray = new Array();
	this.activeSlide = null;
	this.frameArray = new Array();
	this.activeFrame = null;
	this.checkFrame();
	this.isSlideshow = false;
	this.isLyteframe = false;
	this.tipSet = false;
	this.ieVersion = -1;
	this.ie = this.chrome = this.ff = false;
	this.setBrowserVersion();
	this.qtVersion = this.getQuicktimeVersion();
	this.classAttribute = (((this.ie && this.doc.compatMode == 'BackCompat') || (this.ie && this.ieVersion <= 7)) ? 'className' : 'class');
	this.classAttribute = (this.ie && (document.documentMode == 8 || document.documentMode == 9)) ? 'class' : this.classAttribute;
	this.bodyOnscroll = document.body.onscroll;
	if(this.resizeSpeed > 10) { this.resizeSpeed = 10; }
	if(this.resizeSpeed < 1) { this.resizeSpeed = 1; }
	this.resizeDuration = (11 - this.resizeSpeed) * (this.ie && this.ieVersion > 8 ? 20 : ((this.ie && this.ieVersion <= 8) ? 2 : (this.chrome ? 4 : 7)));
	this.initialize();
}
Lytebox.prototype.setBrowserVersion = function() {
	this.chrome = navigator.userAgent.toLowerCase().indexOf('chrome') > -1;
	this.ff = navigator.userAgent.toLowerCase().indexOf('firefox') > -1
	if (navigator.appName == 'Microsoft Internet Explorer') {
		var ua = navigator.userAgent;
		var re  = new RegExp("MSIE ([0-9]{1,}[\.0-9]{0,})");
		if (re.exec(ua) != null) {
			this.ieVersion = parseFloat( RegExp.$1 );
		}
		this.ie = (this.ieVersion > -1 ? true : false);
	}
};
Lytebox.prototype.initialize = function() {
	this.updateLyteboxItems();
	var oBody = this.doc.getElementsByTagName('body').item(0);
	var oLauncher = this.doc.createElement('a');
		oLauncher.setAttribute('id','lbLauncher');
		oLauncher.style.display = 'none';
		oBody.appendChild(oLauncher);
	if (this.doc.getElementById('lbOverlay')) {
		oBody.removeChild(this.doc.getElementById('lbOverlay'));
		oBody.removeChild(this.doc.getElementById('lbMain'));
	}
	var oOverlay = this.doc.createElement('div');
		oOverlay.setAttribute('id','lbOverlay');
		oOverlay.setAttribute(this.classAttribute, this.theme);
		if (this.ie && (this.ieVersion <= 6 || (this.ieVersion <= 9 && this.doc.compatMode == 'BackCompat'))) {
			oOverlay.style.position = 'absolute';
		}
		oOverlay.style.display = 'none';
		oBody.appendChild(oOverlay);
	var oLytebox = this.doc.createElement('div');
		oLytebox.setAttribute('id','lbMain');
		oLytebox.style.display = 'none';
		oBody.appendChild(oLytebox);
	var oOuterContainer = this.doc.createElement('div');
		oOuterContainer.setAttribute('id','lbOuterContainer');
		oOuterContainer.setAttribute(this.classAttribute, this.theme);
		oLytebox.appendChild(oOuterContainer);
	var oTopContainer = this.doc.createElement('div');
		oTopContainer.setAttribute('id','lbTopContainer');
		oTopContainer.setAttribute(this.classAttribute, this.theme);
		oOuterContainer.appendChild(oTopContainer);
	var oTopData = this.doc.createElement('div');
		oTopData.setAttribute('id','lbTopData');
		oTopData.setAttribute(this.classAttribute, this.theme);
		oTopContainer.appendChild(oTopData);
	var oTitleTop = this.doc.createElement('span');
		oTitleTop.setAttribute('id','lbTitleTop');
		oTopData.appendChild(oTitleTop);
	var oNumTop = this.doc.createElement('span');
		oNumTop.setAttribute('id','lbNumTop');
		oTopData.appendChild(oNumTop);
	var oTopNav = this.doc.createElement('div');
		oTopNav.setAttribute('id','lbTopNav');
		oTopContainer.appendChild(oTopNav);
	var oCloseTop = this.doc.createElement('a');
		oCloseTop.setAttribute('id','lbCloseTop');
		oCloseTop.setAttribute('title', this.label['close']);
		oCloseTop.setAttribute(this.classAttribute, this.theme);
		oCloseTop.setAttribute('href','javascript:void(0)');
		oTopNav.appendChild(oCloseTop);
	var oPrintTop = this.doc.createElement('a');
		oPrintTop.setAttribute('id','lbPrintTop')
		oPrintTop.setAttribute('title', this.label['print']);
		oPrintTop.setAttribute(this.classAttribute, this.theme);
		oPrintTop.setAttribute('href','javascript:void(0)');
		oTopNav.appendChild(oPrintTop);
	var oNextTop = this.doc.createElement('a');
		oNextTop.setAttribute('id','lbNextTop');
		oNextTop.setAttribute('title', this.label['next']);
		oNextTop.setAttribute(this.classAttribute, this.theme);
		oNextTop.setAttribute('href','javascript:void(0)');
		oTopNav.appendChild(oNextTop);
	var oPauseTop = this.doc.createElement('a');
		oPauseTop.setAttribute('id','lbPauseTop');
		oPauseTop.setAttribute('title', this.label['pause']);
		oPauseTop.setAttribute(this.classAttribute, this.theme);
		oPauseTop.setAttribute('href','javascript:void(0)');
		oPauseTop.style.display = 'none';
		oTopNav.appendChild(oPauseTop);
	var oPlayTop = this.doc.createElement('a');
		oPlayTop.setAttribute('id','lbPlayTop');
		oPlayTop.setAttribute('title', this.label['play']);
		oPlayTop.setAttribute(this.classAttribute, this.theme);
		oPlayTop.setAttribute('href','javascript:void(0)');
		oPlayTop.style.display = 'none';
		oTopNav.appendChild(oPlayTop);
	var oPrevTop = this.doc.createElement('a');
		oPrevTop.setAttribute('id','lbPrevTop');
		oPrevTop.setAttribute('title', this.label['prev']);
		oPrevTop.setAttribute(this.classAttribute, this.theme);
		oPrevTop.setAttribute('href','javascript:void(0)');
		oTopNav.appendChild(oPrevTop);
	var oIframeContainer = this.doc.createElement('div');
		oIframeContainer.setAttribute('id','lbIframeContainer');
		oIframeContainer.style.display = 'none';
		oOuterContainer.appendChild(oIframeContainer);
	var oIframe = this.doc.createElement('iframe');
		oIframe.setAttribute('id','lbIframe');
		oIframe.setAttribute('name','lbIframe')
		oIframe.setAttribute('frameBorder','0');
		if (this.innerBorder) {
			oIframe.setAttribute(this.classAttribute, this.theme);
		}
		oIframe.style.display = 'none';
		oIframeContainer.appendChild(oIframe);
	var oImageContainer = this.doc.createElement('div');
		oImageContainer.setAttribute('id','lbImageContainer');
		oOuterContainer.appendChild(oImageContainer);
	var oLyteboxImage = this.doc.createElement('img');
		oLyteboxImage.setAttribute('id','lbImage');
		if (this.innerBorder) {
			oLyteboxImage.setAttribute(this.classAttribute, this.theme);
		}
		oImageContainer.appendChild(oLyteboxImage);
	var oLoading = this.doc.createElement('div');
		oLoading.setAttribute('id','lbLoading');
		oLoading.setAttribute(this.classAttribute, this.theme);
		oOuterContainer.appendChild(oLoading);
	var oBottomContainer = this.doc.createElement('div');
		oBottomContainer.setAttribute('id','lbBottomContainer');
		oBottomContainer.setAttribute(this.classAttribute, this.theme);
		oOuterContainer.appendChild(oBottomContainer);
	var oDetailsBottom = this.doc.createElement('div');
		oDetailsBottom.setAttribute('id','lbBottomData');
		oDetailsBottom.setAttribute(this.classAttribute, this.theme);
		oBottomContainer.appendChild(oDetailsBottom);
	var oTitleBottom = this.doc.createElement('span');
		oTitleBottom.setAttribute('id','lbTitleBottom');
		oDetailsBottom.appendChild(oTitleBottom);
	var oNumBottom = this.doc.createElement('span');
		oNumBottom.setAttribute('id','lbNumBottom');
		oDetailsBottom.appendChild(oNumBottom);
	var oDescBottom = this.doc.createElement('span');
		oDescBottom.setAttribute('id','lbDescBottom');
		oDetailsBottom.appendChild(oDescBottom);
	var oHoverNav = this.doc.createElement('div');
		oHoverNav.setAttribute('id','lbHoverNav');
		oImageContainer.appendChild(oHoverNav);
	var oBottomNav = this.doc.createElement('div');
		oBottomNav.setAttribute('id','lbBottomNav');
		oBottomContainer.appendChild(oBottomNav);
	var oPrevHov = this.doc.createElement('a');
		oPrevHov.setAttribute('id','lbPrevHov');
		oPrevHov.setAttribute('title', this.label['prev']);
		oPrevHov.setAttribute(this.classAttribute, this.theme);
		oPrevHov.setAttribute('href','javascript:void(0)');
		oHoverNav.appendChild(oPrevHov);
	var oNextHov = this.doc.createElement('a');
		oNextHov.setAttribute('id','lbNextHov');
		oNextHov.setAttribute('title', this.label['next']);
		oNextHov.setAttribute(this.classAttribute, this.theme);
		oNextHov.setAttribute('href','javascript:void(0)');
		oHoverNav.appendChild(oNextHov);
	var oClose = this.doc.createElement('a');
		oClose.setAttribute('id','lbClose');
		oClose.setAttribute('title', this.label['close']);
		oClose.setAttribute(this.classAttribute, this.theme);
		oClose.setAttribute('href','javascript:void(0)');
		oBottomNav.appendChild(oClose);
	var oPrint = this.doc.createElement('a');
		oPrint.setAttribute('id','lbPrint');
		oPrint.setAttribute('title', this.label['print']);
		oPrint.setAttribute(this.classAttribute, this.theme);
		oPrint.setAttribute('href','javascript:void(0)');
		oPrint.style.display = 'none';
		oBottomNav.appendChild(oPrint);
	var oNext = this.doc.createElement('a');
		oNext.setAttribute('id','lbNext');
		oNext.setAttribute('title', this.label['next']);
		oNext.setAttribute(this.classAttribute, this.theme);
		oNext.setAttribute('href','javascript:void(0)');
		oBottomNav.appendChild(oNext);
	var oPause = this.doc.createElement('a');
		oPause.setAttribute('id','lbPause');
		oPause.setAttribute('title', this.label['pause']);
		oPause.setAttribute(this.classAttribute, this.theme);
		oPause.setAttribute('href','javascript:void(0)');
		oPause.style.display = 'none';
		oBottomNav.appendChild(oPause);
	var oPlay = this.doc.createElement('a');
		oPlay.setAttribute('id','lbPlay');
		oPlay.setAttribute('title', this.label['play']);
		oPlay.setAttribute(this.classAttribute, this.theme);
		oPlay.setAttribute('href','javascript:void(0)');
		oPlay.style.display = 'none';
		oBottomNav.appendChild(oPlay);
	var oPrev = this.doc.createElement('a');
		oPrev.setAttribute('id','lbPrev');
		oPrev.setAttribute('title', this.label['prev']);
		oPrev.setAttribute(this.classAttribute, this.theme);
		oPrev.setAttribute('href','javascript:void(0)');
		oBottomNav.appendChild(oPrev);
};
Lytebox.prototype.updateLyteboxItems = function() {
	var anchors = (this.isFrame && window.parent.frames[window.name].document) ? window.parent.frames[window.name].document.getElementsByTagName('a') : document.getElementsByTagName('a');
		anchors = (this.isFrame) ? anchors : document.getElementsByTagName('a');
	var areas = (this.isFrame) ? window.parent.frames[window.name].document.getElementsByTagName('area') : document.getElementsByTagName('area');
	var lyteLinks = this.combine(anchors, areas);
	var myLink = relAttribute = classAttribute = dataAttribute = tipStyle = tipImage = tipHtml = aSetting = sName = sValue = null;
	for (var i = 0; i < lyteLinks.length; i++) {
		myLink = lyteLinks[i];
		classAttribute = String(myLink.getAttribute(this.classAttribute));
		if (myLink.getAttribute('href')) {
			if (classAttribute.toLowerCase().match('lytebox')) {
				myLink.onclick = function () { $lb.start(this, false, false); return false; }
			} else if (classAttribute.toLowerCase().match('lyteshow')) {
				myLink.onclick = function () { $lb.start(this, true, false); return false; }
			} else if (classAttribute.toLowerCase().match('lyteframe')) {
				myLink.onclick = function () { $lb.start(this, false, true); return false; }
			}
			if (classAttribute.toLowerCase().match('lytetip') && myLink.getAttribute('data-tip') != null && !this.tipsSet) {
				if (this.changeTipCursor) {	myLink.style.cursor = 'help'; }
				dataAttribute = String(myLink.getAttribute('data-lyte-options'));
				if (dataAttribute == 'null') {
					tipStyle = this.tipStyle;
				} else {
					aSetting = dataAttribute.split(':');
					if (aSetting.length > 1) {
						sName = String(aSetting[0]).trim().toLowerCase();
						sValue = String(aSetting[1]).trim().toLowerCase();
						tipStyle = (sName == 'tipstyle' ? (/classic|info|help|warning|error/.test(sValue) ? sValue : this.tipStyle) : this.tipStyle);
					}
					aOptions = dataAttribute.split(' ');
					for (var j = 0; j < aOptions.length; i++) {
						aSetting = aOptions[j].split(':');
						if (aSetting.length > 1) {
							sName = String(aSetting[0]).trim().toLowerCase();
							sValue = String(aSetting[1]).trim().toLowerCase();
							tipStyle = (sName == 'tipstyle' ? (/classic|info|help|warning|error/.test(sValue) ? sValue : this.tipStyle) : this.tipStyle);
							break;
						}
					}
				}
				switch(tipStyle) {
					case 'info': tipStyle = 'lbCustom lbInfo'; tipImage = 'lbTipImg lbInfoImg'; break;
					case 'help': tipStyle = 'lbCustom lbHelp'; tipImage = 'lbTipImg lbHelpImg'; break;
					case 'warning': tipStyle = 'lbCustom lbWarning'; tipImage = 'lbTipImg lbWarningImg'; break;
					case 'error': tipStyle = 'lbCustom lbError'; tipImage = 'lbTipImg lbErrorImg'; break;
					case 'classic': tipStyle = 'lbClassic'; tipImage = ''; break;
					default: tipStyle = 'lbClassic'; tipImage = '';
				}
				if ((this.ie && this.ieVersion <= 7) || (this.ieVersion == 8 && this.doc.compatMode == 'BackCompat')) {
					tipImage = '';
					if (tipStyle != 'lbClassic' && tipStyle != '') {
						tipStyle += ' lbIEFix';
					}
				}
				var aLinkPos = this.findPos(myLink);
				if (this.ie && (this.ieVersion <= 6 || this.doc.compatMode == 'BackCompat')) {
					myLink.style.position = 'relative';
				}
				tipHtml = myLink.innerHTML;
				myLink.innerHTML = '';
				if ((this.ie && this.ieVersion <= 6 && this.doc.compatMode != 'BackCompat') || this.tipRelative) {
					myLink.innerHTML = tipHtml + '<span class="' + tipStyle + '">' + (tipImage ? '<div class="' + tipImage + '"></div>' : '') + myLink.getAttribute('data-tip') + '</span>';
					if (this.tipRelative) {
						myLink.style.position = 'relative';
					}
				} else {
					myLink.innerHTML = tipHtml + '<span class="' + tipStyle + '" style="left:'+aLinkPos[0]+'px;top:'+(aLinkPos[1]+aLinkPos[2])+'px;">' + (tipImage ? '<div class="' + tipImage + '"></div>' : '') + myLink.getAttribute('data-tip') + '</span>';
				}
				myLink.setAttribute('title','');
			}
		}
	}
	this.tipsSet = true;
};
Lytebox.prototype.start = function(oLink, bLyteshow, bLyteframe) {
	this.setOptions(String(oLink.getAttribute('data-lyte-options')));
	if (this.beforeStart != '') {
		var callback = window[this.beforeStart];
		if (typeof callback === 'function') {
			if (!callback()) { return; }
		}
	}
	if (this.ie && this.ieVersion <= 6) { this.toggleSelects('hide'); }
	if (this.hideObjects) { this.toggleObjects('hide'); }
	this.isLyteframe = (bLyteframe ? true : false);
	if (this.isFrame && window.parent.frames[window.name].document) {
		window.parent.$lb.printId = (this.isLyteframe ? 'lbIframe' : 'lbImage');
	} else {
		this.printId = (this.isLyteframe ? 'lbIframe' : 'lbImage');
	}
	var pageSize	= this.getPageSize();
	var objOverlay	= this.doc.getElementById('lbOverlay');
	var objBody		= this.doc.getElementsByTagName("body").item(0);
	objOverlay.style.height = pageSize[1] + "px";
	objOverlay.style.display = '';
	this.appear('lbOverlay', (this.doAnimations && this.ieVersion >=9 ? 0 : this.maxOpacity));
	var anchors = (this.isFrame && window.parent.frames[window.name].document) ? window.parent.frames[window.name].document.getElementsByTagName('a') : document.getElementsByTagName('a');
		anchors = (this.isFrame) ? anchors : document.getElementsByTagName('a');
	var areas = (this.isFrame) ? window.parent.frames[window.name].document.getElementsByTagName('area') : document.getElementsByTagName('area');
	var lyteLinks = this.combine(anchors, areas);
	if (this.isLyteframe) {
		this.frameArray = [];
		this.frameNum = 0;
		if (this.group == '') {
			this.frameArray.push(new Array(oLink.getAttribute('href'), (oLink.getAttribute('data-title') != null ? oLink.getAttribute('data-title') : oLink.getAttribute('title')), oLink.getAttribute('data-description')));
		} else {
			if (String(oLink.getAttribute(this.classAttribute)).indexOf('lyteframe') != -1) {
				for (var i = 0; i < lyteLinks.length; i++) {
					var myLink = lyteLinks[i];
					if (myLink.getAttribute('href') && String(myLink.getAttribute('data-lyte-options')).toLowerCase().match('group:' + this.group)) {
						this.frameArray.push(new Array(myLink.getAttribute('href'), (myLink.getAttribute('data-title') != null ? myLink.getAttribute('data-title') : myLink.getAttribute('title')), myLink.getAttribute('data-description')));
					}
				}
				this.frameArray = this.removeDuplicates(this.frameArray);
				while(this.frameArray[this.frameNum][0] != oLink.getAttribute('href')) { this.frameNum++; }
			}
		}
	} else {
		this.imageArray = [];
		this.imageNum = 0;
		this.slideArray = [];
		this.slideNum = 0;
		if (this.group == '') {
			this.imageArray.push(new Array(oLink.getAttribute('href'), (oLink.getAttribute('data-title') != null ? oLink.getAttribute('data-title') : oLink.getAttribute('title')), oLink.getAttribute('data-description')));
		} else {
			if (String(oLink.getAttribute(this.classAttribute)).indexOf('lytebox') != -1) {
				for (var i = 0; i < lyteLinks.length; i++) {
					var myLink = lyteLinks[i];
					if (myLink.getAttribute('href') && String(myLink.getAttribute('data-lyte-options')).toLowerCase().match('group:' + this.group)) {
						this.imageArray.push(new Array(myLink.getAttribute('href'), (myLink.getAttribute('data-title') != null ? myLink.getAttribute('data-title') : myLink.getAttribute('title')), myLink.getAttribute('data-description')));
					}
				}
				this.imageArray = this.removeDuplicates(this.imageArray);
				while(this.imageArray[this.imageNum][0] != oLink.getAttribute('href')) { this.imageNum++; }
			}
			if (String(oLink.getAttribute(this.classAttribute)).indexOf('lyteshow') != -1) {
				for (var i = 0; i < lyteLinks.length; i++) {
					var myLink = lyteLinks[i];
					if (myLink.getAttribute('href') && String(myLink.getAttribute('data-lyte-options')).toLowerCase().match('group:' + this.group)) {
						this.slideArray.push(new Array(myLink.getAttribute('href'), (myLink.getAttribute('data-title') != null ? myLink.getAttribute('data-title') : myLink.getAttribute('title')), myLink.getAttribute('data-description')));
					}
				}
				this.slideArray = this.removeDuplicates(this.slideArray);
				while(this.slideArray[this.slideNum][0] != oLink.getAttribute('href')) { this.slideNum++; }
			}
		}
	}
	var object = this.doc.getElementById('lbMain');
		object.style.display = '';
	if (this.autoResize && this.fixedPosition) {
		if (document.all && document.all.item && !window.opera) {
			object.style.top = (this.getPageScroll() + (pageSize[3] / 40)) + "px";
			var ps = (pageSize[3] / 40);
			var handler = function(){
				document.getElementById('lbMain').style.top = ($lb.getPageScroll() + ps) + 'px';
			}
			this.bodyOnscroll = document.body.onscroll;
			if (window.addEventListener) {
				window.addEventListener('scroll', handler, false);
			} else if (window.attachEvent) {
				window.attachEvent('onscroll', handler);
			} else {
				window.onload = handler_start;
			}
			object.style.position = "absolute";
		} else {
			object.style.top = ((pageSize[3] / 40)) + "px";
			object.style.position = "fixed";
		}
	} else {
		object.style.top = (this.getPageScroll() + (pageSize[3] / 40)) + "px";
	}
	if (!this.outerBorder) {
		this.doc.getElementById('lbOuterContainer').style.border = 'none';
	} else {
		this.doc.getElementById('lbOuterContainer').setAttribute(this.classAttribute, this.theme);
	}
	if (this.forceCloseClick) {
		this.doc.getElementById('lbOverlay').onclick = '';
	} else {
		this.doc.getElementById('lbOverlay').onclick = function() { $lb.end(); return false; }
	}
	this.doc.getElementById('lbMain').onclick = function(e) {
		var e = e;
		if (!e) {
			if (window.parent.frames[window.name] && (parent.document.getElementsByTagName('frameset').length <= 0)) {
				e = window.parent.window.event;
			} else {
				e = window.event;
			}
		}
		var id = (e.target ? e.target.id : e.srcElement.id);
		if ((id == 'lbMain') && (!$lb.forceCloseClick)) { $lb.end(); return false; }
	}
	this.doc.getElementById('lbPrintTop').onclick = this.doc.getElementById('lbPrint').onclick = function() { $lb.printWindow(); return false; }
	this.doc.getElementById('lbCloseTop').onclick = this.doc.getElementById('lbClose').onclick = function() { $lb.end(); return false; }
	this.doc.getElementById('lbPauseTop').onclick = function() { $lb.togglePlayPause("lbPauseTop", "lbPlayTop"); return false; }
	this.doc.getElementById('lbPause').onclick = function() { $lb.togglePlayPause("lbPause", "lbPlay"); return false; }
	this.doc.getElementById('lbPlayTop').onclick = function() { $lb.togglePlayPause("lbPlayTop", "lbPauseTop"); return false; }
	this.doc.getElementById('lbPlay').onclick = function() { $lb.togglePlayPause("lbPlay", "lbPause"); return false; }
	this.isSlideshow = bLyteshow;
	this.isPaused = (this.slideNum != 0 ? true : false);
	if (this.isSlideshow && this.showPlayPause && this.isPaused) {
		this.doc.getElementById('lbPlay').style.display = '';
		this.doc.getElementById('lbPause').style.display = 'none';
	}
	if (this.isLyteframe) {
		this.changeContent(this.frameNum);
	} else {
		if (this.isSlideshow) {
			this.changeContent(this.slideNum);
		} else {
			this.changeContent(this.imageNum);
		}
	}
};
Lytebox.prototype.launch = function(sUrl, sOptions, sTitle, sDesc) {
	var sExt = sUrl.split('.').pop().toLowerCase();
	var sRel = 'lyteframe';
	if (sExt == 'png' || sExt == 'jpg' || sExt == 'jpeg' || sExt == 'gif' || sExt == 'bmp') {
		sRel = 'lytebox';
	}
	var oLauncher = this.doc.getElementById('lbLauncher');
		oLauncher.setAttribute('href', sUrl);
		oLauncher.setAttribute('rel', sRel);
		oLauncher.setAttribute('data-lyte-options', !sOptions ? '' : sOptions);
		oLauncher.setAttribute('data-title', !sTitle ? '' : sTitle);
		oLauncher.setAttribute('data-description', !sDesc ? '' : sDesc);
	this.updateLyteboxItems();
	this.start(oLauncher, false, (sRel == 'lyteframe'));
};
Lytebox.prototype.changeContent = function(iImageNum) {
	if (this.isSlideshow) {
		for (var i = 0; i < this.slideshowIDCount; i++) { window.clearTimeout(this.slideshowIDArray[i]); }
	}
	this.activeImage = this.activeSlide = this.activeFrame = iImageNum;
	if (!this.outerBorder) {
		this.doc.getElementById('lbOuterContainer').style.border = 'none';
	} else {
		this.doc.getElementById('lbOuterContainer').setAttribute(this.classAttribute, this.theme);
	}
	this.doc.getElementById('lbLoading').style.display = '';
	this.doc.getElementById('lbImage').style.display = 'none';
	this.doc.getElementById('lbIframe').style.display = 'none';
	this.doc.getElementById('lbPrevHov').style.display = 'none';
	this.doc.getElementById('lbNextHov').style.display =  'none';
	this.doc.getElementById('lbIframeContainer').style.display = 'none';
	if (this.titleTop || this.navTop) {
		this.doc.getElementById('lbTopContainer').style.visibility = 'hidden';
	} else {
		this.doc.getElementById('lbTopContainer').style.display = 'none';
	}
	this.doc.getElementById('lbBottomContainer').style.display = 'none';
	if (this.isLyteframe) {
		var iframe = $lb.doc.getElementById('lbIframe');
			iframe.src = 'about:blank';
		var pageSize = this.getPageSize();
		var w = this.width.trim();
		var h = this.height.trim();
		if (/\%/.test(w)) {
			var percent = parseInt(w);
			w = parseInt((pageSize[2]-50)*percent/100);
			w = w+'px';
		}
		if (/\%/.test(h)) {
			var percent = parseInt(h);
			h = parseInt((pageSize[3]-150)*percent/100);
			h = h+'px';
		}
		iframe.height = h;
		iframe.width = w;
		iframe.scrolling = this.scrollbars.trim();
		this.resizeContainer(parseInt(iframe.width), parseInt(iframe.height));
	} else {
		imgPreloader = new Image();
		imgPreloader.onload = function() {
			var imageWidth = imgPreloader.width;
			var imageHeight = imgPreloader.height;
			if ($lb.autoResize) {
				var pagesize = $lb.getPageSize();
				var x = pagesize[2] - 50;
				var y = pagesize[3] - 150;
				if (imageWidth > x) {
					imageHeight = Math.round(imageHeight * (x / imageWidth));
					imageWidth = x; 
					if (imageHeight > y) { 
						imageWidth = Math.round(imageWidth * (y / imageHeight));
						imageHeight = y; 
					}
				} else if (imageHeight > y) { 
					imageWidth = Math.round(imageWidth * (y / imageHeight));
					imageHeight = y; 
					if (imageWidth > x) {
						imageHeight = Math.round(imageHeight * (x / imageWidth));
						imageWidth = x;
					}
				}
			}
			var lbImage = $lb.doc.getElementById('lbImage')
			lbImage.src = ($lb.isSlideshow ? $lb.slideArray[$lb.activeSlide][0] : $lb.imageArray[$lb.activeImage][0]);
			lbImage.width = imageWidth;
			lbImage.height = imageHeight;
			$lb.resizeContainer(imageWidth, imageHeight);
			imgPreloader.onload = function() {};
		}
		imgPreloader.src = (this.isSlideshow ? this.slideArray[this.activeSlide][0] : this.imageArray[this.activeImage][0]);
	}
};
Lytebox.prototype.resizeContainer = function(iWidth, iHeight) {	
	this.wCur = this.doc.getElementById('lbOuterContainer').offsetWidth;
	this.hCur = this.doc.getElementById('lbOuterContainer').offsetHeight;
	this.xScale = ((iWidth  + (this.borderSize * 2)) / this.wCur) * 100;
	this.yScale = ((iHeight  + (this.borderSize * 2)) / this.hCur) * 100;
	var wDiff = (this.wCur - this.borderSize * 2) - iWidth;
	var hDiff = (this.hCur - this.borderSize * 2) - iHeight;
	if (!(hDiff == 0)) {
		this.hDone = false;
		this.resizeH('lbOuterContainer', this.hCur, iHeight + this.borderSize*2, this.getPixelRate(this.hCur, iHeight));
	} else {
		this.hDone = true;
	}
	if (!(wDiff == 0)) {
		this.wDone = false;
		this.resizeW('lbOuterContainer', this.wCur, iWidth + this.borderSize*2, this.getPixelRate(this.wCur, iWidth));
	} else {
		this.wDone = true;
	}
	if ((hDiff == 0) && (wDiff == 0)) {
		if (this.ie){ this.pause(250); } else { this.pause(100); } 
	}
	this.doc.getElementById('lbPrevHov').style.height = iHeight + "px";
	this.doc.getElementById('lbNextHov').style.height = iHeight + "px";
	this.showContent();
};
Lytebox.prototype.showContent = function() {
	if (this.wDone && this.hDone) {
		for (var i = 0; i < this.showContentTimerCount; i++) { window.clearTimeout(this.showContentTimerArray[i]); }
		this.doc.getElementById('lbLoading').style.display = 'none';
		this.doc.getElementById('lbImageContainer').style.display = (this.isLyteframe ? 'none' : '');
		this.doc.getElementById('lbIframeContainer').style.display = (this.isLyteframe ? '' : 'none');
		if (this.isLyteframe) {
			this.doc.getElementById('lbIframe').style.display = '';
			this.appear('lbIframe', (this.doAnimations ? 0 : 100));
		} else {
			this.doc.getElementById('lbImage').style.display = '';
			this.appear('lbImage', (this.doAnimations ? 0 : 100));
			this.preloadNeighborImages();
		}
		if (this.isSlideshow) {
			if(this.activeSlide == (this.slideArray.length - 1)) {
				if (this.loopSlideshow) {
					this.slideshowIDArray[this.slideshowIDCount++] = setTimeout("$lb.changeContent(0)", this.slideInterval);
				} else if (this.autoEnd) {
					this.slideshowIDArray[this.slideshowIDCount++] = setTimeout("$lb.end('slideshow')", this.slideInterval);
				}
			} else {
				if (!this.isPaused) {
					this.slideshowIDArray[this.slideshowIDCount++] = setTimeout("$lb.changeContent("+(this.activeSlide+1)+")", this.slideInterval);
				}
			}
			this.doc.getElementById('lbHoverNav').style.display = (this.showNavigation && this.navTypeHash['Hover_by_type_' + this.navType] ? '' : 'none');
			this.doc.getElementById('lbCloseTop').style.display = (this.showClose && this.navTop ? '' : 'none');
			this.doc.getElementById('lbClose').style.display = (this.showClose && !this.navTop ? '' : 'none');
			this.doc.getElementById('lbBottomData').style.display = (this.showDetails ? '' : 'none');
			this.doc.getElementById('lbPauseTop').style.display = (this.showPlayPause && this.navTop ? (!this.isPaused ? '' : 'none') : 'none');
			this.doc.getElementById('lbPause').style.display = (this.showPlayPause && !this.navTop ? (!this.isPaused ? '' : 'none') : 'none');
			this.doc.getElementById('lbPlayTop').style.display = (this.showPlayPause && this.navTop ? (!this.isPaused ? 'none' : '') : 'none');
			this.doc.getElementById('lbPlay').style.display = (this.showPlayPause && !this.navTop ? (!this.isPaused ? 'none' : '') : 'none');
			this.doc.getElementById('lbPrevTop').style.display = (this.navTop && this.showNavigation && this.navTypeHash['Display_by_type_' + this.navType] ? '' : 'none');
			this.doc.getElementById('lbPrev').style.display = (!this.navTop && this.showNavigation && this.navTypeHash['Display_by_type_' + this.navType] ? '' : 'none');
			this.doc.getElementById('lbNextTop').style.display = (this.navTop && this.showNavigation && this.navTypeHash['Display_by_type_' + this.navType] ? '' : 'none');
			this.doc.getElementById('lbNext').style.display = (!this.navTop && this.showNavigation && this.navTypeHash['Display_by_type_' + this.navType] ? '' : 'none');
		} else {
			this.doc.getElementById('lbHoverNav').style.display = (this.navTypeHash['Hover_by_type_' + this.navType] && !this.isLyteframe ? '' : 'none');
			if ((this.navTypeHash['Display_by_type_' + this.navType] && !this.isLyteframe && this.imageArray.length > 1) || (this.frameArray.length > 1 && this.isLyteframe)) {
				this.doc.getElementById('lbPrevTop').style.display = (this.navTop ? '' : 'none');
				this.doc.getElementById('lbPrev').style.display = (!this.navTop ? '' : 'none');
				this.doc.getElementById('lbNextTop').style.display = (this.navTop ? '' : 'none');
				this.doc.getElementById('lbNext').style.display = (!this.navTop ? '' : 'none');
			} else {
				this.doc.getElementById('lbPrevTop').style.display = 'none';
				this.doc.getElementById('lbPrev').style.display = 'none';
				this.doc.getElementById('lbNextTop').style.display = 'none';
				this.doc.getElementById('lbNext').style.display = 'none';
			}
			this.doc.getElementById('lbCloseTop').style.display = (this.navTop ? '' : 'none');
			this.doc.getElementById('lbClose').style.display = (!this.navTop ? '' : 'none');				
			this.doc.getElementById('lbBottomData').style.display = '';
			this.doc.getElementById('lbPauseTop').style.display = 'none';
			this.doc.getElementById('lbPause').style.display = 'none';
			this.doc.getElementById('lbPlayTop').style.display = 'none';
			this.doc.getElementById('lbPlay').style.display = 'none';
		}
		this.doc.getElementById('lbPrintTop').style.display = (this.showPrint && this.navTop ? '' : 'none');
		this.doc.getElementById('lbPrint').style.display = (this.showPrint && !this.navTop ? '' : 'none');
		try {
			var uri = this.frameArray[this.activeFrame][0];
			var ext = uri.split('.').pop().toLowerCase();
			if (this.appendQS) {
				uri += ((/\?/.test(uri)) ? '&' : '?') + 'request_from=lytebox';
			}
			if (ext == 'mov' || ext == 'avi' || ext == 'wmv' || ext == 'mpg' || ext == 'mpeg' || ext == 'swf') {
				var ifrm = this.doc.getElementById('lbIframe');
				var blah = this.buildObject(parseInt(ifrm.width), parseInt(ifrm.height), uri, ext);
				ifrm = (ifrm.contentWindow) ? ifrm.contentWindow : (ifrm.contentDocument.document) ? ifrm.contentDocument.document : ifrm.contentDocument;
				ifrm.document.open();
				ifrm.document.write(blah);
				ifrm.document.close();
				var wStyle = ifrm.document.body.style;
				wStyle.margin = 0;
				wStyle.padding = 0;
				wStyle.backgroundColor = '#fff';
				wStyle.fontFamily = 'Verdana, Helvetica, sans-serif';
				wStyle.fontSize = '0.9em';
			} else {
				this.doc.getElementById('lbIframe').src = uri;
			}
		} catch(e) { }
		if (this.afterStart != '') {
			var callback = window[this.afterStart];
			if (typeof callback === 'function') {
				callback();
			}
		}
	} else {
		this.showContentTimerArray[this.showContentTimerCount++] = setTimeout("$lb.showContent()", 200);
	}
};
Lytebox.prototype.updateDetails = function() {
	var sTitle = (this.isSlideshow ? this.slideArray[this.activeSlide][1] : (this.isLyteframe ? this.frameArray[this.activeFrame][1] : this.imageArray[this.activeImage][1]));
		sTitle = sTitle == '' ? null : sTitle;
	var sDesc  = (this.isSlideshow ? this.slideArray[this.activeSlide][2] : (this.isLyteframe ? this.frameArray[this.activeFrame][2] : this.imageArray[this.activeImage][2]));
		sDesc  = sDesc == '' ? null : sDesc;
	if (this.ie && this.ieVersion <= 7 || (this.ieVersion >= 8 && this.doc.compatMode == 'BackCompat')) {
		this.doc.getElementById(this.titleTop ? 'lbTitleBottom' : 'lbTitleTop').style.display = 'none';
		this.doc.getElementById(this.titleTop ? 'lbTitleTop' : 'lbTitleBottom').style.display = (sTitle == null ? 'none' : 'block');
		this.doc.getElementById('lbDescBottom').style.display = (sDesc == null ? 'none' : 'block');
	}
	this.doc.getElementById(this.titleTop ? 'lbTitleTop' : 'lbTitleBottom').innerHTML = (sTitle == null ? '' : sTitle);
	this.doc.getElementById(this.titleTop ? 'lbTitleBottom' : 'lbTitleTop').innerHTML = '';
	this.doc.getElementById(this.titleTop ? 'lbNumBottom' : 'lbNumTop').innerHTML = '';
	this.updateNav();
	if (this.titleTop || this.navTop) {
		this.doc.getElementById('lbTopContainer').style.display = 'block';
		this.doc.getElementById('lbTopContainer').style.visibility = 'visible';
	} else {
		this.doc.getElementById('lbTopContainer').style.display = 'none';
	}
	var object = (this.titleTop ? this.doc.getElementById('lbNumTop') : this.doc.getElementById('lbNumBottom'));
	if (this.isSlideshow && this.slideArray.length > 1) {
		object.innerHTML = this.label['image'] + " " + eval(this.activeSlide + 1) + " "+ this.label['of'] +" " + this.slideArray.length;
	} else if (this.imageArray.length > 1 && !this.isLyteframe) {
		object.innerHTML = this.label['image'] + " " + eval(this.activeImage + 1) + " "+ this.label['of'] +" " + this.imageArray.length;
	} else if (this.frameArray.length > 1 && this.isLyteframe) {
		object.innerHTML = this.label['page'] + " " + eval(this.activeFrame + 1) + " "+ this.label['of'] +" " + this.frameArray.length;
	} else {
		object.innerHTML = '';
	}
	var bAddSpacer = !(this.titleTop || (sTitle == null && object.innerHTML == ''));
	this.doc.getElementById('lbDescBottom').innerHTML = (sDesc == null ? '' : (bAddSpacer ? '<br style="line-height:0.6em;" />' : '') + sDesc);
	this.doc.getElementById('lbBottomContainer').style.display = (!(this.titleTop && this.navTop) || sDesc != null ? 'block' : 'none');
	var iNavWidth = 0;
	if (this.ie && this.ieVersion <= 7 || (this.ieVersion >= 8 && this.doc.compatMode == 'BackCompat')) {
		iNavWidth = 39 + (this.showPrint ? 39 : 0) + (this.isSlideshow && this.showPlayPause ? 39 : 0);
		if ((this.isSlideshow && this.slideArray.length > 1 && this.showNavigation && this.navType != 1) ||
			(this.frameArray.length > 1 && this.isLyteframe) ||
			(this.imageArray.length > 1 && !this.isLyteframe && this.navType != 1)) {
				iNavWidth += 39*2;
		}
	}
	if (this.titleTop && this.navTop) {
		if (iNavWidth > 0) {
			this.doc.getElementById('lbTopNav').style.width = iNavWidth + 'px';
		}
		this.doc.getElementById('lbTopData').style.width = (this.doc.getElementById('lbTopContainer').offsetWidth - this.doc.getElementById('lbTopNav').offsetWidth - 15) + 'px';
		this.doc.getElementById('lbDescBottom').style.width = (this.doc.getElementById('lbBottomContainer').offsetWidth - 15) + 'px';
	} else if ((!this.titleTop || sDesc != null) && !this.navTop) {
		if (iNavWidth > 0) {
			this.doc.getElementById('lbBottomNav').style.width = iNavWidth + 'px';
		}
		this.doc.getElementById('lbBottomData').style.width = (this.doc.getElementById('lbBottomContainer').offsetWidth - this.doc.getElementById('lbBottomNav').offsetWidth - 15) + 'px';
		this.doc.getElementById('lbDescBottom').style.width = this.doc.getElementById('lbBottomData').style.width
	}
	if (!((this.ieVersion == 7 || this.ieVersion == 8 || this.ieVersion == 9) && this.doc.compatMode == 'BackCompat') && this.ieVersion != 6) {
		var titleHeight = this.doc.getElementById('lbTopContainer').offsetHeight + 5;
		var offsetHeight = (titleHeight == 5 ? 0 : titleHeight) + this.doc.getElementById('lbBottomContainer').offsetHeight;
		this.doc.getElementById('lbOuterContainer').style.paddingBottom = (offsetHeight + 5) + 'px';
	}
};
Lytebox.prototype.updateNav = function() {
	if (this.isSlideshow) {
		if (this.activeSlide != 0) {
			if (this.navTypeHash['Display_by_type_' + this.navType] && this.showNavigation) {
				this.doc.getElementById(this.navTop ? 'lbPrevTop' : 'lbPrev').setAttribute(this.classAttribute, this.theme);
				this.doc.getElementById(this.navTop ? 'lbPrevTop' : 'lbPrev').style.display = '';
				this.doc.getElementById(this.navTop ? 'lbPrevTop' : 'lbPrev').onclick = function() {
					if ($lb.pauseOnPrevClick) { $lb.togglePlayPause($lb.navTop ? 'lbPauseTop' : 'lbPause', $lb.navTop ? 'lbPlayTop' : 'lbPlay'); }
					$lb.changeContent($lb.activeSlide - 1); return false;
				}
			}
			if (this.navTypeHash['Hover_by_type_' + this.navType]) {
				var object = this.doc.getElementById('lbPrevHov');
				object.style.display = '';
				object.onclick = function() {
					if ($lb.pauseOnPrevClick) { $lb.togglePlayPause($lb.navTop ? 'lbPauseTop' : 'lbPause', $lb.navTop ? 'lbPlayTop' : 'lbPlay'); }
					$lb.changeContent($lb.activeSlide - 1); return false;
				}
			}
		} else {
			if (this.navTypeHash['Display_by_type_' + this.navType]) {
				this.doc.getElementById(this.navTop ? 'lbPrevTop' : 'lbPrev').setAttribute(this.classAttribute, this.theme + 'Off');
				this.doc.getElementById(this.navTop ? 'lbPrevTop' : 'lbPrev').onclick = function() { return false; }
			}
		}
		if (this.activeSlide != (this.slideArray.length - 1) && this.showNavigation) {
			if (this.navTypeHash['Display_by_type_' + this.navType]) {
				this.doc.getElementById(this.navTop ? 'lbNextTop' : 'lbNext').setAttribute(this.classAttribute, this.theme);
				this.doc.getElementById(this.navTop ? 'lbNextTop' : 'lbNext').style.display = '';
				this.doc.getElementById(this.navTop ? 'lbNextTop' : 'lbNext').onclick = function() {
					if ($lb.pauseOnNextClick) { $lb.togglePlayPause($lb.navTop ? 'lbPauseTop' : 'lbPause', $lb.navTop ? 'lbPlayTop' : 'lbPlay'); }
					$lb.changeContent($lb.activeSlide + 1); return false;
				}
			}
			if (this.navTypeHash['Hover_by_type_' + this.navType]) {
				var object = this.doc.getElementById('lbNextHov');
				object.style.display = '';
				object.onclick = function() {
					if ($lb.pauseOnNextClick) { $lb.togglePlayPause($lb.navTop ? 'lbPauseTop' : 'lbPause', $lb.navTop ? 'lbPlayTop' : 'lbPlay'); }
					$lb.changeContent($lb.activeSlide + 1); return false;
				}
			}
		} else {
			if (this.navTypeHash['Display_by_type_' + this.navType]) { 
				this.doc.getElementById(this.navTop ? 'lbNextTop' : 'lbNext').setAttribute(this.classAttribute, this.theme + 'Off');
				this.doc.getElementById(this.navTop ? 'lbNextTop' : 'lbNext').onclick = function() { return false; }
			}
		}
	} else if (this.isLyteframe) {
		if(this.activeFrame != 0) {
			this.doc.getElementById(this.navTop ? 'lbPrevTop' : 'lbPrev').setAttribute(this.classAttribute, this.theme);
			this.doc.getElementById(this.navTop ? 'lbPrevTop' : 'lbPrev').style.display = '';
			this.doc.getElementById(this.navTop ? 'lbPrevTop' : 'lbPrev').onclick = function() {
				$lb.changeContent($lb.activeFrame - 1); return false;
			}
		} else {
			this.doc.getElementById(this.navTop ? 'lbPrevTop' : 'lbPrev').setAttribute(this.classAttribute, this.theme + 'Off');
			this.doc.getElementById(this.navTop ? 'lbPrevTop' : 'lbPrev').onclick = function() { return false; }
		}
		if(this.activeFrame != (this.frameArray.length - 1)) {
			this.doc.getElementById(this.navTop ? 'lbNextTop' : 'lbNext').setAttribute(this.classAttribute, this.theme);
			this.doc.getElementById(this.navTop ? 'lbNextTop' : 'lbNext').style.display = '';
			this.doc.getElementById(this.navTop ? 'lbNextTop' : 'lbNext').onclick = function() {
				$lb.changeContent($lb.activeFrame + 1); return false;
			}
		} else {
			this.doc.getElementById(this.navTop ? 'lbNextTop' : 'lbNext').setAttribute(this.classAttribute, this.theme + 'Off');
			this.doc.getElementById(this.navTop ? 'lbNextTop' : 'lbNext').onclick = function() { return false; }
		}
	} else {
		if(this.activeImage != 0) {
			if (this.navTypeHash['Display_by_type_' + this.navType]) {
				this.doc.getElementById(this.navTop ? 'lbPrevTop' : 'lbPrev').setAttribute(this.classAttribute, this.theme);
				this.doc.getElementById(this.navTop ? 'lbPrevTop' : 'lbPrev').style.display = '';
				this.doc.getElementById(this.navTop ? 'lbPrevTop' : 'lbPrev').onclick = function() {
					$lb.changeContent($lb.activeImage - 1); return false;
				}
			}
			if (this.navTypeHash['Hover_by_type_' + this.navType]) {
				var object2 = this.doc.getElementById('lbPrevHov');
				object2.style.display = '';
				object2.onclick = function() {
					$lb.changeContent($lb.activeImage - 1); return false;
				}
			}
		} else {
			if (this.navTypeHash['Display_by_type_' + this.navType]) {
				this.doc.getElementById(this.navTop ? 'lbPrevTop' : 'lbPrev').setAttribute(this.classAttribute, this.theme + 'Off');
				this.doc.getElementById(this.navTop ? 'lbPrevTop' : 'lbPrev').onclick = function() { return false; }
			}
		}
		if(this.activeImage != (this.imageArray.length - 1)) {
			if (this.navTypeHash['Display_by_type_' + this.navType]) {
				this.doc.getElementById(this.navTop ? 'lbNextTop' : 'lbNext').setAttribute(this.classAttribute, this.theme);
				this.doc.getElementById(this.navTop ? 'lbNextTop' : 'lbNext').style.display = '';
				this.doc.getElementById(this.navTop ? 'lbNextTop' : 'lbNext').onclick = function() {
					$lb.changeContent($lb.activeImage + 1); return false;
				}
			}
			if (this.navTypeHash['Hover_by_type_' + this.navType]) {
				var object2 = this.doc.getElementById('lbNextHov');
				object2.style.display = '';
				object2.onclick = function() {
					$lb.changeContent($lb.activeImage + 1); return false;
				}
			}
		} else {
			if (this.navTypeHash['Display_by_type_' + this.navType]) { 
				this.doc.getElementById(this.navTop ? 'lbNextTop' : 'lbNext').setAttribute(this.classAttribute, this.theme + 'Off');
				this.doc.getElementById(this.navTop ? 'lbNextTop' : 'lbNext').onclick = function() { return false; }
			}
		}
	}
	this.enableKeyboardNav();
};
Lytebox.prototype.enableKeyboardNav = function() { document.onkeydown = this.keyboardAction; };
Lytebox.prototype.disableKeyboardNav = function() { document.onkeydown = ''; };
Lytebox.prototype.keyboardAction = function(e) {
	var keycode = key = escape = null;
	keycode	= (e == null) ? event.keyCode : e.which;
	key		= String.fromCharCode(keycode).toLowerCase();
	escape  = (e == null) ? 27 : e.DOM_VK_ESCAPE;
	if ((key == 'x') || (key == 'c') || (keycode == escape || keycode == 27)) {
		parent.$lb.end();
	} else if (keycode == 32 && $lb.isSlideshow && $lb.showPlayPause) {
		if ($lb.isPaused) {
			$lb.togglePlayPause($lb.navTop ? 'lbPlayTop' : 'lbPlay', $lb.navTop ? 'lbPauseTop' : 'lbPause');
		} else {
			$lb.togglePlayPause($lb.navTop ? 'lbPauseTop' : 'lbPause', $lb.navTop ? 'lbPlayTop' : 'lbPlay');
		}
		return false;
	} else if (key == 'p' || keycode == 37) {
		if ($lb.isSlideshow) {
			if($lb.activeSlide != 0) {
				$lb.disableKeyboardNav();
				$lb.changeContent($lb.activeSlide - 1);
			}
		} else if ($lb.isLyteframe) {
			if($lb.activeFrame != 0) {
				$lb.disableKeyboardNav();
				$lb.changeContent($lb.activeFrame - 1);
			}
		} else {
			if($lb.activeImage != 0) {
				$lb.disableKeyboardNav();
				$lb.changeContent($lb.activeImage - 1);
			}
		}
	} else if (key == 'n' || keycode == 39) {
		if ($lb.isSlideshow) {
			if($lb.activeSlide != ($lb.slideArray.length - 1)) {
				$lb.disableKeyboardNav();
				$lb.changeContent($lb.activeSlide + 1);
			}
		} else if ($lb.isLyteframe) {
			if($lb.activeFrame != ($lb.frameArray.length - 1)) {
				$lb.disableKeyboardNav();
				$lb.changeContent($lb.activeFrame + 1);
			}
		} else {
			if($lb.activeImage != ($lb.imageArray.length - 1)) {
				$lb.disableKeyboardNav();
				$lb.changeContent($lb.activeImage + 1);
			}
		}
	}
};
Lytebox.prototype.preloadNeighborImages = function() {
	if (this.isSlideshow) {
		if ((this.slideArray.length - 1) > this.activeSlide) {
			preloadNextImage = new Image();
			preloadNextImage.src = this.slideArray[this.activeSlide + 1][0];
		}
		if(this.activeSlide > 0) {
			preloadPrevImage = new Image();
			preloadPrevImage.src = this.slideArray[this.activeSlide - 1][0];
		}
	} else {
		if ((this.imageArray.length - 1) > this.activeImage) {
			preloadNextImage = new Image();
			preloadNextImage.src = this.imageArray[this.activeImage + 1][0];
		}
		if(this.activeImage > 0) {
			preloadPrevImage = new Image();
			preloadPrevImage.src = this.imageArray[this.activeImage - 1][0];
		}
	}
};
Lytebox.prototype.togglePlayPause = function(sHideId, sShowId) {
	if (this.isSlideshow && (sHideId == 'lbPauseTop' || sHideId == 'lbPause')) {
		for (var i = 0; i < this.slideshowIDCount; i++) { window.clearTimeout(this.slideshowIDArray[i]); }
	}
	this.doc.getElementById(sHideId).style.display = 'none';
	this.doc.getElementById(sShowId).style.display = '';
	if (sHideId == 'lbPlayTop' || sHideId == 'lbPlay') {
		this.isPaused = false;
		if (this.activeSlide == (this.slideArray.length - 1)) {
			if (this.loopSlideshow) {
				this.changeContent(0);
			} else if (this.autoEnd) {
				this.end();
			}
		} else {
			this.changeContent(this.activeSlide + 1);
		}
	} else {
		this.isPaused = true;
	}
};
Lytebox.prototype.end = function(sCaller) {
	var closeClick = (sCaller == 'slideshow' ? false : true);
	if (this.isSlideshow && this.isPaused && !closeClick) { return; }
	if (this.beforeEnd != '') {
		var callback = window[this.beforeEnd];
		if (typeof callback === 'function') {
			if (!callback()) { return; }
		}
	}
	this.disableKeyboardNav();
	document.body.onscroll = this.bodyOnscroll;
	if (this.refreshPage) {
		this.doc.getElementById('lbLoading').style.display = '';
		this.doc.getElementById('lbImage').style.display = 'none';
		this.doc.getElementById('lbIframe').style.display = 'none';
		this.doc.getElementById('lbPrev').style.display = 'none';
		this.doc.getElementById('lbNext').style.display = 'none';
		this.doc.getElementById('lbIframeContainer').style.display = 'none';
		this.doc.getElementById('lbTopContainer').style.display = 'none';
		this.doc.getElementById('lbBottomContainer').style.display = 'none';
		this.refreshPage = false;
		var uri_href = top.location.href;
		var reg=/\#.*$/g;
		uri_href=uri_href.replace(reg, "");
		top.location.href = uri_href;
		return;
	}
	this.doc.getElementById('lbMain').style.display = 'none';
	this.fade('lbOverlay', (this.doAnimations && this.ieVersion >=9 ? this.maxOpacity : 0));
	this.toggleSelects('visible');
	if (this.hideObjects) { this.toggleObjects('visible'); }
	this.doc.getElementById('lbOuterContainer').style.width = '200px';
	this.doc.getElementById('lbOuterContainer').style.height = '200px';
	if (this.isSlideshow) {
		for (var i = 0; i < this.slideshowIDCount; i++) { window.clearTimeout(this.slideshowIDArray[i]); }
	}
	if (this.isLyteframe) {
		this.initialize();
		this.doc.getElementById('lbIframe').src = 'about:blank';
	}
	if (this.afterEnd != '') {
		var callback = window[this.afterEnd];
		if (typeof callback === 'function') {
			callback();
		}
	}
};
Lytebox.prototype.checkFrame = function() {
	if (window.parent.frames[window.name] && (parent.document.getElementsByTagName('frameset').length <= 0)) {
		this.isFrame = true;
		this.doc = parent.document;
	} else {
		this.isFrame = false;
		this.doc = document;
	}
};
Lytebox.prototype.getPixelRate = function(iCurrent, iDim) {	
	var diff = (iDim > iCurrent) ? iDim - iCurrent : iCurrent - iDim;
	if (diff >= 0 && diff <= 100) { return (100 / this.resizeDuration); }
	if (diff > 100 && diff <= 200) { return (150 / this.resizeDuration); }
	if (diff > 200 && diff <= 300) { return (200 / this.resizeDuration); }
	if (diff > 300 && diff <= 400) { return (250 / this.resizeDuration); }
	if (diff > 400 && diff <= 500) { return (300 / this.resizeDuration); }
	if (diff > 500 && diff <= 600) { return (350 / this.resizeDuration); }
	if (diff > 600 && diff <= 700) { return (400 / this.resizeDuration); }
	if (diff > 700) { return (450 / this.resizeDuration); }
};
Lytebox.prototype.appear = function(sId, iOpacity) {
	var object = this.doc.getElementById(sId).style;
	object.opacity = (iOpacity / 100);
	object.MozOpacity = (iOpacity / 100);
	object.KhtmlOpacity = (iOpacity / 100);
	object.filter = "alpha(opacity=" + (iOpacity + 10) + ")";
	if (iOpacity == 100 && (sId == 'lbImage' || sId == 'lbIframe')) {
		try { object.removeAttribute("filter"); } catch(e) {}
		this.updateDetails();
	} else if (iOpacity >= this.maxOpacity && sId == 'lbOverlay') {
		for (var i = 0; i < this.overlayTimerCount; i++) { window.clearTimeout(this.overlayTimerArray[i]); }
		return;
	} else if (iOpacity >= 100 && (sId == 'lbBottomContainer' || sId == 'lbTopContainer')) {
		try { object.removeAttribute("filter"); } catch(e) {}
		for (var i = 0; i < this.imageTimerCount; i++) { window.clearTimeout(this.imageTimerArray[i]); }
		this.doc.getElementById('lbOverlay').style.height = this.getPageSize()[1] + "px";
	} else {
		if (sId == 'lbOverlay') {
			this.overlayTimerArray[this.overlayTimerCount++] = setTimeout("$lb.appear('" + sId + "', " + (iOpacity+20) + ")", 1);
		} else {
			this.imageTimerArray[this.imageTimerCount++] = setTimeout("$lb.appear('" + sId + "', " + (iOpacity+10) + ")", 1);
		}
	}
};
Lytebox.prototype.fade = function(sId, iOpacity) {
	var object = this.doc.getElementById(sId).style;
	object.opacity = (iOpacity / 100);
	object.MozOpacity = (iOpacity / 100);
	object.KhtmlOpacity = (iOpacity / 100);
	object.filter = "alpha(opacity=" + iOpacity + ")";
	if (iOpacity <= 0) {
		try {
			object.display = 'none';
		} catch(err) { }
	} else if (sId == 'lbOverlay') {
		this.overlayTimerArray[this.overlayTimerCount++] = setTimeout("$lb.fade('" + sId + "', " + (iOpacity-20) + ")", 1);
	} else {
		this.timerIDArray[this.timerIDCount++] = setTimeout("$lb.fade('" + sId + "', " + (iOpacity-10) + ")", 1);
	}
};
Lytebox.prototype.resizeW = function(sId, iCurrentW, iMaxW, iPixelRate, iSpeed) {
	if (!this.hDone) {
		this.resizeWTimerArray[this.resizeWTimerCount++] = setTimeout("$lb.resizeW('" + sId + "', " + iCurrentW + ", " + iMaxW + ", " + iPixelRate + ")", iSpeed);
		return;
	}
	var object = this.doc.getElementById(sId);
	var newW = (this.doAnimations ? iCurrentW : iMaxW);
	object.style.width = (newW) + "px";
	if (newW < iMaxW) {
		newW += (newW + iPixelRate >= iMaxW) ? (iMaxW - newW) : iPixelRate;
	} else if (newW > iMaxW) {
		newW -= (newW - iPixelRate <= iMaxW) ? (newW - iMaxW) : iPixelRate;
	}
	this.resizeWTimerArray[this.resizeWTimerCount++] = setTimeout("$lb.resizeW('" + sId + "', " + newW + ", " + iMaxW + ", " + iPixelRate + ", " + (iSpeed+.02) + ")", iSpeed+.02);
	if (parseInt(object.style.width) == iMaxW) {
		this.wDone = true;
		for (var i = 0; i < this.resizeWTimerCount; i++) { window.clearTimeout(this.resizeWTimerArray[i]); }
	}
};
Lytebox.prototype.resizeH = function(sId, iCurrentH, iMaxH, iPixelRate, iSpeed) {
	var object = this.doc.getElementById(sId);
	var newH = (this.doAnimations ? iCurrentH : iMaxH);
	object.style.height = (newH) + "px";
	if (newH < iMaxH) {
		newH += (newH + iPixelRate >= iMaxH) ? (iMaxH - newH) : iPixelRate;
	} else if (newH > iMaxH) {
		newH -= (newH - iPixelRate <= iMaxH) ? (newH - iMaxH) : iPixelRate;
	}
	this.resizeHTimerArray[this.resizeHTimerCount++] = setTimeout("$lb.resizeH('" + sId + "', " + newH + ", " + iMaxH + ", " + iPixelRate + ", " + (iSpeed+.02) + ")", iSpeed+.02);
	if (parseInt(object.style.height) == iMaxH) {
		this.hDone = true;
		for (var i = 0; i < this.resizeHTimerCount; i++) { window.clearTimeout(this.resizeHTimerArray[i]); }
	}
};
Lytebox.prototype.getPageScroll = function() {
	if (self.pageYOffset) {
		return this.isFrame ? parent.pageYOffset : self.pageYOffset;
	} else if (this.doc.documentElement && this.doc.documentElement.scrollTop){
		return this.doc.documentElement.scrollTop;
	} else if (document.body) {
		return this.doc.body.scrollTop;
	}
};
Lytebox.prototype.getPageSize = function() {
	var xScroll, yScroll, windowWidth, windowHeight;
	if (window.innerHeight && window.scrollMaxY) {
		xScroll = this.doc.scrollWidth;
		yScroll = (this.isFrame ? parent.innerHeight : self.innerHeight) + (this.isFrame ? parent.scrollMaxY : self.scrollMaxY);
	} else if (this.doc.body.scrollHeight > this.doc.body.offsetHeight){
		xScroll = this.doc.body.scrollWidth;
		yScroll = this.doc.body.scrollHeight;
	} else {
		xScroll = this.doc.getElementsByTagName("html").item(0).offsetWidth;
		yScroll = this.doc.getElementsByTagName("html").item(0).offsetHeight;
		xScroll = (xScroll < this.doc.body.offsetWidth) ? this.doc.body.offsetWidth : xScroll;
		yScroll = (yScroll < this.doc.body.offsetHeight) ? this.doc.body.offsetHeight : yScroll;
	}
	if (self.innerHeight) {
		windowWidth = (this.isFrame) ? parent.innerWidth : self.innerWidth;
		windowHeight = (this.isFrame) ? parent.innerHeight : self.innerHeight;
	} else if (document.documentElement && document.documentElement.clientHeight) {
		windowWidth = this.doc.documentElement.clientWidth;
		windowHeight = this.doc.documentElement.clientHeight;
	} else if (document.body) {
		windowWidth = this.doc.getElementsByTagName("html").item(0).clientWidth;
		windowHeight = this.doc.getElementsByTagName("html").item(0).clientHeight;
		windowWidth = (windowWidth == 0) ? this.doc.body.clientWidth : windowWidth;
		windowHeight = (windowHeight == 0) ? this.doc.body.clientHeight : windowHeight;
	}
	var pageHeight = (yScroll < windowHeight) ? windowHeight : yScroll;
	var pageWidth = (xScroll < windowWidth) ? windowWidth : xScroll;
	return new Array(pageWidth, pageHeight, windowWidth, windowHeight);
};
Lytebox.prototype.toggleObjects = function(sState) {
	var objects = this.doc.getElementsByTagName("object");
	for (var i = 0; i < objects.length; i++) {
		objects[i].style.visibility = (sState == "hide") ? 'hidden' : 'visible';
	}
	var embeds = this.doc.getElementsByTagName("embed");
	for (var i = 0; i < embeds.length; i++) {
		embeds[i].style.visibility = (sState == "hide") ? 'hidden' : 'visible';
	}
	if (this.isFrame) {
		for (var i = 0; i < parent.frames.length; i++) {
			try {
				objects = parent.frames[i].window.document.getElementsByTagName("object");
				for (var j = 0; j < objects.length; j++) {
					objects[j].style.visibility = (sState == "hide") ? 'hidden' : 'visible';
				}
			} catch(e) { }
			try {
				embeds = parent.frames[i].window.document.getElementsByTagName("embed");
				for (var j = 0; j < embeds.length; j++) {
					embeds[j].style.visibility = (sState == "hide") ? 'hidden' : 'visible';
				}
			} catch(e) { }
		}
	}	
};
Lytebox.prototype.toggleSelects = function(sState) {
	var selects = this.doc.getElementsByTagName("select");
	for (var i = 0; i < selects.length; i++ ) {
		selects[i].style.visibility = (sState == "hide") ? 'hidden' : 'visible';
	}
	if (this.isFrame) {
		for (var i = 0; i < parent.frames.length; i++) {
			try {
				selects = parent.frames[i].window.document.getElementsByTagName("select");
				for (var j = 0; j < selects.length; j++) {
					selects[j].style.visibility = (sState == "hide") ? 'hidden' : 'visible';
				}
			} catch(e) { }
		}
	}
};
Lytebox.prototype.pause = function(iMillis) {
	var now = new Date();
	var exitTime = now.getTime() + iMillis;
	while (true) {
		now = new Date();
		if (now.getTime() > exitTime) { return; }
	}
};
Lytebox.prototype.combine = function(aAnchors, aAreas) {
	var lyteLinks = [];
	for (var i = 0; i < aAnchors.length; i++) {
		lyteLinks.push(aAnchors[i]);
	}
	for (var i = 0; i < aAreas.length; i++) {
		lyteLinks.push(aAreas[i]);
	}
	return lyteLinks;
};
Lytebox.prototype.removeDuplicates = function (aArray) {
	for (var i = 1; i < aArray.length; i++) { 
		if (aArray[i][0] == aArray[i-1][0]) {
			aArray.splice(i,1);
		}
	}
	return aArray;
};
Lytebox.prototype.printWindow = function () {
	var w = 400;
	var h = 300;
	var left = parseInt((screen.availWidth/2) - (w/2));
	var top = parseInt((screen.availHeight/2) - (h/2));
	var wOpts = "width=" + w + ",height=" + h + ",left=" + left + ",top=" + top + "screenX=" + left + ",screenY=" + top + "directories=0,location=0,menubar=0,resizable=0,scrollbars=0,status=0,titlebar=0,toolbar=0";
	var d = new Date();
	var wName = 'Print' + d.getTime();
	var wUrl = document.getElementById(this.printId).src;
	this.wContent = window.open(wUrl, wName, wOpts);
	this.wContent.focus();
	var t = setTimeout("$lb.printContent()",1000);
};
Lytebox.prototype.printContent = function() {
	if (this.wContent.document.readyState == 'complete') {
		this.wContent.print();
		this.wContent.close();
		this.wContent = null;
	} else {
		var t = setTimeout("$lb.printContent()",1000);
	}
};
Lytebox.prototype.setOptions = function(sOptions) {
	this.group = '';
	this.hideObjects = this.__hideObjects;
	this.autoResize = this.__autoResize;
	this.doAnimations = this.__doAnimations;
	this.forceCloseClick = this.__forceCloseClick;
	this.refreshPage = this.__refreshPage;
	this.showPrint = this.__showPrint;
	this.navType = this.__navType;
	this.titleTop = this.__titleTop;
	this.navTop = this.__navTop;
	this.beforeStart = this.__beforeStart;
	this.afterStart = this.__afterStart
	this.beforeEnd = this.__beforeEnd;
	this.afterEnd = this.__afterEnd;
	this.scrollbars = this.__scrollbars;
	this.width = this.__width;
	this.height = this.__height;
	this.loopPlayback = this.__loopPlayback;
	this.autoPlay = this.__autoPlay;
	this.slideInterval = this.__slideInterval;
	this.showNavigation = this.__showNavigation;
	this.showClose = this.__showClose;
	this.showDetails = this.__showDetails;
	this.showPlayPause = this.__showPlayPause;
	this.autoEnd = this.__autoEnd;
	this.pauseOnNextClick = this.__pauseOnNextClick;
	this.pauseOnPrevClick = this.__pauseOnPrevClick;
	this.loopSlideshow = this.__loopSlideshow;
	var sName = sValue = '';
	var aSetting = null;
	var aOptions = sOptions.split(' ');
	for (var i = 0; i < aOptions.length; i++) {
		aSetting = aOptions[i].split(':');
		sName = (aSetting.length > 1 ? String(aSetting[0]).trim().toLowerCase() : '');
		sValue = (aSetting.length > 1 ? String(aSetting[1]).trim() : '');
		switch(sName) {
			case 'group':			this.group = (sName == 'group' ? (sValue != '' ? sValue : '') : ''); break;
			case 'hideobjects':		this.hideObjects = (/true|false/.test(sValue) ? (sValue == 'true') : this.__hideObjects); break;
			case 'autoresize':		this.autoResize = (/true|false/.test(sValue) ? (sValue == 'true') : this.__autoResize); break;
			case 'doanimations':	this.doAnimations = (/true|false/.test(sValue) ? (sValue == 'true') : this.__doAnimations); break;
			case 'forcecloseclick':	this.forceCloseClick = (/true|false/.test(sValue) ? (sValue == 'true') : this.__forceCloseClick); break;
			case 'refreshpage':		this.refreshPage = (/true|false/.test(sValue) ? (sValue == 'true') : this.__refreshPage); break;
			case 'showprint':		this.showPrint = (/true|false/.test(sValue) ? (sValue == 'true') : this.__showPrint); break;
			case 'navtype':			this.navType = (/[1-3]{1}/.test(sValue) ? parseInt(sValue) : this.__navType); break;
			case 'titletop':		this.titleTop = (/true|false/.test(sValue) ? (sValue == 'true') : this.__titleTop); break;
			case 'navtop':			this.navTop = (/true|false/.test(sValue) ? (sValue == 'true') : this.__navTop); break;
			case 'beforestart':		this.beforeStart = (sValue != '' ? sValue : this.__beforeStart); break;
			case 'afterstart':		this.afterStart = (sValue != '' ? sValue : this.__afterStart); break;
			case 'beforeend':		this.beforeEnd = (sValue != '' ? sValue : this.__beforeEnd); break;
			case 'afterend':		this.afterEnd = (sValue != '' ? sValue : this.__afterEnd); break;
			case 'scrollbars':		this.scrollbars = (/auto|yes|no/.test(sValue) ? sValue : this.__scrollbars); break;
			case 'width':			this.width = (/\d(%|px|)/.test(sValue) ? sValue : this.__width); break;
			case 'height':			this.height = (/\d(%|px|)/.test(sValue) ? sValue : this.__height); break;
			case 'loopplayback':	this.loopPlayback = (/true|false/.test(sValue) ? (sValue == 'true') : this.__loopPlayback); break;
			case 'autoplay':		this.autoPlay = (/true|false/.test(sValue) ? (sValue == 'true') : this.__autoPlay); break;
			case 'slideinterval':	this.slideInterval = (/\d/.test(sValue) ? parseInt(sValue) : this.__slideInterval); break;
			case 'shownavigation':	this.showNavigation = (/true|false/.test(sValue) ? (sValue == 'true') : this.__showNavigation); break;
			case 'showclose':		this.showClose = (/true|false/.test(sValue) ? (sValue == 'true') : this.__showClose); break;
			case 'showdetails':		this.showDetails = (/true|false/.test(sValue) ? (sValue == 'true') : this.__showDetails); break;
			case 'showplaypause':	this.showPlayPause = (/true|false/.test(sValue) ? (sValue == 'true') : this.__showPlayPause); break;
			case 'autoend':			this.autoEnd = (/true|false/.test(sValue) ? (sValue == 'true') : this.__autoEnd); break;
			case 'pauseonnextclick': this.pauseOnNextClick = (/true|false/.test(sValue) ? (sValue == 'true') : this.__pauseOnNextClick); break;
			case 'pauseonprevclick': this.pauseOnPrevClick = (/true|false/.test(sValue) ? (sValue == 'true') : this.__pauseOnPrevClick); break;
			case 'loopslideshow':	this.loopSlideshow = (/true|false/.test(sValue) ? (sValue == 'true') : this.__loopSlideshow); break;
		}
	}
};
Lytebox.prototype.buildObject = function(w, h, url, ext) {
	var object = '';
	var classId = '';
	var codebase = '';
	var pluginsPage = '';
	var auto = this.autoPlay ? 'true' : 'false';
	var loop = this.loopPlayback ? 'true' : 'false';
	switch(ext) {
		case 'mov':
			codebase = 'http://www.apple.com/qtactivex/qtplugin.cab';
			pluginsPage = 'http://www.apple.com/quicktime/';
			classId = 'clsid:02BF25D5-8C17-4B23-BC80-D3488ABDDC6B';
			object 	= '<object classid="' + classId + '" width="' + w + '" height="' + h + '" codebase="' + codebase + '">'
					+ '<param name="src" value="' + url + '">'
					+ '<param name="autoplay" value="' + auto + '">'
					+ '<param name="loop" value="' + loop + '">'
					+ '<param name="controller" value="true">'
					+ '<embed src="' + url + '" width="' + w + '" height="' + h + '" autoplay="' + auto + '" loop="' + loop + '" controller="true" pluginspage="' + pluginsPage + '"></embed>'
					+ '</object>';		
			if (this.qtVersion <= 0) {
				object	= '<div style="padding:1em;">'
						+ '<h2>QUICKTIME PLAYER</h2>'
						+ '<p>Content on this page requires a newer version of QuickTime. Please click the image link below to download and install the latest version.</p>'
						+ '<p><a href="http://www.apple.com/quicktime/" target="_blank"><img src="http://images.apple.com/about/webbadges/images/qt7badge_getQTfreeDownload.gif" alt="Get QuickTime" border="0" /></a></p>'
						+ '</div>';
			}
			break;
		case 'avi':
		case 'mpg':
		case 'mpeg':
		case 'wmv':
			classId = 'clsid:02BF25D5-8C17-4B23-BC80-D3488ABDDC6B';			
			object 	= '<object classid="' + classId + '" width="' + w + '" height="' + h + '" codebase="' + codebase + '">'
					+ '<param name="src" value="' + url + '">'
					+ '<param name="autoplay" value="' + auto + '">'
					+ '<param name="loop" value="' + loop + '">'
					+ '<param name="controller" value="true">'
					+ '<object type="video/quicktime" data="' + url + '" width="' + w + '" height="' + h + '">'
					+ '<param name="controller" value="false">'
					+ '<param name="autoplay" value="' + auto + '">'
					+ '<param name="loop" value="' + loop + '">'
					+ '</object>' 
					+ '</object>';
			break;
		case 'swf':
			classId = 'clsid:D27CDB6E-AE6D-11cf-96B8-444553540000';
			object 	= '<object classid="' + classId + '" width="' + w + '" height="' + h + '" codebase="' + codebase + '">'
					+ '<param name="movie" value="' + url + '">'
					+ '<param name="quality" value="high">'
					+ '<param name="wmode" value="opaque">'
					+ '<!--[if !IE]>-->'
					+ '<object type="application/x-shockwave-flash" data="' + url + '" width="' + w + '" height="' + h + '">'
					+ '<!--<![endif]-->'
					+ '<param name="quality" value="high">'
					+ '<param name="wmode" value="opaque">'
					+ '<div style="padding:1em;">'
					+ '<h2>FLASH PLAYER</h2>'
					+ '<p>Content on this page requires a newer version of Adobe Flash Player. Please click the image link below to download and install the latest version.</p>'
					+ '<p><a href="http://www.adobe.com/go/getflashplayer" target="_blank"><img src="http://www.adobe.com/macromedia/style_guide/images/160x41_Get_Flash_Player.jpg" alt="Get Adobe Flash player" border="0" /></a></p>'
					+ '</div>'
					+ '<!--[if !IE]>-->'
					+ '</object>'
					+ '<!--<![endif]-->'
					+ '</object>';
			break;
	}
	return object;
};	
Lytebox.prototype.getQuicktimeVersion = function() {
	var agent = navigator.userAgent.toLowerCase(); 
	var version = -1;
	if (navigator.plugins != null && navigator.plugins.length > 0) {
		for (i=0; i < navigator.plugins.length; i++ ) {
			var plugin = navigator.plugins[i];
			if (plugin.name.indexOf('QuickTime') > -1) {
				version = parseFloat(plugin.name.substring(18));
			}
		}
	} else if (agent.indexOf('msie') != -1 && parseInt(navigator.appVersion) >= 4 && agent.indexOf('win') != -1 && agent.indexOf('16bit') == -1) {
		var control = null;
		try {
			control = new ActiveXObject('QuickTime.QuickTime');
		} catch (e) { }
		if (control) {
			isInstalled = true;
		}			
		try {
			control = new ActiveXObject('QuickTimeCheckObject.QuickTimeCheck');
		} catch (e) { return; }
		if (control) {
			isInstalled = true;
			version = control.QuickTimeVersion.toString(16); // Convert to hex
			version = version.substring(0, 1) + '.' + version.substring(1, 3);
			version = parseInt(version);
		}
	}
	return version;
};	
Lytebox.prototype.findPos = function(el) {
	if (this.ie && this.doc.compatMode == 'BackCompat') {
		return [0, 16, 12];
	}
	var left = 0;
	var top = 0;
	var height = 0;
	height = el.offsetHeight + 6;
	if (el.offsetParent) {
		do {
			left += el.offsetLeft;
			top += el.offsetTop;
		} while (el = el.offsetParent);
	}
	return [left, top, height];
};
Lytebox.prototype.isMobile = function() {
	var ua = navigator.userAgent;
	return (ua.match(/ipad/i) != null)
		|| (ua.match(/ipod/i) != null)
		|| (ua.match(/iphone/i) != null)
		|| (ua.match(/android/i) != null)
		|| (ua.match(/opera mini/i) != null)
		|| (ua.match(/blackberry/i) != null)
		|| (ua.match(/(pre\/|palm os|palm|hiptop|avantgo|plucker|xiino|blazer|elaine)/i) != null)
		|| (ua.match(/(iris|3g_t|windows ce|opera mobi|windows ce; smartphone;|windows ce; iemobile)/i) != null)
		|| (ua.match(/(mini 9.5|vx1000|lge |m800|e860|u940|ux840|compal|wireless| mobi|ahong|lg380|lgku|lgu900|lg210|lg47|lg920|lg840|lg370|sam-r|mg50|s55|g83|t66|vx400|mk99|d615|d763|el370|sl900|mp500|samu3|samu4|vx10|xda_|samu5|samu6|samu7|samu9|a615|b832|m881|s920|n210|s700|c-810|_h797|mob-x|sk16d|848b|mowser|s580|r800|471x|v120|rim8|c500foma:|160x|x160|480x|x640|t503|w839|i250|sprint|w398samr810|m5252|c7100|mt126|x225|s5330|s820|htil-g1|fly v71|s302|-x113|novarra|k610i|-three|8325rc|8352rc|sanyo|vx54|c888|nx250|n120|mtk |c5588|s710|t880|c5005|i;458x|p404i|s210|c5100|teleca|s940|c500|s590|foma|samsu|vx8|vx9|a1000|_mms|myx|a700|gu1100|bc831|e300|ems100|me701|me702m-three|sd588|s800|8325rc|ac831|mw200|brew |d88|htc\/|htc_touch|355x|m50|km100|d736|p-9521|telco|sl74|ktouch|m4u\/|me702|8325rc|kddi|phone|lg |sonyericsson|samsung|240x|x320|vx10|nokia|sony cmd|motorola|up.browser|up.link|mmp|symbian|smartphone|midp|wap|vodafone|o2|pocket|kindle|mobile|psp|treo)/i) != null);
};
String.prototype.trim = function () { return this.replace(/^\s+|\s+$/g, ''); }
if (window.addEventListener) {
	window.addEventListener("load", initLytebox, false);
} else if (window.attachEvent) {
	window.attachEvent("onload", initLytebox);
} else {
	window.onload = function() {initLytebox();}
}
function initLytebox(lang) { 
    myLytebox = $lb = new Lytebox(lang);
}