xquery version "3.0" encoding "UTF-8";

(:~
: Collected xQuery functions
:
: @author Peter Stadler 
: @version 1.0
:)

module namespace wega="http://xquery.weber-gesamtausgabe.de/modules/wega";
declare default collation "?lang=de;strength=primary";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace session = "http://exist-db.org/xquery/session";
(:declare namespace image = "http://exist-db.org/xquery/image";:)
declare namespace xmldb = "http://exist-db.org/xquery/xmldb";
(:declare namespace cache = "http://exist-db.org/xquery/cache";:)
declare namespace util = "http://exist-db.org/xquery/util";
declare namespace httpclient = "http://exist-db.org/xquery/httpclient";
import module namespace functx="http://www.functx.com";
import module namespace http = "http://expath.org/ns/http-client";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date" at "date.xqm";
import module namespace bibl="http://xquery.weber-gesamtausgabe.de/modules/bibl" at "bibl.xqm";
import module namespace datetime="http://exist-db.org/xquery/datetime" at "java:org.exist.xquery.modules.datetime.DateTimeModule";
(:import module namespace image="http://exist-db.org/xquery/image" at "java:org.exist.xquery.modules.image.ImageModule";:)
import module namespace img="http://xquery.weber-gesamtausgabe.de/modules/img" at "img.xqm";
import module namespace norm="http://xquery.weber-gesamtausgabe.de/modules/norm" at "norm.xqm";

