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
declare namespace math="http://www.w3.org/2005/xpath-functions/math";
declare namespace owl="http://www.w3.org/2002/07/owl#";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs="http://www.w3.org/2000/01/rdf-schema#";
declare namespace schema="http://schema.org/";

import module namespace functx="http://www.functx.com";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";
import module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/date.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/str.xqm";
import module namespace cache="http://xquery.weber-gesamtausgabe.de/modules/cache" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/cache.xqm";

(:~
 : Get resources from the web by PND and store the result in a cache object with the current date. 
 : If the date does match with today's date then the result will be taken from the cache; otherwise the external resource will be queried.
 :
 : @author Peter Stadler 
 : @param $resource the external resource (wikipedia|adb|dnb|beacon)
 : @param $gnd the PND number
 : @param $lang the language variable (de|en). If no language is specified, the default (German) resource is grabbed and served
 : @param $useCache use cached version or force a reload of the external resource
 : @return node
 :)
declare function wega-util:grabExternalResource($resource as xs:string, $gnd as xs:string, $docType as xs:string, $lang as xs:string?) as element(httpclient:response)? {
    let $lease := 
        try { config:get-option('lease-duration') cast as xs:dayTimeDuration }
        catch * { xs:dayTimeDuration('P1D'), core:logToFile('error', string-join(('wega-util:grabExternalResource', $err:code, $err:description, config:get-option('lease-duration') || ' is not of type xs:dayTimeDuration'), ' ;; '))}
    (: Prevent the grabbing of external resources when a web crawler comes around … :)
    let $botPresent := matches(request:get-header('User-Agent'), 'Baiduspider|Yandex|MegaIndex|AhrefsBot|HTTrack|bingbot|Googlebot|cliqzbot|DotBot|SemrushBot|MJ12bot', 'i')
    let $url := 
        switch($resource)
        case 'wikipedia' return
            let $beaconMap := wega-util:beacon-map($gnd, $docType)
            let $url := $beaconMap(map:keys($beaconMap)[contains(., 'Wikipedia-Personenartikel')][1])[1]
            return
                replace($url, '/gnd/de/', '/gnd/' || $lang || '/')
        case 'dnb' return concat('http://d-nb.info/gnd/', $gnd, '/about/rdf')
        case 'viaf' return concat('https://viaf.org/viaf/', $gnd, '.rdf')
        case 'geonames' return concat('http://sws.geonames.org/', $gnd, '/about.rdf')
        case 'deutsche-biographie' return 'https://www.deutsche-biographie.de/gnd' || $gnd || '.html'
        default return config:get-option($resource) || $gnd
    let $fileName := string-join(($gnd, $lang, 'xml'), '.')
    let $onFailureFunc := function($errCode, $errDesc) {
        core:logToFile('warn', string-join(($errCode, $errDesc), ' ;; '))
    }
    let $response := 
        if($botPresent) then ()
        else
            (: Because the EXPath http client is very picky about HTTPS certificates, we need to use the standard httpclient module for the munich-stadtmuseum which uses HTTPS :)
            switch($resource)
            case 'munich-stadtmuseum' return cache:doc(str:join-path-elements(($config:tmp-collection-path, $resource, $fileName)), wega-util:httpclient-get#1, xs:anyURI($url), $lease, $onFailureFunc)
            default return cache:doc(str:join-path-elements(($config:tmp-collection-path, $resource, $fileName)), wega-util:http-get#1, xs:anyURI($url), $lease, $onFailureFunc)
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
        try { http:send-request($req) }
        catch * {core:logToFile(if(contains($err:description, 'Read timed out')) then 'info' else 'warn', string-join(('wega-util:http-get', $err:code, $err:description, 'URL: ' || $url), ' ;; '))}
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

(:~
 : Helper function for wega:grabExternalResource()
 :
 : @author Peter Stadler 
 : @param $url the URL as xs:anyURI
 : @return element wega:externalResource, a wrapper around httpclient:response
 :)
declare function wega-util:httpclient-get($url as xs:anyURI) as element(wega:externalResource) {
    let $response := 
        try { httpclient:get($url, true(), <headers><header name="Connection" value="close"/></headers>)  }
        catch * {core:logToFile('warn', string-join(('wega-util:httpclient-get', $err:code, $err:description, 'URL: ' || $url), ' ;; '))}
    (:let $response := 
        if($response/httpclient:body[matches(@mimetype,"text/html")]) then wega:changeNamespace($response,'http://www.w3.org/1999/xhtml', 'http://exist-db.org/xquery/httpclient')
        else $response:)
(:    let $statusCode := $response[1]/data(@status):)
    return
        <wega:externalResource date="{current-date()}">
            { $response }
        </wega:externalResource>
};

declare function wega-util:beacon-map($gnd as xs:string, $docType as xs:string) as map(*) {
    let $findbuchResponse := 
        switch($docType)
        case 'persons' return wega-util:grabExternalResource('beacon', $gnd, $docType, 'de')
        default return wega-util:grabExternalResource('gnd-beacon', $gnd, $docType, 'de')
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
 : Processing XML files for display (and download)
 : Comments and not-whitelisted facsimile information will be removed
 :
 : @author Peter Stadler 
 : @param $nodes the nodes to transform
 : @return transformed nodes
~:)
declare function wega-util:process-xml-for-display($nodes as node()*) as node()* {
    for $node in $nodes
    return
        typeswitch($node)
        case comment() return 
            if($config:isDevelopment) then $node
            else ()
        case element(tei:facsimile) return 
            let $facsimile := query:facsimile($node/root())
            return
                if($facsimile) then 
                    element {node-name($node)} {
                        $node/@*,
                        wega-util:process-xml-for-display($facsimile/node())
                    }
                else ()
        case element() return 
            element {node-name($node)} {
                $node/@*,
                wega-util:process-xml-for-display($node/node())
            }
        case document-node() return wega-util:process-xml-for-display($node/node())
        default return $node
};

(:~
 : Add current version information to a TEI file
 : If the file contains a tei:fileDesc a tei:editionStmt is injected,
 : otherwise a comment is written after the root element 
 :
 : @author Peter Stadler 
 : @param $nodes the nodes to transform
 : @return transformed nodes
 :)
declare function wega-util:inject-version-info($nodes as node()*) as item()* {
    for $node in $nodes
    return
        if($node instance of processing-instruction()) then (
            (: replace the schema location from development to current stable version :)
            if($node[ancestor::node()]) then $node
            else (
                processing-instruction xml-model {replace($node, '(master|develop)', 'v' || config:get-option('ODDversion'))}
            )
        )
        (: inject editionStmt element after the titleStmt :)
        else if($node instance of element(tei:titleStmt)) then (
            if($node/parent::tei:fileDesc/parent::tei:teiHeader/parent::tei:TEI) then ( (: make sure we're dealing with the right titleStmt :)
                let $editionStmt := wega-util:editionStmt()
                return (
                    $node,
                    '&#10;&#9;&#9;&#9;', (: Indentation :)
                    element {QName('http://www.tei-c.org/ns/1.0', 'editionStmt')} {
                        '&#10;&#9;&#9;&#9;&#9;',
                        element {QName('http://www.tei-c.org/ns/1.0', 'p')} {
                            $editionStmt?version
                        },
                        '&#10;&#9;&#9;&#9;&#9;',
                        element {QName('http://www.tei-c.org/ns/1.0', 'p')} {
                            $editionStmt?download
                        },
                        '&#10;&#9;&#9;&#9;'
                    }
                )
            )
            else $node
        )
        
        else if($node instance of element(tei:text)) then $node (: shortcut :)
        
        (: inject version information as comment after the root element :)
        else if($node instance of element(tei:ab)) then wega-util:editionStmt2comment($node)
        else if($node instance of element(tei:person)) then wega-util:editionStmt2comment($node)
        else if($node instance of element(tei:place)) then wega-util:editionStmt2comment($node)
        else if($node instance of element(tei:biblStruct)) then wega-util:editionStmt2comment($node)
        else if($node instance of element(tei:org)) then wega-util:editionStmt2comment($node)
        
        (: fallback: identity transformation :)
        else if($node instance of element()) then 
            element {node-name($node)} {
                $node/@*,
                wega-util:inject-version-info($node/node())
            }
        else if($node instance of document-node()) then wega-util:inject-version-info($node/node())
        else $node
};

(:~
 : Helper function for wega-util:inject-version-info()
~:)
declare %private function wega-util:editionStmt() as map() {
    let $lang := config:guess-language(())
    return
        map {
            'version' :=    lang:get-language-string(
                                'versionInformation', (
                                    config:get-option('version'), 
                                    date:format-date(xs:date(config:get-option('versionDate')), $config:default-date-picture-string($lang), $lang)
                                ), 
                                $lang
                            ),
            'download' := lang:get-language-string('downloaded_on', $lang) || ': ' || current-dateTime()
        }
};

(:~
 : Helper function for wega-util:inject-version-info()
~:)
declare %private function wega-util:editionStmt2comment($node as node()?) as node()? {
    if($node[ancestor::node()]) then $node
    else (
        let $editionStmt := wega-util:editionStmt()
        return (
            element {node-name($node)} {
                $node/@*,
                comment {$editionStmt?version || '. ' || $editionStmt?download },
                $node/node()
            }
        )
    )
};

(:~
 : Recursively remove idiosyncratic WeGA elements ('workName', 'characterName') and turn them into generic TEI <rs> elements
 :
 : @author Peter Stadler 
 : @param $nodes the nodes to transform
 : @return transformed nodes
~:)
declare function wega-util:substitute-wega-element-additions($nodes as node()*) as node()* {
    for $node in $nodes
    return
        if($node instance of processing-instruction()) then $node
        else if($node instance of comment()) then $node
        else if($node instance of element(tei:workName) or $node instance of element(tei:characterName)) then
            element {QName('http://www.tei-c.org/ns/1.0', 'rs')} {
                $node/@*,
                attribute type { substring-before(local-name($node), 'Name') },
                wega-util:substitute-wega-element-additions($node/node())
            }
        else if($node instance of element()) then 
            element {node-name($node)} {
                $node/@*,
                wega-util:substitute-wega-element-additions($node/node())
            }
        else if($node instance of document-node()) then wega-util:substitute-wega-element-additions($node/node())
        else $node
};

declare function wega-util:wikimedia-iiif($wikiFilename as xs:string) as map(*)* {
    (: kanonische Adresse wäre eigentlich https://tools.wmflabs.org/zoomviewer/iiif.php?f=$DATEINAME$, bestimmte Weiterleitungen funktionieren dann aber nicht :)
    (: zum Dienst siehe https://github.com/toollabs/zoomviewer :)
    let $escapedWikiFilename := replace($wikiFilename, ' ', '_')
    let $url := 'https://tools.wmflabs.org/zoomviewer/proxy.php?iiif=' || $escapedWikiFilename || '/info.json'
    let $lease := xs:dayTimeDuration('P1D')
    let $fileName := util:hash($escapedWikiFilename, 'md5') || '.xml'
    let $onFailureFunc := function($errCode, $errDesc) {
        core:logToFile('warn', string-join(($errCode, $errDesc), ' ;; '))
    }
    let $response := cache:doc(str:join-path-elements(($config:tmp-collection-path, 'iiif', $fileName)), wega-util:http-get#1, xs:anyURI($url), $lease, $onFailureFunc)
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

(:~
 : Creates a simple text version of a TEI document (or fragment)
 : by resolving choices, substitutions and removing notes
 : (used for e.g. wordOfTheDay and several titles)
 :
 : @param $nodes the nodes to transform
~:)
declare function wega-util:txtFromTEI($nodes as node()*) as xs:string* {
    for $node in $nodes
    return
        typeswitch($node)
        case element(tei:forename) return 
        	if($node/@cert) then ($node/child::node() ! wega-util:txtFromTEI(.), '(?)') 
        	else $node/child::node() ! wega-util:txtFromTEI(.)
        case element(tei:del) return ()
        case element(tei:subst) return $node/child::element() ! wega-util:txtFromTEI(.)
        case element(tei:note) return ()
        case element(tei:lb) return 
            if($node[@type='inWord']) then ()
            else '&#10;'
        case element(tei:pb) return 
            if($node[@type='inWord']) then ()
            else ' '
        case element(tei:q) return str:enquote($node/child::node() ! wega-util:txtFromTEI(.), config:guess-language(()))
        case element(tei:quote) return 
            if($node[@rend='double-quotes']) then str:enquote($node/child::node() ! wega-util:txtFromTEI(.), config:guess-language(()))
            else str:enquote-single($node/child::node() ! wega-util:txtFromTEI(.), config:guess-language(()))
        case element(tei:supplied) return ('[', $node/child::node() ! wega-util:txtFromTEI(.), ']') 
        case text() return replace($node, '\n+', ' ')
        case document-node() return $node/child::node() ! wega-util:txtFromTEI(.) 
        case processing-instruction() return ()
        case comment() return ()
        default return $node/child::node() ! wega-util:txtFromTEI(.)
};

(:~
 : Removes descendant elements from all of the nodes in $nodes based on the class name.
 : Inspired by functx:remove-elements-deep
~:)
declare function wega-util:remove-elements-by-class($nodes as node()*, $classes as xs:string*) as node()* {
	if($nodes/descendant-or-self::*[@class = tokenize($classes, '\s+')]) then
	    for $node in $nodes
	    return
	        typeswitch($node)
	        case element() return
	            if ($node[@class = tokenize($classes, '\s+')]) then ()
	            else 
	                element { node-name($node) } { 
	                    $node/@*,
	                    wega-util:remove-elements-by-class($node/node(), $classes)
	                }
	        case document-node() return wega-util:remove-elements-by-class($node/node(), $classes)
	        default return $node
    else $nodes
};

(:~
 : Helper function for computing geo loc distances 
~:)
declare %private function wega-util:deg2rad($deg as xs:double) as xs:double {
   $deg * ( math:pi() div 180 )
};

(:~
 : The haversine distance of two points on the Earth
 : NB: The implementation seems buggy!
 : Compare with http://www.movable-type.co.uk/scripts/latlong.html
~:)
declare function wega-util:haversine-distance($lat1 as xs:double, $lon1 as xs:double, $lat2 as xs:double, $lon2 as xs:double) as xs:double {
   let $radius-of-earth := 6371 (: Radius of the earth in km :)
   let $p := 0.017453292519943295 (: Math.PI / 180 :)
   let $dLat := $lat2 - $lat1 (:local:deg2rad($lat2 - $lat1):)
   let $dLon := $lon2 - $lon1 (:local:deg2rad($lon2 - $lon1):)
   let $a :=
      0.5 - math:cos($dLat * $p) div 2 +
      math:cos($lat1 * $p) * math:cos($lat2 * $p) *
      (1 - math:cos($dLon * $p)) div 2
   return
      2 * $radius-of-earth * math:sin(math:sqrt($a))
};

(:~
 : The "Spherical Law of Cosines" distance of two points on the Earth
 : Outlined at http://www.movable-type.co.uk/scripts/latlong.html
~:)
declare function wega-util:spherical-law-of-cosines-distance($latLon1 as array(*), $latLon2 as array(*)) as xs:double {
   let $radius-of-earth := 6371 (: Radius of the earth in km :)
   let $dLon := wega-util:deg2rad($latLon2(2) - $latLon1(2))
   let $a :=
      math:sin(wega-util:deg2rad($latLon1(1))) * math:sin(wega-util:deg2rad($latLon2(1))) +
      math:cos(wega-util:deg2rad($latLon1(1))) * math:cos(wega-util:deg2rad($latLon2(1))) *
      math:cos($dLon)
   return
      math:acos($a) * $radius-of-earth 
};

declare function wega-util:distance-between-places($placeID1 as xs:string, $placeID2 as xs:string) as xs:double {
   let $places := core:getOrCreateColl('places', 'indices', true())
   let $latLon1 := array { tokenize($places/id($placeID1)//tei:geo, '\s+') ! . cast as xs:double }
   let $latLon2 := array { tokenize($places/id($placeID2)//tei:geo, '\s+') ! . cast as xs:double }
   return 
      wega-util:spherical-law-of-cosines-distance($latLon1, $latLon2)
};

(:~
 :  Lookup viaf ID by calling an external service.
 :  Currently, we are using the rdf serialization from the DNB.
~:)
declare function wega-util:gnd2viaf($gnd as xs:string) as xs:string* {
    wega-util:grabExternalResource('dnb', $gnd, '', ())//owl:sameAs/@rdf:resource[starts-with(., 'http://viaf.org/viaf/')]/substring(., 22)
};

(:~
 :  Lookup gnd ID by calling an external service.
 :  Currently, we are using the rdf serialization from viaf.org.
~:)
declare function wega-util:viaf2gnd($viaf as xs:string) as xs:string* {
    wega-util:grabExternalResource('viaf', $viaf, '', ())//schema:sameAs/@rdf:resource[starts-with(., 'http://d-nb.info/gnd/')]/substring(., 22)
};

(:~
 :  Map geonames ID to gnd ID by calling an external service.
 :  Currently, we are using the rdf serialization from geonames.org.
~:)
declare function wega-util:geonames2gnd($geonames-id as xs:string) as xs:string* {
    let $dbpedia-rdf := wega-util:dbpedia-from-geonames($geonames-id)
    return
        (: ther might be multiple sameAs relations to the GND, see e.g. Altona A130064 :)
        if($dbpedia-rdf//owl:sameAs/@rdf:resource[starts-with(., 'http://d-nb.info/gnd/')]) then ($dbpedia-rdf//owl:sameAs/@rdf:resource[starts-with(., 'http://d-nb.info/gnd/')])[1]/substring-after(., 'http://d-nb.info/gnd/')
        else ()
};

(:~
 :  Grab dbpedia rdf for a place by geonames ID
~:)
declare function wega-util:dbpedia-from-geonames($geonames-id as xs:string) as node()* {
    let $dbpedia-url := wega-util:grabExternalResource('geonames', $geonames-id, '', ())//rdfs:seeAlso/data(@rdf:resource)
    let $lease := 
        try { config:get-option('lease-duration') cast as xs:dayTimeDuration }
        catch * { xs:dayTimeDuration('P1D'), core:logToFile('error', string-join(('wega-util:grabExternalResource', $err:code, $err:description, config:get-option('lease-duration') || ' is not of type xs:dayTimeDuration'), ' ;; '))}
    let $onFailureFunc := function($errCode, $errDesc) {
        core:logToFile('warn', string-join(($errCode, $errDesc), ' ;; '))
    }
    let $dbpedia-rdf := 
        for $i in $dbpedia-url
        return cache:doc(str:join-path-elements(($config:tmp-collection-path, 'dbpedia', 'gn_' || $geonames-id || '.rdf')), wega-util:http-get#1, xs:anyURI(replace($i, 'resource', 'data') || '.rdf'), $lease, $onFailureFunc)
    return
        $dbpedia-rdf//httpclient:response[@statusCode = '200']
};

(:~
 : create a flattened version of strings without diacritics, e.g. "Méhul" --> "Mehul"
 : see http://exist.2174344.n4.nabble.com/stripping-diacritics-with-fn-normalize-unicode-tp4657960.html
~:)
declare function wega-util:strip-diacritics($str as xs:string*) as xs:string* {
    for $i in $str
    return replace(normalize-unicode($i, 'NFKD'),  '[\p{M}]', '')
};
