xquery version "3.0";

(:~
 : XQuery module for processing dates
~:)
module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace pdr="http://pdr.bbaw.de/namespaces/pdrws/";

(:import module namespace datetime="http://exist-db.org/xquery/datetime" at "java:org.exist.xquery.modules.datetime.DateTimeModule";:)
import module namespace functx="http://www.functx.com";

declare variable $date:DATE_FORMAT_ERROR := QName("http://xquery.weber-gesamtausgabe.de/modules/date", "DateFormatError");

(:~
 : Construct one normalized xs:date from a tei:date element's date or duration attributes (@from, @to, @when, @notBefore, @notAfter)
 :  
 : @author Christian Epp
 : @author Peter Stadler
 : @param $date the tei:date
 : @param $latest a boolean whether the constructed date shall be the latest or earliest possible
 : @return the constructed date as xs:date or empty
 :)
declare function date:getOneNormalizedDate($date as element()?, $latest as xs:boolean) as xs:date? {
    if($latest) then max($date/@* ! date:getCastableDate(., $latest))
    else min($date/@* ! date:getCastableDate(., $latest))
};


(:~
 : Checks, if given $date is castable as xs:date and returns this date.
 : If $date is castable as xs:gYear the first or the last day of the year (depending on $latest) will be returned 
 : (Helper function for date:getOneNormalizedDate() and date:printDate())
 : 
 : @author Christian Epp
 : @author Peter Stadler
 : @param $date the date to test as xs:string
 : @param $latest if $latest is set to true() the last day of the year will be returned
 : @return the (constructed) date as xs:date, empty() if no conversion is possible
 :)
declare %private function date:getCastableDate($date as xs:string, $latest as xs:boolean) as xs:date? {
    if($date castable as xs:date) then xs:date($date)
    else if($date castable as xs:dateTime) then
        if(starts-with($date, '-')) then xs:date(substring($date, 1, 11))
        else xs:date(substring($date, 1, 10))
    else if($date castable as xs:gYear) then 
        if($latest) then xs:date(concat($date,'-12-31'))
        else xs:date(concat($date,'-01-01'))
    else()
};

(:~
 : format year specification depending on positive or negative value
 :
 : @author Peter Stadler
 : @param $year the year as (positive or negative) integer
 : @param $lang the language switch (en|de)
 : @return xs:string
 :)
declare function date:formatYear($year as xs:int, $lang as xs:string) as xs:string {
    if($year gt 0) then $year cast as xs:string
    else if($lang eq 'en') then concat($year*-1,' BC')
    else concat($year*-1,' v.&#8239;Chr.')
};

(:~
 : Parse date from string via PDR webservice
 :
 : @author Peter Stadler
 : @param $input the input string
 : @return tei:date element with the matching part of the string as text content and isodate attributes
 :)
declare function date:parse-date($input as xs:string, $http-get as function() as item()) as element(tei:date)* {
    let $webservice-url := 'https://pdrprod.bbaw.de/pdrws/dates?lang=de&amp;output=xml'
    let $text := 'text=' || encode-for-uri($input)
    let $pdr-result := $http-get(xs:anyURI(string-join(($webservice-url, $text), '&amp;')))//pdr:result
    return 
        if($pdr-result) then 
            for $result in $pdr-result 
            return 
                element tei:date {$result/pdr:isodate/@*, $result/string(pdr:occurrence)}
        else ()
};

(:~
 :  Wrapper around the standard fn:format-date() function
 :  because the current implementation has a bug(?) with dates BC
~:)
declare function date:format-date($date as xs:date, $picture as xs:string, $lang as xs:string) as xs:string? {
    if(starts-with($date, '-')) then format-date($date, replace($picture, '\[Y\]', date:formatYear(year-from-date($date), $lang)), $lang, (), ())
    else format-date($date, $picture, $lang, (), ())
};

(:~
 : Creates a verbal date representation for i.e. birthday or the sending date of a letter in paraphrasing @notBefore, @notAfter etc.
 :
 : @author Christian Epp
 : @author Peter Stadler
 : @param $date the date element to be displayed
 : @param $lang the current language (en|de)
 : @param $get-language-string a callback function that is expected to return a localized string for a given term
 : @return text
 :)
