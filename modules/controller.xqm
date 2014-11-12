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

declare function controller:forward($html-template as xs:string, $exist-vars as map()*) as element(exist:dispatch) {
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="{str:join-path-elements((map:get($exist-vars, 'controller'), $html-template))}"/>
    	<view>
            <forward url="{str:join-path-elements((map:get($exist-vars, 'controller'), 'modules/view.xql'))}">
                <set-attribute name="resource" value="{$exist-vars('resource')}"/>
                <!--<set-attribute name="$exist:prefix" value="{map:get($exist-vars, 'prefix')}"/>
                <set-attribute name="$exist:controller" value="{map:get($exist-vars, 'controller')}"/>
                <set-attribute name="docID" value="{map:get($exist-vars, 'resource')}"/>
                <set-attribute name="{$context}" value="true"/>-->
                <!--<set-header name="Cache-Control" value="no-cache"/>-->
            </forward>
            <forward url="{str:join-path-elements((map:get($exist-vars, 'controller'), 'modules/view-tidy.xql'))}">
                <set-attribute name="lang" value="{$exist-vars('lang')}"/>
            </forward>
        </view>
        <error-handler>
            <forward url="{str:join-path-elements((map:get($exist-vars, 'controller'), '/templates/error-page.html'))}" method="get"/>
            <forward url="{str:join-path-elements((map:get($exist-vars, 'controller'), '/modules/view.xql'))}"/>
        </error-handler>
    </dispatch>
};


(:declare function controller:forward($path as xs:string, $exist-vars as map(*)) as element(exist:dispatch) {
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="{str:join-path-elements((map:get($exist-vars, 'controller'), $path))}">
    	   <add-parameter name="lang" value="{map:get($exist-vars, 'lang')}"/>
    	   <add-parameter name="docType" value="{config:get-doctype-by-id(map:get($exist-vars, 'resource'))}"/>
    	   <add-parameter name="id" value="{map:get($exist-vars, 'resource')}"/>
    	</forward>
    </dispatch>
};:)

(:declare function controller:forward-ajax($exist-vars as map(*)) as element(exist:dispatch) {
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="{str:join-path-elements((map:get($exist-vars, 'controller'), 'modules/' || map:get($exist-vars, 'resource')))}">
    	   {if(request:get-parameter-names() = 'lang') then () else <add-parameter name="lang" value="{map:get($exist-vars, 'lang')}"/> }
    	   {if(map:get($exist-vars, 'resource') = 'getJavaScriptOptions.xql') then <set-header name="Cache-Control" value="max-age=3600"/>
            else ()}
            <cache-control cache="yes"/>
    	</forward>
    </dispatch>
};:)


(:~
 : Redirect to given (absolute) path
 : The language subfolder is automatically added
 : 
 : @author Peter Stadler
 : @param $exist-vars a map with information about prefix, controller, lang etc
 : @param $path the path to redirect to
 : @return exist:dispatch element for controller.xql
 :)
declare function controller:redirect-absolute($path as xs:string, $lang as xs:string) as element(exist:dispatch) {
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{core:link-to-current-app($lang || '/' || $path)}"/>
    </dispatch>
};

declare function controller:redirect-docID($exist-vars as map(*)) as element(exist:dispatch) {
    let $doc := core:doc($exist-vars('resource'))
    let $docID := $doc/tei:*/string(@xml:id)
    let $docType := config:get-doctype-by-id($docID) (: Die originale Darstellung der doctypes, also 'persons', 'letters' etc:)
    let $displayName := controller:display-name($exist-vars, $docType) (: Die Darstellung als URL, also 'Korrespondenz', 'Tagebücher' etc. :)
    let $authorID := query:getAuthorOfTeiDoc($doc)
    return 
        if($docType eq 'persons') then controller:redirect-absolute($docID, $exist-vars('lang'))
        else if($authorID) then controller:redirect-absolute(str:join-path-elements(($authorID, $displayName, $docID)), $exist-vars('lang'))
        else controller:error($exist-vars, 404)
};

declare function controller:error($exist-vars as map(*), $errorCode as xs:int) as element(exist:dispatch) {
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="{str:join-path-elements((map:get($exist-vars, 'controller'), 'templates/error-page.html'))}"/>
    	<view>
            <forward url="{str:join-path-elements((map:get($exist-vars, 'controller'), '/modules/view.xql'))}">
                <add-parameter name="errorCode" value="{$errorCode}"/>
                <add-parameter name="lang" value="{$exist-vars('lang')}"/>
                <cache-control cache="yes"/>
            </forward>
        </view>
        <error-handler>
            <forward url="{str:join-path-elements((map:get($exist-vars, 'controller'), '/templates/error-page.html'))}" method="get"/>
            <forward url="{str:join-path-elements((map:get($exist-vars, 'controller'), '/modules/view.xql'))}"/>
        </error-handler>
    </dispatch>
};

(:~
 : Get the display name for a given docType
 : 
 : @author Peter Stadler
 :)
declare %private function controller:display-name($exist-vars as map(*), $docType as xs:string) as xs:string {
    let $displayName := 
        if($docType eq 'letters') then 'correspondence'
        else $docType
    return 
        encode-for-uri(lang:get-language-string($displayName, $exist-vars('lang')))
};

(:~
 : Split URI into path segments and encode those for URI
 : 
 : @author Peter Stadler
 : @param $uri the 
 :)
declare function controller:encode-path-segments-for-uri($uri-string as xs:string) as xs:string {
    if(matches($uri-string, '^[a-zA-Z0-9/]+$')) then $uri-string
    else str:join-path-elements(tokenize($uri-string, '/') ! encode-for-uri(.))
};

(:
declare function controller:default-forward($html-template as xs:string, $exist-vars as map()*) as element(exist:dispatch) {
    let $context := (\: Param for templating the context nav :\)
        switch (config:get-doctype-by-id(map:get($exist-vars, 'resource')))
            case 'diaries' return 'context1'
            case 'letters' return 'context2'
            case 'news' return 'context1'
            default return ()
    return
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="{map:get($exist-vars, 'controller') || '/templates/' || $html-template}"/>
    	<view>
            <forward url="{map:get($exist-vars, 'controller') || '/modules/view.xql'}">
                <set-attribute name="$exist:prefix" value="{map:get($exist-vars, 'prefix')}"/>
                <set-attribute name="$exist:controller" value="{map:get($exist-vars, 'controller')}"/>
                <set-attribute name="docID" value="{map:get($exist-vars, 'resource')}"/>
                <set-attribute name="{$context}" value="true"/>
                <set-header name="Cache-Control" value="no-cache"/>
            </forward>
        </view>
        <error-handler>
            <forward url="{map:get($exist-vars, 'controller') || '/templates/error-page.html'}" method="get"/>
            <forward url="{map:get($exist-vars, 'controller') || '/modules/view.xql'}"/>
        </error-handler>
    </dispatch>
};
:)

(:~
 : 
 : 
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
