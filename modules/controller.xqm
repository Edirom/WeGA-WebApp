xquery version "3.0" encoding "UTF-8";

(:~
 : XQuery functions for the main controller
 :)
module namespace controller="http://xquery.weber-gesamtausgabe.de/modules/controller";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace map="http://www.w3.org/2005/xpath-functions/map";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace util="http://exist-db.org/xquery/util";

import module namespace functx="http://www.functx.com";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace crud="http://xquery.weber-gesamtausgabe.de/modules/crud" at "crud.xqm";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util" at "wega-util.xqm";
import module namespace wdt="http://xquery.weber-gesamtausgabe.de/modules/wdt" at "wdt.xqm";
import module namespace gl="http://xquery.weber-gesamtausgabe.de/modules/gl" at "gl.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/str.xqm";


declare variable $controller:projectNav :=
    map {
        'docID': 'A070001',
        'title': 'editorialGuidelines-text'
    },
    map {
        'docID': 'A070002',
        'title': 'about'
    },
    map {
        'docID': 'A070003',
        'title': 'bio'
    },
    map {
        'docID': 'A070004',
        'title': 'faq'
    },
    map {
        'docID': 'A070006',
        'title': 'projectDescription'
    },
    map {
        'docID': 'A070009',
        'title': 'contact'
    },
    map {
        'docID': 'A070010',
        'title': 'editorialGuidelines-music'
    },
    map {
        'docID': 'A070011',
        'title': 'volContents'
    },
    map {
        'docID': 'A070012',
        'title': 'apiDocumentation'
    },
    map {
        'docID': 'A070013',
        'title': 'credits'
    },
    map {
        'docID': 'A070090',
        'title': 'specialVolume'
    };

(:~
 : HTML output. Forwards to a given template and takes care of ETag caching
 :
 : @param $html-template the HTML template for processing by the templating module. The path must be given relative to the app root collection
 : @param $exist-vars the keys of this map object will get passed through to the following modules by sending them as request attributes
~:)
declare function controller:forward-html($html-template as xs:string, $exist-vars as map(*)*) as element(exist:dispatch) {
    let $etag := controller:etag($exist-vars('exist:path'))
    let $modified := not(functx:substring-before-if-contains(request:get-header('If-None-Match'), '--') = $etag)
    return (
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{str:join-path-elements((map:get($exist-vars, 'exist:controller'), $html-template))}"/>
            <view>
                <forward url="{str:join-path-elements((map:get($exist-vars, 'exist:controller'), 'modules/view-html.xql'))}" method="get">
                	{
                	for $var in map:keys($exist-vars) 
                	return
                		<set-attribute name="{$var}" value="{$exist-vars($var)}"/>
                	}
                    <!-- Need to provoke 304 error in view-html.xql if unmodified -->
                    <set-attribute name="modified" value="{$modified cast as xs:string}"/>
                </forward>
                {if($modified) then 
                <forward url="{str:join-path-elements((map:get($exist-vars, 'exist:controller'), 'modules/view-tidy.xql'))}">
                    <set-attribute name="lang" value="{$exist-vars('lang')}"/>
                </forward>
                else ()}
            </view>
            {if($modified) then
            <error-handler>
                <forward url="{str:join-path-elements((map:get($exist-vars, 'exist:controller'), '/templates/error-page.html'))}" method="get">
                	{
                	for $var in map:keys($exist-vars) 
                	return
                		<set-attribute name="{$var}" value="{$exist-vars($var)}"/>
                	}
                </forward>
                <forward url="{str:join-path-elements((map:get($exist-vars, 'exist:controller'), '/modules/view-html.xql'))}">
                	{
                	for $var in map:keys($exist-vars) 
                	return
                		<set-attribute name="{$var}" value="{$exist-vars($var)}"/>
                	}
                </forward>
            </error-handler>
            else ()}
        </dispatch>,
        if(matches($html-template, 'search|register|ajax')) then response:set-header('Cache-Control', 'no-cache')
        else response:set-header('Cache-Control', 'max-age=300,public'),
        response:set-header('ETag', $etag)
    )
};

