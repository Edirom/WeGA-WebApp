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
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";
import module namespace wdt="http://xquery.weber-gesamtausgabe.de/modules/wdt" at "wdt.xqm";
import module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util" at "wega-util.xqm";
import module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/date.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/str.xqm";
import module namespace mycache="http://xquery.weber-gesamtausgabe.de/modules/cache" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/cache.xqm";

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
    let $docURI := str:join-path-elements(($config:tmp-collection-path, $fileName))
    let $onFailureFunc := function($errCode as item(), $errDesc as item()?) {
        core:logToFile('error', string-join(('norm:get-norm-doc: Unsupported docType ' || $docType, $errCode, $errDesc), ' ;; '))
    }
    let $lease := function($currentDateTimeOfFile as xs:dateTime?) as xs:boolean { wega-util:check-if-update-necessary($currentDateTimeOfFile, ()) }
    return 
        mycache:doc($docURI, norm:create-norm-doc#1, $docType, $lease, $onFailureFunc)
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
(:        case 'places' return norm:create-norm-doc-places():)
        case 'orgs' return norm:create-norm-doc-orgs()
        default return core:logToFile('warn', 'norm:create-norm-doc: Unsupported docType "' || $docType || '". Could not find callback function.')
};

declare %private function norm:create-norm-doc-biblio() as element(norm:catalogue) {
    <catalogue xmlns="http://xquery.weber-gesamtausgabe.de/modules/norm">{
        for $doc in core:getOrCreateColl('biblio', 'indices', true())
        let $docID := $doc/tei:*/data(@xml:id)
        let $normDate := query:get-normalized-date($doc)
        (: $authorIDs should be in sync with the definition at core:createColl()  :)
        let $authorIDs := distinct-values($doc//tei:author/@key | $doc//tei:editor/@key)
(:   collections are already sorted!     :)
(:        order by $normDate descending:)
        return 
            element entry {
                attribute docID {$docID},
                attribute authorID {string-join($authorIDs, ' ')},
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
        let $normDate := query:get-normalized-date($doc)
(:        order by $normDate:)
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
        let $normDate := query:get-normalized-date($doc)
        let $n :=  $doc//tei:correspAction[@type='sent']/tei:date/data(@n)
        (: $authorIDs should be in sync with the definition at core:createColl()  :)
        let $authorIDs := distinct-values($doc//tei:correspAction[@type='sent']//@key[parent::tei:persName or parent::name or parent::tei:orgName])
        let $addresseeIDs := distinct-values($doc//tei:correspAction[@type='received']//@key[parent::tei:persName or parent::name or parent::tei:orgName])
(:        order by $normDate, $n:)
        return 
            element entry {
                attribute docID {$docID},
                attribute n {$n},
                attribute authorID {string-join($authorIDs, ' ')},
                attribute addresseeID {string-join($addresseeIDs, ' ')},
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
        (: $authorIDs should be in sync with the definition at core:createColl()  :)
        let $authorIDs := distinct-values($doc//tei:author[ancestor::tei:fileDesc]/@key)
        let $normDate := query:get-normalized-date($doc) (:datetime:date-from-dateTime($doc//tei:publicationStmt/tei:date/xs:dateTime(@when)):)
(:        order by $normDate descending:)
        return 
            element entry {
                attribute docID {$docID},
                attribute authorID {string-join($authorIDs, ' ')},
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
(:        let $sortName := core:create-sort-persname($doc/tei:person) :)
(:        order by $sortName ascending, $name ascending:)
        return 
            element entry {
                attribute docID {$docID},
                attribute sex {$sex},
(:                attribute sortName {$sortName},:)
                $name
            }
    }</catalogue>
};

declare %private function norm:create-norm-doc-orgs() as element(norm:catalogue) {
    <catalogue xmlns="http://xquery.weber-gesamtausgabe.de/modules/norm">{
        for $doc in core:getOrCreateColl('orgs', 'indices', true())
        let $docID := $doc/tei:org/data(@xml:id)
        let $name := str:normalize-space($doc//tei:orgName[@type='reg'])
(:        order by $name ascending:)
        return 
            element entry {
                attribute docID {$docID},
                $name
            }
    }</catalogue>
};

declare %private function norm:create-norm-doc-writings() as element(norm:catalogue) {
    <catalogue xmlns="http://xquery.weber-gesamtausgabe.de/modules/norm">{
        for $doc in core:getOrCreateColl('writings', 'indices', true())
        let $docID := $doc/tei:TEI/data(@xml:id)
        let $source := query:get-main-source($doc)
        let $normDate := query:get-normalized-date($doc)
        let $n :=  string-join($source/tei:monogr/tei:title[@level = 'j']/str:normalize-space(.), '. ')
        (: $authorIDs should be in sync with the definition at core:createColl()  :)
        let $authorIDs := distinct-values($doc//tei:author[ancestor::tei:fileDesc]/@key)
(:        order by $normDate, $n:)
        return 
            element entry {
                attribute docID {$docID},
                attribute authorID {string-join($authorIDs, ' ')},
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
        let $title := wdt:works($doc)('title')('txt')
        let $n := $doc//mei:altId[@type = 'WeV']
        (:let $sortCategory02 := $doc//mei:altId[@type = 'WeV']/string(@subtype):) 
        (:let $sortCategory03 := $doc//mei:altId[@type = 'WeV']/xs:int(@n):) 
        (:order by $normDate, $sortCategory02, $sortCategory03, $n:)
(:        order by $title, $n:)
        return 
            element entry {
                attribute docID {$docID},
                attribute n {$n},
                (:$normDate:)
                $title
            }
    }</catalogue>
};

(:declare %private function norm:create-norm-doc-places() as element(norm:catalogue) {
    <catalogue xmlns="http://xquery.weber-gesamtausgabe.de/modules/norm">{
        for $doc in core:getOrCreateColl('places', 'indices', true())
        let $docID := $doc/tei:place/data(@xml:id)
        let $name := wdt:places($doc)('title')()
        let $n := $doc//tei:idno[@type='geonames']
(\:        order by $name:\)
        return 
            element entry {
                attribute docID {$docID},
                attribute n {$n},
                $name
            }
    }</catalogue>
};:)
