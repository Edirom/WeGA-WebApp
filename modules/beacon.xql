xquery version "3.1" encoding "UTF-8";

(:~
 :
 :  Module for exporting BEACON files
 :  see https://de.wikipedia.org/wiki/Wikipedia:BEACON
 :
 :)

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace beacon="https://de.wikipedia.org/wiki/Wikipedia:BEACON";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace util="http://exist-db.org/xquery/util";

import module namespace crud="http://xquery.weber-gesamtausgabe.de/modules/crud" at "crud.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util" at "wega-util.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/str.xqm";
import module namespace mycache="http://xquery.weber-gesamtausgabe.de/modules/cache" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/cache.xqm";

declare option output:method "text";
declare option output:media-type "text/plain";


declare function beacon:new($type as xs:string) as xs:string {
    let $gnd-ids := 
        switch($type)
        case 'pnd' return crud:data-collection('persons')//tei:idno[@type='gnd']
        case 'gkd' return crud:data-collection('orgs')//tei:idno[@type='gnd']
        case 'works' return crud:data-collection('works')//mei:altId[@type='gnd']
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
        string-join($gnd-ids, '&#10;')
        )
};

declare function beacon:beacon($type as xs:string) as xs:string {
    let $fileName := 
        switch($type)
        case 'pnd' return 'pnd_beacon.txt'
        case 'gkd' return 'gkd_beacon.txt'
        case 'works' return 'works_beacon.txt'
        default return ()
    let $onFailureFunc := function($errCode, $errDesc) {
        wega-util:log-to-file('warn', string-join(($errCode, $errDesc), ' ;; '))
    }
    return 
        util:binary-to-string(
            mycache:doc(
                str:join-path-elements(($config:tmp-collection-path, $fileName)), 
                beacon:new#1, $type, 
                function($currentDateTimeOfFile as xs:dateTime?) as xs:boolean { wega-util:check-if-update-necessary($currentDateTimeOfFile, ()) },
                $onFailureFunc
            )
        )
};

let $beacon := request:get-attribute('beacon')
let $setHeader := response:set-header('Access-Control-Allow-Origin', '*')
return
    beacon:beacon($beacon)
