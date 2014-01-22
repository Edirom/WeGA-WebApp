xquery version "1.0" encoding "UTF-8";
declare default element namespace "http://www.w3.org/1999/xhtml"; 
declare default collation "?lang=de;strength=primary";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace util="http://exist-db.org/xquery/util";
import module namespace wega="http://xquery.weber-gesamtausgabe.de/modules/wega" at "wega.xqm";
import module namespace xho="http://xquery.weber-gesamtausgabe.de/modules/xho" at "xho.xqm";
import module namespace facets="http://xquery.weber-gesamtausgabe.de/modules/facets" at "facets.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace functx="http://www.functx.com";

declare option exist:serialize "method=xhtml media-type=text/html indent=no omit-xml-declaration=yes encoding=utf-8 doctype-public=-//W3C//DTD&#160;XHTML&#160;1.0&#160;Strict//EN doctype-system=http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"; 

declare function local:createTabsUL($pubType as xs:string, $lang as xs:string) as element() {
    let $baseHref := config:get-option('baseHref')
    let $menu := ('weberStudies', 'musicVolumes', 'papers', 'talks')
    let $listItems := 
        for $i in $menu
        (:let $coll := if($i eq 'correspondence')
            then core:getOrCreateColl('letters', $id)
            else core:getOrCreateColl($i, $id):)
        let $title := wega:getLanguageString($i, $lang)
        let $url := string-join(($baseHref, $lang, wega:getLanguageString('publications', $lang), encode-for-uri($title)), '/')
        return (
            <li>{
                if(true()) (: Abfrage nach $coll:)
                    then element a {
                        attribute href {$url},
                        attribute title {$title},
                        if($i eq $pubType)
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

declare function local:collectMetaData($pubType as xs:string, $lang as xs:string) as item() {
    let $pageTitle := concat(wega:getLanguageString($pubType, $lang), ' – ', wega:getLanguageString('WeGAPublications', $lang))
    let $pageDescription := wega:getLanguageString(concat($pubType, 'PublicationMetaDescription'), $lang)
    let $commonMetaData := xho:collectCommonMetaData(())
    let $subject := string-join(('Carl Maria von Weber', wega:getLanguageString('publications', $lang)), '; ')
    return 
    <metaData>
        <title>{$pageTitle}</title>
        {$commonMetaData/*}
        <meta name="DC.title" content="{$pageTitle}"/>
        <meta name="description" content="{$pageDescription}" lang="{$lang}"/>
        <meta name="DC.description" content="{$pageDescription}"/>
        <meta name="DC.creator" content="Peter Stadler"/>
        <meta name="DC.subject" content="{$subject}"/>
        <meta name="DC.language" content="de" scheme="DCTERMS.RFC3066"/>
    </metaData>
};

let $lang := request:get-parameter('lang','de')
let $pubType := request:get-parameter('pubType','weberStudies')
(:let $log := util:log-system-out($pubType):)

return 

<html>
    {xho:createHtmlHead('listView.css', ('list_functions.js', 'infinite_scroll.js'), local:collectMetaData($pubType, $lang), (), ())}
    <body onload="scrollToTop();">
        <div id="container">
            {xho:createHeadContainer($lang)}
            <div id="main">
                <div id="contentLeft">
                    <!-- (: Wird onload gefüllt :) -->
                </div>
                <div id="contentRight">
                    {local:createTabsUL($pubType, $lang)}
                    <div id="ajaxMainFrame">
                        <!-- (: Wird onload gefüllt :) -->
                    </div>
                </div>
            </div>
            {xho:createFooter()}
        </div>
        <div id="popupMain" style="position: fixed; visibility: hidden; left:10%; top: 10%; z-index: 7538; margin: 10px; background-color:#fff">
            <div style="border: 2px solid #AAAAAA;">
                <h2>Auswahl einschränken</h2>
                <ul id="popupTabs" class="shadetabs">
                    <li onmouseover="this.style.cursor='pointer'">
                        <a title="test" class="test"></a>
                    </li>
                </ul>
                <div id="popupContent" style="text-align:left; position:relative; border: 2px solid #AAAAAA; margin: 0 5px; overflow:auto;">
                </div> 
                <h3>
                    <span style="margin-right:100px" onmouseover="this.style.cursor='pointer'" >Abbrechen</span>
                    <!--<span onmouseover="this.style.cursor='pointer'">Zurücksetzen </span>-->
                    <span onmouseover="this.style.cursor='pointer'" >Abschicken</span>
                </h3>
            </div>
        </div>
        <div id="overlay" style="display:none;"></div>
    </body>
</html>