xquery version "3.0";

(:~
 : XQuery module for processing dates
 :)
module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace pdr="http://pdr.bbaw.de/namespaces/pdrws/";

import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace wega="http://xquery.weber-gesamtausgabe.de/modules/wega" at "wega.xqm";
import module namespace datetime="http://exist-db.org/xquery/datetime" at "java:org.exist.xquery.modules.datetime.DateTimeModule";
import module namespace functx="http://www.functx.com";

(:~
 : Construct one normalized xs:date from a tei:date element's date or duration attributes (@from, @to, @when, @notBefore, @notAfter)
 :  
 : @author Christian Epp
 : @author Peter Stadler
 : @param $date the tei:date
 : @param $latest a boolean whether the constructed date shall be the latest or earliest possible
 : @return the constructed date or empty
 :)
declare function date:getOneNormalizedDate($date as element()?, $latest as xs:boolean) as xs:string? {
    if($date/@when)
        then if($date/@when castable as xs:date) 
            then $date/string(@when)
            else if($date/@when castable as xs:dateTime)
                then substring($date/@when,1,10)
                else date:getCastableDate($date/data(@when), $latest)
        else if($latest)
            then if($date/@notAfter)
                then if($date/@notAfter castable as xs:date)
                    then $date/string(@notAfter)
                    else date:getCastableDate($date/data(@notAfter), $latest)
                else if($date/@notBefore)
                    then if($date/@notBefore castable as xs:date)
                        then $date/string(@notBefore)
                        else date:getCastableDate($date/data(@notBefore), $latest)
                    else if($date/@to)
                        then if($date/@to castable as xs:date)
                            then $date/string(@to)
                            else date:getCastableDate($date/data(@to), $latest)
                        else if($date/@from)
                            then if($date/@from castable as xs:date)
                                then $date/string(@from)
                                else date:getCastableDate($date/data(@from), $latest)
                            else ()
(: Alles nochmal in umgekehrter Reihenfolge, wenn der früheste Zeitpunkt gewünscht ist. :)                                
            else if($date/@notBefore)
                then if($date/@notBefore castable as xs:date)
                    then $date/string(@notBefore)
                    else date:getCastableDate($date/data(@notBefore), $latest)
                else if($date/@notAfter)
                    then if($date/@notAfter castable as xs:date)
                        then $date/string(@notAfter)
                        else date:getCastableDate($date/data(@notAfter), $latest)
                    else if($date/@from)
                        then if($date/@from castable as xs:date)
                            then $date/string(@from)
                            else date:getCastableDate($date/data(@from), $latest)
                        else if($date/@to)
                            then if($date/@from castable as xs:date)
                                then $date/string(@to)
                                else date:getCastableDate($date/data(@to), $latest)
                            else ()
};


(:~
 : Checks, if given $date is castable as xs:date and returns this date.
 : If $date is castable as xs:gYear the first or the last day of the year (depending on $latest) will be returned 
 : 
 : @author Christian Epp
 : @author Peter Stadler
 : @param $date the date to test as xs:string
 : @param $latest if $latest is set to true() the last day of the year will be returned
 : @return the (constructed) date as xs:date, empty() if no conversion is possible
 :)
declare function date:getCastableDate($date as xs:string, $latest as xs:boolean) as xs:date? {
    if($date castable as xs:date) then xs:date($date)
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
 : String from date
 :
 : @author Peter Stadler
 : @param $format time format, e.g. '%B %d, %Y'
 : @param $date the date
 : @param $lang the language switch (en|de)
 : @return xs:string 
 :)
declare function date:strfdate($date as xs:date, $lang as xs:string, $format as xs:string?) as xs:string {
    let $format := 
        if($format) then $format
        else if($lang eq 'en') then '%B %d, %Y' (: if no format is specified, output day, month and year :)
        else '%d. %B %Y'
    let $day    := day-from-date($date)
    let $month  := month-from-date($date)
    let $year   := date:formatYear(number(year-from-date($date)), $lang)
    let $output := replace($format, '%d', string($day))
    let $output := replace($output, '%Y', string($year))
    let $output := replace($output, '%B', lang:get-language-string(concat('month',$month), $lang))
    let $output := replace($output, '%A', lang:get-language-string(concat('day',datetime:day-in-week($date)), $lang))

    return normalize-space($output)
};

(:~
 : Parse date from string via PDR webservice
 :
 : @author Peter Stadler
 : @param $input the input string
 : @return tei:date element with the matching part of the string as text content and isodate attributes
 :)
declare function date:parse-date($input as xs:string) as element(tei:date)* {
    let $webservice-url := 'https://pdrprod.bbaw.de/pdrws/dates?lang=de&amp;output=xml'
    let $text := 'text=' || encode-for-uri($input)
    let $pdr-result := wega:http-get(xs:anyURI(string-join(($webservice-url, $text), '&amp;')))//pdr:result
    return 
        if($pdr-result) then 
            for $result in $pdr-result 
            return 
                element tei:date {$result/pdr:isodate/@*, $result/string(pdr:occurrence)}
        else ()
};


(:~
 : Creates a verbal date representation for i.e. birthday
 : in paraphrasing @notBefore, @notAfter etc.
 :
 : @author Christian Epp
 : @param $date the date to be displayed
 : @param $lang the current language (en|de)
 : @return text
 :)
