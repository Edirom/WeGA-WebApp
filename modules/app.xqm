xquery version "3.0" encoding "UTF-8";

module namespace app="http://xquery.weber-gesamtausgabe.de/modules/app";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace templates="http://exist-db.org/xquery/templates";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace gndo="http://d-nb.info/standards/elementset/gnd#";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
(:declare namespace request = "http://exist-db.org/xquery/request";:)
declare namespace session = "http://exist-db.org/xquery/session";

import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";
import module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date" at "date.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "str.xqm";
import module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util" at "wega-util.xqm";
import module namespace functx="http://www.functx.com";

declare function app:page-title($node as node(), $model as map(*)) as element(title) {
    <title>{$model('page-title')}</title>
};

declare function app:page-h1($node as node(), $model as map(*)) as element(h1) {
    <h1>{query:get-reg-name($model('docID'))}</h1>
};

(:
 : ****************************
 : Generic functions
 : ****************************
:)

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
 : Set an attribute to the value given in the $model map
 :
 : @author Peter Stadler
 :)
declare function app:set-attr($node as node(), $model as map(*), $attr as xs:string, $key as xs:string) as element() {
    element {name($node)} {
        $node/@*[not(name(.) = $attr)],
        attribute {$attr} {$model($key)},
        templates:process($node/node(), $model)
    }
};

(:~
 : Simply print a value from the $model map
 :
 : @author Peter Stadler
 :)
declare 
    %templates:wrap
    function app:print($node as node(), $model as map(*), $key as xs:string) as xs:string? {
        if ($model($key) castable as xs:string) then string($model($key))
        else ()
};

(:~
 : Add additional JavaScript to the page template
 : which gets invoked at the end of the page
 :
 : @author Peter Stadler
 :)
declare function app:page-javascript($node as node(), $model as map(*)) {
    let $email := config:get-option('bugEmail')
    return
        <script type="text/javascript">
                var e = "{substring-before($email, '@')}";
                var t = "{substring-after($email, '@')}";
                var r = '' + e + '@' + t ;
                $('.obfuscate-email').attr('href',' mailto:' +r).html(r);
        </script>
};

declare 
    %templates:default("lang", "en")
    %templates:wrap
    function app:print-bugReportEmail($node as node(), $model as map(*), $lang as xs:string) as element(p) {
        if($lang eq 'de') then 
            <p>Wenn Ihnen auf dieser Seite ein Fehler oder eine Ungenauigkeit aufgefallen ist, so bitten wir um eine kurze Nachricht an
                <a href="#" class="obfuscate-email">You need Javascript enabled</a>
            </p>
        else 
            <p>If you've spotted some error or inaccurateness please do not hesitate to inform us via 
                <a href="#" class="obfuscate-email">You need Javascript enabled</a>
            </p>
};

declare
    %templates:default("lang", "en")
    %templates:wrap
    function app:print-permaLink($node as node(), $model as map(*), $lang as xs:string) as element(p) {
        let $dateFormat := if($lang eq 'en')
            then '%B %d, %Y'
            else '%d. %B %Y'
        let $svnProps := config:get-svn-props($model('docID'))
        let $author := map:get($svnProps, 'author')
        let $date := xs:dateTime(map:get($svnProps, 'dateTime'))
        let $version := concat(config:get-option('version'), if($config:isDevelopment) then 'dev' else '')
        let $versionDate := date:strfdate(xs:date(config:get-option('versionDate')), $lang, $dateFormat)
        let $permalink := core:permalink($model('docID'))
        return 
            <p>{lang:get-language-string('proposedCitation', $lang)}, {$permalink} ({app:createDocLink(core:doc(config:get-option('versionNews')), lang:get-language-string('versionInformation',($version, $versionDate), $lang), $lang, ())})
                <br/>
                {if($config:isDevelopment) then lang:get-language-string('lastChangeDateWithAuthor',(date:strfdate($date, $lang, $dateFormat),$author),$lang)
                else lang:get-language-string('lastChangeDateWithoutAuthor', date:strfdate($date, $lang, $dateFormat), $lang)
                }
            </p>
};

(:
 : ****************************
 : Index functions
 : ****************************
:)

declare 
    %templates:wrap
    %templates:default("lang", "en")
    function app:word-of-the-day($node as node(), $model as map(*), $lang as xs:string) as map(*) {
        let $words := core:getOrCreateColl('letters', 'A002068', true())//tei:seg[@type='wordOfTheDay']
        let $random := util:random(count($words) - 1) + 1 (: util:random may return 0! :)
(:        let $log := util:log-system-out($words[$random]/ancestor::tei:TEI/string(@xml:id)):)
        return 
            map {
                'wordOfTheDay' := str:enquote(str:normalize-space($words[$random]), $lang),
                'wordOfTheDayURL' := app:createUrlForDoc(core:doc($words[$random]/ancestor::tei:TEI/string(@xml:id)), $lang)
            }
};

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

