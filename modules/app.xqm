xquery version "3.1" encoding "UTF-8";

module namespace app="http://xquery.weber-gesamtausgabe.de/modules/app";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace gndo="http://d-nb.info/standards/elementset/gnd#";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace request = "http://exist-db.org/xquery/request";

import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace img="http://xquery.weber-gesamtausgabe.de/modules/img" at "img.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";
import module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date" at "date.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "str.xqm";
import module namespace norm="http://xquery.weber-gesamtausgabe.de/modules/norm" at "norm.xqm";
import module namespace controller="http://xquery.weber-gesamtausgabe.de/modules/controller" at "controller.xqm";
import module namespace bibl="http://xquery.weber-gesamtausgabe.de/modules/bibl" at "bibl.xqm";
import module namespace search="http://xquery.weber-gesamtausgabe.de/modules/search" at "search.xqm";
import module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util" at "wega-util.xqm";
import module namespace wdt="http://xquery.weber-gesamtausgabe.de/modules/wdt" at "wdt.xqm";
import module namespace functx="http://www.functx.com";
import module namespace datetime="http://exist-db.org/xquery/datetime" at "java:org.exist.xquery.modules.datetime.DateTimeModule";
import module namespace templates="http://exist-db.org/xquery/templates" at "/db/apps/shared-resources/content/templates.xql";

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
    let $path :=  controller:path-to-resource($doc, $lang)
    return
        if($path) then core:link-to-current-app($path || '.html')
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
 : Simply print the string value of $model($key)
 :
 : @author Peter Stadler
 :)
declare 
    %templates:wrap
    function app:print($node as node(), $model as map(*), $key as xs:string) as xs:string? {
        if ($model($key) castable as xs:string) then str:normalize-space($model($key))
        else app:join($node, $model, $key, '0', '')
};

(:~
 : Simply print a sequence from the $model map by joining items with $separator
 :
 : @param $separator the separator for the string-join()
 : @author Peter Stadler
 :)
declare 
    %templates:wrap
    %templates:default("max", "0")
    %templates:default("separator", ", ")
    function app:join($node as node(), $model as map(*), $key as xs:string, $max as xs:string, $separator as xs:string) as xs:string? {
        let $items := 
            if($max castable as xs:integer and number($max) le 0) then $model($key)
            else if($max castable as xs:integer and number($max) < count($model($key))) then (subsequence($model($key), 1, $max), '…')
            else if($max castable as xs:integer and number($max) > 0) then subsequence($model($key), 1, $max)
            else $model($key)
        return
            if (every $i in $items satisfies $i castable as xs:string) then string-join($items ! str:normalize-space(.), $separator)
            else ()
};

declare 
    %templates:wrap
    function app:documentFooter($node as node(), $model as map(*)) as map(*) {
        let $lang := $model('lang')
        let $dateFormat := if($lang eq 'en')
            then '%B %d, %Y'
            else '%d. %B %Y'
        let $svnProps := config:get-svn-props($model('docID'))
        let $author := map:get($svnProps, 'author')
        let $date := xs:dateTime(map:get($svnProps, 'dateTime'))
        let $formatedDate := 
            try { date:strfdate($date, $lang, $dateFormat) }
            catch * { core:logToFile('warn', 'Failed to get Subversion properties for ' || $model('docID') ) }
        let $version := concat(config:get-option('version'), if($config:isDevelopment) then 'dev' else '')
        let $versionDate := date:strfdate(xs:date(config:get-option('versionDate')), $lang, $dateFormat)
        return
            map {
                'bugEmail' := config:get-option('bugEmail'),
                'permalink' := core:permalink($model('docID')),
                'versionNews' := app:createDocLink(core:doc(config:get-option('versionNews')), lang:get-language-string('versionInformation',($version, $versionDate), $lang), $lang, ()),
                'latestChange' :=
                    if($config:isDevelopment) then lang:get-language-string('lastChangeDateWithAuthor',($formatedDate,$author),$lang)
                    else lang:get-language-string('lastChangeDateWithoutAuthor', $formatedDate, $lang)
            }
};

(:~
 : A non-wrapping alternative to the standard templates:each()
 : Gets rid of the superfluous first list item
 : 
 : At present, only $callbackArity=2 is supported
 :
 : @author Peter Stadler
 :)
declare 
    %templates:default("max", "0")
    %templates:default("callback", "0")
    %templates:default("callbackArity", "2")
    function app:each($node as node(), $model as map(*), $from as xs:string, $to as xs:string, $max as xs:string, $callback as xs:string, $callbackArity as xs:string) as node()* {
    let $items := 
        if($max castable as xs:integer and $max != '0') then subsequence($model($from), 1, $max)
        else $model($from)
    let $callbackFunc := 
        try { function-lookup(xs:QName($callback), xs:int($callbackArity)) } 
        catch * { core:logToFile('error', 'Failed to lookup function "' || $callback ) }
    return (
        for $item in $items
        return 
            if(exists($callbackFunc)) then $callbackFunc($node, map:new(($model, map:entry($to, $item))))
            else 
                element { node-name($node) } {
                    $node/@*,
                    templates:process($node/node(), map:new(($model, map:entry($to, $item))))
                }
    )
};

(:~
 : Processes the node only if some $key (value) exists in $model 
 :
 : @author Peter Stadler
 :)
declare 
    %templates:default("wrap", "yes")
    function app:if-exists($node as node(), $model as map(*), $key as xs:string, $wrap as xs:string) as node()* {
        if($model($key)) then 
            if($wrap = 'yes') then
                element {node-name($node)} {
                    $node/@*,
                    templates:process($node/node(), $model)
                }
            else templates:process($node/node(), $model)
        else ()
};

(:~
 : Processes the node only if some $key (value) *not* exists in $model 
 :
 : @author Peter Stadler
 :)
declare function app:if-not-exists($node as node(), $model as map(*), $key as xs:string) as node()? {
    if(not($model($key))) then 
        element {node-name($node)} {
            $node/@*,
            templates:process($node/node(), $model)
        }
    else ()
};

(:~
 : Processes the node only if some $key matches $value in $model 
 :
 : @author Peter Stadler
 :)
declare 
    %templates:default("wrap", "yes")
    function app:if-matches($node as node(), $model as map(*), $key as xs:string, $value as xs:string, $wrap as xs:string) as item()* {
        if($model($key) = tokenize($value, '\s+')) then
            if($wrap = 'yes') then
                element {node-name($node)} {
                    $node/@*,
                    templates:process($node/node(), $model)
                }
            else templates:process($node/node(), $model)
        else ()
};

(:~
 : Processes the node only if some $key *not* matches $value in $model 
 :
 : @param $node the processed $node from the html template (a default param from the templating module)
 : @param $model a map (a default param from the templating module)
 : @param $key the key in $Model to look for
 : @param $value the value of $key to match
 : @param $wrap whether to copy the node $node to the output or just process the child nodes of $node  
 : @author Peter Stadler
 :)
declare 
    %templates:default("wrap", "yes")
    function app:if-not-matches($node as node(), $model as map(*), $key as xs:string, $value as xs:string, $wrap as xs:string) as item()* {
        if($model($key) = tokenize($value, '\s+')) then ()
        else if($wrap = 'yes') then
            element {node-name($node)} {
                $node/@*,
                templates:process($node/node(), $model)
            }
        else templates:process($node/node(), $model)
};

declare function app:order-list-items($node as node(), $model as map(*)) as element() {
    element {node-name($node)} {
        $node/@*,
        for $child in $node/node()
        let $childProcessed := templates:process($child, $model)
        order by str:normalize-space($childProcessed)
        return $childProcessed
    }
};

