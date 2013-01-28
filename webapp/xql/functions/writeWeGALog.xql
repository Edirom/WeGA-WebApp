xquery version "1.0" encoding "UTF-8";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util = "http://exist-db.org/xquery/util";
declare namespace session = "http://exist-db.org/xquery/session";
import module namespace wega="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/wega" at "xmldb:exist:///db/webapp/xql/modules/wega.xqm";
import module namespace facets="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/facets" at "xmldb:exist:///db/webapp/xql/modules/facets.xqm";

let $text := request:get-parameter('text','')
let $logLevel := request:get-parameter('logLevel','error')
let $errorMessage := 
    if(matches($text, 'filterMenu\.xql')) then ( (: add current filter parameters to the error message:)
        let $docType := substring-after($text, 'docType=')
        let $filter := session:get-attribute(facets:getFilterName($docType))
        let $serializeParameters := 'method=text media-type=text/plain encoding=utf-8'
        return concat($text, '; ', util:serialize($filter, $serializeParameters))
    )
    else $text
let $logToFile := wega:logToFile($logLevel, $errorMessage)
return()