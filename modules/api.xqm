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
import module namespace wega-util-shared="http://xquery.weber-gesamtausgabe.de/modules/wega-util-shared" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/wega-util-shared.xqm";
import module namespace dev="http://xquery.weber-gesamtausgabe.de/modules/dev" at "dev/dev.xqm";
import module namespace mycache="http://xquery.weber-gesamtausgabe.de/modules/cache" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/cache.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/str.xqm";
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

declare function api:facets($model as map(*)) as map()* {
    let $fileName := util:hash($model?facet || $model?scope || $model?docType, 'md5')
    let $localFilepath := str:join-path-elements(($config:tmp-collection-path, 'facets', $fileName || '.json'))
    let $lease := function($currentDateTimeOfFile as xs:dateTime?) as xs:boolean { wega-util:check-if-update-necessary($currentDateTimeOfFile, ()) }
    let $onFailureFunc := function($errCode, $errDesc) {
            core:logToFile('warn', string-join(($errCode, $errDesc), ' ;; '))
        }
    (: check whether the result set is already filtered  :)
    let $filtered := map:keys($model)[not(.= ('term', 'facet', 'scope', 'docType'))] = $search:valid-params
    let $allFacets :=
    (: if the result set is already filtered, do not use the cached version which is only to speed up 'vanilla' sets :)
        if($filtered) then api:get-facets($model)?*
        else mycache:doc($localFilepath, api:get-facets#1, $model, $lease, $onFailureFunc)?*
    let $facets := 
        if($model?term) 
        then 
            for $facet in $allFacets[?label[contains(wega-util:strip-diacritics(lower-case(.)), wega-util:strip-diacritics(lower-case($model?term)))]]
            let $matches := functx:index-of-string(wega-util:strip-diacritics(lower-case($facet?label)), wega-util:strip-diacritics(lower-case($model?term)))
            order by $matches[1], $facet?label
            return
                map:merge(( $facet, map { 
                    'matches': array { for $match in $matches return map { 
                        'start': $match - 1, (: subtract 1 because Javascript frontend starts counting at 0 :) 
                        'length':  string-length(wega-util:strip-diacritics(lower-case($model?term))) (: the length is just a stub but can be elaborated on when even-better-searching is implemented ;) :)
                    }} 
                }))
        else $allFacets
    return (
        map { 'totalRecordCount': count($facets) },
        api:subsequence($facets, $model)
    )
};

(:~
 :  Helper function for api:facets()
 :)
