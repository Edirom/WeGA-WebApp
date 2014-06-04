xquery version "3.0" encoding "UTF-8";

(:~
: WeGA XHTML XQuery-Modul
:
: @author Peter Stadler 
: @version 1.0
:)

module namespace xho="http://xquery.weber-gesamtausgabe.de/modules/xho";
declare default collation "?lang=de;strength=primary";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace xmldb = "http://exist-db.org/xquery/xmldb";
declare namespace request = "http://exist-db.org/xquery/request";
import module namespace functx="http://www.functx.com";
import module namespace wega="http://xquery.weber-gesamtausgabe.de/modules/wega" at "wega.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date" at "date.xqm";
import module namespace datetime="http://exist-db.org/xquery/datetime" at "java:org.exist.xquery.modules.datetime.DateTimeModule";

declare option exist:serialize "method=xhtml media-type=text/html indent=no omit-xml-declaration=yes encoding=utf-8";

(:~
 : Creates HTML head container
 :
 : @author Peter Stadler
 : @param $lang the language switch (de|en)
 : @return XHTML element
 :)

declare function xho:createHeadContainer($lang as xs:string) as element()* {
    let $html_pixDir := config:get-option('html_pixDir')
    let $baseHref := config:get-option('baseHref')
    let $uriTokens := tokenize(substring-after(xmldb:decode-uri(request:get-uri()), $baseHref), '/')
    let $search := core:join-path-elements(($baseHref, $lang, lang:get-language-string('search', $lang)))
    let $index := core:join-path-elements(($baseHref, $lang, lang:get-language-string('index', $lang)))
    let $impressum := core:join-path-elements(($baseHref, $lang, lang:get-language-string('about', $lang)))
    let $help := core:join-path-elements(($baseHref, $lang, lang:get-language-string('help', $lang)))
    let $switchLanguage := 
        for $i in $uriTokens[string-length(.) gt 2]
        return
        if (matches($i, 'A\d{6}'))
            then $i
            else if($lang eq 'en') 
                then replace(lang:translate-language-string(replace($i, '_', ' '), $lang, 'de'), '\s', '_') (: Ersetzen von Leerzeichen durch Unterstriche in der URL :)
                else replace(lang:translate-language-string(replace($i, '_', ' '), $lang, 'en'), '\s', '_')
    let $switchLanguage := if($lang eq 'en')
        then <xhtml:a href="{core:join-path-elements(($baseHref, 'de', $switchLanguage))}" title="{lang:get-language-string('switchLanguage', 'de')}"><xhtml:img src="{core:join-path-elements(($baseHref, $html_pixDir, 'de.gif'))}" alt="germanFlag" width="20" height="12"/></xhtml:a>
        else <xhtml:a href="{core:join-path-elements(($baseHref, 'en', $switchLanguage))}" title="{lang:get-language-string('switchLanguage', 'en')}"><xhtml:img src="{core:join-path-elements(($baseHref, $html_pixDir, 'gb.gif'))}" alt="englishFlag" width="20" height="12"/></xhtml:a>
    return (
    element xhtml:div {
        attribute id {"headContainer"},
        if($config:isDevelopment) then attribute class {'dev'}
        else if(config:get-option('environment') eq 'release') then attribute class {'rel'}
        else (),
        <xhtml:h1><xhtml:a href="{$index}"><xhtml:span class="hiddenLink">Carl Maria von Weber Gesamtausgabe</xhtml:span></xhtml:a></xhtml:h1>,
        <xhtml:ul id="topMenu">
            <xhtml:li><xhtml:a href="{$search}">{lang:get-language-string('search',$lang)}</xhtml:a></xhtml:li>
            <xhtml:li><xhtml:a href="{$index}">{lang:get-language-string('home',$lang)}</xhtml:a></xhtml:li>
            <xhtml:li><xhtml:a href="{$impressum}">{lang:get-language-string('about',$lang)}</xhtml:a></xhtml:li>
            <xhtml:li><xhtml:a href="{$help}">{lang:get-language-string('help',$lang)}</xhtml:a></xhtml:li>
            <xhtml:li>{$switchLanguage}</xhtml:li>
        </xhtml:ul>
    },
    <xhtml:noscript><xhtml:p class="noscript">{lang:get-language-string('noscript', $lang)}</xhtml:p></xhtml:noscript>,
    <xhtml:p id="IE6" class="noscript" style="display:none;">{lang:get-language-string('oldBrowser', $lang)}</xhtml:p>,
    <xhtml:script type="text/javascript">if(navigator.userAgent.indexOf('MSIE 6') != -1) $('IE6').show()</xhtml:script>
    )
};