declare function app:print-events-title($node as node(), $model as map(*), $lang as xs:string) as element(h2) {
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
    function app:person-details($node as node(), $model as map(*)) as map(*) {
        let $gnd := $model('doc')//tei:idno[@type = 'gnd']/string()
        let $docTypes := map:new(
            for $docType in map:keys($config:wega-docTypes)
            return 
                map:entry($docType, core:getOrCreateColl($docType, $model('docID'), true()))
        )
        let $contacts := distinct-values(core:getOrCreateColl('letters', $model('docID'), true())//@key[ancestor::tei:correspDesc][. != $model('docID')])
(:        let $beacon := wega-http:grabExternalResource('beacon', $model('doc')//tei:idno[@type = 'gnd'], 'de', true()):)
        
        let $backlinks := core:getOrCreateColl('letters', 'indices', true())//@key[.=$model('docID')] | core:getOrCreateColl('diaries', 'indices', true())//@key[.=$model('docID')] | core:getOrCreateColl('writings', 'indices', true())//@key[.=$model('docID')] | core:getOrCreateColl('persons', 'indices', true())//@key[.=$model('docID')]
        
        let $beaconMap := 
            if($gnd) then wega-util:beacon-map($gnd)
            else map:new()
        
        let $document-tabs := (
            if(functx:all-whitespace($model('doc')//tei:note[@type='bioSummary'])) then () else 'wega',
            if(map:contains($beaconMap, 'Wikipedia-Personenartikel')) then 'wikipedia' else(),
            if(map:contains($beaconMap, 'Allgemeine Deutsche Biographie (Wikisource)')) then 'adb' else(),
            if($gnd) then 'dnb' else (),
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
        
        (: 
         : Storing necessary parameters in a session for reuse via AJAX (e.g. wikipedia, adb, dnb mashups) 
         :)
        let $setSession := (
            session:remove-attribute('gnd'),
            session:set-attribute('gnd', $gnd),
            session:remove-attribute('docID'),
            session:set-attribute('docID', $model('docID'))
        )
        
(:        let $log := util:log-system-out(session:get-attribute('docID')):)
        return
            map{
                'tabTitlesMap' := $tabTitles,
                'tabTitleKeys' := map:keys($tabTitles)[. != 'iconography'],
                'docTypesMap' := $docTypes,
                'contacts' := $contacts,
                'gnd' := $gnd,
                'beaconMap' := $beaconMap,
                'document-tabs' := $document-tabs,
                'xml-download-URL' := core:link-to-current-app($model('docID') || '.xml')
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
                attribute {'data-tab-url'} {core:link-to-current-app('templates/adb.html')} , 'ADB ' || lang:get-language-string('personenartikel', $lang)
            )
            case 'wikipedia' return (
                attribute {'data-tab-url'} {core:link-to-current-app('templates/wikipedia.html')} , 'Wikipedia ' || lang:get-language-string('personenartikel', $lang)
            )
            case 'dnb' return (
                attribute {'data-tab-url'} {core:link-to-current-app('templates/dnb.html')} , 'DNB ' || lang:get-language-string('personenartikel', $lang)
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

(:~
 : Main Function for wikipedia.html
 : Creates the wikipedia model
 :
 : @author Peter Stadler 
 : @return map with keys:('wikiContent','wikiUrl','wikiName')
 :)
declare 
    %templates:wrap
    %templates:default("gnd", "")
    %templates:default("lang", "en")
    function app:wikipedia($node as node(), $model as map(*), $gnd as xs:string, $lang as xs:string) as map(*) {
    let $wikiContent := wega-util:grabExternalResource('wikipedia', $gnd, $lang, true())
    let $wikiUrl := $wikiContent//xhtml:div[@class eq 'printfooter']/xhtml:a[1]/data(@href)
    let $wikiName := normalize-space($wikiContent//xhtml:h1[@id = 'firstHeading'])
    return 
        map {
            'wikiContent' := $wikiContent,
            'wikiUrl' := $wikiUrl,
            'wikiName' := $wikiName
        }
};


declare function app:wikipedia-text($node as node(), $model as map(*)) as element() {
    element {name($node)} {
        $node/@*,
        transform:transform($model('wikiContent')//xhtml:div[@id='bodyContent'], doc(concat($config:xsl-collection-path, '/person_wikipedia.xsl')), config:get-xsl-params(()))/node()
    }
};

declare 
    %templates:default("lang", "en")
    function app:wikipedia-disclaimer($node as node(), $model as map(*), $lang as xs:string) as element() {
    element {name($node)} {
        $node/@*,
        
        if($lang eq 'en') then (
            'The content of this "Wikipedia" entitled box is taken from the article "',
            <a href='{$model('wikiUrl')}' title='Wikipedia article for {$model('wikiName')}'>{$model('wikiName')}</a>,
            '" from ',
            <a href="http://en.wikipedia.org">Wikipedia</a>,
            'the free encyclopedia, and is released under a ',
            <a href="http://creativecommons.org/licenses/by-sa/3.0/deed.en">CC-BY-SA-license</a>,
            '. You will find the ',
            <a href="{concat(replace($model('wikiUrl'), 'wiki/', 'w/index.php?title='), '&amp;action=history')}" title="Authors and revision history of the Wikipedia Article for {$model('wikiName')}">revision history along with the authors</a>,
            'of this article in Wikipedia.'
        )
            
        else (
            'Der Inhalt dieser mit "Wikipedia" bezeichneten Box entstammt dem Artikel "',
            <a href='{$model('wikiUrl')}' title='Wikipedia Artikel zu "{$model('wikiName')}"'>{$model('wikiName')}</a>,
            '" aus der freien Enzyklopädie ',
            <a href="http://de.wikipedia.org" title="Wikipedia Hauptseite">Wikipedia</a>, 
            ' und steht unter der ',
            <a href="http://creativecommons.org/licenses/by-sa/3.0/deed.de">CC-BY-SA-Lizenz</a>,
            '. In der Wikipedia findet sich auch die ',
            <a href="{concat(replace($model('wikiUrl'), 'wiki/', 'w/index.php?title='), '&amp;action=history')}" title='Autoren und Versionsgeschichte des Wikipedia Artikels zu "{$model('wikiName')}"'>Versionsgeschichte mitsamt Autorennamen</a>,
            ' für diesen Artikel.'
        )
    }
};

(:~
 : Main Function for adb.html
 : Creates the ADB model
 :
 : @author Peter Stadler 
 : @return map with key:'adbContent'
 :)
declare 
    %templates:wrap
    %templates:default("gnd", "")
    %templates:default("lang", "en")
    function app:adb($node as node(), $model as map(*), $gnd as xs:string, $lang as xs:string) as map(*) {
        map {
            'adbContent' := wega-util:grabExternalResource('adb', $gnd, (), true())
        }
};


declare function app:adb-text($node as node(), $model as map(*)) as element() {
    element {name($node)} {
        $node/@*,
        transform:transform($model('adbContent')//xhtml:div[@id='bodyContent'], doc(concat($config:xsl-collection-path, '/person_wikipedia.xsl')), config:get-xsl-params(()))/node()
    }
};

declare function app:adb-disclaimer($node as node(), $model as map(*)) as element() {
    element {name($node)} {
        $node/@*,
        transform:transform($model('adbContent')//xhtml:div[@id='adbcite'], doc(concat($config:xsl-collection-path, '/person_wikipedia.xsl')), config:get-xsl-params(map {'mode' := 'appendix'}))
    }
};

declare 
    %templates:wrap
    %templates:default("gnd", "")
    %templates:default("lang", "en")
    function app:dnb($node as node(), $model as map(*), $gnd as xs:string, $lang as xs:string) as map(*) {
        let $dnbContent := wega-util:grabExternalResource('dnb', $gnd, (), true())
(:        let $log := util:log-system-out($dnbContent//rdf:Description/gndo:preferredNameForThePerson/string()):)
        return
            map {
                'dnbContent' := $dnbContent,
                'dnbName' := $dnbContent//rdf:RDF/rdf:Description/gndo:preferredNameForThePerson/string(),
                'dnbBirths' := if($dnbContent//gndo:dateOfBirth castable as xs:date) then date:getNiceDate($dnbContent//gndo:dateOfBirth, $lang) else(),
                'dnbDeaths' := if($dnbContent//gndo:dateOfDeath castable as xs:date) then date:getNiceDate($dnbContent//gndo:dateOfDeath, $lang) else(),
                'dnbOccupations' := $dnbContent//rdf:RDF/rdf:Description/gndo:professionOrOccupation/string(),
                'dnbOtherNames' := $dnbContent//rdf:RDF/rdf:Description/gndo:variantNameForThePerson/string()
            }
};

declare
    %templates:default("docID", "")
    function app:xml-prettify($node as node(), $model as map(*), $docID as xs:string) {
        let $serializationParameters := ('method=xml', 'media-type=application/xml', 'indent=no', 'omit-xml-declaration=yes', 'encoding=utf-8')
        let $log := util:log-system-out(session:get-attribute('path'))
        return
            if($config:isDevelopment) then util:serialize(core:doc($docID), $serializationParameters)
            else util:serialize(wega-util:remove-comments(core:doc($docID)), $serializationParameters)
};
