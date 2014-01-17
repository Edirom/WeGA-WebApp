xquery version "3.0";

(:~
 : Core functions of the WeGA-WebApp
 :)
module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
(:import module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date" at "date.xqm";:)
import module namespace functx="http://www.functx.com";

(:~
 : Get document by ID
 :
 : @author Peter Stadler
 : @param $id the ID of the document
 : @return returns the document node of the resource found for the specified ID.
:)
declare function core:doc($docID as xs:string) as document-node()? {
    let $collectionPath := config:getCollectionPath($docID)
    return 
        if (exists($collectionPath)) then collection($collectionPath)//id($docID)/root() else ()
};

(:~
 : Returns collection (from cache, if possible)
 :
 : @author Peter Stadler
 : @param $collName
 : @param $cacheKey
 : @param $useCache
 : @return node*
 :)
declare function core:getOrCreateColl($collName as xs:string, $cacheKey as xs:string, $useCache as xs:boolean) as document-node()* {
    let $lastModKey := 'lastModDateTime'
    let $dateTimeOfCache := cache:get($collName, $lastModKey)
    let $collCached := cache:get($collName, $cacheKey)
    return
        if(exists($collCached) and not(config:eXistDbWasUpdatedAfterwards($dateTimeOfCache)) and $useCache)
        then 
            typeswitch($collCached)
            case xs:string return ()
            default return $collCached
        else
            let $newColl := core:createColl($collName,$cacheKey)
            let $sortedColl := core:sortColl($newColl)
            let $setCache := (cache:put($collName, $lastModKey, current-dateTime()),
                if(exists($newColl)) then cache:put($collName, $cacheKey, $sortedColl)
                else cache:put($collName, $cacheKey, 'empty'))
            let $logMessage := concat('core:getOrCreateColl(): created collection cache (',$cacheKey,') for ', $collName, ' (', count($newColl), ' items)')
            let $logToFile := core:logToFile('info', $logMessage)
            return $sortedColl
};

(:~
 : helper function for core:getOrCreateColl and search_getResults.xql
 :
 : @author Peter Stadler
 : @param $collName
 : @param $cacheKey
 : @return node*
 :)
declare function core:createColl($collName as xs:string, $cacheKey as xs:string) as document-node()* {
    let $collPath := string-join(($config:data-collection-path, $collName),'/') 
    let $collPathExists := xmldb:collection-available($collPath) and ($collPath ne '') and ($cacheKey ne '')
    let $isSupportedDiary := if($collName eq 'diaries') then $cacheKey eq 'indices' or $cacheKey eq 'A002068' else true()
    let $predicates :=  if(config:is-person($cacheKey)) then config:get-option(concat($collName, 'Pred'), $cacheKey)
        else config:get-option(concat($collName, 'PredIndices'))
    return if ($predicates ne '' and $collPathExists and $isSupportedDiary) then util:eval(concat('collection("', $collPath, '")', $predicates)) else()
};

(:~
 : Sort collection
 :
 : @author Peter Stadler 
 : @param $coll collection to be sorted
 : @return item*
 :)
declare function core:sortColl($coll as item()*) as item()* {
    if(config:is-person($coll[1]/tei:person/string(@xml:id)))            then for $i in $coll order by $i//tei:persName[@type = 'reg'] ascending return $i
    else if(config:is-letter($coll[1]/tei:TEI/string(@xml:id)))          then for $i in $coll order by date:getOneNormalizedDate($i//tei:dateSender/tei:date[1], false()) ascending, $i//tei:dateSender/tei:date[1]/@n ascending return $i
    else if(config:is-writing($coll[1]/tei:TEI/string(@xml:id)))         then for $i in $coll order by date:getOneNormalizedDate($i//tei:imprint/tei:date[1], false()) ascending return $i
    else if(config:is-diary($coll[1]/tei:ab/string(@xml:id)))            then for $i in $coll order by $i/tei:ab/xs:date(@n) ascending return $i
    else if(config:is-work($coll[1]/tei:TEI/string(@xml:id)))            then for $i in $coll order by $i//mei:seriesStmt/mei:title[@level='s']/xs:int(@n) ascending, $i//mei:altId[@type = 'WeV']/string(@subtype) ascending, $i//mei:altId[@type = 'WeV']/xs:int(@n) ascending, $i//mei:altId[@type = 'WeV']/string() ascending return $i
    else if(config:is-news($coll[1]/tei:TEI/string(@xml:id)))            then for $i in $coll order by $i//tei:publicationStmt/tei:date/xs:dateTime(@when) descending return $i
    else if(config:is-biblio($coll[1]/tei:biblStruct/string(@xml:id)))   then for $i in $coll order by date:getOneNormalizedDate($i//tei:imprint/tei:date, false()) descending return $i
    else $coll
};


(:~
 : Write log message to log file
 :
 : @author Peter Stadler
 : @param $priority to be used by util:log-app:  'error', 'warn', 'debug', 'info', 'trace'
 : @param $message to write
 : @return 
:)
declare function core:logToFile($priority as xs:string, $message as xs:string) as empty() {
    let $file := config:get-option('errorLogFile')
    let $message := concat($message, ' (rev. ', config:getCurrentSvnRev(), ')')
    return (
        util:log-app($priority, $file, $message),
        if($config:isDevelopment and ($priority = ('error', 'warn'))) then util:log-system-out($message)
        else ()
    )
};

(:~
 : Store some content as file in the db
 : (helper function for wega:grabExternalResource())
 : 
 : @author Peter Stadler
 : @param $collection the collection to put the file in. If empty, the content will be stored in the tmp  
 : @param $fileName the filename of the to be created resource with filename extension
 : @param $contents the content to store. Either a node, an xs:string, a Java file object or an xs:anyURI 
 : @return Returns the path to the newly created resource, empty sequence otherwise
 :)
declare function core:store-file($collection as xs:string?, $fileName as xs:string, $contents as item()) as xs:string? {
    let $collection := 
        if(empty($collection) or ($collection eq '')) then $config:tmp-collection-path
        else $collection
    let $createCollection := 
        for $coll in tokenize($collection, '/')
        let $parentColl := substring-before($collection, $coll)
        return 
            if(xmldb:collection-available($parentColl || '/' || $coll)) then ''
            else xmldb:create-collection($parentColl, $coll)
    return 
        util:catch(
            '*', 
            xmldb:store($collection, $fileName, $contents), 
            core:logToFile('error', string-join(('wega:storeFileInTmpCollection', $util:exception, $util:exception-message), ' ;; '))
        )
};

(:~ 
 : Print forename surname
 :
 : @author Peter Stadler
 : @return xs:string
 :)
declare function core:printFornameSurname($name as xs:string?) as xs:string? {
    let $clearName := normalize-space($name)
    return
        if(matches($clearName, ','))
        then normalize-space(string-join(reverse(tokenize($clearName, ',')), ' '))
        else $clearName
};

(:~
 : @author Peter Stadler
 : Recursive identity transform with changing of namespace for a given element.
 :
 : @author Peter Stadler
 : @param $element the source element 
 : @param $targetNamespace the new namespace for $element
 : @param $keepNamespaces an list of namespaces that shall not be changed
 : @return a cloned element within the target namespace
 :)
 
declare function core:change-namespace($element as element(), $targetNamespace as xs:string, $keepNamespaces as xs:string*) as element() {
    if(namespace-uri($element) = $keepNamespaces) then 
        element {node-name($element)}
            {$element/@*,
            for $child in $element/node()
            return 
                if ($child instance of element()) then core:change-namespace($child, $targetNamespace, $keepNamespaces)
                else $child
            }
  else element {QName($targetNamespace,local-name($element))}
            {$element/@*,
            for $child in $element/node()
            return 
                if ($child instance of element()) then core:change-namespace($child, $targetNamespace, $keepNamespaces)
                else $child}
};