(:
 : ****************************
 : Breadcrumbs 
 : ****************************
:)
declare 
    %templates:default("lang", "en")
    function app:breadcrumb-person($node as node(), $model as map(*), $lang as xs:string) as element(a) {
        let $authorID := 
            if(config:is-person($model('docID'))) then $model('docID')
            else query:get-authorID($model('doc'))
        let $href := app:createUrlForDoc(core:doc($authorID), $lang)
        return 
            element {node-name($node)} {
                $node/@*[not(local-name(.) eq 'href')],
                if($href and not($authorID = config:get-option('anonymusID'))) then attribute href {$href} else (),
                str:printFornameSurname(query:get-reg-name($authorID))
            }
};

declare
    %templates:default("lang", "en")
    function app:breadcrumb-docType($node as node(), $model as map(*), $lang as xs:string) as element(a) {
        let $authorID := query:get-authorID($model('doc'))
        let $href := core:link-to-current-app(functx:substring-before-last(controller:path-to-resource($model('doc'), $lang), '/'))
        let $display-name := functx:substring-after-last($href, '/')
        return
            element {node-name($node)} {
                $node/@*[not(local-name(.) eq 'href')],
                if($href and not($authorID = config:get-option('anonymusID'))) then attribute href {$href} else (),
                $display-name
            }
};

declare 
    %templates:default("lang", "en")
    function app:breadcrumb-register1($node as node(), $model as map(*), $lang as xs:string) as item() {
        switch($model('docType')) 
        case 'indices' return lang:get-language-string('indices', $lang)
        case 'biblio' case 'news' return 
            element {node-name($node)} {
                $node/@*[not(local-name(.) eq 'href')],
                lang:get-language-string('project', $lang)
            }
        default return
            element {node-name($node)} {
                $node/@*[not(local-name(.) eq 'href')],
                attribute href {core:link-to-current-app(controller:path-to-register('indices', $lang))},
                lang:get-language-string('indices', $lang)
            }
};

declare 
    %templates:default("lang", "en")
    function app:breadcrumb-register2($node as node(), $model as map(*), $lang as xs:string) as element(a)? {
        if($model('docType') = 'indices') then ()
        else 
            element {node-name($node)} {
                $node/@*,
                lang:get-language-string($model('docType'), $lang)
            }
};

declare 
    %templates:default("lang", "en")
    function app:breadcrumb-var($node as node(), $model as map(*), $lang as xs:string) as element(a) {
        let $pathTokens := tokenize(request:get-attribute('$exist:path'), '/')
        return 
            element {node-name($node)} {
                $node/@*,
                $pathTokens[3]
            }
};

