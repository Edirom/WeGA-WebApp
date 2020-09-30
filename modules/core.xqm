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

import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace crud="http://xquery.weber-gesamtausgabe.de/modules/crud" at "crud.xqm";
import module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util" at "wega-util.xqm";
import module namespace wdt="http://xquery.weber-gesamtausgabe.de/modules/wdt" at "wdt.xqm";
import module namespace mycache="http://xquery.weber-gesamtausgabe.de/modules/cache" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/cache.xqm";
import module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/date.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/str.xqm";

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
    case 'letters' case 'writings' case 'documents' return 
        for $doc in crud:data-collection($docType)//tei:TEI[ft:query(., (), map { "fields": ("date") })]
        order by ft:field($doc, 'date')
        return
            if(ft:field($doc, 'date')) then ()
            else $doc/root()
    default return ()
};
