xquery version "3.1" encoding "UTF-8";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace ct="http://wiki.tei-c.org/index.php/SIG:Correspondence/task-force-correspDesc";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace request="http://exist-db.org/xquery/request";

import module namespace functx="http://www.functx.com";
import module namespace crud="http://xquery.weber-gesamtausgabe.de/modules/crud" at "crud.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";
import module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util" at "wega-util.xqm";
import module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/date.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/str.xqm";
import module namespace mycache="http://xquery.weber-gesamtausgabe.de/modules/cache" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/cache.xqm";


declare variable $ct:source-uuid := config:get-option('cmifID');
declare variable $ct:last-modified as xs:dateTime? := 
    if($config:svn-change-history-file/dictionary/@dateTime castable as xs:dateTime) 
    then $config:svn-change-history-file/dictionary/xs:dateTime(@dateTime)
    else ();
declare variable $ct:etag as xs:string? := 
    if(exists($ct:last-modified))
    then util:hash($ct:last-modified, 'md5')
    else ();

declare function ct:create-header() as element(tei:teiHeader) {
    <teiHeader xmlns="http://www.tei-c.org/ns/1.0">
        <fileDesc>
            <titleStmt>
                <title>Korrespondenzbeschreibungen aus der Carl-Maria-von-Weber-Gesamtausgabe</title>
                <editor>Peter Stadler (<email>stadler@weber-gesamtausgabe.de</email>)</editor>
            </titleStmt>
            <publicationStmt>
                <publisher>
                    <ref target="{config:get-option('permaLinkPrefix')}">Carl-Maria-von-Weber-Gesamtausgabe</ref>
                </publisher>
                <idno type="url">{config:get-option('permaLinkPrefix')}/correspDesc.xml</idno>
                <date when="{$ct:last-modified}"/>
                <availability>
                    <licence target="http://creativecommons.org/licenses/by/4.0/">CC-BY 4.0</licence>
                    <licence target="http://opensource.org/licenses/BSD-2-Clause">BSD-2</licence>
                </availability>
            </publicationStmt>
            <sourceDesc>
                <bibl type="online" xml:id="{$ct:source-uuid}">
                    Carl-Maria-von-Weber-Gesamtausgabe. Digitale Edition, <ref target="{config:get-option('permaLinkPrefix')}">{config:get-option('permaLinkPrefix')}</ref> (Version {config:expath-descriptor()/data(@version)} vom {date:format-date(xs:date(config:get-option('versionDate')), $config:default-date-picture-string('de'), 'de')})
                </bibl>
            </sourceDesc>
        </fileDesc>
        <profileDesc>
            {crud:data-collection('letters')//tei:correspDesc ! ct:identity-transform-with-switches(.)}
        </profileDesc>
    </teiHeader>
};

declare function ct:identity-transform-with-switches($nodes as node()*) as item()* {
    for $node in $nodes
    return
        typeswitch($node)
        case element(tei:correspDesc) return ct:correspDesc($node)
        case element(tei:persName) return ct:participant($node)
        case element(tei:name) return ct:participant($node)
        case element(tei:orgName) return ct:participant($node)
        case element(tei:rs) return ct:participant($node) (: what to do with families? :)
        case element(tei:placeName) return ct:place($node)
        case element(tei:settlement) return ct:place($node)
        case element(tei:country) return ct:place($node)
        case element(tei:date) return ct:date($node)
        case element(tei:note) return 
            element {QName(namespace-uri($node), local-name($node))} {
                (: skip attributes due to danger of duplicate xml:ids – and we don't need them :)
                ct:identity-transform-with-switches($node/node())
            }
        case text() return $node
        case comment() return ()
        case processing-instruction() return ()
        case document-node() return ct:identity-transform-with-switches($node/node())
        default return
            element {QName(namespace-uri($node), local-name($node))} {
                $node/@*,
                ct:identity-transform-with-switches($node/node())
            }
};

declare function ct:correspDesc($input as element(tei:correspDesc)) as element(tei:correspDesc) {
    element {node-name($input)} {
        $input/@* except ($input/@source | $input/@ref),
        attribute ref {config:get-option('permaLinkPrefix') || '/' || $input/ancestor::tei:TEI/@xml:id},
        attribute source {concat('#', $ct:source-uuid)},
        ct:identity-transform-with-switches($input/node())
    }
};

declare function ct:participant($input as element()) as element() {
    let $id := $input/@key
    (: no support for multiple keys, e.g. `<rs type="persons" key="A000914 A008040">Jähns, F. W. und Ida</rs>` :)
    let $gnd := if(string-length($id) = 7) then query:get-gnd(string($id)) else ()
    let $elemName := 
        if(local-name($input) = 'rs') then 'name'
        else local-name($input)
    return 
        element {QName('http://www.tei-c.org/ns/1.0', $elemName)} {
            if($gnd) then attribute {'ref'} {'http://d-nb.info/gnd/' || $gnd}
            else if($id) then attribute {'ref'} {config:get-option('permaLinkPrefix') || '/' || $id}
            else (),
            normalize-space($input)
        }
};

declare function ct:place($input as element()) as element(tei:placeName) {
    let $id := ($input//@key)[1] (: take care of nested structures like <placeName key="zzz"><settlement key="yyy">foo</settlement> :)
    let $geoID := query:get-geonamesID($id)
    return 
        element {QName('http://www.tei-c.org/ns/1.0', 'placeName')} {
            if($geoID) then attribute {'ref'} {'http://www.geonames.org/' || $geoID}
            else if($id) then attribute {'ref'} {config:get-option('permaLinkPrefix') || '/' || $id}
            else (),
            normalize-space($input)
        }
};

declare function ct:date($input as element()) as element(tei:date) {
    element {QName('http://www.tei-c.org/ns/1.0', local-name($input))} {
        $input/@*[not(local-name(.) = ('n', 'calendar'))]
        (: 
        no content allowed here with the schema at 
        https://raw.githubusercontent.com/TEI-Correspondence-SIG/CMIF/master/schema/cmi-customization.rng  
        :)
    }
};

declare function ct:corresp-list() as element(tei:TEI) {
    <TEI xmlns="http://www.tei-c.org/ns/1.0">
        {ct:create-header()}
        <text><body><p/></body></text>
    </TEI>
};

declare function ct:onFailure($errCode, $errDesc) {
    wega-util:log-to-file('warn', string-join(($errCode, $errDesc), ' ;; '))
};

declare %private function ct:response-headers() as empty-sequence() {
    response:set-header('Access-Control-Allow-Origin', '*'),
    if(exists($ct:last-modified))
    then (
        response:set-header('Last-Modified', date:rfc822($ct:last-modified)),
        response:set-header('ETag', $ct:etag),
        response:set-header('Cache-Control', 'max-age=300,public')
    )
    else ()
};

(:~
 : checks whether a valid If-Modified-Since header was sent 
 : and if our last-modified is younger.
 : Returns true() when we need to send back the whole document 
:)
declare %private function ct:check-If-Modified-Since() as xs:boolean {
    (:  need to check for existence of the If-Modified-Since header first
        otherwise the lt comparison yields an empty-sequence (for an empty header)
    :)
    if(request:get-header('If-Modified-Since'))
    then
        try { 
            (: need to subtract another second since $ct:last-modified features milliseconds and the ietf-date not :)
            (request:get-header('If-Modified-Since') => parse-ietf-date()) lt ($ct:last-modified - xs:dayTimeDuration('PT1S'))
        }
        catch * { true() }
    else true()
};

(: check Etag :)
if(exists($ct:etag) and functx:substring-before-if-contains(request:get-header('If-None-Match'), '--') = $ct:etag)
then (
    ct:response-headers(),
    response:set-status-code(304)
)
(: check "If-Modified-Since" header as fallback if no "If-None-Match" header was sent :)
else if(exists($ct:last-modified) and not(request:get-header('If-None-Match') or ct:check-If-Modified-Since()))
then (
    ct:response-headers(),
    response:set-status-code(304)
)
else (
    ct:response-headers(),
    mycache:doc(str:join-path-elements(
        ($config:tmp-collection-path, 'correspDesc.xml')), 
        ct:corresp-list#0, 
        (), 
        function($currentDateTimeOfFile as xs:dateTime?) as xs:boolean { wega-util:check-if-update-necessary($currentDateTimeOfFile, xs:dayTimeDuration('P999D')) }, 
        ct:onFailure#2
    )
)