(:~
 : Creates footer for document view
 :
 : @author Peter Stadler
 : @param $lang the language switch (de|en)
 : @param $docPath path to document
 : @return XHTML element
 :)

declare function xho:createFooter($lang as xs:string, $docPath as xs:string) as element(xhtml:div) {
    let $docID := substring-before(functx:substring-after-last($docPath, '/'), '.')
    let $svnProps := config:get-svn-props($docID)
    let $author := map:get($svnProps, 'author')
    let $date := xs:dateTime(map:get($svnProps, 'dateTime'))
    let $rev := map:get($svnProps, 'rev')
    let $dateFormat := if($lang eq 'en')
        then '%B %d, %Y'
        else '%d. %B %Y'
    let $encryptedBugEmail := wega:encryptString(config:get-option('bugEmail'), ())
    let $version := concat(config:get-option('version'), if($config:isDevelopment) then 'dev' else '')
    let $versionDate := date:strfdate(xs:date(config:get-option('versionDate')), $lang, $dateFormat)
    let $permalink := core:permalink($docID)
    return 
        if(exists($author) and exists($date)) then
            <xhtml:div id="footer">
                <xhtml:p>{lang:get-language-string('proposedCitation', $lang)}, {$permalink} (<xhtml:a href="{wega:createLinkToDoc(core:doc(config:get-option('versionNews')), $lang)}">{lang:get-language-string('versionInformation',($version, $versionDate), $lang)}</xhtml:a>) </xhtml:p>
                <xhtml:p>{
                    if($config:isDevelopment) then lang:get-language-string('lastChangeDateWithAuthor',(date:strfdate($date, $lang, $dateFormat),$author),$lang)
                    else lang:get-language-string('lastChangeDateWithoutAuthor', date:strfdate($date, $lang, $dateFormat), $lang)
                }</xhtml:p>
                  {if($lang eq 'en') then 
                  <xhtml:p>If you've spotted some error or inaccurateness please do not hesitate to inform us via 
                    <xhtml:span onclick="javascript:decEma('{$encryptedBugEmail}')" class="ema">{wega:obfuscateEmail(config:get-option('bugEmail'))}</xhtml:span>
                  </xhtml:p>
                  else 
                  <xhtml:p>Wenn Ihnen auf dieser Seite ein Fehler oder eine Ungenauigkeit aufgefallen ist, so bitten wir um eine kurze Nachricht an
                    <xhtml:span onclick="javascript:decEma('{$encryptedBugEmail}')" class="ema">{wega:obfuscateEmail(config:get-option('bugEmail'))}</xhtml:span>
                  </xhtml:p>
                  }
                    {xho:createCommonFooter()}
            </xhtml:div>
        else xho:createFooter()
};


(:~
 : Creates HTML footer without parameters
 :
 : @author Peter Stadler
 : @return XHTML element
 :)

declare function xho:createFooter() as element(xhtml:div) {
    <xhtml:div id="footer">{xho:createCommonFooter()}</xhtml:div>
};

(:~
 : Creates HTML footer with common content - is called by "xho:createFooter()"
 :
 : @author Peter Stadler
 : @return XHTML element 
 :)

