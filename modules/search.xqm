xquery version "3.1" encoding "UTF-8";

module namespace search="http://xquery.weber-gesamtausgabe.de/modules/search";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

import module namespace kwic="http://exist-db.org/xquery/kwic";
import module namespace templates="http://exist-db.org/xquery/templates" at "/db/apps/shared-resources/content/templates.xql";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace norm="http://xquery.weber-gesamtausgabe.de/modules/norm" at "norm.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "str.xqm";

(: params for filtering the result set :)
declare variable $search:valid-params := ('biblioType', 'editors', 'authors' , 'works', 'persons', 
    'occupations', 'docSource', 'composers', 'librettists', 'lyricists', 'dedicatees', 'journals', 
    'docStatus', 'addressee', 'sender', 'textType', 'residences', 'places', 'placeOfAddressee', 'placeOfSender',
    'fromDate', 'toDate', 'undated', 'docTypeSubClass');

(: 
 : a subset of $config:wega-docTypes. 
 : Finally, all of these should be supported 
 :)
declare variable $search:wega-docTypes := ('persons', 'letters', 'diaries', 'writings', 'works', 'biblio', 'news');

(:~
 : Main function called from the templating module
 : All results will be created here for the search page as well as for list views (indices pages)
~:)
declare 
    %templates:default("docType", "letters")
    %templates:wrap
    function search:results($node as node(), $model as map(*), $docType as xs:string) as map(*) {
        let $filters := map { 'filters' := search:create-filters() }
(:        let $log := util:log-system-out($docType):)
        return
            switch($docType)
            (: search page :)
            case 'search' return search:search(map:new(($model, $filters, map:entry('docID', 'indices'))))
            (: various list views :)
            default return search:list(map:new(($model, $filters, map:entry('docType', $docType))))
};

(:~
 : Print out the ammount of hits
~:)
declare 
    %templates:wrap
    function search:results-count($node as node(), $model as map(*)) as xs:string {
        count($model('search-results')) || ' Suchergebnisse'
};

(:~
 : Write the sanitized query string into the search text input for reuse
~:)
declare function search:inject-value($node as node(), $model as map(*)) as element(input) {
    element {name($node)} {
        $node/@*[not(name(.) = 'value')],
        if($model('query-string') ne '') then attribute {'value'} {$model('query-string')}
        else ()
    }
};

(:~
 : results for one page
~:)
declare 
    %templates:wrap
    %templates:default("page", "1")
    function search:result-page($node as node(), $model as map(*), $page as xs:string) as map(*) {
        let $page := if($page castable as xs:int) then xs:int($page) else 1
        let $entries-per-page := xs:int(config:entries-per-page())
        return
            map {
                'result-page-entries' := subsequence($model('search-results'), ($page - 1) * $entries-per-page + 1, $entries-per-page)
            }
};

(:~
 : Wrapper for dispatching various document types
 : Simply redirects to the right fragment from 'templates/includes'
 :
 :)
declare 
    %templates:default("usage", "")
    function search:dispatch-preview($node as node(), $model as map(*), $usage as xs:string) {
        let $docType := config:get-doctype-by-id($model('result-page-entry')/*/data(@xml:id))
        (: Need to distinguish between contacts and other person previews :)
        let $usage := if(config:is-person($model('docID')) and $model('docType') = 'persons') then 'contacts' else ''
        (: Since docID will be overwritten by app:preview we need to preserve it to know what the parent page is :)
        let $newModel := map:new(($model, map:entry('parent-docID', $model('docID')), map:entry('usage', $usage)))
        return
            templates:include($node, $newModel, 'templates/includes/preview-' || $docType || '.html')
};

(:~
 : KWIC output
 :
 :)
declare 
    %templates:wrap
    function search:kwic($node as node(), $model as map(*)) {
        for $hit in $model($model('docID'))[.//exist:match]
        return
            kwic:get-summary($hit, ($hit//exist:match)[1], <config width="40"/>)
};

(:~
 : Search results and other goodies for the search page 
~:)
declare %private function search:search($model as map(*)) as map(*) {
    let $queryMap := search:prepare-search-string()
    let $results := search:query(map:new(($queryMap, $model)))
    let $docs := for $i in $results return $i('doc')
    let $kwics := map:new( for $i in $results return map:entry($i('doc')/*/data(@xml:id), $i('kwic')) )
    return
        map:new(($queryMap, $model, map:entry('search-results', $docs), $kwics))
};  

