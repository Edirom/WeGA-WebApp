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
import module namespace ajax="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/ajax" at "/db/webapp/xql/modules/ajax.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";

declare option exist:serialize "method=xhtml media-type=text/html indent=no omit-xml-declaration=yes encoding=utf-8 doctype-public=-//W3C//DTD&#160;XHTML&#160;1.0&#160;Strict//EN doctype-system=http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd";

declare function local:collectMetaData($doc as node(), $lang as xs:string) as element(wega:metaData) {
    let $pageTitle := string-join(wega:getLetterHead($doc, $lang), '. ')
    let $pageDescription := wega:cleanString($doc//tei:note[@type='summary'])
    let $commonMetaData := xho:collectCommonMetaData($doc)
    return 
    <wega:metaData>
        <title>{$pageTitle}</title>
        {$commonMetaData/*}
        <meta name="DC.title" content="{$pageTitle}"/>
        <meta name="description" content="{$pageDescription}" lang="{$lang}"/>
        <meta name="DC.description" content="{$pageDescription}"/>
        <meta name="DC.subject" content="Letter"/>
        <!-- <meta name="DC.source" content=""/> -->
        <!-- <meta name="DC.relation" content=""/> --> 
        <!-- <meta name="DC.coverage" content="" scheme="DCTERMS.TGN"/> -->
        <meta name="DC.language" content="de" scheme="DCTERMS.RFC3066"/>
        <meta name="DC.rights" content="All rights reserved"/>
    </wega:metaData>
};

let $lang := request:get-parameter('lang','')
let $docID := request:get-parameter('id','A041325')
let $withJS := request:get-parameter('js','true')
let $doc := core:doc($docID)
let $environment := config:get-option('environment')
let $facsimileWhiteList := tokenize(config:get-option('facsimileWhiteList'), ',') (: Komma-separierte Liste von Rism-Siglen in der options-Datei :)
let $rightsAreOK := exists($doc//tei:repository[@n = $facsimileWhiteList]) or $environment eq 'development' (: Bilderrechte zur Veröffentlichung müssen vorliegen :)
let $domLoaded := 
    if($withJS eq 'true') then
    <domLoaded xmlns="">
        <function>
            <name>getListFromEntriesWithKey</name>
            <param>{$docID}</param>
            <param>{$lang}</param>
            <param>persons</param>
            <param>person</param>
        </function>
        <function>
            <name>getListFromEntriesWithKey</name>
            <param>{$docID}</param>
            <param>{$lang}</param>
            <param>works</param>
            <param>work</param>
        </function>
        <function>
            <name>requestLetterContext</name>
            <param>{$docID}</param>
            <param>{$lang}</param>
        </function>
        <function>
            <name>getListFromEntriesWithoutKey</name>
            <param>{$docID}</param>
            <param>{$lang}</param>
            <param>places</param>
            <param>place</param>
        </function>
        <function>
            <name>getListFromEntriesWithoutKey</name>
            <param>{$docID}</param>
            <param>{$lang}</param>
            <param>characters</param>
            <param>character</param>
        </function>
    </domLoaded>
    else()
return

<html>
    {xho:createHtmlHead(('layout76-22.css', 'letter_singleView.css'), 'letter_functions.js', local:collectMetaData($doc, $lang), $domLoaded, ())}
    <body>
       <div id="container">
            {xho:createHeadContainer($lang)}
            <div id="main">
                {xho:createBreadCrumb($doc, $lang)}
                <div id="contentLeft">
                        <ul id="letterTabs" class="shadetabs">
                            <li><a href="functions/getAjax.xql?function=printTranscription&#38;id={$docID}&#38;lang={$lang}" class="selected" rel="letterFrame" title="{wega:getLanguageString('tabTitle_transcription', $lang)}">{wega:getLanguageString('textOfLetter',$lang)}</a></li>
                            <li><a href="functions/xmlPrettyPrint.xql?id={$docID}" rel="letterFrame" title="{wega:getLanguageString('tabTitle_xml', $lang)}">XML</a></li>
                            <li>{if(exists($doc//tei:facsimile//tei:graphic) and $rightsAreOK) 
                                then <a href="functions/getImage.xql?id={$docID}&#38;lang={$lang}" rel="letterFrame" title="{wega:getLanguageString('tabTitle_facsimile', $lang)}">{wega:getLanguageString('facsimile',$lang)}</a>
                                else <span class="notAvailable">{wega:getLanguageString('facsimile',$lang)}</span>}
                            </li>
                        </ul>
                    <div id="letterFrame">
                        {if($withJS ne 'true') then ajax:printTranscription($docID,$lang) else()}
                    </div>
                    <script type="text/javascript">
                        var letter=new ddajaxtabs("letterTabs", "letterFrame")
                        letter.setpersist(true)
                        letter.setselectedClassTarget("link")
                        if('{$withJS}'=='true') letter.init()
                    </script>
                </div>
                <div id="contentRight">
                    {wega:printSourceDesc($doc, $lang)}
                    <div>
                        <h2>{wega:getLanguageString('context',$lang)}</h2>
                        <div id="context">
                            <!-- (:Wird onlad gefüllt:) -->
                            {if($withJS ne 'true') then ajax:requestLetterContext($docID,$lang) else()}
                        </div>
                    </div>
                    <div class="nameList">
                        <h2>{wega:getLanguageString('persons',$lang)}</h2>
                        <ul id="persons">
                            <!-- (:Wird onload gefüllt:) -->
                            {if($withJS ne 'true') then ajax:getListFromEntriesWithKey($docID,$lang, 'person') else <li/>}
                        </ul>
                    </div>
                    <div class="nameList">
                        <h2>{wega:getLanguageString('works',$lang)}</h2>
                        <ul id="works">
                            <!-- (: Wird onload gefüllt :) -->
                            {if($withJS ne 'true') then ajax:getListFromEntriesWithoutKey($docID,$lang,'work') else <li/>}
                        </ul>
                    </div>
                    <div class="nameList">
                        <h2>{wega:getLanguageString('places',$lang)}</h2>
                        <ul id="places">
                            <!-- (: Wird onload gefüllt :) -->
                            {if($withJS ne 'true') then ajax:getListFromEntriesWithoutKey($docID,$lang,'place') else <li/>}
                        </ul>
                    </div>
                    <div class="nameList">
                        <h2>{wega:getLanguageString('characterNames',$lang)}</h2>
                        <ul id="characters">
                            <!-- (: Wird onload gefüllt :) -->
                            {if($withJS ne 'true') then ajax:getListFromEntriesWithoutKey($docID,$lang,'character') else <li/>}
                        </ul>
                    </div>
                </div>
            </div>
            {xho:createFooter($lang, document-uri($doc/root()))}
        </div>
    </body>
</html>