(:~
 :  XML Output
~:)
declare function controller:forward-xml($exist-vars as map(*)*) as element(exist:dispatch) {
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{map:get($exist-vars, 'exist:controller') || '/modules/view-xml.xql'}">
            {
            for $var in map:keys($exist-vars) 
            return
                <set-attribute name="{$var}" value="{$exist-vars($var)}"/>
            }
        </forward>
    </dispatch>
};

(:~
 :  Plain text output
~:)
declare function controller:forward-txt($exist-vars as map(*)*) as element(exist:dispatch) {
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{map:get($exist-vars, 'exist:controller') || '/modules/view-txt.xql'}">
            {
            for $var in map:keys($exist-vars) 
            return
                <set-attribute name="{$var}" value="{$exist-vars($var)}"/>
            }
        </forward>
    </dispatch>
};

(:~
 :  JSON-LD output
 :)
declare function controller:forward-jsonld($exist-vars as map(*)*) as element(exist:dispatch) {
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{map:get($exist-vars, 'exist:controller') || '/modules/view-jsonld.xql'}">
            {
            for $var in map:keys($exist-vars) 
            return
                <set-attribute name="{$var}" value="{$exist-vars($var)}"/>
            }
        </forward>
    </dispatch>
};

(:~
 : Redirect to given (absolute) path
 : 
 : @author Peter Stadler
 : @param $path the path to redirect to
 : @return exist:dispatch element for controller.xql
 :)
declare function controller:redirect-absolute($path as xs:string) as element(exist:dispatch) {
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{
            config:link-to-current-app($path) || (
            if(request:get-parameter-names() = 'format') then ('?format=' || request:get-parameter('format', ''))
            else ()
            )
        }"/>
    </dispatch>
};

(:~
 : Main entry point for all resources, i.e. documents accessed via WeGA document ID
 :)
declare function controller:dispatch($exist-vars as map(*)) as element(exist:dispatch) {
    let $media-type := controller:media-type($exist-vars)
    let $docID := functx:substring-before-if-contains($exist-vars('exist:resource'), '.')
    let $updated-exist-vars := 
        map:merge((
            $exist-vars, 
            map:entry('docID', $docID),
            map:entry('docType', config:get-doctype-by-id($docID)),
            map:entry('media-type', $media-type)
        ))
    let $doc := crud:doc($docID)
    let $path := controller:path-to-resource($doc, $exist-vars('lang')) ! controller:encode-path-segments-for-uri(.)
(:    let $log := util:log-system-out($exist-vars('exist:path')):)
(:    let $log := util:log-system-out($path):)
    return 
        if($media-type and $exist-vars('exist:path') = ($path ! (. || '.' || $media-type))) then controller:forward-document($updated-exist-vars)
        else if($media-type and count($path) gt 0) then controller:redirect-absolute('/' || $path[1] || '.' || $media-type)
        (: last else case: document does not exist :)
        else controller:error(map:put($updated-exist-vars, 'error-message', 'resource not found'), 404)
};

(:~
 : Dispatch pages for tab "Indices"
 :)
declare function controller:dispatch-register($exist-vars as map(*)) as element(exist:dispatch) {
    let $indexDocTypes := for $func in wdt:members('indices') return $func(())('name') (: = all supported docTypes :)
    let $docType := 
        if($exist-vars('exist:resource')) then lang:reverse-language-string-lookup(controller:url-decode($exist-vars('exist:resource')), $exist-vars('lang'))[. = ($indexDocTypes, 'indices')]
        else 'indices'
    let $path := 
        if($docType) then controller:encode-path-segments-for-uri(controller:path-to-register($docType, $exist-vars('lang')))
        else ()
    let $updated-exist-vars := 
        map:merge((
            $exist-vars, 
            map:entry('docID', 'indices'),
            map:entry('docType', $docType)
        ))
    return 
        if($exist-vars('exist:path') eq $path) then controller:forward-html('/templates/register.html', $updated-exist-vars)
        else controller:error($exist-vars, 404)
};

