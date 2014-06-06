xquery version "3.0" encoding "UTF-8";

(:~
 : XQuery module for processing dates
 :)
module namespace controller="http://xquery.weber-gesamtausgabe.de/modules/controller";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace exist="http://exist.sourceforge.net/NS/exist";

import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace wega="http://xquery.weber-gesamtausgabe.de/modules/wega" at "wega.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";


declare function controller:forward($path as xs:string, $exist-vars as map(*)) as element(exist:dispatch) {
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="{core:join-path-elements((map:get($exist-vars, 'controller'), $path))}">
    	   <add-parameter name="lang" value="{map:get($exist-vars, 'lang')}"/>
    	   <add-parameter name="docType" value="{config:get-doctype-by-id(map:get($exist-vars, 'resource'))}"/>
    	   <add-parameter name="id" value="{map:get($exist-vars, 'resource')}"/>
    	</forward>
    </dispatch>
};

declare function controller:forward-ajax($exist-vars as map(*)) as element(exist:dispatch) {
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="{core:join-path-elements((map:get($exist-vars, 'controller'), 'modules/' || map:get($exist-vars, 'resource')))}">
    	   {if(request:get-parameter-names() = 'lang') then () else <add-parameter name="lang" value="{map:get($exist-vars, 'lang')}"/> }
    	   {if(map:get($exist-vars, 'resource') = 'getJavaScriptOptions.xql') then <set-header name="Cache-Control" value="max-age=3600"/>
            else ()}
            <cache-control cache="yes"/>
    	</forward>
    </dispatch>
};


(:~
 : Redirect to given (absolute) path
 : The language subfolder is automatically added
 : 
 : @author Peter Stadler
 : @param $exist-vars a map with information about prefix, controller, lang etc
 : @param $path the path to redirect to
 : @return exist:dispatch element for controller.xql
 :)
declare function controller:redirect-absolute($exist-vars as map(*), $path as xs:string) as element(exist:dispatch) {
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{core:join-path-elements(('/', $exist-vars('prefix'), $exist-vars('controller'), $exist-vars('lang'), $path))}"/>
    </dispatch>
};

declare function controller:redirect-docID($exist-vars as map(*), $requestID as xs:string) as element(exist:dispatch) {
    let $doc := core:doc($requestID)
    let $docID := $doc/tei:*/string(@xml:id)
    let $docType := config:get-doctype-by-id($docID) (: Die originale Darstellung der doctypes, also 'persons', 'letters' etc:)
    let $displayName := controller:display-name($exist-vars, $docType, 'persons') (: Die Darstellung als URL, also 'Korrespondenz', 'Tagebücher' etc. :)
    let $authorID := wega:getAuthorOfTeiDoc($doc)
    return 
        if($docType eq 'persons') then controller:redirect-absolute($exist-vars, $docID)
        else if($authorID) then controller:redirect-absolute($exist-vars, core:join-path-elements(($authorID, $displayName, $docID)))
        else controller:error($exist-vars, 404)
};

declare function controller:error($exist-vars as map(*), $errorCode as xs:int) {
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="{concat($exist-vars('controller'), '/modules/error.xql')}">
    	   <add-parameter name="errorCode" value="{$errorCode}"/>
    	   <add-parameter name="lang" value="{$exist-vars('lang')}"/>
    	   <cache-control cache="yes"/>
    	</forward>
    </dispatch>
};

(:~
 : Get the display name for a given docType
 : 
 : @author Peter Stadler
 :)
declare %private function controller:display-name($exist-vars as map(*), $docType as xs:string, $menuID as xs:string) as xs:string {
    let $menu := doc(config:get-option('menusFile'))//id($menuID)
    return 
        encode-for-uri(lang:get-language-string($menu/entry[docType = $docType]/string(displayName), $exist-vars('lang')))
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