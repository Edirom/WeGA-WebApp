xquery version "1.0" encoding "UTF-8";

(:~
: WeGA XHTML XQuery-Modul
:
: @author Peter Stadler 
: @version 1.0
:)

module namespace xho="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/xho";
declare default collation "?lang=de;strength=primary";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace session = "http://exist-db.org/xquery/session";
declare namespace xmldb = "http://exist-db.org/xquery/xmldb";
declare namespace cache = "http://exist-db.org/xquery/cache";
import module namespace functx="http://www.functx.com" at "xmldb:exist:///db/webapp/xql/modules/functx.xqm";
import module namespace wega="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/wega" at "xmldb:exist:///db/webapp/xql/modules/wega.xqm";
import module namespace facets="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/facets" at "xmldb:exist:///db/webapp/xql/modules/facets.xqm";

declare option exist:serialize "method=xhtml media-type=text/html indent=no omit-xml-declaration=yes encoding=utf-8";

(:~
 : Creates HTML head container
 :
 : @author Peter Stadler
 : @param $lang the language switch (de|en)
 : @return XHTML element
 :)

declare function xho:createHeadContainer($lang as xs:string) as element()* {
    let $html_pixDir := wega:getOption('html_pixDir')
    let $baseHref := wega:getOption('baseHref')
    let $uriTokens := tokenize(xmldb:decode-uri(request:get-uri()), '/')
    let $search := string-join(($baseHref, $lang, wega:getLanguageString('search', $lang)), '/')
    let $index := string-join(($baseHref, $lang, wega:getLanguageString('index', $lang)), '/')
    let $impressum := string-join(($baseHref, $lang, wega:getLanguageString('about', $lang)), '/')
    let $help := string-join(($baseHref, $lang, wega:getLanguageString('help', $lang)), '/')
    let $switchLanguage := 
        for $i in $uriTokens[string-length(.) gt 2]
        return
        if (matches($i, 'A\d{6}'))
            then $i
            else if($lang eq 'en') 
                then replace(wega:translateLanguageString(replace($i, '_', ' '), $lang, 'de'), '\s', '_') (: Ersetzen von Leerzeichen durch Unterstriche in der URL :)
                else replace(wega:translateLanguageString(replace($i, '_', ' '), $lang, 'en'), '\s', '_')
    let $switchLanguage := if($lang eq 'en')
        then <a href="{string-join(($baseHref, 'de', $switchLanguage), '/')}" title="Diese Seite auf Deutsch"><img src="{string-join(($baseHref, $html_pixDir, 'de.gif'), '/')}" alt="germanFlag" width="20" height="12"/></a>
        else <a href="{string-join(($baseHref, 'en', $switchLanguage), '/')}" title="This page in english"><img src="{string-join(($baseHref, $html_pixDir, 'gb.gif'), '/')}" alt="englishFlag" width="20" height="12"/></a>
    return (
    element div {
        attribute id {"headContainer"},
        if(wega:getOption('environment') eq 'development') then attribute class {'dev'}
        else if(wega:getOption('environment') eq 'release') then attribute class {'rel'}
        else (),
        <h1><a href="{$index}"><span class="hiddenLink">Carl Maria von Weber Gesamtausgabe</span></a></h1>,
        <ul id="topMenu">
            <li><a href="{$search}">{wega:getLanguageString('search',$lang)}</a></li>
            <li><a href="{$index}">{wega:getLanguageString('home',$lang)}</a></li>
            <li><a href="{$impressum}">{wega:getLanguageString('about',$lang)}</a></li>
            <li><a href="{$help}">{wega:getLanguageString('help',$lang)}</a></li>
            <li>{$switchLanguage}</li>
        </ul>
    },
    <noscript><p class="noscript">{wega:getLanguageString('noscript', $lang)}</p></noscript>,
    <p id="IE6" class="noscript" style="display:none;">{wega:getLanguageString('oldBrowser', $lang)}</p>,
    <script type="text/javascript">if(navigator.userAgent.indexOf('MSIE 6') != -1) $('IE6').show()</script>
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

declare function xho:createFooter($lang as xs:string, $docPath as xs:string) as element() {
    let $docHash := util:hash($docPath, 'md5')
(:    let $log := util:log-system-out($docPath):)
    let $entry := doc(wega:getOption('svnChangeHistoryFile'))//id(concat('_',$docHash))
    let $author := if(exists($entry/@author))
        then wega:dictionaryLookup(data($entry/@author), xs:ID('svnUsers'))
        else ()
    let $date := if(exists($entry/@dateTime))
        then datetime:date-from-dateTime($entry/@dateTime)
        else ()
    let $rev := data($entry/@rev)
    let $dateFormat := if($lang eq 'en')
        then '%B %d, %Y'
        else '%d. %B %Y'
    let $encryptedBugEmail := wega:encryptString(wega:getOption('bugEmail'), ())
    return if(exists($author) and exists($date)) 
        then
            <div id="footer">
                  <p>{wega:getLanguageString('lastChangeDate',(wega:strftime($dateFormat, $date, $lang),$author),$lang)}</p>
                  {if($lang eq 'en') then 
                  <p>If you've spotted some error or inaccurateness please do not hesitate to inform us via 
                    <span onclick="javascript:decEma('{$encryptedBugEmail}')" class="ema">{wega:obfuscateEmail(wega:getOption('bugEmail'))}</span>
                  </p>
                  else 
                  <p>Wenn Ihnen auf dieser Seite ein Fehler oder eine Ungenauigkeit aufgefallen ist, so bitten wir um eine kurze Nachricht an
                    <span onclick="javascript:decEma('{$encryptedBugEmail}')" class="ema">{wega:obfuscateEmail(wega:getOption('bugEmail'))}</span>
                  </p>
                  }
                    {xho:createCommonFooter()}
            </div>
        else xho:createFooter()
};


(:~
 : Creates HTML footer without parameters
 :
 : @author Peter Stadler
 : @return XHTML element
 :)

declare function xho:createFooter() as element() {
    <div id="footer">{xho:createCommonFooter()}</div>
};

(:~
 : Creates HTML footer with common content - is called by "xho:createFooter()"
 :
 : @author Peter Stadler
 : @return XHTML element 
 :)

declare function xho:createCommonFooter() as item()* {
    let $html_pixDir := wega:getOption('html_pixDir')
    let $baseHref := wega:getOption('baseHref')
    let $piwikTrackingCode := 
        if(wega:getOption('environment') eq 'production') then (
            <!-- Piwik -->,
            <script type="text/javascript">
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
            </script>,
            <!-- End Piwik Code -->,
            <!-- Piwik Image Tracker -->,
            <noscript><p><img src="{concat($baseHref, '/piwik/piwik.php?idsite=1&amp;rec=1')}" style="border:0" alt="" /></p></noscript>,
            <!-- End Piwik -->
        )
        else ()
    return (
    <div id="supportBadges">
        <a href="http://validator.w3.org/check?uri=referer"><img src="http://www.w3.org/Icons/valid-xhtml11" alt="Valid XHTML 1.1" height="31" width="88" title="W3C Markup Validation Service" /></a>
        <a href="http://exist-db.org"><img src="http://exist-db.org/exist/icons/existdb-128.png" alt="powered by eXist" title="eXist-db Open Source Native XML Database" /></a>
        <a href="http://staatsbibliothek-berlin.de"><img src="{string-join(($baseHref, $html_pixDir,'stabi-logo.png'), '/')}" alt="Staatsbibliothek zu Berlin - Preußischer Kulturbesitz" title="Staatsbibliothek zu Berlin - Preußischer Kulturbesitz" /></a>
        <a href="http://www.adwmainz.de"><img src="{string-join(($baseHref, $html_pixDir,'adwMainz.png'), '/')}" alt="Akademie der Wissenschaften und der Literatur Mainz" title="Akademie der Wissenschaften und der Literatur Mainz" /></a>
        <a href="http://www.tei-c.org"><img src="http://www.tei-c.org/About/Badges/powered-by-TEI.png" alt="Powered by TEI" title="TEI: Text Encoding Initiative" /></a>
        <br/>
        <a href="http://www.uni-paderborn.de/"><img src="{string-join(($baseHref, $html_pixDir,'upb-logo.png'), '/')}" alt="Universität Paderborn" title="Universität Paderborn" /></a>
        <a href="http://www.hfm-detmold.de"><img src="{string-join(($baseHref, $html_pixDir,'hfm-logo.png'), '/')}" alt="Hochschule für Musik Detmold" title="Hochschule für Musik Detmold" /></a>
    </div>,
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

declare function xho:createHtmlHead($stylesheets as xs:string*, $jscripts as xs:string*, $metaData as item(), $domLoaded as node()?, $additionalJScripts as node()?) as element() {
    let $html_pixDir := wega:getOption('html_pixDir')
    let $commonStylesheets := ('main.css', 'tei_common.css', 'ajaxtabs.css', 'lytebox.css', 'xmlPrettyPrint.css')
    let $commonJscripts := ('text_common.js', 'ajaxtabs.js', 'prototype_min.js', 'lytebox_min.js', 'wz_tooltip/wz_tooltip_min.js')
    let $baseHref := wega:getOption('baseHref')
    return 
        <head>
            <meta content="text/html; charset=utf-8" http-equiv="Content-Type"/>
            <meta name="fragment" content="!"/> 
            <link rel="icon" href="{string-join(($baseHref, $html_pixDir, 'weber_favicon.ico'), '/')}" type="image/x-icon"/>
            {$metaData/*}
            {for $i in insert-before($stylesheets, 0, $commonStylesheets)
                return <link media="all" type="text/css" rel="stylesheet" href="{string-join(($baseHref, wega:getOption('html_cssDir'), $i), '/')}"/>
            }
            <script type="text/javascript" src="{string-join(($baseHref, 'functions/getJavaScriptOptions.xql'), '/')}"></script>
            {for $i in insert-before($jscripts, 0, $commonJscripts)
                return <script type="text/javascript" src="{string-join(($baseHref, wega:getOption('html_jsDir'), $i), '/')}"></script> 
            }
            {for $i in $additionalJScripts//function
            	return <script type="text/javascript">{wega:printJavascriptFunction($i)};</script>
            }
            <script type="text/javascript">
            document.observe('dom:loaded', function () {{
                {for $i in $domLoaded//function
                    return (wega:printJavascriptFunction($i), ';')
                }
                tt_Init();
            }});
            </script>
        </head>
};


(:~
 : Creates bread crumb tree starting at a certain document
 :
 : @author Peter Stadler
 : @param $doc the document for which the breadcrumb will be created
 : @param $lang the language switch (de|en)
 : @return XHTML (div)
 :)

declare function xho:createBreadCrumb($doc as item(), $lang as xs:string) as element() {
    let $docID := $doc/root()/*/@xml:id cast as xs:string
    let $baseHref := wega:getOption('baseHref')
    let $isDiary := starts-with($docID, 'A06') (: Diverse Sonderbehandlungen fürs Tagebuch :)
    let $authors := if($isDiary) 
        then wega:createPersonLink('A002068', $lang, 'fs')
        else for $i in $doc//tei:titleStmt//tei:author return wega:printCorrespondentName($i, $lang, 'fs')
    let $authorsCount := count($authors)
    let $docStatus := wega:getRevisionStatus($doc)
    return (
    <div id="breadCrumb">
        {for $i at $count in $authors 
        let $authorID := functx:substring-after-last($i/@href, '/')
        let $docType := 
            if($doc//tei:text[@type eq 'letter'])
                then if($authorID ne '') 
                    then <a href="{string-join(($baseHref, $lang, $authorID, wega:getLanguageString('correspondence',$lang)), '/')}">{wega:getLanguageString('correspondence',$lang)}</a>
                    else <span class="noDataFound">{wega:getLanguageString('correspondence',$lang)}</span>
                else if($doc//tei:text[@type eq 'historic-news' or @type eq 'performance-review'])
                    then if($authorID ne '') 
                        then <a href="{string-join(($baseHref, $lang, $authorID, wega:getLanguageString('writings',$lang)), '/')}">{wega:getLanguageString('writings',$lang)}</a>
                        else <span class="noDataFound">{wega:getLanguageString('writings',$lang)}</span>
                    else if($isDiary)
                        then <a href="{string-join(($baseHref, $lang, $authorID, wega:getLanguageString('diaries',$lang)), '/')}">{wega:getLanguageString('diaries',$lang)}</a>
                        else if($doc//tei:text[@type eq 'news'])
                            then <span class="noDataFound">{wega:getLanguageString('news',$lang)}</span>
                            else ()
                                        
        return ($i, xs:string(' > '), $docType, xs:string(' > '), <span class="{$docStatus}">{$docID}</span>, if($count = $authorsCount) then () else element br{})
        }
    </div>
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

declare function xho:createBreadCrumb($id as xs:string, $docType as xs:string, $lang as xs:string) as element() {
    let $author := wega:createPersonLink($id, $lang, 'fs')
    return
    <div id="breadCrumb">
        {$author, xs:string(' > '), wega:getLanguageString($docType, $lang)}
    </div>
};


(:~
 : Builds the list of works by a person
 :
 : @author Peter Stadler
 : @param $id person id for work list
 : @param $lang the language switch (de|en)
 : @return element
 :)
 
declare function xho:createWorksDocumentsUL($id as xs:string, $lang as xs:string) as element() {
    let $persName := wega:getRegName($id)
    let $baseHref := wega:getOption('baseHref')
    let $listItems :=  
        for $i in ('letters', 'writings', 'diaries', 'works')
(:            let $log := util:log-system-out($i):)
            let $coll := facets:getOrCreateColl($i, $id)
            let $title := wega:getLanguageString(concat($i,'TableTitle'), wega:printFornameSurname($persName), $lang)
            let $href := if($i eq 'letters')
                then string-join(($baseHref, $lang, $id, wega:getLanguageString('correspondence', $lang)), '/')
                else string-join(($baseHref, $lang, $id, wega:getLanguageString($i, $lang)), '/')
            let $linkText := if($i eq 'letters')
                then wega:getLanguageString('correspondence', $lang)
                else wega:getLanguageString($i, $lang)
            return if(exists($coll) and ($i ne 'diaries' or $id eq 'A002068')) (: Tagebuch nur bei Weber anzeigen :)
                then <li><a href="{$href}" title="{$title}">{$linkText}</a></li> 
                else <li><span class="noTarget">{$linkText}</span></li>
    return (
    <div id="works">
        <h2>{wega:getLanguageString('worksDocuments',$lang)}</h2>
        <ul>
            {$listItems}
            
        </ul>
    </div>
    )
};


(:~
 : Collect common html meta data for a given document
 :
 : @author Peter Stadler
 : @param $doc the document as a node
 : @return item of meta data 
 :)

declare function xho:collectCommonMetaData($doc as node()?) as item() {
    let $docPath := if(exists($doc)) then document-uri($doc/root()) else ()
    let $contributors := 
        if(exists($doc//tei:fileDesc/tei:titleStmt/(tei:author | tei:editor))) then for $i in $doc//tei:fileDesc/tei:titleStmt/(tei:author | tei:editor) return <meta name="DC.contributor" content="{$i}"/>
        else (<meta name="DC.contributor" content="Joachim Veit"/>,<meta name="DC.contributor" content="Peter Stadler"/>)
    return 
    <metaData>
        <link rel="schema.DC" href="http://purl.org/dc/elements/1.1/"/>
        <link rel="schema.DCTERMS" href="http://purl.org/dc/terms/"/>
        {if(exists($docPath)) then (
        <meta name="DC.creator" content="{wega:getLastAuthorOfDocument($docPath)}"/>,
        <meta name="DC.date" content="{wega:getLastModifyDateOfDocument($docPath)}" scheme="DCTERMS.W3CDTF"/> )
        else ()
        }
        <meta name="DC.publisher" content="Carl-Maria-von-Weber-Gesamtausgabe"/>
        <meta name="DC.type" content="Text" scheme="DCTERMS.DCMIType"/>
        <meta name="DC.format" content="text/html" scheme="DCTERMS.IMT"/>
        {$contributors}
        <meta name="DC.identifier" content="{concat(wega:getOption('baseHref'), request:get-uri())}" scheme="DCTERMS.URI"/>
    </metaData>
};

(:~
 : Creates container/placeholder for popup data
 :
 : @author Christian Epp
 : @param $lang the language switch (de|en)
 : @return element with popup-data in list-view 
 :)
 
declare function xho:createPopupContainer($lang as xs:string) as element() {
    <div id="popupMain" style="position: fixed; visibility: hidden; left:10%; top: 10%; z-index: 7538; margin: 10px; background-color:#fff">
        <div style="border: 2px solid #AAAAAA;">
            <h2>{wega:getLanguageString("restrictSelection", $lang)}</h2>
            <ul id="popupTabs" class="shadetabs">
                <li onmouseover="this.style.cursor='pointer'">
                    <a title="test" class="test"></a>
                </li>
            </ul>
            <div id="popupContent" style="text-align:left; position:relative; border: 2px solid #AAAAAA; margin: 0 5px; overflow:auto;">
            </div> 
            <h3>
                <span style="margin-right:100px" onmouseover="this.style.cursor='pointer'" >{wega:getLanguageString("cancel", $lang)}</span>
                <!--<span onmouseover="this.style.cursor='pointer'">{wega:getLanguageString("reset", $lang)} </span>-->
                <span onmouseover="this.style.cursor='pointer'" >{wega:getLanguageString("confirm", $lang)}</span>
            </h3>
        </div>
    </div>
};


(:~
 : Creates tabs for listview pages
 :
 : @author Peter Stadler
 : @param  $curDocType the active document type as given by menus.xml (e.g. "letters", "persons")
 : @param  $menuID the @xml:id of a div in menu.xml *or* a person ID (e.g. "indices", "A002068")
 : @return a xhtml element ul
 :)
 
declare function xho:createTabsUL($curDocType as xs:string, $menuID as xs:string, $lang as xs:string) as element() {
    let $baseHref := wega:getOption('baseHref')
    let $isPerson := wega:isPerson($menuID)
    let $menuNode := 
        if($isPerson) then doc(wega:getOption('menusFile'))//id('persons')
        else doc(wega:getOption('menusFile'))//id($menuID)
    let $urlPart1 := 
        if($isPerson) then string-join(($baseHref, $lang, $menuID), '/')
        else string-join(($baseHref, $lang, wega:getLanguageString($menuNode/pageName, $lang)), '/')
    let $listItems := 
        for $i in $menuNode/entry
        let $coll := facets:getOrCreateColl($i/docType, $menuID)
        let $title := wega:getLanguageString($i/displayName, $lang)
        let $url := string-join(($urlPart1, encode-for-uri($title)), '/')
(:        let $log := util:log-system-out(string-join(($i/docType, $curDocType), ' ;; ')):)
        return (
            <li>{
                if(exists($coll) and ($i/docType ne 'diaries' or $menuID eq 'A002068' or $menuID eq 'indices')) (: Tagebuch nur bei Weber anzeigen :)
                    then element a {
                        attribute href {$url},
                        attribute title {$title},
                        if($curDocType = $i/docType)
                            then attribute class {'selected'}
                            else (),
                        $title
                        }
                    else element span {
                        attribute title {$title},
                        attribute class {'notAvailable'},
                        $title
                    }
                }
            </li>
        )
    return 
    <ul id="ajaxTabs" class="shadetabs">
        {$listItems}
    </ul>
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
 
declare function xho:collectMetaData($docType as xs:string, $menuID as xs:string, $lang as xs:string) as item() {
    let $menuNode := 
        if(wega:isPerson($menuID)) then doc(wega:getOption('menusFile'))//id('persons')/entry[./docType eq $docType]
        else doc(wega:getOption('menusFile'))//id($menuID)/entry[./docType eq $docType]
    let $persName := wega:printFornameSurname(wega:getRegName($menuID))
    let $pageDescription := 
        if(wega:isPerson($menuID)) then wega:getLanguageString($menuNode/string(@metaDesc), $persName, $lang)
        else wega:getLanguageString($menuNode/string(@metaDesc), $lang)
    let $pageTitle := 
        if(wega:isPerson($menuID)) then wega:getLanguageString($menuNode/string(@metaTitle), $persName, $lang)
        else wega:getLanguageString($menuNode/string(@metaTitle), $lang)
    let $commonMetaData := xho:collectCommonMetaData(())
    let $subject := wega:getLanguageString($menuNode/displayName/text(), $lang)
    return 
        <metaData>
            <title>{$pageTitle}</title>
            {$commonMetaData/*}
            <meta name="DC.title" content="{$pageTitle}"/>
            <meta name="description" content="{$pageDescription}" lang="{$lang}"/>
            <meta name="DC.creator" content="Peter Stadler"/>
            <meta name="DC.description" content="{$pageDescription}"/>
            <meta name="DC.subject" content="{$subject}"/>
            <meta name="DC.language" content="de" scheme="DCTERMS.RFC3066"/>
        </metaData>
};

(:~
 : This function acts as a template to be used on the pages index.xql and error.xql
 :
 : @author Peter Stadler
 : @param $startID the ID fpr the reference
 : @param $lang the language switch (de|en)
 : @return html:div 
 :)
 
declare function xho:printEditionLinks($startID as xs:string, $lang as xs:string) as element() {
    let $baseHref := wega:getOption('baseHref')
    return
    <div id="edition">
        <h1>{wega:getLanguageString('digitalEdition', $lang)}</h1>
        <ul>
            <li><a href="{string-join(($baseHref, $lang, $startID), '/')}">Weber Person</a></li>
            <li><a href="{string-join(($baseHref, $lang, $startID, wega:getLanguageString('correspondence', $lang)), '/')}">Weber {wega:getLanguageString('correspondence', $lang)}</a></li>
            <li><a href="{string-join(($baseHref, $lang, $startID, wega:getLanguageString('diaries', $lang)), '/')}">Weber {wega:getLanguageString('diaries', $lang)}</a></li>
            <li><a href="{string-join(($baseHref, $lang, $startID, wega:getLanguageString('writings', $lang)), '/')}">Weber {wega:getLanguageString('writings', $lang)}</a></li>
            <li><a href="{string-join(($baseHref, $lang, $startID, wega:getLanguageString('works', $lang)), '/')}">Weber {wega:getLanguageString('works', $lang)}</a></li>
            <li><a href="{string-join(($baseHref, $lang, wega:getLanguageString('indices', $lang)), '/')}">{wega:getLanguageString('indices', $lang)}</a></li>
        </ul>
    </div>
};

(:~
 : This function acts as a template to be used on the pages index.xql and error.xql
 :
 : @author Peter Stadler
 : @param $lang the language switch (de|en)
 : @return html:div 
 :)
 
declare function xho:printProjectLinks($lang as xs:string) as element() {
    let $baseHref := wega:getOption('baseHref')
    return
    <div id="project">
        <h1>{wega:getLanguageString('aboutTheProject', $lang)}</h1>
        <ul>
            <li><a href="{string-join(($baseHref, $lang, wega:getLanguageString('indices',$lang), wega:getLanguageString('news',$lang)),'/')}">{wega:getLanguageString('news', $lang)}</a></li>
            <li><a href="{string-join(($baseHref, $lang, replace(wega:getLanguageString('editorialGuidelines',$lang), '\s', '_')),'/')}">{wega:getLanguageString('editorialGuidelines', $lang)}</a></li>
            <li><a href="{string-join(($baseHref, $lang, replace(wega:getLanguageString('projectDescription',$lang), '\s', '_')), '/')}">{wega:getLanguageString('projectDescription', $lang)}</a></li>
            <li><a href="{string-join(($baseHref, $lang, wega:getLanguageString('publications',$lang)), '/')}">{wega:getLanguageString('publications', $lang)}</a></li>
            <li><a href="{string-join(($baseHref, $lang, wega:getLanguageString('bibliography',$lang)), '/')}">{wega:getLanguageString('bibliography', $lang)}</a></li>
            <li><a href="{string-join(($baseHref, $lang, wega:getLanguageString('contact',$lang)), '/')}">{wega:getLanguageString('contact', $lang)}</a></li>
        </ul>
    </div>
};

(:~
 : This function acts as a template to be used on the pages index.xql and error.xql
 :
 : @author Peter Stadler
 : @param $lang the language switch (de|en)
 : @return html:div 
 :)
 
declare function xho:printDevelopmentLinks($lang) {
    let $baseHref := wega:getOption('baseHref')
    return
    element div {
        attribute id {'developmentTools'},
        element h1 {wega:getLanguageString('development', $lang)},
        element ul {
            element li {
                element a {
                    attribute href {string-join(($baseHref, $lang, wega:getLanguageString('tools', $lang)), '/')},
                    'Tools'
                }
            }
        }
    }
};