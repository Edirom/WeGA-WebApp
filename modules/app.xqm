xquery version "3.1" encoding "UTF-8";

module namespace app="http://xquery.weber-gesamtausgabe.de/modules/app";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace gndo="https://d-nb.info/standards/elementset/gnd#";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace gn="http://www.geonames.org/ontology#";
declare namespace sr="http://www.w3.org/2005/sparql-results#";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace map="http://www.w3.org/2005/xpath-functions/map";
declare namespace ft="http://exist-db.org/xquery/lucene";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";

import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace crud="http://xquery.weber-gesamtausgabe.de/modules/crud" at "crud.xqm";
import module namespace img="http://xquery.weber-gesamtausgabe.de/modules/img" at "img.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace controller="http://xquery.weber-gesamtausgabe.de/modules/controller" at "controller.xqm";
import module namespace bibl="http://xquery.weber-gesamtausgabe.de/modules/bibl" at "bibl.xqm";
import module namespace search="http://xquery.weber-gesamtausgabe.de/modules/search" at "search.xqm";
import module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util" at "wega-util.xqm";
import module namespace wdt="http://xquery.weber-gesamtausgabe.de/modules/wdt" at "wdt.xqm";
import module namespace gl="http://xquery.weber-gesamtausgabe.de/modules/gl" at "gl.xqm";
import module namespace er="http://xquery.weber-gesamtausgabe.de/modules/external-requests" at "external-requests.xqm";
import module namespace functx="http://www.functx.com";
import module namespace kwic="http://exist-db.org/xquery/kwic";
import module namespace templates="http://exist-db.org/xquery/html-templating";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/str.xqm";
import module namespace app-shared="http://xquery.weber-gesamtausgabe.de/modules/app-shared" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/app-shared.xqm";
import module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/date.xqm";
import module namespace wega-util-shared="http://xquery.weber-gesamtausgabe.de/modules/wega-util-shared" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/wega-util-shared.xqm";

(:
 : ****************************
 : Generic functions
 : ****************************
:)

(:~
 : Creates an xhtml:a link to a WeGA document
 :
 : @author Peter Stadler
 : @param $doc the document to create the link for
 : @param $content the string content for the xhtml a element
 : @param $lang the language switch (en, de)
 : @param $attributes a sequence of attribute-value-pairs, e.g. ('class=xy', 'style=display:block')
 :)
declare function app:createDocLink($doc as document-node()?, $content as xs:string, $lang as xs:string, $attributes as xs:string*) as element(xhtml:a) {
    let $href := controller:create-url-for-doc($doc, $lang)
    let $docID :=  $doc/root()/*/@xml:id
    return 
    element xhtml:a {
        attribute href {$href},
        if(exists($attributes)) then for $att in $attributes return attribute {substring-before($att, '=')} {substring-after($att, '=')} 
        else (),
        $content
    }
};

(:~
 : Creates an xhtml:a link to a WeGA document with popover preview
 : This is a shortcut version of the 3-arity function app:createDocLink()
 :
 : @author Peter Stadler
 : @param $doc the document to create the link for
 : @param $content the string content for the xhtml a element
 : @param $lang the language switch (en, de)
 : @param $attributes a sequence of attribute-value-pairs, e.g. ('class=xy', 'style=display:block')
 : @param $popover whether to add class attributes for popovers
 : @return a html:a element
 :)
declare function app:createDocLink($doc as document-node()?, $content as xs:string, $lang as xs:string, $attributes as xs:string*, $popover as xs:boolean) as element(xhtml:a) {
    if($popover) then 
        let $docID := $doc/*/data(@xml:id)
        let $docType := config:get-doctype-by-id($docID)
        return app:createDocLink($doc,$content, $lang, ($attributes, string-join(('class=preview', $docType, $docID), ' ')))
    else app:createDocLink($doc,$content, $lang, $attributes)
};

declare 
    %templates:wrap
    function app:documentFooter($node as node(), $model as map(*)) as map(*) {
        let $lang := $model('lang')
        let $svnProps := config:get-svn-props($model('docID'))
        let $author := map:get($svnProps, 'author')
        let $date := xs:dateTime(map:get($svnProps, 'dateTime'))
        let $formatedDate := 
            try { date:format-date($date, $config:default-date-picture-string($lang), $lang) }
            catch * { wega-util:log-to-file('warn', 'Failed to get Subversion properties for ' || $model('docID') ) }
        let $version := concat(config:expath-descriptor()/@version, if($config:isDevelopment) then 'dev' else '')
        let $versionDate := date:format-date(xs:date(config:get-option('versionDate')), $config:default-date-picture-string($lang), $lang)
        return
            map {
                'bugEmail' : config:get-option('bugEmail'),
                'permalink' : config:permalink($model('docID')),
                'versionNews' : app:createDocLink(crud:doc(config:get-option('versionNews')), lang:get-language-string('versionInformation',($version, $versionDate), $lang), $lang, ()),
                'latestChange' :
                    if($config:isDevelopment) then lang:get-language-string('lastChangeDateWithAuthor',($formatedDate,$author),$lang)
                    else lang:get-language-string('lastChangeDateWithoutAuthor', $formatedDate, $lang)
            }
};

declare 
    %templates:wrap
    function app:bugreport($node as node(), $model as map(*)) as map(*) {
    	map {
                'bugEmail' : config:get-option('bugEmail')
            }
};

declare 
    %templates:default("format", "WeGA")
    function app:download-link($node as node(), $model as map(*), $format as xs:string) as element() {
        let $url := replace(controller:create-url-for-doc($model('doc'), $model('lang')), '\.html', '.xml')
        return 
            element {node-name($node)} {
                $node/@* except $node/@href,
                attribute href {
                    switch($format)
                    case 'WeGA' return $url
                    case 'tei_all' return $url || '?format=tei_all'
                    case 'mei_all' return $url || '?format=mei_all'
                    case 'tei_simplePrint' return $url || '?format=tei_simplePrint'
                    case 'text' return replace($url, '\.xml', '.txt')
                    case 'dta' return $url || '?format=dta'
                    default return wega-util:log-to-file('warn', 'app:download-link(): unsupported format "' || $format || '"!')
                },
                templates:process($node/node(), $model)
            }
};

(:~
 : get and set line-wrap variable
 : (whether a user prefers code examples with or without wrapped lines)
 :)
declare 
    %templates:wrap
    function app:line-wrap($node as node(), $model as map(*)) as map(*)? {
        map {
            'line-wrap' : config:line-wrap()
        }
};

declare function app:set-line-wrap($node as node(), $model as map(*)) as element() {
    element {node-name($node)} {
        if($model('line-wrap')) then ( 
            $node/@*[not(name(.)='class')],
            attribute class {string-join(($node/@class, 'line-wrap'), ' ')}
        )
        else $node/@*,
        templates:process($node/node(), $model)
    }
};



(:
 : ****************************
 : Breadcrumbs 
 : ****************************
:)
declare 
    %templates:default("lang", "en")
    function app:breadcrumb-person($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:a) {
        let $authorID := tokenize($model?('exist:path'), '/')[3]
        let $anonymusID := config:get-option('anonymusID')
        let $authorElem :=
            (: NB: there might be multiple anonymous authors :)
            if ($authorID = $anonymusID) then (query:get-author-element($model?doc)[(count(@key | @codedval) = 0) or ((@key, @codedval) = $anonymusID)])[1]
            (: NB: there might be multiple occurences of the same person as e.g. composer and lyricist :)
            else (query:get-author-element($model?doc)[(@key, @codedval) = $authorID])[1]
        let $href :=
            if ($authorID = $anonymusID) then ()
            else controller:create-url-for-doc(crud:doc($authorID), $lang)
        let $elem := 
            if($href) then QName('http://www.w3.org/1999/xhtml', 'a')
            else QName('http://www.w3.org/1999/xhtml', 'span')
        let $name := wega-util:print-forename-surname-from-nameLike-element($authorElem)
        return 
            element {$elem} {
                $node/@*[not(local-name(.) eq 'href')],
                if($href) then attribute href {$href} else (),
                $name
            }
};

declare
    %templates:default("lang", "en")
    function app:breadcrumb-docType($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:a) {
        let $href := config:link-to-current-app(functx:substring-before-last($model('$exist:path'), '/'))
        let $display-name := replace(xmldb:decode(functx:substring-after-last($href, '/')), '_', ' ')
        let $elem := 
            if($href and not(contains($href, config:get-option('anonymusID')))) then QName('http://www.w3.org/1999/xhtml', 'a')
            else QName('http://www.w3.org/1999/xhtml', 'span')
        return
            element {$elem} {
                $node/@*[not(local-name(.) eq 'href')],
                if(local-name-from-QName($elem) = 'a') then attribute href {$href} else (),
                $display-name
            }
};

declare 
    %templates:default("lang", "en")
    function app:breadcrumb-register1($node as node(), $model as map(*), $lang as xs:string) as item() {
        switch($model('docType')) 
        case 'indices' return 
            element xhtml:span {
                lang:get-language-string('indices', $lang)
            }
        case 'biblio' case 'news' return 
            element {node-name($node)} {
                $node/@*[not(local-name(.) eq 'href')],
                lang:get-language-string('project', $lang)
            }
        default return
            element {node-name($node)} {
                $node/@*[not(local-name(.) eq 'href')],
                attribute href {config:link-to-current-app(controller:path-to-register('indices', $lang))},
                lang:get-language-string('indices', $lang)
            }
};

declare 
    %templates:default("lang", "en")
    function app:breadcrumb-register2($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:a)? {
        if($model('docType') = 'indices') then ()
        else 
            element {node-name($node)} {
                $node/@*,
                lang:get-language-string($model('docType'), $lang)
            }
};

declare 
    %templates:default("lang", "en")
    function app:breadcrumb-var($node as node(), $model as map(*), $lang as xs:string) as element() {
        let $pathTokens := tokenize($model?('$exist:path'), '/')
        return 
            element {node-name($node)} {
                $node/@*,
                $pathTokens[3]
            }
};

