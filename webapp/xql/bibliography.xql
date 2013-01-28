xquery version "1.0" encoding "UTF-8";
declare default element namespace "http://www.w3.org/1999/xhtml"; 
declare default collation "?lang=de;strength=primary";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace util="http://exist-db.org/xquery/util";
import module namespace wega="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/wega" at "xmldb:exist:///db/webapp/xql/modules/wega.xqm";
import module namespace xho="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/xho" at "xmldb:exist:///db/webapp/xql/modules/xho.xqm";
import module namespace facets="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/facets" at "xmldb:exist:///db/webapp/xql/modules/facets.xqm";

declare option exist:serialize "method=xhtml media-type=text/html indent=no omit-xml-declaration=yes encoding=utf-8 doctype-public=-//W3C//DTD&#160;XHTML&#160;1.0&#160;Strict//EN doctype-system=http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"; 

declare function local:formatBibliography($biblItems as element()*, $lang as xs:string) as element()* {
    let $xslParams := <parameters><param name="lang" value="{$lang}"/></parameters>
    return 
    for $i in $biblItems
    return 
    element li {
        transform:transform($i, doc('/db/webapp/xsl/var.xsl'), $xslParams)
    }
};

let $lang := request:get-parameter('lang','de')
let $bibliography := doc('/db/var/A0700xx/A070006.xml')//tei:TEI
let $pageTitle := wega:getLanguageString('bibliography',$lang)
let $domLoaded := 
    <domLoaded xmlns="">
        <function>
            <name>buildFilterMenu</name>
        </function>
        <function>
            <name>showEntries</name>
        </function>
    </domLoaded>
return 

<html>
    {xho:createHtmlHead('listView.css', ('list_functions.js', 'infinite_scroll.js'), $pageTitle, (), ())}
    <body>
        <div id="container">
            {xho:createHeadContainer($lang)}
            <div id="main">
                <div id="contentLeft">
                    <!-- (: Wird onload gefüllt :) -->
                </div>
                <div id="contentRight">
                    <div id="ajaxMainFrame">
                        <ul>{local:formatBibliography($bibliography//tei:bibl, $lang) }</ul>
                    </div>
                </div>
            </div>
            {xho:createFooter()}
        </div>
    </body>
</html>
