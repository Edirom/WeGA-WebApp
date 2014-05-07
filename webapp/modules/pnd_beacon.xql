xquery version "1.0" encoding "UTF-8";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace request = "http://exist-db.org/xquery/request";
declare namespace xmldb = "http://exist-db.org/xquery/xmldb";
declare namespace cache = "http://exist-db.org/xquery/cache";
declare namespace response = "http://exist-db.org/xquery/response";
declare namespace util = "http://exist-db.org/xquery/util";
import module namespace wega="http://xquery.weber-gesamtausgabe.de/modules/wega" at "wega.xqm";
import module namespace functx="http://www.functx.com";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";

declare option exist:serialize "method=text media-type=text/plain encoding=utf-8";

declare function local:createPNDBeacon() {
    let $pnds := core:data-collection('persons')//tei:idno[@type='gnd']
    let $header := (
        '#FORMAT: BEACON',
        '#PREFIX: http://d-nb.info/gnd/',
        '#VERSION: 0.1',
        '#TARGET: http://www.weber-gesamtausgabe.de/de/pnd/{ID}',
        '#FEED: http://www.weber-gesamtausgabe.de/pnd_beacon.txt',
        '#CONTACT: Peter Stadler <stadler [ at ] weber-gesamtausgabe.de>',
        '#INSTITUTION: Carl Maria von Weber Gesamtausgabe (WeGA)',
        '#DESCRIPTION: Personendatensätze der Carl Maria von Weber Gesamtausgabe',
        concat('#TIMESTAMP: ', current-dateTime())
        )
    return concat(
        string-join($header, '&#10;'),
        '&#10;',
        string-join($pnds, '&#10;')
        )
};

let $fileName := 'pnd_beacon.txt'
let $folderName := config:get-option('tmpDir')
let $currentDateTimeOfFile := 
    if(xmldb:collection-available($folderName)) then xmldb:last-modified($folderName, $fileName) 
    else ()
let $updateNecessary := typeswitch($currentDateTimeOfFile) 
    case xs:dateTime return config:eXistDbWasUpdatedAfterwards($currentDateTimeOfFile)
    default return true()

return if($updateNecessary) then (
    let $newPNDBeacon := local:createPNDBeacon()
    let $logMessage := 'creating PND Beacon file'
    let $logToFile := core:logToFile('info', $logMessage)
    return 
        if(exists($newPNDBeacon)) then util:binary-to-string(util:binary-doc(xmldb:store($folderName, $fileName, $newPNDBeacon)))
        else ()
    )
    else util:binary-to-string(util:binary-doc(string-join(($folderName, $fileName), '/')))