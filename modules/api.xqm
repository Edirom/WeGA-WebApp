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
declare variable $api:UNSUPPORTED_ID_SCHEMA := QName("http://xquery.weber-gesamtausgabe.de/modules/api", "UnsupportedIDSchema");

declare function api:documents($model as map()) {
    let $test-input := api:validateInput($model)
    let $wega-docTypes := for $func in wdt:members('indices') return $func(())('name')
    let $ids :=
        if($model('docID')) then api:findByID(xmldb:decode-uri($model('docID')))
        else if($model('docType')) then for $docType in tokenize($model('docType'),',') return core:getOrCreateColl($docType, 'indices', true())
        else for $docType in $wega-docTypes return core:getOrCreateColl($docType, 'indices', true())
    return
        api:document(api:subsequence($ids, $model), $model)
};

(:http://localhost:8080/exist/apps/WeGA-WebApp/dev/api.xql?works=A020062&fromDate=1798-10-10&toDate=1982-06-08&func=facets&format=json&facet=persons&docID=indices&docType=writings:)
(:http://localhost:8080/exist/apps/WeGA-WebApp/dev/api.xql?&fromDate=1801-01-15&toDate=1982-06-08&func=facets&format=json&facet=places&docID=A002068&docType=writings:)
(:declare function api:facets($model as map()) {
    let $search := search:results(<span/>, map { 'docID' := $model('docID') }, tokenize($model(exist:resource), '/')[last() -2])
    return 
        facets:facets($search?search-results, $model('facet'), -1, 'de')
};
:)

declare function api:documents-findByDate($model as map()) {
    let $test-input := api:validateInput($model)
    let $wega-docTypes := for $func in wdt:members('indices') return $func(())('name')
    let $documents := 
        if($model('docType')) then for $docType in tokenize($model('docType'),',') return query:exact-date(xs:date($model('date')), $docType)
        else for $docType in $wega-docTypes return query:exact-date(xs:date($model('date')), $docType)
    return
        api:document(api:subsequence($documents, $model), $model)
};

declare function api:documents-findByMention($model as map()) {
    let $test-input := api:validateInput($model)
    let $mentioned-doc := api:findByID($model('docID'))
    let $wega-docTypes := for $func in wdt:members('indices') return $func(())('name')
    let $requested-docTypes := 
        if($model('docType')) then tokenize($model('docType'),',')
        else $wega-docTypes
    let $backlinks :=core:getOrCreateColl('backlinks', $mentioned-doc/*/data(@xml:id), true())
    let $documents := 
        for $docType in $requested-docTypes[. = $wega-docTypes]
        return wdt:lookup($docType, $backlinks)('filter')()
    return
        api:document(api:subsequence($documents, $model), $model)
};

declare function api:documents-findByAuthor($model as map()) {
    let $author := api:findByID($model('authorID'))
    let $wega-docTypes := for $func in wdt:members('indices') return $func(())('name')
    let $requested-docTypes := 
        if($model('docType')) then tokenize($model('docType'),',')
        else $wega-docTypes
    let $documents := 
        for $docType in $requested-docTypes[. = $wega-docTypes]
        return core:getOrCreateColl($docType, $author/tei:person/data(@xml:id), true())
    return
        api:document(api:subsequence($documents, $model), $model)
};

declare function api:code-findByElement($model as map()) {
    let $test-input := if(matches($model('element'), '^[-a-zA-Z]+$')) then () else error($api:WRONG_PARAMETER, 'Unsupported element name "' || $model('element') || '"')
    let $wega-docTypes := for $func in wdt:members('indices') return $func(())('name')
    let $requested-docTypes := 
        if($model('docType')) then tokenize($model('docType'),',')
        else $wega-docTypes
    let $documents := 
        for $docType in $requested-docTypes[. = $wega-docTypes]
        return core:getOrCreateColl($docType,'indices', true())
    let $ns-prefix := 
        switch($model('namespace'))
        case 'http://www.music-encoding.org/ns/mei' return 'mei'
        case 'http://www.tei-c.org/ns/1.0' return 'tei'
        default return () 
    let $eval := 
        if($ns-prefix) then util:eval('$documents//' || $ns-prefix || ':' || $model('element')) (: TEI or MEI elements :)
        else if($model('namespace')) then util:eval('$documents//*:' || $model('element') || '[namespace-uri()=' || $model('namespace') || ']') (: other namespaces :)
        else util:eval('$documents//' || $model('element')) (: empty namespace :)
    return
        api:codeSample(api:subsequence($eval, $model), $model)
};

(:~
 :  Find document by ID.
 :  IDs are accepted in the following formats:
 :  * WeGA, e.g. A002068 or http://weber-gesamtausgabe.de/A002068
 :  * VIAF, e.g. http://viaf.org/viaf/310642461
 :  * GND, e.g. http://d-nb.info/gnd/118629662
~:)
declare %private function api:findByID($id as xs:string) as document-node()* {
    if(matches(normalize-space($id), '^A[A-F0-9]{6}$')) then core:doc($id)
    else if(matches(normalize-space($id), '^https?://weber-gesamtausgabe\.de/A[A-F0-9]{6}$')) then core:doc(substring-after($id, 'de/'))
    else if(starts-with(normalize-space($id), 'http://d-nb.info/gnd/')) then query:doc-by-gnd(substring($id, 22))
    else if(starts-with(normalize-space($id), 'http://viaf.org/viaf/')) then query:doc-by-gnd(wega-util:viaf2gnd(substring($id, 22)))
    else error($api:UNSUPPORTED_ID_SCHEMA, 'Failed to recognize ID schema for "' || $id || '"')
};

(:
declare function api:ant-currentSvnRev($model as map()) as xs:int? {
    config:getCurrentSvnRev()
};

declare function api:ant-deleteResources($model as map()) {
    ()
    (\:
    for $path in tokenize(normalize-space(util:binary-to-string($model('data'))), '\s+')
    let $fullPathResource:= local:get-resource-path($path)
    let $fullPathCollection := local:get-collection-path($path)
    return 
        if(count(($fullPathCollection, $fullPathResource)) eq 1) then
            if($fullPathResource) then xmldb:remove(functx:substring-before-last($fullPathResource, '/'), functx:substring-after-last($fullPathResource, '/'))
            else xmldb:remove($fullPathCollection)
        else if(count(($fullPathCollection, $fullPathResource)) eq 0) then core:logToFile('info', 'Resource ' || $path || ' not available')
        else error(QName('wega','error'), 'ambigious delete target: ' || $path)
    :\)
};
:)

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
        let $supportsHTML := $docType = ('letters', 'persons', 'diaries', 'writings', 'news', 'documents', 'thematicCommentaries')
        return
            map { 
                'uri' := $scheme || '://' || $host || substring-before($basePath, 'api') || $id,
                'docID' := $id,
                'docType' := $docType,
                'title' := wdt:lookup($docType, $doc)('title')('txt'),
                'supportedFormats' := ( 'xml', if($supportsHTML) then 'html' else ())
            } 
};

(:~
 :  Helper function for creating a CodeSample object 
~:)
declare %private function api:codeSample($nodes as node()*, $model as map()) as map()* {
    let $host := $model('swagger:config')?host
    let $basePath := $model('swagger:config')?basePath
    let $scheme := $model('swagger:config')?schemes[1]
    return 
        for $node in $nodes
        let $docID := $node/root()/*/data(@xml:id)
        return
            map { 
                'uri' := $scheme || '://' || $host || substring-before($basePath, 'api') || $docID,
                'docID' := $docID,
                'codeSample' := serialize(wega-util:remove-comments($node))
            }
};

(:~
 : Helper function for validating user input (= function parameters)
~:)
declare %private function api:validateInput($model as map()) as empty() {
    for $param in $model?*
    return
        switch($param)
        case 'docType' return api:check-docType($model)
        case 'element' return api:check-elementName($model)
        case 'date' return api:check-date($model)
        default return ()
};

(:~
 : Check docType
~:)
declare %private function api:check-docType($model as map()) as empty() {
    let $wega-docTypes := for $func in wdt:members('indices') return $func(())('name')
    let $requested-docTypes := tokenize($model('docType'),',')
    return 
        for $docType in $requested-docTypes
        return
            if($docType = $wega-docTypes) then ()
            else error($api:WRONG_PARAMETER, 'There is no document type "' || $model('docType') || '"')
};

(:~
 : Check element name
~:)
declare %private function api:check-elementName($model as map()) as empty() {
    if(matches($model('element'), '^[-a-zA-Z]+$')) then () 
    else error($api:WRONG_PARAMETER, 'Unsupported element name "' || $model('element') || '"')
};

(:~
 : Check date format
~:)
declare %private function api:check-date($model as map()) as empty() {
    if($model('date') castable as xs:date) then () 
    else error($api:WRONG_PARAMETER, 'Wrong date format given: "' || $model('date') || '". Should be YYYY-MM-DD.')
};
