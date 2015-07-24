xquery version "3.0";

(:~
 : XQuery module for creating normalized lists of documents
 :)
module namespace norm="http://xquery.weber-gesamtausgabe.de/modules/norm";
declare default collation "?lang=de;strength=primary";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date" at "date.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "str.xqm";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";

import module namespace datetime="http://exist-db.org/xquery/datetime" at "java:org.exist.xquery.modules.datetime.DateTimeModule";
import module namespace functx="http://www.functx.com";

(:~
 : Main entry function
 : Returns a sorted and normalized catalogue of all documents for a given typ 
 :  
 : @author Peter Stadler
 : @param $docType The WeGA document typ, e.g. 'writings', 'letters'
 : @return the norm file as document-node()
 :)
declare function norm:get-norm-doc($docType as xs:string) as document-node()? {
    let $fileName := 'normFile-' || $docType || '.xml'
    return 
        if($config:wega-docTypes($docType)) then
            try {
                core:cache-doc(str:join-path-elements(($config:tmp-collection-path, $fileName)), norm:create-norm-doc#1, $docType, xs:dayTimeDuration('P999D'))
            }
            catch * { core:logToFile('error', string-join(('norm:get-norm-doc', $err:code, $err:description), ' ;; ')) }
        else core:logToFile('warn', 'norm:get-norm-doc: Unsupported docType "' || $docType || '". Please refer to those defined in $config:wega-docTypes')
};

declare function norm:create-norm-doc($docType as xs:string) as element(norm:catalogue)? {
    switch ($docType)
        case 'biblio' return norm:create-norm-doc-biblio()
        case 'diaries' return norm:create-norm-doc-diaries()
        case 'letters' return norm:create-norm-doc-letters()
        case 'news' return norm:create-norm-doc-news()
        case 'persons' return norm:create-norm-doc-persons()
        case 'writings' return norm:create-norm-doc-writings()
        case 'works' return norm:create-norm-doc-works()
        case 'places' return norm:create-norm-doc-places()
        default return ()
};

declare %private function norm:create-norm-doc-biblio() as element(norm:catalogue) {
    <catalogue xmlns="http://xquery.weber-gesamtausgabe.de/modules/norm">{
        for $doc in core:getOrCreateColl('biblio', 'indices', true())
        let $docID := $doc/tei:*/data(@xml:id)
        let $normDate := date:getOneNormalizedDate($doc//tei:imprint/tei:date, false())
        order by $normDate descending
        return 
            element entry {
                attribute docID {$docID},
                if ($normDate castable as xs:date) then (
                    attribute year {year-from-date($normDate cast as xs:date)}, 
                    attribute month {month-from-date($normDate cast as xs:date)}, 
                    attribute day {day-from-date($normDate cast as xs:date)}) 
                else (),
                $normDate
            }
    }</catalogue>
};

declare %private function norm:create-norm-doc-diaries() as element(norm:catalogue) {
    <catalogue xmlns="http://xquery.weber-gesamtausgabe.de/modules/norm">{
        for $doc in core:getOrCreateColl('diaries', 'indices', true())
        let $docID := $doc/tei:ab/data(@xml:id)
        let $normDate := $doc/tei:ab/string(@n)
        order by $normDate
        return 
            element entry {
                attribute docID {$docID},
                if ($normDate castable as xs:date) then (
                    attribute year {year-from-date($normDate cast as xs:date)}, 
                    attribute month {month-from-date($normDate cast as xs:date)}, 
                    attribute day {day-from-date($normDate cast as xs:date)}) 
                else (),
                $normDate
            }
    }</catalogue>
};

declare %private function norm:create-norm-doc-letters() as element(norm:catalogue) {
    <catalogue xmlns="http://xquery.weber-gesamtausgabe.de/modules/norm">{
        for $doc in core:getOrCreateColl('letters', 'indices', true())
        let $docID := $doc/tei:TEI/data(@xml:id)
        let $normDate := date:getOneNormalizedDate($doc//tei:dateSender/tei:date, false())
        let $n :=  $doc//tei:dateSender/tei:date/data(@n)
(:            let $senderID := $doc//tei:sender/tei:persName[1]/string(@key):)
        let $authorID := $doc//tei:fileDesc/tei:titleStmt/tei:author[1]/string(@key)
        let $addresseeID := $doc//tei:addressee/tei:persName[1]/string(@key)
        order by $normDate, $n
        return 
            element entry {
                attribute docID {$docID},
                attribute n {$n},
                attribute authorID {$authorID},
                attribute addresseeID {$addresseeID},
                if ($normDate castable as xs:date) then (
                    attribute year {year-from-date($normDate cast as xs:date)}, 
                    attribute month {month-from-date($normDate cast as xs:date)}, 
                    attribute day {day-from-date($normDate cast as xs:date)}) 
                else (),
                $normDate
            }
    }</catalogue>
};

declare %private function norm:create-norm-doc-news() as element(norm:catalogue) {
    <catalogue xmlns="http://xquery.weber-gesamtausgabe.de/modules/norm">{
        for $doc in core:getOrCreateColl('news', 'indices', true())
        let $docID := $doc/tei:TEI/data(@xml:id)
        let $normDate := datetime:date-from-dateTime($doc//tei:publicationStmt/tei:date/xs:dateTime(@when))
        order by $normDate descending
        return 
            element entry {
                attribute docID {$docID},
                if ($normDate castable as xs:date) then (
                    attribute year {year-from-date($normDate cast as xs:date)}, 
                    attribute month {month-from-date($normDate cast as xs:date)}, 
                    attribute day {day-from-date($normDate cast as xs:date)}) 
                else (),
                $normDate
            }
    }</catalogue>
};

declare %private function norm:create-norm-doc-persons() as element(norm:catalogue) {
    <catalogue xmlns="http://xquery.weber-gesamtausgabe.de/modules/norm">{
        for $doc in core:getOrCreateColl('persons', 'indices', true())
        let $docID := $doc/tei:person/data(@xml:id)
        let $sex := str:normalize-space($doc//tei:sex)
        let $name := str:normalize-space($doc//tei:persName[@type='reg'])
        let $sortName := core:create-sort-persname($doc/tei:person) 
        order by $sortName ascending, $name ascending
        return 
            element entry {
                attribute docID {$docID},
                attribute sex {$sex},
                attribute sortName {$sortName},
                $name
            }
    }</catalogue>
};

declare %private function norm:create-norm-doc-writings() as element(norm:catalogue) {
    <catalogue xmlns="http://xquery.weber-gesamtausgabe.de/modules/norm">{
        for $doc in core:getOrCreateColl('writings', 'indices', true())
        let $docID := $doc/tei:TEI/data(@xml:id)
        let $normDate := date:getOneNormalizedDate($doc//tei:sourceDesc/tei:*/tei:monogr/tei:imprint/tei:date[1], false())
        let $n :=  string-join($doc//tei:monogr/tei:title[@level = 'j']/str:normalize-space(.), '. ')
        let $authorID := query:get-authorID($doc)
        order by $normDate, $n
        return 
            element entry {
                attribute docID {$docID},
                attribute authorID {$authorID},
                attribute n {$n},
                if ($normDate castable as xs:date) then (
                    attribute year {year-from-date($normDate cast as xs:date)}, 
                    attribute month {month-from-date($normDate cast as xs:date)}, 
                    attribute day {day-from-date($normDate cast as xs:date)}) 
                else (),
                $normDate
            }
    }</catalogue>
};

declare %private function norm:create-norm-doc-works() as element(norm:catalogue) {
    <catalogue xmlns="http://xquery.weber-gesamtausgabe.de/modules/norm">{
        for $doc in core:getOrCreateColl('works', 'indices', true())
        let $docID := $doc/mei:mei/data(@xml:id)
(:        let $normDate := $doc//mei:seriesStmt/mei:title[@level='s']/xs:int(@n):)
        let $title := str:normalize-space(query:get-title-element($doc)[1])
        let $n := $doc//mei:altId[@type = 'WeV']
        (:let $sortCategory02 := $doc//mei:altId[@type = 'WeV']/string(@subtype):) 
        (:let $sortCategory03 := $doc//mei:altId[@type = 'WeV']/xs:int(@n):) 
        (:order by $normDate, $sortCategory02, $sortCategory03, $n:)
        order by $title, $n
        return 
            element entry {
                attribute docID {$docID},
                attribute n {$n},
                (:$normDate:)
                $title
            }
    }</catalogue>
};

declare %private function norm:create-norm-doc-places() as element(norm:catalogue) {
    <catalogue xmlns="http://xquery.weber-gesamtausgabe.de/modules/norm">{
        for $doc in core:getOrCreateColl('places', 'indices', true())
        let $docID := $doc/tei:place/data(@xml:id)
        let $name := str:normalize-space($doc//tei:placeName[@type='reg'])
        let $n := $doc//tei:idno[@type='geonames']
        order by $name
        return 
            element entry {
                attribute docID {$docID},
                attribute n {$n},
                $name
            }
    }</catalogue>
};
