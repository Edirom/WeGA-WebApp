xquery version "3.0" encoding "UTF-8";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace ct="http://wiki.tei-c.org/index.php/SIG:Correspondence/task-force-correspDesc";

import module namespace wega="http://xquery.weber-gesamtausgabe.de/modules/wega" at "wega.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date" at "date.xqm";

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
                <date when="{current-dateTime()}"/>
                <availability>
                    <licence target="https://creativecommons.org/licenses/by/3.0/">CC-BY 3.0</licence>
                    <licence target="http://opensource.org/licenses/BSD-2-Clause">BSD-2</licence>
                </availability>
            </publicationStmt>
            <sourceDesc>
                <bibl>
                    Carl-Maria-von-Weber-Gesamtausgabe. Digitale Edition, <ref target="http://www.weber-gesamtausgabe.de">http://www.weber-gesamtausgabe.de</ref> (Version {config:get-option('version')} vom {date:strfdate(xs:date(config:get-option('versionDate')), 'de', '%d. %B %Y')})
                </bibl>
            </sourceDesc>
        </fileDesc>
    </teiHeader>
};

declare function ct:create-text($correspDescs as element(tei:correspDesc)*) as element(tei:text) {
    <text xmlns="http://www.tei-c.org/ns/1.0">
        <body>
            <listBibl>{
                for $i in $correspDescs
                return ct:create-correspDesc($i)
            }</listBibl>
        </body>
    </text>
};

declare function ct:create-correspDesc($correspDesc as element(tei:correspDesc)) as element(ct:correspDesc) {
    <ct:correspDesc ref="{concat('http://www.weber-gesamtausgabe.de/', $correspDesc/ancestor::tei:TEI/@xml:id)}">{
        for $person in ($correspDesc/tei:sender, $correspDesc/tei:addressee) return ct:create-sender-or-addressee($person),
        for $place in ($correspDesc/tei:placeSender, $correspDesc/tei:placeAddressee) return ct:create-places($place),
        for $date in ($correspDesc/tei:dateSender, $correspDesc/tei:dateAddressee) return ct:create-dates($date)
    }</ct:correspDesc>
};

declare function ct:create-sender-or-addressee($input as element()) as element() {
    let $id := $input//@key[1]
    let $gnd := if($id) then wega:getGND(string($id)) else ()
    return 
        element {xs:QName('ct:' || local-name($input))} {
            if($gnd) then attribute {'ref'} {'http://d-nb.info/gnd/' || $gnd} else (),
            normalize-space($input/*[1])
        }
};

declare function ct:create-dates($input as element()) as element() {
    element {xs:QName('ct:' || local-name($input))} {
        $input/tei:date/@*[local-name(.) ne 'n'](:,
        normalize-space($input):)
    }
};

declare function ct:create-places($input as element()) as element() {
    let $placeName := normalize-space($input/tei:placeName[1])
    let $geoID := core:data-collection('places')//tei:placeName[. = $placeName]/following-sibling::tei:idno
    return 
        element {xs:QName('ct:' || local-name($input))} {
            if($geoID) then attribute {'ref'} {'http://www.geonames.org/' || $geoID[1]} else (),
            $placeName
        }
};

declare function ct:corresp-list() as element(tei:TEI) {
    <TEI xmlns="http://www.tei-c.org/ns/1.0">{
        ct:create-header(),
        ct:create-text(core:data-collection('letters')//tei:correspDesc)
    }</TEI>
};

core:cache-doc(core:join-path-elements(($config:tmp-collection-path, 'correspDesc.xml')), ct:corresp-list#0, (), xs:dayTimeDuration('P999D'))
