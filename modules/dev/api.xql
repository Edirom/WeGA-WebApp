xquery version "3.0" encoding "UTF-8";

(:~
 : WeGA API functions
 :
 : @author Peter Stadler 
 : @version 1.0
 :)
 
declare default collation "?lang=de;strength=primary";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace session = "http://exist-db.org/xquery/session";
declare namespace xmldb = "http://exist-db.org/xquery/xmldb";
declare namespace cache = "http://exist-db.org/xquery/cache";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace request="http://exist-db.org/xquery/request";
import module namespace functx="http://www.functx.com";
import module namespace wega="http://xquery.weber-gesamtausgabe.de/modules/wega" at "../wega.xqm";
import module namespace dev="http://xquery.weber-gesamtausgabe.de/modules/dev" at "dev.xqm";
(:import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "../config.xqm";:)
(:import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "../core.xqm";:)


declare function local:get-reg-name($params as map(*)) as xs:string {
    wega:getRegName($params('id'))
};

declare function local:get-new-id($params as map(*)) as xs:string {
    dev:createNewID($params('docType'))
};

declare function local:serialize-xml($response as item()*) {
    let $serializationParameters := ('method=xml', 'media-type=application/xml', 'indent=no', 'omit-xml-declaration=no', 'encoding=utf-8')
    let $setHeader1 := response:set-header('cache-control','max-age=0, no-cache, no-store')
    let $setHeader2 := response:set-header('pragma','no-cache')
    let $setHeader3 := 
        if($response) then response:set-header('ETag', util:hash($response, 'md5'))
        else () (: some errors with the hash function?!? :)
    return 
        response:stream(
            <wega-api-result xmlns="http://xquery.weber-gesamtausgabe.de/api">
                {$response}
            </wega-api-result>,
            string-join($serializationParameters, ' ')
        )
};

let $func := request:get-parameter('func', '')
let $format := request:get-parameter('format', 'xml')
let $params := 
    map:new(
        for $i in request:get-parameter-names()
        return
            map:entry($i, request:get-parameter($i, ''))
    )
let $response := 
    try {
        function-lookup(xs:QName('local:' || $func), 1)($params)
    } catch * {
        ()
    }
return 
    local:serialize-xml($response)