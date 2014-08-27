xquery version "3.0" encoding "UTF-8";

(:~
 : Functions for querying data from the WeGA-data app 
:)
module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query";
declare default collation "?lang=de;strength=primary";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace norm="http://xquery.weber-gesamtausgabe.de/modules/norm" at "norm.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace functx="http://www.functx.com";

(:~
 : Print the regularised name for a given person ID
 :
 : @author Peter Stadler
 : @return xs:string
 :)
declare function query:get-reg-name($key as xs:string) as xs:string {
    (:
    Leider zu langsam
    
    let $regName := collection('/db/persons')//id($key)/tei:persName[@type='reg']
    return wega:cleanString($regName)
    :)
    let $dictionary := norm:get-norm-doc('persons') 
    let $response := $dictionary//norm:entry[@docID = $key]
    return 
        if(exists($response)) then $response/text() cast as xs:string
        else ''
};

(:~
 : Grabs the first author from a TEI document
 :
 : @author Peter Stadler 
 : @param $item the id of the TEI document (or the document node itself) to grab the author from
 : @return xs:string the name of the author as given by //tei:fileDesc/tei:titleStmt/tei:author[1]
:)
declare function query:getAuthorOfTeiDoc($item as item()) as xs:string {
    let $doc := typeswitch($item)
        case xs:string return core:doc($item)/*
        default return $item/*
    let $docID := typeswitch($item)
        case xs:string return $item
        default return $doc/root()/*/@xml:id cast as xs:string
    return 
        if(exists($doc)) then 
            if(config:is-diary($docID)) then 'A002068' (: Diverse Sonderbehandlungen fürs Tagebuch :)
            else if(config:is-work($docID)) then  (: Diverse Sonderbehandlungen für Werke :)
                if(exists($doc//mei:titleStmt/mei:respStmt/mei:persName[@role = 'cmp'][1]/@dbkey)) then $doc//mei:titleStmt/mei:respStmt/mei:persName[@role = 'cmp'][1]/string(@dbkey)
                else if(exists($doc/mei:ref)) then ''
                else config:get-option('anonymusID')
            else if(exists($doc//tei:fileDesc/tei:titleStmt/tei:author[1]/@key)) then $doc//tei:fileDesc/tei:titleStmt/tei:author[1]/string(@key)
            else if(exists($doc/tei:ref)) then query:getAuthorOfTeiDoc($doc/tei:ref/@target cast as xs:string)
            else config:get-option('anonymusID')
        else ''
};

(:~
 : Retrieves the WeGA person ID by PND
 :
 : @author Peter Stadler
 : @param $pnd the PND number
 : @return xs:string
:)
declare function query:getIDByPND($pnd as xs:string) as xs:string {
    core:data-collection('persons')//tei:idno[.=$pnd][@type='gnd']/parent::tei:person/string(@xml:id)
};


(:~ 
 : Gets events of the day for a certain date
 :
 : @author Peter Stadler
 : @param $date todays date
 : @return tei:date* tei:date elements that match given day and month of $date
 :)
declare function query:getTodaysEvents($date as xs:date) as element(tei:date)* {
    let $day := functx:pad-integer-to-length(day-from-date($date), 2)
    let $month := functx:pad-integer-to-length(month-from-date($date), 2)
    let $date-regex := concat('^', string-join(('\d{4}',$month,$day),'-'), '$')
    return 
        collection(config:get-option('letters'))//tei:dateSender/tei:date[matches(@when, $date-regex)] union
        collection(config:get-option('persons'))//tei:date[matches(@when, $date-regex)][not(preceding-sibling::tei:date[matches(@when, $date-regex)])][parent::tei:birth or parent::tei:death][ancestor::tei:person/@source='WeGA']
};