(:~
 : Dispatch pages for tab "Project"
 :)
declare function controller:dispatch-project($exist-vars as map(*)) as element(exist:dispatch) {
    let $project-nav := doc(concat($config:app-root, '/templates/page.html'))//(xhtml:li[@id='project-nav']//xhtml:a | xhtml:ul[@class='footerNav']//xhtml:a) 
    let $request := request:get-uri()
    let $a := distinct-values($project-nav/@href[controller:encode-path-segments-for-uri(controller:resolve-link(.,$exist-vars)) = $request]/parent::*)
    return
        if($a = ('bibliography', 'news')) then controller:dispatch-register($exist-vars)
        (: Need to inject the corresponding IDs of special pages here :)
        else if($a = $controller:projectNav?title) then controller:forward-html('/templates/var.html', map:merge(($exist-vars, map:entry('docID', $controller:projectNav[?title=$a]?docID), map:entry('docType', 'var'))))
        else controller:error($exist-vars, 404)
};

(:~
 : Dispatch pages for tab "Help"
 :)
declare function controller:dispatch-help($exist-vars as map(*)) as element(exist:dispatch) {
    let $help-nav := doc(concat($config:app-root, '/templates/page.html'))//(xhtml:li[@id='help-nav']//xhtml:a | xhtml:ul[@class='footerNav']//xhtml:a) 
    let $request := request:get-uri()
    let $a := distinct-values($help-nav/@href[controller:encode-path-segments-for-uri(controller:resolve-link(.,$exist-vars)) = $request]/parent::*)
    return
        switch($a)
        (: Need to inject the corresponding IDs of special pages here :)
        case 'faq' case 'apiDocumentation' return controller:forward-html('/templates/var.html', map:merge(($exist-vars, map:entry('docID', $controller:projectNav[?title=$a]?docID), map:entry('docType', 'var'))))
        default return controller:error($exist-vars, 404)
};