(:~
 : Search results and other goodies for the list view pages 
~:)
declare %private function search:list($model as map(*)) as map(*) {
    let $coll := core:getOrCreateColl($model('docType'), $model('docID'), true())
    let $search-results := 
        if(exists($model('filters'))) then search:filter-result($coll, $model('filters'), $model('docType'))
        else $coll
    let $filtered-results := 
        if ($model('docType') = 'persons' and $model('docID') ne 'indices') then core:sortColl($search-results, 'persons', $model('docID'))
        else if ($model('docType') = 'letters' and $model('docID') ne 'indices') then core:sortColl($search-results, 'letters', $model('docID'))
        else if ($model('docType') = 'writings' and $model('docID') ne 'indices') then core:sortColl($search-results, 'writings', $model('docID'))
        else if ($model('docType') = 'diaries' and $model('docID') ne 'indices') then core:sortColl($search-results, 'diaries', $model('docID'))
        else if ($model('docType') = 'biblio' and $model('docID') ne 'indices') then core:sortColl($search-results, 'biblio', $model('docID'))
        else $search-results
    return
        map {
            'filters' := $model('filters'),
            'search-results' := $filtered-results,
            'earliestDate' := if($model('docType') = ('letters', 'writings', 'diaries', 'news', 'biblio')) then search:get-earliest-date($model('docType'), $model('docID')) else (),
            'latestDate' := if($model('docType') = ('letters', 'writings', 'diaries', 'news', 'biblio')) then search:get-latest-date($model('docType'), $model('docID')) else ()
        }
};  


declare %private function search:query($model as map(*)) as map(*)* {
    let $searchString := $model('query-string')
    let $docTypes := $model('query-docTypes')
    let $docTypes := 
        if($docTypes = 'all') then $search:wega-docTypes
        else $search:wega-docTypes[.=$docTypes]
    return 
        if($model('dates')) then $docTypes ! search:exact-date($model('dates'), $model('filters'), .)
        else if($searchString) then search:merge-hits($docTypes ! search:fulltext($searchString, $model('filters'), .)) 
        else ()
};


(:~
 : helper function for sorting and merging search results
~:)
declare %private function search:merge-hits($hits as item()*) as map(*)* {
    for $hit in $hits
    let $expanded := kwic:expand($hit)
    group by $doc := $hit/root()
    order by sum($hit ! ft:score(.)) descending 
    return 
        map { 
            'doc' := $doc, 
            'kwic' := $expanded
        }
};

declare %private function search:fulltext($searchString as xs:string, $filters as map(), $docType as xs:string) as item()* {
    let $query := search:create-lucene-query-element($searchString)
    let $coll := 
        if(count(map:keys($filters)) gt 0) then search:filter-result(core:getOrCreateColl($docType, 'indices', true()), $filters, $docType)
        else core:getOrCreateColl($docType, 'indices', true())
    return
        switch($docType)
        case 'persons' return $coll/tei:person[ft:query(., $query)] | $coll//tei:persName[ft:query(., $query)][@type]
        case 'letters' return 
            $coll//tei:body[ft:query(., $query)] | 
            $coll//tei:correspDesc[ft:query(., $query)] | 
            $coll//tei:title[ft:query(., $query)] |
            $coll//tei:note[@type='incipit'][ft:query(., $query)] | 
            $coll//tei:note[@type='summary'][ft:query(., $query)] |
            $coll/tei:TEI[ft:query(., $query)]
        case 'diaries' return $coll/tei:ab[ft:query(., $query)]
        case 'writings' return 
            $coll//tei:body[ft:query(., $query)] | 
            $coll//tei:title[ft:query(., $query)] |
            $coll/tei:TEI[ft:query(., $query)]
        case 'works' return $coll/mei:mei[ft:query(., $query)] | $coll//mei:title[ft:query(., $query)]
        case 'news' return $coll//tei:body[ft:query(., $query)] | $coll//tei:title[ft:query(., $query)]
        case 'biblio' return $coll//tei:biblStruct[ft:query(., $query)] | $coll//tei:title[ft:query(., $query)] | $coll//tei:author[ft:query(., $query)] | $coll//tei:editor[ft:query(., $query)]
        default return ()
};

