xquery version "3.0";

(:~
 : Core functions of the WeGA-WebApp
 :)
module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core";
declare default collation "?lang=de;strength=primary";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace request="http://exist-db.org/xquery/request";

import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date" at "date.xqm";
import module namespace functx="http://www.functx.com";
import module namespace cache="http://exist-db.org/xquery/cache" at "java:org.exist.xquery.modules.cache.CacheModule";

(:~
 : Get document by ID
 : The core:doc() function will also resolve duplicates
 :
 : @author Peter Stadler
 : @param $docID the ID of the document
 : @return returns the document node of the resource found for the specified ID.
:)
declare function core:doc($docID as xs:string) as document-node()? {
    let $collectionPath := config:getCollectionPath($docID)
    let $docURL := core:join-path-elements(($collectionPath, $docID)) || '.xml'
    return 
        if(doc-available($docURL)) then
            let $doc := doc($docURL) 
            return
                if($doc/tei:*/tei:ref/@target) then core:doc($doc/tei:*/tei:ref/@target)
                else $doc
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
declare function core:data-collection($collectionName as xs:string) as document-node()* {
    let $collectionPath := core:join-path-elements(($config:data-collection-path, $collectionName)) 
    let $collectionPathExists := xmldb:collection-available($collectionPath) and ($collectionPath ne '')
    return 
        if ($collectionPathExists) then collection($collectionPath)
        else ()
};

(:~
 : Returns collection (from cache, if possible)
 : In contrast to core:data-collection() this function will return the filtered (i.e. without duplicates) and sorted documents from the specified collection
 :
 : @author Peter Stadler
 : @param $collName
 : @param $cacheKey
 : @param $useCache
 : @return document-node()*
 :)
declare function core:getOrCreateColl($collName as xs:string, $cacheKey as xs:string, $useCache as xs:boolean) as document-node()* {
    let $dateTimeOfCache := cache:get($collName, 'lastModDateTime')
    let $collCached := cache:get($collName, $cacheKey)
    return
        if(exists($collCached) and not(config:eXistDbWasUpdatedAfterwards($dateTimeOfCache)) and $useCache) then
            typeswitch($collCached)
            case xs:string return ()
            default return $collCached
        else if($collName eq 'diaries' and not($cacheKey = ('indices', 'A002068'))) then () (: Suppress the creation of diary collections for others than Weber :)
        else
            let $newColl := core:createColl($collName,$cacheKey)
            let $sortedColl := core:sortColl($newColl)
            let $setCache := 
                (: Do not cache all collections. This will result in too much memory consumption :)
                if(count($sortedColl) gt 250) then core:put-cache($collName, $cacheKey, $sortedColl)
                else ()
            return $sortedColl
};

(:~
 : helper function for core:getOrCreateColl
 :
 : @author Peter Stadler
 : @param $cacheName the name of the cache
 : @param $cacheKey the key for the cache
 : @param $content the content to cache
 : @return item()*
 :)
declare %private function core:put-cache($cacheName as xs:string, $cacheKey as xs:string, $content as item()*) as item()* {
    let $logMessage := concat('core:put-cache(): created cache (',$cacheKey,') for ', $cacheName, ' (', count($content), ' items)')
    let $logToFile := core:logToFile('info', $logMessage)
    return (
        cache:put($cacheName, 'lastModDateTime', current-dateTime()),
        cache:put($cacheName, $cacheKey, $content)
    )
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
    let $rawCollection := core:data-collection($collName)
    let $predicates :=  
        if(config:is-person($cacheKey)) then config:get-option(concat($collName, 'Pred'), $cacheKey)
        else config:get-option(concat($collName, 'PredIndices'))
    return 
        if ($predicates and $rawCollection) then util:eval('$rawCollection' || $predicates) 
        else()
};

(:~
 : Sort collection
 :
 : @author Peter Stadler 
 : @param $coll collection to be sorted
 : @return the sorted collection
 :)
declare function core:sortColl($coll as item()*) as document-node()* {
    if(config:is-person($coll[1]/tei:person/string(@xml:id)))            then for $i in $coll order by core:create-sort-persname($i/tei:person) ascending return $i
    else if(config:is-letter($coll[1]/tei:TEI/string(@xml:id)))          then for $i in $coll order by date:getOneNormalizedDate($i//tei:dateSender/tei:date[1], false()) ascending, $i//tei:dateSender/tei:date[1]/@n ascending return $i
    else if(config:is-writing($coll[1]/tei:TEI/string(@xml:id)))         then for $i in $coll order by date:getOneNormalizedDate($i//tei:imprint/tei:date[ancestor::tei:sourceDesc][1], false()) ascending return $i
    else if(config:is-diary($coll[1]/tei:ab/string(@xml:id)))            then for $i in $coll order by $i/tei:ab/xs:date(@n) ascending return $i
    else if(config:is-work($coll[1]/mei:mei/string(@xml:id)))            then for $i in $coll order by $i//mei:seriesStmt/mei:title[@level='s']/xs:int(@n) ascending, $i//mei:altId[@type = 'WeV']/string(@subtype) ascending, $i//mei:altId[@type = 'WeV']/xs:int(@n) ascending, $i//mei:altId[@type = 'WeV']/string() ascending return $i
    else if(config:is-news($coll[1]/tei:TEI/string(@xml:id)))            then for $i in $coll order by $i//tei:publicationStmt/tei:date/xs:dateTime(@when) descending return $i
    else if(config:is-biblio($coll[1]/tei:biblStruct/string(@xml:id)))   then core:sort-by-imprint-date-descending($coll)
    else $coll
};

(:~
 : Helper function for core:sortColl()
 : Sorts by imprint date descending and puts undated at the end
 :
 : @author Peter Stadler 
 : @param $coll collection to be sorted
 : @return the sorted collection
 :)
declare %private function core:sort-by-imprint-date-descending($coll as document-node()*) as document-node()* {
    for $i in $coll
    let $normDate := date:getOneNormalizedDate($i//tei:imprint[1]/tei:date[1], false())
    let $orderDate := if($normDate) then $normDate else '-9999-01-01'
    order by xs:date($orderDate) descending
    return 
        $i
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
 : @param $collection the collection to put the file in. If empty, the content will be stored in tmp  
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
        try { xmldb:store($collection, $fileName, $contents) }
        catch * { core:logToFile('error', string-join(('core:store-file', $err:code, $err:description), ' ;; ')) }
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

(:~
 : Serves as a shortcut to templates:link-to-app()
 : The assumed context is the current app
 :
 : @author Peter Stadler
 : @param $relLink a relative path to be added to the returned path
 : @return the complete URL for $relLink
 :)
declare function core:link-to-current-app($relLink as xs:string?) as xs:string {
(:    templates:link-to-app($config:expath-descriptor/@name, $relLink):)
    core:join-path-elements(('/', request:get-context-path(), request:get-attribute("$exist:prefix"), request:get-attribute('$exist:controller'), $relLink))
};

(:~
 : Joins path elements with a forward slash
 : In addition to string-join this function also takes care of double slashes
 :
 : @author Peter Stadler
 : @param $segs the path elements to join
 : @return the joined path as xs:string, the empty string when $segs was the empty sequence
 :)
declare function core:join-path-elements($segs as xs:string*) as xs:string {
    replace(string-join($segs, '/'), '/+' , '/')
};

(:~
 : Creates a sortname for a given tei:person element
 : This will be the first tei:surname, if none given it falls back to the substring before the comma 
 :
 : @author Peter Stadler
 : @param $person the tei:person element
 : @return xs:string
 :)
declare function core:create-sort-persname($person as element(tei:person)) as xs:string {
    if(functx:all-whitespace($person/tei:persName[@type='reg']/tei:surname[1])) then core:normalize-space(functx:substring-before-match($person/tei:persName[@type='reg'], '\s?,'))
    else core:normalize-space($person/tei:persName[@type='reg']/tei:surname[1])
};

(:~
 : Normalizes a given string
 : In addition to fn:normalize-space() this function treats non-breaking-spaces etc. as whitespace 
 :
 : @author Peter Stadler
 : @param $string the string to normalize
 : @return xs:string
 :)
declare function core:normalize-space($string as xs:string?) as xs:string {
    normalize-space(replace($string, '&#160;|&#8194;|&#8195;|&#8201;|[\.,]\s*$', ' '))
};

(:~
 : Creates a permalink for a given ID
 :
 : @author Peter Stadler
 : @param $docID the ID of the document
 : @return xs:string
 :)
declare function core:permalink($docID as xs:string) as xs:anyURI? {
    xs:anyURI(config:get-option('permaLinkPrefix') || core:link-to-current-app($docID))
};

(:~
 : A simple caching function for XML documents
 :
 : @author Peter Stadler
 : @param $docURI the database URI of the document
 : @param $callBack a function to create the document content when the document is outdated or not available
 : @param $overwrite force an overwrite of the given document
 : @return the cached document
 :)
declare function core:cache-doc($docURI as xs:string, $callback as function() as element(), $callback-params as item()*, $overwrite as xs:boolean) as document-node()? {
    let $fileName := functx:substring-after-last($docURI, '/')
    let $collection := functx:substring-before-last($docURI, '/')
    let $currentDateTimeOfFile := 
        if(doc-available($docURI)) then xmldb:last-modified($collection, $fileName)
        else ()
    let $updateNecessary := typeswitch($currentDateTimeOfFile) 
	   case xs:dateTime return config:eXistDbWasUpdatedAfterwards($currentDateTimeOfFile)
	   default return true()
	return 
	   if($updateNecessary or $overwrite) then (
            let $content := 
                if(count($callback-params) eq 0) then $callback()
                else if(count($callback-params) eq 1) then $callback($callback-params)
                else if(count($callback-params) eq 3) then $callback($callback-params[1], $callback-params[2], $callback-params[3])
                else if(count($callback-params) eq 2) then $callback($callback-params[1], $callback-params[2])
                else $callback($callback-params)
            let $logMessage := concat('core:cache-doc(): saved document ', $docURI)
            let $logToFile := core:logToFile('info', $logMessage)
            let $store-file := core:store-file($collection, $fileName, $content)
            return 
                if(doc-available($store-file)) then doc($store-file)
                else ()
        )
        else doc($docURI)
};