declare function date:printDate($date as element(tei:date)?, $lang as xs:string, $get-language-string as function(xs:string, xs:string*) as xs:string, $get-picture-string as function(empty()) as xs:string) as xs:string? {
    if($date) then (
        let $picture-string := $get-picture-string() (: if($lang = 'de') then '[D]. [MNn] [Y]' else '[MNn] [D], [Y]':)
        let $notBefore  := if($date/@notBefore) then date:getCastableDate(data($date/@notBefore),false()) else()
        let $notAfter   := if($date/@notAfter)  then date:getCastableDate(data($date/@notAfter),true()) else()
        let $from       := if($date/@from) then date:getCastableDate(data($date/@from),false()) else()
        let $to         := if($date/@to)  then date:getCastableDate(data($date/@to),true()) else()
        let $myDate := 
            if($date/@when) then date:format-date(date:getCastableDate($date/@when,true()), $picture-string, $lang)
            else if(exists($notBefore)) then 
                if(exists($notAfter)) then 
                    if(year-from-date($notBefore) eq year-from-date($notAfter)) then 
                        if(month-from-date($notBefore) eq month-from-date($notAfter)) then 
                            if(day-from-date($notBefore) = 1 and day-from-date($notAfter) = functx:days-in-month($notAfter)) then concat($get-language-string(concat('month',month-from-date($notAfter)),$lang),' ',year-from-date($notAfter))                  (: August 1879 :)
                            else $get-language-string('dateBetween',(xs:string(day-from-date($notBefore)),date:format-date($notAfter,$picture-string, $lang)))                       (: Zwischen 1. und 7. August 1801 :)
                        else if(ends-with($notBefore, '01-01') and ends-with($notAfter, '12-31')) then year-from-date($notBefore)                                            (: 1879 :)
                        else $get-language-string('dateBetween', (replace(date:format-date($notBefore,$picture-string, $lang), '(,\s+)?' || year-from-date($notBefore), ''), date:format-date($notAfter,$picture-string, $lang))) (: Zwischen 1. Juli 1789 und 4. August 1789 :)
                    else $get-language-string('dateBetween', (date:format-date($notBefore,$picture-string, $lang), date:format-date($notAfter,$picture-string, $lang)))                     (: Zwischen 1. Juli 1709 und 4. August 1789 :)
                else $get-language-string('dateNotBefore', (date:format-date($notBefore,$picture-string, $lang)))                                                           (: Frühestens am 1.Juli 1709 :)
            else if(exists($notAfter)) then $get-language-string('dateNotAfter', (date:format-date($notAfter,$picture-string, $lang)))                                     (: Spätestens am 1.Juli 1709 :)
            else if(exists($from)) then 
                if(exists($to)) then 
                    if(year-from-date($from) eq year-from-date($to)) then 
                        if(month-from-date($from) eq month-from-date($to)) then 
                            if(day-from-date($from) = 1 and day-from-date($to) = functx:days-in-month($to)) then date:format-date($from,'[MNn] [Y]', $lang) (:concat($get-language-string(concat('month',month-from-date($from)),$lang),' ',year-from-date($from)):)                  (: August 1879 :)
                            else $get-language-string('fromTo',(xs:string(day-from-date($from)),date:format-date($to,$picture-string, $lang)))                       (: Vom 1. bis 7. August 1801 :)
                        else if(ends-with($from, '01-01') and ends-with($to, '12-31')) then year-from-date($from)                                            (: 1879 :)
                        else $get-language-string('fromTo', (replace(date:format-date($from,$picture-string, $lang), '(,\s+)?' || year-from-date($from), ''), date:format-date($to,$picture-string, $lang))) (: Vom 1. Juli bis 4. August 1789 :)
                    else $get-language-string('fromTo', (date:format-date($from,$picture-string, $lang), date:format-date($to,$picture-string, $lang)))                     (: Vom 1. Juli 1709 bis 4. August 1789 :)
                else $get-language-string('fromToUnknown', date:format-date($from,$picture-string, $lang))    (: Vom 1.Juli 1709 bis unbekannt :)
            else if(exists($to)) then $get-language-string('unknownTo', (date:format-date($to,$picture-string, $lang)))                                  (: von unbekannt bis 1.Juli 1709 :)
            else if(normalize-space($date) castable as xs:date) then date:format-date(xs:date(normalize-space($date)),$picture-string, $lang)
            else $get-language-string('dateUnknown', ())
        return 
            if(exists($myDate)) then string($myDate)
            else error($date:DATE_FORMAT_ERROR, string-join(('date:printDate()', 'wrong date format', util:serialize($date, ('method=text', 'media-type=text/plain', 'encoding=utf-8'))), ' ;; '))
    )
    else ()
};

(:~
 :  Helper function for translating a Gregorian date to the Julian calendar
 :  see https://de.wikipedia.org/wiki/Umrechnung_zwischen_julianischem_und_gregorianischem_Kalender
~:)
declare function date:gregorian2julian($date as xs:date) as xs:date? {
    let $JH :=
        if(month-from-date($date) lt 3) then ((year-from-date($date) -1) div 100) cast as xs:positiveInteger
        else (year-from-date($date) div 100) cast as xs:positiveInteger
    let $diff := 3*(($JH div 4) cast as xs:positiveInteger) + ($JH mod 4) -2
    return
        $date - xs:dayTimeDuration('P' || $diff || 'D')
};
