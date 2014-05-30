xquery version "1.0" encoding "UTF-8";
declare default element namespace "http://www.w3.org/1999/xhtml"; 
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace util="http://exist-db.org/xquery/util";
import module namespace wega="http://xquery.weber-gesamtausgabe.de/modules/wega" at "wega.xqm";
import module namespace xho="http://xquery.weber-gesamtausgabe.de/modules/xho" at "xho.xqm";
import module namespace ajax="http://xquery.weber-gesamtausgabe.de/modules/ajax" at "ajax.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";

declare option exist:serialize "method=xhtml media-type=text/html indent=no omit-xml-declaration=yes encoding=utf-8 doctype-public=-//W3C//DTD&#160;XHTML&#160;1.0&#160;Strict//EN doctype-system=http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"; 

declare function local:collectMetaData($doc as document-node(), $lang as xs:string) as element(wega:metaData) {
    let $pageTitle := string-join($doc//tei:fileDesc/tei:titleStmt/tei:title[@level='a'], '. ')
    let $pageDescription := wega:cleanString($doc//tei:note[@type='summary'])
    let $commonMetaData := xho:collectCommonMetaData($doc)
    return 
    <wega:metaData>
        <title>{$pageTitle}</title>
        {$commonMetaData/*}
        <meta name="DC.title" content="{$pageTitle}"/>
        <meta name="description" content="{$pageDescription}" lang="{$lang}"/>
        <meta name="DC.description" content="{$pageDescription}"/>
        <meta name="DC.subject" content="Historic Newspaper; Writing"/>
        <!-- <meta name="DC.source" content=""/> -->
        <!-- <meta name="DC.relation" content=""/> --> 
        <!-- <meta name="DC.coverage" content="" scheme="DCTERMS.TGN"/> -->
        <meta name="DC.language" content="de" scheme="DCTERMS.RFC3066"/>
        <meta name="DC.rights" content="http://creativecommons.org/licenses/by-nc-sa/3.0/" scheme="DCTERMS.URI"/>
    </wega:metaData>
};

let $lang := request:get-parameter('lang','')
let $docID := request:get-parameter('id','A030050')
let $withJS := request:get-parameter('js','true')
let $doc := core:doc($docID) 
let $authorID := wega:getAuthorOfTeiDoc($doc)
let $authorName := wega:getRegName($authorID) 
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
    </domLoaded>
    else()
(:let $url := request:get-url():)
(:let $mainID := wega:getMainID($docID):)
let $docPage := $doc//tei:monogr/tei:imprint/tei:biblScope[@type='col']
(: Z.Z. noch hart codiert, liesse sich hiermit ändern: http://code.google.com/intl/de-DE/apis/books/docs/dynamic-links.html :)
let $googleBookID := if($doc//tei:monogr/tei:title[@level='j']='Allgemeine Musikalische Zeitung')
    then if($doc//tei:monogr/tei:imprint/tei:biblScope[@type='vol']='19') then 'fN0qAAAAYAAJ' 
        else if($doc//tei:monogr/tei:imprint/tei:biblScope[@type='vol']='20') then 'vN0qAAAAYAAJ' else()
    else()        
let $googleLink := if(empty($googleBookID)) then () else concat('http://books.google.com/books?id=', $googleBookID, '&amp;hl=', $lang, '&amp;pg=PA', $docPage, '&amp;output=embed')

return 
<html>
    {xho:createHtmlHead(('layout76-22.css', 'doc_singleView.css'), (), local:collectMetaData($doc, $lang) , $domLoaded, ())}
    <body>
       <div id="container">
            {xho:createHeadContainer($lang)}
            <div id="main">
                {xho:createBreadCrumb($doc, $lang)}
                <div id="contentLeft">
                        <ul id="docTabs" class="shadetabs">
                            <li><a href="functions/getAjax.xql?function=printTranscription&#38;id={$docID}&#38;lang={$lang}" class="selected" rel="docFrame" title="{lang:get-language-string('tabTitle_transcription', $lang)}">{lang:get-language-string('textOfDoc',$lang)}</a></li>
                            <li><a href="functions/xmlPrettyPrint.xql?id={$docID}" rel="docFrame" title="{lang:get-language-string('tabTitle_xml', $lang)}">XML</a></li>
                            <li>
                                {if(exists($doc/tei:figDesc)) then <a href="#" rel="#default" title="{lang:get-language-string('tabTitle_facsimile', $lang)}">{lang:get-language-string('facsimile',$lang)}</a>
                                    else if(empty($googleLink)) 
                                        then <span class="notAvailable">{lang:get-language-string('facsimile',$lang)}</span>
                                        else <a href="{$googleLink}" rel="#iframe">GoogleBooks</a>}
                            </li>
                        </ul>
                    <div id="docFrame">
                       {if($withJS ne 'true') then ajax:printTranscription($docID,$lang) else()}
                    </div>
                    <script type="text/javascript">
                        var letter=new ddajaxtabs("docTabs", "docFrame")
                        letter.setpersist(true)
                        letter.setselectedClassTarget("link")
                        if('{$withJS}'=='true') letter.init()
                    </script>
                </div>
                <div id="contentRight">
                    {wega:printSourceDesc($doc, $lang)}
                    <div class="nameList">
                        <h2>{lang:get-language-string('knownPersons',$lang)}</h2>
                        <ul id="persons">
                            <!-- (: Wird onload gefüllt :) -->
                            {if($withJS ne 'true') then ajax:getListFromEntriesWithKey($docID,$lang,'person') else <li/>}
                        </ul>
                    </div>
                    <div class="nameList">
                        <h2>{lang:get-language-string('works',$lang)}</h2>
                        <ul id="works">
                            <!-- (: Wird onload gefüllt :) -->
                            {if($withJS ne 'true') then ajax:getListFromEntriesWithKey($docID,$lang,'work') else <li/>}
                        </ul>
                    </div>
                    <div class="nameList">
                        <h2>{lang:get-language-string('places',$lang)}</h2>
                        <ul id="places">
                            <!-- (: Wird onload gefüllt :) -->
                            {if($withJS ne 'true') then ajax:getListFromEntriesWithoutKey($docID,$lang,'place') else <li/>}
                        </ul>
                    </div>
                    <div class="nameList">
                        <h2>{lang:get-language-string('characterNames',$lang)}</h2>
                        <ul id="characters">
                            <!-- (: Wird onload gefüllt :) -->
                            {if($withJS ne 'true') then ajax:getListFromEntriesWithoutKey($docID,$lang,'character') else <li/>}
                        </ul>
                    </div>
                </div>
            </div>
            {xho:createFooter($lang, document-uri($doc))}
        </div>
    </body>
</html>