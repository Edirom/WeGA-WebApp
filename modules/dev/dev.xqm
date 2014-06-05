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
import module namespace wega="http://xquery.weber-gesamtausgabe.de/modules/wega" at "../wega.xqm";
import module namespace facets="http://xquery.weber-gesamtausgabe.de/modules/facets" at "../facets.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "../config.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "../core.xqm";

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


declare function dev:addFffiEntry($IDFile as document-node(), $id as xs:string?) as xs:string {
    let $currentdateTime := util:system-dateTime()
    let $newNode := <entry xml:id="{$id}" dateTime="{$currentdateTime}" xmlns="http://xquery.weber-gesamtausgabe.de/modules/dev"/>
    let $storeNode := 
        if (matches($id, '_A\d{6}')) then update insert $newNode into $IDFile/dev:dictionary
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

declare function dev:removeOldEntries($IDFile as document-node()) as empty() {
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
    let $IDPrefix := substring($coll1[1], 1, 3)
    let $rand := functx:pad-integer-to-length(util:random($max) + 1, 4)
    let $newID := concat($IDPrefix, $rand)
    return 
        if ($newID = ($coll1, $coll2)) then dev:getNewID($max, $coll1, $coll2)
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
    let $IDFileName := concat($docType, '-tmpIDs.xml')
    let $IDFileURI := core:join-path-elements(($config:tmp-collection-path, $IDFileName))
    let $IDFile := core:cache-doc($IDFileURI, dev:create-empty-idfile#1, $docType, false())
    let $coll1 := core:data-collection($docType)/*/data(@xml:id) (: core:getOrCreateColl() geht nicht, da hier auch die Dubletten mit berücksichtigt werden müssen! :)
    let $coll2 := $IDFile//dev:entry/substring(@xml:id, 2)
    let $removeOldTempIDS := dev:removeOldEntries($IDFile)
    let $maxID := count($coll1) + count($coll2) + 200
    let $newID := 
        if ($maxID lt 9999) then dev:addFffiEntry($IDFile, concat('_', dev:getNewID($maxID, $coll1, $coll2)))
        else '_kein Eintrag verfügbar'

    return substring($newID, 2)
};

declare function dev:create-empty-idfile($docType as xs:string) as element() {
    <dictionary xml:id="{concat($docType, '-tmpIDs')}" xmlns="http://xquery.weber-gesamtausgabe.de/modules/dev"/>
};

(:~
 : Validate IDs
 :
 : @author Peter Stadler 
 : @param $docType
 : @return element
 :)

declare function dev:validateIDs($docType as xs:string) as element(div) {
    let $goodKeys := core:getOrCreateColl($docType, 'indices', true())(:/*/data(@xml:id):)
    let $col := collection($config:data-collection-path)
    let $elements := 
        if($docType eq 'persons') then ($col//tei:persName[@key] | $col//tei:editor[@key] | $col//tei:author[@key] | $col//tei:rs[matches(@type,'person')][@key] | $col//mei:persName[@dbkey])
        else if($docType eq 'letters') then ($col//tei:rs[matches(@type,'letter')][@key])
        else if($docType eq 'works') then ($col//tei:workName[@key] | $col//tei:rs[matches(@type,'work')][@key])
        else if($docType eq 'diaries') then ($col//tei:rs[matches(@type,'diary')][@key])
        else if($docType eq 'news') then ($col//tei:rs[matches(@type,'news')][@key])
        else if($docType eq 'writings') then ($col//tei:rs[matches(@type,'writing')][@key])
        else ()

(:    return element div {count(distinct-values($elements))}:)
    return element div {
        for $element in distinct-values($elements/@key | $elements/@dbkey)
        for $key in tokenize($element, '\s')
    
        return (
            if ($goodKeys//id($key)) then ()
            else (
                let $docIDs := $elements[contains(@key, $element)]/root()/*/@xml:id | $elements[contains(@dbkey, $element)]/root()/*/@xml:id 
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

declare function dev:validatePNDs($docType as xs:string) as element(div) {
    let $coll := core:getOrCreateColl('persons', 'indices', true())
    return element div {
        for $pnd in distinct-values($coll//tei:idno[@type='gnd'])
        return (
            if ($coll//tei:idno[. = $pnd][@type='gnd'][2]) then (
                element li {concat('Doppelte PND: ', $pnd)}
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
    let $falseDocs := core:data-collection($docType)[document-uri(.) ne concat(config:getCollectionPath(./*/string(@xml:id)), '/', ./*/@xml:id, '.xml')]
    return element div {
        element ul {
            for $i in $falseDocs/document-uri(.)
            return element li {$i}
        }
    }
};
