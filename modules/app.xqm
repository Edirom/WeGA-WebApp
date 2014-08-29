xquery version "3.0" encoding "UTF-8";

module namespace app="http://xquery.weber-gesamtausgabe.de/modules/app";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace templates="http://exist-db.org/xquery/templates";
declare namespace xhtml="http://www.w3.org/1999/xhtml";
(:declare namespace request = "http://exist-db.org/xquery/request";:)
(:declare namespace session = "http://exist-db.org/xquery/session";:)

import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";
import module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date" at "date.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "str.xqm";
import module namespace wega-http="http://xquery.weber-gesamtausgabe.de/modules/wega-http" at "wega-http.xqm";
import module namespace xqjson="http://xqilla.sourceforge.net/lib/xqjson";
import module namespace functx="http://www.functx.com";

declare function app:page-title($node as node(), $model as map(*)) as element(title) {
    <title>{$model('page-title')}</title>
};

declare function app:page-h1($node as node(), $model as map(*)) as element(h1) {
    <h1>{query:get-reg-name($model('docID'))}</h1>
};

(:declare function app:init-doc($node as node(), $model as map(*)) {
    let $docID := tokenize(request:get-uri(), '/')[last()]
    let $doc := core:doc($docID)
    return 
        map{
            'doc' := $doc,
            'docID' := $docID,
            'page-title' := 'Eine Seite aus der WeGA' 
        }
};:)

declare 
    %templates:wrap
    function app:lookup-todays-events($node as node(), $model as map(*)) as map(*) {
    let $events := 
        for $i in query:getTodaysEvents(current-date())
        order by $i/xs:date(@when) ascending
        return $i
    let $length := count($events)
    return
        map {
            'events1' := subsequence($events, 1, ceiling($length div 2)),
            'events2' := subsequence($events, ceiling($length div 2) + 1)
        }
};

