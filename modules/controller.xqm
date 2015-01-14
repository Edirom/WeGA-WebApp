xquery version "3.0" encoding "UTF-8";

(:~
 : XQuery functions for the main controller
 :)
module namespace controller="http://xquery.weber-gesamtausgabe.de/modules/controller";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace exist="http://exist.sourceforge.net/NS/exist";

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
                <set-attribute name="resource" value="{$exist-vars('resource')}"/>
                <set-attribute name="docID" value="{$exist-vars('docID')}"/>
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


declare function controller:dispatch($exist-vars as map(*)) {
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
    let $path := controller:path-to-resource($doc, $exist-vars('lang'))
(:    let $log := util:log-system-out($exist-vars('path')):)
(:    let $log := util:log-system-out($path):)
    return 
        if($exist-vars('path') eq $path || '.' || $media-type) then controller:forward-document($updated-exist-vars)
        else if($path) then controller:redirect-absolute($path || '.' || $media-type)
        else controller:error($exist-vars, 404)
};

declare function controller:error($exist-vars as map(*), $errorCode as xs:int) as element(exist:dispatch) {
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="{str:join-path-elements((map:get($exist-vars, 'controller'), 'templates/error-page.html'))}"/>
    	<view>
            <forward url="{str:join-path-elements((map:get($exist-vars, 'controller'), '/modules/view-html.xql'))}">
                <add-parameter name="errorCode" value="{$errorCode}"/>
                <add-parameter name="lang" value="{$exist-vars('lang')}"/>
                <cache-control cache="yes"/>
            </forward>
        </view>
        <error-handler>
            <forward url="{str:join-path-elements((map:get($exist-vars, 'controller'), '/templates/error-page.html'))}" method="get"/>
            <forward url="{str:join-path-elements((map:get($exist-vars, 'controller'), '/modules/view-html.xql'))}"/>
        </error-handler>
    </dispatch>
};


(:~
 : Split URI into path segments and encode those for URI
 : 
 : @author Peter Stadler
 : @param $uri
 :)
declare function controller:encode-path-segments-for-uri($uri-string as xs:string) as xs:string {
    if(matches($uri-string, '^[a-zA-Z0-9/]+$')) then $uri-string
    else str:join-path-elements(tokenize($uri-string, '/') ! encode-for-uri(.))
};

declare function controller:path-to-resource($doc as document-node()?, $lang as xs:string) as xs:string? {
    let $docID := $doc/*/@xml:id
    let $docType := config:get-doctype-by-id($docID) (: Die originale Darstellung der doctypes, also 'persons', 'letters' etc:)
    let $displayName := (: Die Darstellung als URL, also 'Korrespondenz', 'Tagebücher' etc. :)
        try {
            if(config:is-letter($docID)) then lang:get-language-string('correspondence', $lang) (: Ausnahme für Briefe=Korrespondenz:)
            else if(config:is-weberStudies($doc)) then lang:get-language-string('weberStudies', $lang)
            else lang:get-language-string(config:get-doctype-by-id($docID), $lang)
        }
        catch * {()}
    let $authorID := 
        try {
            query:get-authorID($doc)
        }
        catch * {()}
    return 
        if($docType = 'persons') then str:join-path-elements(('/', $lang, $docID))
        else if($authorID and $displayName) then str:join-path-elements(('/', $lang, $authorID, $displayName, $docID))
        else core:logToFile('error', 'controller:path-to-resource(): could not create path for ' || $docID)
};


(:~
 : 
 : @author Peter Stadler
 : @param $path e.g. /db/apps/WeGA-WebApp/tmp/images/A0020xx/A002068/12345628.jpg
~:)
declare function controller:map-local-image-path-to-external($path as xs:string) as xs:string {
    replace($path, $config:tmp-collection-path || '/images/A00\d{2}xx/(A00\d{4})/', '$1/img/')
};

(:~
 :
 : @author Peter Stadler
 : @param $path e.g. /de/A002068/img/12345628.jpg
~:)
declare function controller:map-external-image-path-to-local($path as xs:string) as xs:string {
    replace($path, '/\w{2}/(A00\d{2})(\d{2})/img/', replace($config:tmp-collection-path, $config:app-root, '') || '/images/$1xx/$1$2/')
};

declare %private function controller:resource-id($exist-vars as map(*)) as xs:string? {
    let $regex := '^A\d{6}\.' || string-join($config:valid-resource-suffixes, '|') || '$'
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
