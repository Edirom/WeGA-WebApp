xquery version "3.0" encoding "UTF-8";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

import module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util" at "wega-util.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
(:import module namespace wdt="http://xquery.weber-gesamtausgabe.de/modules/wdt" at "wdt.xqm";:)
(:import module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date" at "date.xqm";:)
(:import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";:)
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";
import module namespace html-meta="http://xquery.weber-gesamtausgabe.de/modules/html-meta" at "html-meta.xqm";

declare option exist:serialize "method=text media-type=plain/text indent=no encoding=utf-8";

declare function local:header($doc as document-node()) as xs:string {
    let $docID := $doc/*/data(@xml:id)
    let $lang := 'en'
    let $model := 
        map { 
            'lang': $lang,
            'docID': $docID,
            'doc': $doc,
            'docType': config:get-doctype-by-id($docID)
        }
    let $html-meta := html-meta:metadata(<head/>, $model, $lang)
    let $author := '## Author: ' || query:get-authorName($doc)
    let $title := '## Title: ' || $html-meta?meta-page-title
    let $version := '## Version: ' || config:get-option('version')
    let $origin := '## Origin: ' || core:permalink($docID)
    let $license := '## License: ' || $html-meta?DC.rights
    return
        string-join(($title,$author,$version,$origin,$license), '&#10;')
};

let $docID := request:get-attribute('docID')
let $content := 
	if(config:get-doctype-by-id($docID)) then try { core:doc($docID) } catch  * {()}
	else ()
let $transformed :=  wega-util:transform($content, doc($config:xsl-external-schemas-collection-path || '/to-text.xsl'), ())
let $setHeader5 := response:set-header('Access-Control-Allow-Origin', '*')
return (
    local:header($content),
    '&#10;&#10;',
    $transformed
)