declare 
    %templates:wrap
    %templates:default("lang", "en")
    function app:status($node as node(), $model as map(*), $lang as xs:string) as xs:string? {
        let $docStatus := $model('doc')/*/@status | $model('doc')//tei:revisionDesc/@status 
        return
            if($docStatus) then lang:get-language-string($docStatus, $lang)
            else ()
};


(:
 : ****************************
 : Navigation / Tabs 
 : ****************************
:)

declare
    %templates:default("lang", "en")
    function app:person-main-tab($node as node(), $model as map(*), $lang as xs:string) as element()? {
        let $tabTitle := normalize-space($node)
        let $count := count($model($tabTitle))
        let $alwaysShowNoCount := $tabTitle = ('biographies', 'history')
        return
            if($count gt 0 or $alwaysShowNoCount) then
                element {name($node)} {
                        $node/@*[not(name(.)='data-target')],
                        if($node/@data-target) then attribute data-target {replace($node/@data-target, '\$docID', $model('docID'))} else (),
                        lang:get-language-string($tabTitle, $lang),
                        if($alwaysShowNoCount) then () else <small>{' (' || $count || ')'}</small>
                    }
            else 
                element {name($node)} {
                    attribute class {'deactivated'}
                }
};

declare
    %templates:default("lang", "en")
    function app:ajax-tab($node as node(), $model as map(*), $lang as xs:string) as element() {
        let $beacon := 
            try {string-join(map:keys($model('beaconMap')), ' ')}
            catch * {()}
        let $ajax-url :=
            switch(normalize-space($node))
            case 'XML-Preview' return 'xml.html'
            case 'wikipedia-article' return if(matches($beacon, 'Wikipedia-Personenartikel')) then 'wikipedia.html' else ()
            case 'adb-article' return if(contains($beacon, '(hier ADB ')) then 'adb.html' else ()
            case 'ndb-article' return if(contains($beacon, '(hier NDB ')) then 'ndb.html' else ()
            case 'gnd-entry' return if($model('gnd')) then 'dnb.html' else ()
            default return ()
        return
            if($ajax-url) then 
                element {name($node)} {
                    $node/@*,
                    attribute data-tab-url {core:link-to-current-app(controller:path-to-resource($model('doc'), $lang) || '/' || $ajax-url)},
                    lang:get-language-string(normalize-space($node), $lang)
                }
            else
                element {name($node)} {
                    attribute class {'deactivated'}
                }
};


declare
    %templates:default("lang", "en")
    function app:facsimile-tab($node as node(), $model as map(*), $lang as xs:string) as element() {
        if($model('hasFacsimile')) then 
            element {name($node)} {
                $node/@*,
                lang:get-language-string(normalize-space($node), $lang)
            }
        else
            element {name($node)} {
                attribute class {'deactivated'}
            }
};

declare
    %templates:default("lang", "en")
    function app:tab($node as node(), $model as map(*), $lang as xs:string) as element() {
        (: Currently only needed for "PND Beacon Links" :)
        if($model('gnd')) then
            element {name($node)} {
                $node/@*,
                normalize-space($node)
            }
        else
            element {name($node)} {
                attribute class {'deactivated'}
            }
};

declare
    %templates:wrap
    %templates:default("page", "1")
    %templates:default("lang", "en")
    function app:pagination($node as node(), $model as map(*), $page as xs:string, $lang as xs:string) as element(li)* {
        let $page := if($page castable as xs:int) then xs:int($page) else 1
(:        let $url := controller:docType-url-for-author($model('doc'), $model('docType'), $lang):)
        let $params := request:get-parameter-names()[.=($search:valid-params, 'd', 'q')]
        let $paramsMap := map:new(($model('filters'), $params ! map:entry(., request:get-parameter(., ()))))
        let $page-link := function($page as xs:int){
            (:$url ||:) '?page=' || $page || string-join(
                map:keys($paramsMap) ! (
                    '&amp;' || string(.) || '=' || string-join(
                        $paramsMap(.),
                        '&amp;' || string(.) || '=')
                    ), 
                '')
            }
        let $a-element := function($page as xs:int, $text as xs:string) {
            element a {
                attribute class {'page-link'},
                (: for AJAX pages (e.g. correspondence) called from a person page we need the data-url attribute :) 
                if(config:get-combined-doctype-by-id($model('docID')) = 'personsPlus') then attribute data-url {$page-link($page)}
                (: for index pages there is no javascript needed but a direct refresh of the page :)
                else attribute href {$page-link($page)},
                $text
            }
        }
        let $last-page := ceiling(count($model('search-results')) div config:entries-per-page()) 
        return (
            <li>{
                if($page le 1) then (
                    attribute {'class'}{'disabled'},
                    <span>&#x00AB; previous</span>
                )
                else $a-element($page - 1, '&#x00AB; previous') 
            }</li>,
            if($page gt 3) then <li>{$a-element(1, '1')}</li> else (),
            if($page gt 4) then <li>{$a-element(2, '2')}</li> else (),
            if($page gt 5) then <li class="disabled"><span>…</span></li> else (),
            ($page - 2, $page - 1)[. gt 0] ! <li>{$a-element(., string(.))}</li>,
            <li class="active"><span>{$page}</span></li>,
            ($page + 1, $page + 2)[. le $last-page] ! <li>{$a-element(., string(.))}</li>,
            if($page + 4 lt $last-page) then <li class="disabled"><span>…</span></li> else (),
            if($page + 3 lt $last-page) then <li>{$a-element($last-page - 1, string($last-page - 1))}</li> else (),
            if($page + 2 lt $last-page) then <li>{$a-element($last-page, string($last-page))}</li> else (),
            <li>{
                if($page ge $last-page) then (
                    attribute {'class'}{'disabled'},
                    <span>next &#x00BB;</span>
                )
                else $a-element($page + 1, 'next &#x00BB;')
            }</li>
        )
};

declare 
    %templates:wrap
    %templates:default("lang", "en")
    function app:active-nav($node as node(), $model as map(*), $lang as xs:string) as map() {
        let $active := $node//xhtml:a/@href[controller:encode-path-segments-for-uri(controller:resolve-link(., $lang)) = request:get-uri()]
        return
            map {'active-nav': $active}
};

declare 
    %templates:default("lang", "en")
    function app:set-active-nav($node as node(), $model as map(*), $lang as xs:string) as element(li) {
        let $active := exists($node//xhtml:a[@href = $model('active-nav')])
        return
            element {name($node)} {
                if($active) then (
                    $node/@*[not(name(.)='class')],
                    attribute class {string-join(($node/@class, 'active'), ' ')}
                )
                else $node/@*,
                templates:process($node/node(), $model)
            }
};

declare 
    %templates:default("lang", "en")
    function app:set-active-lang($node as node(), $model as map(*), $lang as xs:string) as element(li) {
        let $isActive := $lang = lower-case(normalize-space($node))
        return
            element {name($node)} {
                if($isActive) then (
                    $node/@*[not(name(.)='class')],
                    attribute class {string-join(($node/@class, 'active'), ' ')}
                )
                else $node/@*,
                
                (: Child element a takes the link :)
                element a {
                    attribute href {
                        if($isActive) then '#'
                        else controller:translate-URI(request:get-uri(), $lang, lower-case(normalize-space($node)))
                    },
                    normalize-space($node)
                }
            }
};

(:~
 : set the maximum dates for the IonRangeSlider
~:)
declare 
    %templates:default("fromDate", "")
    %templates:default("toDate", "")
    function app:set-slider-range($node as node(), $model as map(*), $fromDate as xs:string, $toDate as xs:string) as element(input) {
    element {name($node)} {
         $node/@*,
         attribute data-min-slider {$model('earliestDate')},
         attribute data-max-slider {$model('latestDate')},
         attribute data-from-slider {if($fromDate castable as xs:date) then $fromDate else $model('earliestDate')},
         attribute data-to-slider {if($toDate castable as xs:date) then $toDate else $model('latestDate')}
    }
};

declare function app:set-undated-checkbox($node as node(), $model as map(*)) as element(input) {
    element {name($node)} {
         $node/@*,
         if(map:contains($model('filters'), 'undated')) then attribute checked {'checked'}
         else ()
    }
};

(:
 : ****************************
 : Popover
 : ****************************
:)
(:~
 : Wrapper for dispatching various document types (in analogy to search:dispatch-preview())
 : Simply redirects to the right fragment from 'templates/includes'
 :
 :)
declare function app:popover($node as node(), $model as map(*)) as map(*)* {
    map {
        'result-page-entry' := $model('doc')
    }
};

(:
 : ****************************
 : Index page
 : ****************************
:)

declare 
    %templates:wrap
    %templates:default("lang", "en")
    function app:word-of-the-day($node as node(), $model as map(*), $lang as xs:string) as map(*) {
        let $words := core:getOrCreateColl('letters', 'A002068', true())//tei:seg[@type='wordOfTheDay']
        let $random :=
            if(count($words) gt 1) then util:random(count($words) - 1) + 1 (: util:random may return 0! :)
            else 1
        return 
            map {
                'wordOfTheDay' := str:enquote(str:normalize-space(string-join(wega-util:txtFromTEI($words[$random]), '')), $lang),
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
                else (app:createDocLink($teiDate/root(), str:printFornameSurname(query:get-reg-name($teiDate/ancestor::tei:person/@xml:id)), $lang, ('class=persons')), ' ', lang:get-language-string($typeOfEvent, $lang))
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
    let $sender := app:printCorrespondentName(($teiDate/parent::tei:correspAction[@type='sent']/tei:*[self::tei:persName or self::tei:orgName or self::tei:name])[1], $lang, 'fs')
    let $addressee := app:printCorrespondentName(($teiDate/ancestor::tei:correspDesc/tei:correspAction[@type='received']/tei:*[self::tei:persName or self::tei:orgName or self::tei:name])[1], $lang, 'fs')
    return (
        $sender, ' ', lang:get-language-string('writesTo', $lang), ' ', $addressee, 
        if(ends-with($addressee, '.')) then ' ' else '. ', 
        app:createDocLink($teiDate/root(), concat('[', lang:get-language-string('readOnLetter', $lang), ']'), $lang, ('class=readOn'))
    )
};

(:~
 : Construct a name from a tei:persName or tei:name element wrapped in a <span> 
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
     if(exists($persName/@key)) then app:createDocLink(core:doc($persName/string(@key)), str:printFornameSurname(query:get-reg-name($persName/@key)), $lang, ('class=persons'))
        (:wega:createPersonLink($persName/string(@key), $lang, $order):)
     else if (not(functx:all-whitespace($persName))) then 
        if ($order eq 'fs') then <xhtml:span class="noDataFound">{str:printFornameSurname($persName)}</xhtml:span>
        else <xhtml:span class="noDataFound">{string($persName)}</xhtml:span>
    else <xhtml:span class="noDataFound">{lang:get-language-string('unknown',$lang)}</xhtml:span>
};

declare 
    %templates:wrap
    function app:index-news-items($node as node(), $model as map(*)) as map(*) {
        map {
            'news' := subsequence(core:getOrCreateColl('news', 'indices', true()), 1, xs:int(config:get-option('maxNews')))
        }
};

declare
    %templates:wrap
    %templates:default("lang", "en")
    function app:index-news-date($node as node(), $model as map(*), $lang as xs:string) as xs:string {
        date:printDate($model('doc')//tei:date[parent::tei:publicationStmt], $lang)
};

declare 
    %templates:default("lang", "en")
    function app:search-options($node as node(), $model as map(*), $lang as xs:string) as element(option)* {
        <option value="all">{lang:get-language-string('all', $lang)}</option>,
        for $docType in $search:wega-docTypes
        let $displayTitle := lang:get-language-string($docType, $lang)
        order by $displayTitle
        return
            element {name($node)} {
                attribute value {$docType},
                $displayTitle
            }
};

(:
 : ****************************
 : Person pages
 : ****************************
:)

declare 
    %templates:wrap
    function app:person-title($node as node(), $model as map(*)) as xs:string {
        query:get-reg-name($model('docID'))
};

declare 
    %templates:wrap
    function app:person-forename-surname($node as node(), $model as map(*)) as xs:string {
        str:printFornameSurname(query:get-reg-name($model('docID')))
};

declare 
    %templates:wrap
    %templates:default("lang", "en")
    function app:person-basic-data($node as node(), $model as map(*), $lang as xs:string) as map(*) {
        map{
            'fullnames' := $model('doc')//tei:persName[@type = 'full'],
            'pseudonyme' := $model('doc')//tei:persName[@type = 'pseud'],
            'birthnames' := $model('doc')//tei:persName[@subtype = 'birth'],
            'realnames' := $model('doc')//tei:persName[@type = 'real'],
            'altnames' := $model('doc')//tei:persName[@type = 'alt'][not(@subtype)] | $model('doc')//tei:orgName[@type = 'alt'],
            'marriednames' := $model('doc')//tei:persName[@subtype = 'married'],
            'births' := date:printDate(($model('doc')//tei:birth/tei:date[not(@type)])[1], $lang),
            'baptism' := date:printDate(($model('doc')//tei:birth/tei:date[@type='baptism'])[1], $lang),
            'deaths' := date:printDate(($model('doc')//tei:death/tei:date[not(@type)])[1], $lang),
            'funeral' := date:printDate(($model('doc')//tei:death/tei:date[@type = 'funeral'])[1], $lang),
            'occupations' := $model('doc')//tei:occupation | $model('doc')//tei:label[.='Art der Institution']/following-sibling::tei:desc,
            'residences' := $model('doc')//tei:residence | $model('doc')//tei:label[.='Ort']/following-sibling::tei:desc/tei:*,
            'addrLines' := $model('doc')//tei:affiliation[tei:orgName='Carl-Maria-von-Weber-Gesamtausgabe']//tei:addrLine 
        }
};

declare 
    %templates:wrap
    function app:person-details($node as node(), $model as map(*)) as map(*) {
    map{
        'correspondence' := core:getOrCreateColl('letters', $model('docID'), true()),
        'diaries' := core:getOrCreateColl('diaries', $model('docID'), true()),
        'writings' := core:getOrCreateColl('writings', $model('docID'), true()),
        'works' := core:getOrCreateColl('works', $model('docID'), true()),
        'contacts' := core:getOrCreateColl('contacts', $model('docID'), true()),
        'biblio' := core:getOrCreateColl('biblio', $model('docID'), true()),
        'news' := core:getOrCreateColl('news', $model('docID'), true()),
        (:distinct-values(core:getOrCreateColl('letters', $model('docID'), true())//@key[ancestor::tei:correspDesc][. != $model('docID')]) ! core:doc(.),:)
        'backlinks' := core:getOrCreateColl('backlinks', $model('docID'), true()),
        'thematicCommentaries' := core:getOrCreateColl('thematicCommentaries', $model('docID'), true()),
        
        'source' := $model('doc')/tei:person/data(@source),
        'xml-download-url' := replace(app:createUrlForDoc($model('doc'), $model('lang')), '\.html', '.xml')
        (:core:getOrCreateColl('letters', 'indices', true())//@key[.=$model('docID')]/root() | core:getOrCreateColl('diaries', 'indices', true())//@key[.=$model('docID')]/root() | core:getOrCreateColl('writings', 'indices', true())//@key[.=$model('docID')]/root() | core:getOrCreateColl('persons', 'indices', true())//@key[.=$model('docID')]/root(),:)
        (:                'xml-download-URL' := core:link-to-current-app($model('docID') || '.xml'):)
    }
};

declare function app:person-beacon($node as node(), $model as map(*)) as map(*) {
    let $gnd := query:get-gnd($model('doc'))
    let $beaconMap := 
        if($gnd) then wega-util:beacon-map($gnd, config:get-doctype-by-id($model('docID')))
        else map:new()
    return
        map{
            'gnd' := $gnd,
            'beaconMap' := $beaconMap
        }
};

declare 
    %templates:default("lang", "en")
    function app:print-wega-bio($node as node(), $model as map(*), $lang as xs:string) as element(div)* {
        let $bio := wega-util:transform($model('doc')//(tei:note[@type='bioSummary'] | tei:event[tei:head] | tei:note[parent::tei:org]), doc(concat($config:xsl-collection-path, '/persons.xsl')), config:get-xsl-params(()))
        return
            if(some $i in $bio satisfies $i instance of element()) then $bio
            else 
                element {name($node)} {
                    $node/@*,
                    if($bio instance of xs:string) then <p>{$bio}</p>
                    else templates:process($node/node(), $model)
                }
};

declare function app:print-beacon-links($node as node(), $model as map(*)) as element(ul) {
        let $beaconMap := $model('beaconMap')
        return
            <ul>{
                for $i in map:keys($beaconMap)
                order by $beaconMap($i)[2] collation "?lang=de-DE"
                return 
                    <li><a title="{$i}" href="{(: replacement for invalid links from www.sbn.it :)replace($beaconMap($i)[1], '\\', '%5C')}">{$beaconMap($i)[2]}</a></li>
            }</ul>
};

declare 
    %templates:wrap
    function app:printPlaceOfBirthOrDeath($node as node(), $model as map(*), $key as xs:string) as xs:string* {
    let $placeNames :=
        switch($key)
        case 'birth' return $model('doc')//tei:placeName[parent::tei:birth]
        case 'death' return $model('doc')//tei:placeName[parent::tei:death]
        default return ()
    return
        for $placeName at $count in $placeNames
        let $preposition :=
            if(matches(normalize-space($placeName), '^(auf|bei)')) then ' ' (: Präposition 'in' weglassen wenn schon eine andere vorhanden :)
            else concat(' ', lower-case(lang:get-language-string('in', $model('lang'))), ' ')
        return (
            $preposition || str:normalize-space($placeName),
            if($count eq count($placeNames)) then ()
            else concat(' ',lang:get-language-string('or', $model('lang')),' ')
        )
};

declare
    %templates:wrap
    function app:portrait-credits($node as node(), $model as map(*)) as item()* {
        if($model('portrait')('source') = 'Carl-Maria-von-Weber-Gesamtausgabe') then ()
        else (
            $model('portrait')('source'),
            if(contains($model('portrait')('linkTarget'), config:get-option('iiifServer'))) then ()
            else (<br/>, element a {
                attribute href {$model('portrait')('linkTarget')},
                $model('portrait')('linkTarget')
            })
        )
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
    %templates:default("lang", "en")
    function app:wikipedia($node as node(), $model as map(*), $lang as xs:string) as map(*) {
        let $gnd := query:get-gnd($model('doc'))
        let $wikiContent := wega-util:grabExternalResource('wikipedia', $gnd, config:get-doctype-by-id($model('docID')), $lang)
        let $wikiUrl := $wikiContent//xhtml:div[@class eq 'printfooter']/xhtml:a[1]/data(@href)
        let $wikiName := normalize-space($wikiContent//xhtml:h1[@id = 'firstHeading'])
        return 
            map {
                'wikiContent' := $wikiContent,
                'wikiUrl' := $wikiUrl,
                'wikiName' := $wikiName
            }
};


declare 
    %templates:wrap
    %templates:default("lang", "en")
    function app:wikipedia-text($node as node(), $model as map(*), $lang as xs:string) as item()* {
        let $wikiText := wega-util:transform($model('wikiContent')//xhtml:div[@id='bodyContent'], doc(concat($config:xsl-collection-path, '/wikipedia.xsl')), config:get-xsl-params(()))/node()
        return 
            if(exists($wikiText)) then $wikiText
            else lang:get-language-string('failedToLoadExternalResource', $lang)
};

declare 
    %templates:wrap
    %templates:default("lang", "en")
    function app:wikipedia-disclaimer($node as node(), $model as map(*), $lang as xs:string) as item()* {
        if($model('wikiContent')//xhtml:html) then 
            switch($lang) 
            case 'de' return (
                'Der Text unter der Überschrift „Wikipedia“ entstammt dem Artikel „',
                <a href='{$model('wikiUrl')}' title='Wikipedia Artikel zu "{$model('wikiName')}"'>{$model('wikiName')}</a>,
                '“ aus der freien Enzyklopädie ',
                <a href="http://de.wikipedia.org" title="Wikipedia Hauptseite">Wikipedia</a>, 
                ' und steht unter der ',
                <a href="http://creativecommons.org/licenses/by-sa/3.0/deed.de">CC-BY-SA-Lizenz</a>,
                '. In der Wikipedia findet sich auch die ',
                <a href="{concat(replace($model('wikiUrl'), 'wiki/', 'w/index.php?title='), '&amp;action=history')}" title='Autoren und Versionsgeschichte des Wikipedia Artikels zu "{$model('wikiName')}"'>Versionsgeschichte mitsamt Autorennamen</a>,
                ' für diesen Artikel.'
            )
            default return (
                'The text under the headline “Wikipedia” is taken from the article “',
                <a href='{$model('wikiUrl')}' title='Wikipedia article for {$model('wikiName')}'>{$model('wikiName')}</a>,
                '” from ',
                <a href="http://en.wikipedia.org">Wikipedia</a>,
                ' the free encyclopedia, and is released under a ',
                <a href="http://creativecommons.org/licenses/by-sa/3.0/deed.en">CC-BY-SA-license</a>,
                '. You will find the ',
                <a href="{concat(replace($model('wikiUrl'), 'wiki/', 'w/index.php?title='), '&amp;action=history')}" title="Authors and revision history of the Wikipedia Article for {$model('wikiName')}">revision history along with the authors</a>,
                ' of this article in Wikipedia.'
            )
        else ()
};


(:~
 : Main Function for ndb.html and adb.html
 : Creates the Deutsche Biographie model
 :
 : @author Peter Stadler 
 : @return map with key:'adbndbContent'
 :)
declare 
    %templates:wrap
    function app:deutsche-biographie($node as node(), $model as map(*)) as map(*) {
        map {
            'adbndbContent' := wega-util:grabExternalResource('deutsche-biographie', query:get-gnd($model('doc')), config:get-doctype-by-id($model('docID')), ())
        }
};

declare 
    %templates:wrap
    %templates:default("lang", "en")
    function app:deutsche-biographie-text($node as node(), $model as map(*), $type as xs:string, $lang as xs:string) as item()* {
        let $deutsche-biographie-text := 
            if($type = 'ndb') then wega-util:transform($model('adbndbContent')//xhtml:div[@id='ndbcontent'], doc(concat($config:xsl-collection-path, '/deutsche-biographie.xsl')), config:get-xsl-params(()))/node()
            else wega-util:transform($model('adbndbContent')//xhtml:div[@id='adbcontent'], doc(concat($config:xsl-collection-path, '/deutsche-biographie.xsl')), config:get-xsl-params(()))/node()
        return 
            if(exists($deutsche-biographie-text)) then $deutsche-biographie-text
            else lang:get-language-string('failedToLoadExternalResource', $lang)
};

declare 
    %templates:wrap
    function app:deutsche-biographie-disclaimer($node as node(), $model as map(*), $type as xs:string) as item()* {
        ($model('adbndbContent')//xhtml:p[preceding-sibling::xhtml:h4[@id=concat($type, 'content_zitierweise')]])[1]/node()
};

declare 
    %templates:wrap
    %templates:default("lang", "en")
    function app:dnb($node as node(), $model as map(*), $lang as xs:string) as map(*) {
        let $gnd := query:get-gnd($model('doc'))
        let $dnbContent := wega-util:grabExternalResource('dnb', $gnd, config:get-doctype-by-id($model('docID')), ())
        return
            map {
                'dnbContent' := $dnbContent,
                'dnbName' := ($dnbContent//rdf:RDF/rdf:Description/gndo:preferredNameForThePerson/str:normalize-space(.), $dnbContent//rdf:RDF/rdf:Description/gndo:preferredNameForTheCorporateBody/str:normalize-space(.)),
                'dnbBirths' := if($dnbContent//gndo:dateOfBirth castable as xs:date) then date:getNiceDate($dnbContent//gndo:dateOfBirth, $lang) else(),
                'dnbDeaths' := if($dnbContent//gndo:dateOfDeath castable as xs:date) then date:getNiceDate($dnbContent//gndo:dateOfDeath, $lang) else(),
                'dnbOccupations' := ($dnbContent//rdf:RDF/rdf:Description/gndo:professionOrOccupation/str:normalize-space(.), $dnbContent//rdf:RDF/rdf:Description/gndo:professionOrOccupationAsLiteral/str:normalize-space(.)),
                'dnbOtherNames' := ($dnbContent//rdf:RDF/rdf:Description/gndo:variantNameForThePerson/str:normalize-space(.), $dnbContent//rdf:RDF/rdf:Description/gndo:variantNameForTheCorporateBody/str:normalize-space(.)),
                'lang' := $lang,
                'dnbURL' := config:get-option('dnb') || $gnd
            }
};

declare function app:xml-prettify($node as node(), $model as map(*)) {
        let $docID := $model('docID')
        let $serializationParameters := ('method=xml', 'media-type=application/xml', 'indent=no', 'omit-xml-declaration=yes', 'encoding=utf-8')
        return
            if($config:isDevelopment) then util:serialize(core:doc($docID), $serializationParameters)
            else util:serialize(wega-util:remove-comments(core:doc($docID)), $serializationParameters)
};

declare 
    %templates:default("lang", "en")
    function app:person-addrLine($node as node(), $model as map(*), $lang as xs:string) as item()* {
        switch ($model('addrLine')/@n)
        case 'email' return 
            element a {
                attribute class {'obfuscate-email'},
                normalize-space($model('addrLine'))
            }
        case 'telephone' return (
            lang:get-language-string('tel',$lang) || ': ',
            element a {
                attribute href {'tel:' || replace(normalize-space($model('addrLine')), '-|–|(\(0\))|\s', '')},
                normalize-space($model('addrLine'))
            }
        )
        default return (
            switch ($model('addrLine')/@n)
            case 'fax' return lang:get-language-string('fax',$lang) || ': '
            default return (),
            normalize-space($model('addrLine'))
        )
};

(:
 : ****************************
 : Document pages
 : ****************************
:)


declare 
    %templates:wrap
    function app:doc-details($node as node(), $model as map(*)) as map(*) {
        let $facsimileWhiteList := tokenize(config:get-option('facsimileWhiteList'), '\s+')
        return
            map {
                'hasFacsimile' := 
                    if($config:isDevelopment) then exists($model('doc')//tei:facsimile/tei:graphic/@url)
                    else exists($model('doc')//tei:facsimile[preceding::tei:repository[@n=$facsimileWhiteList]]/tei:graphic/@url),
                'xml-download-url' := replace(app:createUrlForDoc($model('doc'), $model('lang')), '\.html', '.xml')
            }
};

declare
    %templates:wrap
    %templates:default("lang", "en")
    function app:document-title($node as node(), $model as map(*), $lang as xs:string) as item()* {
        let $title-element := query:get-title-element($model('doc'), $lang)
        let $dateFormat := if ($lang eq 'en')
            then '%A, %B %d, %Y'
            else '%A, %d. %B %Y'
        let $title := 
            typeswitch($title-element)
            case element(tei:title) return wega-util:transform($title-element, doc(concat($config:xsl-collection-path, '/common_main.xsl')), config:get-xsl-params(()))
            case element(mei:title) return str:normalize-space($title-element)
            case element(tei:date) return 
                if($title-element castable as xs:date) then
                    let $diaryPlaces as array(xs:string) := query:place-of-diary-day($model('doc'))
                    return (
                        date:strfdate(xs:date($title-element), $lang, $dateFormat),
                        <xhtml:br/>,
                        switch(array:size($diaryPlaces))
                        case 0 return ()
                        case 1 return $diaryPlaces(1)
                        case 2 return $diaryPlaces(1) || ', ' || $diaryPlaces(2)
                        case 3 return $diaryPlaces(1) || ', ' || $diaryPlaces(2) || ', ' || $diaryPlaces(3)
                        default return $diaryPlaces(1) || ', …, ' || $diaryPlaces(array:size($diaryPlaces))
                    )
                else ()
            default return wega-util:transform(app:construct-title($model('doc'), $lang), doc(concat($config:xsl-collection-path, '/common_main.xsl')), config:get-xsl-params(()))
        return
            typeswitch($title)
            case element() return $title/node()
            default return $title
};

declare 
    %templates:wrap
    function app:prepare-text($node as node(), $model as map(*)) as map(*) {
        let $doc := $model('doc')
        let $docID := $model('docID')
        let $lang := $model('lang')
        let $docType := $model('docType')
        let $xslParams := config:get-xsl-params( map {
            'dbPath' := document-uri($doc),
            'docID' := $docID,
            'transcript' := 'true',
            (: Some special flag for diaries :)
            'suppressLinks' := if(year-from-date(xs:date($doc/tei:ab/@n)) = $config:diaryYearsToSuppress) then 'true' else ()
            } )
        let $xslt1 := 
            switch($docType)
            case 'letters' return doc(concat($config:xsl-collection-path, '/letters.xsl'))
            case 'news' case 'writings' return doc(concat($config:xsl-collection-path, '/document.xsl'))
            case 'diaries' return doc(concat($config:xsl-collection-path, '/diary_tableLeft.xsl'))
            default  return doc(concat($config:xsl-collection-path, '/var.xsl'))
        let $xslt2 :=
            switch($docType)
            case 'diaries' return doc(concat($config:xsl-collection-path, '/diary_tableRight.xsl'))
            default return ()
        let $textRoot :=
            switch($docType)
            case 'diaries' return $doc/tei:ab
            case 'var' return $doc//tei:text/tei:body/(tei:div[@xml:lang=$lang] | tei:divGen)
            case 'thematicCommentaries' return $doc//tei:text/(tei:body | tei:back)
            default return $doc//tei:text/tei:body
        let $body := 
             if(functx:all-whitespace(<root>{$textRoot}</root>))
             then (
                let $text := 
                    if($doc//tei:correspDesc[@n = 'revealed']) then lang:get-language-string('correspondenceTextNotAvailable', $lang)
                    else lang:get-language-string('correspondenceTextNotYetAvailable', $lang)
                return
                    element p {
                        attribute class {'notAvailable'},
                        $text
                    }
             )
             else (
                wega-util:transform($textRoot, $xslt1, $xslParams),
                if($xslt2) then wega-util:transform($textRoot, $xslt2, $xslParams) else ()
            )
         let $foot := 
            if(config:is-news($docID)) then app:get-news-foot($doc, $lang)
            else ()
         
         return 
            map { 
                'transcription' := (wega-util:remove-elements-by-class($body, 'apparatus'),$foot), 
                'apparatus' := $body/descendant-or-self::*[@class='apparatus']
            }
};

declare function app:output($node as node(), $model as map(*), $key as xs:string) as item()* {
        $model($key)
};

declare 
    %templates:wrap
    function app:series($node as node(), $model as map(*)) as xs:string {
        str:normalize-space($model('doc')/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[@level='s'])
};

declare 
    %templates:wrap
    %templates:default("lang", "en")
    function app:respStmts($node as node(), $model as map(*), $lang as xs:string) as element()* {
        let $respStmts :=
            switch($model('docType'))
            case 'diaries' return <tei:respStmt><tei:resp>Übertragung</tei:resp><tei:name>Dagmar Beck</tei:name></tei:respStmt>
            default return $model('doc')//tei:respStmt[parent::tei:editionStmt]
        return
            for $respStmt in $respStmts
            return (
                <dt>{str:normalize-space($respStmt/tei:resp)}</dt>,
                <dd>{str:normalize-space(string-join($respStmt/tei:name, ', '))}</dd>
            )
};

declare 
    %templates:wrap
    function app:textSources($node as node(), $model as map(*)) as map(*) {
        (: Drei mögliche Kinder (neben tei:correspDesc) von sourceDesc: tei:msDesc, tei:listWit, tei:biblStruct :)
        let $source := 
            switch($model('docType'))
            case 'diaries' return 
                <tei:msDesc>
                   <tei:msIdentifier>
                      <tei:country>D</tei:country>
                      <tei:settlement>Berlin</tei:settlement>
                      <tei:repository n="D-B">Staatsbibliothek zu Berlin – Preußischer Kulturbesitz</tei:repository>
                      <tei:idno>Mus. ms. autogr. theor. C. M. v. Weber WFN 1</tei:idno>
                   </tei:msIdentifier>
                </tei:msDesc>
            default return $model('doc')//tei:sourceDesc/tei:*[name(.) != 'correspDesc']
        return 
        map {
            'textSources' := 
                typeswitch($source)
                case element(tei:listWit) return $source/tei:witness/tei:*
                default return $source
        }
};

declare 
    %templates:default("lang", "en")
    function app:print-textSource($node as node(), $model as map(*), $lang as xs:string) as element()* {
        typeswitch($model('textSource'))
        case element(tei:msDesc) return wega-util:transform($model('textSource'), doc(concat($config:xsl-collection-path, '/editorial.xsl')), config:get-xsl-params(()))
        case element(tei:biblStruct) return bibl:printCitation($model('textSource'), 'p', $lang)
        case element(tei:bibl) return <p>{str:normalize-space($model('textSource'))}</p>
        default return <span class="noDataFound">{lang:get-language-string('noDataFound',$lang)}</span>
};

declare 
    %templates:wrap
    function app:additionalSources($node as node(), $model as map(*)) as map(*) {
        (: tei:msDesc, tei:bibl, tei:biblStruct als mögliche Kindelemente von tei:additional/tei:listBibl :)
        map {
            'additionalSources' := $model('textSource')/tei:additional/tei:listBibl/tei:* | $model('textSource')/tei:relatedItem/tei:* 
        }
};

declare 
    %templates:default("lang", "en")
    function app:print-additionalSource($node as node(), $model as map(*), $lang as xs:string) as element()* {
        typeswitch($model('additionalSource'))
        case element(tei:msDesc) return wega-util:transform($model('additionalSource'), doc(concat($config:xsl-collection-path, '/editorial.xsl')), config:get-xsl-params(()))
        case element(tei:biblStruct) return <span class="biblio-entry">{bibl:printCitation($model('additionalSource'), 'p', $lang)/node()}</span>
        case element(tei:bibl) return <span>{str:normalize-space($model('additionalSource'))}</span>
        default return <span class="noDataFound">{lang:get-language-string('noDataFound',$lang)}</span>
};

(:~
 : Outputs the summary information of a TEI document
 :
:)
declare 
    %templates:default("lang", "en")
    function app:print-summary($node as node(), $model as map(*), $lang as xs:string) as element(p)* {
        let $summary :=
            if($model('doc')//tei:correspDesc[@n = 'revealed']) then lang:get-language-string('correspondenceTextNotAvailable', $lang)
            else wega-util:transform($model('doc')//tei:note[@type='summary'], doc(concat($config:xsl-collection-path, '/editorial.xsl')), config:get-xsl-params(()))
        return
            if(exists($summary) and (every $i in $summary satisfies $i instance of element())) then $summary
            else element p {
                if(exists($summary)) then $summary
                else '–'
            }
};

declare 
    %templates:default("lang", "en")
    function app:print-incipit($node as node(), $model as map(*), $lang as xs:string) as element(p)* {
        let $incipit := wega-util:transform($model('doc')//tei:note[@type='incipit'], doc(concat($config:xsl-collection-path, '/editorial.xsl')), config:get-xsl-params(()))
        return 
            if(exists($incipit) and (every $i in $incipit satisfies $i instance of element())) then $incipit
            else element p {
                if(exists($incipit)) then $incipit
                else '–'
            }
};

declare 
    %templates:default("lang", "en")
    function app:print-generalRemark($node as node(), $model as map(*), $lang as xs:string) as element(p)* {
        let $generalRemark := wega-util:transform($model('doc')//tei:note[@type='editorial'], doc(concat($config:xsl-collection-path, '/editorial.xsl')), config:get-xsl-params(()))
        return 
            if(exists($generalRemark) and (every $i in $generalRemark satisfies $i instance of element())) then $generalRemark
            else element p {
                if(exists($generalRemark)) then $generalRemark
                else '–'
            }
};

declare 
    %templates:default("lang", "en")
    function app:print-creation($node as node(), $model as map(*), $lang as xs:string) as element(p) {
        let $creation := wega-util:transform($model('doc')//tei:creation, doc(concat($config:xsl-collection-path, '/editorial.xsl')), config:get-xsl-params(()))
        return 
            element p {
                if(exists($creation)) then $creation
                else '–'
            }
};

(:~
 : Query the letter context, i.e. preceding and following letters
~:)
declare function app:context-letter($node as node(), $model as map(*)) as map(*)* {
    let $doc := $model('doc')
    let $docID := $model('docID')
    let $authorID := $doc//tei:fileDesc/tei:titleStmt/tei:author[1]/@key (:$doc//tei:sender/tei:persName[1]/@key:)
    let $addresseeID := ($doc//tei:correspAction[@type='received']/tei:*[self::tei:persName or self::tei:orgName or self::tei:name])[1]/@key
    let $authorColl := 
        if($authorID) then core:getOrCreateColl('letters', $authorID, true())
        else ()
    let $indexOfCurrentLetter := sort:index('letters', $doc)
    
    (: Vorausgehender Brief in der Liste des Autors (= vorheriger von-Brief) :)
    let $prevLetterFromSender := wdt:letters($authorColl[sort:index('letters', .) lt $indexOfCurrentLetter]//tei:correspAction[@type='sent']/tei:*[self::tei:persName or self::tei:orgName or self::tei:name][@key=$authorID])('sort')(())[last()]/root()
    (: Vorausgehender Brief in der Liste an den Autors (= vorheriger an-Brief) :)
    let $prevLetterToSender := wdt:letters($authorColl[sort:index('letters', .) lt $indexOfCurrentLetter]//tei:correspAction[@type='received']/tei:*[self::tei:persName or self::tei:orgName or self::tei:name][@key=$authorID])('sort')(())[last()]/root()
    (: Nächster Brief in der Liste des Autors (= nächster von-Brief) :)
    let $nextLetterFromSender := wdt:letters($authorColl[sort:index('letters', .) gt $indexOfCurrentLetter]//tei:correspAction[@type='sent']/tei:*[self::tei:persName or self::tei:orgName or self::tei:name][@key=$authorID])('sort')(())[1]/root()
    (: Nächster Brief in der Liste an den Autor (= nächster an-Brief) :)
    let $nextLetterToSender := wdt:letters($authorColl[sort:index('letters', .) gt $indexOfCurrentLetter]//tei:correspAction[@type='received']/tei:*[self::tei:persName or self::tei:orgName or self::tei:name][@key=$authorID])('sort')(())[1]/root()
    (: Direkter vorausgehender Brief des Korrespondenzpartners (worauf dieser eine Antwort ist) :)
    let $prevLetterFromAddressee := wdt:letters($authorColl[sort:index('letters', .) lt $indexOfCurrentLetter]//tei:correspAction[@type='sent']/tei:*[self::tei:persName or self::tei:orgName or self::tei:name][@key=$addresseeID])('sort')(())[last()]/root()
    (: Direkter vorausgehender Brief des Autors an den Korrespondenzpartner :)
    let $prevLetterFromAuthorToAddressee := wdt:letters($authorColl[sort:index('letters', .) lt $indexOfCurrentLetter]//tei:correspAction[@type='received']/tei:*[self::tei:persName or self::tei:orgName or self::tei:name][@key=$addresseeID])('sort')(())[last()]/root()
    (: Direkter Antwortbrief des Adressaten:)
    let $replyLetterFromAddressee := wdt:letters($authorColl[sort:index('letters', .) gt $indexOfCurrentLetter]//tei:correspAction[@type='sent']/tei:*[self::tei:persName or self::tei:orgName or self::tei:name][@key=$addresseeID])('sort')(())[1]/root()
    (: Antwort des Autors auf die Antwort des Adressaten :)
    let $replyLetterFromSender := wdt:letters($authorColl[sort:index('letters', .) gt $indexOfCurrentLetter]//tei:correspAction[@type='received']/tei:*[self::tei:persName or self::tei:orgName or self::tei:name][@key=$addresseeID])('sort')(())[1]/root()
    
    let $create-map := function($letter as document-node()?, $fromTo as xs:string) as map()? {
        if($letter and exists(query:get-normalized-date($letter))) then
            map {
                'fromTo' := $fromTo,
                'doc' := $letter
            }
        else ()
    }
    
    return
        map {
            'context-letter-absolute-prev' := ($create-map($prevLetterFromSender, 'to'), $create-map($prevLetterToSender, 'from')),
            'context-letter-absolute-next' := ($create-map($nextLetterFromSender, 'to'), $create-map($nextLetterToSender, 'from')),
            'context-letter-korrespondenzstelle-prev' := ($create-map($prevLetterFromAuthorToAddressee, 'to'), $create-map($prevLetterFromAddressee, 'from')),
            'context-letter-korrespondenzstelle-next' := ($create-map($replyLetterFromSender, 'to'), $create-map($replyLetterFromAddressee, 'from'))
        }
};

declare 
    %templates:default("lang", "en")
    function app:print-letter-context($node as node(), $model as map(*), $lang as xs:string) as item()* {
        let $letter := $model('letter-norm-entry')('doc')
        let $partnerID := 
            switch($model('letter-norm-entry')('fromTo')) 
            (: There may be multiple addressees or senders! :)
            case 'from' return ($letter//tei:correspAction[@type='sent']/tei:*[self::tei:persName or self::tei:orgName or self::tei:name]/@key/tokenize(., '\s+'))[1]
            case 'to' return ($letter//tei:correspAction[@type='received']/tei:*[self::tei:persName or self::tei:orgName or self::tei:name]/@key/tokenize(., '\s+'))[1]
            default return core:logToFile('error', 'app:print-letter-context(): wrong value for parameter &quot;fromTo&quot;: &quot;' || $model('letter-norm-entry')('fromTo') || '&quot;')
        let $partner := 
            if($partnerID) then core:doc($partnerID)
            else ()
        let $normDate := query:get-normalized-date($letter)
        return (
            app:createDocLink($letter, $normDate, $lang, ()), 
            ": ",
            lang:get-language-string($model('letter-norm-entry')('fromTo'), $lang),
            " ",
            if($partner) then app:createDocLink($partner, query:get-reg-name($partnerID), $lang, ())
            else lang:get-language-string('unknown', $lang)
        )
};

(:~
 : Constructs letter header
 :
 : @author Peter Stadler
 : @param $doc document node
 : @param $lang the current language (de|en)
 : @return element
:)
declare function app:construct-title($doc as document-node(), $lang as xs:string) as element()+ {
    (: Support for Albumblätter?!? :)
    let $id := $doc/tei:TEI/string(@xml:id)
    let $date := date:printDate(($doc//tei:correspAction[@type='sent']/tei:date)[1], $lang)
    let $sender := app:printCorrespondentName(($doc//tei:correspAction[@type='sent']/tei:*[self::tei:persName or self::tei:orgName or self::tei:name])[1], $lang, 'fs')/string()
    let $addressee := app:printCorrespondentName(($doc//tei:correspAction[@type='received']/tei:*[self::tei:persName or self::tei:orgName or self::tei:name])[1], $lang, 'fs')/string()
    let $placeSender := str:normalize-space(($doc//tei:correspAction[@type='sent']/tei:*[self::tei:placeName or self::tei:settlement or self::tei:region])[1])
    let $placeAddressee := str:normalize-space(($doc//tei:correspAction[@type='received']/tei:*[self::tei:placeName or self::tei:settlement or self::tei:region])[1])
    return (
        element tei:title {
            concat($sender, ' ', lower-case(lang:get-language-string('to', $lang)), ' ', $addressee),
            if($placeAddressee) then concat(' ', lower-case(lang:get-language-string('in', $lang)), ' ', $placeAddressee) else(),
            <tei:lb/>,
            if($placeSender) then string-join(($placeSender, $date), ', ')
            else $date
        }
    )
};


(:~
 : Create dateline and author link for website news
 : (Helper Function for app:print-transcription)
 :
 : @author Peter Stadler
 : @param $doc the news document node
 : @param $lang the current language (de|en)
 : @return element html:p
 :)
declare %private function app:get-news-foot($doc as document-node(), $lang as xs:string) as element(p)? {
    let $authorID := query:get-authorID($doc)
    let $dateFormat := 
        if ($lang = 'en') then '%A, %B %d, %Y'
                          else '%A, %d. %B %Y'
    return 
        if($authorID) then 
            element p {
                attribute class {'authorDate'},
                app:printCorrespondentName(query:get-author-element($doc), $lang, 'fs'),
                concat(', ', date:strfdate(datetime:date-from-dateTime($doc//tei:publicationStmt/tei:date/@when), $lang, $dateFormat))
            }
        else()
};

declare function app:init-facsimile($node as node(), $model as map(*)) as element(div) {
    let $image-url := core:link-to-current-app('IIIF/' || $model('docID') || '/manifest.json')
(:    let $image-originalMaxSize := doc($config:data-collection-path || '/images/images.xml')//image[@id=$model('docID')]/data(@height) :)
    return 
        element {name($node)} {
            if($image-url) then (
                $node/@*[not(name()=('data-originalMaxSize', 'data-url'))],
                attribute {'data-url'} {$image-url}
(:                attribute {'data-originalMaxSize'} {$image-originalMaxSize} :)
            )
            else $node/@*
        }
};

(:
 : ****************************
 : Searches
 : ****************************
:)

declare 
    %templates:default("lang", "en")
    function app:search-filter($node as node(), $model as map(*), $lang as xs:string) as element(label)* {
        let $selected-docTypes := request:get-parameter('d', ()) 
        return 
            for $docType in $search:wega-docTypes
            let $class := 
                if($docType = $selected-docTypes) then normalize-space($node/@class) || ' active'
                else normalize-space($node/@class)
            let $displayTitle := lang:get-language-string($docType, $lang)
            order by $displayTitle
            return
                element {name($node)} {
                    $node/@*[not(name(.) = 'class')],
                    attribute class {$class},
                    element input {
                        $node/xhtml:input/@*[not(name(.) = 'value')],
                        attribute value {$docType},
                        if($docType = $selected-docTypes) then attribute checked {'checked'}
                        else ()
                    },
                    $displayTitle
                }
};

(:declare 
    %templates:wrap
    function app:search-results-count($node as node(), $model as map(*)) as xs:string {
        count($model('search-results')) || ' Suchergebnisse'
};
:)

declare 
    %templates:default("lang", "en")
    function app:preview-icon($node as node(), $model as map(*), $lang as xs:string) as element(a) {
        element {name($node)} {
            $node/@*[not(name(.) = 'href')],
            attribute href {app:createUrlForDoc($model('doc'), $lang)},
            templates:process($node/node(), $model)
    }
};

(:~
 : Overwrites the current model with 'doc' and 'docID' of the preview document
 :
 :)
declare
    %templates:wrap
    function app:preview($node as node(), $model as map(*)) as map(*) {
        map {
            'doc' := $model('result-page-entry'),
            'docID' := $model('result-page-entry')/root()/*/data(@xml:id),
            'relators' := $model('result-page-entry')//mei:fileDesc/mei:titleStmt/mei:respStmt/mei:persName[@role],
            'biblioType' := $model('result-page-entry')/tei:biblStruct/data(@type),
            'workType' := $model('result-page-entry')//mei:term/data(@classcode)
        }
};

