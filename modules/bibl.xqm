xquery version "3.0" encoding "UTF-8";

module namespace bibl="http://xquery.weber-gesamtausgabe.de/modules/bibl";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/str.xqm";
import module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util" at "wega-util.xqm";
import module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/date.xqm";
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
declare function bibl:printCitation($biblStruct as element(tei:biblStruct), $wrapperElement as element(), $lang as xs:string) as element()? {
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
    else if($biblStruct/tei:analytic and $biblStruct/tei:monogr/tei:title/@level = 'm') then bibl:printIncollectionCitation($biblStruct, $wrapperElement, $lang)
    else if($biblStruct/tei:monogr/tei:title/@level = 'j') then bibl:printArticleCitation($biblStruct, $wrapperElement, $lang)
    else if($biblStruct/tei:monogr/tei:title/@level = 'm') then bibl:printBookCitation($biblStruct, $wrapperElement, $lang)
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
declare function bibl:printGenericCitation($biblStruct as element(tei:biblStruct), $wrapperElement as element(), $lang as xs:string) as element() {
    let $authors := bibl:printCitationAuthors($biblStruct/*/tei:author, $lang)
    let $title := bibl:printTitles($biblStruct/*/tei:title)
    let $note := bibl:printNote($biblStruct/tei:note[1])
    return 
        element {$wrapperElement/name()} {
            $wrapperElement/@*,
            $authors,
            if(exists($authors)) then ', ' else (),
            $title,
            $note
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
declare function bibl:printBookCitation($biblStruct as element(tei:biblStruct), $wrapperElement as element(), $lang as xs:string) as element() {
    let $authors := bibl:printCitationAuthors($biblStruct/tei:monogr/tei:author, $lang)
    let $editors := bibl:printCitationAuthors($biblStruct/tei:monogr/tei:editor, $lang)
    let $series := if(exists($biblStruct/tei:series/tei:title)) then bibl:printSeriesCitation($biblStruct/tei:series, <xhtml:span/>, $lang) else ()
    let $title := bibl:printTitles($biblStruct/tei:monogr/tei:title)
    let $pubPlaceNYear := bibl:printpubPlaceNYear($biblStruct/tei:monogr/tei:imprint, $lang)
    let $note := bibl:printNote($biblStruct/tei:note[1])
    return 
        element {$wrapperElement/name()} {
            $wrapperElement/@* except $wrapperElement/@class,
            attribute class {string-join(($wrapperElement/@class,'book'), ' ')},
            if(exists($authors)) then ($authors, ', ') 
            else if(exists($editors)) then ($editors, concat(' (', lang:get-language-string('ed', $lang), '), '))
            else (), 
            $title,
            if(exists($editors) and exists($authors)) then (concat(', ', lang:get-language-string('edBy', $lang), ' '), $editors) else (),
            if(exists($series)) then (' (', $series, '), ') else ', ',
            if($biblStruct/tei:monogr/tei:imprint/tei:biblScope[@unit = 'vol']) then concat(lang:get-language-string('vol', $lang), '&#160;', $biblStruct/tei:monogr/tei:imprint/tei:biblScope[@unit = 'vol'], ', ') else (),
            $pubPlaceNYear,
            if($biblStruct/tei:monogr/tei:imprint/tei:biblScope[@unit = 'pp']) then concat(', ', lang:get-language-string('pp', $lang), '&#160;', replace($biblStruct/tei:monogr/tei:imprint/tei:biblScope[@unit = 'pp'], '-', '–')) else (),
            $note
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
declare function bibl:printArticleCitation($biblStruct as element(tei:biblStruct), $wrapperElement as element(), $lang as xs:string) as element() {
    let $authors := bibl:printCitationAuthors($biblStruct/tei:analytic/tei:author, $lang) 
    let $articleTitle := $biblStruct/tei:analytic/tei:title (: could be several subtitles:)
    let $journalCitation := bibl:printJournalCitation($biblStruct/tei:monogr, <xhtml:span/>, $lang)
    let $note := bibl:printNote($biblStruct/tei:note[1])
    return 
        element {$wrapperElement/name()} {
            $wrapperElement/@*,
            if(exists($authors)) then ($authors, ', ') else (), 
            if($biblStruct[@type='review']) then '[' || lang:get-language-string('review', $lang) || '] ' else (),
            if($articleTitle) then (bibl:printTitles($articleTitle), ', in: ') else (),
            $journalCitation/xhtml:span,
            $journalCitation/text(),
            $note
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
declare function bibl:printIncollectionCitation($biblStruct as element(tei:biblStruct), $wrapperElement as element(), $lang as xs:string) as element() {
    let $authors := bibl:printCitationAuthors($biblStruct/tei:analytic/tei:author, $lang)
    let $editor := bibl:printCitationAuthors($biblStruct/tei:monogr/tei:editor, $lang)
    let $articleTitle := bibl:printTitles($biblStruct/tei:analytic/tei:title)
    let $bookTitle := <xhtml:span class="collectionTitle">{bibl:printTitles($biblStruct/tei:monogr/tei:title)/node()}</xhtml:span>
    let $pubPlaceNYear := bibl:printpubPlaceNYear($biblStruct/tei:monogr/tei:imprint, $lang)
    let $series := if(exists($biblStruct/tei:series/tei:title)) then bibl:printSeriesCitation($biblStruct/tei:series, <xhtml:span/>, $lang) else ()
    let $note := bibl:printNote($biblStruct/tei:note[1])
    return 
        element {$wrapperElement/name()} {
            $wrapperElement/@*,
            if(exists($authors)) then ($authors, ', ') else (),
            $articleTitle,
            ', in: ',
            $bookTitle,
            if(exists($editor)) then (concat(', ', lang:get-language-string('edBy', $lang), ' '), $editor) else (),
            if(exists($series)) then (' ',<xhtml:span>({$series})</xhtml:span>) else (),
            if(exists($pubPlaceNYear)) then (', ', $pubPlaceNYear) else(),
            if($biblStruct/tei:monogr/tei:imprint/tei:biblScope[@unit = 'pp']) then concat(', ', lang:get-language-string('pp', $lang), '&#160;', replace($biblStruct/tei:monogr/tei:imprint/tei:biblScope[@unit = 'pp'], '-', '–')) else (),
            $note
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
declare function bibl:printJournalCitation($monogr as element(tei:monogr), $wrapperElement as element(), $lang as xs:string) as element() {
    let $journalTitle := <xhtml:span class="journalTitle">{bibl:printTitles($monogr/tei:title)/node()}</xhtml:span>
    let $biblScope := bibl:biblScope($monogr/tei:imprint[1], $lang)
    return 
        element {$wrapperElement/name()} {
            $wrapperElement/@*,
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
        if($parent/tei:biblScope/@unit = 'vol') then concat(', ', lang:get-language-string('vol', $lang), '&#160;', $parent/tei:biblScope[@unit = 'vol']) else (),
        if($parent/tei:biblScope/@unit = 'jg') then concat(', ', 'Jg.', '&#160;', $parent/tei:biblScope[@unit = 'jg']) else (),
        (: Vierstellige Jahresangaben werden direkt nach vol oder bd ausgegeben :)
        if(matches(normalize-space($parent/tei:date), '^\d{4}$') and $parent/tei:biblScope/@unit = ('vol', 'jg')) then concat(' (', $parent/tei:date, ')') else (),
        if($parent/tei:biblScope/@unit = 'issue') then concat(', ', lang:get-language-string('issue', $lang), '&#160;', $parent/tei:biblScope[@unit = 'issue']) else (),
        if($parent/tei:biblScope/@unit = 'nr') then concat(', ', 'Nr.', '&#160;', $parent/tei:biblScope[@unit = 'nr']) else (),
        (: Alle anderen Datumsausgaben hier :)
        if(string-length(normalize-space($parent/tei:date)) gt 4 or (string-length(normalize-space($parent/tei:date)) gt 0 and not($parent/tei:biblScope/@unit = ('vol', 'jg')))) then concat(' (', $parent/tei:date, ')') else (),
        if($parent/tei:note/@type = 'additional') then concat(' ', $parent/tei:note[@type = 'additional']) else (),
        if($parent/tei:biblScope/@unit = 'pp') then concat(', ', lang:get-language-string('pp', $lang), '&#160;', replace($parent/tei:biblScope[@unit = 'pp'], '-', '–')) else (),
        if($parent/tei:biblScope/@unit = 'col') then concat(', ', lang:get-language-string('col', $lang), '&#160;', replace($parent/tei:biblScope[@unit = 'col'], '-', '–')) else (),
        if($parent/tei:biblScope/@unit = 'leaf') then concat(', ', lang:get-language-string('leaf', $lang), '&#160;', replace($parent/tei:biblScope[@unit = 'leaf'], '-', '–')) else ()
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
declare %private function bibl:printSeriesCitation($series as element(tei:series), $wrapperElement as element(), $lang as xs:string) as element() {
    let $biblScope := concat(
        if($series/tei:biblScope[@unit = 'vol']) then concat(', ', lang:get-language-string('vol', $lang), '&#160;', $series/tei:biblScope[@unit = 'vol']) else (),
        if($series/tei:biblScope[@unit = 'issue']) then concat(', ', lang:get-language-string('issue', $lang), '&#160;', $series/tei:biblScope[@unit = 'issue']) else ()
    )
    return 
        element {$wrapperElement/name()} {
            $wrapperElement/@*,
            <xhtml:span class="seriesTitle">{bibl:printTitles($series/tei:title)/node()}</xhtml:span>,
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
        let $author := <xhtml:span class="{local-name($i)}">{wega-util:print-forename-surname-from-nameLike-element($authorElem)}</xhtml:span>
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
declare %private function bibl:printpubPlaceNYear($imprint as element(tei:imprint), $lang as xs:string) as element(xhtml:span)? {
    let $countPlaces := count($imprint/tei:pubPlace)
    let $places := 
        for $place at $count in $imprint/tei:pubPlace
        return (
            if($count eq $countPlaces) then normalize-space($place)
            else if($count eq $countPlaces - 1) then concat(normalize-space($place), ' &amp; ')
            else concat(normalize-space($place), ', ')
        )
    let $date := 
        if($imprint/tei:date/text()) then normalize-space($imprint/tei:date)
        else if($imprint/tei:date/@when castable as xs:date) then date:printDate($imprint/tei:date/@when, $lang, lang:get-language-string#3, $config:default-date-picture-string)
        else if($imprint/tei:date/@when castable as xs:gYear) then $imprint/tei:date/string(@when)
        else ()
    return 
        if($countPlaces ge 1 or $date) then <xhtml:span class="placeNYear">{string-join($places, ''), $date}</xhtml:span>
        else ()
};

(:~
 : Helper function for bibl:print*Citation() functions
 : Knits together title and subtitles 
 : 
 : @author Peter Stadler
 : @param $titles the titles  
 : @return html:span element if any data is given, the empty sequence otherwise
 :)
declare %private function bibl:printTitles($titles as element(tei:title)*) as element(xhtml:span)? {
    let $formattedTitles := wega-util:transform($titles, doc(concat($config:xsl-collection-path, '/var.xsl')), config:get-xsl-params(()))
    return
        if(count($formattedTitles[.]) gt 0) then
            <xhtml:span class="title">{
                for $title at $pos in $formattedTitles
                return 
                    typeswitch($title)
                    case xs:string return 
                        if($pos eq count($titles)) then $title
                        else if(matches($title, '[\?!;\.,…]["]?\s*$')) then concat($title, ' ')
                        else concat($title, '. ')
                    case element() return 
                        if($pos eq count($titles)) then $title/node()
                        else if(matches($title, '[\?!;\.,…]["]?\s*$')) then ($title/node(), ' ')
                        else ($title/node(), '. ')
                    default return ()
            }</xhtml:span>
        else ()
};

(:~
 : Create note marker and popover for notes which are a direct child of biblStruct
~:)
declare %private function bibl:printNote($notes as element(tei:note)*) as element(xhtml:a)? {
    for $note in $notes
    let $id := 
        if($note/@xml:id) then $note/data(@xml:id)
        else generate-id($note)
    let $content := str:txtFromTEI($note/node(), config:guess-language(()))
    return
        <xhtml:a class="noteMarker" data-toggle="popover" data-popover-title="Anmerkung" id="{$id}" data-popover-body="{$content}">*</xhtml:a>
};
