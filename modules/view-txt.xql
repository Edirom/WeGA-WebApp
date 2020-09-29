xquery version "3.1" encoding "UTF-8";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";

import module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util" at "wega-util.xqm";
import module namespace crud="http://xquery.weber-gesamtausgabe.de/modules/crud" at "crud.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";
import module namespace lod="http://xquery.weber-gesamtausgabe.de/modules/lod" at "lod.xqm";

declare option output:method "xhtml";
declare option output:media-type "text/html";
declare option output:indent "no";
(:declare option exist:serialize "method=text media-type=plain/text indent=no encoding=utf-8";:)

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
    let $lod := lod:metadata(<head/>, $model, $lang)
    let $author := '## Author: ' || query:get-authorName($doc)
    let $title := '## Title: ' || $lod?meta-page-title
    let $version := '## Version: ' || config:expath-descriptor()/@version
    let $origin := '## Origin: ' || config:permalink($docID)
    let $license := '## License: ' || $lod?DC.rights
    return
        string-join(($title,$author,$version,$origin,$license), '&#10;')
};

let $docID := request:get-attribute('docID')
let $content := 
	if(config:get-doctype-by-id($docID)) then try { crud:doc($docID) } catch  * {()}
	else ()
let $transformed :=  wega-util:transform($content, doc($config:xsl-external-schemas-collection-path || '/to-text.xsl'), ())
let $setHeader5 := response:set-header('Access-Control-Allow-Origin', '*')
return (
    local:header($content),
    '&#10;&#10;',
    $transformed
)