xquery version "3.1" encoding "UTF-8";

(:~
 : XQuery for creating a CMIF file from the correspondence descriptions of the WeGA letters 
 : @see https://correspsearch.net/en/documentation.html
 :)

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace ct="http://wiki.tei-c.org/index.php/SIG:Correspondence/task-force-correspDesc";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace functx="http://www.functx.com";
import module namespace crud="http://xquery.weber-gesamtausgabe.de/modules/crud" at "crud.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";
import module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util" at "wega-util.xqm";
import module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/date.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/str.xqm";
import module namespace mycache="http://xquery.weber-gesamtausgabe.de/modules/cache" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/cache.xqm";

declare option output:method "xml";
declare option output:media-type "application/xml";
declare option output:indent "yes";

declare variable $ct:source-uuid := config:get-option('cmifID');
declare variable $ct:last-modified as xs:dateTime? := 
    if($config:svn-change-history-file/dictionary/@dateTime castable as xs:dateTime) 
    then $config:svn-change-history-file/dictionary/xs:dateTime(@dateTime)
    else ();
declare variable $ct:etag as xs:string? := 
    if(exists($ct:last-modified))
    then util:hash($ct:last-modified, 'md5')
    else ();
declare variable $ct:version as xs:string := request:get-parameter('v', '1');

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
                <idno type="url">{config:get-option('permaLinkPrefix')}/cmif_v{$ct:version}.xml</idno>
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
        case element(tei:correspAction) return ct:correspAction($node)
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
        ct:identity-transform-with-switches($input/tei:correspAction[@type=('sent', 'received')]),
        (: add empty correspAction for type=(received|sent) if not given, see https://github.com/Edirom/WeGA-WebApp/issues/404 :)
        if(not($input/tei:correspAction[@type='sent'])) 
        then ct:identity-transform-with-switches(<correspAction xmlns="http://www.tei-c.org/ns/1.0" type="sent"><persName>Unbekannt</persName></correspAction>)
        else (),
        if(not($input/tei:correspAction[@type='received']))
        then ct:identity-transform-with-switches(<correspAction xmlns="http://www.tei-c.org/ns/1.0" type="received"><persName>Unbekannt</persName></correspAction>)
        else (),
        if($ct:version ge '2')
        then ct:cmif2-note($input/root())
        else ()
    }
};

declare function ct:correspAction($input as element()) as element(tei:correspAction) {
    element {node-name($input)} {
        $input/@*,
        ct:identity-transform-with-switches($input/node()),
        (: add unknown persName if no sender or addressee is given, see https://github.com/Edirom/WeGA-WebApp/issues/404 :)
        if(not($input/tei:persName | $input/tei:rs | $input/tei:name | $input/tei:orgName))
        then ct:identity-transform-with-switches(<persName xmlns="http://www.tei-c.org/ns/1.0">Unbekannt</persName>)
        else ()
    }
};

declare function ct:participant($input as element()) as element() {
    let $id := $input/@key => tokenize('\s+')
    (: no support for multiple keys, e.g. `<rs type="persons" key="A000914 A008040">Jähns, F. W. und Ida</rs>` :)
    let $target := if(count($id) = 1) then ct:ref-target($id) else ()
    let $elemName := 
        (: map everything (except orgName) to persName, since correspSearch only supports these :)
        if(local-name($input) = ('rs', 'name')) then 'persName'
        else local-name($input)
    return 
        element {QName('http://www.tei-c.org/ns/1.0', $elemName)} {
            if($target) then attribute {'ref'} {$target}
            else (),
            normalize-space($input)
        }
};

declare function ct:place($input as element()) as element(tei:placeName) {
    let $id := ($input//@key)[1] (: take care of nested structures like <placeName key="zzz"><settlement key="yyy">foo</settlement> :)
    let $target := ct:ref-target($id)
    return 
        element {QName('http://www.tei-c.org/ns/1.0', 'placeName')} {
            if($target) then attribute {'ref'} {$target}
            else (),
            normalize-space($input)
        }
};

declare function ct:date($input as element()) as element(tei:date)? {
    (: The CMIF supports the attributes @when, @from, @to, @notBefore und @notAfter :)
    if($input/(@when | @from | @to | @notBefore | @notAfter))
    then
        element {QName('http://www.tei-c.org/ns/1.0', local-name($input))} {
            $input/@*[not(local-name(.) = ('n', 'calendar', 'cert'))]
            (: 
            no content allowed here with the schema at 
            https://raw.githubusercontent.com/TEI-Correspondence-SIG/CMIF/master/schema/cmi-customization.rng  
            :)
        }
    else ()
};

(:~
 : Extract text features for CMIF v2 and put them in a tei:note
 :)
declare function ct:cmif2-note($doc as document-node()) as element(tei:note)? {
    let $persons := ct:mentioned-entity-by-wega-facet($doc, 'persons', 'cmif:mentionsPerson')
    let $places := ct:mentioned-entity-by-wega-facet($doc, 'places', 'cmif:mentionsPlace')
    let $fullTextURL := config:permalink($doc/*/@xml:id) || '.xml?format=tei_all'
    return
        element {QName('http://www.tei-c.org/ns/1.0', 'note')} {
            $persons,
            $places,
            element {QName('http://www.tei-c.org/ns/1.0', 'ref')} {
                attribute {'type'} {'cmif:isAvailableAsTEIfile'},
                attribute {'target'} {$fullTextURL}
            }
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
 : Helper function to construct entity references within CMIF v2 tei:note element
 :
 : @param $doc the document to extract the features from
 : @param $wegaFacet the facet string as used in query:get-facets#2
 : @param $cmifURI the corresponding CMIF v2 URI as proposed in https://encoding-correspondence.bbaw.de/v1/CMIF.html#c-6
 :)
declare %private function ct:mentioned-entity-by-wega-facet(
    $doc as document-node(), 
    $wegaFacet as xs:string, 
    $cmifURI as xs:string) as element(tei:ref)* 
    {
        for $entity in ($doc => query:get-facets($wegaFacet))/parent::*
        group by $id := $entity/@key
        let $target := ct:ref-target($id)
        return
            element {QName('http://www.tei-c.org/ns/1.0', 'ref')} {
                attribute {'type'} {$cmifURI},
                attribute {'target'} {$target},
                query:title($id)
            }
};

(:~
 : Helper function to construct @target attributes
 : If an authority ID exists (GND for persons, Geonames for places), use this;
 : otherwise use our WeGA permalink
 :)
declare %private function ct:ref-target($id as xs:string?) as xs:anyURI? {
    let $docType := config:get-doctype-by-id($id)
    let $authorityID := 
        switch($docType)
        case 'persons' return query:get-gnd($id)
        case 'places' return query:get-geonamesID($id)
        default return ()
    return
        if($authorityID) 
        then 
            switch($docType)
            case 'persons' return xs:anyURI('http://d-nb.info/gnd/' || $authorityID)
            case 'places' return xs:anyURI('http://www.geonames.org/' || $authorityID)
            default return ()
        else 
        if($id) 
        then xs:anyURI(config:get-option('permaLinkPrefix') || '/' || $id)
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
        ($config:tmp-collection-path, 'cmif_v' || $ct:version || '.xml')), 
        ct:corresp-list#0, 
        (), 
        function($currentDateTimeOfFile as xs:dateTime?) as xs:boolean { wega-util:check-if-update-necessary($currentDateTimeOfFile, xs:dayTimeDuration('P999D')) }, 
        ct:onFailure#2
    )
)
