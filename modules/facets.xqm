xquery version "3.1" encoding "UTF-8";

(:~
 : WeGA facets XQuery-Modul
 :
 : @author Peter Stadler 
 : @version 2.0
 :)

module namespace facets="http://xquery.weber-gesamtausgabe.de/modules/facets";
declare default collation "?lang=de;strength=primary";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace util = "http://exist-db.org/xquery/util";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace norm="http://xquery.weber-gesamtausgabe.de/modules/norm" at "norm.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "str.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace wdt="http://xquery.weber-gesamtausgabe.de/modules/wdt" at "wdt.xqm";
import module namespace functx="http://www.functx.com";
import module namespace templates="http://exist-db.org/xquery/templates";

(:~
 : Trying to reduce function calls to norm:get-norm-doc() when creating facets
~:)
(:declare variable $facets:persons-norm-file := doc($config:tmp-collection-path || '/normFile-persons.xml');:)

(:~
 : 
~:)
declare 
    %templates:default("lang", "en")
    function facets:select($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:select) {
        let $facet := $node/data(@name)
        let $selected := $model?filters?($facet)
        return
            element {name($node)} {
                $node/@*,
                attribute data-api-url {core:link-to-current-app('dev/api.xql')},
                attribute data-doc-id {$model?docID},
                attribute data-doc-type {$model?docType},
                element option {
                    attribute value {''},
                    lang:get-language-string('all', $lang)
                },
                for $i in $selected 
                let $display-term := facets:display-term($facet, $i, $lang)
                order by $i
                return
                    element option {
                        attribute selected {'selected'},
                        attribute value {$i},
                        (: mieser hack da der field-index nicht immer etwas findet und dann in den Facetten der Name leer bleibt … :)
                        if($display-term) then $display-term
                        else if(wdt:persons(@docID)('check')()) then wdt:persons(@docID)('label-facets')()
                        else wdt:orgs(@docID)('label-facets')() (:$facets:persons-norm-file//norm:entry[range:eq(@docID,$i)]:)
                    }
            }
};

declare function facets:facets($nodes as node()*, $facet as xs:string, $max as xs:integer, $lang as xs:string) as array(*)  {
    switch($facet)
    case 'textType' return facets:from-docType($nodes, $facet, $lang)
    default return (facets:createFacets($nodes, $facet, $max, $lang), util:log-system-out(array:size(facets:createFacets($nodes, $facet, $max, $lang))))
};

declare %private function facets:from-docType($collection as node()*, $facet as xs:string, $lang as xs:string) as array(*) {
    [
        for $i in $collection
        group by $docTypePrefix := substring($i/*/@xml:id, 1, 3)
        let $docType := config:get-doctype-by-id($docTypePrefix || '0000')
        return 
            map {
                'value' := $docType,
                'label' := lang:get-language-string($docType, $lang),
                'frequency' := count($i)
            }
    ]
};

(:~
 : Create facets
 :
 :)
declare %private function facets:createFacets($nodes as node()*, $facet as xs:string, $max as xs:integer, $lang as xs:string) as array(*) {
    let $facets := query:get-facets($nodes, $facet)
    let $callback := function($term as xs:string, $data as xs:int+) {
        let $label := facets:display-term($facet, $term, $lang) 
        return
        map {
            'value' := str:normalize-space($term),
            'label' := $label,
            'frequency' := $data[2]
        }
    }
    return 
        array { util:index-keys($facets, (), $callback, $max, 'range-index') }
};

(:~
 : Helper function for localizing facet terms
~:)
declare %private function facets:display-term($facet as xs:string, $term as xs:string, $lang as xs:string) as xs:string {
    switch($facet)
    case 'persons' case 'sender' case 'addressee' 
    case 'dedicatees' case 'lyricists' case 'librettists' 
    case 'composers' case 'authors' case 'editors' return
        if(wdt:persons($term)('check')()) then wdt:persons($term)('label-facets')()
        else wdt:orgs($term)('label-facets')()
    case 'works' return wdt:works($term)('label-facets')()
    case 'sex' return 
        if($term ='Art der Institution') then lang:get-language-string('organisationsInstitutions', $lang)
        else lang:get-language-string('sex_' || $term, $lang)
    case 'docTypeSubClass' case 'docStatus' case 'textType' return lang:get-language-string($term, $lang)
    default return str:normalize-space($term)
};

declare 
    %templates:default("lang", "en") 
    %templates:wrap
    function facets:document-allFilter($node as node(), $model as map(*), $lang as xs:string) as map(*) {
        map {
            'filterSections' := 
                for $filter in ('persons', 'works', 'places', 'characterNames')
                let $keys := distinct-values($model('doc')//@key[ancestor::tei:text or ancestor::tei:ab][not(ancestor::tei:note)]/tokenize(., '\s+')[config:get-doctype-by-id(.) = $filter])
                let $places := 
                    if($filter = 'places') then distinct-values($model('doc')//tei:settlement[ancestor::tei:text or ancestor::tei:ab][not(ancestor::tei:note)])
                    else ()
                let $characterNames := 
                    if($filter = 'characterNames') then distinct-values($model('doc')//tei:characterName[ancestor::tei:text or ancestor::tei:ab][not(ancestor::tei:note)])
                    else ()
                return 
                    if(exists($keys)) then map { $filter := $keys}
                    else if(exists($places)) then map { $filter := $places}
                    else if(exists($characterNames)) then map { $filter := $characterNames}
                    else ()
        }
};

declare 
    %templates:default("lang", "en")
    %templates:wrap
    function facets:filter-options($node as node(), $model as map(*), $lang as xs:string) as map(*) {
        map {
            'filterOptions' := 
                (: iterating over filterSection although there's only one key in this map :)
                for $i in map:keys($model('filterSection'))
                    for $j in $model('filterSection')($i)
                    let $label :=
                        switch($i)
                        case 'persons' return query:title($j)
                        case 'works' return wdt:works($j)('title')('txt')
                        default return $j
                    let $key :=
                        switch($i)
                        case 'places' return string-join(string-to-codepoints(normalize-space($j)) ! string(.), '')
                        case 'characterNames' return string-join(string-to-codepoints(normalize-space($j)) ! string(.), '')
                        default return $j
                    order by $label ascending
                    return map { 'key' := $key, 'label' := $label}
        }
};

declare function facets:filter-body($node as node(), $model as map(*)) as element(div) {
    element {name($node)} {
        $node/@class,
        (: That should be safe because there's always only one key in filterSection :)
        attribute id {map:keys($model('filterSection'))},
        templates:process($node/node(), $model)
    }
};

declare 
    %templates:default("lang", "en") 
    function facets:filter-head($node as node(), $model as map(*), $lang as xs:string) as element() {
        element {name($node)} {
            $node/@*[not(name(.) = 'href')],
            (: That should be safe because there's always only one key in filterSection :)
            attribute href {'#' || map:keys($model('filterSection'))},
            lang:get-language-string(map:keys($model('filterSection')), $lang)
        }
};

declare function facets:filter-value($node as node(), $model as map(*)) as element(input) {
    element {name($node)} {
        $node/@*[not(name(.) = 'id')],
        attribute value {$model('filterOption')('key')}
    }
};

declare function facets:filter-label($node as node(), $model as map(*)) as element(span) {
    element {name($node)} {
        $node/@*[not(name(.) = 'title')],
        attribute title {$model('filterOption')('label')},
        if(string-length($model('filterOption')('label')) > 30) then 
            substring($model('filterOption')('label'), 1, 30) || '…'
        else $model('filterOption')('label')
    }
};