(:~
 : Dispatch pages under "editorial guidelines text"
 :
 : Virtual directory structure for Guidelines:
 : |- project/editorialGuidelines-text
 :		|- index.html
 :		|- chap-DT.html
 :      |- Elements
 :          |- Index
 :          |- wegaLetters
 :              |- ref-ab.html
 :		    	|- ref-p.html
~:)
declare function controller:dispatch-editorialGuidelines-text($exist-vars as map(*)) as element(exist:dispatch)? {
    let $media-type := controller:media-type($exist-vars)
	let $subPathTokens := tokenize(substring-after($exist-vars('exist:path'), replace(lang:get-language-string('editorialGuidelines-text', $exist-vars?lang), '\s+', '_')), '/')[.]
	let $schemaID := 
	   if(request:get-parameter('schemaID', ()) = gl:schemaSpec-idents()) then request:get-parameter('schemaID', ())
	   else $gl:main-source//tei:schemaSpec/data(@ident)
	return
	(: count=1: index and chapters, the direct children of editorialGuidelines-text :)
	   if( (: xml :)
	       count($subPathTokens) eq 1 
	       and $media-type='xml' 
	       and controller:basename($exist-vars('exist:resource')) = gl:chapter-idents()
	       ) then controller:forward-xml(map:merge(($exist-vars, map {'chapID' : controller:basename($exist-vars('exist:resource')) } )))
       else if( (: Index :)
	       count($subPathTokens) eq 1 
	       and $exist-vars('exist:resource') = 'Index'
	       ) then controller:forward-html('templates/guidelines-toc.html', map:merge(($exist-vars, map {'chapID' : 'toc' } )))
       else if( (: redirect for index.html etc. :)
	       count($subPathTokens) eq 1 
	       and matches($exist-vars('exist:resource'), '[Ii]ndex\.html?')
	       ) then controller:redirect-absolute(str:join-path-elements((substring-before($exist-vars('exist:path'), $exist-vars('exist:resource')), 'Index')))
	   else if( (: html :)
	       count($subPathTokens) eq 1 
	       and $media-type='html' 
	       and controller:basename($exist-vars('exist:resource')) = gl:chapter-idents()
	       ) then controller:forward-html('templates/guidelines-chapters.html', map:merge(($exist-vars, map {'chapID' : controller:basename($exist-vars('exist:resource')) } )))
       else if( (: Redirects für htm o.ä. :)
           count($subPathTokens) eq 1 
           and $media-type 
           and controller:basename($exist-vars('exist:resource')) = (gl:chapter-idents())
           ) then controller:redirect-absolute(str:join-path-elements((substring-before($exist-vars('exist:path'), $exist-vars('exist:resource')), controller:basename($exist-vars('exist:resource')))) || '.' || $media-type)
	   
   (: count=2: elements, classes and other specs :)
	   else if(
	       count($subPathTokens) eq 2
	       and substring-after(controller:basename($exist-vars('exist:resource')), 'ref-') = gl:spec-idents($schemaID, lang:reverse-language-string-lookup($subPathTokens[1], $exist-vars?lang))
	       ) then controller:dispatch-editorialGuidelines-text-specs(map:merge(($exist-vars, map { 'specID' : substring-after(controller:basename($exist-vars('exist:resource')), 'ref-'), 'schemaID' : $schemaID, 'media-type' : $media-type } )))
	   else if(
	       $subPathTokens[1] = (lang:get-language-string('elements', $exist-vars?lang), lang:get-language-string('attributes', $exist-vars?lang), lang:get-language-string('classes', $exist-vars?lang))
	       and $exist-vars('exist:resource') = 'Index'
	       ) then controller:forward-html('templates/guidelines-spec-index.html', map:merge(($exist-vars, map {'chapID' : 'index-' || lang:reverse-language-string-lookup($subPathTokens[1], $exist-vars?lang), 'schemaID' : $schemaID } )))
	   
   (: resorting to the error page if all of the above tests fail :)
	   else controller:error($exist-vars, 404)
};

(:~
 : Dispatch pages for the specs of the "editorial guidelines text"
~:)
declare %private function controller:dispatch-editorialGuidelines-text-specs($exist-vars as map(*)) as element(exist:dispatch) {
    if($exist-vars('media-type') = 'html') then controller:forward-html('/templates/guidelines-specs.html', $exist-vars)
	else if ($exist-vars('media-type') = 'xml') then controller:forward-xml($exist-vars)
	else if($exist-vars('media-type')) then controller:redirect-absolute(str:join-path-elements((substring-before($exist-vars('exist:path'), $exist-vars('exist:resource')), controller:basename($exist-vars('exist:resource')))) || '.' || $exist-vars('media-type'))
    else controller:error($exist-vars, 404)
};

(:~
 : Output error message 
 : (mostly used for 404, aka document not found)
 : When HTML serialization is requested, it forwards to the HTML error-page template via the templating module
 : Other output serializations are handled by private functions that directly write to the output stream
 :
 : @param   $exist-vars an object with the standard runtime variables which are necessary for the templating module;
 :          for all non-html serializations you'll only need the 'error-message' property
 :)
declare function controller:error($exist-vars as map(*), $errorCode as xs:int) {
    response:set-status-code($errorCode),
    switch($exist-vars?media-type)
    case 'jsonld' return controller:error-jsonld($exist-vars?error-message)
    case 'xml' return <error>{$exist-vars?error-message}</error>
    case 'txt' return controller:error-txt($exist-vars?error-message)
    default return controller:error-html($exist-vars)
};

(:~
 : Output error message as html and close the stream
 : Helper function for controller:error()
 :)
