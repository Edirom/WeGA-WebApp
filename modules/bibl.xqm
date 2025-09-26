xquery version "3.1" encoding "UTF-8";

module namespace bibl="http://xquery.weber-gesamtausgabe.de/modules/bibl";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace crud="http://xquery.weber-gesamtausgabe.de/modules/crud" at "crud.xqm";
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
    let $title := bibl:printTitles($biblStruct/*/tei:title, $biblStruct/*/tei:edition)
    let $note := bibl:printNote($biblStruct/tei:note[1], $lang)
    let $imprint := bibl:printpubPlaceNYear($biblStruct/tei:monogr/tei:imprint, $biblStruct/tei:monogr/tei:edition, $lang)
    return 
        element {$wrapperElement/name()} {
            $wrapperElement/@*,
            $authors,
            if(exists($authors)) then ', ' else (),
            $title,
            $imprint,
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
    let $title := bibl:printTitles($biblStruct/tei:monogr/tei:title, $biblStruct/tei:monogr/tei:edition)
    let $pubPlaceNYear := bibl:printpubPlaceNYear($biblStruct/tei:monogr/tei:imprint, $biblStruct/tei:monogr/tei:edition, $lang)
    let $note := bibl:printNote($biblStruct/tei:note[1], $lang)
    return 
        element {$wrapperElement/name()} {
            $wrapperElement/@* except $wrapperElement/@class,
            attribute class {string-join(($wrapperElement/@class,'book'), ' ')},
            if(exists($authors)) then ($authors, ', ') 
            else if(exists($editors)) then ($editors, concat(' (', lang:get-language-string('ed', $lang), '), '))
            else (), 
            $title,
            if(exists($editors) and exists($authors)) then bibl:edited-by($biblStruct, $lang) else (),
            if(exists($series)) then (' (', $series, '), ') else ', ',
            if($biblStruct/tei:monogr/tei:imprint/tei:biblScope[@unit = 'vol']) then bibl:print-single-biblScope-unit((), $biblStruct/tei:monogr/tei:imprint/tei:biblScope[@unit = 'vol'], $lang) || ', ' else (),
            $pubPlaceNYear,
            if($biblStruct/tei:monogr/tei:imprint/tei:biblScope[@unit = 'pp']) then bibl:print-single-biblScope-unit(', ', $biblStruct/tei:monogr/tei:imprint/tei:biblScope[@unit = 'pp'], $lang) else (),
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
    let $note := bibl:printNote($biblStruct/tei:note[1], $lang)
    return 
        element {$wrapperElement/name()} {
            $wrapperElement/@*,
            if(exists($authors)) then ($authors, ', ') else (), 
            if($biblStruct[@type='review']) then '[' || lang:get-language-string('review', $lang) || '] ' else (),
            if($articleTitle) then (bibl:printTitles($articleTitle, ()), ', in: ') else (),
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
    let $articleTitle := bibl:printTitles($biblStruct/tei:analytic/tei:title, ())
    let $bookTitle := <xhtml:span class="collectionTitle">{bibl:printTitles($biblStruct/tei:monogr/tei:title, $biblStruct/tei:monogr/tei:edition)/node()}</xhtml:span>
    let $pubPlaceNYear := bibl:printpubPlaceNYear($biblStruct/tei:monogr/tei:imprint, $biblStruct/tei:monogr/tei:edition, $lang)
    let $series := if(exists($biblStruct/tei:series/tei:title)) then bibl:printSeriesCitation($biblStruct/tei:series, <xhtml:span/>, $lang) else ()
    let $note := bibl:printNote($biblStruct/tei:note[1], $lang)
    return 
        element {$wrapperElement/name()} {
            $wrapperElement/@*,
            if(exists($authors)) then ($authors, ', ') else (),
            $articleTitle,
            ', in: ',
            $bookTitle,
            bibl:edited-by($biblStruct, $lang),
            if(exists($series)) then (' ',<xhtml:span>({$series})</xhtml:span>) else (),
            if(exists($pubPlaceNYear)) then (', ', $pubPlaceNYear) else(),
            if($biblStruct/tei:monogr/tei:imprint/tei:biblScope[@unit = 'pp']) then concat(', ', lang:get-language-string('pp', $lang), '&#160;', bibl:normalize-hyphen($biblStruct/tei:monogr/tei:imprint/tei:biblScope[@unit = 'pp'])) else (),
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
    let $journalTitle := <xhtml:span class="journalTitle">{bibl:printTitles($monogr/tei:title, $monogr/tei:edition)/node()}</xhtml:span>
    let $biblScope := bibl:biblScope($monogr, $lang)
    return 
        element {$wrapperElement/name()} {
            $wrapperElement/@*,
            $journalTitle,
            $biblScope
        }
};

(:~
 : Helper function to print biblScopes of one or many imprint elements
 : 
 : @author Peter Stadler
 : @param $monogr the parent element of the tei:imprint elements that contain tei:biblScopes
 : @param $lang the language switch (en, de)
 : @return xs:string*
 :)
declare %private function bibl:biblScope($monogr as element(tei:monogr), $lang as xs:string) as xs:string {
    concat(
        bibl:format-biblScope-units($monogr, 'vol', $lang),
        bibl:format-biblScope-units($monogr, 'jg', $lang),
        (: Vierstellige Jahresangaben werden direkt nach vol oder bd ausgegeben :)
        if(matches(normalize-space($monogr/tei:imprint[1]/tei:date), '^\d{4}$') and $monogr/tei:imprint[1]/tei:biblScope/@unit = ('vol', 'jg')) then concat(' (', $monogr/tei:imprint[1]/tei:date, ')') else (),
        bibl:format-biblScope-units($monogr, 'issue', $lang),
        bibl:format-biblScope-units($monogr, 'nr', $lang),
        (: Alle anderen Datumsausgaben hier :)
        if(string-length(normalize-space($monogr/tei:imprint[1]/tei:date)) gt 4 or (string-length(normalize-space($monogr/tei:imprint[1]/tei:date)) gt 0 and not($monogr/tei:imprint[1]/tei:biblScope/@unit = ('vol', 'jg')))) then bibl:format-multi-dates($monogr, $lang) else (),
        if($monogr/tei:imprint[1]/tei:note/@type = 'additional') then concat(' ', $monogr/tei:imprint[1]/tei:note[@type = 'additional']) else (),
        bibl:format-biblScope-units($monogr, 'pp', $lang),
        bibl:format-biblScope-units($monogr, 'col', $lang),
        bibl:format-biblScope-units($monogr, 'leaf', $lang)
    )
};

(:~
 : Helper function for bibl:biblScope to collapse tei:biblScopes from several tei:imprint elements into a citation format
 : Splits biblScope values into strings and integers, then splits integer values into runs (non consecutive numbers) and collapses them into ranges
 : 
 : @author Steffen Astheimer
 : @param $monogr the parent element of the tei:imprint elements that contain tei:biblScopes
 : @param $unit the unit that is to be displayed
 : @param $lang the language switch (en, de)
 : @return xs:string
 :)
declare %private function bibl:format-biblScope-units($monogr as element(tei:monogr), $unit as xs:string, $lang as xs:string) as xs:string {
  let $biblScopes := $monogr/tei:imprint/tei:biblScope[@unit = $unit]
  let $values :=
    distinct-values(
      for $biblScope in $biblScopes
      let $value := normalize-space(string($biblScope))
      where $value ne ''
      return $value
    )
  let $citationString :=
    if ($unit = ('pp', 'col', 'leaf')) then bibl:join-list($values)
    else
      let $strValues := $values[not(. castable as xs:integer)]
      let $intValues := 
        for $value in $values[. castable as xs:integer]
        return xs:integer($value)
      let $runStartsPositions :=
        for $value at $position in $intValues
        return if($position = 1 or $intValues[$position] != $intValues[$position - 1] + 1) then $position else ()
      let $runEndsValues :=
        for $value at $position in $runStartsPositions
        return if($position lt count($runStartsPositions))
               then $intValues[$runStartsPositions[$position + 1] - 1]
               else $intValues[last()]
      let $collapsedIntValues :=
        for $value at $position in $runStartsPositions
        let $first := $intValues[$value]
        let $last := $runEndsValues[$position]
        return if($first = $last) then string($first) else concat(string($first), '–', string($last))
      return bibl:join-list(($collapsedIntValues, $strValues)) (: currently seperates ints from strings, if bibl documents mix both types the rendering will be wrong:)
  return 
    if($citationString = '') then ''
    else bibl:print-single-biblScope-unit(', ', <tei:biblScope unit="{$unit}">{$citationString}</tei:biblScope>, $lang)
};

(:~
 : Helper function for bibl:format-biblScope-units to collapse tei:dates from several tei:imprint elements into a citation format
 : Will group by year and month and concatenate the days with commas, naming each corresponding month and year only once at the end of a group
 : This might lead to unwanted / unhelpful rendering if a group of imprints ranges over the change of a year
 : 
 : @author Steffen Astheimer
 : @param $monogr the parent element of the tei:imprint elements that contain tei:biblScopes
 : @param $lang the language switch (en, de)
 : @return xs:string
 :)
declare %private function bibl:format-multi-dates($monogr as element(tei:monogr), $lang as xs:string) as xs:string? {
  if(count($monogr/tei:imprint) = 1) then concat(' (', $monogr/tei:imprint/tei:date, ')')
  else
    let $whenValues :=
      for $date in $monogr/tei:imprint/tei:date[@when]
      let $when := normalize-space(string($date/@when))
      where $when ne ''
      return $when
    return
      if(empty($whenValues)) then ''
      else if(every $when in $whenValues satisfies matches($when, '^\d{4}$')) then concat(' (', bibl:join-list(distinct-values($whenValues)), ')')
      else
        let $parsed :=
          for $when in $whenValues
          where matches($when, '^\d{4}-\d{2}-\d{2}$')
          let $year := xs:integer(substring($when, 1, 4))
          let $month := xs:integer(substring($when, 6, 2))
          let $day := xs:integer(substring($when, 9, 2))
          return map { "year": $year, "month": $month, "day": $day }
        return
            let $years := distinct-values($parsed?year)
            let $multiYears := count($years) gt 1
            let $yearGroups :=
              for $year in $years
              let $inYear := $parsed[$parsed?year = $year]
              let $months := distinct-values($inYear?month)
              let $monthPieces :=
                for $month in $months
                let $days := 
                  distinct-values(
                    for $p in $inYear
                    where $p?month = $month
                    return $p?day
                  )
                let $dayStrings := for $day in $days return concat($day, '.')
                let $dayList := bibl:join-list($dayStrings)
                let $monthName := lang:get-language-string(concat('month', $month), $lang)
                return
                  if ($multiYears) then concat($dayList, ' ', $monthName, ' ', $year)
                  else concat($dayList, ' ', $monthName)
              let $monthsJoined := bibl:join-list($monthPieces)
              return
                if ($multiYears) then $monthsJoined
                else concat($monthsJoined, ' ', $year)
            return concat(' (', bibl:join-list($yearGroups), ')')
};

(:~
 : Helper function for bibl:biblScope#2
 :)
declare %private function bibl:print-single-biblScope-unit($separator as xs:string?, $biblScope as element(tei:biblScope), $lang as xs:string) as xs:string {
    concat(
        $separator,
        (: eventually add brackets, see https://github.com/Edirom/WeGA-WebApp/issues/460 :)
        if($biblScope/@rend='bracketed') then '[' else (),
        lang:get-language-string($biblScope/@unit, $lang),
        '&#160;',
        bibl:normalize-hyphen($biblScope),
        if($biblScope/@rend='bracketed') then ']' else ()
    )
};

(:~
 : Helper function for bibl:format-biblScope-units and bibl:format-multi-dates to collapse multiple strings
 :)
declare %private function bibl:join-list($items as xs:string*) as xs:string {
  if (empty($items)) then ''
  else if (count($items) = 1) then $items[1]
  else if (count($items) = 2) then string-join($items, ' und ')
  else string-join($items[position() lt last()], ', ') || ' und ' || $items[last()]
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
            <xhtml:span class="seriesTitle">{bibl:printTitles($series/tei:title, ())/node()}</xhtml:span>,
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
        let $prefix := 
            if($authorElem/@full) 
            then '[' || lang:get-language-string('siglum', $lang) || '] ' 
            else ()
        let $author := <xhtml:span class="{local-name($i)}">{$prefix || wega-util:print-forename-surname-from-nameLike-element($authorElem)}</xhtml:span>
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
declare %private function bibl:printpubPlaceNYear($imprint as element(tei:imprint)?, $edition as element(tei:edition)?, $lang as xs:string) as element(xhtml:span)? {
    let $countPlaces := count($imprint/tei:pubPlace)
    let $places := 
        for $place at $count in $imprint/tei:pubPlace
        return (
            if($count eq $countPlaces) then normalize-space($place)
            else if($count eq $countPlaces - 1) then concat(normalize-space($place), ' &amp; ')
            else concat(normalize-space($place), ', ')
        )
    let $date := (
        if($edition castable as xs:integer)
        then (' ', <xhtml:sup>{number($edition)}</xhtml:sup>)
        else (),
        if($imprint/tei:date/text()) then normalize-space($imprint/tei:date)
        else if($imprint/tei:date/@when castable as xs:date) then date:printDate($imprint/tei:date/@when, $lang, lang:get-language-string#3, $config:default-date-picture-string)
        else if($imprint/tei:date/@when castable as xs:gYear) then $imprint/tei:date/string(@when)
        else ()
    )
    return 
        if($countPlaces ge 1 or $date) then <xhtml:span class="placeNYear">{string-join($places, ''), $date}</xhtml:span>
        else ()
};

(:~
 : Helper function for bibl:print*Citation() functions
 : Knits together title, subtitles, and edition (if these are not simple numbers)
 : 
 : @author Peter Stadler
 : @param $titles the titles  
 : @return html:span element if any data is given, the empty sequence otherwise
 :)
declare %private function bibl:printTitles($titles as element(tei:title)*, $edition as element(tei:edition)?) as element(xhtml:span)? {
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
                    default return (),
                if($edition and not($edition castable as xs:integer))
                then <xhtml:span class="edition">{', ' || $edition}</xhtml:span>
                else ()
            }</xhtml:span>
        else ()
};

(:~
 : Create note marker and popover for notes which are a direct child of biblStruct
 :)
declare %private function bibl:printNote($notes as element(tei:note)*, $lang as xs:string) as element()* {
    for $note in $notes
    let $id := 
        if($note/@xml:id) then $note/data(@xml:id)
        else generate-id($note)
    let $content := wega-util:transform(
        $note, 
        doc(concat($config:xsl-collection-path, '/var.xsl')), 
        config:get-xsl-params(())
    )
    return (
        <xhtml:a class="noteMarker biblioNote" data-toggle="popover" data-ref="#{$id}">*</xhtml:a>,
        <xhtml:div id="{$id}" data-title="{lang:get-language-string('gl_note', $lang)}" style="display:none;">{$content}</xhtml:div>
      )
};

(:~
 : Replace standard hyphens with ndashs 
 :)
declare %private function bibl:normalize-hyphen($biblScope as element(tei:biblScope)) as xs:string {
    replace($biblScope, '-', '–')
};

(:~
 : Process editors
 : Helper function for bibl:printBookCitation and bibl:printIncollectionCitation
 :)
declare %private function bibl:edited-by($biblStruct as element(tei:biblStruct), $lang as xs:string) as item()* {
    let $editors := bibl:printCitationAuthors($biblStruct/tei:monogr/tei:editor, $lang)
    let $ders as xs:boolean := 
        count($biblStruct/tei:monogr/tei:editor) eq 1 and 
        count($biblStruct/tei:analytic/tei:author) eq 1 and 
        exists($biblStruct/tei:monogr/tei:editor/@key) and
        exists($biblStruct/tei:analytic/tei:author/@key) and
        $biblStruct/tei:monogr/tei:editor/@key = $biblStruct/tei:analytic/tei:author/@key
    let $dens as xs:boolean :=
        count($biblStruct/tei:monogr/tei:editor) gt 1 and 
        count($biblStruct/tei:analytic/tei:author) gt 1 and
        count($biblStruct/tei:analytic/tei:author) eq count($biblStruct/tei:monogr/tei:editor) and 
        (every $i in ($biblStruct/tei:analytic/tei:author | $biblStruct/tei:monogr/tei:editor) satisfies $i/@key) and 
        (every $i in $biblStruct/tei:analytic/tei:author/@key satisfies $i = $biblStruct/tei:monogr/tei:editor/@key)
    let $sex := 
        if($ders)
        then crud:doc($biblStruct/tei:monogr/tei:editor/@key)//tei:sex
        else ()
    return
        if(exists($editors)) 
        then 
            if($dens)
            then (concat(', ', lang:get-language-string('edBy', $lang), ' '), <xhtml:span class="editor">{lang:get-language-string('edByIdemPl', $lang)}</xhtml:span>)
            else
                if($sex = 'm') 
                then (concat(', ', lang:get-language-string('edBy', $lang), ' '), <xhtml:span class="editor">{lang:get-language-string('edByIdemM', $lang)}</xhtml:span>)
                else 
                    if($sex = 'f') 
                    then (concat(', ', lang:get-language-string('edBy', $lang), ' '), <xhtml:span class="editor">{lang:get-language-string('edByIdemF', $lang)}</xhtml:span>)
                    else (concat(', ', lang:get-language-string('edBy', $lang), ' '), $editors) 
        else ()
};
