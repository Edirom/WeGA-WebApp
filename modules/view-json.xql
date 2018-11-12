xquery version "3.0" encoding "UTF-8";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace img="http://xquery.weber-gesamtausgabe.de/modules/img" at "img.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";

declare option output:method "json";
declare option output:media-type "application/json";


let $content := request:get-data()
let $docID := request:get-attribute('docID')
let $sourceID := request:get-attribute('sourceID')
let $type := request:get-attribute('type')
let $image := request:get-attribute('image')
let $setHeader5 := response:set-header('Access-Control-Allow-Origin', '*')
return
    if($type eq 'manifest') then 
        let $doc := core:doc($docID)
        let $allowedFacsimiles := query:facsimile($doc)
        let $requestedFacsimile := $doc//tei:facsimile[substring(@source,2) = string($sourceID)]
        return
            if($requestedFacsimile = $allowedFacsimiles) then img:iiif-manifest($requestedFacsimile)
            else ()
    else ()