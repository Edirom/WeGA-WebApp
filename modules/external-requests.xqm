xquery version "3.1" encoding "UTF-8";

(:~
 : XQuery module for querying external service provider
 :)
module namespace er="http://xquery.weber-gesamtausgabe.de/modules/external-requests";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace wega="http://www.weber-gesamtausgabe.de";
declare namespace http="http://expath.org/ns/http-client";
declare namespace math="http://www.w3.org/2005/xpath-functions/math";
declare namespace owl="http://www.w3.org/2002/07/owl#";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs="http://www.w3.org/2000/01/rdf-schema#";
declare namespace sr="http://www.w3.org/2005/sparql-results#";
declare namespace schema="http://schema.org/";

import module namespace functx="http://www.functx.com";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";
import module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util" at "wega-util.xqm";
import module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/date.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/str.xqm";
import module namespace mycache="http://xquery.weber-gesamtausgabe.de/modules/cache" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/cache.xqm";
import module namespace wega-util-shared="http://xquery.weber-gesamtausgabe.de/modules/wega-util-shared" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/wega-util-shared.xqm";


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
declare function er:grabExternalResource($resource as xs:string, $gnd as xs:string, $docType as xs:string, $lang as xs:string?) as element(er:response)? {
    let $lease := function($currentDateTimeOfFile as xs:dateTime?) as xs:boolean { wega-util:check-if-update-necessary($currentDateTimeOfFile, ()) }
    (: Prevent the grabbing of external resources when a web crawler comes around … :)
    let $botPresent := er:bot-present()
    let $url := 
        switch($resource)
        case 'wikipediaVIAF' return (er:grab-external-resource-wikidata($gnd, 'viaf')//sr:binding[@name=('article' || upper-case($lang))]/sr:uri/data(.))[1]
        case 'wikipedia' return (er:grab-external-resource-wikidata($gnd, 'gnd')//sr:binding[@name=('article' || upper-case($lang))]/sr:uri/data(.))[1]
        case 'dnb' return concat('http://d-nb.info/gnd/', $gnd, '/about/rdf')
        case 'viaf' return concat('https://viaf.org/viaf/', $gnd, '.rdf')
        case 'geonames' return concat('http://sws.geonames.org/', $gnd, '/about.rdf') (: $gnd is actually the geonames ID :)
        case 'dbpedia' return concat('http://www.wikidata.org/entity/', $gnd, '.rdf') (: $gnd is actually the dbpedia(wikidata?) ID :)
        case 'deutsche-biographie' return 'https://www.deutsche-biographie.de/gnd' || $gnd || '.html'
        default return config:get-option($resource) || $gnd
    let $fileName := string-join(($gnd, $lang, 'xml'), '.')
    let $onFailureFunc := function($errCode, $errDesc) {
        core:logToFile('warn', string-join(($errCode, $errDesc), ' ;; '))
    }
    let $response := 
        if($botPresent or not($url)) then ()
        else mycache:doc(str:join-path-elements(($config:tmp-collection-path, $resource, $fileName)), er:http-get#1, xs:anyURI($url), $lease, $onFailureFunc)
    return 
        if($response//er:response/@statusCode eq '200') 
        then $response//er:response
        else ()
};

declare function er:grab-external-resource-via-beacon($beaconProvider as xs:string, $gnd as xs:string) as element(er:response)? {
    let $uri := er:lookup-gnd-from-beaconProvider($beaconProvider, $gnd)
    let $fileName := $gnd || '.xml'
    let $localFilePath := str:join-path-elements(($config:tmp-collection-path, encode-for-uri($beaconProvider), $fileName))
    return
        if(er:bot-present() or not($uri)) 
        then ()
        else er:cached-external-request($uri, $localFilePath)
};

(:~
 : Query the Wikidata API for images and mappings for a given authority ID (e.g. Geonames, GND)
 : 
 : @param $id some external authority ID (e.g. Geonames, GND)
 : @param $authority-provider the respective authority-provider string (e.g. 'geonames', or 'gnd')
 : @return a er:response element if successful, the empty sequence otherwise. For a description of the `er:response` element
 :      see http://expath.org/modules/http-client/
 :)
declare function er:grab-external-resource-wikidata($id as xs:string, $authority-provider as xs:string) as element(er:response)? {
    let $uri := er:wikidata-url($id, $authority-provider)
    let $fileName := util:hash($uri, 'md5') || '.xml'
    return
        if(er:bot-present() or not($uri)) 
        then ()
        else er:cached-external-request($uri, str:join-path-elements(($config:tmp-collection-path, 'wikidata', $fileName)))
};

(:~
 : Lookup gnd IDs in BEACON files 
 :)
declare function er:lookup-gnd-from-beaconProvider($beaconProvider as xs:string, $gnd as xs:string) as xs:anyURI? {
    let $beaconURI := config:get-option($beaconProvider)
    return
        if($beaconURI castable as xs:anyURI)
        then er:lookup-gnd-from-beaconURI($beaconURI, $gnd)
        else ()
};

(:~
 : Lookup gnd IDs in BEACON files 
 :)
declare function er:lookup-gnd-from-beaconURI($beaconURI as xs:anyURI, $gnd as xs:string) as xs:anyURI? {
    let $lease := function($currentDateTimeOfFile as xs:dateTime?) as xs:boolean { wega-util:check-if-update-necessary($currentDateTimeOfFile, ()) }
    let $onFailureFunc := function($errCode, $errDesc) {
            core:logToFile('warn', string-join(($errCode, $errDesc), ' ;; '))
        }
    let $filename := util:hash($beaconURI, 'md5') || '.xml'
    let $localFilePath := str:join-path-elements(($config:tmp-collection-path, 'beaconFiles', $filename))
    let $beacon := mycache:doc($localFilePath, er:parse-beacon#1, $beaconURI, $lease, $onFailureFunc)
    let $uri := $beacon/id(concat('_', $gnd))
    return 
        if($uri castable as xs:anyURI) 
        then xs:anyURI($uri) 
        else ()
};

(:~
 :  Make a request to linked data resources
 :  This is in fact a wrapper function around the expath `http:send-request` method, see http://expath.org/modules/http-client/
 : 
 :  @param $elem an element (e.g. `<gndo:formOfWorkAndExpression rdf:resource="http://d-nb.info/gnd/4043582-9"/>`) bearing 
 :      an `@rdf:resource` attribute which indicates the resource to fetch
 :  @return an er:response element if successful, the empty sequence otherwise. For a description of the `er:response` element
 :      see http://expath.org/modules/http-client/
~:)
declare function er:resolve-rdf-resource($elem as element()) as element(er:response)? {
    let $uri := 
        if(starts-with($elem/@rdf:resource, 'http://d-nb.info/gnd')) then ($elem/@rdf:resource || '/about/lds.rdf')
        else if(starts-with($elem/@rdf:resource, 'http://dbpedia.org/resource/')) then (replace($elem/@rdf:resource, 'resource', 'data') || '.rdf')
        else ()
    let $filename := util:hash($uri, 'md5') || '.xml'
    return
        if($uri castable as xs:anyURI) 
        then er:cached-external-request($uri, str:join-path-elements(($config:tmp-collection-path, 'rdf', $filename)))
        else ()
};

(:~
 : Helper function for wega:grabExternalResource()
 :
 : @author Peter Stadler 
 : @param $url the URL as xs:anyURI
 : @return element wega:externalResource, a wrapper around er:response
 :)
declare function er:http-get($url as xs:anyURI) as element(wega:externalResource) {
    let $req := <http:request href="{$url}" method="get" timeout="3"><http:header name="Connection" value="close"/></http:request>
    let $response := 
        try { http:send-request($req) }
        catch * {core:logToFile(if(contains($err:description, 'Read timed out')) then 'info' else 'warn', string-join(('er:http-get', $err:code, $err:description, 'URL: ' || $url), ' ;; '))}
    let $statusCode := $response[1]/data(@status)
    return
        <wega:externalResource date="{current-date()}">
            <er:response statusCode="{$statusCode}">
                <er:headers>{
                    for $header in $response[1]//http:header
                    return element er:header {$header/@*}
                }</er:headers>
                <er:body mimetype="{$response[1]//http:body/data(@media-type)}">
                    {$response[2]}
                </er:body>
            </er:response>
        </wega:externalResource>
};


declare function er:wikimedia-iiif($wikiFilename as xs:string) as map(*)* {
    (: kanonische Adresse wäre eigentlich https://tools.wmflabs.org/zoomviewer/iiif.php?f=$DATEINAME$, bestimmte Weiterleitungen funktionieren dann aber nicht :)
    (: zum Dienst siehe https://github.com/toollabs/zoomviewer :)
    let $escapedWikiFilename := replace($wikiFilename, ' ', '_')
    let $url := 'https://tools.wmflabs.org/zoomviewer/proxy.php?iiif=' || $escapedWikiFilename || '/info.json'
    let $lease := function($currentDateTimeOfFile as xs:dateTime?) as xs:boolean { wega-util:check-if-update-necessary($currentDateTimeOfFile, ()) }
    let $fileName := util:hash($escapedWikiFilename, 'md5') || '.xml'
    let $onFailureFunc := function($errCode, $errDesc) {
        core:logToFile('warn', string-join(($errCode, $errDesc), ' ;; '))
    }
    let $response := mycache:doc(str:join-path-elements(($config:tmp-collection-path, 'iiif', $fileName)), er:http-get#1, xs:anyURI($url), $lease, $onFailureFunc)
    return 
        if($response//er:response/@statusCode eq '200') then 
            try { parse-json(util:binary-to-string($response//er:body)) }
            catch * {core:logToFile('warn', string-join(('er:wikimedia-ifff', $err:code, $err:description, 'wikiFilename: ' || $wikiFilename), ' ;; '))}
        else ()
};


(:~
 : Make a (locally) cached request to an external URI
 : This is the 2-arity version, using defaults for $lease and $onFailureFunc
 :
 : @param $uri the external URI to fetch
 : @param $localFilepath the filepath to store the cached document
 : @return a er:response element with the response stored within er:body if successful, the empty sequence otherwise
 :)
declare function er:cached-external-request($uri as xs:anyURI, $localFilepath as xs:string) as element(er:response)? {
    let $lease := function($currentDateTimeOfFile as xs:dateTime?) as xs:boolean { wega-util:check-if-update-necessary($currentDateTimeOfFile, ()) }
    let $onFailureFunc := function($errCode, $errDesc) {
            core:logToFile('warn', string-join(($errCode, $errDesc), ' ;; '))
        }
    return
        er:cached-external-request($uri, $localFilepath, $lease, $onFailureFunc)
};

(:~
 : Make a (locally) cached request to an external URI
 : This is the full fledged 4-arity version
 :
 : @param $uri the external URI to fetch
 : @param $localFilepath the filepath to store the cached document
 : @param $lease a function to determine wether the cache should be updated. Must return a boolean value
 : @param $onFailureFunc an on-error function that's passed on to the underlying mycache:doc() function 
 : @return a er:response element with the response stored within er:body if successful, the empty sequence otherwise
 :)
declare function er:cached-external-request($uri as xs:anyURI, $localFilepath as xs:string, $lease as function() as xs:boolean, $onFailureFunc as function() as item()*) as element(httpclient:response)? {
    mycache:doc($localFilepath, er:http-get#1, $uri, $lease, $onFailureFunc)//er:response[@statusCode = '200']
};


(:~
 : construct wikidata query URL
 : (Helper function for er:grabExternalResource())
~:)
declare %private function er:wikidata-url($id as xs:string, $authority-provider as xs:string) as xs:anyURI {
    (:  
    see https://query.wikidata.org/ 
    and https://www.wikidata.org/wiki/Wikidata:SPARQL_query_service/Wikidata_Query_Help 
    :)
    let $properties := map {
        'geonames': 'wdt:P1566',
        'gnd': 'wdt:P227',
        'viaf': 'wdt:P214'
    }
    let $propFrom := $properties($authority-provider)
    let $sparql-query := encode-for-uri(
        'SELECT ?item ?viaf ?gnd ?geonames ?wappenbild ?flaggenbild ?image ?articleDE ?articleEN WHERE '
        || '{ ?item ' || $propFrom ||' "' || str:normalize-space($id) || '". '
        || 'OPTIONAL { ?item ' || $properties?geonames || ' ?geonames. } '
        || 'OPTIONAL { ?item ' || $properties?gnd || ' ?gnd. } '
        || 'OPTIONAL { ?item ' || $properties?viaf || ' ?viaf. } '
        || 'OPTIONAL { ?item ' || 'wdt:P94' || ' ?wappenbild. } '
        || 'OPTIONAL { ?item ' || 'wdt:P41' || ' ?flaggenbild. } '
        || 'OPTIONAL { ?item ' || 'wdt:P18' || ' ?image. } '
        || 'OPTIONAL { ?articleDE schema:about ?item ; schema:isPartOf <https://de.wikipedia.org/> ;  schema:name ?page_titleDE . } '
        || 'OPTIONAL { ?articleEN schema:about ?item ; schema:isPartOf <https://en.wikipedia.org/> ;  schema:name ?page_titleEN . } '
        || '}')
    let $sparql-endpoint := "https://query.wikidata.org/sparql?format=xml&amp;query="
    return
        xs:anyURI($sparql-endpoint || $sparql-query) 
};

(:~
 : Simple test for a bot request by checking the HTTP User-Agent header
 :
 :)
declare %private function er:bot-present() as xs:boolean {
    matches(request:get-header('User-Agent'), 'Baiduspider|Yandex|MegaIndex|AhrefsBot|HTTrack|bingbot|Googlebot|cliqzbot|DotBot|SemrushBot|MJ12bot', 'i')
};

(:~
 : Helper function for fetching and parsing a plain text BEACON file into an XML structure
 :)
declare %private function er:parse-beacon($beaconURI as xs:anyURI) as element(er:beacon) {
    let $beacon := er:http-get($beaconURI)
    let $lines := 
        if($beacon//er:response/@statusCode eq '200')
        then tokenize($beacon//er:body, '\n')
        else ()
    let $target := $lines[starts-with(., '#TARGET:')] ! normalize-space(substring-after(., '#TARGET:'))
    (: GND ID regex taken from https://www.wikidata.org/wiki/Property:P227 :)
    let $gnd-regex := '1[01]?\d{7}[0-9X]|[47]\d{6}-\d|[1-9]\d{0,7}-[0-9X]|3\d{7}[0-9X]'
    let $gnds := $lines[matches(normalize-space(.), $gnd-regex)] ! analyze-string(., $gnd-regex)/fn:match/text()
    return 
        <er:beacon>{
            for $meta in $lines[starts-with(., '#')]
            return
                element {
                    QName('http://xquery.weber-gesamtausgabe.de/modules/external-requests', lower-case(substring-before(substring($meta, 2), ':')))
                }{
                    normalize-space(substring-after($meta, ':'))
                },
            for $gnd in $gnds
            return
                <er:gnd>{
                    attribute {'xml:id'} {'_' || $gnd},
                    replace($target, '\{ID\}', $gnd)
                }</er:gnd>
        }</er:beacon>
};