declare %private function search:exact-date($dates as xs:date*, $filters as map(), $docType as xs:string) as map(*)* {
    let $coll := 
        if(count(map:keys($filters)) gt 0) then search:filter-result(core:getOrCreateColl($docType, 'indices', true()), $filters, $docType)
        else ()
    let $date-search := norm:get-norm-doc($docType)//norm:entry[. = $dates] ! core:doc(./@docID)
    let $docs :=
        if($coll) then $coll intersect $date-search
        else $date-search
    return
        $docs ! map { 'doc' := . }
};

declare %private function search:create-lucene-query-element($searchString as xs:string) as element(query) {
    let $tokens := tokenize($searchString, '\s+')
    return
        <query>
            <bool>
                <bool boost="2">{$tokens ! <term occur="must">{.}</term>}</bool>
                <bool>{$tokens ! <wildcard occur="must">{lower-case(.)}*</wildcard>}</bool>
            </bool>
        </query>
};

(:~
 : Creates a map of to-be-applied-filters from URL request parameters
~:)
declare %private function search:create-filters() as map(*) {
    let $params := request:get-parameter-names()[.=$search:valid-params]
    return
        map:new(
            (: "undated" takes precedence over date filter :)
            if($params[.='undated']) then $params[not(.= ('fromDate', 'toDate'))] ! map:entry(., request:get-parameter(., ()))
            else $params ! map:entry(., request:get-parameter(., ()))
        )
};

(:~  
 : Filters collection according to given facets and date constraints
 : Recursively applies this function until the filter map is empty
~:)
declare %private function search:filter-result($collection as document-node()*, $filters as map(*), $docType as xs:string) as document-node()* {
    let $filter := map:keys($filters)[1]
    let $filtered-coll := 
      if($filter) then 
        if($filter = ('fromDate', 'toDate', 'undated')) then search:date-filter($collection, $docType, $filters)
        else if($filter = 'textType') then search:textType-filter($collection, $docType, $filters)
        else query:get-facets($collection, $filter)[.=$filters($filter)]/root()
      else $collection
    let $newFilter := 
        try { map:remove($filters, $filter) }
        catch * {map:new()}
    return
        if(exists(map:keys($newFilter))) then search:filter-result($filtered-coll, $newFilter, $docType)
        else $filtered-coll
};

(:~
 : Helper function for search:filter-result()
 : Applies chronological filter 'fromDate' and 'toDate'
~:)
declare %private function search:date-filter($collection as document-node()*, $docType as xs:string, $filters as map(*)) as document-node()* {
    let $filter := map:keys($filters)[1]
    return
        switch($docType)
        case 'biblio' return
            if ($filter = 'undated') then ($collection intersect core:undated($docType))/root()
            else if ($filter = 'fromDate') then $collection//tei:date[(@when, @notBefore, @notAfter, @from, @to) >= $filters($filter)][parent::tei:imprint]/root()
            else $collection//tei:date[(@when, @notBefore, @notAfter, @from, @to) <= $filters($filter)][parent::tei:imprint]/root()
        case 'diaries' return 
            if ($filter = 'fromDate') then $collection//tei:ab[@n >= $filters($filter)]/root()
            else $collection//tei:ab[@n <= $filters($filter)]/root()
        case 'letters' return
            if ($filter = 'undated') then ($collection intersect core:undated($docType))/root()
            else if ($filter = 'fromDate') then $collection//tei:date[(@when, @notBefore, @notAfter, @from, @to) >= $filters($filter)][ancestor::tei:correspDesc]/root()
            else $collection//tei:date[(@when, @notBefore, @notAfter, @from, @to) <= $filters($filter)][ancestor::tei:correspDesc]/root()
        case 'news' return
            if ($filter = 'undated') then ($collection intersect core:undated($docType))/root()
            (: news enthalten dateTime im date/@when :)
            else  if ($filter = 'fromDate') then $collection//tei:date[substring(@when,1,10) >= $filters($filter)][parent::tei:publicationStmt]/root()
            else $collection//tei:date[substring(@when,1,10) <= $filters($filter)][parent::tei:publicationStmt]/root()
        case 'persons' return ()
        case 'writings' return
            if ($filter = 'undated') then ($collection intersect core:undated($docType))/root()
            else if ($filter = 'fromDate') then $collection//tei:date[(@when, @notBefore, @notAfter, @from, @to) >= $filters($filter)][parent::tei:imprint][ancestor::tei:sourceDesc]/root()
            else $collection//tei:date[(@when, @notBefore, @notAfter, @from, @to) <= $filters($filter)][parent::tei:imprint][ancestor::tei:sourceDesc]/root()
        case 'works' return ()
        case 'places' return ()
        default return $collection
};

