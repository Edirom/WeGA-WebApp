xquery version "3.0" encoding "UTF-8";

(:~
 : Functions for creating http requests
:)
module namespace wega-http="http://xquery.weber-gesamtausgabe.de/modules/wega-http";
declare default collation "?lang=de;strength=primary";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace httpclient = "http://exist-db.org/xquery/httpclient";
declare namespace wega="http://www.weber-gesamtausgabe.de";

import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "str.xqm";

(:~
 : Get resources from the web by PND and store the result in a cache object with the current date. 
 : If the date does match with today's date then the result will be taken from the cache; otherwise the external resource will be queried.
 : ATTENTION: Wikipedia sends HTMl pages without namespace
 :
 : @author Peter Stadler 
 : @param $resource the external resource (wikipedia|adb|dnb)
 : @param $pnd the PND number
 : @param $lang the language variable (de|en). If no language is specified, the default (German) resource is grabbed and served
 : @param $useCache use cached version or force a reload of the external resource
 : @return node
 :)
 declare function wega-http:grabExternalResource($resource as xs:string, $pnd as xs:string, $lang as xs:string?, $useCache as xs:boolean) as element(httpclient:response)? {
    let $serverURL := 
        if($resource eq 'wikipedia') then concat(config:get-option($resource), $lang, '/')
        else config:get-option($resource)
    let $fileName := string-join(($pnd, $lang, 'xml'), '.')
    let $today := current-date()
    let $response := core:cache-doc(str:join-path-elements(($config:tmp-collection-path, $resource, $fileName)), wega-http:http-get#1, xs:anyURI(concat($serverURL, $pnd)), not($useCache))
    return 
        if($response//httpclient:response/@statusCode eq '200') then $response//httpclient:response
        else ()
};


(:~
 : Helper function for wega:grabExternalResource()
 :
 : @author Peter Stadler 
 : @param $url the URL as xs:anyURI
 : @return element wega:externalResource, a wrapper around httpclient:response
 :)
declare function wega-http:http-get($url as xs:anyURI) as element(wega:externalResource) {
    let $req := <http:request href="{$url}" method="get" timeout="4"><http:header name="Connection" value="close"/></http:request>
    let $response := 
        try { http:send-request($req) }
        catch * {core:logToFile('warn', string-join(('wega:http-get', $err:code, $err:description, 'URL: ' || $url), ' ;; '))}
    (:let $response := 
        if($response/httpclient:body[matches(@mimetype,"text/html")]) then wega:changeNamespace($response,'http://www.w3.org/1999/xhtml', 'http://exist-db.org/xquery/httpclient')
        else $response:)
    let $statusCode := $response[1]/data(@status)
    return
        <wega:externalResource date="{current-date()}">
            <httpclient:response statusCode="{$statusCode}">
                <httpclient:headers>{
                    for $header in $response[1]//http:header
                    return element httpclient:header {$header/@*}
                }</httpclient:headers>
                <httpclient:body mimetype="{$response[1]//http:body/data(@media-type)}">
                    {$response[2]}
                </httpclient:body>
            </httpclient:response>
        </wega:externalResource>
};
