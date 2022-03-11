xquery version "3.1" encoding "UTF-8";

module namespace search="http://xquery.weber-gesamtausgabe.de/modules/search";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace map="http://www.w3.org/2005/xpath-functions/map";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace session="http://exist-db.org/xquery/session";
declare namespace range="http://exist-db.org/xquery/range";
declare namespace ft="http://exist-db.org/xquery/lucene";
import module namespace kwic="http://exist-db.org/xquery/kwic";
import module namespace templates="http://exist-db.org/xquery/html-templating";
import module namespace functx="http://www.functx.com";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/str.xqm";
import module namespace wdt="http://xquery.weber-gesamtausgabe.de/modules/wdt" at "wdt.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util" at "wega-util.xqm";
import module namespace controller="http://xquery.weber-gesamtausgabe.de/modules/controller" at "controller.xqm";
import module namespace api="http://xquery.weber-gesamtausgabe.de/modules/api" at "api.xqm";


declare variable $search:ERROR := QName("http://xquery.weber-gesamtausgabe.de/modules/search", "Error");

(: 
 : a subset of $config:wega-docTypes. 
 : Finally, all of these should be supported 
 :)
declare variable $search:wega-docTypes := for $func in wdt:members('search') return $func(())('name');

(: params for filtering the result set :)
declare variable $search:valid-params := ('biblioType', 'editors', 'authors', 'works', 'persons', 'orgs',
    'occupations', 'docSource', 'composers', 'librettists', 'lyricists', 'dedicatees', 'journals', 
    'docStatus', 'addressee', 'sender', 'textType', 'residences', 'places', 'placeOfAddressee', 'placeOfSender',
    'fromDate', 'toDate', 'undated', 'hideRevealed', 'docTypeSubClass', 'sex', 'surnames', 'forenames', 
    'asksam-cat', 'vorlageform', 'einrichtungsform', 'placenames', 'repository', 'facsimile', 'series',
    'keywords', 'docLang', 'city', 'siglum', 'orderby', 'orderdir');

