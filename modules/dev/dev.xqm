xquery version "3.0" encoding "UTF-8";

(:~
 : WeGA Development XQuery-Module
 :
 : @author Peter Stadler 
 : @version 1.0
 :)
 
module namespace dev="http://xquery.weber-gesamtausgabe.de/modules/dev";
declare default collation "?lang=de;strength=primary";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace session = "http://exist-db.org/xquery/session";
declare namespace xmldb = "http://exist-db.org/xquery/xmldb";
declare namespace cache = "http://exist-db.org/xquery/cache";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace request="http://exist-db.org/xquery/request";
import module namespace functx="http://www.functx.com";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "../str.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "../config.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "../core.xqm";

(:~
 : Create new ID
 :
 : @author Peter Stadler 
 : @param $docType
 : @return xs:string
 :)
declare function dev:createNewID($docType as xs:string) as xs:string {
    let $IDFileName := concat($docType, '-tmpIDs.xml')
    let $IDFileURI := str:join-path-elements(($config:tmp-collection-path, $IDFileName))
    let $IDFile := core:cache-doc($IDFileURI, dev:create-empty-idfile#2, ($docType, $IDFileURI), xs:dayTimeDuration('P1D'))
       (: if(not(doc-available(concat($config:tmp-collection-path, $IDFileName)))) then doc(xmldb:store($config:tmp-collection-path, $IDFileName, <dictionary xml:id="{$IDFileName}"/>))
        else doc(concat($config:tmp-collection-path, $IDFileName)):)
    let $coll1 := core:data-collection($docType)/*/data(@xml:id) (: core:getOrCreateColl() geht nicht, da hier auch die Dubletten mit berücksichtigt werden müssen! :)
    let $coll2 := $IDFile//dev:entry/substring(@xml:id, 2)
    let $removeOldTempIDS := dev:removeOldEntries($IDFile)
    let $maxID := count($coll1) + count($coll2) + 200
    let $newID := 
        if ($maxID lt 65535) then dev:addFffiEntry($IDFile, concat('_', dev:getNewID($maxID, $coll1, $coll2)))
        else '_kein Eintrag verfügbar'

    return substring($newID, 2)
};

(:~
 : Get latest ANT log file
 :
 : @author Peter Stadler 
 : @return map with entries 'rev' and 'success'
 :)
declare function dev:ant-log() as map(*) {
    let $logFile := util:binary-doc(str:join-path-elements(($config:tmp-collection-path, 'logs', max(xmldb:get-child-resources($config:tmp-collection-path || '/logs')))))
    let $logLines := tokenize(util:binary-to-string($logFile), '\n')
    return
        map:new((
            map:entry('rev', substring-after($logLines[contains(., 'Current revision of the working copy: ')], ': ')),
            map:entry('success', if($logLines = 'BUILD SUCCESSFUL') then 'success' else 'failed')
        ))
};

(:~
 : Add new ID entry
 :
 : @author Peter Stadler 
 : @param $IDFile 
 : @param $id
 : @return xs:string
 :)
declare %private function dev:addFffiEntry($IDFile as document-node(), $id as xs:string?) as xs:string {
    let $currentdateTime := util:system-dateTime()
    let $newNode := <entry xml:id="{$id}" dateTime="{$currentdateTime}" xmlns="http://xquery.weber-gesamtausgabe.de/modules/dev"/>
    let $storeNode := 
        if (config:get-doctype-by-id(substring($id, 2))) then update insert $newNode into $IDFile/dev:dictionary
        else error(xs:QName('dev:error'), 'got wrong ID: ' || $id)
    return 
        $IDFile//id($id)/string(@xml:id)
};

(:~
 : Remove old entries
 :
 : @author Peter Stadler
 : @param $IDFile
 : @return empty()
 :)

declare %private function dev:removeOldEntries($IDFile as document-node()) as empty() {
    let $currentdateTime := util:system-dateTime()
    return 
        for $entry in $IDFile//dev:entry[@dateTime < ($currentdateTime - xs:dayTimeDuration('P10D'))]
        return 
            update delete $entry
};

(:~
 : Helper function for dev:createNewID()
 : Beware: There is no check whether it's even possible to get a new ID!
 : This must be taken care of by the calling function
 :
 : @author Peter Stadler 
 : @param $max
 : @param $coll1
 : @param $coll2
 : @return xs:string
 :)
declare %private function dev:getNewID($max as xs:integer, $coll1 as xs:string+, $coll2 as xs:string+) as xs:string {
    let $IDPrefix := substring($coll1[22], 1, 3) (: use a higher element diary summaries, e.g. diary_Weber_1817 :)
    let $rand := 
        if(config:is-person($coll1[22])) then dev:pad-hex-to-length(dev:int2hex(util:random($max)), 4)
        else functx:pad-integer-to-length(util:random($max), 4)
    let $newID := concat($IDPrefix, $rand)
    return 
        if ($newID = ($coll1, $coll2)) then dev:getNewID($max, $coll1, $coll2)
        else $newID  
};

declare %private function dev:create-empty-idfile($docType as xs:string, $IDFileURI as xs:string) as element(dev:dictionary) {
    if(doc-available($IDFileURI)) then doc($IDFileURI)/dev:dictionary (: preserve entries over db updates :)
    else <dictionary xml:id="{concat($docType, '-tmpIDs')}" xmlns="http://xquery.weber-gesamtausgabe.de/modules/dev"/>
};

declare %private variable $dev:int2hex as map() := map {
    '0' := '0',
    '1' := '1',
    '2' := '2',
    '3' := '3',
    '4' := '4',
    '5' := '5', 
    '6' := '6',
    '7' := '7',
    '8' := '8',
    '9' := '9',
    '10' := 'A',
    '11' := 'B',
    '12' := 'C',
    '13' := 'D',
    '14' := 'E',
    '15' := 'F'
};

declare %private function dev:int2hex($number as xs:int) as xs:string {
    let $div := $number div 16
    let $count := floor($div)
    let $remainder := ($div - $count) * 16
    return
        concat(
            if($count gt 15) then dev:int2hex($count)
            else $dev:int2hex($count),
            $dev:int2hex($remainder)
        )
};

declare %private function dev:pad-hex-to-length($stringToPad as xs:string?, $length as xs:integer) as xs:string {
    if ($length lt string-length($stringToPad)) then error(xs:QName('dev:Hex_Longer_Than_Length'))
    else concat(
            functx:repeat-string('0', $length - string-length($stringToPad)),
            $stringToPad
        )
};