declare function xho:createCommonFooter() as item()* {
    let $html_pixDir := config:get-option('html_pixDir')
    let $baseHref := config:get-option('baseHref')
    let $piwikTrackingCode := 
        if(config:get-option('environment') eq 'production') then (
            <!-- Piwik -->,
            <xhtml:script type="text/javascript">
              var _paq = _paq || [];
              _paq.push(["trackPageView"]);
              _paq.push(["enableLinkTracking"]);
            
              (function() {{
                var u=(("https:" == document.location.protocol) ? "https" : "http") + "{concat(substring-after($baseHref, 'http'), '/piwik/')}";
                _paq.push(["setTrackerUrl", u+"piwik.php"]);
                _paq.push(["setSiteId", "1"]);
                var d=document, g=d.createElement("script"), s=d.getElementsByTagName("script")[0]; g.type="text/javascript";
                g.defer=true; g.async=true; g.src=u+"piwik.js"; s.parentNode.insertBefore(g,s);
              }})();
            </xhtml:script>,
            <!-- End Piwik Code -->,
            <!-- Piwik Image Tracker -->,
            <xhtml:noscript><xhtml:p><xhtml:img src="{concat($baseHref, '/piwik/piwik.php?idsite=1&amp;rec=1')}" style="border:0" alt="" /></xhtml:p></xhtml:noscript>,
            <!-- End Piwik -->
        )
        else ()
    return (
    <xhtml:div id="supportBadges">
        <xhtml:a href="http://validator.w3.org/check?uri=referer"><xhtml:img src="http://www.w3.org/Icons/valid-xhtml11" alt="Valid XHTML 1.1" height="31" width="88" title="W3C Markup Validation Service" /></xhtml:a>
        <xhtml:a href="http://exist-db.org"><xhtml:img src="http://exist-db.org/exist/icons/existdb-128.png" alt="powered by eXist" title="eXist-db Open Source Native XML Database" /></xhtml:a>
        <xhtml:a href="http://staatsbibliothek-berlin.de"><xhtml:img src="{core:join-path-elements(($baseHref, $html_pixDir,'stabi-logo.png'))}" alt="Staatsbibliothek zu Berlin - Preußischer Kulturbesitz" title="Staatsbibliothek zu Berlin - Preußischer Kulturbesitz" /></xhtml:a>
        <xhtml:a href="http://www.adwmainz.de"><xhtml:img src="{core:join-path-elements(($baseHref, $html_pixDir,'adwMainz.png'))}" alt="Akademie der Wissenschaften und der Literatur Mainz" title="Akademie der Wissenschaften und der Literatur Mainz" /></xhtml:a>
        <xhtml:a href="http://www.tei-c.org"><xhtml:img src="http://www.tei-c.org/About/Badges/powered-by-TEI.png" alt="Powered by TEI" title="TEI: Text Encoding Initiative" /></xhtml:a>
        <xhtml:br/>
        <xhtml:a href="http://www.uni-paderborn.de/"><xhtml:img src="{core:join-path-elements(($baseHref, $html_pixDir,'upb-logo.png'))}" alt="Universität Paderborn" title="Universität Paderborn" /></xhtml:a>
        <xhtml:a href="http://www.hfm-detmold.de"><xhtml:img src="{core:join-path-elements(($baseHref, $html_pixDir,'hfm-logo.png'))}" alt="Hochschule für Musik Detmold" title="Hochschule für Musik Detmold" /></xhtml:a>
    </xhtml:div>,
    $piwikTrackingCode
    )
};


(:~
 : Create HTML head with title, css imports and javascript references
 :
 : @author Peter Stadler
 : @param $stylesheets the css files
 : @param $jscripts the js files
 : @param $metaData meta data that is created by xquery
 : @param $domLoaded scripts to load when DOM is loaded
 : @param $additionalJScripts additional scripts
 : @return XHTML element
 :)

