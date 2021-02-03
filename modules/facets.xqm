xquery version "3.1" encoding "UTF-8";

(:~
 : WeGA facets XQuery-Modul
 :
 : @author Peter Stadler 
 : @version 2.0
 :)

module namespace facets="http://xquery.weber-gesamtausgabe.de/modules/facets";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace util = "http://exist-db.org/xquery/util";
declare namespace ft="http://exist-db.org/xquery/lucene";
declare namespace map="http://www.w3.org/2005/xpath-functions/map";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/str.xqm";
import module namespace wdt="http://xquery.weber-gesamtausgabe.de/modules/wdt" at "wdt.xqm";
import module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util" at "wega-util.xqm";
import module namespace functx="http://www.functx.com";
import module namespace templates="http://exist-db.org/xquery/templates";


(:~
 : 
~:)
declare 
    %templates:default("lang", "en")
    function facets:select($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:select) {
        let $facet := $node/data(@name)
        let $selected := $model?filters?($facet)
        let $selectedObjs as array(*)? := 
            if(count($selected) gt 0) then facets:createFacets($model?search-results, $facet, -1, $lang)
            else ()
        return
            element {node-name($node)} {
                $node/@*,
                attribute data-api-url {config:api-base() || '/facets/' || $facet},
                attribute data-doc-id {$model?docID},
                attribute data-doc-type {$model?docType},
                element option {
                    attribute value {''},
                    lang:get-language-string('all', $lang)
                },
                for $i in $selected 
(:                let $log := util:log-system-out($i):)
                let $display-term := facets:display-term($facet, $i, $lang)
                let $freq := 
                    if ($selectedObjs?*[?value = encode-for-uri($i)]?frequency castable as xs:int) 
                    then $selectedObjs?*[?value = encode-for-uri($i)]?frequency
                    else 0
                    order by $display-term collation "?lang=de;strength=primary"
                return
                    element option {
                        attribute selected {'selected'},
                        attribute value {$i},
                        $display-term || ' (' || $freq || ')'
                    }
            }
};

declare function facets:createFacets($nodes as node()*, $facet as xs:string, $max as xs:integer, $lang as xs:string) as array(*) {
    let $coll := (: wildcard $nodes/*[ft:query(., ())] funktioniert hier nicht :)
        $nodes/tei:TEI[ft:query(., ())] | 
        $nodes/tei:ab[ft:query(., ())] | 
        $nodes/tei:person[ft:query(., ())] | 
        $nodes/tei:org[ft:query(., ())] |
        $nodes/mei:mei[ft:query(., ())]
    let $this.facet := 
        if($facet = 'textType') then 'docType' (: special mapping of textType URL param to docType index facet :)
        else $facet
    let $facets := ft:facets($coll, $this.facet, ())
    return
        array {
            map:for-each($facets, function($term, $count) {
                map {
                    'value' : str:normalize-space(encode-for-uri($term)),
                    'label': facets:display-term($this.facet, $term, $lang),
                    'frequency': $count
                }
            })
        }
};

(:~
 : Helper function for localizing facet terms
~:)
declare %private function facets:display-term($facet as xs:string, $term as xs:string, $lang as xs:string) as xs:string {
    switch($facet)
    case 'persons' case 'personsPlus' case 'sender' case 'addressee' 
    case 'dedicatees' case 'lyricists' case 'librettists' 
    case 'composers' case 'authors' case 'editors' return
        if(wdt:persons($term)('check')()) then wdt:persons($term)('label-facets')() (:$facets:persons-norm-file//norm:entry[range:eq(@docID,$term)]/normalize-space():)
        else wdt:orgs($term)('label-facets')()
    case 'works' return wdt:works($term)('label-facets')()
    case 'placeOfAddressee' case 'placeOfSender' case 'residences' case 'places' return wdt:places($term)('title')('txt')
    case 'sex' return 
        if($term ='Art der Institution') then lang:get-language-string('organisationsInstitutions', $lang)
        else lang:get-language-string('sex_' || $term, $lang)
    case 'docTypeSubClass' case 'docStatus' case 'docType' case 'facsimile' return lang:get-language-string($term, $lang)
    default return str:normalize-space($term)
};

(:~
 : Create "Allfilter" section on document pages
 : allows highlighting of names in the text
~:)
declare 
    %templates:default("lang", "en") 
    %templates:wrap
    function facets:document-allFilter($node as node(), $model as map(*), $lang as xs:string) as map(*) {
        let $filterSections := ('personsPlus', 'works', 'places', 'characterNames')
        return
        map {
            'filterSections' : 
                for $filter in $filterSections
                let $keys := distinct-values($model('doc')//@key[ancestor::tei:text or ancestor::tei:ab][not(ancestor::tei:note)]/tokenize(., '\s+')[config:get-combined-doctype-by-id(.) = $filter])
                let $characterNames := 
                    if($filter = 'characterNames') then distinct-values($model('doc')//tei:characterName[ancestor::tei:text or ancestor::tei:ab][not(ancestor::tei:note)] ! normalize-space(.))
                    else ()
                return 
                    if(exists($keys)) then map { $filter : $keys}
                    else if(exists($characterNames)) then map { $filter : $characterNames}
                    else ()
        }
};

declare 
    %templates:default("lang", "en")
    %templates:wrap
    function facets:filter-options($node as node(), $model as map(*), $lang as xs:string) as map(*) {
        map {
            'filterOptions' : 
                (: iterating over filterSection although there's only one key in this map :)
                for $i in map:keys($model('filterSection'))
                    for $j in $model('filterSection')($i)
                    let $label := facets:display-term($i, $j, $lang)
                    let $key :=
                        switch($i)
                        case 'characterNames' return string-join(string-to-codepoints(normalize-space($j)) ! string(.), '')
                        default return $j
                    order by $label ascending collation "?lang=de;strength=primary"
                    return map { 'key' : $key, 'label' : $label}
        }
};

declare function facets:filter-body($node as node(), $model as map(*)) as element(div) {
    element {node-name($node)} {
        $node/@class,
        (: That should be safe because there's always only one key in filterSection :)
        attribute id {map:keys($model('filterSection'))},
        templates:process($node/node(), $model)
    }
};

declare 
    %templates:default("lang", "en") 
    function facets:filter-head($node as node(), $model as map(*), $lang as xs:string) as element() {
        element {node-name($node)} {
            $node/@*[not(name(.) = 'href')],
            (: That should be safe because there's always only one key in filterSection :)
            attribute href {'#' || map:keys($model('filterSection'))},
            lang:get-language-string(map:keys($model('filterSection')), $lang)
        }
};

declare function facets:filter-value($node as node(), $model as map(*)) as element(input) {
    element {node-name($node)} {
        $node/@*[not(name(.) = 'id')],
        attribute value {$model('filterOption')('key')}
    }
};

declare function facets:filter-label($node as node(), $model as map(*), $lang as xs:string) as element(span) {
    element {node-name($node)} {
        $node/@*[not(name(.) = 'title')],
        attribute title {lang:get-language-string("facetsFilterLabel",$model('filterOption')('label'),$lang)},
        $model('filterOption')('label')
    }
};
