xquery version "3.0" encoding "UTF-8";

(:~
 : Functions for manipulating strings
:)
module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str";
declare default collation "?lang=de;strength=primary";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace functx="http://www.functx.com";

(:~
 : Normalizes a given string
 : In addition to fn:normalize-space() this function treats non-breaking-spaces etc. as whitespace 
 :
 : @author Peter Stadler
 : @param $string the string to normalize
 : @return xs:string
 :)
declare function str:normalize-space($string as xs:string?) as xs:string {
    normalize-space(replace($string, '&#160;|&#8194;|&#8195;|&#8201;', ' '))
};

(:~
 : Joins path elements with a forward slash
 : In addition to string-join this function also takes care of double slashes
 :
 : @author Peter Stadler
 : @param $segs the path elements to join
 : @return the joined path as xs:string, the empty string when $segs was the empty sequence
 :)
declare function str:join-path-elements($segs as xs:string*) as xs:string {
    replace(string-join($segs, '/'), '/+' , '/')
};

(:~ 
 : Print forename surname
 :
 : @author Peter Stadler
 : @return xs:string
 :)
declare function str:printFornameSurname($name as xs:string?) as xs:string? {
    let $clearName := str:normalize-space($name)
    return
        if(functx:number-of-matches($clearName, ',') eq 1)
        then normalize-space(string-join(reverse(tokenize($clearName, ',')), ' '))
        else $clearName
};

(:~ 
 : Surround a string with typographic quotes
 :
 : @author Peter Stadler
 : @return xs:string
 :)
declare function str:enquote($str as xs:string?, $lang as xs:string) as xs:string? {
    let $quotes :=
        switch ($lang)
        case 'de' return '&#x201E;%1&#x201C;'
        default return '&#x201C;%1&#x201D;'
    return 
        if($str) then replace($quotes, '%1', $str)
        else ()
    
};

(:~
 : Print teaser text of max length while truncating at word border
 :
 : @author Peter Stadler
 : @param $string the string to truncate
 : @param $maxLength the max length of the returned string as xs:int
 : @return xs:string 
:)
declare function str:shorten-text($string as xs:string, $maxLength as xs:int) as xs:string {
    let $delimiterRegex := '[\s\.,!\?\+-;]' 
    let $maxString := substring(normalize-space($string),1,$maxLength)
    return 
        if(string-length($maxString) lt $maxLength) then $maxString 
        else concat(functx:substring-before-last-match($maxString, $delimiterRegex), ' …')
};

(:~ 
 : Sanitize user input
 : cf. http://www.balisage.net/Proceedings/vol7/html/Vlist02/BalisageVol7-Vlist02.html
 :
 : @author Peter Stadler
 : @return xs:string
 :)
declare function str:sanitize($str as xs:string) as xs:string {
(: Das wird wohl intern schon berücksichtigt?! Jedenfalls bringt die doppelte(?) Kodierung hier nur Probleme    :)
   (:if(contains($str, '&amp;')) then str:sanitize(replace($str, '&amp;', '&amp;amp;'))
   else if(contains($str, '''')) then str:sanitize(replace($str, '''', '&amp;apos;'))
   else if(contains($str, '""')) then str:sanitize(replace($str, '""', '&amp;quot;'))
   else if(contains($str, '<')) then str:sanitize(replace($str, '<', '&amp;lt;'))
   else if(contains($str, '{')) then str:sanitize(replace($str, '{', '{{'))
   else if(contains($str, '}')) then str:sanitize(replace($str, '}', '}}'))
   else :)$str
};
