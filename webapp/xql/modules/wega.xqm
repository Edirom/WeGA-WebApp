xquery version "3.0" encoding "UTF-8";

(:~
: Collected xQuery functions
:
: @author Peter Stadler 
: @version 1.0
:)

module namespace wega="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/wega";
declare default collation "?lang=de;strength=primary";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace session = "http://exist-db.org/xquery/session";
declare namespace datetime = "http://exist-db.org/xquery/datetime";
declare namespace image = "http://exist-db.org/xquery/image";
declare namespace xmldb = "http://exist-db.org/xquery/xmldb";
declare namespace cache = "http://exist-db.org/xquery/cache";
declare namespace util = "http://exist-db.org/xquery/util";
declare namespace httpclient = "http://exist-db.org/xquery/httpclient";
import module namespace functx="http://www.functx.com" at "xmldb:exist:///db/webapp/xql/modules/functx.xqm";
import module namespace http = "http://expath.org/ns/http-client";

declare variable $wega:optionsFile as xs:string := '/db/webapp/xml/wegaOptions.xml';
declare variable $wega:romanNums as xs:integer* := (1000,900,500,400,100,90,50,40,10,9,5,4,1);
declare variable $wega:romanAlpha as xs:string* := ('M', 'CM', 'D', 'CD', 'C', 'XC', 'L', 'XL', 'X', 'IX', 'V', 'IV', 'I');
declare variable $wega:historyStack := ();

(:~
 : String from time
 :
 : @author Peter Stadler
 : @param $format time format
 : @param $value the date
 : @param $lang the language switch (en|de)
 : @return xs:string 
 :)

declare function wega:strftime($format as xs:string, $value as xs:date, $lang as xs:string) as xs:string
{
    let $day    := day-from-date($value)
    let $month  := month-from-date($value)
    let $year   := wega:formatYear(number(year-from-date($value)), $lang)
    let $dicID  := concat('dic_',$lang)
    let $output := replace($format, '%d', string($day))
    let $output := replace($output, '%Y', string($year))
    let $output := replace($output, '%B', wega:dictionaryLookup(concat('month',$month), $dicID))
    let $output := replace($output, '%A', wega:dictionaryLookup(concat('day',datetime:day-in-week($value)), $dicID))

    return wega:cleanString($output)
};

(:~
 : formats year specification depending on positive or negative value
 :
 : @author Peter Stadler
 : @param $year the year as (positive or negative) integer
 : @param $lang the language switch (en|de)
 : @return xs:string
 :)
 
declare function wega:formatYear($year as xs:int, $lang as xs:string) as xs:string {
    if($year gt 0) then $year cast as xs:string
    else if($lang eq 'en') then concat($year*-1,' BC')
        else concat($year*-1,' v.&#8239;Chr.')
};

(:~
 : Casts date format
 :
 : @author Peter Stadler
 : @param $date in the format 'Wed, 03 Nov 2010 19:09:48 GMT'
 : @return xs:dateTime if succesfull, emtpy otherwise
 :)

declare function wega:castDateFormat($date as xs:string) as xs:dateTime? {
    let $splitDate := tokenize($date, ' ')
    let $day := string($splitDate[2])
    let $month := for $i in (1 to 12) return if(matches(substring(wega:dictionaryLookup(concat('month', $i), 'dic_en'), 1, 3), string($splitDate[3]))) 
        then if($i le 9)
            then concat('0', $i)
            else $i
        else ()
    let $year := string($splitDate[4])
    let $time := string($splitDate[5])
    return xs:dateTime(concat($year, '-', $month, '-', $day, 'T', $time))
};

(:~
 : Returns number of days in a month. Does not consider leap years but always returns 28 days for february.
 :
 : @author Christian Epp
 : @param $month as integer value
 : @return number of days in month 
 :)
declare function wega:daysOfMonth($month as xs:integer) as xs:integer {
    if($month eq 2) then 28
    else if($month eq 4 or $month eq 6 or $month eq 9 or $month eq 11) then 30
    else 31
};

(:~
 : Creates a verbal date representation for i.e. birthday.
 :
 : @author Christian Epp
 : @param $date the date to be displayed
 : @param $lang the current language (en|de)
 : @return Text, der in den Meta-Daten angezeigt wird
 :)
declare function wega:printDate($date as element(tei:date)?, $lang as xs:string) as xs:string {
    let $dateFormat := if($lang = 'en') then '%d %B %Y' else '%d. %B %Y'
    let $notBefore  := if($date/@notBefore) then wega:getCastableDate(data($date/@notBefore),false()) else()
    let $notAfter   := if($date/@notAfter)  then wega:getCastableDate(data($date/@notAfter),true()) else()
    let $date := 
        if($date/@when)
        then if($date/@when castable as xs:date)
             then wega:getNiceDate($date/@when,$lang)
             else let $d := number(data($date/@when))
                  return if($d>0)
                         then $d
                         else wega:getLanguageString('BC',string($d*-1),$lang) 
        else if($date/@notBefore)
             then if($date/@notAfter)
                 then if(year-from-date($notBefore) eq year-from-date($notAfter)) 
                      then if(month-from-date($notBefore) eq month-from-date($notAfter))
                           then if(day-from-date($notBefore)=1 and day-from-date($notAfter)=wega:daysOfMonth(month-from-date($notAfter)))
                                then concat(wega:getLanguageString(concat('month',month-from-date($notAfter)),$lang),' ',year-from-date($notAfter))                  (: August 1879 :)
                                else wega:getLanguageString('dateBetween',(xs:string(day-from-date($notBefore)),wega:getNiceDate($notAfter,$lang)),$lang)                       (: Zwischen 1. und 7. August 1801 :)
                           else if(month-from-date($notBefore)=1 and month-from-date($notAfter)=12)
                                then year-from-date($notBefore)                                                                                                      (: 1879 :)
                                else wega:getLanguageString('dateBetween', (wega:strftime($dateFormat, $notBefore,$lang), wega:getNiceDate($notAfter,$lang)), $lang) (: Zwischen 1. Juli 1789 und 4. August 1789 :)
                      else wega:getLanguageString('dateBetween', (wega:getNiceDate($notBefore,$lang), wega:getNiceDate($notAfter,$lang)), $lang)                     (: Zwischen 1. Juli 1709 und 4. August 1789 :)
                 else wega:getLanguageString('dateNotBefore', (wega:getNiceDate($notBefore,$lang)), $lang)                                                           (: Frühestens am 1.Juli 1709 :)
            else
                if($date/@notAfter)
                then wega:getLanguageString('dateNotAfter', (wega:getNiceDate($notAfter, $lang)), $lang)                                                             (: Spätestens am 1.Juli 1709 :)
                else 
                    let $x := replace(data($date),'"','')
                    return if($x castable as xs:date) then wega:getNiceDate(xs:date($x),$lang) else()
        
        return string($date)
};

(:~
 : Constructs the html block with the birth and death information of a person (to be used within wega:getPersonMetaData())   
 : 
 : @author Peter Stadler
 : @param $birthOrDeath a tei:birth or tei:death element with tei:date and/or tei:placeName children
 : @param $lang the current language (en|de)
 : @return element
 :)

declare function wega:printDatesOfBirthOrDeath($birthOrDeath as element(), $lang as xs:string) as element(p)+ {
    let $place := wega:printPlaceOfBirthOrDeath($birthOrDeath/tei:placeName, $lang) 
    return 
        if(exists($birthOrDeath/tei:date/@*[name() != 'cert'])) then (: leere <date/> ausschliessen :)
            for $date in $birthOrDeath/tei:date return
                let $myType := 
                    if($date[@type]) then $date/string(@type) (: baptism or funeral:)
                    else $date/parent::*/local-name() (: birth or death :)
                let $certainty := 
                    if($date/@cert) then concat('cert_', $date/@cert cast as xs:string)
                    else ()
                let $content := (
                    element span {
                        attribute class {string-join(('date', $certainty), ' ')},
                        wega:printDate($date, $lang)
                    },
                    $place
                )
                return wega:datesOfBirthOrDeathTemplate($myType, $content, $lang)
        else 
            let $content := ($place, ' ', <span class="noDataFound">({wega:getLanguageString('dateUnknown',$lang)})</span>)
            return wega:datesOfBirthOrDeathTemplate($birthOrDeath/local-name(), $content, $lang) 
};

(:~
 : HTML template for rendering the birth and death dates within wega:getPersonMetaData() 
 : 
 : @author Peter Stadler
 : @param $myType the tye of date (birth|death|funeral|baptism)
 : @param $content arbitrary html or text content to put into the html:p
 : @param $lang the current language (en|de)
 : @return (html) element p
 :)

declare function wega:datesOfBirthOrDeathTemplate($myType as xs:string, $content as item()*, $lang as xs:string) as element(p) {
    let $html_pixDir := wega:getOption('html_pixDir')
    let $baseHref := wega:getOption('baseHref')
    let $iconPath := string-join(($baseHref, $html_pixDir, concat($myType,'.png')), '/')
    let $iconTitle := wega:getLanguageString($myType,$lang) 
    return 
        element p {
            attribute class {$myType},
            element img {
                attribute src {$iconPath},
                attribute title {$iconTitle},
                attribute alt {concat('icon', $myType)}
            },
            $content
        }
};

(:~
 : Prints the places of birth or death   
 : 
 : @author Peter Stadler
 : @param $placeNames the tei:placeName elements to print
 : @param $lang the current language (en|de)
 : @return a sequence of text and (html) element span elements for given tei:placeName(s), the empty sequence otherwise
 :)
