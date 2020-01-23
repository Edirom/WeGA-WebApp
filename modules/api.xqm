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
import module namespace dev="http://xquery.weber-gesamtausgabe.de/modules/dev" at "dev/dev.xqm";
import module namespace functx="http://www.functx.com";

declare variable $api:INVALID_PARAMETER := QName("http://xquery.weber-gesamtausgabe.de/modules/api", "ParameterError");
declare variable $api:UNSUPPORTED_ID_SCHEMA := QName("http://xquery.weber-gesamtausgabe.de/modules/api", "UnsupportedIDSchema");

declare variable $api:max-limit := function($swagger-conf as map(*)) as xs:integer {
    $swagger-conf?parameters?limitParam?maximum
};

declare function api:documents($model as map()) as map()* {
    let $ids :=
        if(exists($model('docID'))) then api:findByID($model('docID'))
        else for $docType in api:resolve-docTypes($model) return core:getOrCreateColl($docType, 'indices', true())
    return (
        map { 'totalRecordCount': count($ids) },
        api:document(api:subsequence($ids, $model), $model)
    )
};

(:http://localhost:8080/exist/apps/WeGA-WebApp/dev/api.xql?works=A020062&fromDate=1798-10-10&toDate=1982-06-08&func=facets&format=json&facet=persons&docID=indices&docType=writings:)
(:http://localhost:8080/exist/apps/WeGA-WebApp/dev/api.xql?&fromDate=1801-01-15&toDate=1982-06-08&func=facets&format=json&facet=places&docID=A002068&docType=writings:)
(:declare function api:facets($model as map()) {
    let $search := search:results(<span/>, map { 'docID' : $model('docID') }, tokenize($model(exist:resource), '/')[last() -2])
    return 
        facets:facets($search?search-results, $model('facet'), -1, 'de')
};
:)

declare function api:documents-findByDate($model as map()) as map()* {
    let $documents := for $docType in api:resolve-docTypes($model) return wdt:lookup($docType, core:getOrCreateColl($docType, 'indices', true()))?filter-by-date($model?fromDate, $model?toDate)
    return (
        map { 'totalRecordCount': count($documents) },
        api:document(api:subsequence($documents, $model), $model)
    )
};

declare function api:documents-findByMention($model as map()) as map()* {
    let $mentioned-doc := api:findByID($model('docID'))
    let $backlinks := 
        if($mentioned-doc) 
        then core:getOrCreateColl('backlinks', $mentioned-doc/*/data(@xml:id), true())
        else ()
    let $documents := 
        for $docType in api:resolve-docTypes($model)
        return wdt:lookup($docType, $backlinks)('filter')()
    return (
        map { 'totalRecordCount': count($documents) },
        api:document(api:subsequence($documents, $model), $model)
    )
};

declare function api:documents-findByAuthor($model as map()) as map()* {
    let $author := api:findByID($model('authorID'))
    let $documents := 
        if($author)
        then ( 
            for $docType in api:resolve-docTypes($model)
            return core:getOrCreateColl($docType, $author/tei:person/data(@xml:id), true())
            )
        else ()
    return (
        map { 'totalRecordCount': count($documents) },
        api:document(api:subsequence($documents, $model), $model)
    )
};

declare function api:code-findByElement($model as map()) {
    let $documents := 
        for $docType in api:resolve-docTypes($model)
        return core:getOrCreateColl($docType,'indices', true())
    let $ns-prefix := 
        switch($model('namespace'))
        case 'http://www.music-encoding.org/ns/mei' return 'mei'
        case 'http://www.tei-c.org/ns/1.0' return 'tei'
        default return () 
    let $eval := 
        if($ns-prefix) then util:eval('$documents//' || $ns-prefix || ':' || $model('element')) (: TEI or MEI elements :)
        else if($model('namespace')) then util:eval('$documents//*:' || $model('element') || '[namespace-uri()="' || $model('namespace') || '"]') (: other namespaces :)
        else util:eval('$documents//' || $model('element')) (: empty namespace :)
    return
        (: NB: when searching for tei:facsimile empty code samples may be returned due to licensing issues :)
        if($model?total) then $eval
        (: The 'secret' $total switch is used for our list of examples on the spec pages and is of type element()*; 
            regular output from the API is the following subsequence of type map()* :)
        else (
            map { 'totalRecordCount': count($eval) },
            api:codeSample(api:subsequence($eval, $model), $model)
        )
};

declare function api:application-status($model as map()*) as map()* {
    let $healthy := query:facsimile(core:doc('A040043'))[tei:graphic/@url]
                    and core:getOrCreateColl('letters', 'A002068', true())//tei:seg[@type='wordOfTheDay']
    return
    (
        map:merge(( 
            map:entry('totalRecordCount', 1),
            if(not($healthy)) then map:entry('code', 500) else ()
        )),
        map {
            "status": if($healthy) then "healthy" else "unhealthy",
            "svnRevision": if (config:getCurrentSvnRev()) then config:getCurrentSvnRev() else 0,
            "deployment": xs:dateTime($config:repo-descriptor/repo:deployed),
            "version": config:expath-descriptor()/data(@version)
        }
    )
};

declare function api:application-newID($model as map(*)) as map()* {
    if($config:isDevelopment) 
    then (
        map { 'totalRecordCount': 1 },
        map {
            'docID': dev:createNewID($model?docType),
            'docType': $model?docType
        }
    )
    else 
        map {
            'code': 403, 
            'message': 'The creation of new IDs is only available in the development environment' 
        }
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
    else if(matches(normalize-space($id), 'https?://d-nb.info/gnd/')) then query:doc-by-gnd(substring-after($id, '/gnd/'))
    else if(matches(normalize-space($id), 'https?://viaf.org/viaf/')) then try { query:doc-by-gnd(wega-util:viaf2gnd(substring-after($id, '/viaf/'))) } catch * {()}
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

(:declare function api:ant-patchSvnHistory($model as map()) as map()? {
    if($model('data')/*/@head castable as xs:integer) then (
        update value $config:svn-change-history-file/dictionary/@head with $model('data')/*/data(@head),
        for $entry in $model('data')//entry
        let $id := $entry/data(@xml:id)
        let $old := $config:svn-change-history-file//id($id)
        return 
            if($old) then update replace $old with $entry
            else update insert $entry into $config:svn-change-history-file/dictionary
        )
    else map {'code' : 400, 'message' : 'could not parse XML fragment', 'fields' : 'invalid format'}
};
:)

(:~
 : Helper function for resolving docTypes
~:)
declare %private function api:resolve-docTypes($model as map()) as xs:string* {
    if(exists($model('docType'))) then $model('docType')
    else for $func in wdt:members('unary-docTypes') return $func(())('name')
};

(:~
 :  Helper function for creating a subsequence based on external parameters
~:)
declare %private function api:subsequence($seq as item()*, $model as map()) {
    let $offset := if($model('offset') castable as xs:integer) then $model('offset') cast as xs:integer else 0
    let $limit := if($model('limit') castable as xs:integer) then $model('limit') cast as xs:integer else 0
    return
        if($offset gt 0 and $limit gt 0) then subsequence($seq, $offset, $limit)
        else if($offset gt 0) then subsequence($seq, $offset, $api:max-limit($model('swagger:config')))
        else if($limit gt 0) then subsequence($seq, 1, $limit)
        else subsequence($seq, 1, $api:max-limit($model('swagger:config')))
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
                'uri' : $scheme || '://' || $host || substring-before($basePath, 'api') || $id,
                'docID' : $id,
                'docType' : $docType,
                'title' : wdt:lookup($docType, $doc)('title')('txt')
            } 
};

(:~
 :  Helper function for creating a CodeSample object 
~:)
declare function api:codeSample($nodes as node()*, $model as map()) as map()* {
    let $host := $model('swagger:config')?host
    let $basePath := $model('swagger:config')?basePath
    let $scheme := $model('swagger:config')?schemes?1
    return 
        for $node in $nodes
        let $docID := $node/root()/*/data(@xml:id)
        return
            map { 
                'uri' : $scheme || '://' || $host || substring-before($basePath, 'api') || $docID,
                'docID' : $docID,
                'codeSample' : serialize(functx:change-element-ns-deep(wega-util:process-xml-for-display($node), '', ''))
            }
};

(:~
 : Helper function for validating user input (= function parameters)
~:)
(:declare %private function api:validateInput($model as map()) as empty-sequence() {
    for $param in map:keys($model)
    return
        switch($param)
        case 'docType' return api:check-docType($model)
        case 'element' return api:check-elementName($model)
        case 'date' return api:check-date($model)
        default return ()
};
:)

(:~
 : Check parameter docType and split comma separated value into a sequence
~:)
declare function api:validate-docType($model as map()) as map()? {
    let $wega-docTypes := for $func in wdt:members('unary-docTypes') return $func(())('name')
    return
        map:entry(
            'docType',
            for $docType in tokenize($model('docType'),',')
            return
                if($docType = $wega-docTypes) then $docType
                else error($api:INVALID_PARAMETER, 'There is no document type "' || $docType || '"')
        )
};

(:~
 : Check parameter element
~:)
declare function api:validate-element($model as map()) as map()? {
    if(matches($model('element'), '^[-a-zA-Z]+$')) then $model 
    else error($api:INVALID_PARAMETER, 'Unsupported element name "' || $model('element') || '"')
};

(:~
 : Check parameter namespace
~:)
declare function api:validate-namespace($model as map()) as map()? {
    if(xmldb:decode-uri($model('namespace')) castable as xs:anyURI and matches(xmldb:decode-uri($model('namespace')), '^[-\.:#+/a-zA-Z0-9]+$')) then 
        map { 'namespace' : xmldb:decode-uri($model?namespace) }
    else 
        error($api:INVALID_PARAMETER, 'Unsupported namespace notation: "' || $model('namespace') || '". 
            The namespace should be castable to an xs:anyURI, e.g. "http://www.tei-c.org/ns/1.0" und must not contain some special characters.'
        )
};

(:~
 : Check parameter offset
~:)
declare function api:validate-offset($model as map()) as map()? {
    if($model('offset') castable as xs:positiveInteger) then $model 
    else error($api:INVALID_PARAMETER, 'Unsupported value for parameter "offset". It should be a positive integer.')
};

(:~
 : Check parameter limit
~:)
declare function api:validate-limit($model as map()) as map()? {
    if($model('limit') castable as xs:positiveInteger and xs:integer($model('limit')) le $api:max-limit($model('swagger:config'))) then $model 
    else error($api:INVALID_PARAMETER, 'Unsupported value for parameter "limit". It should be a positive integer less or equal to ' || $api:max-limit($model('swagger:config')) || '.')
};

(:~
 : Check parameter fromDate
~:)
declare function api:validate-fromDate($model as map()) as map()? {
    if($model('fromDate') castable as xs:date) then $model
    else error($api:INVALID_PARAMETER, 'Unsupported date format given: "' || $model('fromDate') || '". Should be YYYY-MM-DD.')
};

(:~
 : Check parameter toDate
~:)
declare function api:validate-toDate($model as map()) as map()? {
    if($model('toDate') castable as xs:date) then $model
    else error($api:INVALID_PARAMETER, 'Unsupported date format given: "' || $model('toDate') || '". Should be YYYY-MM-DD.')
};

(:~
 : Check parameter docID
~:)
declare function api:validate-docID($model as map()) as map()? {
    (: Nothing to do here but decoding, IDs will be checked within api:findByID()   :)
    map { 'docID' : xmldb:decode-uri($model?docID) }
};

(:~
 : Check parameter authorID
~:)
declare function api:validate-authorID($model as map()) as map()? {
    (: Nothing to do here but decoding, IDs will be checked within api:findByID()   :)
    map { 'authorID' : xmldb:decode-uri($model?authorID) }
};

(:~
 : Fallback for unknown API parameters 
 : Simply returns an error message
~:)
declare function api:validate-unknown-param($model as map()) as map()? {
    error($api:INVALID_PARAMETER, 'Unsupported parameter "' || string-join(map:keys($model), '; ') || '". If you believe this to be an error please send a note to bugs@weber-gesamtausgabe.de.')
};
