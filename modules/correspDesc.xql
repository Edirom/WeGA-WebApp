xquery version "3.0" encoding "UTF-8";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace ct="http://wiki.tei-c.org/index.php/SIG:Correspondence/task-force-correspDesc";

import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date" at "date.xqm";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "str.xqm";

declare function ct:create-header() as element(tei:teiHeader) {
    <teiHeader xmlns="http://www.tei-c.org/ns/1.0">
        <fileDesc>
            <titleStmt>
                <title>Korrespondenzbeschreibungen aus der Carl-Maria-von-Weber-Gesamtausgabe</title>
                <editor>Peter Stadler (<email>stadler@weber-gesamtausgabe.de</email>)</editor>
            </titleStmt>
            <publicationStmt>
                <publisher>
                    <ref target="http://weber-gesamtausgabe.de">Carl-Maria-von-Weber-Gesamtausgabe</ref>
                </publisher>
                <idno type="url">http://weber-gesamtausgabe.de/correspDesc.xml</idno>
                <date when="{current-dateTime()}"/>
                <availability>
                    <licence target="http://creativecommons.org/licenses/by/4.0/">CC-BY 4.0</licence>
                    <licence target="http://opensource.org/licenses/BSD-2-Clause">BSD-2</licence>
                </availability>
            </publicationStmt>
            <sourceDesc>
                <bibl type="online">
                    Carl-Maria-von-Weber-Gesamtausgabe. Digitale Edition, <ref target="http://www.weber-gesamtausgabe.de">http://www.weber-gesamtausgabe.de</ref> (Version {config:get-option('version')} vom {date:strfdate(xs:date(config:get-option('versionDate')), 'de', '%d. %B %Y')})
                </bibl>
            </sourceDesc>
        </fileDesc>
        <profileDesc>
            {for $i in core:data-collection('letters')//tei:correspDesc return ct:create-correspDesc($i)}
        </profileDesc>
    </teiHeader>
};

declare function ct:create-correspDesc($correspDesc as element(tei:correspDesc)) as element(tei:correspDesc) {
    <correspDesc ref="{concat('http://www.weber-gesamtausgabe.de/', $correspDesc/ancestor::tei:TEI/@xml:id)}" xmlns="http://www.tei-c.org/ns/1.0">{
        ct:create-correspAction-sent($correspDesc),
        ct:create-correspAction-received($correspDesc)
    }</correspDesc>
};

declare function ct:create-correspAction-sent($correspDesc as element(tei:correspDesc)) as element(tei:correspAction)? {
    let $correspAction :=
        <correspAction type="sent" xmlns="http://www.tei-c.org/ns/1.0">{
            $correspDesc/tei:sender/* ! ct:participant(.),
            $correspDesc/tei:placeSender/* ! ct:place(.),
            $correspDesc/tei:dateSender/* ! ct:date(.)
        }</correspAction>
    return
        if($correspAction/*) then $correspAction
        else ()
};

declare function ct:create-correspAction-received($correspDesc as element(tei:correspDesc)) as element(tei:correspAction)? {
    let $correspAction :=
        <correspAction type="received" xmlns="http://www.tei-c.org/ns/1.0">{
            $correspDesc/tei:addressee/* ! ct:participant(.),
            $correspDesc/tei:placeAddressee/* ! ct:place(.),
            $correspDesc/tei:dateAddressee/* ! ct:date(.)
        }</correspAction>
    return
        if($correspAction/*) then $correspAction
        else ()
};


declare function ct:participant($input as element()) as element() {
    let $id := $input//@key[1]
    let $gnd := if($id) then query:get-gnd(string($id)) else ()
    return 
        element {QName('http://www.tei-c.org/ns/1.0', local-name($input))} {
            if($gnd) then attribute {'ref'} {'http://d-nb.info/gnd/' || $gnd} else (),
            normalize-space($input)
        }
};

declare function ct:place($input as element()) as element() {
    let $placeName := normalize-space($input)
    let $geoID := core:data-collection('places')//tei:placeName[. = $placeName]/following-sibling::tei:idno
    return 
        element {QName('http://www.tei-c.org/ns/1.0', local-name($input))} {
            if($geoID) then attribute {'ref'} {'http://www.geonames.org/' || $geoID} else (),
            $placeName
        }
};

declare function ct:date($input as element()) as element() {
    element {QName('http://www.tei-c.org/ns/1.0', local-name($input))} {
        $input/@*[not(local-name(.) = ('n', 'calendar'))](:,
        normalize-space($input):)
    }
};

declare function ct:corresp-list() as element(tei:TEI) {
    <TEI xmlns="http://www.tei-c.org/ns/1.0">
        {ct:create-header()}
        <text><body><p/></body></text>
    </TEI>
};

core:cache-doc(str:join-path-elements(($config:tmp-collection-path, 'correspDesc.xml')), ct:corresp-list#0, (), xs:dayTimeDuration('P999D'))
