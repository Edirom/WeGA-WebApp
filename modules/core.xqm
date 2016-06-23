xquery version "3.1";

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
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "str.xqm";
import module namespace norm="http://xquery.weber-gesamtausgabe.de/modules/norm" at "norm.xqm";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";
import module namespace wdt="http://xquery.weber-gesamtausgabe.de/modules/wdt" at "wdt.xqm";
import module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util" at "wega-util.xqm";
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
    let $docURL := str:join-path-elements(($collectionPath, $docID)) || '.xml'
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
    let $collectionPath := str:join-path-elements(($config:data-collection-path, $collectionName)) 
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
            let $newIndex := 
                if($cacheKey eq 'indices') then wdt:lookup($collName, $newColl)('init-sortIndex')()
                else ()
            let $sortedColl := wdt:lookup($collName, $newColl)('sort')( map { 'personID' := $cacheKey} )
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
    let $func := 
        try { function-lookup(xs:QName('wdt:' || $collName), 1) }
        catch * { core:logToFile('error', 'core:createColl(): failed to lookup function "' || $collName || '"') }
    let $coll := $func(())('init-collection')()
    return
        if(config:is-person($cacheKey) or config:is-org($cacheKey)) then 
            $func($coll)('filter-by-person')($cacheKey)
        else if($cacheKey eq 'indices') then $coll
        else ()
};

(:~
 : Return the undated documents of a given document type
 :
 : @author Peter Stadler 
 : @param $docType the document type (e.g., letters, writings)
 : @return document-node()*
 :)
declare function core:undated($docType as xs:string) as document-node()* {
    let $norm-file := norm:get-norm-doc($docType)
    for $i in $norm-file//norm:entry[not(text())]
    return core:doc($i/@docID)
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
        if($config:isDevelopment and ($priority = ('error', 'warn', 'debug'))) then util:log-system-out($message)
        else ()
    )
};

(:~
 : Store some XML content as file in the db
 : (shortcut for the more generic 4arity version)
 : 
 : @author Peter Stadler
 : @param $collection the collection to put the file in. If empty, the content will be stored in tmp  
 : @param $fileName the filename of the to be created resource with filename extension
 : @param $contents the content to store. Must be a node 
 : @return Returns the path to the newly created resource, empty sequence otherwise
 :)
declare function core:store-file($collection as xs:string?, $fileName as xs:string, $contents as item()) as xs:string? {
    core:store-file($collection, $fileName, $contents, 'application/xml')
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
declare function core:store-file($collection as xs:string?, $fileName as xs:string, $contents as item(), $mime-type as xs:string) as xs:string? {
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
        try { xmldb:store($collection, $fileName, $contents, $mime-type) }
        catch * { core:logToFile('error', string-join(('core:store-file', $err:code, $err:description), ' ;; ')) }
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
    str:join-path-elements(('/', request:get-context-path(), request:get-attribute("$exist:prefix"), request:get-attribute('$exist:controller'), $relLink))
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
 : A caching function for documents (XML and binary)
 :
 : @author Peter Stadler
 : @param $docURI the database URI of the document
 : @param $callBack a function to create the document content when the document is outdated or not available
 : @param $lease an xs:dayTimeDuration value of how long the cache should persist, e.g. P999D (= 999 days)
 : @return the cached document
 :)
declare function core:cache-doc($docURI as xs:string, $callback as function() as item(), $callback-params as item()*, $lease as xs:dayTimeDuration?) {
    let $fileName := functx:substring-after-last($docURI, '/')
    let $collection := functx:substring-before-last($docURI, '/')
    let $currentDateTimeOfFile := 
        if(wega-util:doc-available($docURI)) then xmldb:last-modified($collection, $fileName)
        else if(util:binary-doc-available($docURI)) then xmldb:last-modified($collection, $fileName)
        else ()
    let $updateNecessary := 
        (: Aktualisierung entweder bei geänderter Datenbank oder bei veraltetem Cache :) 
        config:eXistDbWasUpdatedAfterwards($currentDateTimeOfFile) or $currentDateTimeOfFile + $lease lt current-dateTime()
        (: oder bei nicht vorhandener Datei oder nicht vorhandenem $lease:)
        or empty($lease) or empty($currentDateTimeOfFile)
    return 
	   if($updateNecessary) then (
            let $content := 
                if(count($callback-params) eq 0) then $callback()
                else if(count($callback-params) eq 1) then $callback($callback-params)
                else if(count($callback-params) eq 3) then $callback($callback-params[1], $callback-params[2], $callback-params[3])
                else if(count($callback-params) eq 2) then $callback($callback-params[1], $callback-params[2])
                else error(xs:QName('core:error'), 'Too many arguments to function callback')
            let $mime-type := wega-util:guess-mimeType-from-suffix(functx:substring-after-last($docURI, '.'))
            let $store-file := core:store-file($collection, $fileName, $content, $mime-type)
            let $logMessage := concat('core:cache-doc(): saved document ', $docURI)
            let $logToFile := core:logToFile('info', $logMessage)
            return 
                if(util:binary-doc-available($store-file)) then util:binary-doc($store-file)
                else if(wega-util:doc-available($store-file)) then doc($store-file) 
                else ()
        )
        else if(util:binary-doc-available($docURI)) then util:binary-doc($docURI)
        else if(wega-util:doc-available($docURI)) then doc($docURI)
        else ()
};
