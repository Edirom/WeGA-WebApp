xquery version "3.0" encoding "UTF-8";

module namespace search="http://xquery.weber-gesamtausgabe.de/modules/search";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace templates="http://exist-db.org/xquery/templates";

import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace norm="http://xquery.weber-gesamtausgabe.de/modules/norm" at "norm.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";
import module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date" at "date.xqm";

declare variable $search:valid-params := ('biblioType', 'editors', 'authors' , 'works', 'persons', 
    'occupations', 'docSource', 'composers', 'librettists', 'lyricists', 'dedicatees', 'journals', 
    'docStatus', 'addressee', 'sender', 'textType', 'residences', 'places', 'placeOfAddressee', 'placeOfSender',
    'fromDate', 'toDate', 'undated');

(:~
 : All results
~:)
declare 
    %templates:default("docType", "letters")
    %templates:wrap
    function search:results($node as node(), $model as map(*), $docType as xs:string) as map(*) {
        let $filters := search:create-filters()
        let $search-results := 
            switch($docType)
            case 'search' return search:query()
            default return core:getOrCreateColl($docType, $model('docID'), true())
        let $filtered-results := search:filter-result($search-results, $filters, $docType)
        return
            map {
                'search-results' := core:sortColl($filtered-results, $docType),
                'docType' := $docType,
                'filters' := $filters,
                'earliestDate' := if($docType =('letters', 'writings', 'diaries', 'news', 'biblio')) then search:get-earliest-date($docType, $model('docID')) else (),
                'latestDate' := if($docType =('letters', 'writings', 'diaries', 'news', 'biblio')) then search:get-latest-date($docType, $model('docID')) else ()
            }
};

declare 
    %templates:wrap
    function search:results-count($node as node(), $model as map(*)) as xs:string {
        count($model('search-results')) || ' Suchergebnisse'
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
declare function search:dispatch-preview($node as node(), $model as map(*)) {
    let $docType := config:get-doctype-by-id($model('result-page-entry')/*/data(@xml:id))
    return
        templates:include($node, $model, 'templates/includes/preview-' || $docType || '.html')
};

declare function search:query() as document-node()* {
    let $searchString := request:get-parameter('q', '')
    let $docType := request:get-parameter('d', 'all')
    let $docType := 
        if($docType = 'all') then map:keys($config:wega-docTypes)
        else map:keys($config:wega-docTypes)[.=$docType]
    return 
        if($searchString) then $docType ! search:fulltext($searchString, .)/root()
        else ()
};

declare %private function search:fulltext($searchString as xs:string, $docType as xs:string) as item()* {
    let $query := search:create-lucene-query-element($searchString)
    let $coll := core:getOrCreateColl($docType, 'indices', true())
    return
        switch($docType)
        case 'persons' return $coll/tei:person[ft:query(., $query)] | $coll//tei:persName[ft:query(., $query)][@type]
        case 'letters' return $coll//tei:body[ft:query(., $query)] | 
            $coll//tei:correspDesc[ft:query(., $query)] | 
            $coll//tei:title[ft:query(., $query)] |
            $coll//tei:incipit[ft:query(., $query)] | 
            $coll//tei:note[ft:query(., $query)][@type = 'summary']
        case 'diaries' return $coll/tei:ab[ft:query(., $query)]
        case 'writings' return $coll//tei:body[ft:query(., $query)] | $coll//tei:title[ft:query(., $query)]
        case 'works' return $coll/mei:mei[ft:query(., $query)] | $coll//mei:title[ft:query(., $query)]
        case 'news' return $coll//tei:body[ft:query(., $query)] | $coll//tei:title[ft:query(., $query)]
        case 'biblio' return $coll//tei:biblStruct[ft:query(., $query)] | $coll//tei:title[ft:query(., $query)] | $coll//tei:author[ft:query(., $query)] | $coll//tei:editor[ft:query(., $query)]
        default return ()
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
        $collection//@xml:id[config:get-doctype-by-id(.) = $filters($filter)]/root()
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