xquery version "3.0" encoding "UTF-8";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";

import module namespace functx="http://www.functx.com";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "../config.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "../core.xqm";
(:import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace img="http://xquery.weber-gesamtausgabe.de/modules/img" at "img.xqm";
import module namespace norm="http://xquery.weber-gesamtausgabe.de/modules/norm" at "norm.xqm";:)

declare variable $local:wega-docTypes as xs:string+ := tokenize('biblio diaries iconography letters news persons places sources var works writings', '\s+');

declare function local:patch-subversion-history($patch as document-node()) {
    update value $config:svn-change-history-file/dictionary/@head with $patch/dictionary/data(@head),
    for $entry in $patch//entry
    let $id := $entry/data(@xml:id)
    let $old := $config:svn-change-history-file//id($id)
    return 
        if($old) then update replace $old with $entry
        else update insert $entry into $config:svn-change-history-file/dictionary
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
        else if(count(($fullPathCollection, $fullPathResource)) eq 0) then core:logToFile('info', 'Resource ' || $path || ' not available')
        else error(QName('wega','error'), 'ambigious delete target: ' || $path)
};

declare function local:get-resource-path($partialPath as xs:string) as xs:string* {
    for $docType in $local:wega-docTypes
    let $fullPath := core:join-path-elements(($config:data-collection-path, $docType, $partialPath))
    return 
        if(doc-available($fullPath)) then $fullPath
        else ()
};

declare function local:get-collection-path($partialPath as xs:string) as xs:string* {
    for $docType in $local:wega-docTypes
    let $fullPath := core:join-path-elements(($config:data-collection-path, $docType, $partialPath))
    return 
        if(xmldb:collection-available($fullPath)) then $fullPath
        else ()
};

declare function local:reindex($docType as xs:string) as xs:boolean {
    if($docType = $local:wega-docTypes) then xmldb:reindex(core:join-path-elements(($config:data-collection-path,$docType)))
    else false()
};

let $func := request:get-parameter('func', 'getCurrentSvnRev')
let $data := request:get-data() 
let $docType := request:get-parameter('docType', 'biblio')

return 
    switch($func)
    case 'getCurrentSvnRev' return config:getCurrentSvnRev()
    case 'patch-subversion-history' return local:patch-subversion-history($data)
    case 'delete-resources' return local:delete-resources($data)
    case 'reindex' return local:reindex($docType)
    default return error(QName('wega','error'), 'no function parameter given or wrong function name')