declare 
    %templates:default("lang", "en")
    function app:preview-title($node as node(), $model as map(*), $lang as xs:string) as element() {
        element {name($node)} {
            $node/@*[not(name(.) = 'href')],
            if($node[self::xhtml:a]) then attribute href {app:createUrlForDoc($model('doc'), $lang)}
            else (),
            if(config:is-person($model('docID'))) then query:get-reg-name($model('docID'))
            else if(config:is-org($model('docID'))) then query:get-reg-name($model('docID'))
            else app:document-title($node, $model, $lang)
    }
};

declare 
    %templates:default("lang", "en")
    function app:preview-incipit($node as node(), $model as map(*), $lang as xs:string) as xs:string {
        str:normalize-space(app:print-incipit($node, $model, $lang))
};

declare 
    %templates:default("lang", "en")
    function app:preview-summary($node as node(), $model as map(*), $lang as xs:string) as xs:string {
        str:normalize-space(app:print-summary($node, $model, $lang))
};

declare 
    %templates:default("lang", "en")
    function app:preview-citation($node as node(), $model as map(*), $lang as xs:string) as element(p)? {
        let $source := query:get-main-source($model('doc'))
        return 
            typeswitch($source)
            case element(tei:biblStruct) return 
                element {name($node)} {
                    $node/@*,
                    bibl:printCitation($source, 'p', $lang)/node()
                }
            default return ()
};