declare %private function controller:error-html($exist-vars as map(*)) as element(exist:dispatch) {
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="{str:join-path-elements((map:get($exist-vars, 'exist:controller'), 'templates/error-page.html'))}"/>
    	<view>
         <forward url="{str:join-path-elements((map:get($exist-vars, 'exist:controller'), '/modules/view-html.xql'))}">
         	{
         		for $var in map:keys($exist-vars) 
	            return
	            	<set-attribute name="{$var}" value="{$exist-vars($var)}"/>
            }
             <set-attribute name="docType" value="error"/>
             <set-attribute name="modified" value="true"/>
             <cache-control cache="yes"/>
         </forward>
         <forward url="{str:join-path-elements((map:get($exist-vars, 'exist:controller'), 'modules/view-tidy.xql'))}">
            {
            for $var in map:keys($exist-vars) 
            return
                <set-attribute name="{$var}" value="{$exist-vars($var)}"/>
            }
         </forward>
     </view>
  </dispatch>
};

(:~
 : Output error message as ld+json and close the stream
 : Helper function for controller:error()
 :)
declare %private function controller:error-jsonld($message as xs:string) {
    let $serializationParameters := ('method=text', 'media-type=application/ld+json', 'encoding=utf-8')
    let $response := map {'msg': $message}
    return 
        response:stream(
            serialize($response, 
                <output:serialization-parameters>
                    <output:method>json</output:method>
                </output:serialization-parameters>
            ),
            string-join($serializationParameters, ' ')
        )
};

(:~
 : Output error message as xml and close the stream
 : Helper function for controller:error()
 :)
declare %private function controller:error-txt($message as xs:string) {
    let $serializationParameters := ('method=text', 'media-type=text/plain', 'encoding=utf-8')
    return
        response:stream(
            $message, 
            string-join($serializationParameters, ' ')
        )
};

(:~
 : Split URI into path segments and encode those for URI if necessary
 : 
 : @author Peter Stadler
 : @param $uri
 :)
declare function controller:encode-path-segments-for-uri($uri-string as xs:string?) as xs:string {
    str:join-path-elements(tokenize($uri-string, '/') ! controller:url-encode(.))
};

