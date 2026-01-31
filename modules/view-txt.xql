xquery version "3.1" encoding "UTF-8";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";

import module namespace api-dts="http://xquery.weber-gesamtausgabe.de/modules/api-dts" at "api-dts.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace crud="http://xquery.weber-gesamtausgabe.de/modules/crud" at "crud.xqm";

declare option output:method "text";
declare option output:media-type "text/plain";
declare option output:indent "no";

let $docID := request:get-attribute('docID')
let $doc := 
	if(config:get-doctype-by-id($docID)) then try { crud:doc($docID) } catch  * {()}
	else ()
let $doc.txt := api-dts:process-xml-document($doc, "text")
let $setHeader := response:set-header('Access-Control-Allow-Origin', '*')
return 
    $doc.txt
