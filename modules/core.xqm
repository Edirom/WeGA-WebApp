xquery version "3.1";

(:~
 : Core functions of the WeGA-WebApp
 :)
module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace ft="http://exist-db.org/xquery/lucene";

import module namespace functx="http://www.functx.com";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace crud="http://xquery.weber-gesamtausgabe.de/modules/crud" at "crud.xqm";
import module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util" at "wega-util.xqm";
import module namespace wdt="http://xquery.weber-gesamtausgabe.de/modules/wdt" at "wdt.xqm";
import module namespace mycache="http://xquery.weber-gesamtausgabe.de/modules/cache" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/cache.xqm";
import module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/date.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/str.xqm";
import module namespace m="http://xquery.weber-gesamtausgabe.de/modules/math" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/math.xqm";

(:~
 : Returns collection (from cache, if possible)
 : In contrast to crud:data-collection() this function will return the filtered (i.e. without duplicates) and sorted documents from the specified collection
 :
 : @author Peter Stadler
 : @param $collName
 : @param $cacheKey
 : @param $useCache
 : @return document-node()*
 :)
declare function core:getOrCreateColl($collName as xs:string, $cacheKey as xs:string, $useCache as xs:boolean) as document-node()* {
    let $lease := function($dateTimeOfCache) as xs:boolean {
        config:eXistDbWasUpdatedAfterwards($dateTimeOfCache) and $useCache
    }
    let $onFailure := function($errCode as item(), $errDesc as item()?) {
        wega-util:log-to-file('error', concat($errCode, ': ', $errDesc))
    }
    let $callBack := function() {
        if($collName eq 'diaries' and not($cacheKey = ('indices', 'A002068'))) then () (: Suppress the creation of diary collections for others than Weber :)
        else
            let $newColl := core:createColl($collName,$cacheKey)
            let $newIndex := 
                if($cacheKey eq 'indices') then wdt:lookup($collName, $newColl)('init-sortIndex')()
                else ()
            let $sortedColl := wdt:lookup($collName, $newColl)('sort')( map { 'personID' : $cacheKey} )
            (:let $log := wega-util:log-to-file('debug', 'Creating collection' || $collName || ': ' || $cacheKey):)
            return $sortedColl
    }
    return
        (: Do not cache all collections. This will result in too much memory consumption :)
        if($cacheKey = ('indices', 'A002068', 'A130001', 'A130002', 'A000213', 'A130003', 'A000914', 'A020040', 'A130004', 'A130005', 'A130006', 'A001002', 'A002078', 'A020043', 'A002160', 'A002085')) then mycache:collection($collName || $cacheKey, $callBack, $lease, $onFailure)
        else $callBack()
};

(:~
 : helper function for core:getOrCreateColl
 :
 : @author Peter Stadler
 : @param $collName
 : @param $cacheKey
 : @return document-node()*
 :)
declare %private function core:createColl($collName as xs:string, $cacheKey as xs:string) as document-node()* {
    if($cacheKey eq 'indices') then wdt:lookup($collName, ())('init-collection')()
    else if($collName eq 'backlinks') then wdt:backlinks(())('filter-by-person')($cacheKey)
    else wdt:lookup($collName, core:getOrCreateColl($collName, 'indices', true()))('filter-by-person')($cacheKey)
};

(:~
 : Return the undated documents of a given document type
 :
 : @author Peter Stadler 
 : @param $docType the document type (e.g., letters, writings)
 : @return document-node()*
 :)
declare function core:undated($docType as xs:string) as document-node()* {
    switch($docType)
    case 'letters' case 'writings' case 'documents' return crud:data-collection($docType)/tei:TEI[ft:query(., 'date:undated')][not(tei:ref)]/root()
    default return ()
};

declare function core:index-keys-for-field($coll as document-node()*, $field as xs:string) as xs:string* {
    distinct-values(
        for $i in $coll/tei:TEI[ft:query(., (), map { "fields": $field })] | $coll/tei:ab[ft:query(., (), map { "fields": $field })] | $coll/tei:biblStruct[ft:query(., (), map { "fields": $field })]
        return
            ft:field($i, $field)
    )
};

(:~
 : Create a random new ID
 : New IDs are cached and blocked for 2 weeks before they get back into the pool. 
 :
 : @param $docType the document type (e.g., letters, writings)
 : @return new ID
 :)
