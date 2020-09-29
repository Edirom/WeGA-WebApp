xquery version "3.1" encoding "UTF-8";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace img="http://xquery.weber-gesamtausgabe.de/modules/img" at "img.xqm";
import module namespace crud="http://xquery.weber-gesamtausgabe.de/modules/crud" at "crud.xqm";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";
import module namespace mycache="http://xquery.weber-gesamtausgabe.de/modules/cache" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/cache.xqm";
import module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util" at "wega-util.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/str.xqm";

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
        let $doc := crud:doc($docID)
        let $allowedFacsimiles := query:facsimile($doc)
        let $requestedFacsimile := $doc//tei:facsimile[substring(@source,2) = string($sourceID)]
        return
            if($requestedFacsimile = $allowedFacsimiles) then mycache:doc(
                str:join-path-elements(($config:tmp-collection-path, 'manifests', substring($docID, 1, 5) || 'xx', $docID || $sourceID || '.json')), 
                img:iiif-manifest#1, 
                $requestedFacsimile, 
                function($currentDateTimeOfFile as xs:dateTime?) as xs:boolean { wega-util:check-if-update-necessary($currentDateTimeOfFile, xs:dayTimeDuration('P999D')) }, 
                function($errCode, $errDesc) { wega-util:log-to-file('warn', string-join(($errCode, $errDesc), ' ;; ')) }
            )
            else ()
(:    else if($type eq 'collection') then img:iiif-collection($docID):)
    else ()