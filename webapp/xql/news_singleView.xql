xquery version "1.0" encoding "UTF-8";
declare default element namespace "http://www.w3.org/1999/xhtml"; 
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace datetime="http://exist-db.org/xquery/datetime";
import module namespace wega="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/wega" at "xmldb:exist:///db/webapp/xql/modules/wega.xqm";
import module namespace xho="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/xho" at "xmldb:exist:///db/webapp/xql/modules/xho.xqm";
import module namespace ajax="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/ajax" at "xmldb:exist:///db/webapp/xql/modules/ajax.xqm";

declare option exist:serialize "method=xhtml media-type=text/html indent=no omit-xml-declaration=yes encoding=utf-8 doctype-public=-//W3C//DTD&#160;XHTML&#160;1.0&#160;Strict//EN doctype-system=http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd";

declare function local:collectMetaData($doc as node(), $lang as xs:string) as item() {
    let $pageTitle := wega:cleanString($doc//tei:fileDesc/tei:titleStmt/tei:title[@level='a'])
    let $pageDescription := concat(substring(normalize-space($doc//tei:text), 1, 200), '…')
    let $commonMetaData := xho:collectCommonMetaData($doc)
    let $subject := string-join($doc//tei:keywords/tei:term, '; ')
    return 
    <metaData>
        <title>{$pageTitle}</title>
        {$commonMetaData/*}
        <meta name="DC.title" content="{$pageTitle}"/>
        <meta name="description" content="{$pageDescription}" lang="{$lang}"/>
        <meta name="DC.description" content="{$pageDescription}"/>
        <meta name="DC.subject" content="{$subject}"/>
        <!-- <meta name="DC.source" content=""/> -->
        <!-- <meta name="DC.relation" content=""/> --> 
        <!-- <meta name="DC.coverage" content="" scheme="DCTERMS.TGN"/> -->
        <meta name="DC.language" content="de" scheme="DCTERMS.RFC3066"/>
        <meta name="DC.rights" content="http://creativecommons.org/licenses/by-nc-sa/3.0/" scheme="DCTERMS.URI"/>
    </metaData>
};

let $lang := request:get-parameter('lang','de')
let $docID := request:get-parameter('id','A050001')
let $withJS := request:get-parameter('js','true')
let $news:= wega:doc($docID) 
let $authorID := wega:getAuthorOfTeiDoc($news) 
let $contextContainer := 'context'
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
        <function>
            <name>requestNewsContext</name>
            <param>{$contextContainer}</param>
            <param>{$docID}</param>
            <param>{$lang}</param>
        </function>
    </domLoaded>
    else ()
return

<html>
    {xho:createHtmlHead('layout76-22.css', (), local:collectMetaData($news, $lang), $domLoaded, ())}
    <body>
        <div id="container">
            {xho:createHeadContainer($lang)}
            <div id="main">
                {xho:createBreadCrumb($news, $lang)}
                <div id="contentLeft">
                    <ul id="newsTabs" class="shadetabs">
                        <li><a href="functions/news_printTranscription.xql?id={$docID}&#38;lang={$lang}" class="selected" rel="newsFrame" title="{wega:getLanguageString('tabTitle_transcription', $lang)}">Text</a></li>
                        <li><a href="functions/xmlPrettyPrint.xql?id={$docID}" rel="newsFrame" title="{wega:getLanguageString('tabTitle_xml', $lang)}">XML</a></li>
                    </ul>
                    <div id="newsFrame"><!-- (:Wird onload gefüllt:) --></div>
                    <script type="text/javascript">
                        var news=new ddajaxtabs("newsTabs", "newsFrame")
                        news.setpersist(true)
                        news.setselectedClassTarget("link")
                        news.init()
                    </script>
                </div>
                <div id="contentRight">
                    {if($withJS ne 'true') 
                        then ajax:getNewsContext($contextContainer, $docID, $lang) 
                        else <div id="{$contextContainer}"><!-- (: Wird onload gefüllt :) --></div>
                    }
                    <div class="nameList">
                        <h2>{wega:getLanguageString('knownPersons',$lang)}</h2>
                        <ul id="persons">
                            <!-- (: Wird onload gefüllt :) -->
                            {if($withJS ne 'true') then ajax:getListFromEntriesWithKey($docID,$lang,'person') else <li/>}
                        </ul>
                    </div>
                    <div class="nameList">
                        <h2>{wega:getLanguageString('works',$lang)}</h2>
                        <ul id="works">
                            <!-- (: Wird onload gefüllt :) -->
                            {if($withJS ne 'true') then ajax:getListFromEntriesWithKey($docID,$lang,'work') else <li/>}
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
            {xho:createFooter($lang, document-uri($news/root()))}
        </div>
    </body>
</html>