declare 
    %templates:wrap
    %templates:default("max", "200")
    function app:preview-teaser($node as node(), $model as map(*), $max as xs:string) as xs:string {
        str:shorten-text($model('doc')/tei:ab | $model('doc')//tei:body, number($max))
};


declare 
    %templates:default("lang", "en")
    function app:preview-opus-no($node as node(), $model as map(*), $lang as xs:string) as element()? {
        if(exists($model('doc')//mei:altId[@type != 'gnd'])) then 
            element {name($node)} {
                $node/@*[not(name(.) = 'href')],
                if($node[self::xhtml:a]) then attribute href {app:createUrlForDoc($model('doc'), $lang)}
                else (),
                if(exists($model('doc')//mei:altId[@type='WeV'])) then concat('(WeV ', $model('doc')//mei:altId[@type='WeV'], ')') (: Weber-Werke :)
                else concat('(', $model('doc')//(mei:altId[@type != 'gnd'])[1]/string(@type), ' ', $model('doc')//(mei:altId[@type != 'gnd'])[1], ')') (: Fremd-Werke :)
            }
        else()
};

declare 
    %templates:default("lang", "en")
    function app:preview-subtitle($node as node(), $model as map(*), $lang as xs:string) as element(h4)? {
        if(exists($model('doc')//mei:fileDesc/mei:titleStmt/mei:title[@type = 'sub'])) then 
            element {name($node)} {
                $node/@*,
                data($model('doc')//mei:fileDesc/mei:titleStmt/mei:title[@type = 'sub'][1])
            }
        else()
};


declare 
    %templates:wrap
    %templates:default("lang", "en")
    function app:preview-relator-role($node as node(), $model as map(*), $lang as xs:string) as xs:string {
        lang:get-language-string($model('relator')/data(@role), $lang)
};

declare 
    %templates:wrap
    %templates:default("lang", "en")
    function app:preview-relator-name($node as node(), $model as map(*), $lang as xs:string) as xs:string {
        if($model('relator')/@dbkey) then query:get-reg-name($model('relator')/@dbkey)
        else str:normalize-space($model('relator'))
};

declare 
    %templates:wrap
    %templates:default("lang", "en")
    function app:register-title($node as node(), $model as map(*), $lang as xs:string) as xs:string {
        lang:get-language-string($model('docType'), $lang)
};

declare function app:register-dispatch($node as node(), $model as map(*)) {
    switch($model('docType'))
    case 'persons' case 'personsPlus' return templates:include($node, $model, 'templates/ajax/contacts.html')
    case 'letters' return templates:include($node, $model, 'templates/ajax/correspondence.html')
    default return templates:include($node, $model, 'templates/ajax/' || $model('docType') || '.html')
};

declare 
    %templates:wrap
    function app:letter-count($node as node(), $model as map(*)) as xs:integer? {
        query:correspondence-partners($model('docID'))($model('parent-docID'))
};

declare 
    %templates:wrap
    function app:error-settings($node as node(), $model as map(*)) as map(*) {
        map {
            'bugEmail' := config:get-option('bugEmail') 
        }
}; 
