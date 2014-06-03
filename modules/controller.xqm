xquery version "3.0";

(:~
 : XQuery module for processing dates
 :)
module namespace controller="http://xquery.weber-gesamtausgabe.de/modules/controller";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace exist="http://exist.sourceforge.net/NS/exist";

import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";

(:import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";:)


declare function controller:forward($path as xs:string, $exist-vars as map()*) as element(exist:dispatch) {
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="{controller:forward-url(map:get($exist-vars, 'controller'), $path)}">
    	   <add-parameter name="lang" value="{map:get($exist-vars, 'lang')}"/>
    	   <add-parameter name="docType" value="{config:get-doctype-by-id(map:get($exist-vars, 'resource'))}"/>
    	   <add-parameter name="id" value="{map:get($exist-vars, 'resource')}"/>
    	</forward>
    </dispatch>
};

declare function controller:forward-ajax($exist-vars as map()*) as element(exist:dispatch) {
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="{controller:forward-url(map:get($exist-vars, 'controller'), 'modules/' || map:get($exist-vars, 'resource'))}">
    	   {if(request:get-parameter-names() = 'lang') then () else <add-parameter name="lang" value="{map:get($exist-vars, 'lang')}"/> }
    	   {if(map:get($exist-vars, 'resource') = 'getJavaScriptOptions.xql') then <set-header name="Cache-Control" value="max-age=3600"/>
            else ()}
            <cache-control cache="yes"/>
    	</forward>
    </dispatch>
};

declare %private function controller:forward-url($controller as xs:string, $path as xs:string) as xs:string {
    replace(string-join(($controller, $path), "/"), "/+", "/")
};


declare function controller:default-forward($html-template as xs:string, $exist-vars as map()*) as element(exist:dispatch) {
    let $context := (: Param for templating the context nav :)
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
