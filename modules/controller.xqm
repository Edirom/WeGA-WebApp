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

import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "str.xqm";
import module namespace functx="http://www.functx.com";

declare function controller:forward-html($html-template as xs:string, $exist-vars as map()*) as element(exist:dispatch) {
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="{str:join-path-elements((map:get($exist-vars, 'controller'), $html-template))}"/>
    	<view>
            <forward url="{str:join-path-elements((map:get($exist-vars, 'controller'), 'modules/view-html.xql'))}">
                <set-attribute name="docID" value="{$exist-vars('docID')}"/>
                <!-- Needed for register pages -->
                <set-attribute name="docType" value="{$exist-vars('docType')}"/>
            </forward>
            <forward url="{str:join-path-elements((map:get($exist-vars, 'controller'), 'modules/view-tidy.xql'))}">
                <set-attribute name="lang" value="{$exist-vars('lang')}"/>
            </forward>
        </view>
        <error-handler>
            <forward url="{str:join-path-elements((map:get($exist-vars, 'controller'), '/templates/error-page.html'))}" method="get"/>
            <forward url="{str:join-path-elements((map:get($exist-vars, 'controller'), '/modules/view-html.xql'))}"/>
        </error-handler>
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
        <redirect url="{core:link-to-current-app($path)}"/>
    </dispatch>
};


declare function controller:dispatch($exist-vars as map(*)) as element(exist:dispatch) {
    let $media-type := controller:media-type($exist-vars)
    let $docID := functx:substring-before-if-contains($exist-vars('resource'), '.')
    let $updated-exist-vars := 
        map:new((
            $exist-vars, 
            map:entry('docID', $docID),
            map:entry('docType', config:get-doctype-by-id($docID)),
            map:entry('media-type', $media-type)
        ))
    let $doc := core:doc($docID)
    let $path := controller:encode-path-segments-for-uri(controller:path-to-resource($doc, $exist-vars('lang')))
(:    let $log := util:log-system-out($exist-vars('path')):)
(:    let $log := util:log-system-out($path):)
    return 
        if($exist-vars('path') eq $path || '.' || $media-type) then controller:forward-document($updated-exist-vars)
        else if($path) then controller:redirect-absolute($path || '.' || $media-type)
        else controller:error($exist-vars, 404)
};

(:~
 : Dispatch pages for tab "Indices"
 :)
declare function controller:dispatch-register($exist-vars as map(*)) as element(exist:dispatch) {
    let $docType := 
        if($exist-vars('resource')) then lang:reverse-language-string-lookup(xmldb:decode($exist-vars('resource')), $exist-vars('lang'))[. = (map:keys($config:wega-docTypes), 'indices', 'project')]
        else 'indices'
    let $path := controller:encode-path-segments-for-uri(controller:path-to-register($docType, $exist-vars('lang')))
    let $updated-exist-vars := 
        map:new((
            $exist-vars, 
            map:entry('docID', 'indices'),
            map:entry('docType', $docType)
        ))
    return 
        if($exist-vars('path') eq $path) then controller:forward-html('/templates/register.html', $updated-exist-vars)
        else controller:error($exist-vars, 404)
};

(:~
 : Dispatch pages for tab "Project"
 :)
declare function controller:dispatch-project($exist-vars as map(*)) as element(exist:dispatch) {
    let $project-nav := doc(concat($config:app-root, '/templates/page.html'))//(xhtml:li[@id='project-nav']//xhtml:a | xhtml:ul[@class='footerNav']//xhtml:a) 
    let $request := request:get-uri()
    let $a := distinct-values($project-nav/@href[controller:encode-path-segments-for-uri(controller:resolve-link(.,$exist-vars('lang'))) = $request]/parent::*)
    return
        switch($a)
        case 'bibliography' case 'news' return controller:dispatch-register($exist-vars)
        (: Need to inject the corresponding IDs of special pages here :)
        case 'projectDescription' return controller:forward-html('/templates/var.html', map:new(($exist-vars, map:entry('docID', 'A070006'), map:entry('docType', 'var')))) 
        case 'editorialGuidelines'  return controller:forward-html('/templates/var.html', map:new(($exist-vars, map:entry('docID', 'A070001'), map:entry('docType', 'var'))))
        case 'contact' return controller:forward-html('/templates/var.html', map:new(($exist-vars, map:entry('docID', 'A070009'), map:entry('docType', 'var'))))
        case 'about' return controller:forward-html('/templates/var.html', map:new(($exist-vars, map:entry('docID', 'A070002'), map:entry('docType', 'var'))))
        case 'volContents' return controller:forward-html('/templates/var.html', map:new(($exist-vars, map:entry('docID', 'A070011'), map:entry('docType', 'var'))))
        default return controller:error($exist-vars, 404)
};

declare function controller:error($exist-vars as map(*), $errorCode as xs:int) as element(exist:dispatch) {
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="{str:join-path-elements((map:get($exist-vars, 'controller'), 'templates/error-page.html'))}"/>
    	<view>
         <forward url="{str:join-path-elements((map:get($exist-vars, 'controller'), '/modules/view-html.xql'))}">
             <add-parameter name="lang" value="{$exist-vars('lang')}"/>
             <cache-control cache="yes"/>
         </forward>
         <forward url="{str:join-path-elements((map:get($exist-vars, 'controller'), 'modules/view-tidy.xql'))}">
            <set-attribute name="lang" value="{$exist-vars('lang')}"/>
         </forward>
     </view>
  </dispatch>,
   response:set-status-code($errorCode)
};


(:~
 : Split URI into path segments and encode those for URI if necessary
 : 
 : @author Peter Stadler
 : @param $uri
 :)
