xquery version "3.0" encoding "UTF-8";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace request="http://exist-db.org/xquery/request";

import module namespace functx="http://www.functx.com";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "../config.xqm";
import module namespace wdt="http://xquery.weber-gesamtausgabe.de/modules/wdt" at "../wdt.xqm";
import module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util" at "../wega-util.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/str.xqm";

declare variable $local:wega-docTypes as xs:string+ := for $func in wdt:members('unary-docTypes') return $func(())('name') (: = all supported docTypes :);

declare function local:patch-subversion-history($patch as document-node()) {
    if($patch/dictionary/@head castable as xs:integer) then (
        update value $config:svn-change-history-file/dictionary/@head with $patch/dictionary/data(@head),
        update value $config:svn-change-history-file/dictionary/@dateTime with $patch/dictionary/data(@dateTime),
        for $entry in $patch//entry
        let $id := $entry/data(@xml:id)
        let $old := $config:svn-change-history-file//id($id)
        return 
            if($old) then update replace $old with $entry
            else update insert $entry into $config:svn-change-history-file/dictionary
        )
    else ()
};

declare function local:delete-resources($data as xs:string) {
    (: <!-- Be warned: Deletions are not removed from the subversionHistory! --> :)
    for $path in tokenize(normalize-space(util:binary-to-string($data)), '\s+')
    let $fullPathResource:= local:get-resource-path($path)
    let $fullPathCollection := local:get-collection-path($path)
    return 
        if(count(($fullPathCollection, $fullPathResource)) eq 1) then
            if($fullPathResource) then xmldb:remove(functx:substring-before-last($fullPathResource, '/'), functx:substring-after-last($fullPathResource, '/'))
            else xmldb:remove($fullPathCollection)
        else if(count(($fullPathCollection, $fullPathResource)) eq 0) then wega-util:log-to-file('info', 'Resource ' || $path || ' not available')
        else error(QName('wega','error'), 'ambigious delete target: ' || $path)
};

declare function local:get-resource-path($partialPath as xs:string) as xs:string* {
    for $docType in $local:wega-docTypes
    let $fullPath := str:join-path-elements(($config:data-collection-path, $docType, $partialPath))
    return 
        if(doc-available($fullPath)) then $fullPath
        else ()
};

declare function local:get-collection-path($partialPath as xs:string) as xs:string* {
    for $docType in $local:wega-docTypes
    let $fullPath := str:join-path-elements(($config:data-collection-path, $docType, $partialPath))
    return 
        if(xmldb:collection-available($fullPath)) then $fullPath
        else ()
};

declare function local:reindex($docType as xs:string) as xs:boolean {
    if($docType = 'persons') then xmldb:reindex(str:join-path-elements(($config:data-collection-path,'persons'))) 
    else if($docType = 'orgs') then xmldb:reindex(str:join-path-elements(($config:data-collection-path,'orgs')))
    else if($docType = $local:wega-docTypes) then xmldb:reindex(str:join-path-elements(($config:data-collection-path,$docType)))
    else false()
};

let $data := request:get-data()
let $func := request:get-parameter('func', 'getCurrentSvnRev')
let $docType := request:get-parameter('docType', 'biblio')

return 
    switch($func)
    case 'getCurrentSvnRev' return config:getCurrentSvnRev()
    case 'patch-subversion-history' return local:patch-subversion-history($data)
    case 'delete-resources' return local:delete-resources($data)
    case 'reindex' return local:reindex($docType)
    default return error(QName('wega','error'), 'no function parameter given or wrong function name')
