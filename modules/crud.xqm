xquery version "3.1";

(:~
 : CRUD functions of the WeGA-WebApp
 :)
module namespace crud="http://xquery.weber-gesamtausgabe.de/modules/crud";
declare default collation "?lang=de;strength=primary";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
(:declare namespace request="http://exist-db.org/xquery/request";:)
declare namespace xmldb="http://exist-db.org/xquery/xmldb";
(:declare namespace util="http://exist-db.org/xquery/util";:)

import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util" at "wega-util.xqm";
(:import module namespace wdt="http://xquery.weber-gesamtausgabe.de/modules/wdt" at "wdt.xqm";:)
(:import module namespace mycache="http://xquery.weber-gesamtausgabe.de/modules/cache" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/cache.xqm";:)
(:import module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/date.xqm";:)
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/str.xqm";

(:~
 : Get document by ID
 : This function will also resolve duplicates
 :
 : @author Peter Stadler
 : @param $docID the ID of the document
 : @return the document node of the resource found for the specified ID
:)
declare function crud:doc($docID as xs:string) as document-node()? {
    let $collectionPath := config:getCollectionPath($docID)
    let $docURL := str:join-path-elements(($collectionPath, $docID)) || '.xml'
    return 
        if(doc-available($docURL)) then
            let $doc := doc($docURL) 
            return
                if($doc/*/*:ref/@target) then crud:doc($doc/*/*:ref/@target)
                else $doc
        else if($config:isDevelopment) then wega-util:log-to-file('debug', 'crud:doc(): unable to open ' || $docID)
        else ()
};

(:~
 : Returns collection from the WeGA-data library
 : In contrast to core:getOrCreateColl() this function will return *all* documents from the specified collection, i.e. with all duplicates
 :
 : @author Peter Stadler
 : @param $collectionName the name of the collection
 : @return document-node()*
 :)
declare function crud:data-collection($collectionName as xs:string) as document-node()* {
    let $collectionPath := str:join-path-elements(($config:data-collection-path, $collectionName)) 
    let $collectionPathExists := xmldb:collection-available($collectionPath) and ($collectionPath ne '')
    return 
        if ($collectionPathExists) then collection($collectionPath)
        else ()
};