declare function controller:encode-path-segments-for-uri($uri-string as xs:string?) as xs:string? {
    typeswitch($uri-string)
    case xs:string return 
        if(matches($uri-string, '^[a-zA-Z0-9/]+$')) then $uri-string
        else str:join-path-elements(tokenize($uri-string, '/') ! encode-for-uri(.))
    default return ()
};

declare function controller:path-to-resource($doc as document-node()?, $lang as xs:string) as xs:string? {
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
        if($docType = 'persons') then str:join-path-elements(('/', $lang, $docID))
        else if($docType = 'var') then str:join-path-elements(('/', $lang, lang:get-language-string('project', $lang), $docID))
        else if($authorID and $displayName) then str:join-path-elements(('/', $lang, $authorID, $displayName, $docID))
        else core:logToFile('error', 'controller:path-to-resource(): could not create path for ' || $docID)
};

(:~
 : Indices can be under "Register (Indices)" or "Projekt (Project)" 
~:)
declare function controller:path-to-register($docType as xs:string, $lang as xs:string) as xs:string? {
    if($docType = ('letters', 'diaries', 'persons', 'writings', 'works')) then str:join-path-elements(('/', $lang, lang:get-language-string('indices', $lang), lang:get-language-string($docType, $lang)))
    else if($docType = ('biblio', 'news')) then str:join-path-elements(('/', $lang, lang:get-language-string('project', $lang), lang:get-language-string($docType, $lang)))
    else if($docType = 'indices') then str:join-path-elements(('/', $lang, lang:get-language-string('indices', $lang)))
    else if($docType = 'project') then str:join-path-elements(('/', $lang, lang:get-language-string('project', $lang)))
    else core:logToFile('error', 'controller:path-to-register(): could not create path for ' || $docType)
};

declare function controller:docType-url-for-author($author as document-node(), $docType as xs:string, $lang as xs:string) as xs:string {
    let $docType-path-segment := 
        switch($docType)
        case 'letters' return 'correspondence'
        default return $docType
    return
        core:link-to-current-app(str:join-path-elements((controller:path-to-resource($author, $lang), $docType-path-segment || '.html')))
};

(:
 : links can be encoded within the HTML with the prefix '$link'
 : these links are resolved here
 : 
 :)
declare function controller:resolve-link($link as xs:string, $lang as xs:string) as xs:string? {
    let $tokens := 
        for $token in tokenize(substring-after($link, '$link/'), '/')
        let $has-suffix := contains($token, '.')
        let $translation := 
            if(matches($token, 'A[A-F0-9]{6}')) then $token
            else if(matches($token, 'dev|test-html')) then $token
            else if($has-suffix) then lang:get-language-string(substring-before($token, '.'), $lang) || '.' || substring-after($token, '.')
            else lang:get-language-string($token, $lang)
        return 
            if($translation) then replace($translation, '\s+', '_') 
            else $token
    return 
        core:link-to-current-app(str:join-path-elements(($lang, $tokens)))
};

declare function controller:translate-URI($uri as xs:string,$sourceLang as xs:string, $targetLang as xs:string) as xs:string {
    let $tokens := tokenize(functx:substring-after-match($uri, '/(de)|(en)/'), '/')
    let $translated-tokens := 
        for $token in $tokens
        let $has-suffix := contains($token, '.')
        return
            if(matches($token, 'A\d{2}[0-9A-F]')) then $token
            else if($has-suffix) then lang:translate-language-string(replace(substring-before(xmldb:decode($token), '.'), '_', ' '), $sourceLang, $targetLang) || '.' || substring-after($token, '.')
            else lang:translate-language-string(replace(xmldb:decode($token), '_', ' '), $sourceLang, $targetLang)
    return
        core:link-to-current-app(replace(str:join-path-elements(($targetLang,$translated-tokens)), '\s+', '_'))
};

declare function controller:redirect-by-gnd($exist-vars as map(*)) {
    let $doc := query:doc-by-gnd($exist-vars('resource'))
    return
        if(exists($doc)) then controller:redirect-absolute(controller:path-to-resource($doc, $exist-vars('lang')))
        else controller:error($exist-vars('resource'), '404')
};

(:~
 : 
 : @author Peter Stadler
 : @param $path e.g. /db/apps/WeGA-WebApp/tmp/images/A0020xx/A002068/12345628.jpg
~:)
(:declare function controller:map-local-image-path-to-external($path as xs:string) as xs:string {
    replace($path, $config:tmp-collection-path || '/images/A00[0-9A-F]{2}xx/(A00[0-9A-F]{4})/', '$1/img/')
};
:)
(:~
 :
 : @author Peter Stadler
 : @param $path e.g. /de/A002068/img/12345628.jpg
~:)
(:declare function controller:map-external-image-path-to-local($path as xs:string) as xs:string {
    replace($path, '/\w{2}/(A00[0-9A-F]{2})([0-9A-F]{2})/img/', replace($config:tmp-collection-path, $config:app-root, '') || '/images/$1xx/$1$2/')
};
:)
declare %private function controller:resource-id($exist-vars as map(*)) as xs:string? {
    let $regex := '^A\d{2}[0-9A-F]{4}\.' || string-join($config:valid-resource-suffixes, '|') || '$'
    return
        if(matches($exist-vars('resource'), $regex)) then substring-before($exist-vars('resource'), '.')
        else ()
};


declare %private function controller:media-type($exist-vars as map(*)) as xs:string? {
    'html'
};


declare %private function controller:forward-document($exist-vars as map(*)) as element(exist:dispatch) {
    switch($exist-vars('docType'))
    case 'persons' return controller:forward-html('/templates/person.html', $exist-vars)
    default return controller:forward-html('/templates/document.html', $exist-vars)
};