declare function wega:printPlaceOfBirthOrDeath($placeNames as element(tei:placeName)*, $lang as xs:string) as item()* {
    for $placeName at $count in $placeNames
    let $name := wega:cleanString($placeName)
    let $certainty := 
        if($placeName/@cert) then concat('cert_', $placeName/@cert cast as xs:string)
        else ()
    return (
        if($count eq 1) then
            if(matches($name, '^(auf|bei)')) then ' ' (: Präposition 'in' weglassen wenn schon eine andere vorhanden :)
            else concat(' ', lower-case(wega:getLanguageString('in', $lang)), ' ')
        else concat(' ',wega:getLanguageString('or', $lang),' '),
        element span {
            attribute class {string-join(('place', $certainty), ' ')},
            $name
        }
    )
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

declare function wega:getCastableDate($date as xs:string, $latest as xs:boolean) as xs:string? {
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
 : Gets nice date depending on the language
 :
 : @author Peter Stadler
 : @param $date 
 : @param $lang the current language (en|de)
 : @return xs:string
 :)

declare function wega:getNiceDate($date as xs:date?, $lang as xs:string) as xs:string? {
    let $dateFormat := if($lang eq 'en')
        then '%B %d, %Y'
        else '%d. %B %Y'
	return if($date castable as xs:date) 
	   then wega:strftime($dateFormat,$date,$lang)
	   else $date
};

(:~
 : Construct one normalized xs:date from a tei:date element's date or duration attributes (@from, @to, @when, @notBefore, @notAfter)
 :  
 : @author Christian Epp
 : @author Peter Stadler
 : @param $date the tei:date
 : @param $latest a boolean whether the constructed date shall be the latest or earliest possible
 : @return the constructed date or empty
 :)

declare function wega:getOneNormalizedDate($date as element()?, $latest as xs:boolean) as xs:string?
{
    if($date/@when)
        then if($date/@when castable as xs:date) 
            then $date/string(@when)
            else if($date/@when castable as xs:dateTime)
                then substring($date/@when,1,10)
                else wega:getCastableDate($date/data(@when), $latest)
        else if($latest)
            then if($date/@notAfter)
                then if($date/@notAfter castable as xs:date)
                    then $date/string(@notAfter)
                    else wega:getCastableDate($date/data(@notAfter), $latest)
                else if($date/@notBefore)
                    then if($date/@notBefore castable as xs:date)
                        then $date/string(@notBefore)
                        else wega:getCastableDate($date/data(@notBefore), $latest)
                    else if($date/@to)
                        then if($date/@to castable as xs:date)
                            then $date/string(@to)
                            else wega:getCastableDate($date/data(@to), $latest)
                        else if($date/@from)
                            then if($date/@from castable as xs:date)
                                then $date/string(@from)
                                else wega:getCastableDate($date/data(@from), $latest)
                            else ()
(: Alles nochmal in umgekehrter Reihenfolge, wenn der früheste Zeitpunkt gewünscht ist. :)                                
            else if($date/@notBefore)
                then if($date/@notBefore castable as xs:date)
                    then $date/string(@notBefore)
                    else wega:getCastableDate($date/data(@notBefore), $latest)
                else if($date/@notAfter)
                    then if($date/@notAfter castable as xs:date)
                        then $date/string(@notAfter)
                        else wega:getCastableDate($date/data(@notAfter), $latest)
                    else if($date/@from)
                        then if($date/@from castable as xs:date)
                            then $date/string(@from)
                            else wega:getCastableDate($date/data(@from), $latest)
                        else if($date/@to)
                            then if($date/@from castable as xs:date)
                                then $date/string(@to)
                                else wega:getCastableDate($date/data(@to), $latest)
                            else ()
};

declare function wega:getYearFromDate($date as element()?) as xs:string? {
    if(matches($date/@when, '^\d{4}')) then substring($date/@when, 1, 4)
    else if(matches($date/@notBefore, '^\d{4}')) then substring($date/@notBefore, 1, 4)
    else if(matches($date/@from, '^\d{4}')) then substring($date/@from, 1, 4)
    else if(matches($date/@notAfter, '^\d{4}')) then substring($date/@notAfter, 1, 4)
    else if(matches($date/@to, '^\d{4}')) then substring($date/@to, 1, 4)
    else ()
};


(:~
 : Gets called on load of person_singleView.xql and puts tei:person//tei:event on screen
 :
 : @author Christian Epp
 : @author Peter Stadler
 : @param $person the person node with the events
 : @param $lang the language (en|de)
 : @return xhtml:div for every event
 :)

declare function wega:getEvents($person as node(), $lang as xs:string) as element()*
{
   (: let $start := if($start castable as xs:date) then $start else xs:date('0001-01-01')
    let $end   := if($end   castable as xs:date) then $end   else xs:date('3001-01-01'):)
    
    for $event at $i in $person//tei:event
        let $from := if(exists($event/@from)) then concat('f', wega:getCastableDate(string($event/@from), false())) else ()
        let $to := if(exists($event/@to)) then concat('t', wega:getCastableDate(string($event/@to), true())) else ()
        let $notBefore := if(exists($event/@notBefore)) then concat('b', wega:getCastableDate(string($event/@notBefore), false())) else ()
        let $notAfter := if(exists($event/@notAfter)) then concat('a', wega:getCastableDate(string($event/@notAfter), true())) else ()
        let $whenFrom := if(exists($event/@when)) then wega:getCastableDate(string($event/@when), false()) else ()
        let $whenTo := if(exists($event/@when)) then wega:getCastableDate(string($event/@when), true()) else ()
        let $idDatePart := if(exists($whenFrom))
                then if($whenFrom ne $whenTo)
                    then concat('b', $whenFrom, 'a', $whenTo)
                    else concat('w', $whenFrom)
                else string-join(($from, $to, $notBefore, $notAfter), '_')
        let $xslParams := <parameters><param name="lang" value="{$lang}"/><param name="eventID" value="{concat('event-', $i, '_', $idDatePart)}"/></parameters>
        return 
            wega:changeNamespace(transform:transform($event, doc("/db/webapp/xsl/person_singleView.xsl"), $xslParams), '', ())
};

(:~
 : Gets reg name
 :
 : @author Peter Stadler
 : @return xs:string
 :)

declare function wega:getRegName($key as xs:string) as xs:string
{
    (:
    Leider zu langsam
    
    let $regName := collection('/db/persons')//id($key)/tei:persName[@type='reg']
    return wega:cleanString($regName)
    :)
(:    let $response := wega:dictionaryLookup(concat('_', $key), 'persNamesFile'):)
    let $dictionary := wega:getNormDates('persons') 
        (:doc(wega:getOption('persNamesFile')):)
    let $response := $dictionary//entry[@docID = $key]
    return 
        if(exists($response)) then $response/text() cast as xs:string
        else ''
};

(:~
 : Gets reg title
 :
 : @author Peter Stadler
 : @param $docID
 : @return xs:string
 :)

declare function wega:getRegTitle($docID as xs:string) as xs:string {
    let $doc := wega:doc($docID)
    return
        if(wega:isDiary($docID)) then ()
        else if(wega:isWork($docID)) then wega:cleanString($doc//mei:fileDesc/mei:titleStmt/mei:title[@type = 'main'][1])
        else wega:cleanString($doc//tei:fileDesc/tei:titleStmt/tei:title[@level = 'a'][1])
};

(:~
 : Gets language string only by key
 :
 : @author Peter Stadler
 : @param $key for the dictionary
 : @param $lang the language of the string (en|de)
 : @return xs:string
 :)

declare function wega:getLanguageString($key as xs:string, $lang as xs:string) as xs:string
{
    let $dicID := concat('dic_', $lang)
(:    xs:ID(concat('dictionary_',$lang)):)
    return wega:dictionaryLookup($key,$dicID)
};

(:~
 : Gets language string with key and replacements
 :
 : @author Peter Stadler
 : @param $key for the dictionary
 : @param $replacements
 : @param $lang the language of the string (en|de)
 : @return xs:string
 :)

declare function wega:getLanguageString($key as xs:string, $replacements as xs:string*, $lang as xs:string) as xs:string
{
    let $dicID := concat('dic_', $lang)
(:    xs:ID(concat('dictionary_',$lang)):)
    let $dicEntry := wega:dictionaryLookup($key,$dicID)
    let $replacements := for $r in $replacements return if(string-length($r)<3 and $lang='de' and $key eq 'dateBetween')
                                                        then concat($r,'.') (: Sonderfall: "Zwischen 3. und 4. März 1767" - Der Punkt hinter der 3 :)
                                                        else $r
    let $placeHolders := for $i at $count in $replacements
        let $x := concat('%',$count)
        return $x
    return functx:replace-multi($dicEntry,$placeHolders,$replacements)
};

(:~
 : Does a dictionary lookup and returns the key for a given language string 
 :  
 : @author Peter Stadler
 : @param $string the value to look for in the dictionary
 : @param $lang the language of the string (en|de)
 : @return xs:string
 :)
 
declare function wega:reverseLanguageString ($string as xs:string, $lang as xs:string) as xs:string* {
    let $dicID := concat('dic_', $lang)
    return wega:reverseDictionaryLookup($string, $dicID)
};


(:~
 : Sets the language as a session attribute and returns this value
 : 
 : @author Peter Stadler
 : @param $lang the language to switch to
 : @return xs:string 
 :)
 
declare function wega:getSetLanguage ($lang as xs:string) as xs:string
{
    let $session-lang := if ($lang eq 'en' or $lang eq 'de')
        then session:set-attribute('lang', $lang)
        else if (not(exists(session:get-attribute('lang'))))
            then session:set-attribute('lang', 'de') (: Deutsch als Default-Sprache :)
            else ()
    return session:get-attribute('lang')
};

(:~
 : Sets entries per page for search site oder document list and stores in session
 :
 : @author Christian Epp
 : @param $entries must be between 5 and 20
 : @return xs:integer
 :)

declare function wega:getSetEntriesPerPage($entries) as xs:integer
{
    let $session-entries := if ($entries >= 5 and $entries <= 20)
        then session:set-attribute('entries', $entries)
        else if (not(exists(session:get-attribute('entries'))))
             then session:set-attribute('entries',5)
             else()
    return session:get-attribute('entries')
};

(:~
 : Stores and restores search options
 :
 : @author Christian Epp
 : @param $sOpts can be "persons" or "persons letters"
 : @return xs:string
 :)

declare function wega:getSetSearchOptions ($sOpts as xs:string*) as xs:string?
{
    let $session-sOpts :=
             if(matches($sOpts,'persons') or matches($sOpts,'letters') or matches($sOpts,'writings') or matches($sOpts,'diaries') or matches($sOpts,'works') or matches($sOpts,'news') or matches($sOpts,'biblio') (:or matches($sOpts,'var'):) )
             then session:set-attribute('sOpts', $sOpts)
             else if(matches($sOpts,'0'))
                  then ()
                  else session:set-attribute('sOpts', '')
    return session:get-attribute('sOpts')
};

(:~
 : Does a dictionary lookup and returns this value 
 : 
 : @author Peter Stadler
 : @param $key the key to look for in the dictionary
 : @param $dicID the xml:id of the dictionary to search in
 : @return xs:String
 :)
 
declare function wega:dictionaryLookup ($key as xs:string, $dicID as xs:string) as xs:string {
    let $dic := doc(wega:getOption($dicID))
    return wega:cleanString($dic//id($key))
};

(:~
 :  Does a reverse dictionary lookup and returns the keys for a given value
 :  
 : @author Peter Stadler
 : @param $string the string (value) to look for in the dictionary
 : @param $dicID the xml:id of the dictionary to search in
 : @return xs:string* a sequence of matching ids; otherwise the empty sequence
 :)
 
declare function wega:reverseDictionaryLookup ($string as xs:string, $dicID as xs:string) as xs:string* {
    let $dic := doc(wega:getOption($dicID))
    return $dic//entry[. = $string]/string(@xml:id)
};


(:~
 :  Returns the requested option value from an option file given by the variable $wega:optionsFile
 :  
 : @author Peter Stadler
 : @param $key the key to look for in the options file
 : @return xs:string the option value as string identified by the key otherwise the empty string
 :)
 
declare function wega:getOption($key as xs:string?) as xs:string {
    let $dic := doc($wega:optionsFile)
    let $item := $dic//id($key)
    return wega:cleanString($item)
};

(:~
 : Get options from options file
 :
 : @author Peter Stadler
 : @param $key
 : @param $replacements
 : @return xs:string
 :)

declare function wega:getOption($key as xs:string?, $replacements as xs:string*) as xs:string {
    let $dic := doc($wega:optionsFile)
    let $item := $dic//id($key)
    let $placeHolders := for $i at $count in $replacements
        let $x := concat('%',$count)
        return $x
    return functx:replace-multi($item,$placeHolders,$replacements)
};

(:~
 : Tries to translate a string from sourceLang to targetLang using the dictionaries 
 : If no translation is found the empty string is returned
 :  
 : @author Peter Stadler
 : @param $string the string to translate
 : @param $sourceLang the language to translate from
 : @param $targetLang the language to translate to
 : @return xs:string the translated string if successfull, otherwise the empty string
 :)
 
declare function wega:translateLanguageString($string as xs:string, $sourceLang as xs:string, $targetLang as xs:string) as xs:string
{
    let $sourceDic := doc(wega:getOption(concat('dic_', $sourceLang)))
    let $targetDic := doc(wega:getOption(concat('dic_', $targetLang)))
    let $search := $targetDic//id($sourceDic//entry[lower-case(.) eq lower-case($string)]/string(@xml:id))
    return wega:cleanString($search)
};

(:~
 : Return the main (primary) ID for a given ID
 : 
 : @author Peter Stadler
 : @param $id of person or letter
 : @return xs:string
 :)

declare function wega:getMainID($id as xs:string?) as xs:string
{
    let $duplicates := 
        if (wega:isPerson($id)) then collection(wega:getOption('persons'))//tei:person[./tei:ref]
        else if (wega:isLetter($id)) then collection(wega:getOption('letters'))//tei:TEI[./tei:ref]
        else ()
    return 
        if ($duplicates[@xml:id = $id]) then $duplicates[@xml:id = $id]/tei:ref/@target cast as xs:string
        else if(matches(normalize-space($id), '^A\d{6}$')) then $id
        else ''
};
 
(:declare function wega:getPortraitImagePath($person as node()) as xs:string? {
    if ($person/tei:figure[@n eq 'reg']) 
        then functx:replace-multi(document-uri($person/root()), ('/db/', '\.xml'), ('/db/images/', concat('/', $person/tei:figure[@n='reg']/tei:graphic/@url)))
        else if(data($person//tei:sex)='f') then '/db/webapp/pix/nobody_f.gif' else '/db/webapp/pix/nobody_m.gif'
};:)

(:declare function wega:getPortraitImagePath($person as node()) as xs:string {
    let $fffiId := $person/data(@xml:id)
    let $graphicUrl := collection('/db/iconography')//tei:figure[.//tei:person[@corresp = $fffiId]][@n = '1']/tei:graphic/data(@url)
    return if (exists($graphicUrl))
        then if(starts-with($graphicUrl, 'http'))
            then $graphicUrl
            else functx:replace-multi(document-uri($person/root()), ('/db/', '\.xml'), ('/db/images/', concat('/', $graphicUrl)))
        else if(data($person//tei:sex)='f') then '/db/webapp/pix/nobody_f.gif' else '/db/webapp/pix/nobody_m.gif'
(\:    return wega:getOrCreateThumb($imagePath, $dimension):\)
};:)

(:~
 : Gets portrait path for digilib
 :  
 : @author Peter Stadler
 : @param $person node of a certain person
 : @param $dimensions of image
 : @param $lang the language of the string (en|de)
 : @return xs:string
 :)
 
declare function wega:getPortraitPath($person as node(), $dimensions as xs:integer+, $lang as xs:string) as xs:string? {
    let $fffiId := $person/data(@xml:id)
    let $pnd := $person/tei:idno[@type='gnd']
    let $tmpDir := wega:getOption('tmpDir')
    let $iconography := wega:getOption('iconography')
    let $predicates := wega:getOption('iconographyPred', $fffiId)
    let $unknownWoman := wega:getOption('unknownWoman')
    let $unknownMan := wega:getOption('unknownMan')
    let $unknownSex := wega:getOption('unknownSex')
    let $localPortrait := util:eval(concat('collection($iconography)', $predicates))
    let $cachedPortrait := doc(concat($tmpDir, replace($fffiId, '\d{2}$', 'xx'), '/', $fffiId, '.xml'))//localFile/string()
(:    doc(concat($wega:tmpDir, replace($fffiId, '\d{2}$', 'xx'), '/', $fffiId, '.xml'))//localFile/string():)
    let $graphicURL := 
        if(exists($localPortrait)) then 
            if(exists($localPortrait/tei:graphic[1]/data(@url))) then functx:replace-multi(document-uri($person/root()), ('/db/', '\.xml'), ('/db/images/', concat('/', $localPortrait/tei:graphic[1]/data(@url))))
            else ()
        else 
            if(util:binary-doc-available($cachedPortrait)) then $cachedPortrait
            else 
                if(exists($pnd)) then wega:retrieveImagesFromWikipedia(string($pnd), $lang)//wega:wikipediaImage[1]/wega:localUrl/text()
                else ()
    return if(exists($graphicURL))
        then wega:createDigilibURL($graphicURL, $dimensions, true())
        else if(data($person//tei:sex)='f') 
            then wega:createDigilibURL($unknownWoman, $dimensions, true()) 
            else if(data($person//tei:sex)='m') 
                then wega:createDigilibURL($unknownMan, $dimensions, true()) 
                else wega:createDigilibURL($unknownSex, $dimensions, true())
};

(:~
 : Gets document meta data
 :  
 : @author Peter Stadler
 : @param $docItem the item from which the meta data is needed
 : @param $lang the language of the string (en|de)
 : @param $usage the intended usage for the return div: tooltip|singleView|listView 
 : @return element
 :)

declare function wega:getDocumentMetaData($docItem as item(), $lang as xs:string, $usage as xs:string) as element()? {
    let $docID := typeswitch($docItem)
        case xs:string return $docItem
        default return $docItem/root()/*/@xml:id cast as xs:string (: Weber-Studien haben @xml:id an tei:TEI, geliefert wird aber tei:biblStruct :)
    let $doc := typeswitch($docItem)
        case document-node() return $docItem
        case element() return $docItem/root()
        default $a return
            let $docOrg := wega:doc($docID)
            return if(exists($docOrg/*/tei:ref)) 
                then wega:doc($docOrg/*/tei:ref/string(@target)) (: Dublettenauflösung :)
                else $docOrg
    return 
        if(exists($doc)) then
            if(wega:isPerson($docID))       then wega:getPersonMetaData($doc, $lang, $usage)
            else if(wega:isWork($docID))    then wega:getWorkMetaData($doc, $lang, $usage)
            else if(wega:isWriting($docID)) then wega:getWritingMetaData($doc, $lang, $usage)
            else if(wega:isLetter($docID))  then wega:getLetterMetaData($doc, $lang, $usage)
            else if(wega:isNews($docID))    then wega:getNewsMetaData($doc, $lang, $usage)
            else if(wega:isDiary($docID))   then wega:getDiaryMetaData($doc, $lang, $usage)
            else if(wega:isVar($docID))     then wega:getVarMetaData($doc, $lang, $usage)
            else if(wega:isBiblio($docID))  then wega:getBiblioMetaData($doc, $lang, $usage)
            else wega:returnUnknownMetaData($docID, $lang, $usage)
        else wega:returnUnknownMetaData($docID, $lang, $usage)
};

(:~
 : Gets document meta data of unknown document
 :  
 : @author Peter Stadler
 : @param $docID
 : @param $lang the language of the string (en|de)
 : @param $usage the intended usage for the return div: tooltip|singleView|listView 
 : @return element
 :)

declare function wega:returnUnknownMetaData($docID as xs:string, $lang as xs:string, $usage as xs:string) as element() {
    let $logMessage := string-join(('wega:returnUnknownMetaData()', $docID, $lang, $usage), ';;')
    let $log := wega:logToFile('error', $logMessage)
    let $cssClasses := 
        if($usage eq 'toolTip') then 'toolTip'
        else if($usage eq 'listView') then 'item' 
        else ()
    return 
    <div class="{$cssClasses}">
        <div class="left">
            <img src="pix/UnknownIcon.png" alt="unknownIcon" class="icon" width="70" height="93"/>
            <br/>
            <span class="IDunderIcon">{$docID}</span>
        </div>
        <div class="right">
            <h1>{wega:getLanguageString('noDataFound', $lang)}</h1>
        </div>
    </div>
};


(:~ 
 : Creates HTML that shows some person meta data
 :
 : @author Peter Stadler
 : @param $lang the current language
 : @param $doc a TEI document with tei:person root element
 : @param $usage the intended usage for the return div: tooltip|singleView|listView
 : @return XHTML div
 :)
 
declare function wega:getPersonMetaData($doc as document-node(), $lang as xs:string, $usage as xs:string) as element()* {
let $person := $doc/tei:person
let $fffiId := $person/string(@xml:id)
let $baseHref := wega:getOption('baseHref')
let $imageEnlarge := $usage eq 'singleView'
let $imageDimension := 
    if($imageEnlarge) then for $i in tokenize(wega:getOption('bigPicDimensions'), ',') return xs:int($i) 
    else 
        if($usage eq 'toolTip') then for $i in tokenize(wega:getOption('smallPicDimensions'), ',') return xs:int($i)
        else for $i in tokenize(wega:getOption('mediumPicDimensions'), ',') return xs:int($i)
let $clickable := $usage eq 'listView'
let $portraitPath := wega:getPortraitPath($person, $imageDimension, $lang)
let $regName := wega:getRegName($fffiId)
let $xslParams := <parameters><param name="lang" value="{$lang}"/></parameters>
let $html_pixDir := wega:getOption('html_pixDir')
let $cssClasses := if($usage eq 'toolTip') 
    then 'person toolTip'
    else if($clickable)
            then 'person item'
            else 'person'
let $imageEnlargeLink := if($imageEnlarge)
    then let $localIconography := collection('/db/iconography')//tei:figure[.//tei:person[@corresp = $fffiId]][@n = 'portrait'][1][./tei:graphic]/ancestor::tei:TEI
         let $caption := if(exists($localIconography))
            then $localIconography//tei:title
            else if(matches($portraitPath, 'nobody_[fmn].png'))
                then $regName
                else concat($regName, ' (', wega:getLanguageString('sourceWikipedia', $lang), ')')
         let $digilibParams := if(exists($localIconography))
            then if ($localIconography//tei:graphic/xs:int(substring-before(@width, 'px')) > 400 or $localIconography//tei:graphic/xs:int(substring-before(@height, 'px')) > 600)
                then '&#38;dw=400&#38;dh=600'
                else '&#38;mo=file'
            else '&#38;mo=file'
         let $content := <img src="{$portraitPath}" alt="{$caption}" class="portrait" width="{$imageDimension[1]}" height="{$imageDimension[2]}"/>
         return
            wega:createLightboxAnchor(concat(substring-before($portraitPath, '&#38;'), $digilibParams), $caption, '', $content)
    else ()
    
return ( 
element div {
    attribute class {$cssClasses},
    if($clickable) 
        then (attribute onclick {concat("location.href='", string-join(($baseHref, $lang, $fffiId), '/'), "'")},
            attribute title {wega:getLanguageString('showPersonSingleView', wega:printFornameSurname($regName), $lang)})
        else (),

    if($imageEnlarge)
    then $imageEnlargeLink 
    else (
        element div {
            attribute class {'left'},
            <img src="{$portraitPath}" alt="{$regName}" class="portrait" width="{$imageDimension[1]}" height="{$imageDimension[2]}"/>,
            <br/>,
            <span class="{string-join(('IDunderIcon', wega:getRevisionStatus($doc)), ' ')}">{$fffiId}</span>
        }
    ),
    <div class="right">
        <h1 class="regName">{$regName}</h1>
        {
        if (exists($person//tei:persName[@type="full"]))
        then <p class="fullName">{
            wega:cleanString($person/tei:persName[@type='full'])
(:        transform:transform($person//tei:persName[string(@type) eq 'full'], doc("/db/webapp/xsl/person_singleView.xsl"), $xslParams):)
        }</p>
        else()
        }
        {
        if (exists($person//tei:persName[@type="real"]))
        then <p class="realName">{
            wega:cleanString($person/tei:persName[@type='real']),
(:            transform:transform($person//tei:persName[string(@type) eq 'real'], doc("/db/webapp/xsl/person_singleView.xsl"), $xslParams),:)
                                    <span class="nameDesc">{concat(' (', wega:getLanguageString('realName',$lang), ')')}</span>}</p>
        else()
        }
        {
        if (exists($person//tei:persName[@type="alt"]))
        then <p class="altNames">{wega:getLanguageString('altNames',$lang)}: { 
                for $i at $count in $person//tei:persName[string(@type) eq 'alt']
                let $lastItem := $person//tei:persName[@type="alt"]/last()
                return (
                    <span  class="alt">{wega:cleanString($i)}</span>,
(:                    transform:transform($i, doc("/db/webapp/xsl/person_singleView.xsl"), $xslParams),:)
                    if($i[@subtype='maiden']) 
                        then <span class="nameDesc">{concat(' (', wega:getLanguageString('maidenName',$lang), ')')}</span> 
                        else if($i[@subtype='married'])
                            then <span class="nameDesc">{concat(' (', wega:getLanguageString('marriedName',$lang), ')')}</span> 
                            else '',
                    if($count = $lastItem) then () else '; '
                    )
                }
            </p>
        else()
        }
        {
        if (exists($person//tei:persName[@type="pseud"]))
        then <p class="pseudNames">{wega:getLanguageString('pseudonyms',$lang)}: { 
                for $i at $count in $person//tei:persName[string(@type) eq 'pseud']
                let $lastItem := $person//tei:persName[@type="pseud"]/last()
                return (
                    <span class="pseud">{wega:cleanString($i)}</span>,
(:                    transform:transform($i, doc("/db/webapp/xsl/person_singleView.xsl"), $xslParams),:)
                    if($count = $lastItem) then () else '; '
                    )
                }
            </p>
        else(),
        
        if(exists($person//tei:birth)) then wega:printDatesOfBirthOrDeath($person//tei:birth, $lang)
        else wega:datesOfBirthOrDeathTemplate('birth', <span class="noDataFound">({wega:getLanguageString('noDataFound',$lang)})</span>, $lang),
        
        if(exists($person//tei:death)) then wega:printDatesOfBirthOrDeath($person//tei:death, $lang) else (),
        (:   Keine Ausgabe bei leerem death. Bei Angabe eines date wird das Datum ausgelesen bzw. ein  "keine Angaben gefunden" ausgegeben  :)

        if($person//tei:occupation) then 
            <p class="occupation">
                {if($usage eq 'toolTip' and exists($person//tei:occupation[4])) (:Für tooltips und Suche wird die Anzeige von Wirkorten und Tätigkeiten auf 3 beschränkt:)
                    then concat(string-join($person//tei:occupation[position() lt 4]/normalize-space(), ', '), ' ', wega:getLanguageString('etAlii', $lang))
                    else string-join($person//tei:occupation/normalize-space(), ', ')
                }
            </p>
        else (),
        
        if($person//tei:residence) then 
            <p class="residence">{wega:getLanguageString('placesOfAction',$lang)}:
                {if($usage eq 'toolTip' and exists($person//tei:residence[4])) (:Für tooltips und Suche wird die Anzeige von Wirkorten und Tätigkeiten auf 3 beschränkt:)
                    then concat(string-join($person//tei:residence[position() lt 4]/normalize-space(), ', '), ' ', wega:getLanguageString('etAlii', $lang))
                    else string-join($person//tei:residence/normalize-space(), ', ')
                }
            </p>
        else ()
        }
    </div>
    })
};

(:~ 
 : Creates HTML that shows some letter meta data
 :
 : @author Peter Stadler
 : @author Christian Epp
 : @param $lang the current language
 : @param $id the ID of the letter
 : @return XHTML
 :)
 
declare function wega:getLetterMetaData($doc as document-node(), $lang as xs:string, $usage as xs:string) as element() {
    let $letter := $doc/tei:TEI 
    let $imageDimension := if($usage eq 'singleView') then wega:getOption('bigPicDimensions') else wega:getOption('smallPicDimensions')
    let $clickable := $usage eq 'listView'
    let $baseHref := wega:getOption('baseHref')
    let $html_pixDir := wega:getOption('html_pixDir')
	let $iconPath := string-join(($baseHref, $html_pixDir, 'letterIcon.png'), '/')
	let $cssClasses := if($usage eq 'toolTip')  
        then 'letter toolTip'
        else if($usage eq 'listView')
            then 'letter item'
            else 'letter'

    return (
        element div {
            attribute class {$cssClasses},
            if($clickable) 
                then (
                    attribute onclick {concat("location.href='", wega:createLinkToDoc($doc, $lang), "'")},
                    attribute title {wega:getLanguageString('showLetterSingleView', $lang)}
                )
                else (),
            element div {
                attribute class {'left'},
                <img src="{$iconPath}" alt="letterIcon" class="icon" width="70" height="93"/>,
                <br/>,
                <span class="{string-join(('IDunderIcon', wega:getRevisionStatus($doc)), ' ')}">{$letter/string(@xml:id)}</span>
            },
            element div {
                attribute class {'right'},
                wega:getLetterHead($doc, $lang),
                element p {
                    <span class="tei_hiBold">{wega:getLanguageString('incipit',$lang)}: </span>,
                    element span {
                        if(functx:all-whitespace($letter//tei:incipit)) then (
                            attribute class {'noDataFound'},
                            wega:getLanguageString('noDataFound',$lang)
                        )
                        else (
                            let $preview := wega:printPreview($letter//tei:incipit, 100)
                            return 
                                if(ends-with($preview, '…')) then concat('&quot;',$preview,'&quot;')
                                else concat('&quot;',$preview,' …&quot;')
                        )
                    }
                },
                element p {
                    <span class="tei_hiBold">{wega:getLanguageString('summary',$lang)}: </span>,
                    element span {
                        if(functx:all-whitespace($letter//tei:note[@type='summary'])) then (
                            attribute class {'noDataFound'},
                            wega:getLanguageString('noDataFound',$lang)
                        )
                        else wega:printPreview($letter//tei:note[@type='summary'], 100)
                    }
                }
            }
        }
    )
};

(:~ 
 : Creates HTML that shows some diary meta data
 :
 : @author Christian Epp
 : @author Peter Stadler
 : @param $lang the current language (de|en)
 : @param $diaryEntry the tei:ab of the diary entry
 : @param $usage usage of the html fragment (listView|singleView|toolTip)
 : @return XHTML
 :)
 
declare function wega:getDiaryMetaData($doc as document-node(), $lang as xs:string, $usage as xs:string) as element() {
    let $diaryEntry := $doc/tei:ab
    let $baseHref := wega:getOption('baseHref')
    let $html_pixDir := wega:getOption('html_pixDir')
    let $iconPath := string-join(($baseHref, $html_pixDir, 'diaryIcon.png'), '/')
    let $clickable := $usage eq 'listView'
	let $cssClasses := if($usage eq 'toolTip')  
        then 'diaryDay toolTip'
        else if($usage eq 'listView')
            then 'diaryDay item'
            else 'diaryDay'
    let $dateFormat := if ($lang eq 'en')
        then '%A, %B %d, %Y'
        else '%A, %d. %B %Y'
    let $xslParams := <parameters><param name="lang" value="{$lang}"/></parameters>
    let $date := xs:date($diaryEntry/@n)
    let $id := $diaryEntry/@xml:id
    
    return (
    element div {
        if($clickable) 
            then (
                attribute onclick {concat("location.href='", wega:createLinkToDoc($doc, $lang), "'")},
                attribute title {wega:getLanguageString('showDiaryDay', ('Weber', wega:strftime(substring-after($dateFormat, ', '), $date, $lang)), $lang)}
            )
            else (),
        attribute class {$cssClasses},
        element div {
            attribute class {'left'},
            <img src="{$iconPath}" alt="diaryIcon" class="icon" width="70" height="93"/>,
            <br/>,
            <span class="{string-join(('IDunderIcon', wega:getRevisionStatus($doc)), ' ')}">{string($id)}</span>
        },
        element div {
            attribute class {'right'},
            element h1 {
                wega:strftime($dateFormat, $date, $lang)
            },
            element p {
                wega:printPreview(string($diaryEntry), 200)
            }
        }
    })
};

(:~ 
 : Creates HTML that shows some document meta data
 :
 : @author Christian Epp
 : @author Peter Stadler
 : @param $lang the current language (de|en)
 : @param $doc the document to grab the meta data from
 : @param $usage usage of the html fragment (listView|singleView|toolTip)
 : @return XHTML
 :)

declare function wega:getWritingMetaData($doc as document-node(), $lang as xs:string, $usage as xs:string) as element() {
    let $imageDimension := if($usage eq 'singleView') then wega:getOption('bigPicDimensions') else wega:getOption('smallPicDimensions')
    let $clickable := $usage eq 'listView'
    let $docID := $doc/tei:TEI/string(@xml:id)
    let $baseHref := wega:getOption('baseHref')
    let $html_pixDir := wega:getOption('html_pixDir')
    let $iconPath := string-join(($baseHref, $html_pixDir, 'writingIcon.png'), '/')
	let $cssClasses := if($usage eq 'toolTip') 
        then 'writing toolTip'
        else if($usage eq 'listView')
            then 'writing item'
            else 'writing'

    return (
        element div {
            attribute class {$cssClasses},
            if($clickable) 
                then (
                    attribute onclick {concat("location.href='", wega:createLinkToDoc($doc, $lang), "'")},
                    attribute title {wega:getLanguageString('showWritingSingleView', $docID, $lang)}
                )
                else (),
            element div {
                attribute class {'left'},
                <img src="{$iconPath}" alt="writingIcon" class="icon" width="70" height="93"/>,
                <br/>,
                <span class="{string-join(('IDunderIcon', wega:getRevisionStatus($doc)), ' ')}">{$docID}</span>
            },
            element div {
                attribute class {'right'},
                element h1 {
                    string($doc//tei:fileDesc//tei:titleStmt//tei:title[@level='a'][1]),
                    if (exists($doc//tei:idno[@type eq 'WeGA']/@n)) then concat(' (', $doc//tei:idno[@type eq 'WeGA']/@n, ')') 
                    else ()
                },
                wega:printCitation($doc//tei:sourceDesc/tei:biblStruct, 'p', $lang) 
            }
        }
    )
};

(:~ 
 : Creates HTML that shows some news meta data
 :
 : @author Peter Stadler
 : @param $lang the current language (de|en)
 : @param $doc the news document to grab the meta data from
 : @param $usage usage of the html fragment (listView|singleView|toolTip) 
 : @return XHTML
 :)

declare function wega:getNewsMetaData($doc as document-node(), $lang as xs:string, $usage as xs:string) as element() {
    let $imageDimension := if($usage eq 'singleView') then wega:getOption('bigPicDimensions') else wega:getOption('smallPicDimensions')
    let $clickable := $usage eq 'listView'
    let $baseHref := wega:getOption('baseHref')
    let $html_pixDir := wega:getOption('html_pixDir')
    let $iconPath := string-join(($baseHref, $html_pixDir, 'newsIcon.png'), '/')
	let $cssClasses := if($usage eq 'toolTip') 
        then 'news toolTip'
        else if($usage eq 'listView')
            then 'news item'
            else 'news'
    let $date := datetime:date-from-dateTime($doc//tei:publicationStmt/tei:date/xs:dateTime(@when))

    return (
        element div {
            attribute class {$cssClasses},
            if($clickable) 
                then (
                    attribute onclick {concat("location.href='", wega:createLinkToDoc($doc, $lang), "'")},
                    attribute title {wega:getLanguageString('showNewsSingleView', wega:getNiceDate($date, $lang), $lang)}
                )
                else (),
            element div {
                attribute class {'left'},
                <img src="{$iconPath}" alt="newsIcon" class="icon" width="70" height="93"/>,
                <br/>,
                <span class="IDunderIcon">{$doc/*/string(@xml:id)}</span>
            },
            element div {
                attribute class {'right'},
                element h1 {
                    string($doc//tei:fileDesc//tei:titleStmt//tei:title[@level='a'])
                },
                element p {
                    wega:printPreview(string($doc//tei:body), 150)
                },
                element p {
                    attribute class {'news-metadata-teaser-date'},
                    wega:getNiceDate($date, $lang)
                }
            }
        }
    )
};

(:~
 : Gets meta data of var document (copied from getNewsMetaData)
 :  
 : @author Peter Stadler
 : @author Christian Epp
 : @param $docID
 : @param $lang the language of the string (en|de)
 : @param $usage the intended usage for the return div: tooltip|singleView|listView 
 : @return element
 :)

declare function wega:getVarMetaData($doc as document-node(), $lang as xs:string, $usage as xs:string) as element() {
    let $imageDimension := if($usage eq 'singleView') then wega:getOption('bigPicDimensions') else wega:getOption('smallPicDimensions')
    let $clickable := $usage eq 'listView'
    let $baseHref := wega:getOption('baseHref')
    let $html_pixDir := wega:getOption('html_pixDir')
    let $iconPath := string-join(($baseHref, $html_pixDir, 'varIcon.png'), '/')
	let $cssClasses := if($usage eq 'toolTip') 
        then 'news toolTip'
        else if($usage eq 'listView')
            then 'news item'
            else 'news'
    let $docID :=  $doc/root()/*/@xml:id cast as xs:string
    
    return (
        element div {
            attribute class {$cssClasses},
            if($clickable) 
                then (
                    attribute onclick {concat("location.href='", string-join((wega:getOption('baseHref'), $lang, wega:getVarURL($docID,$lang)), '/'), "'")},
                    attribute title {}
                )
                else (),
            element div {
                attribute class {'left'},
                <img src="{$iconPath}" alt="varIcon" class="icon" width="70" height="93"/>,
                <br/>,
                <span class="IDunderIcon">{$docID}</span>
            },
            element div {
                attribute class {'right'},
                element h1 {
                    string($doc//tei:fileDesc//tei:titleStmt//tei:title[@level='a'][1])
                },
                element p {
                    wega:printPreview(string($doc//tei:body), 150)
                }
            }
        }
    )
};

(:~ 
 : Creates HTML that shows meta data for bibliographic items
 : 
 : @author Peter Stadler
 : @param $item the document
 : @param $lang the language of the string (en|de)
 : @param $usage the intended usage for the return div: tooltip|singleView|listView 
 : @return element
 :)
 
declare function wega:getBiblioMetaData($item as item(), $lang as xs:string, $usage as xs:string) as element() {
    let $doc := $item/root()
    let $docID := $doc/*/string(@xml:id)
    let $bibl := $doc//tei:biblStruct[1]
    let $imageDimension := if($usage eq 'singleView') then wega:getOption('bigPicDimensions') else wega:getOption('smallPicDimensions')
    let $clickable := ($usage eq 'listView') and $doc/root()/local-name(*) eq 'TEI' 
    let $baseHref := wega:getOption('baseHref')
    let $html_pixDir := wega:getOption('html_pixDir')
    let $biblioType := if(exists($doc//tei:biblStruct/@type)) then $doc//tei:biblStruct/data(@type) else 'blank'
    let $iconPath := string-join(($baseHref, $html_pixDir, concat('biblioIcon-',$biblioType,'.png')), '/')
	let $cssClasses :=
	   if($usage eq 'toolTip') then 'biblio toolTip'
	   else if($usage eq 'listView' and $clickable) then 'biblio item detail'
	   else if($usage eq 'listView' and not($clickable)) then 'biblio item'
	   else 'biblio'

    return (
        element div {
            attribute class {$cssClasses},
            if($clickable) 
                then (
                    attribute onclick {concat("location.href='", wega:createLinkToDoc($doc, $lang), "'")},
                    attribute title {wega:getLanguageString('showWritingSingleView', $docID, $lang)}
                )
                else (),
            element div {
                attribute class {'left'},
                <img src="{$iconPath}" alt="biblioIcon" class="icon" width="70" height="93"/>,
                <br/>,
                <span class="{string-join(('IDunderIcon', wega:getRevisionStatus($doc)), ' ')}">{$docID}</span>
            },
            element div {
                attribute class {'right'},
                wega:printCitation($bibl, 'span', $lang),
                if($clickable) then element p {
                    attribute class {'readOn'},
                    wega:getLanguageString('detailsAvailable', $lang)
                } 
                else ()
            }
        }
    )
};

(:~ 
 : Gets URL for var documents
 : 
 : @author Peter Stadler
 : @param $string the ID of the document 
 : @param $lang the language of the string (en|de) 
 : @return string?
 :)

declare function wega:getVarURL($string as xs:string?,$lang as xs:string) {
    let $result :=  if($string="A070001") then wega:getLanguageString("editorialGuidelines",$lang)
                    else if($string="A070002") then wega:getLanguageString("about",$lang)
                    else if($string="A070003") then wega:getLanguageString("bio",$lang)
                    else if($string="A070004") then wega:getLanguageString("help",$lang)
                    else if($string="A070005") then wega:getLanguageString("index",$lang)
                    else if($string="A070006") then wega:getLanguageString("projectDescription",$lang)
                    else if($string="A070009") then wega:getLanguageString("contact",$lang)
                    else if($string="A070010") then wega:getLanguageString("editorialGuidelines-works",$lang)
                    else if($string="A070011") then wega:getLanguageString("weberstudien",$lang)
                    else()
    return replace($result, '\s', '_')
};

(:~ 
 : Creates HTML that shows some work meta data
 :
 : @author Peter Stadler
 : @param $lang the current language (de|en)
 : @param $doc the work document to grab the meta data from
 : @param $usage usage of the html fragment (listView|singleView|toolTip) 
 : @return XHTML
 :)
 
declare function wega:getWorkMetaData($doc as document-node(), $lang as xs:string, $usage as xs:string) as element() {
    let $imageDimension := if($usage eq 'singleView') then wega:getOption('bigPicDimensions') else wega:getOption('smallPicDimensions')
    let $clickable := false()
        (:if($usage eq 'listView') then true() else false():)
    let $baseHref := wega:getOption('baseHref')
    let $html_pixDir := wega:getOption('html_pixDir')
    let $iconPath := string-join(($baseHref, $html_pixDir, 'workIcon.png'), '/')
	let $cssClasses := if($usage eq 'toolTip') 
        then 'works toolTip'
        else if($usage eq 'listView')
            then 'works item'
            else 'works'
    let $title := $doc//mei:fileDesc/mei:titleStmt/mei:title[@type = 'main'][1]

    return (
        element div {
            attribute class {$cssClasses},
            if($clickable) 
                then (
                    attribute onclick {concat("location.href='", wega:createLinkToDoc($doc, $lang), "'")},
                    attribute title {wega:getLanguageString('showWorkSingleView', wega:printPreview(string($title), 20), $lang)}
                )
                else (),
            element div {
                attribute class {'left'},
                <img src="{$iconPath}" alt="workIcon" class="icon" width="70" height="93"/>,
                <br/>,
                <span class="IDunderIcon">{$doc/*/string(@xml:id)}</span>
            },
            element div {
                attribute class {'right'},
                element h1 {
                    if(empty($doc)) 
                        then wega:getLanguageString('noDataFound', $lang)
                        else (
                            string($doc//mei:fileDesc/mei:titleStmt/mei:title[@type = 'main'][1]),
                            if(exists($doc//mei:altId[@type])) then 
                                if(exists($doc//mei:altId[@type='WeV'])) then concat('(WeV ', $doc//mei:altId[@type='WeV'], ')') (: Weber-Werke :)
                                else concat('(', $doc//mei:altId[1]/string(@type), ' ', $doc//mei:altId[1], ')') (: Fremd-Werke :)
                            else()
                        )
                },
                if(exists($doc//mei:fileDesc/mei:titleStmt/mei:title[@type = 'sub'])) then 
                    element h2 {
                        data($doc//mei:fileDesc/mei:titleStmt/mei:title[@type = 'sub'][1])
                    }
                else (),
                if(exists($doc//mei:seriesStmt/mei:title[@level='s'])) then ()
                    (:element h2 {
                        string-join((
                            wega:getLanguageString('series', $lang),
                            $doc//mei:seriesStmt/mei:title[@level='s']/wega:number-to-roman(@n), 
                            $doc//mei:seriesStmt/mei:title[@level='s']
                            ), ' ')
                    }:)
                else (),
                element p {
                    let $maxCount := count($doc//mei:fileDesc/mei:titleStmt/mei:respStmt/mei:persName)
                    for $i at $count in $doc//mei:fileDesc/mei:titleStmt/mei:respStmt/mei:persName[@role=('cmp', 'lbt', 'lyr')]
                    return (
                        element span {
                            attribute class {'tei_hiBold'},
                            wega:getLanguageString($i/string(@role), $lang)
                        },
                        ': ',
                        if(exists($i/@dbkey)) then wega:getRegName($i/string(@dbkey)) 
                        else data($i),
                        if($count eq $maxCount) then () else <br/>
                    )
                },
                if(exists($doc//mei:history/mei:p)) then (
                    for $i in $doc//mei:history/mei:p return 
                    element p {$i cast as xs:string}
                ) 
                else ()
            }
        }
    )
};

(:~ 
 : Gets events of the day for a certain date
 :
 : @author Peter Stadler
 : @param $date todays date
 : @return tei:date* tei:date elements that match given day and month of $date
 :)

declare function wega:getTodaysEvents($date as xs:date) as element(tei:date)* {
    let $day := functx:pad-integer-to-length(day-from-date($date), 2)
    let $month := functx:pad-integer-to-length(month-from-date($date), 2)
    let $date-regex := concat('^', string-join(('\d{4}',$month,$day),'-'), '$')
    return 
        collection(wega:getOption('letters'))//tei:dateSender/tei:date[matches(@when, $date-regex)] union
        collection(wega:getOption('persons'))//tei:date[matches(@when, $date-regex)][parent::tei:birth or parent::tei:death]
};

(:~ 
 : Print forename surname
 :
 : @author Peter Stadler
 : @return xs:string
 :)
 
declare function wega:printFornameSurname($name as xs:string?) as xs:string? {
    let $clearName := wega:cleanString($name)
    return
        if(matches($clearName, ','))
        then normalize-space(string-join(reverse(tokenize($clearName, ',')), ' '))
        else normalize-space($clearName)
};

(:~
 : Construct a name from a persName or name element wrapped in a <span> with @onmouseover etc.
 : If a @key is given on persName the regularized form will be returned, otherwise the content of persName.
 : If persName is empty than "unknown" is returned.
 : 
 : @author Peter Stadler
 : @param $persName the tei:persName element
 : @param $lang the current language (de|en)
 : @param $order (sf|fs) whether to print "surname, forename" or "forename surname"
 : @return 
 :)
 
declare function wega:printCorrespondentName($persName as element(), $lang as xs:string, $order as xs:string) as element() {
     if(exists($persName/@key)) 
        then wega:createPersonLink($persName/string(@key), $lang, $order)
        else if (exists($persName//text())) 
            then <xhtml:span class="noDataFound">{normalize-space($persName)}</xhtml:span>
            else <xhtml:span class="noDataFound">{wega:getLanguageString('unknown',$lang)}</xhtml:span>
};

(:~
 : Creates person link
 :
 : @author Peter Stadler
 : @param $id of the person
 : @param $lang the current language (de|en)
 : @param $order (sf|fs) whether to print "surname, forename" or "forename surname"
 : @return HTML element
 :)
 
declare function wega:createPersonLink($id as xs:string, $lang as xs:string, $order as xs:string) as element() {
    let $name := if($order eq 'fs')
        then wega:printFornameSurname(wega:getRegName($id))
        else wega:getRegName($id)
    return if($name != '')
        then 
            <xhtml:a href="{string-join((wega:getOption('baseHref'), $lang, $id), '/')}">
                <xhtml:span class="person" onmouseover="metaDataToTip('{$id}', '{$lang}')" onmouseout="UnTip()">{$name}</xhtml:span>
            </xhtml:a>
        else <xhtml:span class="{concat('noDataFound ', $id)}">{wega:getLanguageString('unknown',$lang)}</xhtml:span>
};

(:~
 : Creates document link
 :
 : @author Peter Stadler
 : @param $doc the document to create the link for
 : @param $content the string content for the xhtml a element
 : @param $lang the language switch (en, de)
 : @param $attributes a sequence of attribute-value-pairs, e.g. ('class=xy', 'style=display:block')
 :)
 
declare function wega:createDocLink($doc as document-node(), $content as xs:string, $lang as xs:string, $attributes as xs:string*) as element() {
    let $href := wega:createLinkToDoc($doc, $lang)
    let $docID :=  $doc/root()/*/@xml:id
    return 
    element a {
        attribute href {$href},
        attribute onmouseover {concat("metaDataToTip('", $docID, "','", $lang, "')")},
        attribute onmouseout {'UnTip()'},
        if(exists($attributes)) then for $att in $attributes return attribute {substring-before($att, '=')} {substring-after($att, '=')} 
        else (),
        $content
    }
};

(:~
 : Create a bibliographic citation from a biblStruct
 : 
 : @author Peter Stadler
 : @param $biblStruct the TEI biblStruct element with the bibliographic information
 : @param $wrapperElement the HTML element for wrapping the output (usually span or li)
 : @param $lang the language switch (en, de)
 : @return element
 :)

declare function wega:printCitation($biblStruct as element(tei:biblStruct), $wrapperElement as xs:string, $lang as xs:string) as element()? {
    if($biblStruct/tei:analytic/tei:author[@sameAs]) then wega:printJournalCitation($biblStruct/tei:monogr, $wrapperElement, $lang) (: Soll in den writings die Ausgabe von (leerem) Autor unterdrücken; Ist aber lediglich als Notlösung zu verstehen! :)
    else if($biblStruct/@type eq 'book') then wega:printBookCitation($biblStruct, $wrapperElement, $lang)
    else if($biblStruct/@type eq 'score') then wega:printBookCitation($biblStruct, $wrapperElement, $lang)
    else if($biblStruct/@type eq 'article') then wega:printArticleCitation($biblStruct, $wrapperElement, $lang)
    else if($biblStruct/@type eq 'incollection') then wega:printIncollectionCitation($biblStruct, $wrapperElement, $lang)
    else if($biblStruct/@type eq 'inproceedings') then wega:printIncollectionCitation($biblStruct, $wrapperElement, $lang)
    else if($biblStruct/@type eq 'review') then wega:printArticleCitation($biblStruct, $wrapperElement, $lang)
    else if($biblStruct/@type eq 'phdthesis') then wega:printBookCitation($biblStruct, $wrapperElement, $lang)
    else wega:printGenericCitation($biblStruct, $wrapperElement, $lang)
};

(:~
 : Create a generic bibliographic citation (This is highly specific to our WeGA data though!)
 : 
 : @author Peter Stadler
 : @param $biblStruct the TEI biblstruct element with the bibliographic information
 : @param $wrapperElement the HTML element for wrapping the output (usually span or li)
 : @param $lang the language switch (en, de)
 : @return element
 :)
 
declare function wega:printGenericCitation($biblStruct as element(tei:biblStruct), $wrapperElement as xs:string, $lang as xs:string) as element() {
    let $xslParams := <parameters><param name="lang" value="{$lang}"/></parameters>
    let $authors := wega:printCitationAuthors($biblStruct//tei:author, $lang)
    let $title := for $i in $biblStruct//tei:title return 
        (transform:transform($i, doc("/db/webapp/xsl/var.xsl"), $xslParams),
        '. '
        )
    return 
        element {$wrapperElement} {
            $authors,
            if(exists($authors)) then ', ' else (),
            $title
        }
};

(:~
 : Create a bibliographic citation for a book
 : 
 : @author Peter Stadler
 : @param $biblStruct the TEI biblstruct element with the bibliographic information
 : @param $wrapperElement the HTML element for wrapping the output (usually span or li) 
 : @param $lang the language switch (en, de)
 : @return element
 :)
 
declare function wega:printBookCitation($biblStruct as element(tei:biblStruct), $wrapperElement as xs:string, $lang as xs:string) as element() {
    let $authors := wega:printCitationAuthors($biblStruct//tei:author, $lang)
    let $editors := wega:printCitationAuthors($biblStruct/tei:monogr/tei:editor, $lang)
    let $series := if(exists($biblStruct/tei:series/tei:title)) then wega:printSeriesCitation($biblStruct/tei:series, 'span', $lang) else ()
    let $title := <span class="title">{string-join($biblStruct/tei:monogr/tei:title, '. ')}</span>
    let $pubPlaceNYear := wega:printpubPlaceNYear($biblStruct//tei:imprint)
    return 
        element {$wrapperElement} {
            attribute class {'book'},
            if(exists($authors)) then ($authors, ', ') 
            else if(exists($editors)) then ($editors, concat(' (', wega:getLanguageString('ed', $lang), '), '))
            else (), 
            $title,
            if(exists($editors) and exists($authors)) then (concat(', ', wega:getLanguageString('edBy', $lang), ' '), $editors) else (),
            if(exists($series)) then concat(' (= ', $series, '), ') else ', ',
            $pubPlaceNYear
        }
};

(:~
 : Create a bibliographic citation for an article
 : 
 : @author Peter Stadler
 : @param $biblStruct the TEI biblstruct element with the bibliographic information
 : @param $wrapperElement the HTML element for wrapping the output (usually span or li) 
 : @param $lang the language switch (en, de)
 : @return element
 :)
 
declare function wega:printArticleCitation($biblStruct as element(tei:biblStruct), $wrapperElement as xs:string, $lang as xs:string) as element() {
    let $authors := wega:printCitationAuthors($biblStruct//tei:author, $lang) 
    let $articleTitle := <span class="title">{string-join($biblStruct/tei:analytic/tei:title, '. ')}</span>
    let $journalCitation := wega:printJournalCitation($biblStruct/tei:monogr, 'wrapper', $lang)
    return 
        element {$wrapperElement} {
            $authors,
            ', ',
            $articleTitle,
            ', in: ',
            $journalCitation/span,
            $journalCitation/text()
        }
};

(:~
 : Create a bibliographic citation for a journal
 : 1. Helper function for wega:printArticleCitation() 
 : 2. Function for creating bibliographic citations for writings when the source is a journal
 : 
 : @author Peter Stadler
 : @param $monogr the TEI monogr element with the bibliographic reference of the journal
 : @param $wrapperElement the HTML element for wrapping the output (usually span or li)
 : @param $lang the language switch (en, de)
 : @return element
 :)

declare function wega:printJournalCitation($monogr as element(tei:monogr), $wrapperElement as xs:string, $lang as xs:string) as element() {
    let $journalTitle := <span class="journalTitle">{string-join($monogr/tei:title, '. ')}</span>
    let $date := concat('(', $monogr/tei:imprint/tei:date, ')')
    let $biblScope := concat(
        if($monogr/tei:imprint/tei:biblScope[@type = 'vol']) then concat(', ', wega:getLanguageString('vol', $lang), '&#160;', $monogr/tei:imprint/tei:biblScope[@type = 'vol']) else (),
        if($monogr/tei:imprint/tei:biblScope[@type = 'jg']) then concat(', ', 'Jg.', '&#160;', $monogr/tei:imprint/tei:biblScope[@type = 'jg']) else (),
        if($monogr/tei:imprint/tei:biblScope[@type = 'issue']) then concat(', ', wega:getLanguageString('issue', $lang), '&#160;', $monogr/tei:imprint/tei:biblScope[@type = 'issue']) else (),
        if($monogr/tei:imprint/tei:biblScope[@type = 'nr']) then concat(', ', 'Nr.', '&#160;', $monogr/tei:imprint/tei:biblScope[@type = 'nr']) else (),
        if(exists($monogr/tei:imprint/tei:date)) then concat(' ', $date) else (),
        if($monogr/tei:imprint/tei:biblScope[@type = 'pp']) then concat(', ', wega:getLanguageString('pp', $lang), '&#160;', replace($monogr/tei:imprint/tei:biblScope[@type = 'pp'], '-', '–')) else (),
        if($monogr/tei:imprint/tei:biblScope[@type = 'col']) then concat(', ', wega:getLanguageString('col', $lang), '&#160;', replace($monogr/tei:imprint/tei:biblScope[@type = 'col'], '-', '–')) else ()
    )
    return 
        element {$wrapperElement} {
            $journalTitle,
            $biblScope
        }
};

(:~
 : Create a bibliographic citation for a series
 : Helper function for various wega:print*Citation() 
 : 
 : @author Peter Stadler
 : @param $series the TEI monogr element with the bibliographic reference of the journal
 : @param $wrapperElement the HTML element for wrapping the output (usually span or li)
 : @param $lang the language switch (en, de)
 : @return element
 :)

declare function wega:printSeriesCitation($series as element(tei:series), $wrapperElement as xs:string, $lang as xs:string) as element() {
    let $seriesTitle := string-join($series/tei:title, '. ')
(:    let $date := concat('(', $monogr/tei:imprint/tei:date, ')'):)
    let $biblScope := concat(
        if($series/tei:biblScope[@type = 'vol']) then concat(', ', wega:getLanguageString('vol', $lang), '&#160;', $series/tei:biblScope[@type = 'vol']) else (),
        if($series/tei:biblScope[@type = 'issue']) then concat(', ', wega:getLanguageString('issue', $lang), '&#160;', $series/tei:biblScope[@type = 'issue']) else ()
    )
    return 
        element {$wrapperElement} {
            string-join(($seriesTitle, $biblScope), '')
        }
};

(:~
 : Create a bibliographic citation for an incollection entry type
 : 
 : @author Peter Stadler
 : @param $biblStruct the TEI biblstruct element with the bibliographic information
 : @param $wrapperElement the HTML element for wrapping the output (usually span or li) 
 : @param $lang the language switch (en, de)
 : @return element
 :)
 
declare function wega:printIncollectionCitation($biblStruct as element(tei:biblStruct), $wrapperElement as xs:string, $lang as xs:string) as element() {
    let $authors := wega:printCitationAuthors($biblStruct//tei:author, $lang)
    let $editor := wega:printCitationAuthors($biblStruct//tei:editor, $lang)
    let $articleTitle := <span class="title">{string-join($biblStruct/tei:analytic/tei:title, '. ')}</span>
    let $bookTitle := <span class="collectionTitle">{string-join($biblStruct/tei:monogr/tei:title, '. ')}</span>
    let $pubPlaceNYear := wega:printpubPlaceNYear($biblStruct//tei:imprint)
    let $series := if(exists($biblStruct/tei:series/tei:title)) then wega:printSeriesCitation($biblStruct/tei:series, 'span', $lang) else ()
    return 
        element {$wrapperElement} {
            $authors,
            ', ',
            $articleTitle,
            ', in: ',
            $bookTitle,
            if(exists($editor)) then (concat(', ', wega:getLanguageString('edBy', $lang), ' '), $editor) else (),
            if(exists($series)) then (' ', <span class="series">{concat('(= ', $series, ')')}</span>) else (),
            if(exists($pubPlaceNYear)) then (', ', $pubPlaceNYear) else(),
            if($biblStruct//tei:imprint/tei:biblScope[@type = 'pp']) then concat(', ', wega:getLanguageString('pp', $lang), '&#160;', replace($biblStruct//tei:imprint/tei:biblScope[@type = 'pp'], '-', '–')) else ()
        }
};

(:~
 : Helper function for wega:print*Citation() functions
 : 
 : @author Peter Stadler
 : @param $authors zero or more tei:author elements 
 : @param $lang the language switch (en, de)
 : @return item
 :)
 
declare function wega:printCitationAuthors($authors as element()*, $lang as xs:string) as item()* {
    let $countAuthors := count($authors)
    return 
    for $i at $counter in $authors
        return (
            wega:printCorrespondentName($i, $lang, 'sf'),
            if($counter lt $countAuthors - 1) then ', '
            else if($counter eq $countAuthors - 1) then concat(' ', wega:getLanguageString('and', $lang), ' ')
            else ()
        )
};

(:~
 : Helper function for wega:print*Citation() functions
 : Creates a html:span element with pubPlaces and date as content 
 : 
 : @author Peter Stadler
 : @param $imprint a tei:imprint element 
 : @return html:span element if any data is given, the empty sequence otherwise
 :)
 
declare function wega:printpubPlaceNYear($imprint as element(tei:imprint)) as element(span)? {
    let $countPlaces := count($imprint/tei:pubPlace)
    let $places := 
        for $place at $count in $imprint/tei:pubPlace
        return (
            if($count eq $countPlaces) then normalize-space($place)
            else if($count eq $countPlaces - 1) then concat(normalize-space($place), ' &amp; ')
            else concat(normalize-space($place), ', ')
        )
    return 
        if($countPlaces ge 1 or $imprint/tei:date/@when castable as xs:date or $imprint/tei:date/@when castable as xs:gYear) then <span class="placeNYear">{string-join($places, ''), normalize-space($imprint/tei:date)}</span>
        else ()
};

(:~
 : Create html output of tei:sourceDesc
 : 
 : @author Peter Stadler
 : @param $doc the TEI document with tei:sourceDesc
 : @param $lang the language switch (en, de)
 : @return element
 :)
 
declare function wega:printSourceDesc($doc as document-node(), $lang as xs:string) as element(div) {
    let $xslParams := <parameters><param name="lang" value="{$lang}"/></parameters>
    let $docID := $doc/tei:TEI/@xml:id cast as xs:string
    return
    <div class="clearfix">
        <h2 class="headWithToggleMarker">{wega:getLanguageString('editorial',$lang)}</h2>
        <a class="toggleMarker" title="{wega:getLanguageString('showEditorial',$lang)}" onclick="$('editorial').toggle();$('show').toggle();$('hide').toggle()"><span id="show">({wega:getLanguageString('show',$lang)})</span><span id="hide" style="display:none">({wega:getLanguageString('hide',$lang)})</span></a>
        <br class="clearer"/>
        <div id="editorial" style="display:none">
            <h3 id="series">{wega:getLanguageString('series',$lang)}</h3>
            <p>{data($doc//tei:titleStmt/tei:title[@level='s'])}</p>
                            
            <h3 id="resp">{wega:getLanguageString('transcription',$lang)}</h3>
            <ul>{for $name in $doc//tei:respStmt/tei:name return <li>{data($name)}</li>}</ul>
                            
            {if(exists($doc//tei:listWit)) 
                then (<h3 class="headWithToggleMarker">{wega:getLanguageString('textSources',$lang)}</h3>,
                     <ol class="toggleMarkerList">
                        {for $i at $count in $doc//tei:listWit/tei:witness 
                            order by $i/@n ascending 
                            return
                            <li><a onclick="switchActivTab('witness','{concat('source_', $count)}')">[{$i/data(@n)}]</a></li>
                        }
                     </ol>,
                     <br class="clearer"/>
                     )
                else <h3>{wega:getLanguageString('textSource',$lang)}</h3>
            }
            <div>{
                (: Drei mögliche Kinder (neben tei:correspDesc) von sourceDesc: tei:msDesc, tei:listWit, tei:biblStruct :)
                if(not(functx:all-whitespace($doc//tei:sourceDesc/tei:listWit))) then transform:transform($doc//tei:sourceDesc/tei:listWit, doc("/db/webapp/xsl/sourceDesc.xsl"), $xslParams)
                else if(not(functx:all-whitespace($doc//tei:sourceDesc/tei:msDesc))) then transform:transform($doc//tei:sourceDesc/tei:msDesc, doc("/db/webapp/xsl/sourceDesc.xsl"), $xslParams)
                else if(not(functx:all-whitespace($doc//tei:sourceDesc/tei:biblStruct))) then wega:printCitation($doc//tei:sourceDesc/tei:biblStruct, 'p', $lang)                
                else (<span class="noDataFound">{wega:getLanguageString('noDataFound',$lang)}</span>)
            }</div>
            {if(exists($doc//tei:creation)) then (
            	<h3>{wega:getLanguageString('creation',$lang)}</h3>,
            	<ul>
            		<li>{transform:transform($doc//tei:creation, doc("/db/webapp/xsl/sourceDesc.xsl"), $xslParams)}</li>
            	</ul>
            	)
            else ()	
            }
        </div>
    </div>
};

(:~
 : Get resources from the web by PND and store the result in a cache object with the current date. 
 : If the date does match with today's date then the result will be taken from the cache; otherwise the external resource will be queried.
 : ATTENTION: Wikipedia sends HTMl pages without namespace
 :
 : @author Peter Stadler 
 : @param $resource the external resource (wikipedia|adb|dnb)
 : @param $pnd the PND number
 : @param $lang the language variable (de|en). If no language is specified, the default (German) resource is grabbed and served
 : @param $useCache use cached version or force a reload of the external resource
 : @return node
 :)
 declare function wega:grabExternalResource($resource as xs:string, $pnd as xs:string, $lang as xs:string?, $useCache as xs:boolean) as element(httpclient:response)? {
    let $serverURL := 
        if($resource eq 'wikipedia') then concat(wega:getOption($resource), $lang, '/')
        else wega:getOption($resource)
    let $fileName := string-join(($pnd, $lang, 'xml'), '.')
    let $today := current-date()
    let $cachedResource := doc(concat(wega:getOption('tmpDir'), $resource, '/', $fileName))/wega:externalResource
    let $response := 
        if($cachedResource/httpclient:response/@statusCode eq '200' and $cachedResource/xs:date(@date) eq $today and $useCache) then (
           (:util:log-system-out(concat($pnd, ': cached version')),:) 
           $cachedResource/httpclient:response
           )
        else 
           (:let $responseOrg := httpclient:get(xs:anyURI(concat($serverURL, $pnd)),true(), ())
           let $modifiedResponse := 
               if($responseOrg/httpclient:body[matches(@mimetype,"text/html")]) then wega:changeNamespace($responseOrg,'http://www.w3.org/1999/xhtml', 'http://exist-db.org/xquery/httpclient')
               else $responseOrg
           let $responseFrame :=
               <wega:externalResource date="{$today}">
                   {$modifiedResponse}
               </wega:externalResource>
           let $storeFile := wega:storeFileInTmpCollection($resource, $fileName, $responseFrame)
           return $modifiedResponse:)
           let $update := wega:http-get(xs:anyURI(concat($serverURL, $pnd)))
           let $storeFile := wega:storeFileInTmpCollection($resource, $fileName, $update)
           return $update/httpclient:response
    return 
        if($response/@statusCode eq '200') then $response 
        else ()
};


(:~
 : Helper function for wega:grabExternalResource()
 :
 : @author Peter Stadler 
 : @param $url the URL as xs:anyURI
 : @return element wega:externalResource, a wrapper around httpclient:response
 :)
declare %private function wega:http-get($url as xs:anyURI) as element(wega:externalResource) {
    let $req := <http:request href="{$url}" method="get" timeout="3"/>
    let $response := 
        try { http:send-request($req) }
        catch * {wega:logToFile('error', string-join(('wega:http-get', $err:code, $err:description), ' ;; '))}
    let $statusCode := $response[1]/data(@status)
    return
        <wega:externalResource date="{current-date()}">
            <httpclient:response statusCode="{$statusCode}">
                <httpclient:headers>{
                    for $header in $response[1]//http:header
                    return element httpclient:header {$header/@*}
                }</httpclient:headers>
                <httpclient:body mimetype="{$response[1]//http:body/data(@media-type)}">
                    {$response[2]}
                </httpclient:body>
            </httpclient:response>
        </wega:externalResource>
};

(:~
 : Store some content as file in the webapp tmp collection   
 : 
 : @author Peter Stadler
 : @param $subCollection the subcollection of the tmp collection to put the file in. If empty, the content will be stored in tmp directly 
 : @param $fileName the filename of the to be created resource with filename extension
 : @param $contents the content to store. Either a node, an xs:string, a Java file object or an xs:anyURI 
 : @return Returns the path to the newly created resource, empty sequence otherwise
 :)
declare function wega:storeFileInTmpCollection($subCollection as xs:string?, $fileName as xs:string, $contents as item()) as xs:string? {
    let $tmpDir := wega:getOption('tmpDir')
    let $dbCollection := 
        if(empty($subCollection)) then $tmpDir
        else (
            let $path := string-join(($tmpDir, $subCollection), '')
            return 
                if(xmldb:collection-available($path)) then $path
                else xmldb:create-collection($tmpDir, $subCollection)
        )
    return 
        util:catch(
            '*', 
            xmldb:store($dbCollection, $fileName, $contents), 
            wega:logToFile('error', string-join(('wega:storeFileInTmpCollection', $util:exception, $util:exception-message), ' ;; '))
        )
};

(:~
 : @author Peter Stadler
 : Recursive identity transform with changing of namespace for a given element.
 :
 : @author Peter Stadler
 : @param $element the source element 
 : @param $targetNamespace the new namespace for $element
 : @param $keepNamespaces an list of namespaces that shall not be changed
 : @return a cloned element within the target namespace
 :)
 
declare function wega:changeNamespace($element as element(), $targetNamespace as xs:string, $keepNamespaces as xs:string*) as element() {
    if(fn:namespace-uri($element) = $keepNamespaces) then 
        element {node-name($element)}
            {$element/@*,
            for $child in $element/node()
            return 
                if ($child instance of element()) then wega:changeNamespace($child, $targetNamespace, $keepNamespaces)
                else $child
            }
  else element {QName($targetNamespace,local-name($element))}
            {$element/@*,
            for $child in $element/node()
            return 
                if ($child instance of element()) then wega:changeNamespace($child, $targetNamespace, $keepNamespaces)
                else $child}
};

(:~
 : Get portrait (i.e. the first picture on the page) from an wikipedia article
 :
 : @author Peter Stadler 
 : @param $pnd the PND number
 : @param $lang the language variable (de|en)
 : @return element the local path to the stored file
 :)
 
declare function wega:retrieveImagesFromWikipedia($pnd as xs:string, $lang as xs:string) as element(wega:wikipediaImages) {
    let $wikiArticle := wega:grabExternalResource('wikipedia', $pnd, $lang, true())
    let $pics := $wikiArticle//xhtml:div[@class='thumbinner']
(:    let $log := util:log-system-out(($pnd, $lang)):)
    return 
        <wega:wikipediaImages>{
            for $div in $pics
            let $caption := normalize-space(concat($div/xhtml:div[@class='thumbcaption'],' (', wega:getLanguageString('sourceWikipedia', $lang), ')'))
            let $tmpPicURI := $div//xhtml:img[@class='thumbimage']/string(@src)
            let $picURI := if(starts-with($tmpPicURI, '//')) then concat('http:', $tmpPicURI) else $tmpPicURI
            let $localURL := wega:retrievePicture(string($picURI), ())
                return if(exists($localURL)) then
                    <wega:wikipediaImage>
                        <wega:caption>{$caption}</wega:caption>
                        <wega:orgUrl>{$picURI}</wega:orgUrl>
                        <wega:localUrl>{$localURL}</wega:localUrl>
                    </wega:wikipediaImage>
                    else ()
        }</wega:wikipediaImages>
};

(:~
 : Retrieve a picture from any URI and store it in the database
 :
 : @author Peter Stadler
 : @param $picURL the URL to the file as xs:string
 : @param $localName the fileName within the local db. If empty, a hash of the $picURL will be taken as fileName
 : @return xs:string the local path to the stored file 
 :)
 
declare function wega:retrievePicture($picURL as xs:string, $localName as xs:string?) as xs:string? {
    let $suffix := lower-case(functx:substring-after-last($picURL, '.'))
(:    let $log := util:log-system-out($picURL):)
    let $localFileName :=  if(matches($localName, '\S')) 
        then $localName
        else util:hash($picURL, 'md5')
    let $tmpDir := wega:getOption('tmpDir')
    let $localDbCollection := if(matches($localFileName, '^A\d{6}$'))
        then if(xmldb:collection-available(concat($tmpDir, replace($localFileName, '\d{2}$', 'xx'))))
            then concat($tmpDir, replace($localFileName, '\d{2}$', 'xx'))
            else xmldb:create-collection($tmpDir, replace($localFileName, '\d{2}$', 'xx'))
        else if(xmldb:collection-available(concat($tmpDir, replace($localFileName, '^(\w{2})\w+', '$1xxx'))))
            then concat($tmpDir, replace($localFileName, '^(\w{2})\w+', '$1xxx'))
            else xmldb:create-collection($tmpDir, replace($localFileName, '^(\w{2})\w+', '$1xxx'))
    let $pathToLocalFile := concat($localDbCollection, '/', $localFileName, '.', $suffix)
    let $storeFile := 
        if (util:binary-doc-available($pathToLocalFile)) then () 
        else util:catch('*', xmldb:store($localDbCollection, concat($localFileName, '.', $suffix), xs:anyURI($picURL)), wega:logToFile('error', string-join(('wega:retrievePicture', $util:exception, $util:exception-message), ' ;; ')))
    let $storePicMetaData := wega:storePicMetadata($pathToLocalFile, $picURL)
(:    let $mimeType := $pic//httpclient:body/string(@mimetype):)
    return 
        if (util:binary-doc-available($pathToLocalFile) and wega:getPicMetadata($pathToLocalFile)) then $pathToLocalFile (: Datei bereits vorhanden :)
        else ()
};

(:~
 : Stores picture meta data
 :
 : @author Peter Stadler
 : @param $pathToLocalFile
 : @param $origURL
 : @return xs:string?
 :)

declare function wega:storePicMetadata($pathToLocalFile as xs:string, $origURL as xs:string) as xs:string? {
    let $localDbCollection := functx:substring-before-last($pathToLocalFile, '/')
    let $localFileName := functx:substring-after-last($pathToLocalFile, '/')
    (:let $pic := util:binary-doc($pathToLocalFile):)
    let $picHeight := util:catch('*', image:get-height(util:binary-doc($pathToLocalFile)), wega:logToFile('error', string-join(('wega:storePicMetadata', $util:exception, $util:exception-message), ' ;; ')))
    let $picWidth := util:catch('*', image:get-width(util:binary-doc($pathToLocalFile)), wega:logToFile('error', string-join(('wega:storePicMetadata', $util:exception, $util:exception-message), ' ;; ')))
    let $metadata := 
        <picMetadata>
            <localFile>{$pathToLocalFile}</localFile>
            <origURL>{$origURL}</origURL>
            <width>{concat($picWidth, 'px')}</width>
            <height>{concat($picHeight, 'px')}</height>
        </picMetadata>
    return if($picWidth instance of xs:integer and $picHeight instance of xs:integer)
        then util:catch('*', xmldb:store($localDbCollection, concat(functx:substring-before-last($localFileName, '.'), '.xml'), $metadata), wega:logToFile('error', string-join(('wega:storePicMetadata', $util:exception, $util:exception-message), ' ;; ')))
        else ()
};

(:~
 : Gets picture meta data
 :
 : @author Peter Stadler
 : @param $pathToLocalFile
 : @param $origURL
 : @return xs:string?
 :)

declare function wega:getPicMetadata($localPicURL as xs:string) as node()? {
    let $tmpDir := wega:getOption('tmpDir')
    let $unknownWoman := wega:getOption('unknownWoman')
    let $unknownMan := wega:getOption('unknownMan')
    let $unknownSex := wega:getOption('unknownSex')
    return 
    if (starts-with($localPicURL, $tmpDir))
        then doc(concat(functx:substring-before-last($localPicURL, '.'), '.xml'))/picMetadata
        else if($localPicURL eq $unknownMan or $localPicURL eq $unknownWoman or $localPicURL eq $unknownSex) 
            then <picMetadata>
                    <localFile>{$localPicURL}</localFile>
                    <origURL/>
                    <width>140px</width>
                    <height>185px</height>
                </picMetadata>
            else
                let $picFile := functx:substring-after-last($localPicURL, '/')
                let $metadataFile := collection('/db/iconography')//tei:graphic[@url = $picFile]
                return
                <picMetadata>
                    <localFile>{$localPicURL}</localFile>
                    <origURL/>
                    <width>{$metadataFile/string(@width)}</width>
                    <height>{$metadataFile/string(@height)}</height>
                </picMetadata>
};

(:~
 : Creates digilib URL
 :
 : @author Peter Stadler
 : @param $localPicURL
 : @param $dimensions of image
 : @param $trim 
 : @return xs:string?
 :)

declare function wega:createDigilibURL($localPicURL as xs:string, $dimensions as xs:integer+, $trim as xs:boolean) as xs:string? {
    let $picMetadata := wega:getPicMetadata($localPicURL)
    let $tmpDir := wega:getOption('tmpDir')
    let $pixDir := wega:getOption('pixDir')
    let $imagesDir := wega:getOption('imagesDir')
    let $digilibDir := wega:getOption('digilibDir')
    let $picHeight := if(exists($picMetadata/height)) then xs:int(substring-before($picMetadata/height, 'px')) else 1
    let $picWidth := if(exists($picMetadata/width)) then xs:int(substring-before($picMetadata/width, 'px')) else 1
    let $dw := $dimensions[1]
    let $dh := $dimensions[2]
    let $ratioW := $picWidth div $dw
    let $ratioH := $picHeight div $dh
    let $ww := if(($ratioW gt $ratioH) and $trim) 
        then round-half-to-even($ratioH div $ratioW, 2)
        else 1
    let $wh := if(($ratioH gt $ratioW) and $trim) 
        then round-half-to-even($ratioW div $ratioH, 2)
        else 1
    let $wx := (1 - $ww) div 2
    let $digilibParams := concat('&#38;dw=', string($dw), '&#38;dh=', string($dh), '&#38;ww=', string($ww), '&#38;wh=', string($wh), '&#38;wx=', string($wx), '&#38;mo=q2')
    return if(starts-with($localPicURL, $tmpDir))
        then concat(replace($localPicURL, '/db/webapp/', $digilibDir), $digilibParams)
        else if(starts-with($localPicURL, $pixDir))
            then concat(replace($localPicURL, '/db/webapp/', $digilibDir), $digilibParams)
            else if(starts-with($localPicURL, $imagesDir))
                then concat(replace($localPicURL, $imagesDir, $digilibDir), $digilibParams)
                else ()
};

(:~
 : Creates digilib URL
 :
 : @author Peter Stadler
 : @param $localPicURL
 : @param $crop
 : @return xs:string? 
 :)

declare function wega:createDigilibURL($localPicURL as xs:string, $crop as xs:boolean) as xs:string? {
(:    let $log := util:log-system-out($localPicURL):)
    let $tmpDir := wega:getOption('tmpDir')
    let $pixDir := wega:getOption('pixDir')
    let $imagesDir := wega:getOption('imagesDir')
    let $digilibDir := wega:getOption('digilibDir')
    let $digilibParams := if($crop)
        then '&#38;dw=400&#38;dh=600'
        else '&#38;mo=file'
    return if(starts-with($localPicURL, $tmpDir))
        then concat(replace($localPicURL, '/db/webapp/', $digilibDir), $digilibParams)
        else if(starts-with($localPicURL, $pixDir))
            then concat(replace($localPicURL, '/db/webapp/', $digilibDir), $digilibParams)
            else if(starts-with($localPicURL, $imagesDir))
                then concat(replace($localPicURL, $imagesDir, $digilibDir), $digilibParams)
                else ()
};

(:~
 : Normalize space
 :
 : @author Peter Stadler
 : @param $string that should be normalized
 : @return xs:string
 :)

declare function wega:cleanString($string as xs:string?) as xs:string {
    normalize-space(replace($string, '&#8194;', ' '))
};

(:~
 : Create a form for filtering journal and news articles by year (used by person_writings.xql and bibliography.xql)
 :
 : @author Peter Stadler
 : @param $writings the collection of writings 
 : @param $lang the front end language
 : @return HTML form with a checkbox for each year 
:)
 
declare function wega:printPubYears($writings as node()*, $lang as xs:string) as element() {
(:    let $pubDates := $writings//(tei:monogr//tei:date/@when | tei:publicationStmt/tei:date/@when):)
    let $years := for $i in 
        (:distinct-values(functx:value-union($writings//tei:monogr//tei:date/year-from-date(xs:date(@when)), $writings//tei:publicationStmt/tei:date/year-from-dateTime(xs:dateTime(@when)))):) (:articles and news:)
        distinct-values($writings//(tei:monogr//tei:date/@when | tei:publicationStmt/tei:date/@when))
            let $year := if($i castable as xs:dateTime) 
                then year-from-dateTime(xs:dateTime($i))
                else year-from-date(xs:date($i))
            order by $year descending
            return $year
    return
    <form id="formYear" method="get" action="javascript:filterByYear()">
        <h2>Jahrgang</h2>
        {for $i at $count in distinct-values($years)
            return (<label class="labelYear"><input type="checkbox" checked="checked" class="itemCheckbox" name="checkYear" value="{$i}"/>{string($i)}</label>,
                    if(($count mod 3) eq 0) then <br/> else()
                    )
        }
        <label class="checkAll"><input type="checkbox" name="checkAll" onclick="checkAllBoxes('formYear', this.checked);" checked="checked"/>{wega:getLanguageString('checkAll', $lang)}</label>
        <p><input type="submit" value="{wega:getLanguageString('apply', $lang)}"/></p>
    </form>
};

(:~
 : Create a form for filtering journal articles by journal name (used by person_writings.xql and bibliography.xql)
 :
 : @author Peter Stadler
 : @param $writings the collection of writings 
 : @param $lang the current language (de|en)
 : @return HTML form with a checkbox for each journal 
:)

declare function wega:printJournals($writings as node()*, $lang as xs:string) as element() {
    let $journals := for $i in distinct-values($writings//tei:monogr/tei:title[@level='j'])
                    order by $i ascending
                    return $i
    return 
    <form id="formJournal" method="get" action="javascript:filterByJournal()">
        <h2>Zeitschrift</h2>
        {for $i in $journals
            return (<label class="labelJournal"><input type="checkbox" checked="checked" class="itemCheckbox" name="checkJournal" value="{util:hash($i, 'md5')}"/>{$i}</label>)
        }
        <label class="checkAll"><input type="checkbox" name="checkAll" onclick="checkAllBoxes('formJournal', this.checked);" checked="checked"/>{wega:getLanguageString('checkAll', $lang)}</label>
        <p><input type="submit" value="{wega:getLanguageString('apply', $lang)}"/></p>
    </form>
};


(:~
 : Grabs the first author from a TEI document
 :
 : @author Peter Stadler 
 : @param $item the id of the TEI document (or the document node itself) to grab the author from
 : @return xs:string the name of the author as given by //tei:fileDesc/tei:titleStmt/tei:author[1]
:)

declare function wega:getAuthorOfTeiDoc($item as item()) as xs:string {
    let $doc := typeswitch($item)
        case xs:string return wega:doc($item)/*
        default return $item/*
    let $docID := typeswitch($item)
        case xs:string return $item
        default return $doc/root()/*/@xml:id cast as xs:string
    return 
        if(exists($doc)) then 
            if(wega:isDiary($docID)) then 'A002068' (: Diverse Sonderbehandlungen fürs Tagebuch :)
            else if(wega:isWork($docID)) then  (: Diverse Sonderbehandlungen für Werke :)
                if(exists($doc//mei:titleStmt/mei:respStmt/mei:persName[@role = 'cmp'][1]/@dbkey)) then $doc//mei:titleStmt/mei:respStmt/mei:persName[@role = 'cmp'][1]/string(@dbkey)
                else if(exists($doc/mei:ref)) then ''
                else wega:getOption('anonymusID')
            else if(exists($doc//tei:fileDesc/tei:titleStmt/tei:author[1]/@key)) then $doc//tei:fileDesc/tei:titleStmt/tei:author[1]/string(@key)
            else if(exists($doc/tei:ref)) then wega:getAuthorOfTeiDoc($doc/tei:ref/@target cast as xs:string)
            else wega:getOption('anonymusID')
        else ''
};

(:~
 : Checks the id for well-formedness and returns its collection path. Doesn't check for availability!
 :
 : @author Peter Stadler
 : @param $docID the id of the TEI document
 : @return xs:string the collection path of the document 
:)

declare function wega:getCollectionPath($docID as xs:string) as xs:string? {
    concat(wega:getOption(wega:getDoctypeByID($docID)), '/', substring($docID, 1, 5), 'xx')
};

(:~
 : Gets writing header
 :
 : @author Peter Stadler
 : @param $doc document node
 : @param $lang the current language (de|en)
 : @return element
 :)

declare function wega:getWritingHead($doc as document-node(), $xslParams as element(parameters), $lang as xs:string) as item()* {
    let $xslParamsHeader := 
        <parameters>
            {$xslParams/*}
            <param name="headerMode" value="true"/>
        </parameters>
    return 
        for $i in transform:transform($doc//tei:fileDesc/tei:titleStmt, doc("/db/webapp/xsl/doc_text.xsl"), $xslParamsHeader)
        return wega:changeNamespace($i, '', ())
};

(:~
 : Gets letter header
 :
 : @author Peter Stadler
 : @param $doc document node
 : @param $lang the current language (de|en)
 : @return element
 :)

declare function wega:getLetterHead($doc as document-node(), $lang as xs:string) as element()+ {
    let $docTitle := $doc//tei:fileDesc/tei:titleStmt/tei:title[@level="a"]
    return if($docTitle ne '') 
        then (
            element h1 { $docTitle/text()[1] },
            element h2 { $docTitle/text()[2] }
        )
        else wega:constructLetterHead($doc, $lang)
};

(:~
 : Constructs letter header
 :
 : @author Peter Stadler
 : @param $doc document node
 : @param $lang the current language (de|en)
 : @return element
:)

declare function wega:constructLetterHead($doc as document-node(), $lang as xs:string) as element()+ {
    let $id := $doc//tei:TEI/string(@xml:id)
    let $date := if(exists(wega:getOneNormalizedDate($doc//tei:dateSender/tei:date[1], false())))
        then wega:getNiceDate(wega:getOneNormalizedDate($doc//tei:dateSender/tei:date[1], false()), $lang)
        else wega:getLanguageString('undated', $lang)
    let $sender := wega:printCorrespondentName($doc//tei:sender/*[1], $lang, 'fs')
    let $addressee := wega:printCorrespondentName($doc//tei:addressee/*[1], $lang, 'fs')
    let $placeSender := if(normalize-space($doc//tei:placeSender) ne '') then normalize-space($doc//tei:placeSender) else ()
    let $placeAddressee := if(normalize-space($doc//tei:placeAddressee) ne '') then normalize-space($doc//tei:placeAddressee) else ()
    return (
        element h1 {
            concat($sender, ' ', lower-case(wega:getLanguageString('to', $lang)), ' ', $addressee),
            if(exists($placeAddressee)) then concat(' ', lower-case(wega:getLanguageString('in', $lang)), ' ', $placeAddressee) else()
        },
        element h2 {
            string-join(($placeSender, $date), ', ')
        }
    )
};

(:~
 : Creates link to doc
 :
 : @author Peter Stadler
 : @param $doc document node
 : @param $lang the current language (de|en)
 : @return xs:string
:)

declare function wega:createLinkToDoc($doc as document-node(), $lang as xs:string) as xs:string? {
    let $docID :=  $doc/*/@xml:id cast as xs:string
    let $authorId := wega:getAuthorOfTeiDoc($doc)
    let $folder := 
        if(wega:isLetter($docID)) then wega:getLanguageString('correspondence', $lang) (: Ausnahme für Briefe=Korrespondenz:)
        else if(wega:isWeberStudies($doc)) then wega:getLanguageString('weberStudies', $lang)
        else wega:getLanguageString(wega:getDoctypeByID($docID), $lang)
    return 
        if(wega:isPerson($docID)) then string-join((wega:getOption('baseHref'), $lang, $docID), '/') (: Ausnahme für Personen, die direkt unter {baseref}/{lang}/ angezeigt werden:)
        else if(wega:isBiblio($docID)) then 
            if(wega:isWeberStudies($doc)) then string-join((wega:getOption('baseHref'), $lang, wega:getLanguageString('publications', $lang), $folder, $docID), '/')
            else ()
        else if(exists($folder) and $authorId ne '') then string-join((wega:getOption('baseHref'), $lang, $authorId, $folder, $docID), '/')
        else ()
};

(:~
 : Checks whether a given id matches the WeGA pattern of person ids
 :
 : @author Peter Stadler
 : @param $docID the id to test as string
 : @return xs:boolean
:)

declare function wega:isPerson($docID as xs:string) as xs:boolean {
    matches($docID, '^A00\d{4}$')
};

(:~
 : Checks whether a given id matches the WeGA pattern of iconography ids
 :
 : @author Peter Stadler
 : @param $docID the id to test as string
 : @return xs:boolean
:)

declare function wega:isIconography($docID as xs:string) as xs:boolean {
    matches($docID, '^A01\d{4}$')
};

(:~
 : Checks whether a given id matches the WeGA pattern of work ids
 :
 : @author Peter Stadler
 : @param $docID the id to test as string
 : @return xs:boolean
:)

declare function wega:isWork($docID as xs:string) as xs:boolean {
    matches($docID, '^A02\d{4}$')
};

(:~
 : Checks whether a given id matches the WeGA pattern of writing ids
 :
 : @author Peter Stadler
 : @param $docID the id to test as string
 : @return xs:boolean
:)

declare function wega:isWriting($docID as xs:string) as xs:boolean {
    matches($docID, '^A03\d{4}$')
};

(:~
 : Checks whether a given id matches the WeGA pattern of letter ids
 :
 : @author Peter Stadler
 : @param $docID the id to test as string
 : @return xs:boolean
:)

declare function wega:isLetter($docID as xs:string) as xs:boolean {
    matches($docID, '^A04\d{4}$')
};

(:~
 : Checks whether a given id matches the WeGA pattern of news ids
 :
 : @author Peter Stadler
 : @param $docID the id to test as string
 : @return xs:boolean
:)

declare function wega:isNews($docID as xs:string) as xs:boolean {
    matches($docID, '^A05\d{4}$')
};

(:~
 : Checks whether a given id matches the WeGA pattern of diary ids
 :
 : @author Peter Stadler
 : @param $docID the id to test as string
 : @return xs:boolean
:)

declare function wega:isDiary($docID as xs:string) as xs:boolean {
    matches($docID, '^A06\d{4}$')
};

(:~
 : Checks whether a given id matches the WeGA pattern of var ids
 :
 : @author Peter Stadler
 : @param $docID the id to test as string
 : @return xs:boolean
:)

declare function wega:isVar($docID as xs:string) as xs:boolean {
    matches($docID, '^A07\d{4}$')
};

(:~
 : Checks whether a given id matches the WeGA pattern of biblio ids
 :
 : @author Peter Stadler
 : @param $docID the id to test as string
 : @return xs:boolean
:)

declare function wega:isBiblio($docID as xs:string) as xs:boolean {
    matches($docID, '^A11\d{4}$')
};

(:~
 : Checks whether a given document is from the series "Weber-Studien" published by the WeGA
 :
 : @author Peter Stadler
 : @param $docID the id to test as string
 : @return xs:boolean
:)

declare function wega:isWeberStudies($doc as document-node()) as xs:boolean {
    $doc//tei:series/tei:title[@level = 's'] = 'Weber-Studien'
};

(:~
 : Checks whether a given string matches the defined types of bibliographic objects
 :
 : @author Peter Stadler
 : @param $string the string to test
 : @return xs:boolean
:)

declare function wega:isBiblioType($string as xs:string) as xs:boolean {
    $string = ('mastersthesis', 'inbook', 'online', 'review', 'book', 'misc', 'inproceedings', 'article', 'score', 'incollection', 'phdthesis')
};

(:~
 : Number to roman (string?)
 :
 : @author Source: http://contentmangler.wordpress.com/
 : @param $num
 : @return xs:string
~:)
declare function wega:number-to-roman($num as xs:integer?) as xs:string {
    if(not($num castable as xs:int)) then ''
    else if($num eq 0) then ''
    else if($num gt 3999) then wega:logToFile('error', 'wega:number-to-roman(): Cannot Convert Number Larger than 3999')
    else wega:recursive-roman($num,'',$wega:romanNums)
};

(:~
 : Recursion Method used to calculate the roman numeral
 :
 : @author Source: http://contentmangler.wordpress.com/
 : @param $num
 : @param $alpha
 : @param $sequences
 : @return xs:String
~:)

declare function wega:recursive-roman($num as xs:integer, $alpha as xs:string, $sequences as xs:integer*) as xs:string {
    let $i := $sequences[1]
    let $rom-a := $wega:romanAlpha[index-of($wega:romanNums,$i)]
    return
        if(empty($sequences) and $num eq 0) then $alpha
        else if($num gt $i) then wega:recursive-roman($num - $i, concat($alpha,$rom-a),$sequences)
        else if($num lt $i) then wega:recursive-roman($num, $alpha,remove($sequences,1)) 
        else if($num eq $i) then concat($alpha,$rom-a)
        else $alpha
};

(:~
 : Returns the revision status (proposed|candidate|approved) for a given document
 :
 : @author Peter Stadler
 : @param $doc the document 
 : @return xs:string
:)

declare function wega:getRevisionStatus($doc as document-node()) as xs:string {
    if(wega:isLetter($doc/tei:TEI/string(@xml:id))) then $doc//tei:revisionDesc/string(@status)
    else if(wega:isWriting($doc/tei:TEI/string(@xml:id))) then $doc//tei:revisionDesc/string(@status)
    else if(wega:isPerson($doc/tei:person/string(@xml:id))) then $doc/tei:person/string(@status)
    else if(wega:isDiary($doc/tei:ab/string(@xml:id))) then $doc/tei:ab/string(@status)
    else if(wega:isBiblio($doc/*/string(@xml:id))) then if($doc//tei:revisionDesc) then $doc//tei:revisionDesc/string(@status) else $doc/*/string(@status) (: Extra-Wurst für Weber-Studien :)
    else ''
};

(:~
 : Encrypts a string to codepoints and multiplies those with a salt
 :
 : @author Peter Stadler
 : @param $string the string to encrypt
 : @param $salt the salt for encrypting
 : @return xs:int+
:)

declare function wega:encryptString($string as xs:string, $salt as xs:int?) as xs:int+ {
    let $salt := if($salt castable as xs:int) then xs:int($salt) else xs:int(wega:getOption('salt'))
    return for $k in string-to-codepoints($string) return $k cast as xs:int * $salt
};

(:~
 : Obfuscates an email address
 :
 : @author Peter Stadler
 : @param $email the email address
 : @return xs:string
:)

declare function wega:obfuscateEmail($email as xs:string) as xs:string {
    string-join(tokenize($email, ' [at] '), '&#8201;[&#8201;at&#8201;]&#8201;')
};

(:~
 : Output a tei:address (with only tei:addrLine children) as html:ul
 :
 : @author Peter Stadler 
 : @param $address the tei:address element
 : @param $lang the current language (de|en)
 : @param $name the name of the addressee (optional)
 : @return element()
:)

declare function wega:outputAddress($address as element(), $lang as xs:string, $name as xs:string?) as element() {
    <ul>
    {for $i in $address/tei:addrLine
    return 
        <li>{
            if($i/string(@n) eq 'telephone') then concat(wega:getLanguageString('tel',$lang), ': ', $i)
            else if($i/string(@n) eq 'email') then 
                let $encryptedEmail := wega:encryptString($i, ())
                return 
                element span {
                    attribute onclick {"javascript:decEma('",$encryptedEmail,"')"},
                    attribute class {'ema'},
                    if (exists($name)) then attribute title {wega:getLanguageString('sendEmail', $name, $lang)} else (),
                    wega:obfuscateEmail($i)
                }
            else if($i/string(@n) eq 'fax') then concat(wega:getLanguageString('fax',$lang), ': ', $i)
            else $i cast as xs:string
            }
        </li> 
    }
    </ul>
};

(:~
 : Retrieves the WeGA person ID by PND
 :
 : @author Peter Stadler
 : @param $pnd the PND number
 : @return xs:string
:)

declare function wega:getIDByPND($pnd as xs:string) as xs:string {
    collection(wega:getOption('persons'))//tei:idno[.=$pnd][@type='gnd']/parent::tei:person/string(@xml:id)
};

(:~
 : Retrieves the latest (subversion) author for a given document ID
 :
 : @author Peter Stadler
 : @param $docName the document name
 : @return xs:string
:)

declare function wega:getLastAuthorOfDocument($docPath as xs:string) as xs:string? {
    let $docHash := util:hash($docPath, 'md5')
    let $entry := doc(wega:getOption('svnChangeHistoryFile'))//id(concat('_',$docHash))
    return 
        if(exists($entry/@author)) then wega:dictionaryLookup(string($entry/@author),'svnUsers')
        else ()
};

(:~
 : Retrieves the latest (subversion) modify date for a given document ID
 :
 : @author Peter Stadler
 : @param $docName the document name
 : @return xs:dateTime
:)

declare function wega:getLastModifyDateOfDocument($docPath as xs:string) as xs:dateTime? {
    let $docHash := util:hash($docPath, 'md5')
    let $entry := doc(wega:getOption('svnChangeHistoryFile'))//id(concat('_',$docHash))
    return 
        if($entry/@dateTime castable as xs:dateTime) then $entry/@dateTime cast as xs:dateTime
        else ()
};

(:~
 : retrieves the dateTime of last eXist-db update by checking svnChangeHistoryFile
 :
 : @author Peter Stadler
 : @return xs:dateTime
:)

declare function wega:getDateTimeOfLastDBUpdate() as xs:dateTime? {
    xmldb:last-modified(functx:substring-before-last(wega:getOption('svnChangeHistoryFile'), '/'), functx:substring-after-last(wega:getOption('svnChangeHistoryFile'), '/'))
};

(:~
 : returns whether eXist-DB was updated after a given dateTime. The function tries to cast the given $dateTime as xs:dateTime and returns true() on default if $dateTime is not castable.
 :
 : @author Peter Stadler
 : @param $dateTime the date to check
 : @return xs:boolean
:)

declare function wega:eXistDbWasUpdatedAfterwards($dateTime as xs:dateTime?) as xs:boolean {
    if($dateTime castable as xs:dateTime) then wega:getDateTimeOfLastDBUpdate() gt ($dateTime cast as xs:dateTime)
    else true()
};

(:~
 : Returns the current head revision of the database as given by the 'svnChangeHistoryFile'
 :
 : @author Peter Stadler
 : @return xs:int
:)

declare function wega:getCurrentSvnRev() as xs:int? {
    let $myNode := doc(wega:getOption('svnChangeHistoryFile'))/dictionary/@head
    return 
        if($myNode castable as xs:int) then $myNode cast as xs:int
        else ()
};

(:~
 : Creates letter norm dates
 :
 : @author Peter Stadler
 : @return element
:)

declare function wega:createLetterNormDates() {
    let $docType := 'letters'
(:    let $normDatesFile := wega:getOption(concat($docType, 'NormDatesFile')):)
    let $coll := collection(wega:getOption($docType))//tei:TEI[not(./tei:ref)]
    let $xmlID := concat($docType, 'NormDates')
    let $content :=   
        <dictionary xmlns=""> {
            attribute xml:id {$xmlID},
            for $i in $coll 
            let $docID := $i/string(@xml:id)
            let $normDate := wega:getOneNormalizedDate($i//tei:dateSender/tei:date, false())
            let $n :=  $i//tei:dateSender/tei:date/string(@n)
(:            let $senderID := $i//tei:sender/tei:persName[1]/string(@key):)
            let $authorID := $i//tei:fileDesc/tei:titleStmt/tei:author[1]/string(@key)
            let $addresseeID := $i//tei:addressee/tei:persName[1]/string(@key)
            order by $normDate, $n
            return 
            element entry {
                attribute docID {$docID},
                attribute n {$n},
                attribute authorID {$authorID},
                attribute addresseeID {$addresseeID},
                if ($normDate castable as xs:date) then attribute year {year-from-date($normDate cast as xs:date)} else (),
                if ($normDate castable as xs:date) then attribute month {month-from-date($normDate cast as xs:date)} else (),
                if ($normDate castable as xs:date) then attribute day {day-from-date($normDate cast as xs:date)} else (),
                $normDate
            }
        }</dictionary>  
    return (:if(exists($storeFile))
        then <p>{xmldb:store(functx:substring-before-last($normDatesFile, '/'), functx:substring-after-last($normDatesFile, '/'), $content)}</p>
        else:) $content 
};

(:~
 : Creates writing norm dates
 :
 : @author Peter Stadler
 : @return element
:)

declare function wega:createWritingNormDates() {
    let $docType := 'writings'
(:    let $normDatesFile := wega:getOption(concat($docType, 'NormDatesFile')):)
    let $coll := collection(wega:getOption($docType))//tei:TEI[not(./tei:ref)]
    let $xmlID := concat($docType, 'NormDates')
    let $content :=   
        <dictionary xmlns=""> {
            attribute xml:id {$xmlID},
            for $i in $coll 
            let $docID := $i/string(@xml:id)
            let $normDate := wega:getOneNormalizedDate($i//tei:sourceDesc/tei:*/tei:monogr/tei:imprint/tei:date[1], false())
            let $n :=  string-join($i//tei:monogr/tei:title[@level = 'j'], '. ')
            order by $normDate, $n
            return 
            element entry {
                attribute docID {$docID},
                attribute n {$n},
                if ($normDate castable as xs:date) then attribute year {year-from-date($normDate cast as xs:date)} else (),
                if ($normDate castable as xs:date) then attribute month {month-from-date($normDate cast as xs:date)} else (),
                if ($normDate castable as xs:date) then attribute day {day-from-date($normDate cast as xs:date)} else (),
                $normDate
            }
        }</dictionary>  
    return (:if(exists($storeFile))
        then <p>{xmldb:store(functx:substring-before-last($normDatesFile, '/'), functx:substring-after-last($normDatesFile, '/'), $content)}</p>
        else :)$content 
};

(:~
 : Creates work norm dates
 :
 : @author Peter Stadler
 : @return element
:)

declare function wega:createWorkNormDates() {
    let $docType := 'works'
(:    let $normDatesFile := wega:getOption('worksNormSeriesFile'):)
    let $coll := collection(wega:getOption($docType))//mei:mei
    let $xmlID := 'worksNormSeries' 
    let $content := 
        <dictionary xmlns=""> {
            attribute xml:id {$xmlID},
            for $i in $coll 
            let $docID := $i/string(@xml:id)
            let $normDate := $i//mei:seriesStmt/mei:title[@level='s']/xs:int(@n)
            let $n := $i//mei:altId[@type = 'WeV']
            let $sortCategory02 := $i//mei:altId[@type = 'WeV']/string(@subtype) 
            let $sortCategory03 := $i//mei:altId[@type = 'WeV']/xs:int(@n) 
            order by $normDate, $sortCategory02, $sortCategory03, $n
            return 
            element entry {
                attribute docID {$docID},
                attribute n {$n},
                $normDate
            }
        }</dictionary> 
    return (:if(exists($storeFile))
    then <p>{xmldb:store(functx:substring-before-last($normDatesFile, '/'), functx:substring-after-last($normDatesFile, '/'), $content)}</p>
    else:) $content 
};

(:~
 : Creates diary norm dates
 :
 : @author Peter Stadler
 : @return element
:)

declare function wega:createDiaryNormDates() {
    let $docType := 'diaries'
(:    let $normDatesFile := wega:getOption(concat($docType, 'NormDatesFile')):)
    let $coll := collection(wega:getOption($docType))//tei:ab[not(./tei:ref)]
    let $xmlID := concat($docType, 'NormDates')
    let $content := 
        <dictionary xmlns=""> {
            attribute xml:id {$xmlID},
            for $i in $coll 
            let $docID := $i/string(@xml:id)
            let $normDate := $i/string(@n)
            order by $normDate
            return 
            element entry {
                attribute docID {$docID},
                if ($normDate castable as xs:date) then attribute year {year-from-date($normDate cast as xs:date)} else (),
                if ($normDate castable as xs:date) then attribute month {month-from-date($normDate cast as xs:date)} else (),
                if ($normDate castable as xs:date) then attribute day {day-from-date($normDate cast as xs:date)} else (),
                $normDate
            }
        }</dictionary>  
    return (:if(exists($storeFile))
        then <p>{xmldb:store(functx:substring-before-last($normDatesFile, '/'), functx:substring-after-last($normDatesFile, '/'), $content)}</p>
        else:) $content 
};

(:~
 : Creates news norm dates
 :
 : @author Peter Stadler
 : @return element
:)

declare function wega:createNewsNormDates() {
    let $docType := 'news'
(:    let $normDatesFile := wega:getOption(concat($docType, 'NormDatesFile')):)
    let $coll :=  collection(wega:getOption($docType))//tei:TEI[not(./tei:ref)]
    let $xmlID := concat($docType, 'NormDates')
    let $content := 
        <dictionary xmlns=""> {
            attribute xml:id {$xmlID},
            for $i in $coll 
            let $docID := $i/string(@xml:id)
            let $normDate := datetime:date-from-dateTime($i//tei:publicationStmt/tei:date/xs:dateTime(@when))
            (:let $log := util:log-system-out($normDate):)
            order by $normDate descending
            return 
            element entry {
                attribute docID {$docID},
                if ($normDate castable as xs:date) then attribute year {year-from-date($normDate cast as xs:date)} else (),
                if ($normDate castable as xs:date) then attribute month {month-from-date($normDate cast as xs:date)} else (),
                if ($normDate castable as xs:date) then attribute day {day-from-date($normDate cast as xs:date)} else (),
                $normDate
            }
        }</dictionary>  
    return (:if(exists($storeFile))
        then <p>{xmldb:store(functx:substring-before-last($normDatesFile, '/'), functx:substring-after-last($normDatesFile, '/'), $content)}</p>
        else:) $content 
};

(:~
 : Creates bibliography norm dates
 :
 : @author Peter Stadler
 : @return element
:)

declare function wega:createBiblioNormDates($docType as xs:string) as element() {
(:    let $normDatesFile := wega:getOption(concat($docType, 'NormDatesFile')):)
    let $collPath := wega:getOption($docType)
    let $predicates := wega:getOption(concat($docType, 'PredIndices'))
    let $coll :=  (:collection(wega:getOption($docType))//tei:biblStruct[not(./tei:ref)]:)
        util:eval(concat('collection("', $collPath, '")', $predicates))
    let $xmlID := concat($docType, 'NormDates')
    let $content := 
        <dictionary xmlns=""> {
            attribute xml:id {$xmlID},
            for $i in $coll 
            let $docID := $i/root()/*/string(@xml:id)
            let $normDate := wega:getOneNormalizedDate($i//tei:imprint/tei:date, false())
            (:let $log := util:log-system-out($normDate):)
            order by $normDate descending
            return 
            element entry {
                attribute docID {$docID},
                if ($normDate castable as xs:date) then attribute year {year-from-date($normDate cast as xs:date)} else (),
                if ($normDate castable as xs:date) then attribute month {month-from-date($normDate cast as xs:date)} else (),
                if ($normDate castable as xs:date) then attribute day {day-from-date($normDate cast as xs:date)} else (),
                $normDate
            }
        }</dictionary>  
    return $content 
};

(:~
 : Creates person norm dates
 :
 : @author Peter Stadler
 : @return element
:)

declare function wega:createPersonNormDates() {
    let $docType := 'persons'
(:    let $normDatesFile := wega:getOption('persNamesFile'):)
    let $coll :=  collection(wega:getOption($docType))//tei:person[not(./tei:ref)]
    let $xmlID := 'persNames'
    let $content := 
        <dictionary xmlns=""> {
            attribute xml:id {$xmlID},
            for $x in $coll
            let $docID := $x/string(@xml:id)
            let $sex := data($x/tei:sex)
            let $name := normalize-space($x/tei:persName[@type='reg'])
            order by $name ascending
            return 
            element entry {
                attribute docID {$docID},
                attribute sex {$sex},
                $name
            }
        }</dictionary> 
    return (:if(exists($storeFile))
        then <p>{xmldb:store(functx:substring-before-last($normDatesFile, '/'), functx:substring-after-last($normDatesFile, '/'), $content)}</p>
        else :)$content 
};

(:~
 : Creates norm dates
 :
 : @author Peter Stadler
 : @param $docType 
 : @return item
:)

declare function wega:createNormDates($docType as xs:string) as item()? {
    if($docType eq 'persons') then wega:createPersonNormDates()
    else if($docType eq 'letters') then wega:createLetterNormDates()
    else if($docType eq 'writings') then wega:createWritingNormDates()
    else if($docType eq 'diaries') then wega:createDiaryNormDates()
    else if($docType eq 'news') then wega:createNewsNormDates()
    else if($docType eq 'works') then wega:createWorkNormDates()
    else if($docType eq 'biblio') then wega:createBiblioNormDates($docType)
    else if($docType eq 'weberStudies') then wega:createBiblioNormDates($docType)
    else if($docType eq 'all') then (wega:createPersonNormDates(),wega:createLetterNormDates(),wega:createWritingNormDates(),wega:createDiaryNormDates(),wega:createNewsNormDates(),wega:createWorkNormDates())
    else ()
};

(:~
 : Returns norm date file
 :
 : @author Peter Stadler
 : @docType for dates
 : @return item?
:)

declare function wega:getNormDates($docType as xs:string) as document-node()? {
    let $normDatesFileName := 
        if($docType eq 'persons') then wega:getOption('persNamesFile') 
        else if($docType eq 'works') then wega:getOption('worksNormSeriesFile') 
        else wega:getOption(concat($docType, 'NormDatesFile'))
    let $fileName := functx:substring-after-last($normDatesFileName, '/')
    let $folderName := substring-before($normDatesFileName, $fileName)
    let $currentDateTimeOfFile := 
        if(doc-available($normDatesFileName)) then xmldb:last-modified($folderName, $fileName) 
        else ()
    let $updateNecessary := typeswitch($currentDateTimeOfFile) 
	   case xs:dateTime return wega:eXistDbWasUpdatedAfterwards($currentDateTimeOfFile)
	   default return true()
    return 
        if($updateNecessary) then (
            let $newNormDates := wega:createNormDates($docType)
            let $logMessage := concat('wega:getNormDates(): created normDatesFile for ', $docType)
            let $logToFile := wega:logToFile('info', $logMessage)
            return 
                if(exists($newNormDates)) then doc(util:catch('*', xmldb:store($folderName, $fileName, $newNormDates), wega:logToFile('error', string-join(('wega:getNormDates', $util:exception, $util:exception-message), ' ;; '))))
                else ()
        )
        else doc($normDatesFileName)
};

(:~
 : Writes log message to log file
 :
 : @author Peter Stadler
 : @param $priority to be used by util:log-app - e.g. "error"
 : @param $message to write
 : @return 
:)

declare function wega:logToFile($priority as xs:string, $message as xs:string) as empty() {
    let $file := wega:getOption('errorLogFile')
    let $message := concat($message, ' (rev. ', wega:getCurrentSvnRev(), ')')
    let $log := if(wega:getOption('environment') eq 'development') then util:log-system-out($message) else ()
    return util:log-app($priority, $file, $message)
};

(:~
 : Gets document type by ID
 :
 : @author Peter Stadler
 : @param $id 
 : @return xs:string document type
:)

declare function wega:getDoctypeByID($id as xs:string) as xs:string? {
    if(wega:isPerson($id)) then 'persons'
    else if(wega:isWriting($id)) then 'writings'
    else if(wega:isWork($id)) then 'works'
    else if(wega:isDiary($id)) then 'diaries'
    else if(wega:isLetter($id)) then 'letters'
    else if(wega:isNews($id)) then 'news'
    else if(wega:isIconography($id)) then 'iconography'
    else if(wega:isVar($id)) then 'var'
    else if(wega:isBiblio($id)) then 'biblio'
    else ()
};


(:~
 : Returns document by ID
 :
 : @author Peter Stadler
 : @param $id the ID of the document
 : @return returns the document node of the resource found for the specified ID.
:)

declare function wega:doc($docID as xs:string) as document-node()? {
    let $collectionPath := wega:getCollectionPath($docID)
    return 
        if ($collectionPath ne '') then collection($collectionPath)//id($docID)/root() else ()
};


(:~
 : Creates lightbox anchor
 :
 : @author Christian Epp
 : @param $href the link to the Image (can be every URL)
 : @param $title the title of the Image
 : @param $group name for grouping of images
 : @param $content the content of the anchor
 : @return xhtml:a element
:)

declare function wega:createLightboxAnchor($href as xs:string, $title as xs:string, $group as xs:string, $content as item()*) as element(a)* {
    <a href="{$href}" class="lytebox" data-lyte-options="group:{$group}" data-title="{$title}">{$content}</a>
};

(:~
 : Print javascript function
 :
 : @author Peter Stadler
 : @param $function a xml element with the following content: <function><name>showEntries</name><param type="obj">this</param><param>myStringParam</param></function>
 : @return a javscript function call as string, e.g. function('param1', 'param2')
:)

declare function wega:printJavascriptFunction($function as element(function)) as xs:string {
	let $funcName := $function/name
	let $params := 
		if(exists($function/param)) then
			string-join(
				for $i in $function/param
				return 
					if($i[@type='obj']) then $i
					else concat("'", $i, "'"),
				","
			)
		else ()
	return concat($funcName, "(", $params, ")")
};

(:~
 : Print teaser text of max length while truncating at word border
 :
 : @author Peter Stadler
 : @param $string the string to truncate
 : @param $maxLength the max length of the returned string as xs:int
 : @return xs:string 
:)

declare function wega:printPreview($string as xs:string, $maxLength as xs:int) as xs:string {
    let $delimiterRegex := '[\s\.,!\?\+-;]' 
    let $maxString := substring(normalize-space($string),1,$maxLength)
    return 
        if(string-length($maxString) lt $maxLength) then $maxString 
        else concat(functx:substring-before-last-match($maxString, $delimiterRegex), ' …')
};

(:~
 :  get GND for a given WeGA ID or document
 :
 :  @author Peter Stadler
 :  @param $docItem as id of document or document node
 :  @return xs:string?
:)

declare function wega:getGND($docItem as item()) as xs:string? {
    let $doc := typeswitch($docItem)
        case xs:string return wega:doc($docItem)
        default return $docItem
    return $doc//tei:idno[@type='gnd']/text()
};