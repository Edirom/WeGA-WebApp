xquery version "3.0" encoding "UTF-8";

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
declare namespace session = "http://exist-db.org/xquery/session";
declare namespace util = "http://exist-db.org/xquery/util";
declare namespace templates="http://exist-db.org/xquery/templates";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace norm="http://xquery.weber-gesamtausgabe.de/modules/norm" at "norm.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "str.xqm";
import module namespace functx="http://www.functx.com";

declare 
    %templates:default("lang", "en")
    function facets:select($node as node(), $model as map(*), $facet as xs:string, $lang as xs:string) as element(select) {
        let $facet-items := 
            switch($facet)
            case 'docType' return facets:from-docType($model('search-results'), $facet, $lang)
            default return facets:from-index($model('search-results'), $facet)
        return
            element {name($node)} {
                $node/@*,
                <option selected="selected">{lang:get-language-string('all', $lang)}</option>,
                $facet-items ! 
                <option>{./facets:term || ' (' || ./facets:frequency || ')'}</option>
            }
};

declare %private function facets:from-index($collection as node()*, $facet as xs:string) as element(facets:entry)* {
    let $index-entries := facets:index-entries($collection, $facet)
(:    let $startTime := util:system-time():)
    return (
        facets:createFacets($index-entries)(:,
        util:log-system-out($facet || ': ' || string(seconds-from-duration(util:system-time() - $startTime))):)
    )
};

