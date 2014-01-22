xquery version "1.0" encoding "UTF-8";
declare default element namespace "http://www.w3.org/1999/xhtml"; 
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace util="http://exist-db.org/xquery/util";
(:declare namespace cache="http://exist-db.org/xquery/cache";:)
(:declare namespace datetime="http://exist-db.org/xquery/datetime";:)
import module namespace wega="http://xquery.weber-gesamtausgabe.de/modules/wega" at "wega.xqm";
import module namespace xho="http://xquery.weber-gesamtausgabe.de/modules/xho" at "xho.xqm";
(:import module namespace functx="http://www.functx.com";:)
import module namespace dev="http://xquery.weber-gesamtausgabe.de/modules/dev" at "dev.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";

declare option exist:serialize "method=xhtml media-type=text/html indent=no omit-xml-declaration=yes encoding=utf-8 doctype-public=-//W3C//DTD&#160;XHTML&#160;1.0&#160;Strict//EN doctype-system=http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd";


declare function local:createTabsUL($containerID as xs:string, $lang as xs:string) as element() {
    let $menu := ('common', 'persons', 'letters', 'writings', 'diaries', 'works', 'news')
    let $listItems := 
        for $i at $count in $menu
        let $title := wega:getLanguageString($i, $lang)
        let $url := concat('functions/getAjax.xql?function=showToolsTab&amp;docType=',$i)
        return (
            element li {
                element a {
                    attribute href {$url},
                    attribute title {$title},
                    attribute rel {$containerID},
                    if($count eq 1)
                        then attribute class {'selected'}
                        else (),
                    $title
                }
            }
        )
    return 
    <ul id="toolsTabs" class="shadetabs">
        {$listItems}
    </ul>
};

let $lang    := request:get-parameter('lang','de')
let $containerID := config:get-option('containerID')
let $metaData := 
    <wega:metaData>
        <title>{wega:getLanguageString('tools', $lang)}</title>
        {xho:collectCommonMetaData(())/*}
        <meta name="DC.creator" content="Peter Stadler"/>
        <meta name="DC.language" content="de" scheme="DCTERMS.RFC3066"/>
    </wega:metaData>
return

<html>
    {xho:createHtmlHead('listView.css', 'development.js', $metaData, (), ())}
    <body>
        <div id="container">
            {xho:createHeadContainer($lang)}
            <div id="main">
                <div id="contentLeft">
                    <div>
                        <h2>{wega:getLanguageString('tools', $lang)}</h2>
                        <ul>
                            <li><span onclick="javascript:generateID('{$lang}')" class="internalLink">Generiere ID</span></li>
                            <li><span onclick="javascript:validateIDs('{$lang}')" class="internalLink">Überprüfe IDs</span></li>
                            <li><span onclick="javascript:validatePNDs('{$lang}')" class="internalLink">Überprüfe PNDs</span></li>
                            <li><span onclick="javascript:validatePaths('{$lang}')" class="internalLink">Überprüfe Pfade</span></li>
                        </ul>
                    </div>
                </div>
                <div id="contentRight">
                    {local:createTabsUL($containerID, $lang)}
                    <div id="{$containerID}"><!-- (: wird durch AJAXTabs gefüllt :) --></div>
                    <script type="text/javascript">
                        var toolsFrame=new ddajaxtabs("toolsTabs", "{$containerID}")
                        toolsFrame.setpersist(true)
                        toolsFrame.setselectedClassTarget("link")
                        toolsFrame.init()
                    </script>
                </div>
            </div>
            {xho:createFooter()}         
        </div>
    </body>
</html>