declare function core:create-new-ID($docType as xs:string) as xs:string? {
    let $IDFileName := concat($docType, '-tmpIDs.xml')
    let $IDFileURI := str:join-path-elements(($config:tmp-collection-path, $IDFileName))
    let $onFailureFunc := function($errCode, $errDesc) {
        wega-util:log-to-file('warn', string-join(($errCode, $errDesc), ' ;; '))
    }
    let $IDFile := mycache:doc($IDFileURI, core:create-empty-idfile#2, ($docType, $IDFileURI), xs:dayTimeDuration('P1D'), $onFailureFunc)
    let $coll1 := crud:data-collection($docType)/* ! substring(./@xml:id, 4) (: core:getOrCreateColl() geht nicht, da hier auch die Dubletten mit berücksichtigt werden müssen! :)
    let $coll2 := $IDFile//core:entry ! substring(./@xml:id, 5)
    let $removeOldTempIDS := core:remove-old-entries-from-idfile($IDFile)
    let $max := count($coll1) + count($coll2) + 200
    let $exceptions := 
        switch($docType)
        case 'persons' return ($coll1, $coll2) ! m:hex2int(.)
        default return ($coll1, $coll2)
    let $rand := core:random-ID($max, $exceptions)
    let $prefix := wdt:lookup($docType, ())?prefix
    let $newID := 
        if ($rand and $max lt 65535) then 
            switch($docType)
            case 'persons' return core:add-new-entry-to-idfile($IDFile, concat('_', $prefix, m:int2hex($rand, 4)))
            default return core:add-new-entry-to-idfile($IDFile, concat('_', $prefix, functx:pad-integer-to-length($rand, 4)))
        else ()

    return 
        if($newID) then substring($newID, 2)
        else ()
};

(:~
 : Create an empty IDfile 
 : Helper function for core:create-new-ID()
 :
 : @param $docType
 : @param $IDFileURI
 :)
declare %private function core:create-empty-idfile($docType as xs:string, $IDFileURI as xs:string) as element(core:dictionary) {
    if(doc-available($IDFileURI)) then doc($IDFileURI)/core:dictionary (: preserve entries over db updates :)
    else <dictionary xml:id="{concat($docType, '-tmpIDs')}" xmlns="http://xquery.weber-gesamtausgabe.de/modules/core"/>
};

(:~
 : Add new ID entry to IDfile
 :
 : @param $IDFile 
 : @param $id
 : @return xs:string
 :)
declare %private function core:add-new-entry-to-idfile($IDFile as document-node(), $id as xs:string?) as xs:string? {
    let $currentdateTime := util:system-dateTime()
    let $newNode := <entry xml:id="{$id}" dateTime="{$currentdateTime}" xmlns="http://xquery.weber-gesamtausgabe.de/modules/core"/>
    let $storeNode := 
        try { update insert $newNode into $IDFile/core:dictionary }
        catch * { wega-util:log-to-file('error', 'core:add-new-entry-to-idfile(): failed to write ID "' || $id || '" to file') }
    return 
        $IDFile//id($id)/data(@xml:id)
};

(:~
 : Remove old entries from IDfile
 : Helper function for core:create-new-ID()
 :
 : @param $IDFile
 : @return 
 :)
declare %private function core:remove-old-entries-from-idfile($IDFile as document-node()) as empty-sequence() {
    let $currentdateTime := util:system-dateTime()
    return 
        for $entry in $IDFile//core:entry[@dateTime < ($currentdateTime - xs:dayTimeDuration('P10D'))]
        return 
            update delete $entry
};

(:~
 : Create a random number
 : Helper function for core:create-new-ID()
 :
 : @param $max the maximum value for the new ID
 : @param $exceptions a sequence of forbidden numbers 
 : @return 
 :)
declare %private function core:random-ID($max as xs:int, $exceptions as xs:int*) as xs:int? {
    if(count(distinct-values($exceptions)[. lt $max]) ge $max) then wega-util:log-to-file('warn', 'core:random-ID(): Failed to create a random ID')
    else 
        let $newID := util:random($max)
        return 
            if ($newID = $exceptions) then core:random-ID($max, $exceptions)
            else $newID  
};