declare function xho:createHtmlHead($stylesheets as xs:string*, $jscripts as xs:string*, $metaData as element(wega:metaData), $domLoaded as node()?, $additionalJScripts as node()?) as element(xhtml:head) {
    let $html_pixDir := config:get-option('html_pixDir')
    let $commonStylesheets := ('main.css', 'tei_common.css', 'ajaxtabs.css', 'lytebox.css', 'xmlPrettyPrint.css')
    let $commonJscripts := ('text_common.js', 'ajaxtabs.js', 'prototype_min.js', 'lytebox_min.js', 'wz_tooltip/wz_tooltip_min.js')
    let $baseHref := config:get-option('baseHref')
    return 
        <xhtml:head>
            <xhtml:meta content="text/html; charset=utf-8" http-equiv="Content-Type"/>
            <xhtml:meta name="fragment" content="!"/> 
            <xhtml:link rel="icon" href="{core:join-path-elements(($baseHref, $html_pixDir, 'weber_favicon.ico'))}" type="image/x-icon"/>
            {$metaData/*}
            {for $i in insert-before($stylesheets, 0, $commonStylesheets)
                return <xhtml:link media="all" type="text/css" rel="stylesheet" href="{core:join-path-elements(($baseHref, config:get-option('html_cssDir'), $i))}"/>
            }
            <xhtml:script type="text/javascript" src="{core:join-path-elements(($baseHref, 'functions/getJavaScriptOptions.xql'))}"></xhtml:script>
            {for $i in insert-before($jscripts, 0, $commonJscripts)
                return <xhtml:script type="text/javascript" src="{core:join-path-elements(($baseHref, config:get-option('html_jsDir'), $i))}"></xhtml:script> 
            }
            {for $i in $additionalJScripts//function
            	return <xhtml:script type="text/javascript">{wega:printJavascriptFunction($i)};</xhtml:script>
            }
            <xhtml:script type="text/javascript">
            document.observe('dom:loaded', function () {{
                {for $i in $domLoaded//function
                    return (wega:printJavascriptFunction($i), ';')
                }
                tt_Init();
            }});
            </xhtml:script>
        </xhtml:head>
};


(:~
 : Creates bread crumb tree starting at a certain document
 :
 : @author Peter Stadler
 : @param $doc the document for which the breadcrumb will be created
 : @param $lang the language switch (de|en)
 : @return XHTML (div)
 :)

declare function xho:createBreadCrumb($doc as item(), $lang as xs:string) as element(xhtml:div) {
    let $docID := $doc/root()/*/@xml:id cast as xs:string
    let $baseHref := config:get-option('baseHref')
    let $isDiary := config:is-diary($docID) (: Diverse Sonderbehandlungen fürs Tagebuch :)
    let $authors := if($isDiary) 
        then wega:createPersonLink('A002068', $lang, 'fs')
        else for $i in $doc//tei:titleStmt//tei:author return wega:printCorrespondentName($i, $lang, 'fs')
    let $authorsCount := count($authors)
    let $docStatus := wega:getRevisionStatus($doc)
    return (
    <xhtml:div id="breadCrumb">
        {for $i at $count in $authors 
        let $authorID := functx:substring-after-last($i/@href, '/')
        let $docType := 
            if(config:is-letter($docID)) then
                if($authorID ne '') then <xhtml:a href="{core:join-path-elements(($baseHref, $lang, $authorID, lang:get-language-string('correspondence',$lang)))}">{lang:get-language-string('correspondence',$lang)}</xhtml:a>
                else <xhtml:span class="noDataFound">{lang:get-language-string('correspondence',$lang)}</xhtml:span>
            else if(config:is-writing($docID)) then 
                if($authorID ne '') then <xhtml:a href="{core:join-path-elements(($baseHref, $lang, $authorID, lang:get-language-string('writings',$lang)))}">{lang:get-language-string('writings',$lang)}</xhtml:a>
                else <xhtml:span class="noDataFound">{lang:get-language-string('writings',$lang)}</xhtml:span>
            else if($isDiary) then <xhtml:a href="{core:join-path-elements(($baseHref, $lang, $authorID, lang:get-language-string('diaries',$lang)))}">{lang:get-language-string('diaries',$lang)}</xhtml:a>
            else if(config:is-news($docID)) then <xhtml:span class="noDataFound">{lang:get-language-string('news',$lang)}</xhtml:span>
            else ()
                                        
        return ($i, xs:string(' > '), $docType, xs:string(' > '), <xhtml:span class="{$docStatus}">{$docID}</xhtml:span>, if($count = $authorsCount) then () else element xhtml:br{})
        }
    </xhtml:div>
    )
};

(:~
 : Creates bread crumb tree starting at a certain person
 :
 : @author Peter Stadler
 : @param $id of author
 : @param $docType type of documents related to the author
 : @param $lang the language switch (de|en)
 : @return XHTML (div)
 :)

declare function xho:createBreadCrumb($id as xs:string, $docType as xs:string, $lang as xs:string) as element(xhtml:div) {
    let $author := wega:createPersonLink($id, $lang, 'fs')
    return
    <xhtml:div id="breadCrumb">
        {$author, xs:string(' > '), lang:get-language-string($docType, $lang)}
    </xhtml:div>
};


(:~
 : Builds the list of works by a person
 :
 : @author Peter Stadler
 : @param $id person id for work list
 : @param $lang the language switch (de|en)
 : @return element
 :)
 
declare function xho:createWorksDocumentsUL($id as xs:string, $lang as xs:string) as element(xhtml:div) {
    let $persName := wega:getRegName($id)
    let $baseHref := config:get-option('baseHref')
    let $listItems :=  
        for $i in ('letters', 'writings', 'diaries', 'works')
(:            let $log := util:log-system-out($i):)
            let $coll := core:getOrCreateColl($i, $id, true())
            let $title := lang:get-language-string(concat($i,'TableTitle'), wega:printFornameSurname($persName), $lang)
            let $href := if($i eq 'letters')
                then core:join-path-elements(($baseHref, $lang, $id, lang:get-language-string('correspondence', $lang)))
                else core:join-path-elements(($baseHref, $lang, $id, lang:get-language-string($i, $lang)))
            let $linkText := if($i eq 'letters')
                then lang:get-language-string('correspondence', $lang)
                else lang:get-language-string($i, $lang)
            return if(exists($coll) and ($i ne 'diaries' or $id eq 'A002068')) (: Tagebuch nur bei Weber anzeigen :)
                then <xhtml:li><xhtml:a href="{$href}" title="{$title}">{$linkText}</xhtml:a></xhtml:li> 
                else <xhtml:li><xhtml:span class="noTarget">{$linkText}</xhtml:span></xhtml:li>
    return (
    <xhtml:div id="works">
        <xhtml:h2>{lang:get-language-string('worksDocuments',$lang)}</xhtml:h2>
        <xhtml:ul>
            {$listItems}
        </xhtml:ul>
    </xhtml:div>
    )
};


(:~
 : Collect common html meta data for a given document
 :
 : @author Peter Stadler
 : @param $doc the document as a node
 : @return item of meta data 
 :)

declare function xho:collectCommonMetaData($doc as document-node()?) as element(wega:metaData) {
    let $docID := $doc/*/data(@xml:id)
    let $contributors := 
        if(exists($doc//tei:fileDesc/tei:titleStmt/(tei:author | tei:editor))) then for $i in $doc//tei:fileDesc/tei:titleStmt/(tei:author | tei:editor) return <xhtml:meta name="DC.contributor" content="{$i}"/>
        else (<xhtml:meta name="DC.contributor" content="Joachim Veit"/>,<xhtml:meta name="DC.contributor" content="Peter Stadler"/>)
    return 
    <wega:metaData>
        <xhtml:link rel="schema.DC" href="http://purl.org/dc/elements/1.1/"/>
        <xhtml:link rel="schema.DCTERMS" href="http://purl.org/dc/terms/"/>
        {if($docID) then (
            <xhtml:meta name="DC.creator" content="{map:get(config:get-svn-props($docID), 'author')}"/>,
            <xhtml:meta name="DC.date" content="{map:get(config:get-svn-props($docID), 'dateTime')}" scheme="DCTERMS.W3CDTF"/> 
        )
        else ()
        }
        <xhtml:meta name="DC.publisher" content="Carl-Maria-von-Weber-Gesamtausgabe"/>
        <xhtml:meta name="DC.type" content="Text" scheme="DCTERMS.DCMIType"/>
        <xhtml:meta name="DC.format" content="text/html" scheme="DCTERMS.IMT"/>
        {$contributors,
        if ($docID) then <xhtml:meta name="DC.identifier" content="{core:permalink($docID)}" scheme="DCTERMS.URI"/>
        else ()}
    </wega:metaData>
};

(:~
 : Creates container/placeholder for popup data
 :
 : @author Christian Epp
 : @param $lang the language switch (de|en)
 : @return element with popup-data in list-view 
 :)
 
declare function xho:createPopupContainer($lang as xs:string) as element(xhtml:div) {
    <xhtml:div id="popupMain" style="position: fixed; visibility: hidden; left:10%; top: 10%; z-index: 7538; margin: 10px; background-color:#fff">
        <xhtml:div style="border: 2px solid #AAAAAA;">
            <xhtml:h2>{lang:get-language-string("restrictSelection", $lang)}</xhtml:h2>
            <xhtml:ul id="popupTabs" class="shadetabs">
                <xhtml:li onmouseover="this.style.cursor='pointer'">
                    <xhtml:a title="test" class="test"></xhtml:a>
                </xhtml:li>
            </xhtml:ul>
            <xhtml:div id="popupContent" style="text-align:left; position:relative; border: 2px solid #AAAAAA; margin: 0 5px; overflow:auto;">
            </xhtml:div> 
            <xhtml:h3>
                <xhtml:span style="margin-right:100px" onmouseover="this.style.cursor='pointer'" >{lang:get-language-string("cancel", $lang)}</xhtml:span>
                <!--<span onmouseover="this.style.cursor='pointer'">{lang:get-language-string("reset", $lang)} </xhtml:span>-->
                <xhtml:span onmouseover="this.style.cursor='pointer'" >{lang:get-language-string("confirm", $lang)}</xhtml:span>
            </xhtml:h3>
        </xhtml:div>
    </xhtml:div>
};


(:~
 : Creates tabs for listview pages
 :
 : @author Peter Stadler
 : @param  $curDocType the active document type as given by menus.xml (e.g. "letters", "persons")
 : @param  $menuID the @xml:id of a div in menu.xml *or* a person ID (e.g. "indices", "A002068")
 : @return a xhtml element ul
 :)
 
declare function xho:createTabsUL($curDocType as xs:string, $menuID as xs:string, $lang as xs:string) as element(xhtml:ul) {
    let $baseHref := config:get-option('baseHref')
    let $isPerson := config:is-person($menuID)
    let $menuNode := 
        if($isPerson) then doc(config:get-option('menusFile'))//id('persons')
        else doc(config:get-option('menusFile'))//id($menuID)
    let $urlPart1 := 
        if($isPerson) then core:join-path-elements(($baseHref, $lang, $menuID))
        else core:join-path-elements(($baseHref, $lang, lang:get-language-string($menuNode/pageName, $lang)))
    let $listItems := 
        for $i in $menuNode/entry
        let $coll := core:getOrCreateColl($i/docType, $menuID, true())
        let $title := lang:get-language-string($i/displayName, $lang)
        let $url := core:join-path-elements(($urlPart1, encode-for-uri($title)))
(:        let $log := util:log-system-out(string-join(($i/docType, $curDocType), ' ;; ')):)
        return (
            <xhtml:li>{
                if(exists($coll) and ($i/docType ne 'diaries' or $menuID eq 'A002068' or $menuID eq 'indices')) (: Tagebuch nur bei Weber anzeigen :)
                    then element xhtml:a {
                        attribute href {$url},
                        attribute title {$title},
                        if($curDocType = $i/docType)
                            then attribute class {'selected'}
                            else (),
                        $title
                        }
                    else element xhtml:span {
                        attribute title {$title},
                        attribute class {'notAvailable'},
                        $title
                    }
                }
            </xhtml:li>
        )
    return 
    <xhtml:ul id="ajaxTabs" class="shadetabs">
        {$listItems}
    </xhtml:ul>
};

(:~
 : Collect page specific meta data that goes under html:head
 :
 : @author Peter Stadler
 : @param  $docType the active document type as given by menus.xml (e.g. "letters", "persons")
 : @param  $menuID the @xml:id of a div in menu.xml *or* a person ID (e.g. "indices", "A002068")
 : @param $lang the language switch (en|de)
 : @return <metadata/>: a container for html:title and html:meta elements
 :)
 
declare function xho:collectMetaData($docType as xs:string, $menuID as xs:string, $lang as xs:string) as element(wega:metadata) {
    let $menuNode := 
        if(config:is-person($menuID)) then doc(config:get-option('menusFile'))//id('persons')/entry[./docType eq $docType]
        else doc(config:get-option('menusFile'))//id($menuID)/entry[./docType eq $docType]
    let $persName := wega:printFornameSurname(wega:getRegName($menuID))
    let $pageDescription := 
        if(config:is-person($menuID)) then lang:get-language-string($menuNode/string(@metaDesc), $persName, $lang)
        else lang:get-language-string($menuNode/string(@metaDesc), $lang)
    let $pageTitle := 
        if(config:is-person($menuID)) then lang:get-language-string($menuNode/string(@metaTitle), $persName, $lang)
        else lang:get-language-string($menuNode/string(@metaTitle), $lang)
    let $commonMetaData := xho:collectCommonMetaData(())
    let $subject := lang:get-language-string($menuNode/displayName/text(), $lang)
    return 
        <wega:metaData>
            <xhtml:title>{$pageTitle}</xhtml:title>
            {$commonMetaData/*}
            <xhtml:meta name="DC.title" content="{$pageTitle}"/>
            <xhtml:meta name="description" content="{$pageDescription}" lang="{$lang}"/>
            <xhtml:meta name="DC.creator" content="Peter Stadler"/>
            <xhtml:meta name="DC.description" content="{$pageDescription}"/>
            <xhtml:meta name="DC.subject" content="{$subject}"/>
            <xhtml:meta name="DC.language" content="de" scheme="DCTERMS.RFC3066"/>
        </wega:metaData>
};

(:~
 : This function acts as a template to be used on the pages index.xql and error.xql
 :
 : @author Peter Stadler
 : @param $startID the ID fpr the reference
 : @param $lang the language switch (de|en)
 : @return html:div 
 :)
 
declare function xho:printEditionLinks($startID as xs:string, $lang as xs:string) as element(xhtml:div) {
    let $baseHref := config:get-option('baseHref')
    return
    <xhtml:div id="edition">
        <xhtml:h1>{lang:get-language-string('digitalEdition', $lang)}</xhtml:h1>
        <xhtml:ul>
            <xhtml:li><xhtml:a href="{core:join-path-elements(($baseHref, $lang, $startID))}">Weber Person</xhtml:a></xhtml:li>
            <xhtml:li><xhtml:a href="{core:join-path-elements(($baseHref, $lang, $startID, lang:get-language-string('correspondence', $lang)))}">Weber {lang:get-language-string('correspondence', $lang)}</xhtml:a></xhtml:li>
            <xhtml:li><xhtml:a href="{core:join-path-elements(($baseHref, $lang, $startID, lang:get-language-string('diaries', $lang)))}">Weber {lang:get-language-string('diaries', $lang)}</xhtml:a></xhtml:li>
            <xhtml:li><xhtml:a href="{core:join-path-elements(($baseHref, $lang, $startID, lang:get-language-string('writings', $lang)))}">Weber {lang:get-language-string('writings', $lang)}</xhtml:a></xhtml:li>
            <xhtml:li><xhtml:a href="{core:join-path-elements(($baseHref, $lang, $startID, lang:get-language-string('works', $lang)))}">Weber {lang:get-language-string('works', $lang)}</xhtml:a></xhtml:li>
            <xhtml:li><xhtml:a href="{core:join-path-elements(($baseHref, $lang, lang:get-language-string('indices', $lang)))}">{lang:get-language-string('indices', $lang)}</xhtml:a></xhtml:li>
        </xhtml:ul>
    </xhtml:div>
};

(:~
 : This function acts as a template to be used on the pages index.xql and error.xql
 :
 : @author Peter Stadler
 : @param $lang the language switch (de|en)
 : @return html:div 
 :)
 
declare function xho:printProjectLinks($lang as xs:string) as element(xhtml:div) {
    let $baseHref := config:get-option('baseHref')
    return
    <xhtml:div id="project">
        <xhtml:h1>{lang:get-language-string('aboutTheProject', $lang)}</xhtml:h1>
        <xhtml:ul>
            <xhtml:li><xhtml:a href="{core:join-path-elements(($baseHref, $lang, lang:get-language-string('indices',$lang), lang:get-language-string('news',$lang)))}">{lang:get-language-string('news', $lang)}</xhtml:a></xhtml:li>
            <xhtml:li><xhtml:a href="{core:join-path-elements(($baseHref, $lang, replace(lang:get-language-string('editorialGuidelines',$lang), '\s', '_')))}">{lang:get-language-string('editorialGuidelines', $lang)}</xhtml:a></xhtml:li>
            <xhtml:li><xhtml:a href="{core:join-path-elements(($baseHref, $lang, replace(lang:get-language-string('projectDescription',$lang), '\s', '_')))}">{lang:get-language-string('projectDescription', $lang)}</xhtml:a></xhtml:li>
            <xhtml:li><xhtml:a href="{core:join-path-elements(($baseHref, $lang, lang:get-language-string('volContents',$lang)))}">{lang:get-language-string('volContents', $lang)}</xhtml:a></xhtml:li>
            <xhtml:li><xhtml:a href="{core:join-path-elements(($baseHref, $lang, lang:get-language-string('bibliography',$lang)))}">{lang:get-language-string('bibliography', $lang)}</xhtml:a></xhtml:li>
            <xhtml:li><xhtml:a href="{core:join-path-elements(($baseHref, $lang, lang:get-language-string('contact',$lang)))}">{lang:get-language-string('contact', $lang)}</xhtml:a></xhtml:li>
        </xhtml:ul>
    </xhtml:div>
};

(:~
 : This function acts as a template to be used on the pages index.xql and error.xql
 :
 : @author Peter Stadler
 : @param $lang the language switch (de|en)
 : @return html:div 
 :)
 
declare function xho:printDevelopmentLinks($lang as xs:string) as element(xhtml:div) {
    let $baseHref := config:get-option('baseHref')
    return
    element xhtml:div {
        attribute id {'developmentTools'},
        element xhtml:h1 {lang:get-language-string('development', $lang)},
        element xhtml:ul {
            element xhtml:li {
                element xhtml:a {
                    attribute href {core:join-path-elements(($baseHref, $lang, lang:get-language-string('tools', $lang)))},
                    'Tools'
                }
            }
        }
    }
};