declare function app:print-event($node as node(), $model as map(*), $lang as xs:string) as element(span) {
    let $date := current-date()
    let $teiDate := $model('event')
    let $isJubilee := (year-from-date($date) - $teiDate/year-from-date(@when)) mod 25 = 0
    let $typeOfEvent := 
        if($teiDate/ancestor::tei:correspDesc) then 'letter'
        else if($teiDate[@type='baptism']) then 'isBaptised'
        else if($teiDate/parent::tei:birth) then 'isBorn'
        else if($teiDate[@type='funeral']) then 'wasBuried'
        else if($teiDate/parent::tei:death) then 'dies'
        else ()
    return
        element span {
                if($isJubilee) then (
                    attribute class {'jubilee'},
                    attribute title {lang:get-language-string('roundYearsAgo',xs:string(year-from-date($date) - $teiDate/year-from-date(@when)), $lang)}
                )
                else (),
                concat(date:formatYear($teiDate/year-from-date(@when) cast as xs:int, $lang), ': '),
                if($typeOfEvent eq 'letter') then app:createLetterLink($teiDate, $lang)
                (:else (wega:createPersonLink($teiDate/root()/*/string(@xml:id), $lang, 'fs'), ' ', lang:get-language-string($typeOfEvent, $lang)):)
                else (app:createDocLink($teiDate/root(), str:printFornameSurname(query:get-reg-name($teiDate/ancestor::tei:person/@xml:id)), $lang, ()), ' ', lang:get-language-string($typeOfEvent, $lang))
            }
};

declare 
    %templates:wrap
    function app:print-events-title($node as node(), $model as map(*), $lang as xs:string) as element(h2) {
    <h2>{lang:get-language-string('whatHappenedOn', date:strfdate(current-date(), $lang, if($lang eq 'en') then '%B %d' else '%d. %B'), $lang)}</h2>
};

(:~
 : Helper function for app:print-event
 :
 : @author Peter Stadler
 :)
declare %private function app:createLetterLink($teiDate as element(tei:date)?, $lang as xs:string) as item()* {
    let $sender := app:printCorrespondentName($teiDate/ancestor::tei:correspDesc/tei:sender[1]/*[1], $lang, 'fs')
    let $addressee := app:printCorrespondentName($teiDate/ancestor::tei:correspDesc/tei:addressee[1]/*[1], $lang, 'fs')
    return (
        $sender, ' ', lang:get-language-string('writesTo', $lang), ' ', $addressee, 
        if(ends-with($addressee, '.')) then ' ' else '. ', 
        app:createDocLink($teiDate/root(), concat('[', lang:get-language-string('readOnLetter', $lang), ']'), $lang, ('class=readOn'))
    )
};

(:~
 : Creates an xhtml:a link to a WeGA document
 :
 : @author Peter Stadler
 : @param $doc the document to create the link for
 : @param $content the string content for the xhtml a element
 : @param $lang the language switch (en, de)
 : @param $attributes a sequence of attribute-value-pairs, e.g. ('class=xy', 'style=display:block')
 :)
declare function app:createDocLink($doc as document-node(), $content as xs:string, $lang as xs:string, $attributes as xs:string*) as element() {
    let $href := app:createUrlForDoc($doc, $lang)
    let $docID :=  $doc/root()/*/@xml:id
    return 
    element a {
        attribute href {$href},
        if(exists($attributes)) then for $att in $attributes return attribute {substring-before($att, '=')} {substring-after($att, '=')} 
        else (),
        $content
    }
};

(:~
 : Construct a name from a tei:persName or tei:name element wrapped in a <span> with @onmouseover etc.
 : If a @key is given on persName the regularized form will be returned, otherwise the content of persName.
 : If persName is empty than "unknown" is returned.
 : 
 : @author Peter Stadler
 : @param $persName the tei:persName element
 : @param $lang the current language (de|en)
 : @param $order (sf|fs) whether to print "surname, forename" or "forename surname"
 : @return 
 :)
declare function app:printCorrespondentName($persName as element()?, $lang as xs:string, $order as xs:string) as element() {
     if(exists($persName/@key)) then app:createDocLink(core:doc($persName/string(@key)), str:printFornameSurname(query:get-reg-name($persName/@key)), $lang, ())
        (:wega:createPersonLink($persName/string(@key), $lang, $order):)
     else if ($order eq 'fs') then <xhtml:span class="noDataFound">{str:printFornameSurname($persName)}</xhtml:span>
     else if (not(functx:all-whitespace($persName))) then <xhtml:span class="noDataFound">{string($persName)}</xhtml:span>
     else <xhtml:span class="noDataFound">{lang:get-language-string('unknown',$lang)}</xhtml:span>
};

(:~
 : Creates link to doc
 :
 : @author Peter Stadler
 : @param $doc document node
 : @param $lang the current language (de|en)
 : @return xs:string
:)
declare function app:createUrlForDoc($doc as document-node(), $lang as xs:string) as xs:string? {
    let $docID :=  $doc/*/@xml:id cast as xs:string
    let $authorId := query:getAuthorOfTeiDoc($doc)
    let $folder := 
        if(config:is-letter($docID)) then lang:get-language-string('correspondence', $lang) (: Ausnahme für Briefe=Korrespondenz:)
        else if(config:is-weberStudies($doc)) then lang:get-language-string('weberStudies', $lang)
        else lang:get-language-string(config:get-doctype-by-id($docID), $lang)
    return
        if(config:is-person($docID)) then core:link-to-current-app(str:join-path-elements(($lang, $docID))) (: Ausnahme für Personen, die direkt unter {baseref}/{lang}/ angezeigt werden:)
        else if(config:is-biblio($docID)) then 
            if(config:is-weberStudies($doc)) then core:link-to-current-app(str:join-path-elements((lang:get-language-string('publications', $lang), $folder, $docID)))
            else ()
        else if(exists($folder) and $authorId ne '') then core:link-to-current-app(str:join-path-elements(($lang, $authorId, $folder, $docID)))
        else ()
};

(:
 : ****************************
 : Person functions
 : ****************************
:)
declare
    %templates:wrap
    %templates:default("lang", "en")
    function app:breadcrumb-person-2nd-level($node as node(), $model as map(*), $lang as xs:string) as element(a) {
        <a href="{core:link-to-current-app(str:join-path-elements(($lang, $model('docID'))))}">{
            str:printFornameSurname($model('doc')//tei:persName[@type='reg'])
        }</a>
};

declare 
    %templates:wrap
    %templates:default("lang", "en")
    function app:basic-data($node as node(), $model as map(*), $lang as xs:string) as map(*) {
        map{
            'fullnames' := $model('doc')//tei:persName[@type = 'full'],
            'pseudonyme' := $model('doc')//tei:persName[@type = 'pseud'],
            'birthnames' := $model('doc')//tei:persName[@subtype = 'birth'],
            'realnames' := $model('doc')//tei:persName[@type = 'real'],
            'marriednames' := $model('doc')//tei:persName[@subtype = 'married'],
            'births' := date:printDate($model('doc')//tei:birth/tei:date[1], $lang),
            'deaths' := date:printDate($model('doc')//tei:death/tei:date[1], $lang)
        }
};

declare
    %templates:wrap
    function app:print-name($node as node(), $model as map(*), $type as xs:string) as xs:string? {
        if ($model($type)) then $model($type) cast as xs:string 
        else ()
};

declare
    %templates:wrap
    function app:print-date-and-place($node as node(), $model as map(*), $type as xs:string) as xs:string? {
        if ($model($type)) then $model($type) cast as xs:string
        else ()
};

(:declare 
    %templates:wrap
    %templates:default("lang", "en")
    function app:person-details($node as node(), $model as map(*), $lang as xs:string) as map(*) {
        let $letters := core:getOrCreateColl('letters', $model('docID'), true())
        let $diaries := core:getOrCreateColl('diaries', $model('docID'), true())
        let $writings := core:getOrCreateColl('writings', $model('docID'), true())
        let $works := core:getOrCreateColl('works', $model('docID'), true())
        let $contacts := distinct-values(core:getOrCreateColl('letters', $model('docID'), true())//@key[ancestor::tei:correspDesc][. != $model('docID')])
        let $tabTitles := (
            if(not(empty($letters))) then lang:get-language-string('correspondence', $lang) || ' (' || count($letters) || ')' else (),
            if(not(empty($diaries))) then lang:get-language-string('diaries', $lang) || ' (' || count($diaries) || ')' else (),
            if(not(empty($writings))) then lang:get-language-string('writings', $lang) || ' (' || count($writings) || ')' else (),
            if(not(empty($works))) then lang:get-language-string('works', $lang) || ' (' || count($works) || ')' else (),
            if(not(empty($contacts))) then lang:get-language-string('contacts', $lang) || ' (' || count($contacts) || ')' else ()
        ) 
        return
            map{
                'letters' := $letters,
                'diaries' := $diaries,
                'writings' := $writings,
                'works' := $works,
                'contacts' := $contacts,
                'tabTitles' := $tabTitles
            }
};
:)

declare 
    %templates:wrap
    function app:person-details($node as node(), $model as map(*)) as map(*) {
        let $docTypes := map:new(
            for $docType in map:keys($config:wega-docTypes)
            return 
                map:entry($docType, core:getOrCreateColl($docType, $model('docID'), true()))
        )
        let $contacts := distinct-values(core:getOrCreateColl('letters', $model('docID'), true())//@key[ancestor::tei:correspDesc][. != $model('docID')])
(:        let $beacon := wega-http:grabExternalResource('beacon', $model('doc')//tei:idno[@type = 'gnd'], 'de', true()):)
        
        let $backlinks := core:getOrCreateColl('letters', 'indices', true())//@key[.=$model('docID')] | core:getOrCreateColl('diaries', 'indices', true())//@key[.=$model('docID')] | core:getOrCreateColl('writings', 'indices', true())//@key[.=$model('docID')] | core:getOrCreateColl('persons', 'indices', true())//@key[.=$model('docID')]
        
        let $beaconMap := 
            let $findbuchResponse := wega-http:grabExternalResource('beacon', $model('doc')//tei:idno[@type = 'gnd'], 'de', true())
            let $jxml := 
                if(exists($findbuchResponse)) then 
                    if($findbuchResponse/httpclient:body/@encoding = 'Base64Encoded') then xqjson:parse-json(util:binary-to-string($findbuchResponse))
                    else xqjson:parse-json($findbuchResponse)
                else ()
            return 
                map:new(
                    for $i in 1 to count($jxml/item[2]/item)
                    let $link  := str:normalize-space($jxml/item[4]/item[$i])
                    let $title := str:normalize-space($jxml/item[3]/item[$i])
                    let $text  := str:normalize-space($jxml/item[2]/item[$i])
                    return
                        if(matches($link,"weber-gesamtausgabe.de")) then ()
                        else map:entry($title, ($link, $text))
                )
        
        let $document-tabs := (
            if(functx:all-whitespace($model('doc')//tei:note[@type='bioSummary'])) then () else 'wega',
            if(map:contains($beaconMap, 'Wikipedia-Personenartikel')) then 'wikipedia' else(),
            if(map:contains($beaconMap, 'Allgemeine Deutsche Biographie (Wikisource)')) then 'adb' else(),
            if(count(map:keys($beaconMap)) eq 0) then () else 'beacon'
        )
        
        let $tabTitles := map:new((
            if(empty($document-tabs )) then ()
            else map:entry('biographies', count($document-tabs[not(. = 'PND-Beacon')])),
            
            for $docType in map:keys($docTypes)
            return 
                if(empty($docTypes($docType))) then ()
                else map:entry($docType, count($docTypes($docType))),
                
            if(empty($contacts)) then ()
            else map:entry('contacts', count($contacts)),
            
            if(empty($backlinks)) then ()
            else map:entry('backlinks', count($backlinks))
            )
        )
        
(:        let $log := util:log-system-out(count(map:keys($tabTitles))):)
        return
            map{
                'tabTitlesMap' := $tabTitles,
                'tabTitleKeys' := map:keys($tabTitles)[. != 'iconography'],
                'docTypesMap' := $docTypes,
                'contacts' := $contacts,
                'gnd' := $model('doc')//tei:idno[@type = 'gnd'],
                'beaconMap' := $beaconMap,
                'document-tabs' := $document-tabs
            }
};

declare
    %templates:default("lang", "en")
    function app:print-tabTitle($node as node(), $model as map(*), $lang as xs:string) as element(a) {
    let $tabTitlesMap := $model('tabTitlesMap')
    return
    <a target=".{$model('tabTitleKey')}">{lang:get-language-string($model('tabTitleKey'), $lang) || ' (' || $tabTitlesMap($model('tabTitleKey')) || ')'}</a>
};

declare 
    %templates:default("lang", "en")
    function app:print-document-tab($node as node(), $model as map(*), $lang as xs:string) as element(a) {
        <a href="#{$model('document-tab')}Text" data-toggle="tab">{
            switch($model('document-tab'))
            case 'adb' return (
                attribute {'data-tab-url'} {'ajax.xql?func=adb&amp;gnd=' || $model('gnd') || '&amp;lang=' || $lang} , 'ADB ' || lang:get-language-string('personenartikel', $lang)
            )
            case 'wikipedia' return (
                attribute {'data-tab-url'} {'ajax.xql?func=wikipedia&amp;gnd=' || $model('gnd') || '&amp;lang=' || $lang} , 'Wikipedia ' || lang:get-language-string('personenartikel', $lang)
            )
            case 'beacon' return 'PND Beacon Links'
            case 'wega' return 'WeGA ' || lang:get-language-string('bio', $lang)
            default return ()
        }</a>
};

declare 
    %templates:default("lang", "en")
    function app:print-wega-bio($node as node(), $model as map(*), $lang as xs:string) as element(div)? {
        transform:transform($model('doc')//tei:note[@type="bioSummary"], doc(concat($config:xsl-collection-path, '/person_singleView.xsl')), config:get-xsl-params(()))
};

declare 
    %templates:default("lang", "en")
    function app:print-beacon-links($node as node(), $model as map(*), $lang as xs:string) as element(ul) {
        <ul>{
            for $i in map:keys($model('beaconMap'))
            return 
                <li><a title="{$i}" href="{$model('beaconMap')($i)[1]}">{$model('beaconMap')($i)[2]}</a></li>
        }</ul>
};
