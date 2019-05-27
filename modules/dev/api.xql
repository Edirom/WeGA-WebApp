xquery version "3.1" encoding "UTF-8";

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
declare namespace xmldb = "http://exist-db.org/xquery/xmldb";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace json-output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace kml="http://www.opengis.net/kml/2.2";
import module namespace functx="http://www.functx.com";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "../query.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "../config.xqm";
import module namespace dev="http://xquery.weber-gesamtausgabe.de/modules/dev" at "dev.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "../core.xqm";
import module namespace facets="http://xquery.weber-gesamtausgabe.de/modules/facets" at "../facets.xqm";
import module namespace search="http://xquery.weber-gesamtausgabe.de/modules/search" at "../search.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "../lang.xqm";
import module namespace controller="http://xquery.weber-gesamtausgabe.de/modules/controller" at "../controller.xqm";
import module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util" at "../wega-util.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/str.xqm";
import module namespace cache="http://xquery.weber-gesamtausgabe.de/modules/cache" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/cache.xqm";

declare function local:get-reg-name($params as map(*)) as xs:string {
    query:title($params('id'))
};

(:declare function local:get-new-id($params as map(*)) as xs:string {
    dev:createNewID($params('docType'))
};
:)
(:declare function local:get-diary-by-date($params as map(*)) as item() {
    let $ab := core:getOrCreateColl('diaries', 'indices', true())/tei:ab[@n=$params('date')][1]
    return
        if(exists($ab)) then 
            map {
                'id' := $ab/data(@xml:id),
                'url' := core:link-to-current-app(controller:path-to-resource($ab/root(), $params('lang')))
            }
        else 'No results'
};:)

declare function local:diaryDay-to-kml($params as map(*)) as element(kml:Placemark)+ {
    let $day := core:doc($params('docID'))/tei:ab
    let $places := tokenize($day/@where, '\s')[matches(., 'A13')]
    return
    <kml:kml>
        <kml:Folder>{
            for $place in $places
            let $placeEntry := collection('/db/apps/WeGA-data/places')/id($place)
            let $coord := string-join(reverse(tokenize($placeEntry//tei:geo, '\s+')), ',')
            return 
                <kml:Placemark>
                    <kml:name>{$day/string(@n)}</kml:name>
                    <kml:address>{$placeEntry/tei:placeName[@type='reg'] cast as xs:string}</kml:address>
                    <kml:TimeStamp><kml:when>{$day/string(@n)}</kml:when></kml:TimeStamp>
                    <kml:description>Tagebucheintrag vom { $day/string(@n)} (&lt;a href="{if($config:isDevelopment) then 'https://euryanthe.de/wega/' else 'http://weber-gesamtausgabe.de', $day/data(@xml:id)}"&gt;{$day/data(@xml:id)}&lt;/a&gt;).</kml:description>
                    <kml:Point>
                        <kml:coordinates>{$coord}</kml:coordinates>
                    </kml:Point>
                </kml:Placemark>
          }</kml:Folder>
    </kml:kml>
};

(:~
 :  Create BEACON files
 :  (see https://de.wikipedia.org/wiki/Wikipedia:BEACON)
~:)
declare function local:create-beacon($params as map(*)) as xs:string {
    let $callBack := function($type as xs:string) {
        let $pnds := 
            switch($type)
            case 'pnd' return core:data-collection('persons')//tei:idno[@type='gnd']
            case 'gkd' return core:data-collection('orgs')//tei:idno[@type='gnd']
            case 'works' return core:data-collection('works')//mei:altId[@type='gnd']
            default return ()
        let $desc := 
            switch($type)
            case 'pnd' return '#DESCRIPTION: Personendatensätze der Carl-Maria-von-Weber-Gesamtausgabe'
            case 'gkd' return '#DESCRIPTION: Datensätze Organisationen/Körperschaften der Carl-Maria-von-Weber-Gesamtausgabe'
            case 'works' return '#DESCRIPTION: Werkdatensätze der Carl-Maria-von-Weber-Gesamtausgabe'
            default return ()
        let $feed := 
            switch($type)
            case 'pnd' return '#FEED: http://weber-gesamtausgabe.de/pnd_beacon.txt'
            case 'gkd' return '#FEED: http://weber-gesamtausgabe.de/gkd_beacon.txt'
            case 'works' return '#FEED: http://weber-gesamtausgabe.de/works_beacon.txt'
            default return ()
        let $header := (
            '#FORMAT: BEACON',
            '#PREFIX: http://d-nb.info/gnd/',
            '#VERSION: 0.1',
            '#TARGET: https://weber-gesamtausgabe.de/de/gnd/{ID}',
            $feed,
            '#CONTACT: Peter Stadler <stadler [ at ] weber-gesamtausgabe.de>',
            '#INSTITUTION: Carl-Maria-von-Weber-Gesamtausgabe (WeGA)',
            $desc,
            concat('#TIMESTAMP: ', current-dateTime())
            )
        return concat(
            string-join($header, '&#10;'),
            '&#10;',
            string-join($pnds, '&#10;')
            )
    }
    let $fileName := 
        switch($params('type'))
        case 'pnd' return 'pnd_beacon.txt'
        case 'gkd' return 'gkd_beacon.txt'
        case 'works' return 'works_beacon.txt'
        default return ()
    let $onFailureFunc := function($errCode, $errDesc) {
        core:logToFile('warn', string-join(($errCode, $errDesc), ' ;; '))
    }
    return 
        util:binary-to-string(
            cache:doc(
                str:join-path-elements(($config:tmp-collection-path, $fileName)), 
                $callBack, $params('type'), 
                function($currentDateTimeOfFile as xs:dateTime?) as xs:boolean { wega-util:check-if-update-necessary($currentDateTimeOfFile, ()) },
                $onFailureFunc
            )
        )
};

(:http://localhost:8080/exist/apps/WeGA-WebApp/dev/api.xql?func=facets&docID=indices&docType=letters&facet=sender&format=json:)
declare function local:facets($params as map(*))  {
    let $search := search:results(<span/>, map { 'docID' := $params('docID') }, $params('docType'))
    let $lang := config:guess-language($params('lang'))
    return 
        facets:facets($search?search-results, $params('facet'), -1, $lang)
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

declare function local:serialize-json($response as item()*) {
    let $serializationParameters := ('method=text', 'media-type=application/json', 'encoding=utf-8')
    let $setHeader5 := response:set-header('Access-Control-Allow-Origin', '*')
    return 
        response:stream(
            serialize($response, 
                <json-output:serialization-parameters>
                    <json-output:method>json</json-output:method>
                </json-output:serialization-parameters>
            ), 
            string-join($serializationParameters, ' ')
        )
};

declare function local:serialize-txt($response as item()*) {
    let $serializationParameters := ('method=text', 'media-type=text/plain', 'encoding=utf-8')
    let $setHeader5 := response:set-header('Access-Control-Allow-Origin', '*')
    return 
        response:stream(
            if(every $i in $response satisfies $i instance of xs:string) then $response
            else serialize($response), 
            string-join($serializationParameters, ' ')
        )
};

let $func := request:get-parameter('func', '')
let $format := request:get-parameter('format', 'xml')
let $params := 
    map:merge(
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
    switch($format)
    case 'xml' return local:serialize-xml($response)
    case 'json' return local:serialize-json($response)
    case 'txt' return local:serialize-txt($response)
    default return ()
    