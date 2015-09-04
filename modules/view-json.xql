xquery version "3.0" encoding "UTF-8";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace img="http://xquery.weber-gesamtausgabe.de/modules/img" at "img.xqm";

declare option output:method "json";
declare option output:media-type "application/json";


let $content := request:get-data()
let $docID := request:get-attribute('docID')
let $type := request:get-attribute('type')
let $image := request:get-attribute('image')
return
    if($type eq 'manifest') then img:iiif-manifest($docID)
    else ()