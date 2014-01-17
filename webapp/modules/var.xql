xquery version "1.0" encoding "UTF-8";
declare default element namespace "http://www.w3.org/1999/xhtml"; 
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace xho="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/xho" at "xho.xqm";
import module namespace wega="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/wega" at "wega.xqm";
import module namespace ajax="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/ajax" at "ajax.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";

declare option exist:serialize "method=xhtml media-type=text/html indent=no omit-xml-declaration=yes encoding=utf-8 doctype-public=-//W3C//DTD&#160;XHTML&#160;1.0&#160;Strict//EN doctype-system=http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd";

declare function local:createAboutSidebar($impressum as document-node(), $lang as xs:string) as element()* {
    let $addressDetmold := wega:outputAddress($impressum//tei:titleStmt/tei:funder[@xml:lang=$lang]/tei:address[1], $lang, ())
    let $addressBerlin := wega:outputAddress($impressum//tei:titleStmt/tei:funder[@xml:lang=$lang]/tei:address[2], $lang, ())
    return
    element div {
        attribute id {'sidebarAddress'},
        element h2 {
            wega:getLanguageString('address', $lang)
        },
        element h3 {
            data($impressum//tei:titleStmt/tei:funder[@xml:lang=$lang]/tei:name)
        },
        $addressDetmold, 
        element br {},
        $addressBerlin
    },
    element div {
        element h2 {
            (:Inhaltlich Verantwortliche gemäß § 55 Abs. 2 RStV:)
            wega:getLanguageString('editorsInCharge', $lang)
        },
        element ul {
            for $i in ($impressum//tei:titleStmt/tei:author | $impressum//tei:titleStmt/tei:editor) 
            return <li>{wega:printCorrespondentName($i, $lang, 'fs')}</li>
        }
    }
};

declare function local:createNameListSidebar($docID as xs:string, $withJS as xs:boolean, $lang as xs:string) as element()* {
    for $i at $count in ('persons', 'works', 'places', 'characterNames')
    return 
    element div {
        attribute class {'nameList'},
        element h2 {
            wega:getLanguageString($i,$lang)
        },
        element ul {
            attribute id {$i},
            if($withJS) then <li/>
            else if($count lt 3) then ajax:getListFromEntriesWithKey($docID,$lang, substring($i, 1, string-length($i) - 1))
            else ajax:getListFromEntriesWithoutKey($docID,$lang, substring($i, 1, string-length($i) - 1))
        }
    }
};

declare function local:collectMetaData($doc as document-node(), $lang as xs:string) as element(wega:metaData) {
    let $pageTitle := wega:cleanString($doc//tei:fileDesc/tei:titleStmt/tei:title[@level='a'][@xml:lang = $lang]) 
    let $pageDescription := 
        if(config:is-biblio($doc/tei:TEI/string(@xml:id))) then string-join($doc//tei:biblStruct[1]//tei:title, '. ')
        else wega:cleanString($doc//tei:note[@type='summary'][@xml:lang=$lang])
    let $commonMetaData := xho:collectCommonMetaData($doc) 
    let $subject := string-join($doc//tei:profileDesc//tei:term, '; ')
    let $isbnIdentifier := 
        if($doc//tei:idno[@type='isbn-13']) then <meta name="DC.source" scheme="DCTERMS.URI" content="{concat('urn:ISBN:', normalize-space($doc//tei:idno[@type='isbn-13']))}"/>
        else ()
    return 
    <wega:metaData>
        <title>{$pageTitle}</title>
        {$commonMetaData/*}
        <meta name="DC.title" content="{$pageTitle}"/>
        <meta name="description" content="{$pageDescription}" lang="{$lang}"/>
        <meta name="DC.description" content="{$pageDescription}"/>
        {$isbnIdentifier}
        <meta name="DC.subject" content="{$subject}"/>
        <meta name="DC.language" content="{$lang}" scheme="DCTERMS.RFC3066"/>
        <meta name="DC.rights" content="http://creativecommons.org/licenses/by-nc-sa/3.0/" scheme="DCTERMS.URI"/>
    </wega:metaData>
};
 

let $lang := request:get-parameter('lang','')
let $docID := request:get-parameter('docID','A070003')
let $createToc := request:get-parameter('createToc',())
let $createSecNos := request:get-parameter('createSecNos',())
let $withJS := if(request:get-parameter('js', 'true') eq 'true') then true() else false()
let $isImpressum := $docID eq 'A070002'
let $isBiography := $docID eq 'A070003'
let $xslParams :=
    <parameters>
        <param name="lang" value="{$lang}"/>
        {if(exists($createToc)) then <param name="createToc" value="true"/> else()}
        {if(exists($createSecNos)) then <param name="createSecNos" value="true"/> else()}
        {if($isBiography) then <param name="collapseBlock" value="true"/> else()}
        <param name="uri" value="{request:get-uri()}"/>
        <param name="docID" value="{$docID}"/>
    </parameters>
let $doc := core:doc($docID)
let $css := if($isImpressum) then 'index.css' else 'layout76-22.css'
let $domLoaded := 
    if($withJS and $isBiography or config:is-biblio($docID)) then
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
            <param>characterNames</param>
            <param>character</param>
        </function>
    </domLoaded>
    else()
return

<html>
    {xho:createHtmlHead($css, (), local:collectMetaData($doc, $lang) , $domLoaded, ())}
    <body>
        <div id="container">
            {xho:createHeadContainer($lang)}
            <div id="main">
                <div id="contentLeft">
                    <ul id="docTabs" class="shadetabs">
                        <li><a href="./#" class="selected" rel="#default" title="{wega:getLanguageString('tabTitle_transcription', $lang)}">Text</a></li>
                        <li><a href="functions/xmlPrettyPrint.xql?id={$docID}" rel="docFrame" title="{wega:getLanguageString('tabTitle_xml', $lang)}">XML</a></li>
                    </ul>
                    <div id="docFrame">
                        {if($isImpressum) then ()
                        else element h1 { wega:cleanString($doc//tei:fileDesc/tei:titleStmt/tei:title[@level='a'][@xml:lang = $lang]) },
                        transform:transform($doc//tei:text, doc("/db/webapp/xsl/var.xsl"), $xslParams)
                        }
                    </div>
                    <script type="text/javascript">
                        var doc=new ddajaxtabs("docTabs", "docFrame")
                        doc.setpersist(true)
                        doc.setselectedClassTarget("link")
                        {if($withJS) then 'doc.init()' else ()}
                    </script>
                </div>
                <div id="contentRight">{
                    if($isImpressum) then local:createAboutSidebar($doc, $lang) else(),
                    if($isBiography or config:is-biblio($docID)) then local:createNameListSidebar($docID, $withJS, $lang) else ()
                }
                </div>
            </div>
            {xho:createFooter()}         
        </div>
    </body>
</html>
