xquery version "3.1" encoding "UTF-8";

(:~
 : WeGA API XQuery-Module
 :
 : @author Peter Stadler 
 : @version 1.0
 :)
 
module namespace api="http://xquery.weber-gesamtausgabe.de/modules/api";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace facets="http://xquery.weber-gesamtausgabe.de/modules/facets" at "facets.xqm";
import module namespace search="http://xquery.weber-gesamtausgabe.de/modules/search" at "search.xqm";
import module namespace wdt="http://xquery.weber-gesamtausgabe.de/modules/wdt" at "wdt.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";
import module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util" at "wega-util.xqm";

declare variable $api:WRONG_PARAMETER := QName("http://xquery.weber-gesamtausgabe.de/modules/api", "ParameterError");

declare function api:documents($model as map()) {
    let $wega-docTypes := for $func in wdt:members('indices') return $func(())('name')
    let $ids := 
        if($model('docType') = $wega-docTypes) then core:getOrCreateColl($model('docType'), 'indices', true())
        else if($model('docType')) then error($api:WRONG_PARAMETER, 'There is no document type "' || $model('docType') || '"')
        else for $docType in $wega-docTypes return core:getOrCreateColl($docType, 'indices', true())
    return
        api:document(api:subsequence($ids, $model), $model)
};

(:http://localhost:8080/exist/apps/WeGA-WebApp/dev/api.xql?works=A020062&fromDate=1798-10-10&toDate=1982-06-08&func=facets&format=json&facet=persons&docID=indices&docType=writings:)
(:http://localhost:8080/exist/apps/WeGA-WebApp/dev/api.xql?&fromDate=1801-01-15&toDate=1982-06-08&func=facets&format=json&facet=places&docID=A002068&docType=writings:)
declare function api:facets($model as map()) {
    let $search := search:results(<span/>, map { 'docID' := $model('docID') }, tokenize($model(exist:resource), '/')[last() -2])
    return 
        facets:facets($search?search-results, $model('facet'), -1, 'de')
};

declare function api:documents-findByDate($model as map()) {
    let $wega-docTypes := for $func in wdt:members('indices') return $func(())('name')
    let $documents := 
        if($model('docType') = $wega-docTypes) then 
            core:getOrCreateColl($model('docType'), 'indices', true())/tei:ab[@n=$model('date')]/root() |
            core:getOrCreateColl($model('docType'), 'indices', true())//tei:date[@when=$model('date')]/root() |
            core:getOrCreateColl($model('docType'), 'indices', true())//mei:date[@isodate=$model('date')]/root()
        else if($model('docType')) then error($api:WRONG_PARAMETER, 'There is no document type "' || $model('docType') || '"')
        else for $docType in $wega-docTypes return 
            core:getOrCreateColl($docType, 'indices', true())/tei:ab[@n=$model('date')]/root() |
            core:getOrCreateColl($docType, 'indices', true())//tei:date[@when=$model('date')]/root() |
            core:getOrCreateColl($docType, 'indices', true())//mei:date[@isodate=$model('date')]/root()
    return
        api:document(api:subsequence($documents, $model), $model)
};

(:~
 :  Find document by ID.
 :  IDs are accepted in the following formats:
 :  * WeGA, e.g. A002068 or http://weber-gesamtausgabe.de/A002068
 :  * VIAF, e.g. http://viaf.org/viaf/310642461
 :  * GND, e.g. http://d-nb.info/gnd/118629662
~:)
declare function api:findByID($model as map()) {
    if(matches(normalize-space($model?id), '^A[A-F0-9]{6}$')) then api:document(core:doc($model?id), $model)
    else if(matches(normalize-space($model?id), '^https?://weber-gesamtausgabe\.de/A[A-F0-9]{6}$')) then api:document(core:doc(substring-after($model?id, 'de/')), $model)
    else if(starts-with(normalize-space($model?id), 'http://d-nb.info/gnd/')) then api:document(query:doc-by-gnd(substring($model?id, 22)), $model)
    else if(starts-with(normalize-space($model?id), 'http://viaf.org/viaf/')) then api:document(query:doc-by-gnd(wega-util:viaf2gnd(substring($model?id, 22))), $model)
    else util:log-system-out('no match')
};

declare function api:ant-currentSvnRev($model as map()) as xs:int? {
    config:getCurrentSvnRev()
};

declare function api:ant-deleteResources($model as map()) {
    ()
    (:
    for $path in tokenize(normalize-space(util:binary-to-string($model('data'))), '\s+')
    let $fullPathResource:= local:get-resource-path($path)
    let $fullPathCollection := local:get-collection-path($path)
    return 
        if(count(($fullPathCollection, $fullPathResource)) eq 1) then
            if($fullPathResource) then xmldb:remove(functx:substring-before-last($fullPathResource, '/'), functx:substring-after-last($fullPathResource, '/'))
            else xmldb:remove($fullPathCollection)
        else if(count(($fullPathCollection, $fullPathResource)) eq 0) then core:logToFile('info', 'Resource ' || $path || ' not available')
        else error(QName('wega','error'), 'ambigious delete target: ' || $path)
    :)
};

declare function api:ant-patchSvnHistory($model as map()) as map()? {
    if($model('data')/*/@head castable as xs:integer) then (
        update value $config:svn-change-history-file/dictionary/@head with $model('data')/*/data(@head),
        for $entry in $model('data')//entry
        let $id := $entry/data(@xml:id)
        let $old := $config:svn-change-history-file//id($id)
        return 
            if($old) then update replace $old with $entry
            else update insert $entry into $config:svn-change-history-file/dictionary
        )
    else map {'code' := 400, 'message' := 'could not parse XML fragment', 'fields' := 'invalid format'}
};

(:~
 :  Helper function for creating a subsequence based on external parameters
~:)
declare %private function api:subsequence($seq as item()*, $model as map()) {
    let $skip := if($model('skip') castable as xs:integer) then $model('skip') cast as xs:integer else 0
    let $limit := if($model('limit') castable as xs:integer) then $model('limit') cast as xs:integer else 0
    return
        if($skip gt 0 and $limit gt 0) then subsequence($seq, $skip, $limit)
        else if($skip gt 0) then subsequence($seq, $skip)
        else if($limit gt 0) then subsequence($seq, 1, $limit)
        else $seq
}; 

(:~
 :  Helper function for creating an URI for a resource
~:)
declare %private function api:document($documents as document-node()*, $model as map()) as map()* {
    let $host := $model('swagger:config')?host
    let $basePath := $model('swagger:config')?basePath
    let $scheme := $model('swagger:config')?schemes[1]
    return 
        for $doc in $documents
        let $id := $doc/*/data(@xml:id)
        let $docType := config:get-doctype-by-id($id)
        return
            map { 
                'uri' := $scheme || '://' || $host || substring-before($basePath, 'api') || $id,
                'title' := wdt:lookup($docType, $doc)('title')('txt')
            } 
};
