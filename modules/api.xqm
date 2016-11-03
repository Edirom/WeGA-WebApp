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
                'title' := wdt:lookup($docType, $doc)('title')()
            } 
};
