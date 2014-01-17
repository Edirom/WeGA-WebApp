xquery version "1.0" encoding "UTF-8";
declare default element namespace "http://www.w3.org/1999/xhtml"; 
declare default collation "?lang=de;strength=primary";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace util="http://exist-db.org/xquery/util";
import module namespace wega="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/wega" at "wega.xqm";
import module namespace xho="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/xho" at "xho.xqm";
import module namespace facets="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/facets" at "facets.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace functx="http://www.functx.com";

declare option exist:serialize "method=xhtml media-type=text/html indent=no omit-xml-declaration=yes encoding=utf-8 doctype-public=-//W3C//DTD&#160;XHTML&#160;1.0&#160;Strict//EN doctype-system=http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"; 

let $lang := request:get-parameter('lang','de')
let $id := request:get-parameter('id','A002068')
let $docType := request:get-parameter('docType','letters')
let $sessionFilterName := facets:getFilterName($docType)
let $sessionCollName := facets:getCollName($docType, false())
let $clearFilter := session:remove-attribute($sessionFilterName)
let $coll := core:getOrCreateColl($docType, $id, true())
let $createSessionColl := session:set-attribute($sessionCollName, $coll)
(:let $log := util:log-system-out($docType):)
(:let $log := util:log-system-out(count($coll)):)
let $domLoaded := 
    <domLoaded xmlns="">
        <function>
            <name>createListViewMenu</name>
            <param>{$docType}</param>
            <param>{$id}</param>
            <param>{count($coll)}</param>
            <param>{$lang}</param>
            <param>{''}</param>
        </function>
        <function>
            <name>showEntries</name>
            <param type="obj">undefined</param>
            <param>1</param>
            <param>{count($coll)}</param>
            <param>{$lang}</param>
            <param>{$sessionCollName}</param>
        </function>
        <function>
            <name>scrollToTop</name>
        </function>
        <!--<function>
            <name>initializeRSH</name>
        </function>-->
    </domLoaded>
let $additionalJScripts := ()
    (:<additionalJScripts xmlns="">
        <function>
            <name>create_RSH</name>
        </function>
    </additionalJScripts>:)

return 

<html>
    {xho:createHtmlHead('listView.css', ('list_functions.js', 'infinite_scroll.js'(:, 'rsh_functions.js', 'rsh.js':)), xho:collectMetaData($docType, $id, $lang), $domLoaded, $additionalJScripts)}
    <body>
        <div id="container">
            {xho:createHeadContainer($lang)}
            <div id="main">
                {if(config:is-person($id))
                then if($docType eq 'letters') 
                    then xho:createBreadCrumb($id, 'correspondence', $lang)
                    else xho:createBreadCrumb($id, $docType, $lang)
                else ()
                }
                <div id="contentLeft">
                    <div id="chronoAlphaList">
                        <!-- (: Wird onload gefüllt :) -->
                    </div>
                    <div id="facetsFromFacetFile">
                        <!-- (: Wird onload gefüllt :) -->
                    </div>
                </div>
                <div id="contentRight">
                    {xho:createTabsUL($docType, $id, $lang)}
                    <div id="ajaxMainFrame">
                        <!-- (: Wird onload gefüllt :) -->
                    </div>
                </div>
            </div>
            {(:xho:createFooter:)()}
        </div>
        {xho:createPopupContainer($lang)}
        <div id="overlay" style="display:none;"></div>
    </body>
</html>
