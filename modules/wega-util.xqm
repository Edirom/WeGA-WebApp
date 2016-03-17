xquery version "3.1" encoding "UTF-8";

(:~
 : Various utility functions for the WeGA WebApp
:)
module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util";
declare default collation "?lang=de;strength=primary";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace httpclient = "http://exist-db.org/xquery/httpclient";
declare namespace wega="http://www.weber-gesamtausgabe.de";
declare namespace http="http://expath.org/ns/http-client";

import module namespace functx="http://www.functx.com";
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
    let $lease := 
        try { config:get-option('lease-duration') cast as xs:dayTimeDuration }
        catch * { xs:dayTimeDuration('P1D'), core:logToFile('error', string-join(('wega-util:grabExternalResource', $err:code, $err:description, config:get-option('lease-duration') || ' is not of type xs:dayTimeDuration'), ' ;; '))}
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
    let $req := <http:request href="{$url}" method="get" timeout="3"><http:header name="Connection" value="close"/></http:request>
    let $response := 
        try { wega-util:stopwatch(http:send-request#1, $req, string($url)) }
        catch * {core:logToFile('warn', string-join(('wega-util:http-get', $err:code, $err:description, 'URL: ' || $url), ' ;; '))}
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
            if($findbuchResponse/httpclient:body/@encoding = 'Base64Encoded') then parse-json(util:binary-to-string($findbuchResponse))
            else parse-json($findbuchResponse)
        else ()
    return 
        if(exists($jxml)) then
            map:new(
                for $i in 1 to array:size($jxml?2)
                let $link  := str:normalize-space($jxml?4?($i))
                let $title := str:normalize-space($jxml?3?($i))
                let $text  := str:normalize-space($jxml?2?($i))
                return
                    if(matches($link,"weber-gesamtausgabe.de")) then ()
                    else map:entry($title, ($link, $text))
            )
        else map:new()
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

declare function wega-util:wikimedia-ifff($wikiFilename as xs:string) as map(*)* {
    let $url := 'https://tools.wmflabs.org/zoomviewer/iiif.php?f=' || $wikiFilename
    let $lease := xs:dayTimeDuration('P1D')
    let $fileName := util:hash($wikiFilename, 'md5') || '.xml'
    let $response := core:cache-doc(str:join-path-elements(($config:tmp-collection-path, 'iiif', $fileName)), wega-util:http-get#1, xs:anyURI($url), $lease)
    return 
        if($response//httpclient:response/@statusCode eq '200') then 
            try { parse-json(util:binary-to-string($response//httpclient:body)) }
            catch * {core:logToFile('warn', string-join(('wega-util:wikimedia-ifff', $err:code, $err:description, 'wikiFilename: ' || $wikiFilename), ' ;; '))}
        else ()
};

(:~
 : A wrapper function around eXist's transform:transform()
 : Applies a shortcut for empty and text only contents
~:)
declare function wega-util:transform($node-tree as node()*, $stylesheet as item(), $parameters as node()?) as item()* {
    if(every $i in $node-tree satisfies functx:all-whitespace($i)) then () 
    else if($node-tree/*) then transform:transform($node-tree, $stylesheet, $parameters)
    else $node-tree ! str:normalize-space(.)
};

(:~
 : A function for logging the query times
 :
 : @param $func the function to watch
 : @param $func-params the function parameters
 : @param $mesg an optional message to append for the logging
 : @return Timing information is written into the log file and the results of $func are returned 
~:)
declare function wega-util:stopwatch($func as function() as item(), $func-params as item()*, $mesg as xs:string?) as item()* {
    let $startTime := util:system-time()
    let $result := 
        if(count($func-params) eq 0) then $func()
        else if(count($func-params) eq 1) then $func($func-params)
        else if(count($func-params) eq 2) then $func($func-params[1], $func-params[2])
        else if(count($func-params) eq 3) then $func($func-params[1], $func-params[2], $func-params[3])
        else if(count($func-params) eq 4) then $func($func-params[1], $func-params[2], $func-params[3], $func-params[4])
        else error(xs:QName('wega-util:error'), 'Too many arguments to calback function of wega-util:stopwatch()')
    let $message := 
        if(exists($mesg)) then ' [' || $mesg || ']'
        else ()
    return (
        $result, 
        core:logToFile('debug', 'stopwatch (' || function-name($func) || '): ' || string(seconds-from-duration(util:system-time() - $startTime)) || $message)
    )
};

declare function wega-util:txtFromTEI($node as node()?) as xs:string* {
    typeswitch($node)
    case element() return 
        switch(local-name($node))
        case 'del' case 'note' return ()
        default return $node/child::node() ! wega-util:txtFromTEI(.)
    case text() return $node
    case document-node() return $node/child::node() ! wega-util:txtFromTEI(.) 
    default return ()
};