declare
    %templates:default("lang", "en")
    function app:breadcrumb-var2($node as node(), $model as map(*), $lang as xs:string) as element() {
        let $docID := $model('docID')
        let $breadcrumb := $controller:projectNav[?docID=$docID]?title
        return
            element {node-name($node)} {
                $node/@*,
                lang:get-language-string($breadcrumb,$lang)
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
        let $alwaysShowNoCount := $tabTitle = ('biographies', 'history', 'descriptions')
        return
            if($count gt 0 or $alwaysShowNoCount) then
                element {node-name($node)} {
                        $node/@*[not(name(.)='data-target')],
                        if($node/@data-target) then attribute data-target {replace($node/@data-target, '\$docID', $model('docID'))} else (),
                        lang:get-language-string($tabTitle, $lang),
                        if($alwaysShowNoCount) then () else <small>{' (' || $count || ')'}</small>
                    }
            else 
                element {node-name($node)} {
                    attribute class {'deactivated'}
                }
};

declare
    %templates:default("lang", "en")
    function app:ajax-tab($node as node(), $model as map(*), $lang as xs:string) as element() {
        let $ajax-resource :=
            switch(normalize-space($node))
            case 'XML-Preview' return 'xml.html'
            case 'examples' return if(gl:schemaIdent2docType($model?schemaID) = (for $func in $wdt:functions return $func(())('name'))) then 'examples.html' else ()
            case 'wikipedia-article' return 
                if($model?gnd and exists(er:grab-external-resource-wikidata($model?gnd, 'gnd')//sr:binding[@name=('article' || upper-case($lang))]/sr:uri/data(.))) then 'wikipedia.html'
                else if($model?viaf and exists(er:grab-external-resource-wikidata($model?viaf, 'viaf')//sr:binding[@name=('article' || upper-case($lang))]/sr:uri/data(.))) then 'wikipedia.html'
                else ()
            case 'adb-article' return if($model?gnd and er:lookup-gnd-from-beaconProvider('adbBeacon', $model?gnd)) then 'adb.html' else ()
            case 'ndb-article' return if($model?gnd and er:lookup-gnd-from-beaconProvider('ndbBeacon', $model?gnd)) then 'ndb.html' else ()
            case 'gnd-entry' return if($model('gnd')) then 'dnb.html' else ()
            case 'backlinks' return if($model('backlinks')) then 'backlinks.html' else ()
            case 'gnd-beacon' return if($model('gnd')) then 'beacon.html' else ()
            default return ()
        let $ajax-url :=
        	if(config:get-doctype-by-id($model('docID')) and $ajax-resource) then config:link-to-current-app(controller:path-to-resource($model('doc'), $lang)[1] || '/' || $ajax-resource)
        	else if(gl:spec($model?specID, $model?schemaID) and $ajax-resource) then config:link-to-current-app(replace($model('exist:path'), '\.[xhtml]+$', '') || '/' || $ajax-resource)
        	else ()
        return
            if($ajax-url) then 
                element {node-name($node)} {
                    $node/@*,
                    attribute data-tab-url {$ajax-url},
                    lang:get-language-string(normalize-space($node), $lang)
                }
            else
                element {node-name($node)} {
                    attribute class {'nav-link deactivated'}
                }
};


declare
    %templates:default("lang", "en")
    function app:facsimile-tab($node as node(), $model as map(*), $lang as xs:string) as element() {
        if(count($model?localFacsimiles | $model?externalIIIFManifestFacsimiles) gt 0) then 
            element {node-name($node)} {
                $node/@*,
                lang:get-language-string(normalize-space($node), $lang)
            }
        else
            element {node-name($node)} {
                attribute class {'deactivated'}
            }
};

declare
    %templates:default("lang", "en")
    function app:tab($node as node(), $model as map(*), $lang as xs:string) as element() {
        (: Currently only needed for "PND Beacon Links" :)
        if($model('gnd')) then
            element {node-name($node)} {
                $node/@*,
                normalize-space($node)
            }
        else
            element {node-name($node)} {
                attribute class {'deactivated'}
            }
};

declare
    %templates:wrap
    %templates:default("page", "1")
    %templates:default("lang", "en")
    function app:pagination($node as node(), $model as map(*), $page as xs:string, $lang as xs:string) as element(xhtml:li)* {
        let $page := if($page castable as xs:int) then xs:int($page) else 1
        let $a-element := function($page as xs:int, $text as xs:string) {
            element xhtml:a {
                attribute class {'page-link'},
                (: for AJAX pages (e.g. correspondence) called from a person page we need the data-url attribute :) 
                if($model('docID') = 'indices') then attribute href {app:page-link($model, map { 'page': $page} )}
                (: for index pages there is no javascript needed but a direct refresh of the page :)
                else attribute data-url {app:page-link($model, map { 'page': $page} )},
                $text
            }
        }
        let $last-page := ceiling(count($model('search-results')) div config:entries-per-page()) 
        return
        (
            if($page le 1) then
             <li xmlns="http://www.w3.org/1999/xhtml" class="page-item disabled"><a class="page-link">{'&#x00AB; ' || lang:get-language-string('paginationPrevious', $lang)}</a></li>
             else <li xmlns="http://www.w3.org/1999/xhtml" class="page-item">{$a-element($page - 1, '&#x00AB; ' || lang:get-language-string('paginationPrevious', $lang)) }</li>,
            if($page gt 3) then <li xmlns="http://www.w3.org/1999/xhtml" class="page-item d-none d-sm-inline">{$a-element(1, '1')}</li> else (),
            if($page gt 4) then <li xmlns="http://www.w3.org/1999/xhtml" class="page-item disabled d-none d-sm-inline"><a class="page-link">…</a></li> else (),
            ($page - 2, $page - 1)[. gt 0] ! <li xmlns="http://www.w3.org/1999/xhtml" class="page-item d-none d-lg-inline">{$a-element(., string(.))}</li>,
            <li xmlns="http://www.w3.org/1999/xhtml" class="page-item active"><a class="page-link">{$page}</a></li>,
            ($page + 1, $page + 2)[. le $last-page] ! <li xmlns="http://www.w3.org/1999/xhtml" class="page-item d-none d-lg-inline">{$a-element(., string(.))}</li>,
            if($page + 3 lt $last-page) then <li xmlns="http://www.w3.org/1999/xhtml" class="page-item disabled d-none d-sm-inline"><a class="page-link">…</a></li> else (),
            if($page + 2 lt $last-page) then <li xmlns="http://www.w3.org/1999/xhtml" class="page-item d-none d-sm-inline">{$a-element($last-page, string($last-page))}</li> else (),
            if($page ge $last-page) then
                <li xmlns="http://www.w3.org/1999/xhtml" class="page-item disabled">{
                    <a class="page-link">{lang:get-language-string('paginationNext', $lang) || ' &#x00BB;'}</a>
                }</li>
            else <li xmlns="http://www.w3.org/1999/xhtml" class="page-item">{$a-element($page + 1, lang:get-language-string('paginationNext', $lang) || ' &#x00BB;')}</li>
        )
};

declare
    %templates:wrap
    function app:set-entries-per-page($node as node(), $model as map(*)) as map(*) {
		map {
			'limit' : config:entries-per-page(),
			'moreresults' : if ( count($model('search-results')) gt config:entries-per-page() ) then 'true' else ()
		}
};

declare function app:switch-limit($node as node(), $model as map(*)) as element() {
	element {node-name($node)} {
		if($model?limit = number($node)) then attribute class {'page-item active'} else attribute class {'page-item'},
		element xhtml:a {
			attribute class {'page-link'},
			(: for AJAX pages (e.g. correspondence) called from a person page we need the data-url attribute :) 
            if($model('docID') = 'indices') then attribute href {app:page-link($model, map { 'limit': string($node) } )}
            (: for index pages there is no javascript needed but a direct refresh of the page :)
            else attribute data-url {app:page-link($model, map { 'limit': string($node) } )},
			string($node)
		}
	}
};

(:~
 : construct a link to the current page consisting of URL parameters only
 : helper function for pagination
 :
 : @param $model the current model map with filters etc.
 : @param $params the new parameters that will override (eventually existing parameters from $model)
 : @return a string starting with "?"
~:)
declare %private function app:page-link($model as map(*), $params as map(*)) as xs:string {
	let $URLparams := request:get-parameter-names()[.=($search:valid-params, 'd', 'q', 'oldFromDate', 'oldToDate')]
    let $paramsMap := map:merge((map { 'limit': config:entries-per-page() }, $model('filters'), $URLparams ! map:entry(., request:get-parameter(., ())), $params))
    return
        replace(
	        string-join(
	            map:keys($paramsMap) ! (
	                '&amp;' || string(.) || '=' || string-join(
	                    ($paramsMap(.) ! encode-for-uri(.)),
	                    '&amp;' || string(.) || '=')
	                ), 
	            ''),
            '^&amp;', '?'
        )
};

declare 
    %templates:wrap
    %templates:default("lang", "en")
    function app:active-nav($node as node(), $model as map(*), $lang as xs:string) as map(*) {
        let $active := $node//xhtml:a/@href[controller:encode-path-segments-for-uri(controller:resolve-link(functx:substring-before-if-contains(., '#'), $model)) = request:get-uri()]
        return
            map {'active-nav': $active}
};

declare 
    %templates:default("lang", "en")
    function app:set-active-nav($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:li) {
        let $active := exists($node//xhtml:a[@href = $model('active-nav')])
        return
            element {node-name($node)} {
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
    function app:set-active-lang($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:li) {
        let $curLang := lower-case(normalize-space($node))
        let $isActive := $lang = $curLang
        return
            element {node-name($node)} {
                if($isActive) then (
                    $node/@*[not(name(.)='class')],
                    attribute class {string-join(($node/@class, 'active'), ' ')}
                )
                else $node/@*,
                
                (: Child element a takes the link :)
                element xhtml:a {
                    attribute class {"nav-link"},
                    attribute href {
                        if($isActive) then '#'
                        else controller:translate-URI(request:get-uri(), $lang, lower-case(normalize-space($node)))
                    },
                    attribute hreflang { $curLang },
                    attribute lang { $curLang },
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
    function app:set-slider-range($node as node(), $model as map(*), $fromDate as xs:string, $toDate as xs:string) as element(xhtml:input) {
    element {node-name($node)} {
         $node/@*,
         attribute data-min-slider {if($model('oldFromDate') castable as xs:date) then $model('oldFromDate') else $model('earliestDate')},
         attribute data-max-slider {if($model('oldToDate') castable as xs:date) then $model('oldToDate') else $model('latestDate')},
         attribute data-from-slider {if($fromDate castable as xs:date) then $fromDate else $model('earliestDate')},
         attribute data-to-slider {if($toDate castable as xs:date) then $toDate else $model('latestDate')}
    }
};

declare function app:set-facet-checkbox($node as node(), $model as map(*), $key as xs:string) as element(xhtml:input) {
    element {node-name($node)} {
         $node/@*,
         if(map:contains($model('filters'), $key)) then attribute checked {'checked'}
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
 : Used by templates/ajax/popover.html
 :
 :)
declare function app:popover($node as node(), $model as map(*)) as map(*)* {
    map {
        'result-page-entry' : $model('doc')
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
            if(count($words) gt 1) then util:random(count($words) - 1) + 1 (: util:random may return 0 and takes as argument positiveInteger! :)
            else if(count($words) eq 1) then 1
            else wega-util:log-to-file('info', 'app:word-of-the-day(): no words of the day found')
        return 
            map {
                'wordOfTheDay' : 
                    if($random) then str:enquote(str:normalize-space(string-join(str:txtFromTEI($words[$random], $lang), '')), $lang)
                    else str:normalize-space($node/xhtml:h1),
                'wordOfTheDayURL' : 
                    if($random) then controller:create-url-for-doc(crud:doc($words[$random]/ancestor::tei:TEI/string(@xml:id)), $lang)
                    else '#'
            }
};

declare 
    %templates:wrap
    %templates:default("otd-date", "")
    function app:lookup-todays-events($node as node(), $model as map(*), $otd-date as xs:string) as map(*) {
    let $date := 
        if($otd-date castable as xs:date) then xs:date($otd-date)
        else current-date()
    let $events := 
        for $i in query:getTodaysEvents($date)
        order by $i/xs:date(@when) ascending
        return $i
    let $length := count($events)
    return
        map {
            'otd-date' : $date,
            'events1' : subsequence($events, 1, ceiling($length div 2)),
            'events2' : subsequence($events, ceiling($length div 2) + 1)
        }
};

declare function app:print-event($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:span)* {
    let $date := $model?otd-date
    let $teiDate := $model('event')
    let $isJubilee := (year-from-date($date) - $teiDate/year-from-date(@when)) mod 25 = 0
    let $typeOfEvent := 
        if($teiDate/ancestor::tei:correspDesc) then 'letter'
        else if($teiDate[@type='baptism']) then 'isBaptised'
        else if($teiDate/parent::tei:birth) then 'isBorn'
        else if($teiDate[@type='funeral']) then 'wasBuried'
        else if($teiDate/parent::tei:death) then 'dies'
        else ()
    return (
        element xhtml:span {
            if($isJubilee) then (
                attribute class {'jubilee event-year'},
                attribute title {lang:get-language-string('roundYearsAgo',xs:string(year-from-date($date) - $teiDate/year-from-date(@when)), $lang)},
                attribute data-toggle {'tooltip'},
                attribute data-container {'body'}
            )
            else attribute class {'event-year'},
            date:formatYear($teiDate/year-from-date(@when) cast as xs:int, $lang)
        },
        element xhtml:span {
        	attribute class {'event-text'},
            if($typeOfEvent eq 'letter') then app:createLetterLink($teiDate, $lang)
            (:else (wega:createPersonLink($teiDate/root()/*/string(@xml:id), $lang, 'fs'), ' ', lang:get-language-string($typeOfEvent, $lang)):)
            else (app:createDocLink($teiDate/root(), wega-util:print-forename-surname-from-nameLike-element($teiDate/ancestor::tei:person/tei:persName[@type='reg']), $lang, ('class=persons')), ' ', lang:get-language-string($typeOfEvent, $lang))
        }
    )
};

declare function app:print-events-title($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:h2) {
    <xhtml:h2>{lang:get-language-string('whatHappenedOn', format-date($model?otd-date, if($lang eq 'de') then '[D]. [MNn]' else '[MNn] [D]',  $lang, (), ()), $lang)}</xhtml:h2>
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
    if(exists($persName/@key)) then 
        if ($order eq 'fs') then app:createDocLink(crud:doc($persName/string(@key)), wega-util:print-forename-surname-from-nameLike-element($persName), $lang, ('class=' || config:get-doctype-by-id($persName/@key)))
        else if ($order eq 's') then app:createDocLink(crud:doc($persName/string(@key)), substring-before(query:title($persName/@key),','), $lang, ('class=preview ' || concat($persName/@key, " ", config:get-doctype-by-id($persName/@key))))
        else app:createDocLink(crud:doc($persName/string(@key)), query:title($persName/@key), $lang, ('class=' || config:get-doctype-by-id($persName/@key)))
    else if(not(functx:all-whitespace($persName))) then 
        if ($order eq 'fs') then <xhtml:span class="noDataFound">{wega-util:print-forename-surname-from-nameLike-element($persName)}</xhtml:span>
        else <xhtml:span class="noDataFound">{string($persName)}</xhtml:span>
    else <xhtml:span class="noDataFound">{lang:get-language-string('unknown', $lang)}</xhtml:span>
};

declare 
    %templates:wrap
    function app:index-news-items($node as node(), $model as map(*)) as map(*) {
        map {
            'news' : subsequence(core:getOrCreateColl('news', 'indices', true()), 1, xs:int(config:get-option('maxNews')))
        }
};

declare 
    %templates:default("lang", "en")
    function app:index-news-item($node as node(), $model as map(*), $lang as xs:string) as map(*) {
        map {
            'title' : wdt:news($model?newsItem)?title('html'),
            'date' : date:printDate($model?newsItem//tei:date[parent::tei:publicationStmt], $lang, lang:get-language-string#3, $config:default-date-picture-string),
            'url' : controller:create-url-for-doc($model?newsItem, $lang)
        }
};

declare 
    %templates:default("lang", "en")
    function app:search-options($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:option)* {
        <option xmlns="http://www.w3.org/1999/xhtml" value="all">{lang:get-language-string('all', $lang)}</option>,
        for $docType in $search:wega-docTypes
        let $displayTitle := lang:get-language-string($docType, $lang)
        order by $displayTitle
        return
            element {node-name($node)} {
                attribute value {$docType},
                $displayTitle
            }
};


(:
 : ****************************
 : Place pages
 : ****************************
:)

declare function app:place-details($node as node(), $model as map(*)) as map(*) {
    let $geonames-id := str:normalize-space(($model?doc//tei:idno[@type='geonames'])[1])
    let $gnd := query:get-gnd($model('doc'))
    let $gn-doc := er:grabExternalResource('geonames', $geonames-id, '', ())
    return
        map {
            'gnd' : $gnd,
            'names' : $model?doc//tei:placeName[@type],
            'backlinks' : core:getOrCreateColl('backlinks', $model('docID'), true()),
            'xml-download-url' : replace(controller:create-url-for-doc($model('doc'), $model('lang')), '\.html', '.xml'),
            'geonames_alternateNames' : 
                for $alternateName in $gn-doc//gn:alternateName 
                group by $name := $alternateName/text()
                order by $name 
                return
                    ($name || ' (' || $alternateName/data(@xml:lang) => string-join(', ') || ')'),
            'geonames_parentCountry' : $gn-doc//gn:parentCountry/analyze-string(@rdf:resource, '/(\d+)/')//fn:group/text() ! query:get-geonames-name(.)
        }
};

declare 
    %templates:wrap
    function app:place-basic-data($node as node(), $model as map(*)) as map(*) {
        map {
            'geonames-id' : str:normalize-space(($model?doc//tei:idno[@type='geonames'])[1]),
            'coordinates' : str:normalize-space($model?doc//tei:geo)
        }
};

declare 
    %templates:default("provider", "osm")
    function app:place-link($node as node(), $model as map(*), $provider as xs:string) as element(xhtml:a) {
        let $latLon := tokenize($model?coordinates, '\s+')
        return
            element xhtml:a {
                attribute href {
                    switch($provider)
                    case 'osm' return 'https://www.openstreetmap.org/?mlat=' || $latLon[1] || '&amp;mlon=' || $latLon[2] || '&amp;zoom=11'
                    case 'google' return 'https://www.google.com/maps/@?api=1&amp;map_action=map&amp;zoom=12&amp;basemap=terrain&amp;center=' || string-join($latLon, ',')
                    case 'geoNames' return 'http://geonames.org/' || $model?geonames-id
                    default return ''
                },
                switch($provider)
                case 'osm' return 'OpenStreetMap'
                case 'google' return 'Google'
                case 'geoNames' return $model?geonames-id
                default return ''
            }
};

(:
 : ****************************
 : Work pages
 : ****************************
:)

declare 
    %templates:wrap
    function app:work-basic-data($node as node(), $model as map(*)) as map(*) {
        let $print-titles := function($doc as document-node(), $alt as xs:boolean) {
            for $title in $doc//mei:meiHead/mei:fileDesc/mei:titleStmt/mei:title[not(@type='sub')][exists(@type='alt') = $alt]
            let $titleLang := $title/string(@xml:lang) 
            let $subTitle := ($title/following-sibling::mei:title[@type='sub'][string(@xml:lang) = $titleLang])[1]
            return <span xmlns="http://www.w3.org/1999/xhtml">{
                string-join((
                    wega-util:transform($title, doc(concat($config:xsl-collection-path, '/works.xsl')), config:get-xsl-params(())),
                    wega-util:transform($subTitle, doc(concat($config:xsl-collection-path, '/works.xsl')), config:get-xsl-params(()))
                    ),
                    '. '
                ),
                if($titleLang) then ' (' || $titleLang || ')'
                else ()
            }</span>
        }
        return
        map {
            'ids' : $model?doc//mei:altId[not(@type=('gnd', 'wikidata', 'dracor.einakter'))],
            'relators' : query:relators($model?doc),
            'workType' : $model?doc//mei:term/data(@class),
            'titles' : $print-titles($model?doc, false()),
            'altTitles' : $print-titles($model?doc, true())
        }
};

declare 
    %templates:wrap
    function app:work-details($node as node(), $model as map(*)) as map(*) {
        map {
            'sources' : 
                if($config:isDevelopment) then core:getOrCreateColl('sources', $model('docID'), true())
                else (),
            'creation' : wega-util:transform(
                ($model?doc//mei:creation, $model?doc//mei:history), 
                doc(concat($config:xsl-collection-path, '/works.xsl')), 
                config:get-xsl-params( map {'dbPath' : document-uri($model?doc), 'docID' : $model?docID })
                ), 
            'dedicatees' : $model?doc//mei:fileDesc/mei:titleStmt/mei:respStmt/mei:persName[@role='dte'],
            'notesStmt': wega-util:transform(
                $model?doc//mei:notesStmt,
                doc(concat($config:xsl-collection-path, '/works.xsl')), 
                config:get-xsl-params( map {'dbPath' : document-uri($model?doc), 'docID' : $model?docID })
                ), 
            'backlinks' : core:getOrCreateColl('backlinks', $model('docID'), true()),
            'gnd' : query:get-gnd($model('doc')),
            'xml-download-url' : replace(controller:create-url-for-doc($model('doc'), $model('lang')), '\.html', '.xml')
        }
};

declare 
    %templates:wrap
    function app:prepare-work-id($node as node(), $model as map(*)) as map(*) {
        map {
            'id-key' : $model?id/@type,
            'id-value' : $model?id/text()
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
        query:title($model('docID'))
};

declare 
    %templates:wrap
    function app:person-forename-surname($node as node(), $model as map(*)) as xs:string {
        wega-util:print-forename-surname-from-nameLike-element(($model?doc//tei:persName | $model?doc//tei:orgName)[@type='reg'])
};

declare 
    %templates:wrap
    %templates:default("lang", "en")
    function app:person-basic-data($node as node(), $model as map(*), $lang as xs:string) as map(*) {
        map{
            'fullnames' : $model('doc')//tei:persName[@type = 'full'] ! string-join(str:txtFromTEI(., $lang), ''),
            'pseudonyme' : $model('doc')//tei:persName[@type = 'pseud'] ! string-join(str:txtFromTEI(., $lang), ''),
            'birthnames' : $model('doc')//tei:persName[@subtype = 'birth'] ! string-join(str:txtFromTEI(., $lang), ''),
            'realnames' : $model('doc')//tei:persName[@type = 'real'] ! string-join(str:txtFromTEI(., $lang), ''),
            'altnames' : 
                (
                $model('doc')//tei:persName[@type = 'alt'][not(@subtype)] ! string-join(str:txtFromTEI(., $lang), ''),  
                $model('doc')//tei:orgName[@type = 'alt'] ! string-join(str:txtFromTEI(., $lang), '')
                ),
            'marriednames' : $model('doc')//tei:persName[@subtype = 'married'] ! string-join(str:txtFromTEI(., $lang), ''),
            'birth' : exists($model('doc')//tei:birth[not(tei:date[@type])]),
            'baptism' : exists($model('doc')//tei:birth/tei:date[@type='baptism']),
            'death' : exists($model('doc')//tei:death[not(tei:date[@type])]),
            'funeral' : exists($model('doc')//tei:death/tei:date[@type = 'funeral']),
            'occupations' : $model('doc')//tei:occupation | $model('doc')//tei:label[.='Art der Institution']/following-sibling::tei:desc,
            'residences' : $model('doc')//tei:residence | $model('doc')//tei:label[.='Ort']/following-sibling::tei:desc/tei:*,
            'addrLines' : $model('doc')//tei:addrLine[ancestor::tei:affiliation[tei:orgName='Carl-Maria-von-Weber-Gesamtausgabe']] 
        }
};

declare 
    %templates:wrap
    function app:person-details($node as node(), $model as map(*)) as map(*) {
    map{
        'correspondence' : core:getOrCreateColl('letters', $model('docID'), true()),
        'diaries' : core:getOrCreateColl('diaries', $model('docID'), true()),
        'writings' : core:getOrCreateColl('writings', $model('docID'), true()),
        'works' : core:getOrCreateColl('works', $model('docID'), true()),
        'contacts' : core:getOrCreateColl('contacts', $model('docID'), true()),
        'biblio' : core:getOrCreateColl('biblio', $model('docID'), true()),
        'news' : core:getOrCreateColl('news', $model('docID'), true()),
        (:distinct-values(core:getOrCreateColl('letters', $model('docID'), true())//@key[ancestor::tei:correspDesc][. != $model('docID')]) ! crud:doc(.),:)
        'backlinks' : core:getOrCreateColl('backlinks', $model('docID'), true()),
        'thematicCommentaries' : core:getOrCreateColl('thematicCommentaries', $model('docID'), true()),
        'documents' : core:getOrCreateColl('documents', $model('docID'), true()),
        
        'source' : $model('doc')/tei:person/data(@source),
        'gnd' : query:get-gnd($model?doc),
        'viaf' : query:get-viaf($model?doc),
        'xml-download-url' : replace(controller:create-url-for-doc($model('doc'), $model('lang')), '\.html', '.xml')
        (:core:getOrCreateColl('letters', 'indices', true())//@key[.=$model('docID')]/root() | core:getOrCreateColl('diaries', 'indices', true())//@key[.=$model('docID')]/root() | core:getOrCreateColl('writings', 'indices', true())//@key[.=$model('docID')]/root() | core:getOrCreateColl('persons', 'indices', true())//@key[.=$model('docID')]/root(),:)
        (:                'xml-download-URL' : config:link-to-current-app($model('docID') || '.xml'):)
    }
};

(:~
 : Prepare Beacon Links for display on person and work pages
 : Called via AJAX
 :)
declare 
    %templates:wrap 
    function app:beacon($node as node(), $model as map(*)) as map(*) {
        let $gnd := query:get-gnd($model?doc)
        let $beaconMap := 
            if($gnd) then er:beacon-map($gnd, config:get-doctype-by-id($model('docID')))
            else map {}
        return
            map { 'beaconLinks': 
                    for $i in map:keys($beaconMap)
                    order by $beaconMap($i)[2]
                    return 
                        (: replacement in @href for invalid links from www.sbn.it :)
                        <a xmlns="http://www.w3.org/1999/xhtml" title="{$i}" href="{replace($beaconMap($i)[1], '\\', '%5C')}">{$beaconMap($i)[2]}</a>
            }
};

declare 
    %templates:default("lang", "en")
    function app:print-wega-bio($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:div)* {
        let $query-result:= app:inject-query($model?doc/*)
        let $bio := wega-util:transform($query-result//(tei:note[@type='bioSummary'] | tei:event[tei:head] | tei:note[parent::tei:org]), doc(concat($config:xsl-collection-path, '/persons.xsl')), config:get-xsl-params(()))
        return
            if(some $i in $bio satisfies $i instance of element()) then $bio
            else 
                element {node-name($node)} {
                    $node/@*,
                    if($bio instance of xs:string) then <p xmlns="http://www.w3.org/1999/xhtml">{$bio}</p>
                    else templates:process($node/node(), $model)
                }
};

declare 
    %templates:wrap
    function app:printPlaceOfBirthOrDeath($node as node(), $model as map(*), $key as xs:string) as xs:string* {
    let $placeNames :=
        switch($key)
        case 'birth' return query:placeName-elements($model('doc')//tei:birth)
        case 'death' return query:placeName-elements($model('doc')//tei:death)
        default return ()
    return
        for $placeName at $count in wega-util-shared:order-by-cert($placeNames)
        let $preposition :=
            if(matches(normalize-space($placeName), '^(auf|bei|im)')) then ' ' (: Präposition 'in' weglassen wenn schon eine andere vorhanden :)
            else concat(' ', lower-case(lang:get-language-string('in', $model('lang'))), ' ')
        return (
            $preposition || str:normalize-space($placeName),
            if($count eq count($placeNames)) then ()
            else concat(' ',lang:get-language-string('or', $model('lang')),' ')
        )
};

declare 
    %templates:wrap
    function app:printDatesOfBirthOrDeath($node as node(), $model as map(*), $key as xs:string) as item()* {
        let $dates :=
            switch($key)
            case 'birth' return $model('doc')//tei:birth/tei:date[not(@type)]
            case 'baptism' return $model('doc')//tei:birth/tei:date[@type = 'baptism']
            case 'death' return $model('doc')//tei:death/tei:date[not(@type)]
            case 'funeral' return $model('doc')//tei:death/tei:date[@type = 'funeral']
            default return ()
        let $orderedDates := wega-util-shared:order-by-cert($dates)
        let $julian-tooltip := function($date as xs:date, $lang as xs:string) as element(xhtml:sup)? {
            let $julian-date := date:gregorian2julian($date)
            let $formated-julian-date := 
                if($julian-date castable as xs:date) then date:format-date(xs:date($julian-date), $config:default-date-picture-string($lang), $lang)
                (: special case for Julian leap years :)
                else if(ends-with($julian-date, '-02-29')) then replace(
                    date:format-date(xs:date('1600' || substring($julian-date, 5)), $config:default-date-picture-string($lang), $lang),
                    '1600',
                    substring($julian-date, 1, 4)
                )
                else ()
            return
                if($formated-julian-date) then
                <sup xmlns="http://www.w3.org/1999/xhtml"
                    class="jul" 
                    data-toggle="tooltip" 
                    data-container="body" 
                    title="{concat(lang:get-language-string('julianDate', $lang), ': ', $formated-julian-date)}"
                    >greg.</sup>
                else ()
        }
        return (
            date:printDate($orderedDates[1], $model?lang, lang:get-language-string#3, $config:default-date-picture-string),
            if(($orderedDates[1])[@calendar='Julian'][@when]) then ($julian-tooltip(xs:date($orderedDates[1]/@when), $model?lang))
            else (),
            (
                if(count($orderedDates) gt 1) then (
                    ' (' || lang:get-language-string('otherSources', $model?lang) || ': ',
                    
                    for $date at $count in subsequence($orderedDates, 2)
                    return 
                        <span xmlns="http://www.w3.org/1999/xhtml">{
                            date:printDate($date, $model?lang, lang:get-language-string#3, $config:default-date-picture-string),
                            if($date[@calendar='Julian'][@when]) then ($julian-tooltip(xs:date($date/@when), $model?lang))
                            else (),
                            if($count < count($orderedDates) - 1) then ', '
                            else ()
                        }</span>,
                        
                    ')'
                )
                else ()
            )
        )
};

declare
    %templates:wrap
    function app:portrait-credits($node as node(), $model as map(*)) as item()* {
        if($model('portrait')('source') = 'Carl-Maria-von-Weber-Gesamtausgabe') then ()
        else (
            $model('portrait')('source'),
            if(contains($model('portrait')('linkTarget'), config:get-option('iiifImageApi'))) then ()
            else (<br xmlns="http://www.w3.org/1999/xhtml"/>, element xhtml:a {
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
        let $viaf := if($gnd) then () else query:get-viaf($model('doc'))
        let $wikiContent := 
            if($gnd) then er:grabExternalResource('wikipedia', $gnd, config:get-doctype-by-id($model('docID')), $lang)
            else er:grabExternalResource('wikipediaVIAF', $viaf, config:get-doctype-by-id($model('docID')), $lang)
        let $wikiUrl := $wikiContent//xhtml:div[@class eq 'printfooter']/xhtml:a[1]/data(@href)
        let $wikiName := normalize-space($wikiContent//xhtml:h1[@id = 'firstHeading'])
        return 
            map {
                'wikiContent' : $wikiContent,
                'wikiUrl' : $wikiUrl,
                'wikiName' : $wikiName
            }
};


declare 
    %templates:wrap
    %templates:default("lang", "en")
    function app:wikipedia-text($node as node(), $model as map(*), $lang as xs:string) as item()* {
        let $wikiText := wega-util:transform($model('wikiContent')//xhtml:div[@id='bodyContent'], doc(concat($config:xsl-collection-path, '/wikipedia.xsl')), config:get-xsl-params(()))
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
                <a xmlns="http://www.w3.org/1999/xhtml" href='{$model('wikiUrl')}' title='Wikipedia Artikel zu "{$model('wikiName')}"'>{$model('wikiName')}</a>,
                '“ aus der freien Enzyklopädie ',
                <a xmlns="http://www.w3.org/1999/xhtml" href="http://de.wikipedia.org" title="Wikipedia Hauptseite">Wikipedia</a>, 
                ' und steht unter der ',
                <a xmlns="http://www.w3.org/1999/xhtml" href="http://creativecommons.org/licenses/by-sa/3.0/deed.de">CC-BY-SA-Lizenz</a>,
                '. In der Wikipedia findet sich auch die ',
                <a xmlns="http://www.w3.org/1999/xhtml" href="{concat(replace($model('wikiUrl'), 'wiki/', 'w/index.php?title='), '&amp;action=history')}" title='Autoren und Versionsgeschichte des Wikipedia Artikels zu "{$model('wikiName')}"'>Versionsgeschichte mitsamt Autorennamen</a>,
                ' für diesen Artikel.'
            )
            default return (
                'The text under the headline “Wikipedia” is taken from the article “',
                <a xmlns="http://www.w3.org/1999/xhtml" href='{$model('wikiUrl')}' title='Wikipedia article for {$model('wikiName')}'>{$model('wikiName')}</a>,
                '” from ',
                <a xmlns="http://www.w3.org/1999/xhtml" href="http://en.wikipedia.org">Wikipedia</a>,
                ' the free encyclopedia, and is released under a ',
                <a xmlns="http://www.w3.org/1999/xhtml" href="http://creativecommons.org/licenses/by-sa/3.0/deed.en">CC-BY-SA-license</a>,
                '. You will find the ',
                <a xmlns="http://www.w3.org/1999/xhtml" href="{concat(replace($model('wikiUrl'), 'wiki/', 'w/index.php?title='), '&amp;action=history')}" title="Authors and revision history of the Wikipedia Article for {$model('wikiName')}">revision history along with the authors</a>,
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
        let $gnd := query:get-gnd($model?doc)
        return 
            map {
                'adbndbContent' : 
                    if(er:lookup-gnd-from-beaconProvider('ndbBeacon', $gnd)) 
                    then er:grab-external-resource-via-beacon('ndbBeacon', $gnd)
                    else if($gnd and er:lookup-gnd-from-beaconProvider('adbBeacon', $gnd)) 
                    then er:grab-external-resource-via-beacon('adbBeacon', $gnd)
                    else ()
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
        let $dnbContent := er:grabExternalResource('dnb', $gnd, config:get-doctype-by-id($model('docID')), ())
        let $dnbOccupations := ($dnbContent//rdf:RDF/rdf:Description/gndo:professionOrOccupation ! er:resolve-rdf-resource(.))//gndo:preferredNameForTheSubjectHeading/str:normalize-space(.)
        let $subjectHeadings := (($dnbContent//rdf:RDF/rdf:Description/gndo:broaderTermInstantial | $dnbContent//rdf:RDF/rdf:Description/gndo:formOfWorkAndExpression) ! er:resolve-rdf-resource(.))//gndo:preferredNameForTheSubjectHeading/str:normalize-space(.)
        return
            map {
                'docType' : config:get-doctype-by-id($model?docID),
                'dnbContent' : $dnbContent,
                'dnbName' : ($dnbContent//rdf:RDF/rdf:Description/gndo:preferredNameForThePerson/str:normalize-space(.), $dnbContent//rdf:RDF/rdf:Description/gndo:preferredNameForTheCorporateBody/str:normalize-space(.), $dnbContent//rdf:RDF/rdf:Description/gndo:preferredNameForThePlaceOrGeographicName/str:normalize-space(.)),
                'dnbBirths' : 
                    if($dnbContent//gndo:dateOfBirth castable as xs:date) then date:format-date($dnbContent//gndo:dateOfBirth, $config:default-date-picture-string($lang), $lang)
                    else if($dnbContent//gndo:dateOfBirth castable as xs:gYear) then date:formatYear($dnbContent//gndo:dateOfBirth, $lang)
                    else(),
                'dnbDeaths' : 
                    if($dnbContent//gndo:dateOfDeath castable as xs:date) then date:format-date($dnbContent//gndo:dateOfDeath, $config:default-date-picture-string($lang), $lang)
                    else if($dnbContent//gndo:dateOfDeath castable as xs:gYear) then date:formatYear($dnbContent//gndo:dateOfDeath, $lang)
                    else(),
                'dnbOccupations' : 
                    if($dnbContent//rdf:RDF/rdf:Description/gndo:professionOrOccupation or $dnbContent//rdf:RDF/rdf:Description/gndo:professionOrOccupationAsLiteral) then
                        ($dnbOccupations, $dnbContent//rdf:RDF/rdf:Description/gndo:professionOrOccupationAsLiteral/str:normalize-space(.))
                    else (),
                'biographicalOrHistoricalInformations' : $dnbContent//gndo:biographicalOrHistoricalInformation,
                'dnbOtherNames' : (
                    for $name in ($dnbContent//rdf:RDF/rdf:Description/gndo:variantNameForThePerson, $dnbContent//rdf:RDF/rdf:Description/gndo:variantNameForTheCorporateBody, $dnbContent//rdf:RDF/rdf:Description/gndo:variantNameForThePlaceOrGeographicName/str:normalize-space(.))
                    return
                        if(functx:all-whitespace($name)) then ()
                        else str:normalize-space($name)
                ),
                'gndDefinition' : $dnbContent//gndo:definition,
                'lang' : $lang,
                'dnbURL' : config:get-option('dnb') || $gnd,
                'preferredNameForTheWork' : $dnbContent//gndo:preferredNameForTheWork  ! str:normalize-space(.),
                'variantNamesForTheWork' : $dnbContent//gndo:variantNameForTheWork ! str:normalize-space(.),
                'subjectHeadings' : $subjectHeadings
            }
};

(:~
 : Output prettified ('censored') XML
 : This function is called by the AJAX template xml.html 
~:)
declare function app:xml-prettify($node as node(), $model as map(*)) {
        let $docID := $model('docID')
        let $serializationParameters := <output:serialization-parameters><output:method>xml</output:method><output:media-type>application/xml</output:media-type><output:indent>no</output:indent></output:serialization-parameters>
        let $doc :=
        	if(config:get-doctype-by-id($docID)) then crud:doc($docID)
        	else gl:spec($model('exist:path'))
        return
            if($config:isDevelopment) then serialize($doc, $serializationParameters)
            else serialize(wega-util:inject-version-info(wega-util:process-xml-for-display($doc)), $serializationParameters)
};

declare 
    %templates:default("lang", "en")
    function app:person-addrLine($node as node(), $model as map(*), $lang as xs:string) as item()* {
        switch ($model('addrLine')/@n)
        case 'email' return 
            element xhtml:a {
                attribute class {'obfuscate-email'},
                normalize-space($model('addrLine'))
            }
        case 'telephone' return (
            lang:get-language-string('tel',$lang) || ': ',
            element xhtml:a {
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

(:~
 : Add a disclaimer to our "FFFI-Fremddaten"
~:)
declare function app:external-data-disclaimer($node as node(), $model as map(*)) as map(*)? {
    if($model?source = 'WeGA' or $model?docType ne 'persons') then ()
    else
        let $external-data-url := 
            if($model?source = 'Bach') then
                if($model?doc//tei:idno[@type='bd'])
                then 'https://www.bach-digital.de/receive/' || $model?doc//tei:idno[@type='bd']
                else 'https://www.bach-digital.de'
            else ()
        let $external-data-text := 
            switch($model?source) 
            case 'Bach' return 'Bach digital'
            case 'MB' return (<i>Giacomo Meyerbeer. Briefwechsel und Tagebücher</i>, ', Bd. 1 (1960)')
            case 'BGA' return 'der Gesamtausgabe des Beethoven-Briefwechsels (1996–1998)'
            case 'LoB' return (<i>Albert Lortzing. Sämtliche Briefe</i>, ' (1995)')
            case 'SchTb' return 'der Ausgabe der Schumann-Tagebücher, Bd. 1 (1971)'
            case 'SchEnd' return (<i>Robert Schumann in Endenich (1854–1856)</i>, ', hg. von Bernhard R. Appel (2006)')
            case 'HoB' return 'der Edition von E. T. A. Hoffmanns Briefwechsel, hg. von Friedrich Schnapp (1967–1969)'
            case 'Wies' return 'einer CellistInnen-Datenbank von Christiane Wiesenfeldt'
            default return 'Fremddaten'
        return
            map {
                'external-data-url': $external-data-url,
                'external-data-text': $external-data-text
            }
};

declare function app:print-external-data-disclaimer($node as node(), $model as map(*)) as item()* {
    element {node-name($node)} {
        if($model?external-data-url) then attribute href {
            $model?external-data-url
        }
        else (),
        $model?external-data-text
    }
};

(:
 : ****************************
 : Document pages
 : ****************************
:)


declare 
    %templates:wrap
    function app:doc-details($node as node(), $model as map(*)) as map(*) {
        let $facs := query:facsimile($model?doc)
        return
            map {
                'facsimile' : $facs,
                'localFacsimiles' : $facs[tei:graphic][not(@sameAs)] except $facs[tei:graphic[starts-with(@url, 'http')]],
                'externalIIIFManifestFacsimiles' : $facs[@sameAs],
                'hasCreation' : exists($model?doc//tei:creation),
                'xml-download-url' : replace(controller:create-url-for-doc($model('doc'), $model('lang')), '\.html', '.xml'),
                'thematicCommentaries' : distinct-values($model('doc')//tei:note[@type='thematicCom']/@target/tokenize(., '\s+')),
                'backlinks' : wdt:backlinks(())('filter-by-person')($model?docID)
            }
};

declare
    %templates:wrap
    function app:document-title($node as node(), $model as map(*)) as item()* {
        let $docID := $model('doc')/*/data(@xml:id) (: need to check because of index.html :)
        let $title := wdt:lookup(config:get-doctype-by-id($docID), $model('doc'))?title('html') 
        return
            if($title instance of xs:string) then $title
            else $title/node()
};

declare 
    %templates:wrap
    function app:prepare-text($node as node(), $model as map(*)) as map(*) {
        let $doc := $model('doc')
        let $docID := $model('docID')
        let $lang := $model('lang')
        let $docType := $model('docType')
        let $xslParams := config:get-xsl-params( map {
            'dbPath' : document-uri($doc),
            'docID' : $docID,
            'transcript' : 'true',
            'createSecNos' : if($docID = ('A070010', 'A070001')) then 'true' else ()
            } )
        let $xslt1 := 
            switch($docType)
            case 'letters' return doc(concat($config:xsl-collection-path, '/letters.xsl'))
            case 'works' return doc(concat($config:xsl-collection-path, '/works.xsl'))
            case 'writings' case 'documents' return doc(concat($config:xsl-collection-path, '/document.xsl'))
            case 'diaries' return doc(concat($config:xsl-collection-path, '/diaries.xsl'))
            default  return doc(concat($config:xsl-collection-path, '/var.xsl'))
        let $textRoot :=
            switch($docType)
            case 'diaries' return $doc/tei:ab ! app:inject-query(.)
            case 'works' return $doc/mei:mei ! app:inject-query(.)
            case 'var' case 'addenda' return ($doc//tei:text/tei:body ! app:inject-query(.))/(tei:div[@xml:lang=$lang] | tei:divGen | tei:div[not(@xml:lang)])
            case 'thematicCommentaries' return $doc//tei:text/tei:body ! app:inject-query(.) | $doc//tei:text/tei:back
            default return $doc//tei:text/tei:body ! app:inject-query(.)
        let $body := 
             if(functx:all-whitespace(<root>{$textRoot}</root>))
             then 
                element xhtml:p {
                        attribute class {'notAvailable'},
                        (: revealed correspondence which has backlinks gets a direct link to the backlinks, see https://github.com/Edirom/WeGA-WebApp/issues/304 :)
                        if($doc//tei:correspDesc[@n = 'revealed'] and $model('backlinks')) then (
                            substring-before(lang:get-language-string('correspondenceTextNotAvailable', $lang),"."), ' ',
                            <span xmlns="http://www.w3.org/1999/xhtml">({lang:get-language-string('see', $lang)}</span>, ' ',
                            <span xmlns="http://www.w3.org/1999/xhtml"><a href="#backlinks">{lang:get-language-string('backlinks', $lang)}</a>).</span>, ' ',
                            substring-after(lang:get-language-string('correspondenceTextNotAvailable',$lang),".") )
                        (: … for revealed correspondence without backlinks drop that link :)
                        else if($doc//tei:correspDesc[@n = 'revealed']) then lang:get-language-string('correspondenceTextNotAvailable',$lang)
                        (: all other empty texts :)
                        else lang:get-language-string('correspondenceTextNotYetAvailable', $lang),
                        (: adding link to editorial :)
                        lang:get-language-string('forFurtherDetailsSee', $lang), ' ',
                        <a xmlns="http://www.w3.org/1999/xhtml" href="#editorial">{lang:get-language-string('editorial', $lang)}</a>, '.'
                }
             else (
                wega-util:transform($textRoot, $xslt1, $xslParams)
            )
         let $foot := 
            if(config:is-news($docID)) then app:get-news-foot($doc, $lang)
            else ()
         
         return 
            map { 
                'transcription' : (wega-util:remove-elements-by-class($body, 'apparatus'),$foot), 
                'apparatus' : $body/descendant-or-self::*[@class='apparatus']
            }
};

(:~
 : Search and highlight query strings in a document
 : Helper function for app:prepare-text()
 :
 : @param $input must be node() that is indexed by Lucene
 : @return if a hit was found in $input, an expanded copy of the $input with exist:match elements wrapping the hits. 
 :      If no hit was found, the initial $input is returned
 :)
declare %private function app:inject-query($input as node()) {
    let $q := request:get-parameter('q', '')
    return 
        if($q) then
            let $sanitized-query-string := str:strip-diacritics(str:normalize-space(str:sanitize(string-join($q, ' '))))
            let $query := search:create-lucene-query-element($sanitized-query-string)
            let $result := ft:query($input, $query) 
            return
                if($result) then $result ! kwic:expand(.)
                else $input
        else $input
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
        for $respStmt in $model?respStmts
        return (
            <dt xmlns="http://www.w3.org/1999/xhtml">{str:normalize-space($respStmt/tei:resp)}</dt>,
            <dd xmlns="http://www.w3.org/1999/xhtml">{str:normalize-space(string-join($respStmt/tei:name, '; '))}</dd>
        )
};

declare 
    %templates:wrap
    function app:textSources($node as node(), $model as map(*)) as map(*) {
    let $textSources := query:text-sources($model?doc)
    let $textSourcesCount := count($textSources)
    return
        map {
            'textSources' : $textSources | $textSources/tei:msFrag,
            'textSourcesCountString' : if($textSourcesCount > 1) then concat("in ", $textSourcesCount, " ", lang:get-language-string("textSources",$model('lang'))) else ""
        }
};


declare 
    %templates:wrap
    %templates:default("lang", "en")
    function app:print-Source($node as node(), $model as map(*), $key as xs:string) as map(*)* {
        let $witOrFragPreceding := $model($key)/parent::tei:witness/preceding-sibling::tei:witness | $model($key)/self::tei:msFrag/preceding-sibling::tei:msFrag
        let $titlePrefix := if($model($key)/self::tei:msFrag or $model($key)/parent::tei:witness) then string(count($witOrFragPreceding) + 1) || '.' else ''
        let $title := if($model($key)/self::tei:msFrag) then 'fragment' else 'textSource'
        let $sourceLink-content :=
            typeswitch($model($key))
                case element(tei:msFrag) return wega-util:transform($model($key)/tei:msIdentifier, doc(concat($config:xsl-collection-path, '/editorial.xsl')), config:get-xsl-params(()))
                case element(tei:msDesc) return wega-util:transform($model($key)/tei:msIdentifier, doc(concat($config:xsl-collection-path, '/editorial.xsl')), config:get-xsl-params(()))
                case element(tei:biblStruct) return bibl:printCitation($model($key), <xhtml:span class="biblio-entry"/>, $model('lang'))
                case element(tei:bibl) return 
                    let $processed := wega-util:transform($model($key), doc(concat($config:xsl-collection-path, '/document.xsl')), config:get-xsl-params(()))
                    return if ($processed instance of xs:string+) then <span xmlns="http://www.w3.org/1999/xhtml">{$processed}</span>
                    else $processed
                default return <span xmlns="http://www.w3.org/1999/xhtml" class="noDataFound">{lang:get-language-string('noDataFound',$model('lang'))}</span>
        let $sourceCategory := if($model($key)/@rend) then lang:get-language-string($model($key)/@rend,$model('lang')) else ()
        let $sourceData-content :=
            typeswitch($model($key))
                case element(tei:msFrag) return wega-util:transform($model($key)/tei:*[not(self::tei:msIdentifier)], doc(concat($config:xsl-collection-path, '/editorial.xsl')), config:get-xsl-params(()))
                case element(tei:msDesc) return wega-util:transform($model($key)/tei:*[not(self::tei:msIdentifier or self::tei:msFrag)], doc(concat($config:xsl-collection-path, '/editorial.xsl')), config:get-xsl-params(()))
                default return ()
        let $source-id := concat("source_",util:hash(generate-id($model($key)),'md5'))
        let $collapse := exists($sourceData-content) or exists($model($key)/tei:additional) or exists($model($key)/tei:relatedItem)
        return
            map {
                'title' : $titlePrefix || ' ' || lang:get-language-string($title,$model?lang),
                'collapse' : $collapse,
                'sourceLink' : concat("#",$source-id),
                'sourceId' : $source-id,
                'sourceLink-content' : $sourceLink-content,
                'sourceData-content' : $sourceData-content,
                'sourceCategory' : $sourceCategory
            }
};

declare 
    %templates:wrap
    function app:additionalSources($node as node(), $model as map(*)) as map(*) {
        (: tei:msDesc, tei:bibl, tei:biblStruct als mögliche Kindelemente von tei:additional/tei:listBibl :)
        map {
            'additionalSources' : $model('textSource')/tei:additional/tei:listBibl/tei:* | $model('textSource')/tei:relatedItem/tei:*[not(./self::tei:listBibl)] | $model('textSource')/tei:relatedItem/tei:listBibl/tei:* 
        }
};


(:~
 : Fetch all (external) facsimiles for a text source
 :)
declare 
    %templates:wrap
    function app:externalImageURLs($node as node(), $model as map(*)) as map(*) {
        map {
            (: intersect with $model?facsimile to only get allowed facsimiles :)
            'externalImageURLs' : (query:witness-facsimile($model?textSource) intersect $model?facsimile)/tei:graphic[starts-with(@url, 'http')]/data(@url) 
        }
};

(:~
 : Outputs the summary information of a TEI document
 :
:)
declare 
    %templates:default("lang", "en")
    function app:print-summary($node as node(), $model as map(*), $lang as xs:string) as element()* {
        let $revealedNote := 
            if($model('doc')//tei:correspDesc[@n = 'revealed']) then lang:get-language-string('correspondenceTextNotAvailable', $lang)
            else ()
        let $summary := 
            if(query:summary($model('doc'), $lang)) then wega-util:transform(query:summary($model('doc'), $lang), doc(concat($config:xsl-collection-path, '/editorial.xsl')), config:get-xsl-params(()))
            else '–'
        return (
            if(exists($summary) and (every $i in $summary satisfies $i instance of element())) then $summary
            else if($summary = '–' and $revealedNote) then <div xmlns="http://www.w3.org/1999/xhtml"><p>{$revealedNote}</p></div>
            else if($summary = '–' and $node/ancestor-or-self::xhtml:div[@data-template="app:preview"]) then ()
            else <div xmlns="http://www.w3.org/1999/xhtml"><p>{$summary}</p></div>
        )
};

(:~
 : surround HTML fragment with quotation marks  
 :
 : @param $items the HTML fragments (or strings) to enquote
 : @param $lang the language switch (en, de)
 :)
declare %private function app:enquote-html($items as item()*, $lang as xs:string) as item()*  {
    let $enquotedDummy := str:enquote('dummy', $lang)
    return (
        <xhtml:span class="marks_supplied">{substring-before($enquotedDummy, 'dummy')}</xhtml:span>,
        $items,
        <xhtml:span class="marks_supplied">{substring-after($enquotedDummy, 'dummy')}</xhtml:span>
    ) 
};

declare 
    %templates:default("lang", "en")
    %templates:default("generate", "false")
    function app:print-incipit($node as node(), $model as map(*), $lang as xs:string, $generate as xs:string) as element(xhtml:p)* {
        let $incipit := wega-util:transform(query:incipit($model('doc')), doc(concat($config:xsl-collection-path, '/editorial.xsl')), config:get-xsl-params(()))
        return 
            if(exists($incipit) and (every $i in $incipit satisfies $i instance of element())) then $incipit ! element xhtml:p { app:enquote-html(./xhtml:p/node(), $lang) }
            else element xhtml:p {
                if(exists($incipit)) then app:enquote-html($incipit, $lang)
                else if(wega-util-shared:semantic-boolean($generate) and not(functx:all-whitespace($model('doc')//tei:text/tei:body))) then app:enquote-html(app:compute-incipit($model?doc, $lang), $lang)
                else '–'
            }
};

(:~
 :  Compute the incipit for a text 
 :  Helper function for app:print-incipit()
 :
 :  Incipits for letters shall not be taken from the address or the opener, but only from the letter text (proper)
 :  The current implementation is more or less a stub and can be expanded …
 :
 :  @param $doc the TEI document to compute the incipit from
 :  @param $lang the current language (de|en)
 :)
declare %private function app:compute-incipit($doc as document-node(), $lang as xs:string) as xs:string? {
    let $myTextNodes := $doc//tei:text/tei:body/tei:div[not(@type='address')]/(* except tei:dateline except tei:opener except tei:head | text())
    return
        if(string-length(normalize-space(string-join($myTextNodes, ' '))) gt 20) then str:shorten-TEI($myTextNodes, 80, $lang)
        else str:shorten-TEI($doc//tei:text/tei:body, 80, $lang)
};

declare 
    %templates:default("lang", "en")
    function app:print-generalRemark($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:p)* {
        let $generalRemark := wega-util:transform(query:generalRemark($model('doc')), doc(concat($config:xsl-collection-path, '/editorial.xsl')), config:get-xsl-params(()))
        return 
            if(exists($generalRemark) and (every $i in $generalRemark satisfies $i instance of element())) then $generalRemark
            else element xhtml:p {
                if(exists($generalRemark)) then $generalRemark
                else '–'
            }
};

declare 
    %templates:default("lang", "en")
    function app:print-thematicCom($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:p)* {
        let $thematicCom := crud:doc(substring-after($model('thematicCom'), 'wega:'))
        return
            element { node-name($node) } {
                attribute href { controller:create-url-for-doc($thematicCom, $lang) },
                wdt:thematicCommentaries($thematicCom)('title')('html')
            }
};

declare 
    %templates:default("lang", "en")
    %templates:wrap
    function app:print-creation($node as node(), $model as map(*), $lang as xs:string) as item()* {
        if($model?hasCreation and $model('result-page-entry')) then wega-util:txtFromTEI($model('doc')//tei:creation)
        else if($model?hasCreation) then wega-util:transform($model('doc')//tei:creation, doc(concat($config:xsl-collection-path, '/editorial.xsl')), config:get-xsl-params(()))
        else '–'
};


declare
    %templates:default("lang", "en")
    %templates:wrap
    function app:check-apparatus($node as node(), $model as map(*), $lang as xs:string) as map(*) {
        map {
            'incipit' : query:incipit($model('doc')),
            'summary' : query:summary($model('doc'), $lang),
            'generalRemark' : query:generalRemark($model('doc')),
            'authors' : if (count(query:get-author-element($model('doc'))) > 1 ) then
                for $author in query:get-author-element($model('doc')) return app:printCorrespondentName($author,$lang,'fs') else (),
            'respStmts': 
                switch($model('docType'))
                case 'diaries' return <tei:respStmt><tei:resp>Übertragung</tei:resp><tei:name>Dagmar Beck</tei:name></tei:respStmt>
                default return $model('doc')//tei:respStmt[parent::tei:titleStmt]
        }
};


(:~
 : Add context information to the current model map
 : NB: If no context information is found, an empty sequence will be returned
 : effectively removing the HTML subtree under $node from the output.
 :)
declare 
    %templates:wrap
    function app:context($node as node(), $model as map(*)) as map(*)? {
        let $senderID := tokenize($model?('exist:path'), '/')[3]
        let $context := 
            switch($model?docType)
            case 'letters' return map:merge((
                query:context-relatedItems($model?doc), 
                query:correspContext($model?doc, $senderID)
            ))
            default return query:context-relatedItems($model?doc)
        return
            if(wega-util-shared:has-content($context)) 
            then map:merge(($context, map:entry('senderID', $senderID)))
            else ()
};

declare 
    %templates:default("lang", "en")
    function app:print-letter-context($node as node(), $model as map(*), $lang as xs:string) as item()* {
        let $letter := $model('letter-norm-entry')('doc')
        let $partner := 
            switch($model('letter-norm-entry')('fromTo')) 
            (: There may be multiple addressees or senders! :)
            case 'from' return ($letter//tei:correspAction[@type='sent']/tei:*[self::tei:persName or self::tei:orgName or self::tei:name])[1]
            case 'to' return ($letter//tei:correspAction[@type='received']/tei:*[self::tei:persName or self::tei:orgName or self::tei:name])[1]
            default return wega-util:log-to-file('error', 'app:print-letter-context(): wrong value for parameter &quot;fromTo&quot;: &quot;' || $model('letter-norm-entry')('fromTo') || '&quot;')
        let $normDate := query:get-normalized-date($letter)
        return (
            element xhtml:a {
                attribute href {controller:create-url-for-doc-in-context($letter, $lang, $model?senderID)},
                $normDate
            },
            ": ",
            lower-case(lang:get-language-string($model('letter-norm-entry')('fromTo'), $lang)),
            " ",
            app:printCorrespondentName($partner, $lang, 's')
        )
};

declare 
    %templates:default("lang", "en")
    function app:print-context-relatedItem($node as node(), $model as map(*), $lang as xs:string) as item()* {
        if($model?context-relatedItem?context-relatedItem-doc) 
        then app:createDocLink($model?context-relatedItem?context-relatedItem-doc, wdt:lookup(config:get-doctype-by-id($model?context-relatedItem?context-relatedItem-doc/*/data(@xml:id)), $model?context-relatedItem?context-relatedItem-doc)?title('txt'), $lang, ())
        else wega-util:log-to-file('warn', 'unable to process related items for ' || $model?docID)
};

declare 
    %templates:default("lang", "en")
    %templates:wrap
    function app:print-context-relatedItem-type($node as node(), $model as map(*), $lang as xs:string) as xs:string? {
        lang:get-language-string($model?context-relatedItem?context-relatedItem-type, $lang)
};

(:~
 : Create csLink element (see https://github.com/correspSearch/csLink for options)
 : wip!
 : @author Jakob Schmidt
 :)
declare 
    %templates:default("lang", "en")
    function app:csLink($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:div) {        
        let $doc := $model('doc')
        let $correspondent-1-key := tokenize($model?('exist:path'), '/')[3]
        let $correspondent-1-gnd := query:get-gnd($correspondent-1-key)
        let $correspondent-2-key := ($doc//tei:correspAction[@type = 'received']//@key[parent::tei:persName or parent::name or parent::tei:orgName])[1]
        let $correspondent-2-gnd := query:get-gnd($correspondent-2-key)
        let $gnd-uri := config:get-option("dnb") (: 'https://d-nb.info/gnd/' :)        
        (: Element-Parameter :)
        let $data-correspondent-1-id := if ($correspondent-1-gnd) then concat($gnd-uri,$correspondent-1-gnd) else ""
        let $data-correspondent-1-name :=
            (:if ($data-correspondent-1-id) then "" else:) 
            if ($correspondent-1-key) then query:title($correspondent-1-key) else ""
        let $data-correspondent-2-id := if ($correspondent-2-gnd) then concat($gnd-uri,$correspondent-2-gnd) else ""
        let $data-correspondent-2-name :=
            (:if ($data-correspondent-2-id) then "" else :)
            if ($correspondent-2-key) then query:title($correspondent-2-key) else ""
        let $data-start-date := query:get-normalized-date($doc)        
        return
            element { node-name($node) } {
            attribute id {"csLink"}, (: mandatory :)
            attribute data-correspondent-1-id {$data-correspondent-1-id},
            attribute data-correspondent-1-name {$data-correspondent-1-name},            
            attribute data-correspondent-2-id {$data-correspondent-2-id},
            attribute data-correspondent-2-name {$data-correspondent-2-name},           
            attribute data-start-date { $data-start-date},
            attribute data-end-date {$data-start-date},
            attribute data-range {"30"},
            attribute data-selection-when {"before-after"},
            attribute data-selection-span {"median-before-after"},
            attribute data-result-max {"4"},
            attribute data-exclude-edition {"#WEGA"}            
}
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
declare %private function app:get-news-foot($doc as document-node(), $lang as xs:string) as element(xhtml:p)? {
    let $authorElem := query:get-author-element($doc)
    let $dateFormat := 
        if ($lang = 'de') then '[FNn], [D]. [MNn] [Y]'
                          else '[FNn], [MNn] [D], [Y]'
    return 
        if(count($authorElem) gt 0) then 
            element xhtml:p {
                attribute class {'authorDate'},
                app:printCorrespondentName($authorElem, $lang, 'fs'),
                concat(', ', date:format-date(xs:date($doc//tei:publicationStmt/tei:date/xs:dateTime(@when)), $dateFormat, $lang))
            }
        else()
};

(:~
 : Initialize rendering of the facsimile (if available) on document pages 
 : by writing a whitespace separated list of IIIF manifest URLs to the `@data-url` attribute
 : for a client side renderer. 
 :)
declare function app:init-facsimile($node as node(), $model as map(*)) as element(xhtml:div) {
    element {node-name($node)} {
        $node/@*[not(name()=('data-originalMaxSize', 'data-url'))],
        if(count($model?localFacsimiles | $model?externalIIIFManifestFacsimiles) gt 0) then (
            attribute {'data-url'} { normalize-space(
                string-join($model?externalIIIFManifestFacsimiles/@sameAs, ' ') ||
                ' ' ||
                string-join(($model?localFacsimiles except $model?externalIIIFManifestFacsimiles) ! controller:iiif-manifest-id(.), ' ') 
            )}
        )
        else ()
    }
};


(:
 : ****************************
 : Searches
 : ****************************
:)


(:~
 : Write the sanitized query string into the search text input for reuse
 : and set the placeholder text for initial search box.
 : To be called from an HTML template.
~:)
declare
%templates:default("lang", "en")
    function app:search-input($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:input)* {
    let $placeholder := lang:get-language-string("searchTerm",$lang)
    return
    element {node-name($node)} {
        $node/@*[not(name(.) = ('value', 'placeholder'))],
        if($model('query-string-org') ne '') then attribute {'value'} {$model('query-string-org')}
        else (),
        attribute placeholder {$placeholder}
    }
};

declare 
    %templates:default("lang", "en")
    function app:search-filter($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:label)* {
        let $selected-docTypes := request:get-parameter('d', ()) 
        return 
            for $docType in $search:wega-docTypes
            let $class := 
                if(($docType, 'all') = $selected-docTypes or empty($selected-docTypes)) then normalize-space($node/@class) || ' active'
                else normalize-space($node/@class)
            let $displayTitle := lang:get-language-string($docType, $lang)
            order by $displayTitle
            return                
             element {node-name($node)} {
                 $node/@*[not(name(.) = 'class')],
                 attribute class {$class},
                 element input {
                     $node/xhtml:input/@*[not(name(.) = 'value')],
                     attribute value {$docType},
                     if(($docType, 'all') = $selected-docTypes or empty($selected-docTypes)) then attribute checked {'checked'}
                     else ()
                 },
                 <span xmlns="http://www.w3.org/1999/xhtml">{$displayTitle}</span>,
                 <a xmlns="http://www.w3.org/1999/xhtml" href="#" class="checkbox-only">{lang:get-language-string("only",$lang)}</a>
             }
};

(:~
 : Overwrites the current model with 'doc' and 'docID' of the preview document
 :
 :)
declare
    %templates:wrap
    %templates:default("lang", "en")
    function app:preview($node as node(), $model as map(*), $lang as xs:string) as map(*) {
        map {
            'doc' : $model('result-page-entry'),
            'docID' : $model('result-page-entry')/root()/*/data(@xml:id),
            'docURL' : 
                if(config:is-person($model?parent-docID)) then controller:create-url-for-doc-in-context($model?result-page-entry, $lang, $model?parent-docID)
                else controller:create-url-for-doc($model('result-page-entry'), $lang),
            'docType' : config:get-doctype-by-id($model('result-page-entry')/root()/*/data(@xml:id)),
            'relators' : query:relators($model('result-page-entry')),
            'biblioType' : $model('result-page-entry')/tei:biblStruct/data(@type),
            'workType' : $model('result-page-entry')//mei:term/data(@class),
            'newsDate' : date:printDate($model('result-page-entry')//tei:date[parent::tei:publicationStmt], $lang, lang:get-language-string#3, $config:default-date-picture-string)
        }
};

declare
    %templates:wrap
    function app:preview-details($node as node(), $model as map(*)) as map(*) {
        map {
            'hasCreation' : exists($model('doc')//tei:creation),
            'summary' : app:print-summary($node, $model, $model?lang) => string-join('; ') => str:normalize-space()
        }
};

declare 
    %templates:default("lang", "en")
    function app:preview-title($node as node(), $model as map(*), $lang as xs:string) as element() {
        let $title := wdt:lookup(config:get-doctype-by-id($model('docID')), $model('doc'))?title('html')
        return
            element {node-name($node)} {
                $node/@*[not(name(.) = 'href')],
                if($node[self::xhtml:a])
                then attribute href {
                    $model?docURL || (
                        if(map:contains($model, 'query-string-org'))
                        then ('?q=' || string-join(($model?query-string-org, $model?query-docTypes), '&amp;d=')) 
                        else ()
                )}
                else (),
                if($title instance of xs:string or $title instance of text() or count($title) gt 1) 
                then $title
                else $title/node()
            }
};

declare 
    %templates:default("lang", "en")
    function app:preview-incipit($node as node(), $model as map(*), $lang as xs:string) as xs:string {
        app:print-incipit($node, $model, $lang, 'true') ! str:normalize-space(.)  => string-join('; ')
};

declare 
    %templates:default("lang", "en")
    function app:preview-citation($node as node(), $model as map(*), $lang as xs:string) as element(xhtml:p)? {
        let $source := query:get-main-source($model('doc'))
        return 
            typeswitch($source)
            case element(tei:biblStruct) return 
                element {node-name($node)} {
                    $node/@*,
                    bibl:printCitation($source, <xhtml:p/>, $lang)/node()
                }
            default return ()
};

declare 
    %templates:wrap
    %templates:default("max", "200")
    function app:preview-teaser($node as node(), $model as map(*), $max as xs:string) as xs:string {
        let $textXML := $model('doc')/tei:ab | $model('doc')//tei:body | $model('doc')//mei:annot[@type='Kurzbeschreibung'] (: letzter Fall für sources :)
        return
            str:shorten-TEI($textXML, number($max), $model?lang)
};


declare 
    %templates:default("lang", "en")
    function app:preview-opus-no($node as node(), $model as map(*), $lang as xs:string) as element()? {
        if(count($model('doc')//mei:altId[not(@type=('gnd', 'wikidata', 'dracor.einakter'))]) gt 0) then 
            element {node-name($node)} {
                $node/@*[not(name(.) = 'href')],
                if($node[self::xhtml:a]) then attribute href {controller:create-url-for-doc($model('doc'), $lang)}
                else (),
                if(exists($model('doc')//mei:altId[@type='WeV'])) then concat('(WeV ', $model('doc')//mei:altId[@type='WeV'], ')') (: Weber-Werke :)
                else concat('(', $model('doc')//(mei:altId[not(@type=('gnd', 'wikidata', 'dracor.einakter'))])[1]/string(@type), ' ', $model('doc')//(mei:altId[not(@type=('gnd', 'wikidata', 'dracor.einakter'))])[1], ')') (: Fremd-Werke :)
            }
        else()
};

declare 
    %templates:default("lang", "en")
    function app:preview-subtitle($node as node(), $model as map(*), $lang as xs:string) as element()? {
        let $main-title := ($model?doc//mei:meiHead/mei:fileDesc/mei:titleStmt/mei:title[not(@type=('sub', 'alt'))])[1]
        let $sub-titles := $model?doc//mei:fileDesc/mei:titleStmt/mei:title[@type = 'sub'][string(@xml:lang) = $main-title/string(@xml:lang)]
        return 
            if($sub-titles) then
                element {node-name($node)} {
                    $node/@*,
                    data(
                        (: output the first matching subtitle :)
                        $sub-titles[1]
                    )
                }
            else ()
};


declare 
    %templates:wrap
    %templates:default("lang", "en")
    function app:preview-relator-role($node as node(), $model as map(*), $lang as xs:string) as xs:string? {
        if($model('relator')/self::mei:*/@role) then lang:get-language-string($model('relator')/data(@role), $lang)
        else if($model('relator')/self::tei:author) then lang:get-language-string('aut', $lang)
        else wega-util:log-to-file('warn', 'app:preview-relator-role(): Failed to reckognize role')
};

declare 
    %templates:wrap
    %templates:default("lang", "en")
    function app:preview-creation($node as node(), $model as map(*), $lang as xs:string) as xs:string? {
        if($model('doc')/mei:manifestation/mei:pubStmt) then string-join($model('doc')/mei:manifestation/mei:pubStmt/*, ', ')
        else if($model('doc')/mei:manifestation/mei:creation) then str:normalize-space($model('doc')/mei:manifestation/mei:creation)
        else ()
};


declare 
    %templates:default("lang", "en")
    %templates:default("popover", "false")
    function app:preview-relator-name($node as node(), $model as map(*), $lang as xs:string, $popover as xs:string) as element() {
        let $key := $model('relator')/@codedval | $model('relator')/@key
        let $myPopover := wega-util-shared:semantic-boolean($popover)
        return
            if($key and $myPopover) then app:createDocLink(crud:doc($key), query:title($key), $lang, (), true())
            else element xhtml:span {
                if($key) then wdt:lookup(config:get-doctype-by-id($key), data($key))?title('txt')
                else str:normalize-space($model('relator'))
            }
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
            'bugEmail' : config:get-option('bugEmail') 
        }
};

(:~
 : Inject the @data-api-base attribute at the given node
 :
 : The value is taken from the "openapi" object within $model. 
 : If this key is missing, it defaults to $config:openapi-config-path 
 : (see `config:api-base()`)
 :
 : @author Peter Stadler
 :)
declare function app:inject-api-base($node as node(), $model as map(*))  {
    let $api-base := config:api-base($model?openapi)
    return
        app-shared:set-attr($node, map:merge(($model, map {'api-base' : $api-base})), 'data-api-base', 'api-base')
};