(:~
 : Helper function for search:filter-result()
 : Applies textType filter for backlinks
~:)
declare %private function search:textType-filter($collection as document-node()*, $docType as xs:string, $filters as map(*)) as document-node()* {
    let $filter := map:keys($filters)[1]
    return 
        $collection/*/@xml:id[config:get-doctype-by-id(.) = $filters($filter)]/root()
};

(:~
 : 
~:)
declare %private function search:get-earliest-date($docType as xs:string, $cacheKey as xs:string) as xs:string? {
    let $catalogue := norm:get-norm-doc($docType)
    return
        switch ($docType)
            case 'diaries' return 
                if($cacheKey = ('A002068','indices')) then ($catalogue//norm:entry[text()])[1]/text()
                else ()
            case 'letters' return 
                if($cacheKey eq 'indices') then ($catalogue//norm:entry[text()])[1]/text()
                else ($catalogue//norm:entry[contains(@addresseeID, $cacheKey)][text()] | $catalogue//norm:entry[contains(@authorID, $cacheKey)][text()])[1]/text()
            case 'news' case 'biblio' return
                (: reverse order :)
                if($cacheKey eq 'indices') then ($catalogue//norm:entry[text()])[last()]/text()
                else ($catalogue//norm:entry[contains(@authorID, $cacheKey)][text()])[last()]/text()
            case 'persons' return ()
            case 'writings' return 
                if($cacheKey eq 'indices') then ($catalogue//norm:entry[text()])[1]/text()
                else ($catalogue//norm:entry[contains(@authorID, $cacheKey)][text()])[1]/text()
            case 'works' return ()
            case 'places' return ()
            default return ()
};

(:~
 : 
~:)
declare %private function search:get-latest-date($docType as xs:string, $cacheKey as xs:string) as xs:string? {
    let $catalogue := norm:get-norm-doc($docType)
    return
        switch ($docType)
            case 'diaries' return 
                if($cacheKey = ('A002068','indices')) then ($catalogue//norm:entry[text()])[last()]/text()
                else ()
            case 'letters' return 
                if($cacheKey eq 'indices') then ($catalogue//norm:entry[text()])[last()]/text()
                else ($catalogue//norm:entry[contains(@addresseeID, $cacheKey)][text()] | $catalogue//norm:entry[contains(@authorID, $cacheKey)][text()])[last()]/text()
            case 'news' case 'biblio' return
                (: reverse order :)
                if($cacheKey eq 'indices') then ($catalogue//norm:entry[text()])[1]/text()
                else ($catalogue//norm:entry[contains(@authorID, $cacheKey)][text()])[1]/text()
            case 'persons' return ()
            case 'writings' return
                if($cacheKey eq 'indices') then ($catalogue//norm:entry[text()])[last()]/text()
                else ($catalogue//norm:entry[contains(@authorID, $cacheKey)][text()])[last()]/text()
            case 'works' return ()
            case 'places' return ()
            default return ()
};

(:~
 : Read query string and parameters from URL 
 :
 : @return a map with sanitized query string, parameters and recognized dates (via PDR web service)
~:)
declare %private function search:prepare-search-string() as map(*) {
    let $query-docTypes := request:get-parameter('d', 'all') ! str:sanitize(.)
    let $query-string := str:sanitize(string-join(request:get-parameter('q', ''), ' '))
    let $dates := analyze-string($query-string, '\d{4}-\d{2}-\d{2}')/fn:match/text()
        (:if(string-length($query-string) ge 400) then date:parse-date($query-string)
        else ():)
    return
        map {
            'query-string' := $query-string, 
            'query-docTypes' := $query-docTypes,
            'dates' := $dates
        }
};
