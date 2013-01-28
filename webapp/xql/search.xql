xquery version "1.0" encoding "UTF-8";
declare default element namespace "http://www.w3.org/1999/xhtml"; 
declare default collation "?lang=de;strength=primary";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace session = "http://exist-db.org/xquery/session";
import module namespace wega="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/wega" at "xmldb:exist:///db/webapp/xql/modules/wega.xqm";
import module namespace xho="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/xho" at "xmldb:exist:///db/webapp/xql/modules/xho.xqm";

declare option exist:serialize "method=xhtml media-type=text/html indent=no omit-xml-declaration=yes encoding=utf-8 doctype-public=-//W3C//DTD&#160;XHTML&#160;1.0&#160;Strict//EN doctype-system=http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd";

let $lang      := request:get-parameter('lang','de')
let $sOpts     := wega:getSetSearchOptions('0')
(:let $lastSearch := session:get-attribute('historyStack')
let $sessionVar := session:set-attribute('historyStack',wega:pop($lastSearch)):)
let $metaData  := 
    <metaData>
        <title>{wega:getLanguageString('search',$lang)}</title>
        {xho:collectCommonMetaData(())/*}
        <meta name="DC.creator" content="Christian Epp"/>
        <meta name="DC.language" content="{$lang}" scheme="DCTERMS.RFC3066"/>
    </metaData>
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
return (:'rsh_functions.js', 'rsh.js', 'autocomplete.js' <function>
            <name>initializeAutoComplete</name>
            <param>{$lang}</param>
        </function>:)
<html>
    {xho:createHtmlHead('search.css', ('rsh_functions.js', 'rsh.js','search_functions.js', 'infinite_scroll.js'), $metaData, $domLoaded, $additionalJScripts)}
    <body>
        <div id="container">
            {xho:createHeadContainer($lang)}
            <div id="main">
                <form method="get" action="javascript:requestSearchResults('{$lang}',0)" id="searchForm">
                    <!--<div style="text-align:center">
                        <table style="width:90%;text-align:center">
                            <tbody>
                                <tr style="width:60%;text-align:center">
                                    <td>
                                        <div  id="searchFields">
                                        <input id="input_0" type="text" name="input_0" maxlength="2048" title="{wega:getLanguageString('WeGA-Search',$lang)}" style="width:400px" class="search-input"/><!- - size="55"  - ->
                                        </div>
                                    </td>
                                    <td style="padding:0 10px">
                                        <input type="submit" class="search-button" title="{wega:getLanguageString('WeGA-Search',$lang)}" value="{wega:getLanguageString('WeGA-Search',$lang)}"/>
                                    </td>
                                    <td>
                                        <span onclick="requestSelectRow('{$lang}','1','');this.toggle();$('input_0').toggle()" style="vertical-align:middle;text-align:right" class="side-orders">{wega:getLanguageString('advancedSearch',$lang)}</span>
                                    </td>
                                </tr>
                                <tr>
                                    <td>
                                        <div style="border: 2px solid #aaaaaa;margin:-13px 0px;display:none;padding:0 10px" id="autoComplete">
                                        </div>
                                    </td>
                                    <td>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                    -->
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
                        <!--<div id="contentLeft">
                            <div id="numberOfSearchResults" style="display:none">
                                <span id="numberOfSearchResultsCount" style="float:left;"></span>
                                <div class="numberOfSearchResultsText" id="oneSearchResult"   style="display:none">{wega:getLanguageString('result',  $lang)}</div>
                                <div class="numberOfSearchResultsText" id="manySearchResults" style="display:none">{wega:getLanguageString('results', $lang)}</div>
                            </div>
                            
                            <div style="border: 2px solid #AAA;">
                                <h2>Dokumenttypen</h2>
                                <ul id="searchOptions">
                                   <li><input type="checkbox" name="auswahl" value="persons" /><label>{wega:getLanguageString('persons',$lang)}</label></li>
                                   <li><input type="checkbox" name="auswahl" value="letters" /><label>{wega:getLanguageString('letters',$lang)}</label></li>
                                   <li><input type="checkbox" name="auswahl" value="diaries" /><label>{wega:getLanguageString('diaries',$lang)}</label></li>
                                   <li><input type="checkbox" name="auswahl" value="writings"/><label>{wega:getLanguageString('writings',$lang)}</label></li>
                                   <li><input type="checkbox" name="auswahl" value="works"   /><label>{wega:getLanguageString('works',$lang)}</label></li>
                                   <li><input type="checkbox" name="auswahl" value="news"    /><label>{wega:getLanguageString('news',$lang)}</label></li>
                                   <li><input type="checkbox" name="auswahl" value="biblio"  /><label>{wega:getLanguageString('bibliography',$lang)}</label></li>
                                </ul>
                            </div>
                            <div style="border: 2px solid #AAA;display:none">
                                <h2>Personen</h2>
                                <ul><li>Personen</li><li>Briefe</li><li>Schriften</li><li>Tagebücher</li><li>Werke</li><li>Aktuelles</li></ul>
                                <h2>Orte</h2>
                                <ul><li>Personen</li><li>Briefe</li><li>Schriften</li><li>Tagebücher</li><li>Aktuelles</li></ul>
                                <h2>Werke</h2>
                                <ul><li>Schriften</li><li>Tagebücher</li><li>Aktuelles</li></ul>
                                <h2>Tätigkeiten</h2>
                                <ul><li>Personen</li></ul>
                                <h2>Datenherkunft</h2>
                                <ul><li>Personen</li></ul>
                                <h2>Periodika</h2>
                                <ul><li>Schriften</li></ul>
                                <h2>Dokumentstatus</h2>
                                <ul><li>Personen</li><li>Briefe</li><li>Schriften</li><li>Tagebücher</li><li>Werke</li><li>Aktuelles</li></ul>
                            </div>
                        </div>
                        -->
                        <div id="{wega:getOption('containerID')}" style="float:left;width:98%;margin-left:2%">
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