xquery version "1.0" encoding "UTF-8";
declare default element namespace "http://www.w3.org/1999/xhtml"; 
declare default collation "?lang=de;strength=primary";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace util="http://exist-db.org/xquery/util";
import module namespace wega="http://xquery.weber-gesamtausgabe.de/modules/wega" at "wega.xqm";
import module namespace xho="http://xquery.weber-gesamtausgabe.de/modules/xho" at "xho.xqm";
import module namespace ajax="http://xquery.weber-gesamtausgabe.de/modules/ajax" at "ajax.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date" at "date.xqm";

declare option exist:serialize "method=xhtml media-type=text/html indent=no omit-xml-declaration=yes encoding=utf-8 doctype-public=-//W3C//DTD&#160;XHTML&#160;1.0&#160;Strict//EN doctype-system=http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd";

declare function local:collectMetaData($diaryDay as document-node(), $authorID as xs:string, $lang as xs:string) as element(wega:metaData) {
    let $name := wega:printFornameSurname(wega:getRegName($authorID))
    let $dateFormat := 
        if ($lang eq 'en') then '%A, %B %d, %Y'
        else '%A, %d. %B %Y'
    let $date := date:strfdate($diaryDay/tei:ab/string(@n), $lang, $dateFormat)
    let $pageTitle := concat($name, ' – ', lang:get-language-string('diarySingleViewTitle', $date, $lang)) 
    let $pageDescription := 
        if(string-length(data($diaryDay)) > 200) then concat(substring(wega:cleanString($diaryDay), 1, 200), '…')
        else data($diaryDay)
    let $commonMetaData := xho:collectCommonMetaData($diaryDay)
    return 
    <wega:metaData>
        <title>{$pageTitle}</title>
        {$commonMetaData/*}
        <meta name="DC.title" content="{$pageTitle}"/>
        <meta name="description" content="{$pageDescription}" lang="{$lang}"/>
        <meta name="DC.description" content="{$pageDescription}"/>
        <meta name="DC.subject" content="{string-join((lang:get-language-string('diary', $lang), $name), '; ')}"/>
        <meta name="DC.contributor" content="Dagmar Beck"/>
        <meta name="DC.contributor" content="Sonja Klein"/>
        <!-- <meta name="DC.source" content=""/> -->
        <!-- <meta name="DC.relation" content=""/> --> 
        <!-- <meta name="DC.coverage" content="" scheme="DCTERMS.TGN"/> -->
        <meta name="DC.language" content="de" scheme="DCTERMS.RFC3066"/>
        <meta name="DC.rights" content="All rights reserved by the WeGA"/>
    </wega:metaData>
};

let $lang := request:get-parameter('lang','de')
let $docID := request:get-parameter('id','A060001')
let $withJS := if(request:get-parameter('js', 'true') eq 'true') then true() else false()
let $doc := core:doc($docID)
let $authorID := 'A002068'
let $xslParams := config:get-xsl-params(())
let $contextContainer := 'context'
let $domLoaded := 
    if($withJS) then
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
            <name>requestDiaryContext</name>
            <param>{$contextContainer}</param>
            <param>{$docID}</param>
            <param>{$lang}</param>
        </function>
    </domLoaded>
    else()
return

<html>
    {xho:createHtmlHead(('layout76-22.css', 'diary_singleView.css'), (), local:collectMetaData($doc, $authorID, $lang), $domLoaded, ())}
    <body>
        <div id="container">
            {xho:createHeadContainer($lang)}
            <div id="main">
                {xho:createBreadCrumb($doc, $lang)}
                <div id="contentLeft">
                    <ul id="diaryTabs" class="shadetabs">
                        <li><a href="functions/getAjax.xql?function=diary_printTranscription&#38;docID={$docID}&#38;lang={$lang}"  rel="diaryFrame" title="{lang:get-language-string('tabTitle_transcription', $lang)}" class="selected">Text</a></li>
                        <li><a href="functions/xmlPrettyPrint.xql?id={$docID}" rel="diaryFrame" title="{lang:get-language-string('tabTitle_xml', $lang)}">XML</a></li>
                        <li>{if(exists($doc/tei:figDesc)) then <a href="#" rel="#default" title="{lang:get-language-string('tabTitle_facsimile', $lang)}">{lang:get-language-string('facsimile',$lang)}</a>
                                else <span class="notAvailable">{lang:get-language-string('facsimile',$lang)}</span>}
                        </li>
                        <!--
                        <li>{if(exists($doc/tei:auswertung)) then <a href="#" rel="#default" title="">Auswertung</a>
                                else <span class="notAvailable">Auswertung</span>}
                        </li>
                        -->
                    </ul>
                    <div id="diaryFrame">
                        <!-- (:Wird per Ajax gefüllt:) -->
                        {if(not($withJS)) then ajax:diary_printTranscription($docID,$lang) else()}
                    </div>
                    <script type="text/javascript">
                        var diary=new ddajaxtabs("diaryTabs", "diaryFrame")
                        diary.setpersist(true)
                        diary.setselectedClassTarget("link")
                        if({$withJS}) diary.init()
                    </script>
                </div>
                <div id="contentRight">
                    <div class="clearfix">
                        <h2 class="headWithToggleMarker">{lang:get-language-string('editorial',$lang)}</h2>
                        <a class="toggleMarker" title="{lang:get-language-string('showEditorial',$lang)}" onclick="$('editorial').toggle();$('show').toggle();$('hide').toggle()"><span id="show">({lang:get-language-string('show',$lang)})</span><span id="hide" style="display:none">({lang:get-language-string('hide',$lang)})</span></a>
                        <br class="clearer"/>
                        <div id="editorial" style="display:none">
                            <h3 id="resp">{lang:get-language-string('transcription',$lang)}</h3>
                            <ul><li>Dagmar Beck</li></ul>
                            
                            <h3>{lang:get-language-string('textSource',$lang)}</h3>
                            
                            <div>D-B, Mus. ms. autogr. theor. C. M. v. Weber 1</div>
                        </div>
                    </div>
                    {if(not($withJS))
                        then ajax:getDiaryContext($contextContainer, $docID, $lang) 
                        else <div id="{$contextContainer}"><!-- (: Wird onload gefüllt :) --></div>
                    }
                    <div class="nameList">
                        <h2>{lang:get-language-string('knownPersons',$lang)}</h2>
                        <ul id="persons">
                            <!-- (: Wird onload gefüllt :) -->
                            {if(not($withJS)) then ajax:getListFromEntriesWithKey($docID,$lang,'person') else <li/>}
                        </ul>
                    </div>
                    <div class="nameList">
                        <h2>{lang:get-language-string('works',$lang)}</h2>
                        <ul id="works">
                            <!-- (: Wird onload gefüllt :) -->
                            {if(not($withJS)) then ajax:getListFromEntriesWithKey($docID,$lang,'work') else <li/>}
                        </ul>
                    </div>
                    <div class="nameList">
                        <h2>{lang:get-language-string('places',$lang)}</h2>
                        <ul id="places">
                            <!-- (: Wird onload gefüllt :) -->
                            {if(not($withJS)) then ajax:getListFromEntriesWithoutKey($docID,$lang,'place') else <li/>}
                        </ul>
                    </div>
                    <div class="nameList">
                        <h2>{lang:get-language-string('characterNames',$lang)}</h2>
                        <ul id="characters">
                            <!-- (: Wird onload gefüllt :) -->
                            {if(not($withJS)) then ajax:getListFromEntriesWithoutKey($docID,$lang,'character') else <li/>}
                        </ul>
                    </div>
                </div>
            </div>
            {xho:createFooter($lang, document-uri($doc))}
        </div>
    </body>
</html>
