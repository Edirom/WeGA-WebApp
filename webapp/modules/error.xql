xquery version "1.0" encoding "UTF-8";
declare default element namespace "http://www.w3.org/1999/xhtml"; 
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace response="http://exist-db.org/xquery/response";
import module namespace wega="http://xquery.weber-gesamtausgabe.de/modules/wega" at "wega.xqm";
import module namespace xho="http://xquery.weber-gesamtausgabe.de/modules/xho" at "xho.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";

declare option exist:serialize "method=xhtml media-type=text/html indent=no omit-xml-declaration=yes encoding=utf-8 doctype-public=-//W3C//DTD&#160;XHTML&#160;1.0&#160;Strict//EN doctype-system=http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd";

let $lang := request:get-parameter('lang','de')
let $errorCode := request:get-parameter('errorCode','404')
let $baseHref := config:get-option('baseHref')
let $startID := 'A002068'
let $encryptedBugEmail := wega:encryptString(config:get-option('bugEmail'), ())
let $errorText404 := 
    if($lang eq 'en') then (
        <h1>Fehler 404 – page not found</h1>,
        <p>The page you have requested could not be found. If it seems to be an error within our site please do not hesitate to inform us via email at <span onclick="javascript:decEma('{$encryptedBugEmail}')" class="ema">{wega:obfuscateEmail(config:get-option('bugEmail'))}</span> so we can fix it as soon as possible.</p>,
        <p>If you have landed here due to an external link please contact the person in charge there. Thank you!</p>
    )
    else (
        <h1>Fehler 404 – Seite nicht gefunden</h1>,
        <p>Die von Ihnen angeforderte Seite konnte leider nicht gefunden werden. Sollte es sich um einen Fehler auf unserer Seite handeln, so informieren Sie uns bitte per E-Mail an <span onclick="javascript:decEma('{$encryptedBugEmail}')" class="ema">{wega:obfuscateEmail(config:get-option('bugEmail'))}</span>, damit wir dies schnellstmöglich beheben können.</p>, 
        <p>Sind Sie über einen veralteten externen Link hier gelandet, so informieren Sie bitte den dort Verantwortlichen. Vielen Dank!</p>
    )
let $logMessage := concat('error.xql: ', request:get-uri(), ' (', $errorCode, ')')
let $logToFile := core:logToFile('error', $logMessage)
let $setStatusCode := response:set-status-code(xs:int($errorCode))
let $startID := 'A002068'
let $metaData := 
    <wega:metaData>
        <title>Error 404 – Carl-Maria-von-Weber-Gesamtausgabe</title>
        {xho:collectCommonMetaData(())/*}
        <meta name="DC.creator" content="Peter Stadler"/>
        <meta name="DC.language" content="{$lang}" scheme="DCTERMS.RFC3066"/>
        <meta name="robots" content="noindex,nofollow,noarchive"/>
    </wega:metaData>
return

<html>
    {xho:createHtmlHead('index.css', (), $metaData, (), ())}
    <body>
        <div id="container">
            {xho:createHeadContainer($lang)}
            <div id="main">
                <div id="contentLeft">
                    <div>{$errorText404}</div>
                </div>
                <div id="contentRight">
                    {xho:printEditionLinks($startID, $lang),
                    xho:printProjectLinks($lang),
                    if(config:get-option('environment') eq 'development') then xho:printDevelopmentLinks($lang) else ()}
                </div>
            </div>
        </div>
    </body>
</html>