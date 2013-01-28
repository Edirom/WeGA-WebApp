xquery version "1.0" encoding "UTF-8";

(:~
 : WeGA Development XQuery-Module
 :
 : @author Peter Stadler 
 : @version 1.0
 :)
 
module namespace dev="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/dev";
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
import module namespace functx="http://www.functx.com" at "xmldb:exist:///db/webapp/xql/modules/functx.xqm";
import module namespace wega="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/wega" at "xmldb:exist:///db/webapp/xql/modules/wega.xqm";

(:~
 : Show tools tab
 :
 : @author Peter Stadler 
 : @param $docType
 : @param $lang the current language
 : @return element
 :)
 
declare function dev:showToolsTab($docType as xs:string, $lang as xs:string) {
    <div>
        {if ($docType eq 'common') then ()
        else (
            element span {
                attribute id {'newID'},
                attribute style {'font-size:14px;margin:1em;display:block'},
                dev:createNewID($docType)
            }
        )
        }
    </div>
};

(:~
 : Add fffi entry
 :
 : @author Peter Stadler 
 : @param $IDFile 
 : @param $id
 : @return xs:string
 :)


declare function dev:addFffiEntry($IDFile as item(), $id as xs:string?) as xs:string {
    let $dateTime := util:system-dateTime()
    return if (matches($id, '_A0\d{5}')) 
        then (update insert <entry xml:id="{$id}" dateTime="{$dateTime}"/> into $IDFile/dictionary,
            string($IDFile//id($id)/@xml:id)) 
        else ''
};

(:~
 : Remove old entries
 :
 : @author Peter Stadler
 : @param $IDFile
 : @return empty()
 :)

declare function dev:removeOldEntries($IDFile as item()) as empty() {
    let $currentdateTime := util:system-dateTime()
(:    let $tempIDs := $IDFile//entry:)
    for $entry in $IDFile//entry
        let $date := xs:dateTime($entry/@dateTime)
        let $id := data($entry/@xml:id)
        return if($date lt ($currentdateTime - xs:dayTimeDuration('P10D')))
            then update delete $IDFile//id($id)
            else()
};

(:~
 : Get new ID
 :
 : @author Peter Stadler 
 : @param $max
 : @param $coll1
 : @param $coll2
 : @return xs:string
 :)

declare function dev:getNewID($max as xs:integer, $coll1 as xs:string+, $coll2 as xs:string+) as xs:string {
    let $IDPrefix := substring($coll1[1], 1, 3)
    let $rand := functx:pad-integer-to-length(util:random($max) + 1, 4)
    let $newID := concat($IDPrefix, $rand)
    return if ($newID = $coll1) 
        then dev:getNewID($max, $coll1, $coll2)
        else if ($newID = $coll2)  
            then dev:getNewID($max, $coll1, $coll2)
            else $newID  
};

(:~
 : Create new ID
 :
 : @author Peter Stadler 
 : @param $docType
 : @return xs:string
 :)

declare function dev:createNewID($docType as xs:string) as xs:string {
    let $tmpDir := wega:getOption('tmpDir')
    let $IDFileName := concat('tempIDs', $docType, '.xml')
    let $IDFile := 
        if(not(doc-available(concat($tmpDir, $IDFileName)))) then doc(xmldb:store($tmpDir, $IDFileName, <dictionary xml:id="{$IDFileName}"/>))
        else doc(concat($tmpDir, $IDFileName))
    let $coll1 := collection(wega:getOption($docType))/*/@xml:id
    let $coll2 := $IDFile//entry/substring(@xml:id, 2)
    let $removeOldTempIDS := dev:removeOldEntries($IDFile)
    let $maxID := 
        let $maxTemp := count($coll1) + count($coll2) + 200
        return 
            if ($docType eq 'persons') then max(($maxTemp,9000))
            else $maxTemp
    let $newID := 
        if ($maxID lt 9999) then dev:addFffiEntry($IDFile, concat('_', dev:getNewID($maxID, $coll1, $coll2)))
        else '_kein Eintrag verfügbar'

    return substring($newID, 2)
};

(:~
 : Validate IDs
 :
 : @author Peter Stadler 
 : @param $docType
 : @return element
 :)

declare function dev:validateIDs($docType as xs:string) as element() {
    let $goodKeys := util:eval(concat('collection("', wega:getOption($docType), '")', wega:getOption(concat($docType, 'PredIndices')), '/data(@xml:id)'))
    let $duplicateKeys := util:eval(concat('collection("', wega:getOption($docType), '")', replace(wega:getOption(concat($docType, 'PredIndices')), '\[not\((.+)\)\]', '[$1]'), '/data(@xml:id)'))
    let $col := collection('/db')
    let $elements := 
        if($docType eq 'persons') then ($col//tei:persName/@key | $col//tei:rs[matches(@type,'person')]/@key | $col//mei:persName/@dbkey)
        else if($docType eq 'letters') then ($col//tei:rs[matches(@type,'letter')]/@key)
        else if($docType eq 'works') then ($col//tei:workName/@key | $col//tei:rs[matches(@type,'work')]/@key)
        else ()

(:    return element div {count(distinct-values($elements))}:)
    return element div {
        for $element in distinct-values($elements)
        for $key in tokenize($element, '\s')
    
        return (
            if ($key = $goodKeys) then ()
            else(let $docIDs := $elements[. = $element]/root()/*/@xml:id | $elements[. = $key]/root()/*/@xml:id 
                return element li {concat('Falscher Key: ', $key, ' (in: ', string-join($docIDs, ', '), ')')})
        )
    }
};

(:~
 : Validate PNDs
 :
 : @author Peter Stadler 
 : @param $docType
 : @return element
 :)

declare function dev:validatePNDs($docType as xs:string) as element() {
    let $pnds := collection(wega:getOption('persons'))//tei:idno[@type='gnd']
    return element div {
        for $pnd in distinct-values($pnds)
        return (
            if (count($pnds[. = $pnd]) gt 1) then (
(:                let $docIDs := $elements[. = $element]/root()/*/@xml:id | $elements[. = $key]/root()/*/@xml:id :)
                element li {concat('Doppelte PND: ', $pnd(:, ' (in: ', string-join($docIDs, ', '), ')':))}
            )
            else()
        )
    }
};

(:~
 : Validate paths 
 :
 : @author Peter Stadler 
 : @param $docType
 : @return element
 :)

declare function dev:validatePaths($docType as xs:string) as element() {
    let $falseDocs := collection(wega:getOption($docType))[document-uri(.) ne concat(wega:getCollectionPath(./*/string(@xml:id)), '/', ./*/@xml:id, '.xml')]
    return element div {
        element ul {
            for $i in $falseDocs/document-uri(.)
            return element li {$i}
        }
    }
};
