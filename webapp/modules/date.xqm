xquery version "3.0";

(:~
 : XQuery module for processing dates
 :)
module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace datetime="http://exist-db.org/xquery/datetime" at "java:org.exist.xquery.modules.datetime.DateTimeModule";

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
 : Checks, if given $date is castable as xs:date. If it's not castable, but has a length of 4, it will be changed into a date.  
 : 
 : @author Christian Epp
 : @author Peter Stadler
 : @param $node the supposed date node
 : @param $latest is true if the current node has a notAfter-attribute
 : @return the date in right type or empty
 :)
declare function date:getCastableDate($date as xs:string, $latest as xs:boolean) as xs:string? {
    if($date castable as xs:date)
    then $date
    else if($date castable as xs:gYear)
        (:if(string-length($date)=4):)
         then
            if($latest)
            then concat($date,'-12-31')
            else concat($date,'-01-01')
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
