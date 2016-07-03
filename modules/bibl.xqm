xquery version "3.0" encoding "UTF-8";

module namespace bibl="http://xquery.weber-gesamtausgabe.de/modules/bibl";
declare default collation "?lang=de;strength=primary";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
(:import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";:)
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "str.xqm";
import module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util" at "wega-util.xqm";
(:import module namespace functx="http://www.functx.com";:)

(:~
 : Create a bibliographic citation from a biblStruct
 : 
 : @author Peter Stadler
 : @param $biblStruct the TEI biblStruct element with the bibliographic information
 : @param $wrapperElement the HTML element for wrapping the output (usually span or li)
 : @param $lang the language switch (en, de)
 : @return element
 :)
declare function bibl:printCitation($biblStruct as element(tei:biblStruct), $wrapperElement as xs:string, $lang as xs:string) as element()? {
    (: First, for most writings we only want to display the journal :)
    if($biblStruct/tei:analytic/tei:author[@sameAs] and not($biblStruct/ancestor::tei:additional)) then bibl:printJournalCitation($biblStruct/tei:monogr, $wrapperElement, $lang) (: Soll in den writings die Ausgabe von (leerem) Autor unterdrücken; Ist aber lediglich als Notlösung zu verstehen! :)
    (: That's nice – we have a type! :)
    else if($biblStruct/@type eq 'book') then bibl:printBookCitation($biblStruct, $wrapperElement, $lang)
    else if($biblStruct/@type eq 'score') then bibl:printBookCitation($biblStruct, $wrapperElement, $lang)
    else if($biblStruct/@type eq 'article') then bibl:printArticleCitation($biblStruct, $wrapperElement, $lang)
    else if($biblStruct/@type eq 'incollection') then bibl:printIncollectionCitation($biblStruct, $wrapperElement, $lang)
    else if($biblStruct/@type eq 'inproceedings') then bibl:printIncollectionCitation($biblStruct, $wrapperElement, $lang)
    else if($biblStruct/@type eq 'inbook') then bibl:printIncollectionCitation($biblStruct, $wrapperElement, $lang)
    else if($biblStruct/@type eq 'mastersthesis') then bibl:printBookCitation($biblStruct, $wrapperElement, $lang)
    else if($biblStruct/@type eq 'review') then bibl:printArticleCitation($biblStruct, $wrapperElement, $lang)
    else if($biblStruct/@type eq 'phdthesis') then bibl:printBookCitation($biblStruct, $wrapperElement, $lang)
    (: Trying to guess … :)
    else if($biblStruct/tei:analytic and $biblStruct/tei:monogr/tei:title[@level='m']) then bibl:printIncollectionCitation($biblStruct, $wrapperElement, $lang)
    else if($biblStruct/tei:analytic and $biblStruct/tei:monogr/tei:title[@level='j']) then bibl:printArticleCitation($biblStruct, $wrapperElement, $lang)
    (: Fallback :)
    else bibl:printGenericCitation($biblStruct, $wrapperElement, $lang)
};

(:~
 : Create a generic bibliographic citation (This is highly specific to our WeGA data though!)
 : 
 : @author Peter Stadler
 : @param $biblStruct the TEI biblstruct element with the bibliographic information
 : @param $wrapperElement the HTML element for wrapping the output (usually span or li)
 : @param $lang the language switch (en, de)
 : @return element
 :)
declare function bibl:printGenericCitation($biblStruct as element(tei:biblStruct), $wrapperElement as xs:string, $lang as xs:string) as element() {
    let $authors := bibl:printCitationAuthors($biblStruct//tei:author, $lang)
    let $title := for $i in $biblStruct//tei:title return 
        (wega-util:transform($i, doc(concat($config:xsl-collection-path, '/var.xsl')), config:get-xsl-params(())),
        '. '
        )
    return 
        element {$wrapperElement} {
            $authors,
            if(exists($authors)) then ', ' else (),
            $title
        }
};

(:~
 : Create a bibliographic citation for a book
 : 
 : @author Peter Stadler
 : @param $biblStruct the TEI biblstruct element with the bibliographic information
 : @param $wrapperElement the HTML element for wrapping the output (usually span or li) 
 : @param $lang the language switch (en, de)
 : @return element
 :)
declare function bibl:printBookCitation($biblStruct as element(tei:biblStruct), $wrapperElement as xs:string, $lang as xs:string) as element() {
    let $authors := bibl:printCitationAuthors($biblStruct//tei:author, $lang)
    let $editors := bibl:printCitationAuthors($biblStruct/tei:monogr/tei:editor, $lang)
    let $series := if(exists($biblStruct/tei:series/tei:title)) then bibl:printSeriesCitation($biblStruct/tei:series, 'span', $lang) else ()
    let $title := <span class="title">{string-join($biblStruct/tei:monogr/tei:title/str:normalize-space(.), '. ')}</span>
    let $pubPlaceNYear := bibl:printpubPlaceNYear($biblStruct//tei:imprint)
    return 
        element {$wrapperElement} {
            attribute class {'book'},
            if(exists($authors)) then ($authors, ', ') 
            else if(exists($editors)) then ($editors, concat(' (', lang:get-language-string('ed', $lang), '), '))
            else (), 
            $title,
            if(exists($editors) and exists($authors)) then (concat(', ', lang:get-language-string('edBy', $lang), ' '), $editors) else (),
            if(exists($series)) then (' (', $series, '), ') else ', ',
            $pubPlaceNYear
        }
};

(:~
 : Create a bibliographic citation for an article
 : 
 : @author Peter Stadler
 : @param $biblStruct the TEI biblstruct element with the bibliographic information
 : @param $wrapperElement the HTML element for wrapping the output (usually span or li) 
 : @param $lang the language switch (en, de)
 : @return element
 :)
declare function bibl:printArticleCitation($biblStruct as element(tei:biblStruct), $wrapperElement as xs:string, $lang as xs:string) as element() {
    let $authors := bibl:printCitationAuthors($biblStruct//tei:author, $lang) 
    let $articleTitle := <span class="title">{string-join($biblStruct/tei:analytic/tei:title/str:normalize-space(.), '. ')}</span>
    let $journalCitation := bibl:printJournalCitation($biblStruct/tei:monogr, 'wrapper', $lang)
    return 
        element {$wrapperElement} {
            if(exists($authors)) then ($authors, ', ') else (), 
            if($biblStruct[@type='review']) then '[' || lang:get-language-string('review', $lang) || '] '
            else (),
            $articleTitle,
            ', in: ',
            $journalCitation/span,
            $journalCitation/text()
        }
};

(:~
 : Create a bibliographic citation for an incollection entry type
 : 
 : @author Peter Stadler
 : @param $biblStruct the TEI biblstruct element with the bibliographic information
 : @param $wrapperElement the HTML element for wrapping the output (usually span or li) 
 : @param $lang the language switch (en, de)
 : @return element
 :)
declare function bibl:printIncollectionCitation($biblStruct as element(tei:biblStruct), $wrapperElement as xs:string, $lang as xs:string) as element() {
    let $authors := bibl:printCitationAuthors($biblStruct//tei:author, $lang)
    let $editor := bibl:printCitationAuthors($biblStruct//tei:editor, $lang)
    let $articleTitle := <span class="title">{string-join($biblStruct/tei:analytic/tei:title/str:normalize-space(.), '. ')}</span>
    let $bookTitle := <span class="collectionTitle">{string-join($biblStruct/tei:monogr/tei:title/str:normalize-space(.), '. ')}</span>
    let $pubPlaceNYear := bibl:printpubPlaceNYear($biblStruct//tei:imprint)
    let $series := if(exists($biblStruct/tei:series/tei:title)) then bibl:printSeriesCitation($biblStruct/tei:series, 'span', $lang) else ()
    return 
        element {$wrapperElement} {
            if(exists($authors)) then ($authors, ', ') else (),
            $articleTitle,
            ', in: ',
            $bookTitle,
            if(exists($editor)) then (concat(', ', lang:get-language-string('edBy', $lang), ' '), $editor) else (),
            if(exists($series)) then (' ',<xhtml:span>({$series})</xhtml:span>) else (),
            if(exists($pubPlaceNYear)) then (', ', $pubPlaceNYear) else(),
            if($biblStruct//tei:imprint/tei:biblScope[@type = 'pp']) then concat(', ', lang:get-language-string('pp', $lang), '&#160;', replace($biblStruct//tei:imprint/tei:biblScope[@type = 'pp'], '-', '–')) else ()
        }
};

(:~
 : Create a bibliographic citation for a journal
 : 1. Helper function for bibl:printArticleCitation() 
 : 2. Function for creating bibliographic citations for writings when the source is a journal
 : 
 : @author Peter Stadler
 : @param $monogr the TEI monogr element with the bibliographic reference of the journal
 : @param $wrapperElement the HTML element for wrapping the output (usually span or li)
 : @param $lang the language switch (en, de)
 : @return element
 :)
declare function bibl:printJournalCitation($monogr as element(tei:monogr), $wrapperElement as xs:string, $lang as xs:string) as element() {
    let $journalTitle := <span class="journalTitle">{string-join($monogr/tei:title/str:normalize-space(.), '. ')}</span>
(:    let $date := concat('(', $monogr/tei:imprint/tei:date, ')'):)
    let $biblScope := bibl:biblScope($monogr/tei:imprint[1], $lang) (:concat(
        if($monogr/tei:imprint/tei:biblScope[@type = 'vol']) then concat(', ', lang:get-language-string('vol', $lang), '&#160;', $monogr/tei:imprint/tei:biblScope[@type = 'vol']) else (),
        if($monogr/tei:imprint/tei:biblScope[@type = 'jg']) then concat(', ', 'Jg.', '&#160;', $monogr/tei:imprint/tei:biblScope[@type = 'jg']) else (),
        if($monogr/tei:imprint/tei:biblScope[@type = 'issue']) then concat(', ', lang:get-language-string('issue', $lang), '&#160;', $monogr/tei:imprint/tei:biblScope[@type = 'issue']) else (),
        if($monogr/tei:imprint/tei:biblScope[@type = 'nr']) then concat(', ', 'Nr.', '&#160;', $monogr/tei:imprint/tei:biblScope[@type = 'nr']) else (),
        if(exists($monogr/tei:imprint/tei:date)) then concat(' ', $date) else (),
        if($monogr/tei:imprint/tei:biblScope[@type = 'pp']) then concat(', ', lang:get-language-string('pp', $lang), '&#160;', replace($monogr/tei:imprint/tei:biblScope[@type = 'pp'], '-', '–')) else (),
        if($monogr/tei:imprint/tei:biblScope[@type = 'col']) then concat(', ', lang:get-language-string('col', $lang), '&#160;', replace($monogr/tei:imprint/tei:biblScope[@type = 'col'], '-', '–')) else ()
    ):)
    return 
        element {$wrapperElement} {
            $journalTitle,
            $biblScope
        }
};

(:~
 : Helper function for various bibl:print*Citation() 
 : 
 : @author Peter Stadler
 : @param $parent the parent element of the tei:biblScope elements (usually tei:imprint or tei:series)
 : @param $lang the language switch (en, de)
 : @return xs:string*
 :)
declare %private function bibl:biblScope($parent as element(), $lang as xs:string) as xs:string {
    concat(
        if($parent/tei:biblScope[@type = 'vol']) then concat(', ', lang:get-language-string('vol', $lang), '&#160;', $parent/tei:biblScope[@type = 'vol']) else (),
        if($parent/tei:biblScope[@type = 'jg']) then concat(', ', 'Jg.', '&#160;', $parent/tei:biblScope[@type = 'jg']) else (),
        if($parent/tei:biblScope[@type = 'issue']) then concat(', ', lang:get-language-string('issue', $lang), '&#160;', $parent/tei:biblScope[@type = 'issue']) else (),
        if($parent/tei:biblScope[@type = 'nr']) then concat(', ', 'Nr.', '&#160;', $parent/tei:biblScope[@type = 'nr']) else (),
        if(exists($parent/tei:date)) then concat(' (', $parent/tei:date, ')') else (),
        if($parent/tei:biblScope[@type = 'pp']) then concat(', ', lang:get-language-string('pp', $lang), '&#160;', replace($parent/tei:biblScope[@type = 'pp'], '-', '–')) else (),
        if($parent/tei:biblScope[@type = 'col']) then concat(', ', lang:get-language-string('col', $lang), '&#160;', replace($parent/tei:biblScope[@type = 'col'], '-', '–')) else ()
    )
};

(:~
 : Create a bibliographic citation for a series
 : Helper function for various bibl:print*Citation() 
 : 
 : @author Peter Stadler
 : @param $series the TEI monogr element with the bibliographic reference of the journal
 : @param $wrapperElement the HTML element for wrapping the output (usually span or li)
 : @param $lang the language switch (en, de)
 : @return element
 :)
declare %private function bibl:printSeriesCitation($series as element(tei:series), $wrapperElement as xs:string, $lang as xs:string) as element() {
    let $seriesTitle := string-join($series/tei:title/str:normalize-space(.), '. ')
(:    let $date := concat('(', $monogr/tei:imprint/tei:date, ')'):)
    let $biblScope := concat(
        if($series/tei:biblScope[@type = 'vol']) then concat(', ', lang:get-language-string('vol', $lang), '&#160;', $series/tei:biblScope[@type = 'vol']) else (),
        if($series/tei:biblScope[@type = 'issue']) then concat(', ', lang:get-language-string('issue', $lang), '&#160;', $series/tei:biblScope[@type = 'issue']) else ()
    )
    return 
        element {$wrapperElement} {
            <xhtml:span class="seriesTitle">{$seriesTitle}</xhtml:span>,
            $biblScope
        }
};

(:~
 : Helper function for bibl:print*Citation() functions
 : 
 : @author Peter Stadler
 : @param $authors zero or more tei:author or tei:editor elements 
 : @param $lang the language switch (en, de)
 : @return item
 :)
 
declare %private function bibl:printCitationAuthors($authors as element()*, $lang as xs:string) as item()* {
    let $countAuthors := count($authors)
    return 
        for $i at $counter in $authors
        let $authorElem :=
            if($i/@sameAs) then $i/root()/id($i/substring(@sameAs, 2))
            else $i
        let $author := <span class="{local-name($i)}">{str:printFornameSurname(str:normalize-space($authorElem))}</span>
        return (
            $author,
            if($counter lt $countAuthors - 1) then ', '
            else if($counter eq $countAuthors - 1) then concat(' ', lang:get-language-string('and', $lang), ' ')
            else ()
        )
};

(:~
 : Helper function for bibl:print*Citation() functions
 : Creates a html:span element with pubPlaces and date as content 
 : 
 : @author Peter Stadler
 : @param $imprint a tei:imprint element 
 : @return html:span element if any data is given, the empty sequence otherwise
 :)
 
declare %private function bibl:printpubPlaceNYear($imprint as element(tei:imprint)) as element(span)? {
    let $countPlaces := count($imprint/tei:pubPlace)
    let $places := 
        for $place at $count in $imprint/tei:pubPlace
        return (
            if($count eq $countPlaces) then normalize-space($place)
            else if($count eq $countPlaces - 1) then concat(normalize-space($place), ' &amp; ')
            else concat(normalize-space($place), ', ')
        )
    return 
        if($countPlaces ge 1 or $imprint/tei:date/@when castable as xs:date or $imprint/tei:date/@when castable as xs:gYear) then <span class="placeNYear">{string-join($places, ''), normalize-space($imprint/tei:date)}</span>
        else ()
};