(:~
 : Main function called from the templating module
 : All results will be created here for the search page as well as for list views (indices pages)
~:)
declare 
    %templates:default("docType", "letters")
    %templates:wrap
    function search:results($node as node(), $model as map(*), $docType as xs:string) as map(*) {
        let $filters := map { 'filters' : search:create-filters(), 'api-base' : config:api-base(()) }
        return
            switch($docType)
            (: search page :)
            case 'search' return search:search-session(map:merge(($model, $filters, map:entry('docID', 'indices'))), search:search#1)
            (: controller sends docType=persons which needs to be turned into "personsPlus" here :)
            case 'persons' return search:list(map:merge(($filters, map:put($model, 'docType', 'personsPlus'))))
            (: various list views :)
            default return search:list(map:merge(($filters, map:put($model, 'docType', $docType))))
};

(:~
 : Print the ammount of hits
 : To be called from an HTML template
~:)
declare 
    %templates:wrap
    %templates:default("lang", "en")
    function search:results-count($node as node(), $model as map(*), $lang as xs:string) as xs:string {
        count($model('search-results')) || ' ' || lang:get-language-string('searchResults', $lang)
};

(:~
 : Push the results for one page to the $model
 : $model?result-page-entries will be a sequence of document-node()*
 : $model?result-page-hits-per-entry will be a map(), consisting of document IDs as key and the fulltext hits as value (if appropriate).
~:)
declare 
    %templates:wrap
    %templates:default("page", "1")
    function search:result-page($node as node(), $model as map(*), $page as xs:string) as map(*) {
        let $page := if($page castable as xs:int) then xs:int($page) else 1
        let $entries-per-page := xs:int(config:entries-per-page())
        let $subseq := subsequence($model('search-results'), ($page - 1) * $entries-per-page + 1, $entries-per-page)
        let $docs := search:normalize-result-entries($subseq)
        let $result-page-hits-per-entry := map:merge(
            for $doc in $subseq
            return (
                if($doc instance of map(*) and exists($doc?hits)) then 
                    map:entry($doc?doc/*/data(@xml:id), $doc?hits)
                else ()
            )
        )
        return
            map {
                'result-page-entries' : $docs,
                'result-page-hits-per-entry' : $result-page-hits-per-entry
            }
};

(:~
 : Wrapper for dispatching various document types
 : Simply redirects to the right fragment from 'templates/includes'
 :)
declare 
    %templates:default("usage", "")
    function search:dispatch-preview($node as node(), $model as map(*), $usage as xs:string) {
        let $docID := $model('result-page-entry')/*/data(@xml:id)
        let $docType := config:get-doctype-by-id($docID) 
        let $preview-template := 
            switch($docType)
            (: Preview orgs with the person template :)
            case 'orgs' return 'persons'
            case 'var' return 'documents'
            case 'addenda' return 'documents'
            default return $docType
(:        let $log := util:log-system-out($model('docType') || ' - ' || $model('docID')):)
        (: Need to distinguish between contacts and other person previews :)
        let $usage := if(wdt:personsPlus(($model('docID')))('check')() and $model('docType') = 'contacts') then 'contacts' else ''
        (: Since docID will be overwritten by app:preview we need to preserve it to know what the parent page is :)
        let $newModel := map:merge(($model, map:entry('parent-docID', $model('docID')), map:entry('usage', $usage)))
        return
            templates:include($node, $newModel, 'templates/includes/preview-' || $preview-template || '.html')
};

(:~
 : KWIC output
 :)
declare 
    %templates:wrap
    %templates:default("maxLines", "6")
    function search:kwic($node as node(), $model as map(*), $maxLines as xs:string) as element(xhtml:p)* {
        let $max := 
            if($maxLines castable as xs:int) 
            then $maxLines cast as xs:int 
            else 6
        return
        if(exists($model('result-page-hits-per-entry'))) then 
            let $hits := $model('result-page-hits-per-entry')($model('docID'))
            let $expanded := $hits ! kwic:get-matches(.)
            (: reduce result set and merge different hits from e.g. tei:TEI and tei:body by calling functx:distinct-deep() on the parent nodes of the matches :)
            let $matches := functx:distinct-deep($expanded/parent::*)/exist:match 
            return (
                (subsequence($matches, 1, $max) ! kwic:get-summary(./root(), ., <config width="40"/>)),
                if(count($matches) gt $max) 
                then <xhtml:p>…</xhtml:p>
                else ()
            )
        else ()
};

(:~
 : Search results and other goodies for the *search* page 
~:)
declare %private function search:search($model as map(*)) as map(*) {
    let $updatedModel := $model
    let $docTypes := 
        if($updatedModel?query-docTypes = 'all') then ($search:wega-docTypes, 'var', 'addenda') (: silently add 'var' (= special pages, e.g. "Impressum/About" or "Sonderband/Special Volume") to the list of docTypes :)
        else $search:wega-docTypes[.=$updatedModel?query-docTypes]
    let $base-collection := function ($updatedModel as map(*), $docTypes as xs:string*) {
        if($updatedModel?query-string-org) then $docTypes ! core:getOrCreateColl(., 'indices', true())
        else ()
    }
    let $filtered-results := 
        if(exists($updatedModel('filters'))) then 
            for $docType in $docTypes 
            return search:filter-result($base-collection($updatedModel, $docType), $updatedModel?filters, $docType)
        else $base-collection($updatedModel, $docTypes)
    let $fulltext-search :=
        if($updatedModel('query-string')) then search:merge-hits($docTypes ! search:fulltext($filtered-results, $updatedModel('query-string'), $updatedModel?filters, .))
        else $filtered-results 
    let $store-session := 
        if(count($fulltext-search) gt 0) 
        then session:set-attribute('wegasearch', map:merge(($updatedModel, map:entry('search-results', $fulltext-search))))
        else ()
    return
        map:merge(($updatedModel, map:entry('search-results', $fulltext-search)))
};  

(:~
 : Search results and other goodies for the *list view* pages 
~:)
declare %private function search:list($model as map(*)) as map(*) {
    let $coll := core:getOrCreateColl($model('docType'), $model('docID'), true())
    (: awkward hack to create a new map for $model. It seems $model gets modified by some strange side effect when pushed directly to search:filter-result() :)
    let $filters := map:merge(for $i in map:keys($model?filters) return map:entry($i, $model?filters($i)))
    let $search-results as document-node()* := 
        if(count(map:keys($filters)) gt 0) then search:filter-result($coll, $filters, $model?docType)
        else $coll
    let $sorted-results := wdt:lookup($model('docType'), $search-results)('sort')( map { 'personID' : $model('docID')} )
    return
        map:merge((
            $model,
            map {
                'search-results' : $sorted-results,
                'earliestDate' : search:get-earliest-date($sorted-results, $model('docType')),
                'latestDate' : search:get-latest-date($sorted-results, $model('docType')),
                'oldFromDate' : request:get-parameter('oldFromDate', ''),
                'oldToDate' : request:get-parameter('oldToDate', '')
            }
        ))
};  

(:~
 : Sorting and merging search results
 : Helper function for search:search()
~:)
declare %private function search:merge-hits($hits as item()*) as map(*)* {
    for $hit in $hits
    group by $doc := $hit/root()
    let $score := sum($hit ! ft:score(.))
    order by $score descending 
    return
        map { 
            'doc' : $doc,
            'hits' : $hit,
            'score' : $score
        }
};

(:~
 :  Do a full text search 
 :  by looking up the appropriate search function in the wdt module 
~:)
declare %private function search:fulltext($items as item()*, $searchString as xs:string, $filters as map(*), $docType as xs:string) as item()* {
    let $query := search:create-lucene-query-element($searchString)
    let $search-func := wdt:lookup($docType, $items)?search
    return
        try { $search-func($query) }
        catch * { error($search:ERROR, 'failed to search collection with docType "' || $docType || '"') }
};

(:~
 : Parse the query string and create an XML query element for the lucene search
~:)
declare function search:create-lucene-query-element($searchString as xs:string) as element(query) {
    let $groups := analyze-string($searchString, '(-?"(.+?)")')/* (: split into fn:match – for expressions in parentheses – and fn:non-match elements :)
    let $queryElement := function($elementName as xs:string, $token as item()) as element() {
        element {$elementName} {
            attribute occur {
                if(starts-with($token, '-')) then 'not'
                else if($token instance of node() and $token/ancestor::fn:group[starts-with(., '-')]) then 'not'
                else 'must'
            },
            if(starts-with($token, '-')) then substring($token, 2)
            else string($token)
        }
    }
    let $term-search := <bool boost="5">{$groups ! (if(./self::fn:match) then $queryElement('phrase', .//fn:group[@nr='2']) else (tokenize(str:normalize-space(.), '\s') ! $queryElement('term', .)))}</bool>
    (:  Suppress additional searches when the search string consists of expressions in parentheses only  :)
    let $wildcard-search := if($groups[not(functx:all-whitespace(self::fn:non-match))]) then <bool boost="2">{$groups ! (if(./self::fn:match) then $queryElement('phrase', .//fn:group[@nr='2']) else (tokenize(str:normalize-space(.), '\s') ! $queryElement('wildcard', lower-case(.) || '*')))}</bool> else ()
    let $regex-search := if($groups[not(functx:all-whitespace(self::fn:non-match))]) then <bool>{$groups ! (if(./self::fn:match) then $queryElement('phrase', .//fn:group[@nr='2']) else (tokenize(str:normalize-space(.), '\s') ! search:additional-mappings(lower-case(.))))}</bool> else ()
    let $q :=
        <query>
            <bool>{
                $term-search,
                $wildcard-search,
                $regex-search
            }</bool>
        </query>
(:    let $log := util:log-system-out($groups):)
(:    let $log := util:log-system-out($q):)
    return 
        $q
};

(:~
 : Helper function for search:create-lucene-query-element()
 : Adds additional character mappings to the search, e.g. "Rowenstrunk -> Roewenstrunk"
 : This is applied *after* the unicode normalization, so the input $str is already without diacritics
 :
 : @param $str a search token, derived from the input query string
 : @return a <regex> element for use in XML lucene syntax
~:)
declare %private function search:additional-mappings($str as xs:string) as element(regex) {
    <regex occur="must">{
        functx:replace-multi($str, 
            ('"', '[ck]', 'ae?', 'oe?', 'ue?', 'ß', 'th?', '((ph)|f)', '[yi]e?'), 
            ('', '(c|k)', 'ae?', 'oe?', 'ue?', 'ss', 'th?', '((ph)|f)', '[yi]e?') 
        )
    }.*</regex>
};

(:~
 : Creates a map of to-be-applied-filters from URL request parameters
 : Makes use of the `api:validate-*` functions for checking the sanity of parameter values
~:)
declare %private function search:create-filters() as map(*) {
    let $paramsOrg := request:get-parameter-names()[.=$search:valid-params]
    let $params :=
        (: "undated" takes precedence over date filter :)
        if($paramsOrg[.='undated']) then $paramsOrg[not(.= ('fromDate', 'toDate'))] 
        else $paramsOrg
    let $validate-unknown-param := function-lookup(QName('http://xquery.weber-gesamtausgabe.de/modules/api', 'api:validate-unknown-param'), 1)
    return
        map:merge(
            for $param in $params
            let $lookup := function-lookup(QName('http://xquery.weber-gesamtausgabe.de/modules/api', 'api:validate-' || $param), 1) 
            return
                if(exists($lookup)) then $lookup(map:entry($param, request:get-parameter($param, ())))
                else if(exists($validate-unknown-param)) then $validate-unknown-param(map:entry($param, request:get-parameter($param, ())))
                else (
                    wega-util:log-to-file('warn', 'It seems you did not provide a validate-unknown-param function'),
                    error($search:ERROR, 'Unknown parameter "' || $param || '". Details should be provided in the system log.') 
                )
        )
};

(:~  
 : Filters collection according to given facets and date constraints
 : Recursively applies this function until the filter map is empty
~:)
declare %private function search:filter-result($collection as document-node()*, $filters as map(*), $docType as xs:string) as document-node()* {
    if(count(map:keys($filters)) gt 0) then (
        let $filter := map:keys($filters)[1]
        let $filtered-coll := 
            if($filter = ('undated')) then ($collection intersect core:undated($docType))/root()
            else if($filter = 'searchDate') then search:searchDate-filter($collection, $filters($filter)[1])
            else if($filter = ('fromDate', 'toDate')) then wdt:lookup($docType, $collection)?filter-by-date(try {$filters?fromDate cast as xs:date} catch * {()}, try {$filters?toDate cast as xs:date} catch * {()} )
            else if($filter = 'textType') then search:textType-filter($collection, $filters($filter)[1])
            else if($filter = 'hideRevealed') then search:revealed-filter($collection)
            else if($filter = 'facsimile') then search:facsimile-filter($collection, $filters($filter)[1])
            (: exact search for terms -> range:eq :)
            else if($filter = ('journals', 'forenames', 'surnames', 'sex', 'occupations')) then query:get-facets($collection, $filter)[range:eq(.,$filters($filter)[1])]/root()
            (: range:contains for tokens within key values  :)
            else if($filter = ('addressee', 'sender')) then query:get-facets($collection, $filter)[range:contains(.,$filters($filter)[1])]/root()
            (: exact match for everything else :)
            else if($filter = ('wev', 'jv', 'ks')) then search:search-alt-identifiers($collection, map { 'provider': $filter, 'id': $filters?($filter) })
            else query:get-facets($collection, $filter)[range:eq(.,$filters($filter)[1])]/root()
        let $newFilter :=
            if($filter = ('fromDate', 'toDate')) then 
                try { map:remove(map:remove($filters, 'toDate'), 'fromDate') }
                catch * {()}
            else if(count($filters($filter)) gt 1) then 
                map:merge(($filters, map:entry($filter, subsequence($filters($filter), 2))))
            else
                map:remove($filters, $filter)
        return
            if(count(map:keys($newFilter)) gt 0) then (
                search:filter-result($filtered-coll, $newFilter, $docType)
            )
            else $filtered-coll
    )
    else $collection
};

(:~
 : Helper function for search:filter-result()
 : Queries dates within TEI and MEI documents
 : Dates are expected to be xs:string, yet castable to xs:date
~:)
declare %private function search:searchDate-filter($collection as document-node()*, $dates as xs:string*) as document-node()* {
    for $date in $dates[. castable as xs:date]
    return
        (
            $collection//tei:date[@when=$date] 
            | $collection//tei:date[@notBefore le $date][@notAfter ge $date] 
            | $collection//tei:date[@from le $date][@to ge $date]
            | $collection//mei:date[@isodate=$date] 
            | $collection//mei:date[@notbefore le $date][@notafter ge $date] 
            | $collection//mei:date[@startdate le $date][@enddate ge $date]
        )/root()
};

(:~
 : Helper function for search:filter-result()
 : Applies textType filter for backlinks
~:)
declare %private function search:textType-filter($collection as document-node()*, $textTypes as xs:string*) as document-node()* {
    for $textType in $textTypes
    return
        wdt:lookup($textType, $collection)('sort')(map {})
};

declare %private function search:revealed-filter($collection as document-node()*) as document-node()* {
    $collection//tei:correspDesc[not(@n='revealed')]/root()
};

declare %private function search:facsimile-filter($collection as document-node()*, $filters as xs:string*) as document-node()* {
    let $facsimiles := $collection ! query:facsimile(.)
    return
        for $filter in $filters
        return 
            switch($filter)
            case 'internal' return $facsimiles[not(@sameAs)][tei:graphic]/root()
            case 'external' return $facsimiles[@sameAs]/root()
            default return $collection except $facsimiles/root()
};

(:~
 : 
~:)
declare %private function search:get-earliest-date($coll as document-node()*, $docType as xs:string) as xs:string? {
    if(count($coll) gt 0) then 
        switch ($docType)
        case 'news' case 'biblio' case 'letters' case 'writings' case 'diaries' case 'documents' return 
            min(core:index-keys-for-field($coll, 'date')[not(.='undated')])
        case 'persons' case 'orgs' return ()
        case 'works' return ()
        case 'places' return ()
        default return ()
    else ()
};

(:~
 : 
~:)
declare %private function search:get-latest-date($coll as document-node()*, $docType as xs:string) as xs:string? {
    if(count($coll) gt 0) then 
        switch ($docType)
        case 'news' case 'biblio' case 'letters' case 'writings' case 'diaries' case 'documents' return
            max(core:index-keys-for-field($coll, 'date')[not(.='undated')])
        case 'persons' case 'orgs' return ()
        case 'works' return ()
        case 'places' return ()
        default return ()
    else ()
};

(:~
 : Read query string and parameters from URL 
 :
 : @return a map with sanitized query string, parameters and recognized dates
~:)
declare %private function search:prepare-search-string($model as map(*)) as map(*) {
    let $query-docTypes := request:get-parameter('d', 'all') ! str:sanitize(.)
    let $query-string-org := request:get-parameter('q', '')
    let $sanitized-query-string := str:normalize-space(str:sanitize(string-join($query-string-org, ' ')))
    let $analyzed-query-string as map(xs:string,xs:string) := search:analyse-query-string(map { 'query-string': $sanitized-query-string })
    return
        map:merge((
            $model, 
            map {
                'filters' : map:merge(($model?filters, map:remove($analyzed-query-string, 'query-string'))), (: push recognized filters to the filters :)
                'query-string' : $analyzed-query-string?query-string => normalize-space() => str:strip-diacritics(), (: flatten input search string, e.g. 'mèhul' --> 'mehul' for use with the NoDiacriticsStandardAnalyzer :) 
                'query-docTypes' : $query-docTypes,
                'query-string-org' : $query-string-org
            }
        ))
};

(:~
 : (recursively) analyse a query string regarding magic keywords or dates
 : Helper function for search:prepare-search-string#1
 : 
 : @param $model a map object with at least a "query-string" property as xs:string 
 : @return a map object with the recognised filters (searchDate, wev, jv, ks) and the remaining "query-string" (the non-matches)
 :)
declare %private function search:analyse-query-string($model as map(xs:string,xs:string)) {
    let $q := $model?query-string
    let $dates := analyze-string($q, '\d{4}-\d{2}-\d{2}')
    let $jv := analyze-string($q, 'jv:((Anh\. )?\d+|deest)')
    let $wev := analyze-string($q, 'wev:([A-Za-z](\.\d+)?)')
    let $ks := analyze-string($q, 'ks:(\d+)')
    return
        if($dates/fn:match) then search:analyse-query-string(map:put($model, 'searchDate', $dates/fn:match ! string(.)) => map:put('query-string', $dates/fn:non-match/text() => string-join()))
        else if($jv/fn:match) then search:analyse-query-string(map:put($model, 'jv', $jv/fn:match/fn:group ! string(.)) => map:put('query-string', $jv/fn:non-match/text() => string-join()))
        else if($wev/fn:match) then search:analyse-query-string(map:put($model, 'wev', $wev/fn:match/fn:group ! string(.)) => map:put('query-string', $wev/fn:non-match/text() => string-join()))
        else if($ks/fn:match) then search:analyse-query-string(map:put($model, 'ks', $ks/fn:match/fn:group ! string(.)) => map:put('query-string', $ks/fn:non-match/text() => string-join()))
        else $model
};

(:~
 : Cache search results in browser session
 : 
 : @param $model the current model map of the templating module
 : @param $callback a callback function to actually do the search if the session is empty
 : @return a map object {'filters': {}, 'search-results': {}, 'query-string-org': '', 'query-docTypes': ('') }
~:)
declare %private function search:search-session($model as map(*), $callback as function() as map(*)) as map(*) {
    let $updatedModel := search:prepare-search-string($model)
    let $session-exists :=
        try { 
            count(session:get-attribute('wegasearch')?search-results) gt 0
            and session:get-attribute('wegasearch')?query-string-org = $updatedModel?query-string-org
            and functx:sequence-deep-equal(session:get-attribute('wegasearch')?filters?*, $updatedModel?filters?*)
            and functx:sequence-deep-equal(session:get-attribute('wegasearch')?query-docTypes, $updatedModel?query-docTypes)
        }
        catch * {false()}
    return 
        if($session-exists)
        then map:merge((
            (:  need to do that merge here as a hack 
                because simply returning session:get-attribute('wegasearch') 
                yields strange caching(?) artifacts of empty result sets 
            :)
            map {'search-results': session:get-attribute('wegasearch')?search-results}, 
            $updatedModel
        ))
        else $callback($updatedModel)
};

declare 
    %templates:wrap
    function search:get-session-for-singleview($node as node(), $model as map(*)) as map(*)? {
        let $wegasearch := (:session:get-attribute('wegasearch'):) search:search-session($model, search:search#1)
        let $docs := search:normalize-result-entries($wegasearch?search-results)
        let $index-of-current-doc := functx:index-of-node($docs, $model?doc)
        let $page := ceiling($index-of-current-doc div config:entries-per-page())
        let $url := controller:resolve-link('$link/search', $model) || '?q=' || $wegasearch?query-string-org || '&amp;d=' || string-join($wegasearch?query-docTypes, '&amp;d=') || '&amp;page=' || $page
        let $search-prev-item-url := 
            if($index-of-current-doc gt 1) then controller:create-url-for-doc($docs[$index-of-current-doc - 1], $model?lang) || '?q=' || string-join(($wegasearch?query-string-org, $wegasearch?query-docTypes), '&amp;d=')
            else '#'
        let $search-next-item-url := 
            if($index-of-current-doc lt count($docs)) then controller:create-url-for-doc($docs[$index-of-current-doc + 1], $model?lang) || '?q=' || string-join(($wegasearch?query-string-org, $wegasearch?query-docTypes), '&amp;d=')
            else '#'
        return
            map:merge((
                $wegasearch, 
                map:entry('index-of-current-doc', $index-of-current-doc),
                map:entry('search-backlink', $url),
                map:entry('search-prev-item-url', $search-prev-item-url),
                map:entry('search-next-item-url', $search-next-item-url)
            ))
};

(:~
 : Extract the documents from the search results
 : Helper function for search:get-session-for-singleview() and search:result-page()
 :
 : NB: This whole code block is not very elegant:
 : the results of the fulltext search are of type map()* and need to be turned into document-node
 : the results of the list of examples from the spec pages are elements and need *not* to be processed
 : other searches and/or list views simply return document-node()*
 :)
declare %private function search:normalize-result-entries($entries as item()*) as item()* {
    for $doc in $entries
    return
        if($doc instance of document-node()) then $doc
        else if($doc instance of map(*)) then $doc?doc
        else if($doc instance of element()) then $doc 
        else if($doc instance of node()) then error($search:ERROR, 'unable to process node: ' || functx:node-kind($doc) || ' ' || name($doc))
        else if($doc instance of xs:anyAtomicType) then error($search:ERROR, 'unable to process atomic type: ' || functx:atomic-type($doc))
        else error($search:ERROR, 'unknown result entry')
};

declare %private function search:search-alt-identifiers($collection as document-node()*, $altID as map(xs:string,xs:string)) as document-node()* {
    switch($altID?provider)
    case 'jv' return $collection//mei:altId[@type='JV'][matches(., '^' || $altID?id || '(\D.*)?$')]/root()
    case 'wev' return $collection//mei:altId[@type='WeV'][matches(., '^' || $altID?id || '(\D.*)?$')]/root()
    case 'ks' return $collection//tei:idno[@type='KS'][@n=$altID?id]/root()
    default return ()
};
