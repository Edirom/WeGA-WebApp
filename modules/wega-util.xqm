xquery version "3.0" encoding "UTF-8";

(:~
 : Functions for creating http requests
:)
module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util";
declare default collation "?lang=de;strength=primary";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace httpclient = "http://exist-db.org/xquery/httpclient";
declare namespace wega="http://www.weber-gesamtausgabe.de";

import module namespace xqjson="http://xqilla.sourceforge.net/lib/xqjson";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "str.xqm";

(:~
 : Get resources from the web by PND and store the result in a cache object with the current date. 
 : If the date does match with today's date then the result will be taken from the cache; otherwise the external resource will be queried.
 : ATTENTION: Wikipedia sends HTMl pages without namespace
 :
 : @author Peter Stadler 
 : @param $resource the external resource (wikipedia|adb|dnb|beacon)
 : @param $pnd the PND number
 : @param $lang the language variable (de|en). If no language is specified, the default (German) resource is grabbed and served
 : @param $useCache use cached version or force a reload of the external resource
 : @return node
 :)
 declare function wega-util:grabExternalResource($resource as xs:string, $pnd as xs:string, $lang as xs:string?) as element(httpclient:response)? {
    let $lease := xs:dayTimeDuration('P1D')
    let $url := 
        if($resource eq 'wikipedia') then concat(config:get-option($resource), $lang, '/', $pnd)
        else if($resource eq 'dnb') then concat(config:get-option($resource), $pnd, '/about/rdf')
        else config:get-option($resource) || $pnd
    let $fileName := string-join(($pnd, $lang, 'xml'), '.')
    let $today := current-date()
    let $response := core:cache-doc(str:join-path-elements(($config:tmp-collection-path, $resource, $fileName)), wega-util:http-get#1, xs:anyURI($url), $lease)
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
declare function wega-util:http-get($url as xs:anyURI) as element(wega:externalResource) {
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

declare function wega-util:beacon-map($gnd as xs:string) as map(*) {
    let $findbuchResponse := wega-util:grabExternalResource('beacon', $gnd, 'de')
    (:let $log := util:log-system-out($gnd):)
    let $jxml := 
        if(exists($findbuchResponse)) then 
            if($findbuchResponse/httpclient:body/@encoding = 'Base64Encoded') then xqjson:parse-json(util:binary-to-string($findbuchResponse))
            else xqjson:parse-json($findbuchResponse)
        else ()
    return 
        map:new(
            for $i in 1 to count($jxml/item[2]/item)
            let $link  := str:normalize-space($jxml/item[4]/item[$i])
            let $title := str:normalize-space($jxml/item[3]/item[$i])
            let $text  := str:normalize-space($jxml/item[2]/item[$i])
            return
                if(matches($link,"weber-gesamtausgabe.de")) then ()
                else map:entry($title, ($link, $text))
        )
};

(:~
 : Identity transformation with stripping off XML comments and processing instructions
 :
 : @author Peter Stadler 
 : @param $nodes the nodes to transform
 : @return transformed nodes
 :)
declare function wega-util:remove-comments($nodes as node()*) as node()* {
    for $node in $nodes
    return
        if($node instance of processing-instruction()) then ()
        else if($node instance of comment()) then ()
        else if($node instance of element()) then 
            element {node-name($node)} {
                $node/@*,
                wega-util:remove-comments($node/node())
            }
        else if($node instance of document-node()) then wega-util:remove-comments($node/node())
        else $node
};

(:~
 : Helper function for guessing a mime-type from a file extension
 :
 : @author Peter Stadler 
 : @param $suffix the file extension
 : @return the mime-type
 :)
declare function wega-util:guess-mimeType-from-suffix($suffix as xs:string) as xs:string? {
    switch($suffix)
        case 'xml' return 'application/xml'
        case 'jpg' return 'image/jpeg'
        case 'png' return 'image/png'
        default return error(xs:QName(wega-util:error), 'unknown file suffix "' || $suffix || '"')
};

declare function wega-util:doc-available($uri as xs:string?) as xs:boolean {
    try {doc-available($uri)}
    catch * {false()}
};