(:~
 : Warning: 
 : * No URL encoding here, see controller:encode-path-segments-for-uri()
 : * resulting paths do not include exist:prefix, see config:link-to-current-app()
 :
 : @return a sequence of valid (external) paths for a document, based on the authors and docType 
~:)
declare function controller:path-to-resource($doc as document-node()?, $lang as xs:string) as xs:string* {
    let $docID := $doc/*/@xml:id
    let $docType := config:get-doctype-by-id($docID) (: Die originale Darstellung der doctypes, also 'persons', 'letters' etc:)
    let $displayName := (: Die Darstellung als URL, also 'Korrespondenz', 'Tagebücher' etc. :)
        try {
            if(config:is-letter($docID)) then lang:get-language-string('correspondence', $lang) (: Ausnahme für Briefe=Korrespondenz:)
            else if(config:is-weberStudies($doc)) then lang:get-language-string('weberStudies', $lang)
            else if($docType = 'var') then 'var'
            else lang:get-language-string($docType, $lang)
        }
        catch * {()}
    let $authorID := 
        try {
            query:get-authorID($doc)
        }
        catch * {()}
    return 
        if($docType = ('persons', 'orgs', 'places')) then str:join-path-elements(('/', $lang, $docID))
        else if($docType = 'var') then str:join-path-elements(('/', $lang, lang:get-language-string('project', $lang), $docID))
        else if($docType = 'addenda') then str:join-path-elements(('/', $lang, lang:get-language-string('project', $lang), lang:get-language-string('volContents', $lang), $docID))
        else if(count($authorID) gt 0 and $displayName) then $authorID ! str:join-path-elements(('/', $lang, ., $displayName, $docID))
        else wega-util:log-to-file('error', 'controller:path-to-resource(): could not create path for ' || $docID)
};

(:~
 : Indices can be under "Register (Indices)" or "Projekt (Project)" 
~:)
declare function controller:path-to-register($docType as xs:string, $lang as xs:string) as xs:string? {
    if($docType = ('letters', 'diaries', 'personsPlus', 'writings', 'works', 'thematicCommentaries', 'documents', 'places')) then str:join-path-elements(('/', $lang, lang:get-language-string('indices', $lang), lang:get-language-string($docType, $lang)))
    else if($docType = ('biblio', 'news')) then str:join-path-elements(('/', $lang, lang:get-language-string('project', $lang), lang:get-language-string($docType, $lang)))
    else if($docType = 'indices') then str:join-path-elements(('/', $lang, lang:get-language-string('indices', $lang)))
    else if($docType = 'project') then str:join-path-elements(('/', $lang, lang:get-language-string('project', $lang)))
    else wega-util:log-to-file('error', 'controller:path-to-register(): could not create path for ' || $docType)
};

declare function controller:docType-url-for-author($author as document-node(), $docType as xs:string, $lang as xs:string) as xs:string {
    let $docType-path-segment := 
        switch($docType)
        case 'letters' return 'correspondence'
        default return $docType
    return
        config:link-to-current-app(str:join-path-elements((controller:path-to-resource($author, $lang)[1], $docType-path-segment || '.html')))
};

(:
 : links can be encoded within the HTML with the prefix '$link'
 : these links are resolved here
 : 
 :)
declare function controller:resolve-link($link as xs:string, $exist-vars as map(*)) as xs:string? {
    let $tokens := 
        for $token in tokenize(substring-after($link, '$link/'), '/')
        let $has-suffix := contains($token, '.')
        return 
            if(matches($token, config:get-option('generalIdPattern'))) then $token
            else if(matches($token, 'dev|test-html')) then $token
            else if($has-suffix) then lang:get-language-string(controller:basename($token), $exist-vars?lang) || '.' || controller:suffix($token)
            else lang:get-language-string($token, $exist-vars?lang)
        (:return 
            if($translation) then replace($translation, '\s+', '_') 
            else $token:)
    return 
        config:link-to-current-app(str:join-path-elements(($exist-vars?lang, $tokens)), $exist-vars)
};

declare function controller:translate-URI($uri as xs:string, $sourceLang as xs:string, $targetLang as xs:string) as xs:string {
    let $langRegex := '/(' || string-join($config:valid-languages, '|') || ')/'
    let $URLparams :=
        if (count(request:get-parameter-names()) gt 0) then  
            '?' ||
            string-join(
                for $i in request:get-parameter-names() 
                    for $j in request:get-parameter($i, '')
                        return ($i || '=' || $j),
                '&amp;'
            ) 
        else ()
    let $tokens := tokenize(functx:substring-after-match($uri, $langRegex), '/')
    let $translated-tokens := 
        for $token at $count in $tokens
        let $suffix := controller:suffix($token)
        return
            if(matches($token, 'A\d{2}[0-9A-F]')) then $token (: pattern for document identifier :)
            else if($token = $gl:schemaSpec-idents) then $token (: pattern for schema identifier as used in the Guidelines :)
            else if($count = count($tokens) and starts-with($token, 'ref-')) then $token (: Guidelines specs :)
            else if($suffix) then lang:translate-language-string(controller:url-decode(substring-before($token, '.' || $suffix)), $sourceLang, $targetLang) || '.' || $suffix
            else lang:translate-language-string(controller:url-decode($token), $sourceLang, $targetLang)
    return
        config:link-to-current-app(str:join-path-elements(($targetLang,$translated-tokens))) || $URLparams
};

declare function controller:redirect-by-gnd($exist-vars as map(*)) as element(exist:dispatch) {
    (: especially for works there can be several documents with the same GND :)
    let $doc := query:doc-by-gnd(controller:basename($exist-vars('exist:resource')))[last()]
    let $media-type := controller:media-type($exist-vars)
    return
        if(exists($doc) and $media-type) then controller:redirect-absolute(controller:path-to-resource($doc, $exist-vars('lang'))[1] || '.' || $media-type)
        else controller:error($exist-vars, 404)
};

declare function controller:lookup-url-mappings($exist-vars as map(*)) {
    let $lookup-table := doc($config:catalogues-collection-path || '/urlMappings.xml')
    let $mapping := $lookup-table//mapping[controller:encode-path-segments-for-uri(@from) = $exist-vars('exist:path')]
(:    let $log := util:log-system-out($exist-vars('exist:path')):)
    return
        if($mapping) then controller:redirect-absolute(controller:encode-path-segments-for-uri($mapping/normalize-space(@to)))
        (: zum debuggen rausgenommen um Fehler anzuzeigen:)
        else if($config:isDevelopment) then wega-util:log-to-file('warn', 'fail for: ' || $exist-vars('exist:path'))
        else controller:error($exist-vars, 404)
};

declare function controller:lookup-typo3-mappings($exist-vars as map(*)) {
    let $lookup-table := doc($config:catalogues-collection-path || '/typo3ContentMappings.xml')
    let $oldID := request:get-parameter('id', '')
    let $mapping := 
        if($oldID castable as xs:integer) then $lookup-table//entry[@oldID = $oldID]
        else ()
    return
        if($mapping) then controller:redirect-absolute(controller:encode-path-segments-for-uri(normalize-space($mapping)))
        else if($config:isDevelopment) then wega-util:log-to-file('warn','fail for: ' || $exist-vars('exist:path'))
        else controller:error($exist-vars, 404)
};

(:~
 : create canonical URL for an IIIF manifest
 :
 : @param $facsimile a TEI facsimile element
 : @return the URL for the IIIF manifest  
~:)
declare function controller:iiif-manifest-id($facsimile as element(tei:facsimile)) as xs:anyURI? {
    let $docID := $facsimile/ancestor::tei:TEI/@xml:id
    let $sourceID := substring($facsimile/@source, 2)
    return xs:anyURI(
        config:get-option('iiifPresentationApi') || $docID || $sourceID || '/manifest.json'
    )
};

(:~
 : URL decoding with replacement of underscores to blanks
~:)
declare function controller:url-decode($string as xs:string?) as xs:string {
    if($string) then replace(xmldb:decode($string), '_', ' ')
    else ''
};

(:~
 : URL encoding with replacement of whitespace to underscores
~:)
declare function controller:url-encode($string as xs:string?) as xs:string {
    encode-for-uri(replace($string, ' ', '_'))
};

declare %private function controller:resource-id($exist-vars as map(*)) as xs:string? {
    let $regex := '^' || config:get-option('generalIdPattern') || '\.' || string-join($config:valid-resource-suffixes, '|') || '$'
    return
        if(matches($exist-vars('exist:resource'), $regex)) then substring-before($exist-vars('exist:resource'), '.')
        else ()
};

(:~
 : Create link to doc
 :
 : @author Peter Stadler
 : @param $doc document node
 : @param $lang the current language (de|en)
 : @return the URL for the document 
:)
declare function controller:create-url-for-doc($doc as document-node()?, $lang as xs:string) as xs:string? {
    let $path :=  controller:path-to-resource($doc, $lang)[1]
    return
        if($doc and $path) then config:link-to-current-app($path || '.html')
        else ()
};

(:~
 : Create link to doc
 : This 3-arity function version will honour the current (author) context by returning
 : a link depending on the author ID. If the provided context does not match the requested 
 : document, the canonical link will be returned.
 :
 : @author Peter Stadler
 : @param $doc document node
 : @param $lang the current language (de|en)
 : @param $context the current (author) context, e.g. 'A002068'
 : @return the URL for the document
:)
declare function controller:create-url-for-doc-in-context($doc as document-node()?, $lang as xs:string, $contextID as xs:string) as xs:string? {
    let $path := controller:path-to-resource($doc, $lang)
    return
        if($doc and count($path[contains(., $contextID)]) = 1) then config:link-to-current-app($path[contains(., $contextID)] || '.html')
        else if($doc and count($path) gt 0) then config:link-to-current-app($path[1] || '.html')
        else ()
};

(:~
 : Figure out the requested mime type for a resource by looking at its file extension and HTTP request headers.
 : The file extension gets precedence over HTTP headers; 
 : when no supported file extension nor HTTP headers are given, the empty sequence is returned.
 : 
 : @author Peter Stadler
 : @param $exist-vars a map containing various stuff, here we need the requested resource, i.e. $exist-vars('exist:resource')
 : @return a string {html|xml} or empty sequence
 :)
declare %private function controller:media-type($exist-vars as map(*)) as xs:string? {
    let $suffix := controller:suffix($exist-vars('exist:resource'))
    let $header := tokenize(request:get-header('Accept'), ',')
    return
        if($suffix) then controller:canonical-mime-type($suffix)
        else controller:canonical-mime-type($header)
};

(:~
 : Helper function for controller:media-type()
 : Recursively loop through a sequence of strings and see whether some string matches a defined pattern. 
 : Return the first matching string.
 : 
 : @author Peter Stadler
 : @param $mime-type some string representation of a mime type, e.g. "xml" or "application/xml"
 : @return a string {html|xml} or empty sequence
 :)
declare %private function controller:canonical-mime-type($mime-type as xs:string*) as xs:string? {
    switch($mime-type[1])
    case 'html' case 'htm' return 'html'
    case 'xml' case 'tei' return 'xml'
    case 'text/html' case 'application/xhtml+xml' return 'html'
    case 'application/xml' case 'application/tei+xml' return 'xml'
    case 'txt' case 'text' case 'text/plain' return 'txt'
    case 'jsonld' case 'application/ld+json' return 'jsonld'
    default return 
        if(count($mime-type) gt 1) then controller:canonical-mime-type(subsequence($mime-type, 2))
        else ()
};

declare %private function controller:forward-document($exist-vars as map(*)) as element(exist:dispatch) {
    switch($exist-vars('media-type'))
    case 'html' return
        switch($exist-vars('docType'))
        case 'persons' case 'orgs' return controller:forward-html('/templates/person.html', $exist-vars)
        case 'places' return controller:forward-html('/templates/place.html', $exist-vars)
        case 'works' return controller:forward-html('/templates/work.html', $exist-vars)
        case 'var' case 'thematicCommentaries' case 'addenda' return controller:forward-html('/templates/var.html', $exist-vars)
        default return controller:forward-html('/templates/document.html', $exist-vars)
    case 'xml' return controller:forward-xml($exist-vars)
    case 'txt' return controller:forward-txt($exist-vars)
    case 'jsonld' return controller:forward-jsonld($exist-vars)
    default return controller:error($exist-vars, 404)
};

declare %private function controller:etag($path as xs:string) as xs:string {
    let $lastChanged := 
        (: reload index page every day because of word of the day and what happened on … :)
        if(contains($path, 'Index')) then config:getDateTimeOfLastDBUpdate() || current-date()
        else config:getDateTimeOfLastDBUpdate()
    let $urlParams := string-join((config:entries-per-page(),for $i in request:get-parameter-names() order by $i return request:get-parameter($i, '')), '')
    return
        util:hash($path || $lastChanged || $urlParams, 'md5')
};

(:~
 : Returns the basename of a filename, i.e. the filename without extension
 : If $filename does not contain a dot (= has no extension), the entire $filename is returned. 
 : If $filename is the empty sequence, the empty sequence is returned.
~:)
declare %private function controller:basename($filename as xs:string?) as xs:string? {
    functx:substring-before-last-match($filename, '\.')
};

(:~
 : Returns the filename extension (= the suffix) of a filename
 : The filename extension is the substring after the last dot. 
 : If $filename contains no dot, the empty sequence is returned. 
~:)
declare %private function controller:suffix($filename as xs:string?) as xs:string? {
    if(contains($filename, '.')) then functx:substring-after-last($filename, '.')
    else ()
};
