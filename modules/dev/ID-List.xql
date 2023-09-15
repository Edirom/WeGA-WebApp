(:~
 : XQuery for use with the JUnit Test
 :
 : @author Peter Stadler 
 : @version 1.0
 :)

xquery version "3.0" encoding "UTF-8";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "../config.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "../core.xqm";

declare option output:method "text";
declare option output:media-type "text/plain";
declare option output:indent "no";

declare function local:randomize($seq as item()*) as item()* {
    for $i in $seq
    let $rand := util:random()
    order by $rand
        return $i
};

let $docType := request:get-parameter('type','persons')
let $maxLen := number(request:get-parameter('maxLen','10'))
let $random := request:get-parameter('random','true')
let $ids := core:getOrCreateColl($docType, 'indices', true())/*/data(@xml:id)
let $ids := if($random eq 'true') then local:randomize($ids) else $ids
return
    string-join(subsequence($ids, 1, $maxLen), '&#10;')