declare %private function api:get-facets($model as map(*)) as array(*) {
    let $search := search:results(<span/>, map { 'docID' : $model('scope') }, $model('docType'))
    let $lang := config:guess-language($model('lang'))
    let $allFacets as map()* := facets:facets($search?search-results, $model('facet'), -1, $lang)?*
    return
        array {
            for $i in $allFacets
            order by $i?label collation "?lang=de;strength=primary"
            return $i
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
 :  Helper function for creating a Document object
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
                if($docType = ($wega-docTypes, 'personsPlus')) then $docType
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
            The namespace should be castable to an xs:anyURI, e.g. "http://www.tei-c.org/ns/1.0" und must not contain special characters.'
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
    map { 'docID': xmldb:decode-uri($model?docID) }
};

(:~
 : Check parameter authorID
~:)
declare function api:validate-authorID($model as map()) as map()? {
    (: Nothing to do here but decoding, IDs will be checked within api:findByID()   :)
    map { 'authorID': xmldb:decode-uri($model?authorID) }
};

(:~
 : Check parameter facet
 : only one value allowed
~:)
declare function api:validate-facet($model as map()) as map()? {
    if($model?facet castable as xs:string and $model?facet = $search:valid-params) then $model 
    else error($api:INVALID_PARAMETER, 'Unsupported value for parameter "facet". It must be one of the following values: ' || string-join($search:valid-params, ', '))
};

(:~
 : Check parameter term (= search term for facets)
 : only one value allowed
~:)
declare function api:validate-term($model as map()) as map()? {
    if($model('term') castable as xs:string) then map { 'term': xmldb:decode-uri($model?term) }
    else error($api:INVALID_PARAMETER, 'Unsupported value for parameter "term".')
};

(:~
 : Check parameter scope (either 'indices' or a WeGA ID)
 : only one value allowed
~:)
declare function api:validate-scope($model as map()) as map()? {
    if($model?scope castable as xs:string and (matches($model?scope, '^indices$') or config:get-doctype-by-id($model?scope))) then $model 
    else error($api:INVALID_PARAMETER, 'Unsupported value for parameter "scope". It must be either a WeGA ID or the term "indices".' )
};

(:~
 : Check parameter placeOfAddressee
 : multiple values allowed as input, either by providing multiple URL parameters
 : or by sending a comma separated list as the value of one URL parameter
~:)
declare function api:validate-placeOfAddressee($model as map()) as map()? {
    if(every $i in $model?placeOfAddressee ! tokenize(., ',') satisfies wdt:places($i)('check')()) then map { 'placeOfAddressee': $model?placeOfAddressee ! tokenize(., ',') }
    else error($api:INVALID_PARAMETER, 'Unsupported value for parameter "placeOfAddressee". It must be a WeGA place ID.' )
}; 

(:~
 : Check parameter biblioType
 : multiple values allowed as input, either by providing multiple URL parameters
 : or by sending a comma separated list as the value of one URL parameter
~:)
declare function api:validate-biblioType($model as map()) as map()? {
    if(every $i in $model?biblioType ! tokenize(., ',') satisfies wdt:biblio($i)('check')()) then map { 'biblioType': $model?biblioType ! tokenize(., ',') }
    else error($api:INVALID_PARAMETER, 'Unsupported value for parameter "biblioType". It must be a WeGA biblio ID.' )
}; 

(:~
 : Check parameter editors
 : multiple values allowed as input, either by providing multiple URL parameters
 : or by sending a comma separated list as the value of one URL parameter
~:)
declare function api:validate-editors($model as map()) as map()? {
    if(every $i in $model?editors ! tokenize(., ',') satisfies wdt:persons($i)('check')()) then map { 'editors': $model?editors ! tokenize(., ',') }
    else error($api:INVALID_PARAMETER, 'Unsupported value for parameter "editors". It must be a WeGA person ID.' )
}; 

(:~
 : Check parameter authors
 : multiple values allowed as input, either by providing multiple URL parameters
 : or by sending a comma separated list as the value of one URL parameter
~:)
declare function api:validate-authors($model as map()) as map()? {
    if(every $i in $model?authors ! tokenize(., ',') satisfies wdt:persons($i)('check')()) then map { 'authors': $model?authors ! tokenize(., ',') }
    else error($api:INVALID_PARAMETER, 'Unsupported value for parameter "authors". It must be a WeGA person ID.' )
}; 

(:~
 : Check parameter works
 : multiple values allowed as input, either by providing multiple URL parameters
 : or by sending a comma separated list as the value of one URL parameter
~:)
declare function api:validate-works($model as map()) as map()? {
    if(every $i in $model?works ! tokenize(., ',') satisfies wdt:works($i)('check')()) then map { 'works': $model?works ! tokenize(., ',') }
    else error($api:INVALID_PARAMETER, 'Unsupported value for parameter "works". It must be a WeGA work ID.' )
}; 

(:~
 : Check parameter persons
 : multiple values allowed as input, either by providing multiple URL parameters
 : or by sending a comma separated list as the value of one URL parameter
~:)
declare function api:validate-persons($model as map()) as map()? {
    if(every $i in $model?persons ! tokenize(., ',') satisfies wdt:personsPlus($i)('check')()) then map { 'persons': $model?persons ! tokenize(., ',') }
    else error($api:INVALID_PARAMETER, 'Unsupported value for parameter "persons". It must be a WeGA person or org ID.' )
}; 

(:~
 : Check parameter orgs
 : multiple values allowed as input, either by providing multiple URL parameters
 : or by sending a comma separated list as the value of one URL parameter
~:)
declare function api:validate-orgs($model as map()) as map()? {
    if(every $i in $model?orgs ! tokenize(., ',') satisfies wdt:orgs($i)('check')()) then map { 'orgs': $model?orgs ! tokenize(., ',') }
    else error($api:INVALID_PARAMETER, 'Unsupported value for parameter "orgs". It must be a WeGA org ID.' )
}; 

(:~
 : Check parameter occupations
 : multiple values allowed as input, either by providing multiple URL parameters
 : or by sending a comma separated list as the value of one URL parameter
~:)
declare function api:validate-occupations($model as map()) as map()? {
    if(every $i in $model?occupations ! tokenize(., ',') satisfies $i castable as xs:string) then map { 'occupations': $model?occupations ! tokenize(., ',') ! xmldb:decode-uri(.) }
    else error($api:INVALID_PARAMETER, 'Unsupported value for parameter "occupations".' )
}; 

(:~
 : Check parameter docSource
 : multiple values allowed as input, either by providing multiple URL parameters
 : or by sending a comma separated list as the value of one URL parameter
~:)
declare function api:validate-docSource($model as map()) as map()? {
    if(every $i in $model?docSource ! tokenize(., ',') satisfies $i castable as xs:string) then map { 'docSource': $model?docSource ! tokenize(., ',') ! xmldb:decode-uri(.) }
    else error($api:INVALID_PARAMETER, 'Unsupported value for parameter "docSource".' )
}; 

(:~
 : Check parameter composers
 : multiple values allowed as input, either by providing multiple URL parameters
 : or by sending a comma separated list as the value of one URL parameter
~:)
declare function api:validate-composers($model as map()) as map()? {
    if(every $i in $model?composers ! tokenize(., ',') satisfies wdt:persons($i)('check')()) then map { 'composers': $model?composers ! tokenize(., ',') }
    else error($api:INVALID_PARAMETER, 'Unsupported value for parameter "composers". It must be a WeGA person ID.' )
}; 

(:~
 : Check parameter librettists
 : multiple values allowed as input, either by providing multiple URL parameters
 : or by sending a comma separated list as the value of one URL parameter
~:)
declare function api:validate-librettists($model as map()) as map()? {
    if(every $i in $model?librettists ! tokenize(., ',') satisfies wdt:persons($i)('check')()) then map { 'librettists': $model?librettists ! tokenize(., ',') }
    else error($api:INVALID_PARAMETER, 'Unsupported value for parameter "librettists". It must be a WeGA person ID.' )
}; 

(:~
 : Check parameter lyricists
 : multiple values allowed as input, either by providing multiple URL parameters
 : or by sending a comma separated list as the value of one URL parameter
~:)
declare function api:validate-lyricists($model as map()) as map()? {
    if(every $i in $model?lyricists ! tokenize(., ',') satisfies wdt:persons($i)('check')()) then map { 'lyricists': $model?lyricists ! tokenize(., ',') }
    else error($api:INVALID_PARAMETER, 'Unsupported value for parameter "lyricists". It must be a WeGA person ID.' )
}; 

(:~
 : Check parameter dedicatees
 : multiple values allowed as input, either by providing multiple URL parameters
 : or by sending a comma separated list as the value of one URL parameter
~:)
declare function api:validate-dedicatees($model as map()) as map()? {
    if(every $i in $model?dedicatees ! tokenize(., ',') satisfies wdt:persons($i)('check')()) then map { 'dedicatees': $model?dedicatees ! tokenize(., ',') }
    else error($api:INVALID_PARAMETER, 'Unsupported value for parameter "dedicatees". It must be a WeGA person ID.' )
}; 

(:~
 : Check parameter journals
 : multiple values allowed as input, either by providing multiple URL parameters
 : or by sending a comma separated list as the value of one URL parameter
~:)
declare function api:validate-journals($model as map()) as map()? {
    if(every $i in $model?journals ! tokenize(., ',') satisfies $i castable as xs:string) then map { 'journals': $model?journals ! tokenize(., ',') ! xmldb:decode-uri(.) }
    else error($api:INVALID_PARAMETER, 'Unsupported value for parameter "journals".' )
}; 

(:~
 : Check parameter docStatus ('approved','candidate','proposed')
 : multiple values allowed as input, either by providing multiple URL parameters
 : or by sending a comma separated list as the value of one URL parameter
~:)
declare function api:validate-docStatus($model as map()) as map()? {
    if(every $i in $model?docStatus ! tokenize(., ',') satisfies $i = ('approved','candidate','proposed')) then map { 'docStatus': $model?docStatus ! tokenize(., ',') }
    else error($api:INVALID_PARAMETER, 'Unsupported value for parameter "docStatus". It must be one of "approved", "candidate", or "proposed".' )
}; 

(:~
 : Check parameter addressee
 : multiple values allowed as input, either by providing multiple URL parameters
 : or by sending a comma separated list as the value of one URL parameter
~:)
declare function api:validate-addressee($model as map()) as map()? {
    if(every $i in $model?addressee ! tokenize(., ',') satisfies wdt:personsPlus($i)('check')()) then map { 'addressee': $model?addressee ! tokenize(., ',') }
    else error($api:INVALID_PARAMETER, 'Unsupported value for parameter "addressee". It must be a WeGA person or org ID.' )
}; 

(:~
 : Check parameter sender
 : multiple values allowed as input, either by providing multiple URL parameters
 : or by sending a comma separated list as the value of one URL parameter
~:)
declare function api:validate-sender($model as map()) as map()? {
    if(every $i in $model?sender ! tokenize(., ',') satisfies wdt:personsPlus($i)('check')()) then map { 'sender': $model?sender ! tokenize(., ',') }
    else error($api:INVALID_PARAMETER, 'Unsupported value for parameter "sender". It must be a WeGA person or org ID.' )
}; 

(:~
 : Check parameter textType
 : multiple values allowed as input, either by providing multiple URL parameters
 : or by sending a comma separated list as the value of one URL parameter
~:)
declare function api:validate-textType($model as map()) as map()? {
    if($model?textType castable as xs:string) then map { 'textType': xmldb:decode-uri($model?textType) }
    else error($api:INVALID_PARAMETER, 'Unsupported value for parameter "textType".' )
}; 

(:~
 : Check parameter residences
 : multiple values allowed as input, either by providing multiple URL parameters
 : or by sending a comma separated list as the value of one URL parameter
~:)
declare function api:validate-residences($model as map()) as map()? {
    if(every $i in $model?residences ! tokenize(., ',') satisfies wdt:places($i)('check')()) then map { 'residences': $model?residences ! tokenize(., ',') }
    else error($api:INVALID_PARAMETER, 'Unsupported value for parameter "residences". It must be a WeGA place ID.' )
}; 

(:~
 : Check parameter places
 : multiple values allowed as input, either by providing multiple URL parameters
 : or by sending a comma separated list as the value of one URL parameter
~:)
declare function api:validate-places($model as map()) as map()? {
    if(every $i in $model?places ! tokenize(., ',') satisfies wdt:places($i)('check')()) then map { 'places': $model?places ! tokenize(., ',') }
    else error($api:INVALID_PARAMETER, 'Unsupported value for parameter "places". It must be a WeGA place ID.' )
}; 

(:~
 : Check parameter placeOfSender
 : multiple values allowed as input, either by providing multiple URL parameters
 : or by sending a comma separated list as the value of one URL parameter
~:)
declare function api:validate-placeOfSender($model as map()) as map()? {
    if(every $i in $model?placeOfSender ! tokenize(., ',') satisfies wdt:places($i)('check')()) then map { 'placeOfSender': $model?placeOfSender ! tokenize(., ',') }
    else error($api:INVALID_PARAMETER, 'Unsupported value for parameter "placeOfSender". It must be a WeGA place ID.' )
}; 

(:~
 : Check parameter undated (true|false)
 : only one value allowed
~:)
declare function api:validate-undated($model as map()) as map()? {
    if($model?undated castable as xs:string) then map { 'undated': wega-util-shared:semantic-boolean($model?undated) }
    else error($api:INVALID_PARAMETER, 'Unsupported value for parameter "undated".' )
}; 

(:~
 : Check parameter hideRevealed (true|false)
 : only one value allowed
~:)
declare function api:validate-hideRevealed($model as map()) as map()? {
    if($model?hideRevealed castable as xs:string) then map { 'hideRevealed': wega-util-shared:semantic-boolean($model?hideRevealed) }
    else error($api:INVALID_PARAMETER, 'Unsupported value for parameter "hideRevealed".' )
}; 

(:~
 : Check parameter docTypeSubClass
 : multiple values allowed as input, either by providing multiple URL parameters
 : or by sending a comma separated list as the value of one URL parameter
~:)
declare function api:validate-docTypeSubClass($model as map()) as map()? {
    if($model?docTypeSubClass castable as xs:string) then map { 'docTypeSubClass': xmldb:decode-uri($model?docTypeSubClass) }
    else error($api:INVALID_PARAMETER, 'Unsupported value for parameter "docTypeSubClass".' )
}; 

(:~
 : Check parameter sex ('f','m','unknown','Art der Institution')
 : multiple values allowed as input, either by providing multiple URL parameters
 : or by sending a comma separated list as the value of one URL parameter
~:)
declare function api:validate-sex($model as map()) as map()? {
    if(xmldb:decode-uri($model?sex) = ('f','m','unknown','Art der Institution')) then $model
    else error($api:INVALID_PARAMETER, 'Unsupported value for parameter "sex". Must be one of "f", "m", "unknown", or "Art der Institution".')
}; 

(:~
 : Check parameter surnames
~:)
declare function api:validate-surnames($model as map()) as map()? {
    if($model?surnames castable as xs:string) then map { 'surnames': xmldb:decode-uri($model?surnames) }
    else error($api:INVALID_PARAMETER, 'Unsupported value for parameter "surnames".' )
}; 

(:~
 : Check parameter forenames
~:)
declare function api:validate-forenames($model as map()) as map()? {
    if($model?forenames castable as xs:string) then map { 'forenames': xmldb:decode-uri($model?forenames) }
    else error($api:INVALID_PARAMETER, 'Unsupported value for parameter "forenames".' )
}; 

(:~
 : Check parameter asksam-cat
 : multiple values allowed as input, either by providing multiple URL parameters
 : or by sending a comma separated list as the value of one URL parameter
~:)
declare function api:validate-asksam-cat($model as map()) as map()? {
    if($model?asksam-cat castable as xs:string) then map { 'asksam-cat': xmldb:decode-uri($model?asksam-cat) }
    else error($api:INVALID_PARAMETER, 'Unsupported value for parameter "asksam-cat".' )
};

(:~
 : Check parameter vorlageform
 : multiple values allowed as input, either by providing multiple URL parameters
 : or by sending a comma separated list as the value of one URL parameter
~:)
declare function api:validate-vorlageform($model as map()) as map()? {
    if($model?vorlageform castable as xs:string) then map { 'vorlageform': xmldb:decode-uri($model?vorlageform) }
    else error($api:INVALID_PARAMETER, 'Unsupported value for parameter "vorlageform".' )
}; 

(:~
 : Check parameter einrichtungsform
 : multiple values allowed as input, either by providing multiple URL parameters
 : or by sending a comma separated list as the value of one URL parameter
~:)
declare function api:validate-einrichtungsform($model as map()) as map()? {
    if($model?einrichtungsform castable as xs:string) then map { 'einrichtungsform': xmldb:decode-uri($model?einrichtungsform) }
    else error($api:INVALID_PARAMETER, 'Unsupported value for parameter "einrichtungsform".' )
}; 

(:~
 : Check parameter placenames
 : multiple values allowed as input, either by providing multiple URL parameters
 : or by sending a comma separated list as the value of one URL parameter
~:)
declare function api:validate-placenames($model as map()) as map()? {
    if(every $i in $model?placenames ! tokenize(., ',') satisfies wdt:places($i)('check')()) then map { 'placenames': $model?placenames ! tokenize(., ',') }
    else error($api:INVALID_PARAMETER, 'Unsupported value for parameter "placenames". It must be a WeGA place ID.' )
}; 

(:~
 : Check parameter repository
 : multiple values allowed as input, either by providing multiple URL parameters
 : or by sending a comma separated list as the value of one URL parameter
~:)
declare function api:validate-repository($model as map()) as map()? {
    if($model?repository castable as xs:string) then map { 'repository': xmldb:decode-uri($model?repository) }
    else error($api:INVALID_PARAMETER, 'Unsupported value for parameter "repository".' )
}; 

(:~
 : Fallback for unknown API parameters 
 : Simply returns an error message
~:)
declare function api:validate-unknown-param($model as map()) as map()? {
    error($api:INVALID_PARAMETER, 'Unsupported parameter "' || string-join(map:keys($model), '; ') || '". If you believe this to be an error please send a note to bugs@weber-gesamtausgabe.de.')
};