declare variable $wega:romanNums as xs:integer* := (1000,900,500,400,100,90,50,40,10,9,5,4,1);
declare variable $wega:romanAlpha as xs:string* := ('M', 'CM', 'D', 'CD', 'C', 'XC', 'L', 'XL', 'X', 'IX', 'V', 'IV', 'I');
declare variable $wega:historyStack := ();

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
                        date:printDate($date, $lang)
                    },
                    $place
                )
                return wega:datesOfBirthOrDeathTemplate($myType, $content, $lang)
        else 
            let $content := ($place, ' ', <span class="noDataFound">({lang:get-language-string('dateUnknown',$lang)})</span>)
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
    let $html_pixDir := config:get-option('html_pixDir')
    let $baseHref := config:get-option('baseHref')
    let $iconPath := core:join-path-elements(($baseHref, $html_pixDir, concat($myType,'.png')))
    let $iconTitle := lang:get-language-string($myType,$lang) 
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
            else concat(' ', lower-case(lang:get-language-string('in', $lang)), ' ')
        else concat(' ',lang:get-language-string('or', $lang),' '),
        element span {
            attribute class {string-join(('place', $certainty), ' ')},
            $name
        }
    )
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
        let $from := if(exists($event/@from)) then concat('f', date:getCastableDate(string($event/@from), false())) else ()
        let $to := if(exists($event/@to)) then concat('t', date:getCastableDate(string($event/@to), true())) else ()
        let $notBefore := if(exists($event/@notBefore)) then concat('b', date:getCastableDate(string($event/@notBefore), false())) else ()
        let $notAfter := if(exists($event/@notAfter)) then concat('a', date:getCastableDate(string($event/@notAfter), true())) else ()
        let $whenFrom := if(exists($event/@when)) then date:getCastableDate(string($event/@when), false()) else ()
        let $whenTo := if(exists($event/@when)) then date:getCastableDate(string($event/@when), true()) else ()
        let $idDatePart := if(exists($whenFrom))
                then if($whenFrom ne $whenTo)
                    then concat('b', $whenFrom, 'a', $whenTo)
                    else concat('w', $whenFrom)
                else string-join(($from, $to, $notBefore, $notAfter), '_')
        let $xslParams := config:get-xsl-params( map {'eventID' := concat('event-', $i, '_', $idDatePart) } ) 
        return 
            wega:changeNamespace(transform:transform($event, doc(concat($config:xsl-collection-path, '/person_singleView.xsl')), $xslParams), '', ())
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
    let $dictionary := norm:get-norm-doc('persons') 
    let $response := $dictionary//norm:entry[@docID = $key]
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
    let $doc := core:doc($docID)
    return
        if(config:is-diary($docID)) then ()
        else if(config:is-work($docID)) then wega:cleanString($doc//mei:fileDesc/mei:titleStmt/mei:title[not(@type)][1])
        else wega:cleanString($doc//tei:fileDesc/tei:titleStmt/tei:title[@level = 'a'][1])
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
    let $dic := doc(config:get-option($dicID))
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
    let $dic := doc(config:get-option($dicID))
    return $dic//entry[. = $string]/string(@xml:id)
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
        if (config:is-person($id)) then collection(config:get-option('persons'))//tei:person[./tei:ref]
        else if (config:is-letter($id)) then collection(config:get-option('letters'))//tei:TEI[./tei:ref]
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
            let $docOrg := core:doc($docID)
            return if(exists($docOrg/*/tei:ref)) 
                then core:doc($docOrg/*/tei:ref/string(@target)) (: Dublettenauflösung :)
                else $docOrg
    return 
        if(exists($doc)) then
            if(config:is-person($docID))       then wega:getPersonMetaData($doc, $lang, $usage)
            else if(config:is-work($docID))    then wega:getWorkMetaData($doc, $lang, $usage)
            else if(config:is-writing($docID)) then wega:getWritingMetaData($doc, $lang, $usage)
            else if(config:is-letter($docID))  then wega:getLetterMetaData($doc, $lang, $usage)
            else if(config:is-news($docID))    then wega:getNewsMetaData($doc, $lang, $usage)
            else if(config:is-diary($docID))   then wega:getDiaryMetaData($doc, $lang, $usage)
            else if(config:is-var($docID))     then wega:getVarMetaData($doc, $lang, $usage)
            else if(config:is-biblio($docID))  then wega:getBiblioMetaData($doc, $lang, $usage)
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
    let $log := core:logToFile('warn', $logMessage)
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
            <h1>{lang:get-language-string('noDataFound', $lang)}</h1>
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
let $baseHref := config:get-option('baseHref')
let $imageEnlarge := $usage eq 'singleView'
let $imageDimension := 
    if($imageEnlarge) then for $i in tokenize(config:get-option('bigPicDimensions'), ',') return xs:int($i) 
    else 
        if($usage eq 'toolTip') then for $i in tokenize(config:get-option('smallPicDimensions'), ',') return xs:int($i)
        else for $i in tokenize(config:get-option('mediumPicDimensions'), ',') return xs:int($i)
let $clickable := $usage eq 'listView'
let $portraitPath := img:getPortraitPath($person, $imageDimension, $lang)
let $regName := wega:getRegName($fffiId)
let $html_pixDir := config:get-option('html_pixDir')
let $cssClasses := if($usage eq 'toolTip') 
    then 'person toolTip'
    else if($clickable)
            then 'person item'
            else 'person'
let $imageEnlargeLink := if($imageEnlarge)
    then let $localIconography := core:getOrCreateColl('iconography', 'indices', true())//tei:figure[.//tei:person[@corresp = $fffiId]][@n = 'portrait'][1][./tei:graphic]/ancestor::tei:TEI
         let $caption := if(exists($localIconography))
            then $localIconography//tei:title
            else if(matches($portraitPath, 'nobody_[fmn].png'))
                then $regName
                else concat($regName, ' (', lang:get-language-string('sourceWikipedia', $lang), ')')
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
        then (attribute onclick {concat("location.href='", core:join-path-elements(($baseHref, $lang, $fffiId)), "'")},
            attribute title {lang:get-language-string('showPersonSingleView', wega:printFornameSurname($regName), $lang)})
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
(:        transform:transform($person//tei:persName[string(@type) eq 'full'], doc(concat($config:xsl-collection-path, '/person_singleView.xsl')), $xslParams):)
        }</p>
        else()
        }
        {
        if (exists($person//tei:persName[@type="real"]))
        then <p class="realName">{
            wega:cleanString($person/tei:persName[@type='real']),
(:            transform:transform($person//tei:persName[string(@type) eq 'real'], doc(concat($config:xsl-collection-path, '/person_singleView.xsl')), $xslParams),:)
                                    <span class="nameDesc">{concat(' (', lang:get-language-string('realName',$lang), ')')}</span>}</p>
        else()
        }
        {
        if (exists($person//tei:persName[@type="alt"]))
        then <p class="altNames">{lang:get-language-string('altNames',$lang)}: { 
                for $i at $count in $person//tei:persName[string(@type) eq 'alt']
                let $lastItem := $person//tei:persName[@type="alt"]/last()
                return (
                    <span  class="alt">{wega:cleanString($i)}</span>,
(:                    transform:transform($i, doc(concat($config:xsl-collection-path, '/person_singleView.xsl')), $xslParams),:)
                    if($i[@subtype='birth']) 
                        then <span class="nameDesc">{concat(' (', lang:get-language-string('birthName',$lang), ')')}</span> 
                        else if($i[@subtype='married'])
                            then <span class="nameDesc">{concat(' (', lang:get-language-string('marriedName',$lang), ')')}</span> 
                            else '',
                    if($count = $lastItem) then () else '; '
                    )
                }
            </p>
        else()
        }
        {
        if (exists($person//tei:persName[@type="pseud"]))
        then <p class="pseudNames">{lang:get-language-string('pseudonyms',$lang)}: { 
                for $i at $count in $person//tei:persName[string(@type) eq 'pseud']
                let $lastItem := $person//tei:persName[@type="pseud"]/last()
                return (
                    <span class="pseud">{wega:cleanString($i)}</span>,
(:                    transform:transform($i, doc(concat($config:xsl-collection-path, '/person_singleView.xsl')), $xslParams),:)
                    if($count = $lastItem) then () else '; '
                    )
                }
            </p>
        else(),
        
        if(exists($person//tei:birth)) then wega:printDatesOfBirthOrDeath($person//tei:birth, $lang)
        else wega:datesOfBirthOrDeathTemplate('birth', <span class="noDataFound">({lang:get-language-string('noDataFound',$lang)})</span>, $lang),
        
        if(exists($person//tei:death)) then wega:printDatesOfBirthOrDeath($person//tei:death, $lang) else (),
        (:   Keine Ausgabe bei leerem death. Bei Angabe eines date wird das Datum ausgelesen bzw. ein  "keine Angaben gefunden" ausgegeben  :)

        if($person//tei:occupation) then 
            <p class="occupation">
                {if($usage eq 'toolTip' and exists($person//tei:occupation[4])) (:Für tooltips und Suche wird die Anzeige von Wirkorten und Tätigkeiten auf 3 beschränkt:)
                    then concat(string-join($person//tei:occupation[position() lt 4]/normalize-space(), ', '), ' ', lang:get-language-string('etAlii', $lang))
                    else string-join($person//tei:occupation/normalize-space(), ', ')
                }
            </p>
        else (),
        
        if($person//tei:residence) then 
            <p class="residence">{lang:get-language-string('placesOfAction',$lang)}:
                {if($usage eq 'toolTip' and exists($person//tei:residence[4])) (:Für tooltips und Suche wird die Anzeige von Wirkorten und Tätigkeiten auf 3 beschränkt:)
                    then concat(string-join($person//tei:residence[position() lt 4]/normalize-space(), ', '), ' ', lang:get-language-string('etAlii', $lang))
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
    let $imageDimension := if($usage eq 'singleView') then config:get-option('bigPicDimensions') else config:get-option('smallPicDimensions')
    let $clickable := $usage eq 'listView'
    let $baseHref := config:get-option('baseHref')
    let $html_pixDir := config:get-option('html_pixDir')
	let $iconPath := core:join-path-elements(($baseHref, $html_pixDir, 'letterIcon.png'))
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
                    attribute title {lang:get-language-string('showLetterSingleView', $lang)}
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
                    <span class="tei_hiBold">{lang:get-language-string('incipit',$lang)}: </span>,
                    element span {
                        if(functx:all-whitespace($letter//tei:incipit)) then (
                            attribute class {'noDataFound'},
                            lang:get-language-string('noDataFound',$lang)
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
                    <span class="tei_hiBold">{lang:get-language-string('summary',$lang)}: </span>,
                    element span {
                        if(functx:all-whitespace($letter//tei:note[@type='summary'])) then (
                            attribute class {'noDataFound'},
                            lang:get-language-string('noDataFound',$lang)
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
    let $baseHref := config:get-option('baseHref')
    let $html_pixDir := config:get-option('html_pixDir')
    let $iconPath := core:join-path-elements(($baseHref, $html_pixDir, 'diaryIcon.png'))
    let $clickable := $usage eq 'listView'
	let $cssClasses := if($usage eq 'toolTip')  
        then 'diaryDay toolTip'
        else if($usage eq 'listView')
            then 'diaryDay item'
            else 'diaryDay'
    let $dateFormat := if ($lang eq 'en')
        then '%A, %B %d, %Y'
        else '%A, %d. %B %Y'
    let $date := xs:date($diaryEntry/@n)
    let $id := $diaryEntry/@xml:id
    
    return (
    element div {
        if($clickable) 
            then (
                attribute onclick {concat("location.href='", wega:createLinkToDoc($doc, $lang), "'")},
                attribute title {lang:get-language-string('showDiaryDay', ('Weber', date:strfdate($date, $lang, substring-after($dateFormat, ', '))), $lang)}
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
                date:strfdate($date, $lang, $dateFormat)
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
    let $imageDimension := if($usage eq 'singleView') then config:get-option('bigPicDimensions') else config:get-option('smallPicDimensions')
    let $clickable := $usage eq 'listView'
    let $docID := $doc/tei:TEI/string(@xml:id)
    let $baseHref := config:get-option('baseHref')
    let $html_pixDir := config:get-option('html_pixDir')
    let $iconPath := core:join-path-elements(($baseHref, $html_pixDir, 'writingIcon.png'))
	let $cssClasses := if($usage eq 'toolTip') 
        then 'writing toolTip'
        else if($usage eq 'listView')
            then 'writing item'
            else 'writing'
    let $source := core:main-source($doc//tei:sourceDesc)

    return (
        element div {
            attribute class {$cssClasses},
            if($clickable) 
                then (
                    attribute onclick {concat("location.href='", wega:createLinkToDoc($doc, $lang), "'")},
                    attribute title {lang:get-language-string('showWritingSingleView', $docID, $lang)}
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
                if($source instance of element(tei:biblStruct)) then bibl:printCitation($source, 'p', $lang) else () 
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
    let $imageDimension := if($usage eq 'singleView') then config:get-option('bigPicDimensions') else config:get-option('smallPicDimensions')
    let $clickable := $usage eq 'listView'
    let $baseHref := config:get-option('baseHref')
    let $html_pixDir := config:get-option('html_pixDir')
    let $iconPath := core:join-path-elements(($baseHref, $html_pixDir, 'newsIcon.png'))
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
                    attribute title {lang:get-language-string('showNewsSingleView', date:getNiceDate($date, $lang), $lang)}
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
                    transform:transform($doc//tei:fileDesc//tei:titleStmt//tei:title[@level='a'], doc(concat($config:xsl-collection-path, '/common_main.xsl')), config:get-xsl-params(()))
                },
                element p {
                    wega:printPreview(string($doc//tei:body), 150)
                },
                element p {
                    attribute class {'news-metadata-teaser-date'},
                    date:getNiceDate($date, $lang)
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
    let $imageDimension := if($usage eq 'singleView') then config:get-option('bigPicDimensions') else config:get-option('smallPicDimensions')
    let $clickable := $usage eq 'listView'
    let $baseHref := config:get-option('baseHref')
    let $html_pixDir := config:get-option('html_pixDir')
    let $iconPath := core:join-path-elements(($baseHref, $html_pixDir, 'varIcon.png'))
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
                    attribute onclick {concat("location.href='", core:join-path-elements((config:get-option('baseHref'), $lang, wega:getVarURL($docID,$lang))), "'")},
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
    let $imageDimension := if($usage eq 'singleView') then config:get-option('bigPicDimensions') else config:get-option('smallPicDimensions')
    let $clickable := ($usage eq 'listView') and $doc/root()/local-name(*) eq 'TEI' 
    let $baseHref := config:get-option('baseHref')
    let $html_pixDir := config:get-option('html_pixDir')
    let $biblioType := if(exists($doc//tei:biblStruct/@type)) then $doc//tei:biblStruct/data(@type) else 'blank'
    let $iconPath := core:join-path-elements(($baseHref, $html_pixDir, concat('biblioIcon-',$biblioType,'.png')))
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
                    attribute title {lang:get-language-string('showWritingSingleView', $docID, $lang)}
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
                bibl:printCitation($bibl, 'span', $lang),
                if($clickable) then element p {
                    attribute class {'readOn'},
                    lang:get-language-string('detailsAvailable', $lang)
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
    let $result :=  if($string="A070001") then lang:get-language-string("editorialGuidelines",$lang)
                    else if($string="A070002") then lang:get-language-string("about",$lang)
                    else if($string="A070003") then lang:get-language-string("bio",$lang)
                    else if($string="A070004") then lang:get-language-string("help",$lang)
                    else if($string="A070005") then lang:get-language-string("index",$lang)
                    else if($string="A070006") then lang:get-language-string("projectDescription",$lang)
                    else if($string="A070009") then lang:get-language-string("contact",$lang)
                    else if($string="A070010") then lang:get-language-string("editorialGuidelines-works",$lang)
                    else if($string="A070011") then lang:get-language-string("weberstudien",$lang)
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
    let $imageDimension := if($usage eq 'singleView') then config:get-option('bigPicDimensions') else config:get-option('smallPicDimensions')
    let $clickable := false()
        (:if($usage eq 'listView') then true() else false():)
    let $baseHref := config:get-option('baseHref')
    let $html_pixDir := config:get-option('html_pixDir')
    let $iconPath := core:join-path-elements(($baseHref, $html_pixDir, 'workIcon.png'))
	let $cssClasses := if($usage eq 'toolTip') 
        then 'works toolTip'
        else if($usage eq 'listView')
            then 'works item'
            else 'works'
    let $title := $doc//mei:fileDesc/mei:titleStmt/mei:title[not(@type)][1]

    return (
        element div {
            attribute class {$cssClasses},
            if($clickable) 
                then (
                    attribute onclick {concat("location.href='", wega:createLinkToDoc($doc, $lang), "'")},
                    attribute title {lang:get-language-string('showWorkSingleView', wega:printPreview(string($title), 20), $lang)}
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
                        then lang:get-language-string('noDataFound', $lang)
                        else (
                            string($doc//mei:fileDesc/mei:titleStmt/mei:title[not(@type)][1]),
                            if(exists($doc//mei:altId/@type[. !='gnd'])) then 
                                if(exists($doc//mei:altId[@type='WeV'])) then concat('(WeV ', $doc//mei:altId[@type='WeV'], ')') (: Weber-Werke :)
                                else concat('(', ($doc//mei:altId/@type[. !='gnd'])[1]/string(.), ' ', ($doc//mei:altId[@type[. !='gnd']])[1], ')') (: Fremd-Werke :)
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
                            lang:get-language-string('series', $lang),
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
                            lang:get-language-string($i/string(@role), $lang)
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
        collection(config:get-option('letters'))//tei:dateSender/tei:date[matches(@when, $date-regex)] union
        collection(config:get-option('persons'))//tei:date[matches(@when, $date-regex)][not(preceding-sibling::tei:date[matches(@when, $date-regex)])][parent::tei:birth or parent::tei:death][ancestor::tei:person/@source='WeGA']
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
 
declare function wega:printCorrespondentName($persName as element()?, $lang as xs:string, $order as xs:string) as element() {
     if(exists($persName/@key)) then wega:createPersonLink($persName/string(@key), $lang, $order)
     else if (contains($persName, ',') and $order eq 'fs') then <xhtml:span class="noDataFound">{wega:printFornameSurname($persName)}</xhtml:span>
     else if (not(functx:all-whitespace($persName))) then <xhtml:span class="noDataFound">{string($persName)}</xhtml:span>
     else <xhtml:span class="noDataFound">{lang:get-language-string('unknown',$lang)}</xhtml:span>
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
            <xhtml:a href="{core:join-path-elements((config:get-option('baseHref'), $lang, $id))}">
                <xhtml:span class="person" onmouseover="metaDataToTip('{$id}', '{$lang}')" onmouseout="UnTip()">{$name}</xhtml:span>
            </xhtml:a>
        else <xhtml:span class="{concat('noDataFound ', $id)}">{lang:get-language-string('unknown',$lang)}</xhtml:span>
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

(:(\:~
 : Create a bibliographic citation from a biblStruct
 : 
 : @author Peter Stadler
 : @param $biblStruct the TEI biblStruct element with the bibliographic information
 : @param $wrapperElement the HTML element for wrapping the output (usually span or li)
 : @param $lang the language switch (en, de)
 : @return element
 :\)

declare function wega:printCitation($biblStruct as element(tei:biblStruct), $wrapperElement as xs:string, $lang as xs:string) as element()? {
    if($biblStruct/tei:analytic/tei:author[@sameAs]) then wega:printJournalCitation($biblStruct/tei:monogr, $wrapperElement, $lang) (\: Soll in den writings die Ausgabe von (leerem) Autor unterdrücken; Ist aber lediglich als Notlösung zu verstehen! :\)
    else if($biblStruct/@type eq 'book') then wega:printBookCitation($biblStruct, $wrapperElement, $lang)
    else if($biblStruct/@type eq 'score') then wega:printBookCitation($biblStruct, $wrapperElement, $lang)
    else if($biblStruct/@type eq 'article') then wega:printArticleCitation($biblStruct, $wrapperElement, $lang)
    else if($biblStruct/@type eq 'incollection') then wega:printIncollectionCitation($biblStruct, $wrapperElement, $lang)
    else if($biblStruct/@type eq 'inproceedings') then wega:printIncollectionCitation($biblStruct, $wrapperElement, $lang)
    else if($biblStruct/@type eq 'review') then wega:printArticleCitation($biblStruct, $wrapperElement, $lang)
    else if($biblStruct/@type eq 'phdthesis') then wega:printBookCitation($biblStruct, $wrapperElement, $lang)
    else wega:printGenericCitation($biblStruct, $wrapperElement, $lang)
};

(\:~
 : Create a generic bibliographic citation (This is highly specific to our WeGA data though!)
 : 
 : @author Peter Stadler
 : @param $biblStruct the TEI biblstruct element with the bibliographic information
 : @param $wrapperElement the HTML element for wrapping the output (usually span or li)
 : @param $lang the language switch (en, de)
 : @return element
 :\)
 
declare function wega:printGenericCitation($biblStruct as element(tei:biblStruct), $wrapperElement as xs:string, $lang as xs:string) as element() {
    let $authors := wega:printCitationAuthors($biblStruct//tei:author, $lang)
    let $title := for $i in $biblStruct//tei:title return 
        (transform:transform($i, doc(concat($config:xsl-collection-path, '/var.xsl')), config:get-xsl-params(())),
        '. '
        )
    return 
        element {$wrapperElement} {
            $authors,
            if(exists($authors)) then ', ' else (),
            $title
        }
};

(\:~
 : Create a bibliographic citation for a book
 : 
 : @author Peter Stadler
 : @param $biblStruct the TEI biblstruct element with the bibliographic information
 : @param $wrapperElement the HTML element for wrapping the output (usually span or li) 
 : @param $lang the language switch (en, de)
 : @return element
 :\)
 
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
            else if(exists($editors)) then ($editors, concat(' (', lang:get-language-string('ed', $lang), '), '))
            else (), 
            $title,
            if(exists($editors) and exists($authors)) then (concat(', ', lang:get-language-string('edBy', $lang), ' '), $editors) else (),
            if(exists($series)) then concat(' (= ', $series, '), ') else ', ',
            $pubPlaceNYear
        }
};

(\:~
 : Create a bibliographic citation for an article
 : 
 : @author Peter Stadler
 : @param $biblStruct the TEI biblstruct element with the bibliographic information
 : @param $wrapperElement the HTML element for wrapping the output (usually span or li) 
 : @param $lang the language switch (en, de)
 : @return element
 :\)
 
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
:)
(:(\:~
 : Create a bibliographic citation for a journal
 : 1. Helper function for wega:printArticleCitation() 
 : 2. Function for creating bibliographic citations for writings when the source is a journal
 : 
 : @author Peter Stadler
 : @param $monogr the TEI monogr element with the bibliographic reference of the journal
 : @param $wrapperElement the HTML element for wrapping the output (usually span or li)
 : @param $lang the language switch (en, de)
 : @return element
 :\)

declare function wega:printJournalCitation($monogr as element(tei:monogr), $wrapperElement as xs:string, $lang as xs:string) as element() {
    let $journalTitle := <span class="journalTitle">{string-join($monogr/tei:title, '. ')}</span>
    let $date := concat('(', $monogr/tei:imprint/tei:date, ')')
    let $biblScope := concat(
        if($monogr/tei:imprint/tei:biblScope[@type = 'vol']) then concat(', ', lang:get-language-string('vol', $lang), '&#160;', $monogr/tei:imprint/tei:biblScope[@type = 'vol']) else (),
        if($monogr/tei:imprint/tei:biblScope[@type = 'jg']) then concat(', ', 'Jg.', '&#160;', $monogr/tei:imprint/tei:biblScope[@type = 'jg']) else (),
        if($monogr/tei:imprint/tei:biblScope[@type = 'issue']) then concat(', ', lang:get-language-string('issue', $lang), '&#160;', $monogr/tei:imprint/tei:biblScope[@type = 'issue']) else (),
        if($monogr/tei:imprint/tei:biblScope[@type = 'nr']) then concat(', ', 'Nr.', '&#160;', $monogr/tei:imprint/tei:biblScope[@type = 'nr']) else (),
        if(exists($monogr/tei:imprint/tei:date)) then concat(' ', $date) else (),
        if($monogr/tei:imprint/tei:biblScope[@type = 'pp']) then concat(', ', lang:get-language-string('pp', $lang), '&#160;', replace($monogr/tei:imprint/tei:biblScope[@type = 'pp'], '-', '–')) else (),
        if($monogr/tei:imprint/tei:biblScope[@type = 'col']) then concat(', ', lang:get-language-string('col', $lang), '&#160;', replace($monogr/tei:imprint/tei:biblScope[@type = 'col'], '-', '–')) else ()
    )
    return 
        element {$wrapperElement} {
            $journalTitle,
            $biblScope
        }
};

(\:~
 : Create a bibliographic citation for a series
 : Helper function for various wega:print*Citation() 
 : 
 : @author Peter Stadler
 : @param $series the TEI monogr element with the bibliographic reference of the journal
 : @param $wrapperElement the HTML element for wrapping the output (usually span or li)
 : @param $lang the language switch (en, de)
 : @return element
 :\)

declare function wega:printSeriesCitation($series as element(tei:series), $wrapperElement as xs:string, $lang as xs:string) as element() {
    let $seriesTitle := string-join($series/tei:title, '. ')
(\:    let $date := concat('(', $monogr/tei:imprint/tei:date, ')'):\)
    let $biblScope := concat(
        if($series/tei:biblScope[@type = 'vol']) then concat(', ', lang:get-language-string('vol', $lang), '&#160;', $series/tei:biblScope[@type = 'vol']) else (),
        if($series/tei:biblScope[@type = 'issue']) then concat(', ', lang:get-language-string('issue', $lang), '&#160;', $series/tei:biblScope[@type = 'issue']) else ()
    )
    return 
        element {$wrapperElement} {
            string-join(($seriesTitle, $biblScope), '')
        }
};

(\:~
 : Create a bibliographic citation for an incollection entry type
 : 
 : @author Peter Stadler
 : @param $biblStruct the TEI biblstruct element with the bibliographic information
 : @param $wrapperElement the HTML element for wrapping the output (usually span or li) 
 : @param $lang the language switch (en, de)
 : @return element
 :\)
 
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
            if(exists($editor)) then (concat(', ', lang:get-language-string('edBy', $lang), ' '), $editor) else (),
            if(exists($series)) then (' ', <span class="series">{concat('(= ', $series, ')')}</span>) else (),
            if(exists($pubPlaceNYear)) then (', ', $pubPlaceNYear) else(),
            if($biblStruct//tei:imprint/tei:biblScope[@type = 'pp']) then concat(', ', lang:get-language-string('pp', $lang), '&#160;', replace($biblStruct//tei:imprint/tei:biblScope[@type = 'pp'], '-', '–')) else ()
        }
};

(\:~
 : Helper function for wega:print*Citation() functions
 : 
 : @author Peter Stadler
 : @param $authors zero or more tei:author elements 
 : @param $lang the language switch (en, de)
 : @return item
 :\)
 
declare function wega:printCitationAuthors($authors as element()*, $lang as xs:string) as item()* {
    let $countAuthors := count($authors)
    return 
    for $i at $counter in $authors
        return (
            wega:printCorrespondentName($i, $lang, 'sf'),
            if($counter lt $countAuthors - 1) then ', '
            else if($counter eq $countAuthors - 1) then concat(' ', lang:get-language-string('and', $lang), ' ')
            else ()
        )
};

(\:~
 : Helper function for wega:print*Citation() functions
 : Creates a html:span element with pubPlaces and date as content 
 : 
 : @author Peter Stadler
 : @param $imprint a tei:imprint element 
 : @return html:span element if any data is given, the empty sequence otherwise
 :\)
 
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
};:)

(:~
 : Create html output of tei:sourceDesc
 : 
 : @author Peter Stadler
 : @param $doc the TEI document with tei:sourceDesc
 : @param $lang the language switch (en, de)
 : @return element
 :)
 
declare function wega:printSourceDesc($doc as document-node(), $lang as xs:string) as element(div) {
    let $docID := $doc/tei:TEI/@xml:id cast as xs:string
    return
    <div class="clearfix">
        <h2 class="headWithToggleMarker">{lang:get-language-string('editorial',$lang)}</h2>
        <a class="toggleMarker" title="{lang:get-language-string('showEditorial',$lang)}" onclick="$('editorial').toggle();$('show').toggle();$('hide').toggle()"><span id="show">({lang:get-language-string('show',$lang)})</span><span id="hide" style="display:none">({lang:get-language-string('hide',$lang)})</span></a>
        <br class="clearer"/>
        <div id="editorial" style="display:none">
            <h3 id="series">{lang:get-language-string('series',$lang)}</h3>
            <p>{data($doc//tei:titleStmt/tei:title[@level='s'])}</p>
                            
            <h3 id="resp">{lang:get-language-string('transcription',$lang)}</h3>
            <ul>{for $name in $doc//tei:respStmt/tei:name return <li>{data($name)}</li>}</ul>
                            
            {if(exists($doc//tei:listWit)) 
                then (<h3 class="headWithToggleMarker">{lang:get-language-string('textSources',$lang)}</h3>,
                     <ol class="toggleMarkerList">
                        {for $i at $count in $doc//tei:listWit/tei:witness 
                            order by $i/@n ascending 
                            return
                            <li><a onclick="switchActivTab('witness','{concat('source_', $count)}')">[{$i/data(@n)}]</a></li>
                        }
                     </ol>,
                     <br class="clearer"/>
                     )
                else <h3>{lang:get-language-string('textSource',$lang)}</h3>
            }
            <div>{
                (: Drei mögliche Kinder (neben tei:correspDesc) von sourceDesc: tei:msDesc, tei:listWit, tei:biblStruct :)
                let $source := $doc//tei:sourceDesc/tei:*[name(.) != 'correspDesc']
                return
                    if(functx:all-whitespace($source)) then 
                        <span class="noDataFound">{lang:get-language-string('noDataFound',$lang)}</span>
                    else 
                        typeswitch($source)
                        case element(tei:listWit) return wega:listWit($source, $lang)
                        case element(tei:msDesc) return transform:transform($source, doc(concat($config:xsl-collection-path, '/sourceDesc.xsl')), config:get-xsl-params(()))
                        case element(tei:biblStruct) return bibl:printCitation($source, 'p', $lang)
                        default return <span class="noDataFound">{lang:get-language-string('noDataFound',$lang)}</span>
            }</div>
            {if(exists($doc//tei:creation)) then (
            	<h3>{lang:get-language-string('creation',$lang)}</h3>,
            	<ul>
            		<li>{transform:transform($doc//tei:creation, doc(concat($config:xsl-collection-path, '/sourceDesc.xsl')), config:get-xsl-params(()))}</li>
            	</ul>
            	)
            else ()	
            }
        </div>
    </div>
};

declare %private function wega:listWit($listWit as element(tei:listWit), $lang as xs:string) {
    for $witness at $count in $listWit/tei:witness
    let $source := $witness/tei:*
    order by $witness/@n ascending
    return 
        <div class="witness" id="{concat('source_', $count)}">{
            if($count ne 1) then attribute style {'display:none;'} else (),
            typeswitch($source)
                case element(tei:bibl) return core:normalize-space($source)
                case element(tei:msDesc) return transform:transform($source, doc(concat($config:xsl-collection-path, '/sourceDesc.xsl')), config:get-xsl-params(()))
                case element(tei:biblStruct) return bibl:printCitation($source, 'p', $lang)
                default return <span class="noDataFound">{lang:get-language-string('noDataFound',$lang)}</span>
        }</div>
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
        if($resource eq 'wikipedia') then concat(config:get-option($resource), $lang, '/')
        else config:get-option($resource)
    let $fileName := string-join(($pnd, $lang, 'xml'), '.')
    let $today := current-date()
    let $response := core:cache-doc(core:join-path-elements(($config:tmp-collection-path, $resource, $fileName)), wega:http-get#1, xs:anyURI(concat($serverURL, $pnd)), not($useCache))
    return 
        if($response//httpclient:response/@statusCode eq '200') then $response//httpclient:response
        else ()
};


(:~
 : Helper function for wega:grabExternalResource()
 :
 : @author Peter Stadler 
 : @param $url the URL as xs:anyURI
 : @return element wega:externalResource, a wrapper around httpclient:response
 :)
declare function wega:http-get($url as xs:anyURI) as element(wega:externalResource) {
    let $req := <http:request href="{$url}" method="get" timeout="4"><http:header name="Connection" value="close"/></http:request>
    let $response := 
        try { http:send-request($req) }
        catch * {core:logToFile('warn', string-join(('wega:http-get', $err:code, $err:description, 'URL: ' || $url), ' ;; '))}
    (:let $response := 
        if($response/httpclient:body[matches(@mimetype,"text/html")]) then wega:changeNamespace($response,'http://www.w3.org/1999/xhtml', 'http://exist-db.org/xquery/httpclient')
        else $response:)
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
        <label class="checkAll"><input type="checkbox" name="checkAll" onclick="checkAllBoxes('formYear', this.checked);" checked="checked"/>{lang:get-language-string('checkAll', $lang)}</label>
        <p><input type="submit" value="{lang:get-language-string('apply', $lang)}"/></p>
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
        <label class="checkAll"><input type="checkbox" name="checkAll" onclick="checkAllBoxes('formJournal', this.checked);" checked="checked"/>{lang:get-language-string('checkAll', $lang)}</label>
        <p><input type="submit" value="{lang:get-language-string('apply', $lang)}"/></p>
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
            else if(exists($doc/tei:ref)) then wega:getAuthorOfTeiDoc($doc/tei:ref/@target cast as xs:string)
            else config:get-option('anonymusID')
        else ''
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
        for $i in transform:transform($doc//tei:fileDesc/tei:titleStmt, doc(concat($config:xsl-collection-path, '/doc_text.xsl')), $xslParamsHeader)
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
    let $docTitlePart1 := $docTitle/(text() | *)[not(preceding-sibling::tei:lb)]
    let $docTitlePart2 := $docTitle/(text() | *)[preceding-sibling::tei:lb][following-sibling::tei:lb]
    let $docTitlePart3 := $docTitle[tei:lb]/(text() | *)[not(following-sibling::tei:lb)]
    return 
        if($docTitlePart1) then (
            element h1 { core:normalize-space(string-join($docTitlePart1, ' ')) },
            if($docTitlePart2) then element h2 { core:normalize-space(string-join($docTitlePart2, ' ')) } else (),
            if($docTitlePart3) then element h2 { core:normalize-space(string-join($docTitlePart3, ' ')) } else ()
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
    let $id := $doc/tei:TEI/string(@xml:id)
    let $date := date:printDate($doc//tei:dateSender/tei:date[1], $lang)
    let $sender := wega:printCorrespondentName($doc//tei:sender[1]/*[1], $lang, 'fs')
    let $addressee := wega:printCorrespondentName($doc//tei:addressee[1]/*[1], $lang, 'fs')
    let $placeSender := if(functx:all-whitespace($doc//tei:placeSender)) then () else normalize-space($doc//tei:placeSender)
    let $placeAddressee := if(functx:all-whitespace($doc//tei:placeAddressee)) then () else normalize-space($doc//tei:placeAddressee)
    return (
        element h1 {
            concat($sender, ' ', lower-case(lang:get-language-string('to', $lang)), ' ', $addressee),
            if(exists($placeAddressee)) then concat(' ', lower-case(lang:get-language-string('in', $lang)), ' ', $placeAddressee) else()
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
        if(config:is-letter($docID)) then lang:get-language-string('correspondence', $lang) (: Ausnahme für Briefe=Korrespondenz:)
        else if(config:is-weberStudies($doc)) then lang:get-language-string('weberStudies', $lang)
        else lang:get-language-string(config:get-doctype-by-id($docID), $lang)
    return 
        if(config:is-person($docID)) then core:join-path-elements((config:get-option('baseHref'), $lang, $docID)) (: Ausnahme für Personen, die direkt unter {baseref}/{lang}/ angezeigt werden:)
        else if(config:is-biblio($docID)) then 
            if(config:is-weberStudies($doc)) then core:join-path-elements((config:get-option('baseHref'), $lang, lang:get-language-string('publications', $lang), $folder, $docID))
            else ()
        else if(exists($folder) and $authorId ne '') then core:join-path-elements((config:get-option('baseHref'), $lang, $authorId, $folder, $docID))
        else ()
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
    else if($num gt 3999) then core:logToFile('warn', 'wega:number-to-roman(): Cannot Convert Number Larger than 3999')
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
    if(config:is-letter($doc/tei:TEI/string(@xml:id))) then $doc//tei:revisionDesc/string(@status)
    else if(config:is-writing($doc/tei:TEI/string(@xml:id))) then $doc//tei:revisionDesc/string(@status)
    else if(config:is-person($doc/tei:person/string(@xml:id))) then $doc/tei:person/string(@status)
    else if(config:is-diary($doc/tei:ab/string(@xml:id))) then $doc/tei:ab/string(@status)
    else if(config:is-biblio($doc/*/string(@xml:id))) then if($doc//tei:revisionDesc) then $doc//tei:revisionDesc/string(@status) else $doc/*/string(@status) (: Extra-Wurst für Weber-Studien :)
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
    let $salt := if($salt castable as xs:int) then xs:int($salt) else xs:int(config:get-option('salt'))
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
            if($i/string(@n) eq 'telephone') then concat(lang:get-language-string('tel',$lang), ': ', $i)
            else if($i/string(@n) eq 'email') then 
                let $encryptedEmail := wega:encryptString($i, ())
                return 
                element span {
                    attribute onclick {"javascript:decEma('",$encryptedEmail,"')"},
                    attribute class {'ema'},
                    if (exists($name)) then attribute title {lang:get-language-string('sendEmail', $name, $lang)} else (),
                    wega:obfuscateEmail($i)
                }
            else if($i/string(@n) eq 'fax') then concat(lang:get-language-string('fax',$lang), ': ', $i)
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
    collection(config:get-option('persons'))//tei:idno[.=$pnd][@type='gnd']/parent::tei:person/string(@xml:id)
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
        case xs:string return core:doc($docItem)
        default return $docItem
    return $doc//tei:idno[@type='gnd']/text()
};