declare function date:printDate($date as element(tei:date)?, $lang as xs:string) as xs:string {
    let $dateFormat := if($lang = 'en') then '%d %B %Y' else '%d. %B %Y'
    let $notBefore  := if($date/@notBefore) then date:getCastableDate(data($date/@notBefore),false()) else()
    let $notAfter   := if($date/@notAfter)  then date:getCastableDate(data($date/@notAfter),true()) else()
    let $from       := if($date/@from) then date:getCastableDate(data($date/@from),false()) else()
    let $to         := if($date/@to)  then date:getCastableDate(data($date/@to),true()) else()
    let $date := 
        if($date/@when) then 
            if($date/@when castable as xs:date) then date:getNiceDate($date/@when,$lang)
            else if($date/@when castable as xs:gYear) then date:formatYear($date/@when cast as xs:int, $lang)
            else ()
        else if($notBefore) then 
            if($notAfter) then 
                if(year-from-date($notBefore) eq year-from-date($notAfter)) then 
                    if(month-from-date($notBefore) eq month-from-date($notAfter)) then 
                        if(day-from-date($notBefore) = 1 and day-from-date($notAfter) = functx:days-in-month(month-from-date($notAfter))) then concat(lang:get-language-string(concat('month',month-from-date($notAfter)),$lang),' ',year-from-date($notAfter))                  (: August 1879 :)
                        else lang:get-language-string('dateBetween',(xs:string(day-from-date($notBefore)),date:getNiceDate($notAfter,$lang)),$lang)                       (: Zwischen 1. und 7. August 1801 :)
                    else if(month-from-date($notBefore)=1 and month-from-date($notAfter)=12) then year-from-date($notBefore)                                            (: 1879 :)
                    else lang:get-language-string('dateBetween', (date:strfdate($notBefore,$lang,$dateFormat), date:getNiceDate($notAfter,$lang)), $lang) (: Zwischen 1. Juli 1789 und 4. August 1789 :)
                else lang:get-language-string('dateBetween', (date:getNiceDate($notBefore,$lang), date:getNiceDate($notAfter,$lang)), $lang)                     (: Zwischen 1. Juli 1709 und 4. August 1789 :)
            else lang:get-language-string('dateNotBefore', (date:getNiceDate($notBefore,$lang)), $lang)                                                           (: Frühestens am 1.Juli 1709 :)
        else if($notAfter) then lang:get-language-string('dateNotAfter', (date:getNiceDate($notAfter, $lang)), $lang)                                     (: Spätestens am 1.Juli 1709 :)
        else if($from) then 
            if($to) then 
                if(year-from-date($from) eq year-from-date($to)) then 
                    if(month-from-date($from) eq month-from-date($to)) then 
                        if(day-from-date($from) = 1 and day-from-date($to) = functx:days-in-month(month-from-date($to))) then concat(lang:get-language-string(concat('month',month-from-date($from)),$lang),' ',year-from-date($from))                  (: August 1879 :)
                        else lang:get-language-string('fromTo',(xs:string(day-from-date($from)),date:getNiceDate($to,$lang)),$lang)                       (: Vom 1. bis 7. August 1801 :)
                    else if(month-from-date($from)=1 and month-from-date($to)=12) then year-from-date($from)                                            (: 1879 :)
                    else lang:get-language-string('fromTo', (date:strfdate($from,$lang,$dateFormat), date:getNiceDate($to,$lang)), $lang) (: Vom 1. Juli 1789 bis 4. August 1789 :)
                else lang:get-language-string('fromTo', (date:getNiceDate($from,$lang), date:getNiceDate($to,$lang)), $lang)                     (: Vom 1. Juli 1709 bis 4. August 1789 :)
            else lang:get-language-string('from', (date:getNiceDate($from,$lang)), $lang) || ' bis unbekannt'                                                           (: Vom 1.Juli 1709 :)
        else if($to) then lang:get-language-string('chronoTo', (date:getNiceDate($to, $lang)), $lang) || ' bis unbekannt'                                     (: Bis 1.Juli 1709 :)
        else ()
            (:let $x := replace(data($date),'"','')
            return if($x castable as xs:date) then date:getNiceDate(xs:date($x),$lang) else():)
        return 
            if($date) then string($date)
            else core:logToFile('error', string-join(('date:printDate()', 'wrong date format'), ' ;; '))
};


(:~
 : formats year specification depending on positive or negative value
 :
 : @author Peter Stadler
 : @param $year the year as (positive or negative) integer
 : @param $lang the language switch (en|de)
 : @return xs:string
 :)
declare function date:formatYear($year as xs:int, $lang as xs:string) as xs:string {
    if($year gt 0) then $year cast as xs:string
    else if($lang eq 'en') 
        then concat($year*-1,' BC')
        else concat($year*-1,' v.&#8239;Chr.')
};

(:~
 : Returns number of days in a month. Does not consider leap years but always returns 28 days for february.
 :
 : @author Christian Epp
 : @param $month as integer value
 : @return number of days in month 
 :)
(:declare function wega:daysOfMonth($month as xs:integer) as xs:integer {
    if($month eq 2) then 28
    else if($month eq 4 or $month eq 6 or $month eq 9 or $month eq 11) then 30
    else 31
};:)


(:~
 : Gets nice date depending on the language
 :
 : @author Peter Stadler
 : @param $date 
 : @param $lang the current language (en|de)
 : @return xs:string
 :)

declare function date:getNiceDate($date as xs:date?, $lang as xs:string) as xs:string? {
    let $dateFormat := if($lang eq 'en')
        then '%B %d, %Y'
        else '%d. %B %Y'
	return 
	   if($date castable as xs:date) then date:strfdate($date,$lang,$dateFormat)
	   else $date
};
