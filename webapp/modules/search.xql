xquery version "1.0" encoding "UTF-8";
declare default element namespace "http://www.w3.org/1999/xhtml"; 
declare default collation "?lang=de;strength=primary";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace session = "http://exist-db.org/xquery/session";
import module namespace wega="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/wega" at "wega.xqm";
import module namespace xho="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/xho" at "xho.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";

declare option exist:serialize "method=xhtml media-type=text/html indent=no omit-xml-declaration=yes encoding=utf-8 doctype-public=-//W3C//DTD&#160;XHTML&#160;1.0&#160;Strict//EN doctype-system=http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd";

let $lang      := request:get-parameter('lang','de')
let $sOpts     := wega:getSetSearchOptions('0')
(:let $lastSearch := session:get-attribute('historyStack')
let $sessionVar := session:set-attribute('historyStack',wega:pop($lastSearch)):)
let $metaData  := 
    <wega:metaData>
        <title>{wega:getLanguageString('search',$lang)}</title>
        {xho:collectCommonMetaData(())/*}
        <meta name="DC.creator" content="Christian Epp"/>
        <meta name="DC.language" content="{$lang}" scheme="DCTERMS.RFC3066"/>
    </wega:metaData>
let $domLoaded := 
    <domLoaded xmlns="">
        <function>
            <name>$('input_0').focus</name>
        </function>
        <function>
            <name>selectSearchOptionBoxes</name>
            <param>{$sOpts}</param>
        </function>
        <function>
            <name>initializeRSH</name>
        </function>
    </domLoaded>
let $additionalJScripts :=
    <additionalJScripts xmlns="">
        <function>
            <name>create_RSH</name>
        </function>
    </additionalJScripts>
return 

<html>
    {xho:createHtmlHead('search.css', ('rsh_functions.js', 'rsh.js','search_functions.js', 'infinite_scroll.js'), $metaData, $domLoaded, $additionalJScripts)}
    <body>
        <div id="container">
            {xho:createHeadContainer($lang)}
            <div id="main">
                <form method="get" action="javascript:requestSearchResults('{$lang}',0)" id="searchForm">
                    <div id="searchFields">
                        <input id="input_0" type="text" name="input_0" maxlength="2048" title="{wega:getLanguageString('WeGA-Search',$lang)}" style="width:400px" class="search-input"/><!-- size="55"  -->
                        <span onclick="requestSelectRow('{$lang}','1','');this.toggle();$('input_0').toggle()" style="vertical-align:middle;text-align:right" class="side-orders">{wega:getLanguageString('advancedSearch',$lang)}</span>
                    </div>
                    <div>
                        <input type="submit" class="search-button" title="{wega:getLanguageString('WeGA-Search',$lang)}" value="{wega:getLanguageString('WeGA-Search',$lang)}"/>
                    </div>
                    <div id="searchOptions">
                       <input type="checkbox" name="auswahl" value="persons" /><label>{wega:getLanguageString('persons',$lang)}</label>
                       <input type="checkbox" name="auswahl" value="letters" /><label>{wega:getLanguageString('letters',$lang)}</label>
                       <input type="checkbox" name="auswahl" value="diaries" /><label>{wega:getLanguageString('diaries',$lang)}</label>
                       <input type="checkbox" name="auswahl" value="writings"/><label>{wega:getLanguageString('writings',$lang)}</label>
                       <input type="checkbox" name="auswahl" value="works"   /><label>{wega:getLanguageString('works',$lang)}</label>
                       <input type="checkbox" name="auswahl" value="news"    /><label>{wega:getLanguageString('news',$lang)}</label>
                       <input type="checkbox" name="auswahl" value="biblio"  /><label>{wega:getLanguageString('bibliography',$lang)}</label>
                    </div>
                    
                    <div id="overlaySpinningWheelContainer" style="display: none;"><img src="../pix/ajax-loader.gif" alt="spinning-wheel" /></div>
                    
                    <div id="numberOfSearchResults" style="display:block">
                        <span id="numberOfSearchResultsCount" ></span>
                        <span class="numberOfSearchResultsText" id="oneSearchResult"   style="display:none">{wega:getLanguageString('result',  $lang)}</span>
                        <span class="numberOfSearchResultsText" id="manySearchResults" style="display:none">{wega:getLanguageString('results', $lang)}</span>
                    </div>
                    
                    <div class="searchResults" id="searchResultField" style="width:100%">
                        <div id="{config:get-option('containerID')}" style="float:left;width:98%;margin-left:2%">
                        <!-- Wird nach dem Suchen gefüllt -->
                        </div>
                    </div>
                    
                </form>
            </div>
            {xho:createFooter()}
        </div>
        <!--<div id="overlay" style="display:none;"></div>-->
    </body>
</html>