declare %private function facets:from-docType($collection as node()*, $facet as xs:string, $lang as xs:string) as element(facets:entry)* {
    for $i in $collection
    group by $docType := substring($i/*/@xml:id, 1, 3)
    return 
        <facets:entry>
            <facets:term>{lang:get-language-string(config:get-doctype-by-id($docType || '0001'), $lang)}</facets:term>
            <facets:frequency>{count($i)}</facets:frequency>
        </facets:entry>
};

(:~
 : Returns list of terms and their frequency in the collection
 :
 : @author Peter Stadler 
 : @param $term
 : @param $data contains frequency
 : @return element
 :)
declare %private function facets:term-callback($term as xs:string, $data as xs:int+) as element(facets:entry)? {
    <facets:entry>
        <facets:term>{
            switch(config:get-doctype-by-id($term))
            case 'persons' return query:get-reg-name($term)
            case 'works' return query:get-reg-title($term)
            default return str:normalize-space($term) 
        }</facets:term>
        <facets:frequency>{$data[2]}</facets:frequency>
    </facets:entry>
};

(:~
 : Create facets
 :
 : @author Peter Stadler 
 : @param $collFacets
 : @return element
 :)
declare %private function facets:createFacets($collFacets as item()*) as element(facets:entry)* {
    for $k in util:index-keys($collFacets, '', facets:term-callback#2, -1)
(:        order by $k//xs:int(facets:frequency) descending:)
        order by $k//facets:term ascending
        return $k
};

declare %private function facets:index-entries($collection as node()*, $facet as xs:string) as item()* {
    switch($facet)
    case 'sender' return $collection//@key[ancestor::tei:sender]
    case 'addressee' return $collection//@key[ancestor::tei:addressee]
    case 'docStatus' return $collection/*/@status | $collection//tei:revisionDesc/@status
    case 'placeOfSender' return $collection//tei:placeName[parent::tei:placeSender]
    case 'placeOfAddressee' return $collection//tei:placeName[parent::tei:placeAddressee]
    case 'journals' return $collection//tei:title[@level='j'][not(@type='sub')][ancestor::tei:sourceDesc]
    case 'places' return $collection//tei:settlement[ancestor::tei:text or ancestor::tei:ab]
    case 'dedicatees' return $collection//mei:persName[@role='dte']/@dbkey
    case 'lyricists' return $collection//mei:persName[@role='lyr']/@dbkey
    case 'librettists' return $collection//mei:persName[@role='lbt']/@dbkey
    case 'source' return $collection/tei:person/@source
    case 'occupations' return $collection//tei:occupation
    case 'residences' return $collection//tei:settlement[parent::tei:residence]
        (: index-keys does not work with multiple whitespace separated keys
            probably need to change to ft:query() someday?!
        :)
    case 'persons' return ($collection//tei:persName[ancestor::tei:text or ancestor::tei:ab]/@key | $collection//tei:rs[@type='person'][ancestor::tei:text or ancestor::tei:ab]/@key[matches(., '^A02\d{4}$')])
    case 'works' return ($collection//@key[parent::tei:workName][matches(., '^A02\d{4}$')] | $collection//@key[parent::tei:rs/@type='work'][matches(., '^A02\d{4}$')])
    default return ()
};

(:~
 : Creates facet list element
 :
 : @author Peter Stadler 
 : @param $facet
 : @param $freq frequency
 : @param $checked bool
 : @param $category
 : @param $docType
 : @param $cacheKey
 : @param $lang the current language (de|en)
 : @return element li 
 :)

(:declare function facets:createFacetLi($facet as xs:string, $freq as xs:int, $checked as xs:boolean, $category as xs:string, $docType as xs:string, $cacheKey as xs:string, $lang as xs:string) as element(li) {
    let $facetExpanded := facets:expandFacetTerm($facet, $lang)
    return 
    element li {
        if($checked)
            then attribute class {"checked"}
            else (),
        attribute value {string-join(($category, encode-for-uri($facet)), '_')},
        element span {
            attribute class {"checkItem"},
            attribute onclick {concat("javascript:applyFilter(this, '", $docType, "', '", $cacheKey, "', '", $lang, "')")},
(\:            concat($facetExpanded, ' (', $freq, ')'):\)
            $facetExpanded,
            element span {
                attribute class {'facetCount'},
                concat('(', $freq, ')')
            }
        }
    }
};:)

(:~
 : Creates the facet list element for list view popup
 :
 : @author Christian Epp
 : @param $facet
 : @param $freq frequency
 : @param $checked bool
 : @param $category
 : @param $docType
 : @param $cacheKey
 : @param $lang the current language (de|en)
 : @return element li
 :)
(:
declare function facets:createFacetLiPopup($facet as xs:string, $freq as xs:int, $checked as xs:boolean, $category as xs:string, $lang as xs:string) as element(li) {
    let $facetExpanded := facets:expandFacetTerm($facet, $lang)
    return 
    element li {
        if($checked) then attribute class {"checked"} else attribute class {""},
        attribute value {concat($category,'_',encode-for-uri($facet))},
        element span {
            attribute class {"checkItem"},
            attribute onclick {"clickOnPopupListElement(this)"},
(\:            concat($facetExpanded, ' (', $freq, ')'):\)
            $facetExpanded,
            element span {
                attribute class {'facetCount'},
                concat('(', $freq, ')')
            }
        }
    }
};
:)

(:~
 : Expand a facet term to a proper name (e.g. from an attribute value)
 :
 : @author Peter Stadler
 : @param $facetTerm the facet term as given by facets:term-callback()/facets:entry/facets:term
 : @param $lang the current language (de|en)
 : @return string
 :)
(:declare function facets:expandFacetTerm($facetTerm as xs:string, $lang as xs:string) as xs:string {
    if(config:is-person($facetTerm)) then wega:getRegName($facetTerm)
    else if(config:is-work($facetTerm)) then wega:getRegTitle($facetTerm)
    else if(config:is-biblioType($facetTerm)) then lang:get-language-string($facetTerm, $lang)
    else if($facetTerm = ('albumblatt', 'letter')) then lang:get-language-string($facetTerm, $lang)
    else if($facetTerm ne '') then $facetTerm
    else lang:get-language-string('unknown', $lang)
};:)

(:~
 : Creates the facet list for list view popup
 :
 : @author Christian Epp
 : @param $facets collection of facets
 : @param $maxRows
 : @param $category
 : @param $docType
 : @param $cacheKey
 : @param $lang the current language (de|en)
 : @return element ul
 :)
(:
declare function facets:createFacetListForPopup($facets as element(facets:entry)*, $category as xs:string, $docType as xs:string, $lang as xs:string) as element(ul) {
    let $sessionFilter := session:get-attribute(facets:getFilterName($docType))
    let $checked := distinct-values($sessionFilter//facets:entry[@category = $category])
    let $totalNumberOfChecked := count($checked)
    return
    <ul>{
        if(exists($facets) or exists($checked)) then (
            for $i in $facets
                let $item := $i/facets:term
                let $isChecked := exists(index-of($checked,$item))
                let $freq := $i/xs:int(facets:frequency)
                let $li := facets:createFacetLiPopup($item, $freq, $isChecked, $category, $lang)
                order by $li 
                return $li
        )
        else <li class="notAvailable">{lang:get-language-string('noDataFound', $lang)}</li>
        }
    </ul>
};:)

(:~
 : Creates facets list by attributes
 :
 : @author Peter Stadler
 : @param $facets collection of facets
 : @param $maxRows
 : @param $category
 : @param $docType
 : @param $cacheKey
 : @param $lang the current language (de|en)
 : @return element ul
 :)
(:
declare function facets:createFacetListByAttribute($facets as element()*, $maxRows as xs:int, $category as xs:string, $docType as xs:string, $cacheKey as xs:string, $lang as xs:string) as element(ul) {
    let $sessionFilter := session:get-attribute(facets:getFilterName($docType))
    let $totalNumberOfFacets := count($facets)
    let $checked := distinct-values($sessionFilter//facets:entry[@category=$category](\:/text():\))
    let $totalNumberOfChecked := count($checked)
    let $numberOfRows := if ($totalNumberOfFacets lt $maxRows)
        then $totalNumberOfFacets
        else $maxRows
(\:    let $log := util:log-system-out(concat('totalChecked: ', $totalNumberOfChecked)):\)
    return 
    <ul>{
        if(exists($facets) or exists($checked)) then (
            (\: Erst die markierten ausgeben :\)
            for $i in $checked
                let $freq :=
                    if($facets[./facets:term = $i])
                    then $facets[./facets:term = $i]/xs:int(facets:frequency)
                    else 0
                (\:let $log := util:log-system-out(concat('Attribute-$freq: ', $freq)):\)
                order by $freq descending
                return facets:createFacetLi($i, $freq, true(), $category, $docType, $cacheKey, $lang),
            
            (\: Dann den Rest der Facets bis zu $numberOfRows :\)
            (\:let $log := util:log-system-out(concat('$totalNumberOfFacets=',$totalNumberOfFacets))
            let $log := util:log-system-out(concat('$maxRows=',$maxRows))
            let $log := util:log-system-out(concat('$numberOfRows=',$numberOfRows))
            let $log := util:log-system-out(concat('$totalNumberOfChecked=',$totalNumberOfChecked))
            let $log := util:log-system-out(if($totalNumberOfFacets<2) then $facets else ''):\)
            for $i in subsequence($facets, 1, $numberOfRows (\:- $totalNumberOfChecked:\))
                let $item := $i/facets:term
                let $freq := $i/xs:int(facets:frequency)
                return if ($i/facets:term = $checked)
                    then ()
                    else facets:createFacetLi($item, $freq, false(), $category, $docType, $cacheKey, $lang),
            <li onmouseover="this.style.cursor='pointer'" onclick="loadPopup('{$category}','{$docType}','{$cacheKey}')">{concat(lower-case(lang:get-language-string('more', $lang)), '…')}</li>
        )
        else <li class="notAvailable">{lang:get-language-string('noDataFound', $lang)}</li>
        }
    </ul>
};
:)
(:~
 : Creates facets list by elements
 :
 : @author Peter Stadler 
 : @param $facets collection of facets
 : @param $maxRows
 : @param $category
 : @param $docType
 : @param $cacheKey
 : @param $lang the current language (de|en)
 : @return element ul
 :)
(:
declare function facets:createFacetListByElementContent($facets as element()*, $maxRows as xs:int, $category as xs:string, $docType as xs:string, $cacheKey as xs:string, $lang as xs:string) as element(ul) {
    let $sessionFilter := session:get-attribute(facets:getFilterName($docType))
    let $totalNumberOfFacets := count($facets)
    let $checked := distinct-values($sessionFilter//facets:entry[@category=$category])
    let $totalNumberOfChecked := count($checked)
    let $numberOfRows := if($totalNumberOfFacets < $maxRows)
        then $totalNumberOfFacets
        else $maxRows
(\:    let $log := util:log-system-out($category):\)
    return 
    <ul>{
        if(exists($facets) or exists($checked)) then (
            (\: Erst die markierten ausgeben :\)
            for $i in $checked
                let $freq :=
                    if(exists($facets[./facets:term = $i]))
                    then for $x in $facets[./facets:term = $i]/xs:int(facets:frequency) order by $x descending return $x
                    else 0
                let $freq := $freq[1]
                (\:let $log := util:log-system-out($freq):\)
                order by $freq descending
                return facets:createFacetLi($i, $freq, true(), $category, $docType, $cacheKey, $lang),
            
            (\: Dann den Rest der Facets bis zu $numberOfRows :\)
            for $i in subsequence($facets, 1, $numberOfRows (\:- $totalNumberOfChecked:\)) 
               let $freq := $i/xs:int(facets:frequency)
               return if ($i/facets:term =  $checked) 
                   then ()
                   else facets:createFacetLi($i/facets:term, $freq, false(), $category, $docType, $cacheKey, $lang),
               <li onmouseover="this.style.cursor='pointer'" onclick="loadPopup('{$category}','{$docType}','{$cacheKey}')">{concat(lower-case(lang:get-language-string('more', $lang)), '…')}</li>
        )
        else <li class="notAvailable">{lang:get-language-string('noDataFound', $lang)}</li>
        }
    </ul>
};
:)
(:~
 : Returns collection name
 :
 : @author Peter Stadler 
 : @param $docType
 : @param $org
 : @return xs:string
 :)
(:
declare function facets:getCollName($docType as xs:string?, $org as xs:boolean) as xs:string? {
    if(exists($docType))
    then if($org)
        then concat('sessionColl', $docType, 'Org')
        else concat('sessionColl', $docType)
    else ()
};
:)
(:~
 : Returns filter name
 :
 : @author Peter Stadler 
 : @param $docType
 : @return xs:string
 :)
(:
declare function facets:getFilterName($docType as xs:string?) as xs:string? {
    if(exists($docType))
        then concat('sessionFilter', $docType)
        else ()
};
:)
(:~
 : Returns filter element
 :
 : @author Peter Stadler 
 : @param $checked
 : @return element
 :)

(:
declare function facets:createFilter($checked as xs:string*) as element(facets:filter) {
    <facets:filter>{
        for $i in $checked[. ne '']
        let $checkValues := tokenize($i, '_')
        return <facets:entry category="{$checkValues[1]}">{$checkValues[2]}</facets:entry>
    }</facets:filter>
};
:)
(:~
 : Update collections with filters
 :
 : @author Peter Stadler 
 : @param $coll
 : @param $filter
 : @return item*
 :)
(:
declare function facets:updateColl($coll as node()*, $filter as element()) as item()* {
    let $facetsFile := doc(config:get-option('facetsFile'))
    let $predicates := 
            for $k in distinct-values($filter/facets:entry/@category)
            (\:let $log := util:log-system-out($k):\)
            let $values := $filter//facets:entry[@category=$k]
            return concat('[.',  $facetsFile//id($k)/facets:path, '=("', string-join($values, '","'), '")]')
    (\:let $log := util:log-system-out(concat('facets.xql: ', string-join($predicates, ''))):\)
    let $newColl := util:eval(concat('$coll', string-join($predicates, '')))
    (\:let $log := util:log-system-out(concat('facets.xql: ', count($newColl))):\)
    return core:sortColl($newColl)
};
:)
(:~
 : Returns index of first or last document in year
 :
 : @author Peter Stadler 
 : @param $entriesSessionName
 : @param $year
 : @param $first if false, return last
 : @return xs:integer 
 :)
(:
declare function facets:getIndexOfFirstOrLastDocumentInYear($entriesSessionName as xs:string, $year as xs:string, $first as xs:boolean) as xs:integer* {
    let $entries := session:get-attribute($entriesSessionName)
    let $docsInYear := $entries[@year = $year]
	return 
	   if($first) then functx:index-of-node($entries, $docsInYear[1])
	   else functx:index-of-node($entries, $docsInYear[last()])
};
:)
(:~
 : Returns index of first or last document in month
 :
 : @author Peter Stadler 
 : @param $entriesSessionName
 : @param $year
 : @param $month
 : @param $first if false, return last
 : @return xs:integer 
 :)
(:
declare function facets:getFirstOrLastDocumentInMonth($entriesSessionName as xs:string, $year as xs:string, $month as xs:string, $first as xs:boolean) as xs:integer* {
    let $entries := session:get-attribute($entriesSessionName)
    let $docsInYearAndMonth := $entries[@year = $year][@month = $month] (\: kein Index mehr drauf !! :\)
	return 
		if($first) then functx:index-of-node($entries, $docsInYearAndMonth[1])
		else functx:index-of-node($entries, $docsInYearAndMonth[last()])
};
:)
(:~
 : Returns index of first or last document in series
 :
 : @author Peter Stadler 
 : @param $collIDs
 : @param $seriesNo
 : @param $first if false, return last
 : @return xs:string
 :)
(:
declare function facets:getFirstOrLastDocumentInSeries($collIDs as xs:string*, $seriesNo as xs:int, $first as xs:boolean) as xs:string {
    let $docIDs := norm:get-norm-doc('works')//norm:entry[. = $seriesNo][@docID=$collIDs]
    return 
	   if($first) then $docIDs[1]/string(@docID)
	   else $docIDs[last()]/string(@docID)
};
:)
(:~
 : Returns distinct series
 :
 : @author Peter Stadler 
 : @param $coll
 : @return item*
 :)
(:
declare function facets:getDistinctSeries($coll as item()+) as element(mei:title)* {
    for $series in $coll//mei:seriesStmt[@n='WeGA']
    group by $title := $series/mei:title[@level='s']
    order by $title/xs:int(@n)
    return $title
};
:)
(:~
 : Returns categories of facets
 :
 : @author Peter Stadler 
 : @param $docType
 : @return element
 :)
(:
declare function facets:getFacetCategories($docType as xs:string) as element(facets:categories) {
    <facets:categories>
        { doc(config:get-option('facetsFile'))//facets:collection[. = $docType][not(@default = 'no')]/ancestor::facets:entry }
    </facets:categories>
};
:)
(:~
 :  creates a facet list
 :
 :  @author Peter Stadler
 :  @param  $entry as given by facets:getFacetCategories()
 :  @param  $id the ID of a WeGA person or "indices"
 :  @param  $docType the document type (e.g. "writings", "letters")
 :  @param  $lang the language switch (en|de)
 :  @return html:div
:)
(:declare function facets:createFacetFromFacetFile($entry as element(facets:entry), $id as xs:string, $docType as xs:string, $lang as xs:string) as element(div) {
    let $maxRows := xs:int(config:get-option('listViewMaxRows'))
    let $sessionCollName := facets:getCollName($docType, false())
    let $coll := session:get-attribute($sessionCollName)
    let $collFacets :=
    	(\: 
    		Hier treten immer wieder Fehler auf :-(
    		java.util.ConcurrentModificationException oder 
    		java.lang.ArrayIndexOutOfBoundsException
    	:\)
    	try { util:eval(concat('$coll', $entry/facets:path)) }
    	catch * { core:logToFile('error', string-join(('facets:createFacetFromFacetFile', $err:code, $err:description), ' ;; ')) }
    let $facets := 
    	typeswitch($collFacets)
        	case xs:string return 'error'
        	default return facets:createFacets($collFacets) 
    let $setCache := session:set-attribute(concat('facetsSessionAttribute_', $docType, $entry/string(@xml:id)), $facets) (\: wird für das filterPopup benötigt:\)
    return
	    <div>
	        <h2>{lang:get-language-string($entry/@xml:id, $lang)}</h2>
	        {
	        if(not($facets = 'error') and $entry/facets:path/@node = 'attribute') then facets:createFacetListByAttribute($facets, $maxRows, $entry/@xml:id, $docType, $id, $lang)
	        else if(not($facets = 'error') and $entry/facets:path/@node = 'element') then facets:createFacetListByElementContent($facets, $maxRows, $entry/@xml:id, $docType, $id, $lang)
	        else 'error'
	        }
	    </div>
};
:)
(:~
 :  creates a chronological list
 :
 :  @author Peter Stadler
 :  @param  $docType the document type (e.g. "writings", "letters")
 :  @param  $lang the language switch (en|de)
 :  @return html:div
:)
(:declare function facets:createChronoList($docType as xs:string, $lang as xs:string) as element(div) {
	let $sessionCollName := facets:getCollName($docType, false())
	let $datedSessionName := concat('dated', $docType)
	let $undatedSessionName := concat('undated', $docType)
	let $yearsSessionName := concat('years', $docType)
	let $coll-ids := facets:get-IDs(session:get-attribute($sessionCollName), $docType)
	let $normDates := norm:get-norm-doc($docType)
	let $undatedKeys := 
		if($docType eq 'diaries') then $normDates//norm:entry[not(./node())][@docID = $coll-ids]/string(@docID) (\: Bei keinem Treffer wird der leere String zurückgegeben :\)
		else if($docType eq 'biblio') then $normDates//norm:entry[not(./node())][@docID = $coll-ids]/string(@docID)
		else $normDates//norm:entry[not(node())][@docID = $coll-ids]/string(@docID)
	let $dated := 
		if($docType eq 'diaries') then $normDates//norm:entry[@docID = $coll-ids][./node()]
		else if($docType eq 'biblio') then $normDates//norm:entry[@docID = $coll-ids][./node()]
        else $normDates//norm:entry[@docID = $coll-ids][./node()]
    let $distinctYears := for $i in distinct-values($dated/@year) return $i cast as xs:int
    let $saveDated := session:set-attribute($datedSessionName, $dated)
    let $saveUndated := session:set-attribute($undatedSessionName, $undatedKeys)
    let $saveDistinctYears := session:set-attribute($yearsSessionName, $distinctYears)
    let $undatedCount := if($undatedKeys = '') then 0 else count($undatedKeys) (\: Abfrage auf leeren String, s.o. :\)
	return 
		<div>
			<h2>{lang:get-language-string('chronology', $lang)}</h2>
			{
			    facets:createYearAndMonthUl($datedSessionName, $yearsSessionName, $lang, 0),
        		if($undatedCount ne 0) then 
        			element span {
        				attribute class {"checkItem undated"}, 
        				attribute onclick {concat('javascript:', wega:printJavascriptFunction(<function><name>showEntries</name><param type="obj">this</param><param>1</param><param>{$undatedCount}</param><param>{$lang}</param><param>{$undatedSessionName}</param></function>))},
                        (\: Die Abfrage sollte beim Einbau von weiteren Listen -- zB nach creation-date -- modifiziert werden :\)
                        if($docType eq 'writings') then lang:get-language-string('unpublished', $lang)
                        else lang:get-language-string('undated', $lang),
                        <span class="facetCount">{concat('(', $undatedCount,')')}</span>
                    }
                else ()
			}
		</div>
};
:)
(:~
 : Returns list of year and month
 :
 : @author Peter Stadler
 : @param $entriesSessionName
 : @param $yearsSessionName
 : @param $lang the language switch (en|de)
 : @param $recursionDepth
 : @return html:ul
:)
(:declare function facets:createYearAndMonthUl($entriesSessionName as xs:string, $yearsSessionName as xs:string, $lang as xs:string, $recursionDepth as xs:int) as element(ul) {
    let $showYearsOnly := matches($entriesSessionName, 'biblio') (\: Ausnahme für Bibliographie: hier werden nur Jahre angezeigt, keine Monate :\)
    let $sortDescending := matches($entriesSessionName, 'biblio|news') (\: Bibliographie und News werden absteigend sortiert :\)
    let $entries := session:get-attribute($entriesSessionName)
    let $distinctYears := session:get-attribute($yearsSessionName)
    let $maxRows := xs:int(config:get-option('listViewMaxRows'))
    let $countYears := count($distinctYears)
    let $myDivisor := if (round($countYears div $maxRows) eq 0) then 1 else xs:int(round($countYears div $maxRows)) (\: 9/7 :\) 
    let $numberOfRows := if(ceiling($countYears div $myDivisor) gt $maxRows) then $maxRows else xs:int(ceiling($countYears div $myDivisor))
    return if($countYears gt 1 or $recursionDepth eq 0 or $showYearsOnly) then
		<ul>{
			for $i at $count in (1 to $numberOfRows)
			let $fromYearPosition := ($i - 1) * ($myDivisor) + 1
			let $toYearPosition := if (($i * $myDivisor gt $countYears) or ($i eq $numberOfRows)) then $countYears else $i * $myDivisor
			let $yearsInInterval := (\: news und biblio werden umgekehrt angeführt, also latest->first und nicht first->latest :\)
			     if($sortDescending) then $distinctYears[. = (xs:int($distinctYears[$toYearPosition]) to xs:int($distinctYears[$fromYearPosition]))] 
			     else $distinctYears[. = (xs:int($distinctYears[$fromYearPosition]) to xs:int($distinctYears[$toYearPosition]))]
			let $countDocsInInterval := count($entries[@year = $yearsInInterval]) (\: kein Index mehr drauf !! :\)
			let $isOneYear := $distinctYears[$fromYearPosition] eq $distinctYears[$toYearPosition]
			let $nestedMenu := ($countDocsInInterval gt 12 and not($showYearsOnly)) or (not($isOneYear) and $showYearsOnly)
			return 
			<li>{
				if($nestedMenu) then attribute class {'collapsed'} else (),
				element span {
					attribute class {'checkItem'},
					attribute onclick {
						if($nestedMenu) then 
							let $newYearsSessionName := concat($yearsSessionName, $count)
							let $saveYears := session:set-attribute($newYearsSessionName, $yearsInInterval)
							return concat('javascript:', wega:printJavascriptFunction(<function><name>toggleSubMenu</name><param type="obj">this</param><param>{$entriesSessionName}</param><param>{$newYearsSessionName}</param><param>{$lang}</param></function>))
						else
							let $startPosition := facets:getIndexOfFirstOrLastDocumentInYear($entriesSessionName, $distinctYears[$fromYearPosition] cast as xs:string, true())
							let $endPosition := facets:getIndexOfFirstOrLastDocumentInYear($entriesSessionName, $distinctYears[$toYearPosition] cast as xs:string, false())
							return concat('javascript:', wega:printJavascriptFunction(<function><name>showEntries</name><param type="obj">this</param><param>{$startPosition}</param><param>{$endPosition}</param><param>{$lang}</param><param>{replace($entriesSessionName, 'dated', 'sessionColl')}</param></function>))
					},
					if($isOneYear) then $distinctYears[$fromYearPosition]
					else concat($distinctYears[$fromYearPosition], ' ', lang:get-language-string('chronoTo', $lang), ' ', $distinctYears[$toYearPosition]),
					<span class="facetCount">{concat('(', $countDocsInInterval,')')}</span>
				}
			}</li>
		}</ul>
	else <ul>{
			let $months := $entries[@year = $distinctYears]/@month
			return for $i in distinct-values($months)
				let $countMonth := count($entries[@year = $distinctYears][@month = $i]) (\: kein Index mehr drauf !! :\)
				let $startPosition := facets:getFirstOrLastDocumentInMonth($entriesSessionName, $distinctYears cast as xs:string, $i, true())
				let $endPosition := facets:getFirstOrLastDocumentInMonth($entriesSessionName, $distinctYears cast as xs:string, $i, false())
				let $onclick := concat('javascript:', wega:printJavascriptFunction(<function><name>showEntries</name><param type="obj">this</param><param>{$startPosition}</param><param>{$endPosition}</param><param>{$lang}</param><param>{replace($entriesSessionName, 'dated', 'sessionColl')}</param></function>)) 
				order by functx:pad-integer-to-length($i, 2) ascending
				return 
					<li>
						<span class="checkItem" onclick="{$onclick}">
							{lang:get-language-string(concat('month',$i), $lang)}
							<span class="facetCount">{concat('(', $countMonth,')')}</span>
						</span>
					</li>
		}</ul>
};
:)
(:~
 : Returns series
 :
 : @author Peter Stadler
 : @param  $docType the document type (e.g. "writings", "letters")
 : @param  $lang the language switch (en|de)
 : @return html:ul
:)
(:declare function facets:getSeries($docType as xs:string, $lang as xs:string) as element(div) {
    let $maxRows := xs:int(config:get-option('listViewMaxRows'))
    let $sessionCollName := facets:getCollName($docType, false())
    let $coll := session:get-attribute($sessionCollName)
    let $distinctSeries := facets:getDistinctSeries($coll)
    let $collIDs :=  facets:get-IDs($coll, $docType)
    let $activeIDs := norm:get-norm-doc('works')//norm:entry[@docID=$collIDs]/string(@docID)
    let $docType := 'works'
    let $category := 'series'
    return 
    <div>
    	<h2>{lang:get-language-string('series', $lang)}</h2>
	    <ul>{
	        for $mei-title in $distinctSeries
	        let $seriesNo := $mei-title/@n
	        let $firstDoc := facets:getFirstOrLastDocumentInSeries($collIDs, xs:int($seriesNo), true())
	        let $lastDoc := facets:getFirstOrLastDocumentInSeries($collIDs, xs:int($seriesNo), false())
	        let $startPosition := index-of($activeIDs,$firstDoc)
	        let $endPosition := index-of($activeIDs,$lastDoc)
	        return
	        element li {
	            element span {
	                attribute class {'checkItem'},
	                attribute onclick {concat('javascript:', wega:printJavascriptFunction(<function><name>showEntries</name><param type="obj">this</param><param>{$startPosition}</param><param>{$endPosition}</param><param>{$lang}</param><param>{concat('sessionColl', 'works')}</param></function>))},
	                element span {
	                    attribute class {'seriesNo'},
	                    wega:number-to-roman($seriesNo)
	                },
	                element span {
	                    attribute class {'seriesTitle'},
	                    string($mei-title)
	                }
	            }
	        }
	    }</ul>
    </div>
};
:)
(:~
 : Returns alphabet list container
 :
 : @author Peter Stadler  
 : @param $docType
 : @param $lang the language switch (en|de)
 : @return html:ul
:)
(:declare function facets:createAlphabetList($docType as xs:string, $lang as xs:string) as element(div) {
	let $entriesSessionName := concat('entries', $docType)
	let $fromToSessionName := concat('fromTo', $docType)
    let $sessionCollName := facets:getCollName($docType, false())
    let $coll := session:get-attribute($sessionCollName)
    let $normDates := norm:get-norm-doc($docType)//norm:entry
    let $persons := $normDates[@docID = facets:get-IDs($coll, $docType)]
    let $countPersons := count($persons)
    let $savePersons := session:set-attribute($entriesSessionName, $persons)
    let $saveFromTo := session:set-attribute($fromToSessionName, (1,$countPersons))
    return 
    	<div>
    		<h2>{lang:get-language-string('alphabetic', $lang)}</h2>
	        {facets:createAlphabetListUl($entriesSessionName, $fromToSessionName, $lang, 0)}
        </div>
};
:)
(:~
 : Returns alphabet list
 :
 : @author Peter Stadler
 : @param $entriesSessionName
 : @param $fromToSessionName
 : @param $lang the language switch (en|de)
 : @param $recursionDepth
 : @return html:ul
:)
(:declare function facets:createAlphabetListUl($entriesSessionName as xs:string, $fromToSessionName as xs:string, $lang as xs:string, $recusionDepth as xs:int) as element(ul) {
	let $maxRows := xs:int(config:get-option('listViewMaxRows'))
	let $persons := session:get-attribute($entriesSessionName)
	let $from := session:get-attribute($fromToSessionName)[1]
	let $to := session:get-attribute($fromToSessionName)[2]
	let $countPersons := $to - $from +1
	let $myDivisor := if (round($countPersons div $maxRows) eq 0) then 1 else xs:int(round($countPersons div $maxRows)) (\: 9/7 :\) 
    let $numberOfRows := if(ceiling($countPersons div $myDivisor) gt $maxRows) then $maxRows else xs:int(ceiling($countPersons div $myDivisor))
    let $threshold := 30
(\:    let $log := util:log-system-out(session:get-attribute($entriesSessionName)):\)
    return (
    	element ul {
            for $i at $count in (1 to $numberOfRows) 
            let $fromPosition := ($i - 1) * ($myDivisor) + $from
			let $toPosition := if ((($i * $myDivisor + $from -1) gt $to) or ($i eq $numberOfRows)) then $to else $i * $myDivisor + $from -1
            let $startEntry := functx:substring-before-match($persons[$fromPosition]/@sortName, '\s') (\:'Start':\)
            let $endEntry := functx:substring-before-match($persons[$toPosition]/@sortName, '\s') (\:'Ende':\)
            let $countPersonsInInterval := $toPosition - $fromPosition +1
            let $newFromToSessionName := concat($fromToSessionName, $count)
            let $saveFromTo := session:set-attribute($newFromToSessionName, ($fromPosition,$toPosition))
            return (
                element li {
                	if($countPersonsInInterval gt $threshold) then attribute class {'collapsed'}
                	else (),
                    element span {
                        attribute class {'checkItem'},
                        attribute onclick {
                        	if($countPersonsInInterval gt $threshold) then concat('javascript:', wega:printJavascriptFunction(<function><name>toggleSubMenu</name><param type="obj">this</param><param>{$entriesSessionName}</param><param>{$newFromToSessionName}</param><param>{$lang}</param></function>)) 
                        	else concat('javascript:', wega:printJavascriptFunction(<function><name>showEntries</name><param type="obj">this</param><param>{$fromPosition}</param><param>{$toPosition}</param><param>{$lang}</param><param>{replace($entriesSessionName, 'entries', 'sessionColl')}</param></function>))
                        },
                        if($recusionDepth eq 0) then 
                            if($countPersonsInInterval eq 1) then $startEntry 
                            else concat($startEntry, ' ', lang:get-language-string('chronoTo', $lang), ' ', $endEntry)
                        else concat($startEntry, ' …'),
                        <span class="facetCount">{concat('(', $countPersonsInInterval,')')(\:$fromPosition, ' - ', $toPosition:\)}</span>
                    }
                }
            )
        }
    )
};
:)
(:declare %private function facets:get-IDs($coll as document-node()*, $docType as xs:string) as attribute()* {
    switch($docType)
        case 'diaries' return $coll/tei:ab/@xml:id
        case 'persons' return $coll/tei:person/@xml:id
        case 'works' return $coll/mei:mei/@xml:id
        case 'biblio' return $coll/tei:biblStruct/@xml:id
        default return $coll/tei:TEI/@xml:id 
};
:)
