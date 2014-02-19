xquery version "1.0" encoding "UTF-8";
declare default collation "?lang=de;strength=primary";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";
declare namespace math="http://exist-db.org/xquery/math";

import module namespace wega="http://xquery.weber-gesamtausgabe.de/modules/wega" at "wega.xqm";
import module namespace functx="http://www.functx.com";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";

declare option exist:serialize "method=xhtml media-type=text/html indent=no omit-xml-declaration=yes encoding=utf-8";

declare function local:printKeyless() {
    let $coll := collection('/db/letters')//tei:sender/tei:persName[not(@key)] | collection('/db/letters')//tei:addressee/tei:persName[not(@key)]
    for $i in distinct-values($coll)
                let $count := count($coll//tei:persName[.=$i])
                order by $count descending
                return <p>{concat($count, ': ', data($i))}</p>
};

declare variable $local:fffiIDFile := 
    let $tmpDir := config:get-option('tmpDir')
    return
    if(not(doc-available(concat($tmpDir, 'fffiID.xml'))))
        then doc(xmldb:store($tmpDir, 'fffiID.xml', <dictionary xml:id="fffiID"/>))
    else doc(concat($tmpDir, 'fffiID.xml'));

declare function local:addFffiEntry($id as xs:string?) as xs:string {
    let $dateTime := util:system-dateTime()
    return if ($id ne '_A00') 
        then (update insert <entry xml:id="{$id}" dateTime="{$dateTime}"/> into $local:fffiIDFile/dictionary,
            string($local:fffiIDFile//id($id)/@xml:id)) 
        else ''
};

declare function local:removeOldEntries() {
    let $currentdateTime := util:system-dateTime()
    let $tempIDs := $local:fffiIDFile//entry
    for $entry in $tempIDs
        let $date := xs:dateTime($entry/@dateTime)
        let $id := data($entry/@xml:id)
        return if($date lt ($currentdateTime - xs:dayTimeDuration('P10D')))
            then update delete $local:fffiIDFile//id($id)
            else()
};

declare function local:getID($max as xs:integer, $coll1 as xs:string+, $coll2 as xs:string+) as xs:string {
    let $rand := functx:pad-integer-to-length(util:random($max) + 1, 4)
    let $newID := concat('A00', $rand)
    return if ($newID = $coll1) 
        then local:getID($max, $coll1, $coll2)
        else if ($newID = $coll2)  
            then local:getID($max, $coll1, $coll2)
            else $rand  
};

let $coll1 := collection('/db/persons')//tei:person/@xml:id 
let $coll2 := $local:fffiIDFile//entry/substring(@xml:id, 2)
let $removeOldTempIDS := local:removeOldEntries()
let $maxID := 9000
let $newID := if (count($coll1) + count($coll2) < $maxID)
    then local:addFffiEntry(concat('_A00', local:getID($maxID, $coll1, $coll2)))
    else '_kein Eintrag verfügbar'

return substring($newID, 2)
