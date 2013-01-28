xquery version "1.0" encoding "UTF-8";

 (:~
 : WeGA AJAX XQuery-Module
 :
 : @author Peter Stadler 
 : @version 1.0
 :)

module namespace ajax="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/ajax";
declare default collation "?lang=de;strength=primary";
declare namespace tei="http://www.tei-c.org/ns/1.0";
(:declare namespace xsd="http://www.w3.org/2001/XMLSchema";:)
declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace session = "http://exist-db.org/xquery/session";
declare namespace xmldb = "http://exist-db.org/xquery/xmldb";
declare namespace cache = "http://exist-db.org/xquery/cache";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace httpclient = "http://exist-db.org/xquery/httpclient";
import module namespace functx="http://www.functx.com" at "xmldb:exist:///db/webapp/xql/modules/functx.xqm";
import module namespace wega="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/wega" at "xmldb:exist:///db/webapp/xql/modules/wega.xqm";
import module namespace facets="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/facets" at "xmldb:exist:///db/webapp/xql/modules/facets.xqm";
import module namespace jsonToXML="http://xqilla.sourceforge.net/Functions" at "xmldb:exist:///db/webapp/xql/modules/jsonToXML.xqm";

(:~
 : Creates HTML list entry
 : (function for index.xql)
 :
 : @author Christian Epp
 : @param $type of entry
 : @param $persName 
 : @param $letter
 : @param $sender
 : @param $addressee
 : @param $entryYear
 : @param $date
 : @param $lang the current language (de|en)
 : @return element
 :)

declare function ajax:createHtmlListEntry($type,$persName,$letter,$sender,$addressee,$entryYear,$date,$lang) {
    let $isRound := (year-from-date($date) - $entryYear) mod 25 = 0
    let $formatedYear := <span>{wega:formatYear($entryYear cast as xs:int, $lang)}</span>
    let $content :=
        if($type eq 'letter')       then ($formatedYear, ': ', $sender, ' ', wega:getLanguageString('writesTo', $lang), ' ', $addressee, 
                                          if(ends-with($addressee, '.')) then ' ' else '. ', wega:createDocLink($letter, 
                                          concat('[', wega:getLanguageString('readOnLetter', $lang), ']'), $lang, ('class=readOn', 'foo=bar')))
        else if($type eq 'birth')   then ($formatedYear, ': ', $persName, ' ', wega:getLanguageString('isBorn', $lang))
        else if($type eq 'baptism') then ($formatedYear, ': ', $persName, ' ', wega:getLanguageString('isBaptised', $lang))
        else if($type eq 'death')   then ($formatedYear, ': ', $persName, ' ', wega:getLanguageString('dies', $lang))
        else if($type eq 'funeral') then ($formatedYear, ': ', $persName, ' ', wega:getLanguageString('wasBuried', $lang))
        else()
    let $class :=
        if($type eq 'letter') then "eventLetter"
        else if($type eq 'birth' or $type eq 'baptism') then "eventBirth"
        else if($type eq 'death' or $type eq 'funeral') then "eventDeath"
        else ()
    return
       if($isRound)
       then <li class="{$class}" style="list-style-image:url('../pix/stern_gelb.gif')" title="{wega:getLanguageString('roundYearsAgo',xs:string(year-from-date($date) - $entryYear), $lang)}">{$content}</li> 
       else <li class="{$class}">{$content}</li>
};

(:~
 : Creates HTML list for todays events
 : (function for index.xql)
 :
 : @author Peter Stadler
 : @author Christian Epp
 : @param $date todays date
 : @param $lang the current language (de|en)
 : @return element
 :)

declare function ajax:createHtmlList($date as xs:date, $lang as xs:string) as element() {
    <ul class="{$date}">{
        for $entry in wega:getTodaysEvents($date)//entry
        let $personID := if($entry/@type eq 'birth' or $entry/@type eq 'baptism' or $entry/@type eq 'death' or $entry/@type eq 'funeral')
                         then data($entry/@id)
                         else()
        let $persName := if($entry/@type eq 'birth' or $entry/@type eq 'baptism' or $entry/@type eq 'death' or $entry/@type eq 'funeral') 
                         then wega:createPersonLink($personID, $lang, 'fs')
                         else ()
        let $letter :=   if($entry/@type eq 'letter')
                         then wega:doc($entry/@id)
                         else()
        let $senderID := if($entry/@type eq 'letter')
                         then $letter//tei:sender[1]/tei:persName/@key
                         else()
        let $addresseeID := if($entry/@type eq 'letter') 
                            then $letter//tei:addressee[1]/tei:persName/@key
                            else()
        let $sender := if($entry/@type eq 'letter') 
                       then wega:printCorrespondentName($letter//tei:sender[1]/*[1], $lang, 'fs')
                       else if (exists($letter//tei:sender/tei:persName/text())) 
                            then <i>{data($letter//tei:sender/tei:persName)}</i>
                            else <i>{wega:getLanguageString('unknown',$lang)}</i>
        let $addressee := if($entry/@type eq 'letter') 
                          then wega:printCorrespondentName($letter//tei:addressee[1]/*[1], $lang, 'fs')
                          else if (exists($letter//tei:addressee/tei:persName/text())) 
                               then <i>{data($letter//tei:addressee/tei:persName)}</i>
                               else <i>{wega:getLanguageString('unknown',$lang)}</i>
        order by $entry/number(@year) ascending
        return
            ajax:createHtmlListEntry($entry/@type,$persName,$letter,$sender,$addressee,$entry/@year,$date,$lang)
    }
    </ul>
};

(:~
 : Returns a list of the todays events
 : (function for index.xql)
 :
 : @author Peter Stadler
 : @param $date todays date
 : @param $lang the current language (de|en)
 : @return element
 :)

declare function ajax:getTodaysEvents($date,$lang) {
    let $date := if($date castable as xs:date) then $date else util:system-date()
    let $tmpDir := wega:getOption('tmpDir')
    let $todaysEventsFileName := concat('todaysEventsFile_', $lang, '.xml')
    let $todaysEventsFile := doc(concat($tmpDir, $todaysEventsFileName))
    return
        if(xs:date($date) eq $todaysEventsFile/ul/xs:date(@class) and xmldb:last-modified($tmpDir, $todaysEventsFileName) gt wega:getDateTimeOfLastDBUpdate())
        then $todaysEventsFile
        else doc(xmldb:store($tmpDir, concat('todaysEventsFile_', $lang, '.xml'), ajax:createHtmlList($date, $lang)))
};

(:~
 : Returns correspondents by a person
 : (functions for person_singleView.xql)
 :
 : @author Peter Stadler 
 : @param $id of person
 : @param $lang the current language (de|en)
 : @param $fromOffset1
 : @param $toOffset1
 : @param $correspondents
 : @return element
 :)

declare function ajax:getPersonCorrespondents($id as xs:string, $lang as xs:string, $fromOffset1 as xs:string, $toOffset1 as xs:string, $correspondents as xs:string) as element()* {
    let $fromOffset := if($fromOffset1 castable as xs:date) then string($fromOffset1) else string('0001-01-01')
    let $toOffset   := if($toOffset1   castable as xs:date) then string($toOffset1)   else string('9999-01-01')
    let $letterList := if ($correspondents eq 'addressee')
        then collection('/db/letters')//tei:sender/tei:persName[@key = $id]
            [../../tei:dateSender/tei:date[@when >= $fromOffset and @when <= $toOffset] or 
            ../../tei:dateSender/tei:date[@notBefore >= $fromOffset and @notBefore <= $toOffset] or 
            ../../tei:dateSender/tei:date[@notAfter >= $fromOffset and @notAfter <= $toOffset] or 
            ../../tei:dateSender/tei:date[@to >= $fromOffset and @to <= $toOffset] or 
            ../../tei:dateSender/tei:date[@from >= $fromOffset and @from <= $toOffset] or
            ../../tei:dateSender/tei:date[not(@when or @from or @to or @notBefore or @notAfter)]]
            /../../tei:addressee/tei:persName[@key]
        else if ($correspondents eq 'sender')
            then collection('/db/letters')//tei:addressee/tei:persName[@key = $id]
            [../../tei:dateSender/tei:date[@when >= $fromOffset and @when <= $toOffset] or 
            ../../tei:dateSender/tei:date[@notBefore >= $fromOffset and @notBefore <= $toOffset] or 
            ../../tei:dateSender/tei:date[@notAfter >= $fromOffset and @notAfter <= $toOffset] or 
            ../../tei:dateSender/tei:date[@to >= $fromOffset and @to <= $toOffset] or 
            ../../tei:dateSender/tei:date[@from >= $fromOffset and @from <= $toOffset] or
            ../../tei:dateSender/tei:date[not(@when or @from or @to or @notBefore or @notAfter)]]
            /../../tei:sender/tei:persName[@key]
            else if ($correspondents eq 'all')
                then collection('/db/letters')//tei:sender/tei:persName[@key = $id] 
                     (:[../../tei:dateSender/tei:date[@when >= $fromOffset and @when <= $toOffset] or 
                     ../../tei:dateSender/tei:date[@notBefore >= $fromOffset and @notBefore <= $toOffset] or 
                     ../../tei:dateSender/tei:date[@notAfter >= $fromOffset and @notAfter <= $toOffset] or 
                     ../../tei:dateSender/tei:date[@to >= $fromOffset and @to <= $toOffset] or 
                     ../../tei:dateSender/tei:date[@from >= $fromOffset and @from <= $toOffset] or
                     ../../tei:dateSender/tei:date[not(@when or @from or @to or @notBefore or @notAfter)]]:)
                     /../../tei:addressee/tei:persName[@key]
                     | collection('/db/letters')//tei:addressee/tei:persName[@key = $id]
                     (:[../../tei:dateSender/tei:date[@when >= $fromOffset and @when <= $toOffset] or 
                     ../../tei:dateSender/tei:date[@notBefore >= $fromOffset and @notBefore <= $toOffset] or 
                     ../../tei:dateSender/tei:date[@notAfter >= $fromOffset and @notAfter <= $toOffset] or 
                     ../../tei:dateSender/tei:date[@to >= $fromOffset and @to <= $toOffset] or 
                     ../../tei:dateSender/tei:date[@from >= $fromOffset and @from <= $toOffset] or
                     ../../tei:dateSender/tei:date[not(@when or @from or @to or @notBefore or @notAfter)]]:)
                     /../../tei:sender/tei:persName[@key]
                else()
    return 
        for $i in $letterList 
        group $i as $partition by $i/@key as $key
            order by count($partition) descending
            return <person>{$key, count($partition)}</person>
};

(:~
 : Returns a DIV containing the correspondents to a person
 : (functions for person_singleView.xql)
 :
 : @author Peter Stadler
 : @param $id of person
 : @param $lang the current language (de|en)
 : @param $fromOffset1
 : @param $toOffset1
 : @param $correspondents
 : @param $max
 : @return element
 :)

declare function ajax:printCorrespondents($id as xs:string, $lang as xs:string, $fromOffset1 as xs:string, $toOffset1 as xs:string, $correspondents as xs:string, $max as xs:int) as element() {
    let $correspondents := ajax:getPersonCorrespondents($id, $lang, $fromOffset1, $toOffset1, $correspondents)
    let $baseHref := wega:getOption('baseHref')
    let $linkElements := 
        for $x in subsequence($correspondents,1,$max)
        let $key := $x/string(@key)
        let $doc := wega:doc($key)
        let $persNameSelected := wega:getRegName($key) (:wega:cleanString($person/tei:persName[@type='reg']):)
        let $persNameSelectedCount := $x cast as xs:int
        order by $persNameSelectedCount descending, $persNameSelected ascending
        return element a {
            attribute href {wega:createLinkToDoc($doc, $lang)},
            attribute title {
                if ($persNameSelectedCount gt 1) then concat($persNameSelected, ' (', $persNameSelectedCount, ' ', wega:getLanguageString('letters',$lang), ')')
                else concat($persNameSelected, ' (', $persNameSelectedCount, ' ', wega:getLanguageString('letter',$lang), ')')},
            element img {
                attribute src {wega:getPortraitPath($doc/tei:person, (40, 55), $lang)},
                attribute alt {$persNameSelected},
                attribute width {'40'},
                attribute height {'55'}
            }
        }
    return element div{$linkElements}
};

(:~
 : Returns iconography list
 : (function for person_singleView.xql)
 :
 : @author Peter Stadler
 : @param $fffiID
 : @param $pnd
 : @param $lang the current language (de|en)
 : @return 
 :)

declare function ajax:getIconography($fffiID as xs:string, $pnd as xs:string, $lang as xs:string) as element(img)* {
let $localIconography := collection('/db/iconography')//tei:person[@corresp=$fffiID]/ancestor::tei:TEI
let $personDocUri := if(exists($localIconography)) 
    then document-uri(wega:doc($fffiID))
    else ()
return
    (
    for $pic in $localIconography[.//tei:graphic/@url]
        let $caption := $pic//tei:titleStmt/tei:title
        let $graphicUrl := $pic//tei:graphic/string(@url)
        let $crop := if($pic//tei:graphic/xs:int(substring-before(@width, 'px')) > 400 or $pic//tei:graphic/xs:int(substring-before(@height, 'px')) > 600)
            then true()
            else false()
        let $localURL := functx:replace-multi($personDocUri, ('/db/', '\.xml'), ('/db/images/', concat('/', $graphicUrl)))
        let $thumbnail := <img src="{wega:createDigilibURL($localURL, (40, 55), true())}" alt="{$caption}" width="40" height="55"/>
        return wega:createLightboxAnchor(wega:createDigilibURL($localURL, $crop), $caption, 'person-iconography', $thumbnail),
        
    for $pic in wega:retrieveImagesFromWikipedia($pnd,$lang)//wega:wikipediaImage
        return  <img src="{wega:createDigilibURL($pic/wega:localUrl, (40, 55), true())}" alt="{$pic/wega:caption}" title="{$pic/wega:caption}" width="40" height="55"/>
    )
};

(:~
 : Returns the biography of a person
 : (function for person_singleView.xql)
 :
 : @author Peter Stadler
 : @param $id of the person
 : @param $lang the current language (de|en)
 : @return element
 :)

declare function ajax:getBiography($id as xs:string, $lang as xs:string) as element()* {
let $person := wega:doc($id)
let $xslParams := <parameters><param name="lang" value="{$lang}"/></parameters>
let $baseHref := wega:getOption('baseHref')
return (
    if($person//tei:note[@type="bioSummary"])
        then
            <div id="bioSummary">
                <h2>{wega:getLanguageString('bioSummary',$lang)}</h2>
                {wega:changeNamespace(transform:transform($person//tei:note[@type="bioSummary"], doc("/db/webapp/xsl/person_singleView.xsl"), $xslParams), '', ())}
            </div>
        else 
            if($person//tei:event) then ()
            else <div id="bioSummary"><i>({wega:getLanguageString('noBioFound',$lang)})</i></div>,
        if($id eq 'A002068') then 
            if ($lang eq 'en') then ()
            else <p class="linkAppendix">Einen ausführlichen Lebenslauf finden Sie in der <a href="{concat($baseHref, '/de/Biographie')}">erweiterten Biographie</a></p> 
        else wega:getEvents($person/tei:person,$lang)
        )
};

(:~
 : Grab Wikipedia article for a given PND
 : (functions for person_singleView.xql)
 :
 : @author Peter Stadler
 : @param $pnd the PND number
 : @param $lang the language variable (de|en)
 : @return div for insertion into a xhtml page 
 :)
 
declare function ajax:getWikipedia($pnd as xs:string, $lang as xs:string) as element() {
    let $pnd := request:get-parameter('pnd','118629662')
    let $lang := request:get-parameter('lang', 'de')
    let $wikiContent := wega:grabExternalResource('wikipedia', $pnd, $lang, true())
    let $wikiUrl := $wikiContent//xhtml:div[@class eq 'printfooter']/xhtml:a[1]/@href
    let $xslParams := <parameters><param name="lang" value="{$lang}"/></parameters>
    let $name := normalize-space($wikiContent//xhtml:h1[@id = 'firstHeading'])
    let $appendix := if($lang eq 'en') then 
        <p class="linkAppendix">The content of this "Wikipedia" entitled box is taken from the article "<a href='{$wikiUrl}' title='Wikipedia article for {$name}'>{$name}</a>" 
        from <a href="http://en.wikipedia.org">Wikipedia</a>, the free encyclopedia, 
        and is released under a <a href="http://creativecommons.org/licenses/by-sa/3.0/deed.en">CC-BY-SA-license</a>.
        You will find the <a href="{concat(replace($wikiUrl, 'wiki/', 'w/index.php?title='), '&amp;action=history')}" title="Authors and revision history of the Wikipedia Article for {$name}">revision history along with the authors</a> of this article in Wikipedia.</p>
        
        else 
        <p class="linkAppendix">Der Inhalt dieser mit "Wikipedia" bezeichneten Box entstammt dem Artikel "<a href='{$wikiUrl}' title='Wikipedia Artikel zu "{$name}"'>{$name}</a>" 
        aus der freien Enzyklopädie <a href="http://de.wikipedia.org" title="Wikipedia Hauptseite">Wikipedia</a> 
        und steht unter der <a href="http://creativecommons.org/licenses/by-sa/3.0/deed.de">CC-BY-SA-Lizenz</a>. 
        In der Wikipedia findet sich auch die <a href="{concat(replace($wikiUrl, 'wiki/', 'w/index.php?title='), '&amp;action=history')}" title='Autoren und Versionsgeschichte des Wikipedia Artikels zu "{$name}"'>Versionsgeschichte mitsamt Autorennamen</a> für diesen Artikel.</p>

    let $result := if(exists($wikiContent//xhtml:meta)) 
        then (
            <div class="wikipediaText">
                {transform:transform($wikiContent//xhtml:div[@id='bodyContent'], doc('/db/webapp/xsl/person_wikipedia.xsl'), $xslParams)}
                {$appendix}
            </div>
        )
        else <span class="notAvailable">{wega:getLanguageString('noWikipediaEntryFound', $lang)}</span>
        
    return 
    (:wega:castDateFormat('Wed, 03 Apr 2010 19:09:48 GMT'):)
        wega:changeNamespace($result, '', ())
};

(:~
 : Grab ADB article from wikisource for a given PND
 : (function for person_singleView.xql)
 :
 : @author Peter Stadler
 : @param $pnd the PND number
 : @param $lang the language variable (de|en)
 : @return div for insertion into a xhtml page 
 :)
 
declare function ajax:getADB($pnd as xs:string, $lang as xs:string) as element() {
    let $pnd := request:get-parameter('pnd','118629662')
    let $lang := request:get-parameter('lang', 'de')
    let $wikiContent := wega:grabExternalResource('adb', $pnd, (), true())
    let $wikiUrl := $wikiContent//xhtml:div[@id = 'adbcite']/xhtml:a[2]/@href
    let $xslParams := <parameters><param name="lang" value="{$lang}"/></parameters>
    let $name := normalize-space($wikiContent//xhtml:h1[@id = 'firstHeading'])
    let $appendix := transform:transform($wikiContent//xhtml:div[@id='adbcite'], doc('/db/webapp/xsl/person_wikipedia.xsl'), <parameters><param name="lang" value="{$lang}"/><param name="mode" value="appendix"/></parameters>)
    let $result := if(exists($wikiContent//xhtml:meta)) 
        then (
            <div class="wikipediaText">
                {transform:transform($wikiContent//xhtml:div[@id='bodyContent'], doc('/db/webapp/xsl/person_wikipedia.xsl'), $xslParams)}
                {$appendix}
            </div>
        )
        else <span class="notAvailable">{wega:getLanguageString('noADBEntryFound', $lang)}</span>
        
    return 
    (:wega:castDateFormat('Wed, 03 Apr 2010 19:09:48 GMT'):)
        wega:changeNamespace($result, '', ())
};

(:~
 : Grab DNB site for information for a given PND
 : (function for person_singleView.xql)
 :
 : @author Peter Stadler
 : @param $pnd the PND number
 : @param $lang the language variable (de|en)
 : @return div for insertion into a xhtml page 
 :)
 
declare function ajax:getDNB($pnd as xs:string, $lang as xs:string) as element(div) {
    let $dnbContentRoot := wega:grabExternalResource('dnb', $pnd, (), true())//httpclient:body//xhtml:div[@class='chapters'][data(./xhtml:h2)=concat(wega:getOption('dnb'),$pnd)]/xhtml:table[1]
    let $name := normalize-space($dnbContentRoot//xhtml:td[preceding-sibling::xhtml:td/xhtml:strong = 'Person'])
    let $roleName := normalize-space($dnbContentRoot//xhtml:td[preceding-sibling::xhtml:td/xhtml:strong = 'Adelstitel'])
    let $otherNames := string-join($dnbContentRoot//xhtml:td[preceding-sibling::xhtml:td/xhtml:strong ='Andere Namen']/text()/normalize-space(.), '; ') 
    let $dates := for $i in $dnbContentRoot//xhtml:td/text()[matches(., 'Lebensdaten')] return normalize-space(substring-after($i, 'Lebensdaten: '))
    let $occupation := string-join($dnbContentRoot//xhtml:td[preceding-sibling::xhtml:td/xhtml:strong ='Beruf(e)']/xhtml:a, ', ')
    let $appendix := if($lang='en') then <p class="linkAppendix">For associated publications and further information please visit <a href="http://d-nb.info/gnd/{$pnd}" title="DNB-entry for {$name}">the complete entry</a> at the German National Library.</p>
            else <p class="linkAppendix">Zu verknüpfter Literatur und weiteren Informationen siehe den <a href="http://d-nb.info/gnd/{$pnd}" title="DNB-Eintrag für {$name}">vollständigen Eintrag</a> in der Deutschen Nationalbibliothek.</p>
    return (
        <div id="dnbFrame">
            <ul>
                <li><span class="desc">{wega:getLanguageString('pnd_name', $lang)}:</span> {$name}</li>
                {
                if ($roleName ne '') then element li {element span {attribute class {"desc"}, concat(wega:getLanguageString('pnd_roleName', $lang), ':')}, $roleName} else(),
                if (exists($dates)) then for $date in $dates return element li {element span {attribute class {"desc"}, concat(wega:getLanguageString('pnd_dates', $lang), ':')}, $date} else(),
                if ($occupation ne '') then element li {element span {attribute class {"desc"}, concat(wega:getLanguageString('pnd_occupation', $lang), ':')}, $occupation} else(),
                if ($otherNames ne '') then element li {element span {attribute class {"desc"}, concat(wega:getLanguageString('pnd_otherNames', $lang), ':')}, $otherNames} else()
                }
            </ul>
            {$appendix}
        </div>
        )
};

(:~
 : Query beacon.findbuch.de for a list of institutions that hold information for a given pnd
 : (functions for person_singleView.xql)
 :
 : @author Peter Stadler
 : @param $pnd the PND number
 : @param $lang the language variable (de|en)
 : @return element
 :)
 
declare function ajax:getPNDBeacons($pnd as xs:string, $name as xs:string, $lang as xs:string) as element() {
    let $findbuchResponse := wega:grabExternalResource('beacon', $pnd, (), true())
    let $jxml := if(exists($findbuchResponse)) then jsonToXML:parse-json(util:binary-to-string($findbuchResponse)) else () 
    let $list :=
          <ul>{
            for $i in 1 to count($jxml//json/item[2]//item)
            let $link  := data($jxml//json/item[4]/item[$i])
            let $title := data($jxml//json/item[3]/item[$i])
            let $text  := data($jxml//json/item[2]/item[$i])
            return
                if(data($jxml//json/item[4]/item[$i])!="" and not(matches($link,"weber-gesamtausgabe.de")))
                then <li><a title="{$title}" href="{$link}">{$text}</a></li>
                else()
          }
          </ul>
    return if (exists($list/li)) then
        <div>
            <h2>{wega:getLanguageString('beaconLinks', ($name,$pnd), $lang)}</h2>
            {$list
            (:$findbuchQuery//p:)}
            <!--<p>[ <a href="{data($jxml//json/item[1]//item)}">DNB-Artikel</a> ]</p>-->
        </div>
        else <span class="notAvailable">{wega:getLanguageString('noBeaconsFound', $lang)}</span>
};

(:~
 : Gets list from entries with key
 : (functions for letter_singleView.xql)
 :
 : @author Peter Stadler
 : @param $docID
 : @param $lang the language variable (de|en)
 : @param $entry
 : @return element
 :)
 
declare function ajax:getListFromEntriesWithKey($docID,$lang,$entry) {
    let $doc := wega:doc($docID)
    let $isDiary := wega:isDiary($docID)
    let $coll := 
        if ($entry eq 'person') then
            if($isDiary) then functx:value-union($doc//tei:persName/string(@key), functx:value-union($doc//tei:rs[@type eq 'person']/string(@key), for $i in $doc//tei:rs[@type = 'persons']/string(@key) return tokenize($i, ' ')))
            else functx:value-union($doc//tei:text//tei:persName/string(@key), functx:value-union($doc//tei:text//tei:rs[@type = 'person']/string(@key), for $i in $doc//tei:text//tei:rs[@type = 'persons']/string(@key) return tokenize($i, ' ')))
        else if ($entry eq 'work') then 
            if($isDiary) then functx:value-union($doc//tei:workName/string(@key), functx:value-union($doc//tei:rs[@type eq 'work']/string(@key), for $i in $doc//tei:rs[@type = 'works']/string(@key) return tokenize($i, ' ')))
            else functx:value-union($doc//tei:text//tei:workName/string(@key), functx:value-union($doc//tei:text//tei:rs[@type eq 'work']/string(@key), for $i in $doc//tei:text//tei:rs[@type = 'works']/string(@key) return tokenize($i, ' ')))
        else ()
    return if ($coll != '') then (
        for $x in distinct-values($coll)[. != '']
        let $regName := 
            if($entry eq 'person') then wega:getRegName($x)
            else if($entry eq 'work') then wega:getRegTitle($x)
            else ()
        order by $regName ascending
        return 
        <li onclick="highlightSpanClassInText('{$x}',this)">{$regName}</li>
    )
    else (<li class="noDataFound">{wega:getLanguageString('noDataFound',$lang)}</li>)
};

(:~
 : Returns letter context
 : (functions for requestLetterContext)
 :
 : @author Peter Stadler
 : @param $docID ID of letter
 : @param $lang the current language (de|en)
 : @return element 
 :)

declare function ajax:requestLetterContext($docID as xs:string, $lang as xs:string) as element()* {
    let $doc := wega:doc($docID)
    let $persons := wega:getNormDates('persons') 
    let $authorID := $doc//tei:fileDesc/tei:titleStmt/tei:author[1]/@key (:$doc//tei:sender/tei:persName[1]/@key:)
    let $addresseeID := $doc//tei:addressee/tei:persName[1]/@key
    let $senderName := wega:printCorrespondentName($doc//tei:fileDesc/tei:titleStmt/tei:author[1], $lang, 'fs')
    let $addresseeName := wega:printCorrespondentName($doc//tei:addressee[1]/*[1], $lang, 'fs') (: siehe Ticket #739 :)
    let $normDates := if(exists($authorID)) then wega:getNormDates('letters') else ()
    
    (: Vorausgehender Brief in der Liste des Autors (= vorheriger von-Brief) :)
    let $prevLetterFromSender := $normDates//entry[@docID = $docID][not(functx:all-whitespace(.))]/preceding-sibling::entry[@authorID = $authorID][not(functx:all-whitespace(.))][position() eq last()]
    (: Vorausgehender Brief in der Liste an den Autors (= vorheriger an-Brief) :)
    let $prevLetterToSender := $normDates//entry[@docID = $docID][not(functx:all-whitespace(.))]/preceding-sibling::entry[@addresseeID = $authorID][not(functx:all-whitespace(.))][position() eq last()]
    (: Nächster Brief in der Liste des Autors (= nächster von-Brief) :)
    let $nextLetterFromSender := $normDates//entry[@docID = $docID][not(functx:all-whitespace(.))]/following-sibling::entry[@authorID = $authorID][not(functx:all-whitespace(.))][xs:integer(1)] 
    (: Nächster Brief in der Liste an den Autor (= nächster an-Brief) :)
    let $nextLetterToSender := $normDates//entry[@docID = $docID][not(functx:all-whitespace(.))]/following-sibling::entry[@addresseeID = $authorID][not(functx:all-whitespace(.))][xs:integer(1)]
    (: Direkter vorausgehender Brief des Korrespondenzpartners (worauf dieser eine Antwort ist) :)
    let $prevLetterFromAddressee := $normDates//entry[@docID = $docID][not(functx:all-whitespace(.))]/preceding-sibling::entry[@authorID = $addresseeID][@addresseeID = $authorID][not(functx:all-whitespace(.))][position() eq last()]
    (: Direkter vorausgehender Brief des Autors an den Korrespondenzpartner :)
    let $prevLetterFromAuthorToAddressee := $normDates//entry[@docID = $docID][not(functx:all-whitespace(.))]/preceding-sibling::entry[@authorID = $authorID][@addresseeID = $addresseeID][not(functx:all-whitespace(.))][position() eq last()]
    (: Direkter Antwortbrief des Adressaten:)
    let $replyLetterFromAddressee := $normDates//entry[@docID = $docID][not(functx:all-whitespace(.))]/following-sibling::entry[@authorID = $addresseeID][@addresseeID = $authorID][not(functx:all-whitespace(.))][xs:integer(1)]
    (: Antwort des Autors auf die Antwort des Adressaten :)
    let $replyLetterFromSender := $normDates//entry[@docID = $docID][not(functx:all-whitespace(.))]/following-sibling::entry[@authorID = $authorID][@addresseeID = $addresseeID][not(functx:all-whitespace(.))][xs:integer(1)] 
    return (
        <h3>{wega:getLanguageString('absouluteChronology',$lang)}</h3>,
        <h4>{wega:getLanguageString('prevLetters',$lang)}</h4>,
        <ul>{
          ajax:printLetterContextLink($prevLetterFromSender, false(), $lang),
          ajax:printLetterContextLink($prevLetterToSender, true(), $lang),
        (: Ausgabe von "no data found" when keiner der o.a. Briefe existiert, z.B. bei undatierten Briefen :)    
          if(exists($prevLetterFromSender) or exists($prevLetterToSender))
              then ()
              else <li class="noDataFound">{wega:getLanguageString('noDataFound',$lang)}</li>
        }</ul>,
        <h4>{wega:getLanguageString('nextLetters',$lang)}</h4>,
        <ul>{
          ajax:printLetterContextLink($nextLetterFromSender, false(), $lang),
          ajax:printLetterContextLink($nextLetterToSender, true(), $lang),
        (: Ausgabe von "no data found" when keiner der o.a. Briefe existiert, z.B. bei undatierten Briefen :)
          if(exists($nextLetterFromSender) or exists($nextLetterToSender))
              then()
              else <li class="noDataFound">{wega:getLanguageString('noDataFound',$lang)}</li>
        }</ul>,
        <h3>{wega:getLanguageString('korrespondenzstelle',$lang)}</h3>,
        <h4>{wega:getLanguageString('prevLetters',$lang)}</h4>,
        <ul>{
            ajax:printLetterContextLink($prevLetterFromAuthorToAddressee, false(), $lang),
            ajax:printLetterContextLink($prevLetterFromAddressee, true(), $lang),
            (: Ausgabe von "no data found" when keiner der o.a. Briefe existiert, z.B. bei undatierten Briefen :)
            if(exists($prevLetterFromAuthorToAddressee) or exists($prevLetterFromAddressee))
                then()
                else <li class="noDataFound">{wega:getLanguageString('noDataFound',$lang)}</li>
        }</ul>,
        <h4>{wega:getLanguageString('nextLetters',$lang)}</h4>,
        <ul>{
            ajax:printLetterContextLink($replyLetterFromSender, false(), $lang),
            ajax:printLetterContextLink($replyLetterFromAddressee, true(), $lang),
            (: Ausgabe von "no data found" when keiner der o.a. Briefe existiert, z.B. bei undatierten Briefen :)
            if(exists($replyLetterFromSender) or exists($replyLetterFromAddressee))
                then()
                else <li class="noDataFound">{wega:getLanguageString('noDataFound',$lang)}</li>
        }</ul>
    )
};

(:~
 : Returns context of letter
 : (functions for requestLetterContext)
 :
 : @author Peter Stadler
 : @param $docNormEntry
 : @param $from 
 : @param $lang the current language (de|en)
 : @return element
 :)

declare function ajax:printLetterContextLink($docNormEntry as element(entry)?, $from as xs:boolean, $lang as xs:string) as element(li)? {
    if(exists($docNormEntry)) then (
        let $docID := $docNormEntry/data(@docID)
        let $doc := wega:doc($docID)
        let $authorID := if($docNormEntry/@authorID ne '') then $docNormEntry/data(@authorID) else wega:getOption('anonymusID')
        let $linkText := if($docNormEntry eq '') then wega:getLanguageString('withoutDate', $lang) else string($docNormEntry)
        let $additionalText := if($from) 
            then (concat(wega:getLanguageString('from', $lang), ' '), wega:printCorrespondentName($doc//tei:fileDesc/tei:titleStmt/tei:author[1], $lang, 'fs')) 
            else (concat(wega:getLanguageString('to',   $lang), ' '), wega:printCorrespondentName($doc//tei:addressee[1]/*[1], $lang, 'fs')) (: siehe Ticket #739 :)
        return 
        element li {
            wega:createDocLink($doc, $linkText, $lang, ()),
            ': ',
            $additionalText
        }
    )
    else ()
};

(:~
 : Gets list from entries without keys
 : (functions for requestLetterContext)
 :
 : @author Peter Stadler
 : @param $docID ID of letter
 : @param $lang the current language (de|en)
 : @param $entry
 : @return 
 :)

declare function ajax:getListFromEntriesWithoutKey($docID,$lang,$entry) {
    let $doc := wega:doc($docID)
    let $coll := if($entry = 'person')
     then $doc//tei:text//tei:persName[not(@key)] | $doc//tei:text//tei:rs[@type='person' or @type='persons'][not(@key)] | (: Letters :)
         $doc//tei:ab//tei:persName[not(@key)] | $doc//tei:ab//tei:rs[@type='person' or @type='persons'][not(@key)] (: Diaries :)
     else if($entry = 'work')
         then $doc//tei:text//tei:workName | $doc//tei:text//tei:rs[@type='work' or @type='works'] |
             $doc//tei:ab//tei:workName | $doc//tei:ab//tei:rs[@type='work' or @type='works']
         else if($entry = 'character')
             then $doc//tei:text//tei:characterName | 
                 $doc//tei:ab//tei:characterName
             else if($entry = 'place')
                 then $doc//tei:text//tei:placeName | 
                     $doc//tei:ab//tei:placeName
                 else ()    
    return if (exists($coll)) 
     then (
         for $entry in distinct-values($coll)
         let $asciiCode := string-join(for $i in (string-to-codepoints(normalize-space(data($entry)))) return string($i),'')
         order by $entry ascending
         return (<li onclick="highlightSpanClassInText('{$asciiCode}',this)">{data($entry)}</li>))
    
     else (<li class="noDataFound">{wega:getLanguageString('noDataFound',$lang)}</li>)
};

(:~
 : Returns transcription of letter
 : (functions for requestLetterContext)
 :
 : @author Peter Stadler
 : @param $docID ID of letter
 : @param $lang the current language (de|en)
 : @return 
 :)

declare function ajax:letter_printTranscription($docID,$lang) {
    let $doc := wega:doc($docID)
    let $xslParams := 
     <parameters>
         <param name="lang" value="{$lang}"/>
         <param name="dbPath" value="{document-uri($doc)}"/>
         <param name="docID" value="{$docID}"/>
         <param name="transcript" value="true"/>
     </parameters>
    let $header := wega:getLetterHead($doc, $lang)
    let $letter := 
         if(functx:all-whitespace($doc//tei:text))
         (: Entfernen von Namespace-Deklarationen: siehe http://wiki.apache.org/cocoon/RemoveNamespaces :)
         then (
            let $summary := if(functx:all-whitespace($doc//tei:note[@type='summary'])) then () else wega:changeNamespace(transform:transform($doc//tei:note[@type='summary'], doc("/db/webapp/xsl/letter_text.xsl"), $xslParams), '', ()) 
            let $incipit := if(functx:all-whitespace($doc//tei:incipit)) then () else wega:changeNamespace(transform:transform($doc//tei:incipit, doc("/db/webapp/xsl/letter_text.xsl"), $xslParams), '', ())
            let $text := if($doc//tei:correspDesc[@n = 'revealed']) then wega:getLanguageString('correspondenceTextNotAvailable', $lang)
                         else wega:getLanguageString('correspondenceTextNotYetAvailable', $lang)
            return element div {
                attribute id {'teiLetter_body'},
                $incipit,
                $summary,
                element span {
                    attribute class {'notAvailable'},
                    $text
                }
            }
         )
         else (wega:changeNamespace(transform:transform($doc//tei:text, doc("/db/webapp/xsl/letter_text.xsl"), $xslParams), '', ()))
    return ($header, $letter)
};

(:~
 : Returns transcription of document
 : (functions for requestLetterContext)
 :
 : @author Peter Stadler
 : @param $docID ID of document
 : @param $lang the current language (de|en)
 : @return 
 :)

declare function ajax:doc_printTranscription($docID,$lang) {
    let $doc := wega:doc($docID)
    let $xslParamsHeader := 
        <parameters>
            <param name="lang" value="{$lang}"/>
            <param name="dbPath" value="{document-uri($doc)}"/>
            <param name="docID" value="{$docID}"/>
            <param name="transcript" value="true"/>
            <param name="headerMode" value="true"/>
        </parameters>
    let $xslParamsText := <parameters>{$xslParamsHeader/*[not(@name='headermode')]}</parameters> (: Entspricht $xslParamsHeader nur ohne headerMode-Parameter, was im Stylesheet zu unterschiedlichen modes führt :)
    let $header :=	
    	element header { 
    		transform:transform($doc//tei:fileDesc/tei:titleStmt, doc("/db/webapp/xsl/doc_text.xsl"), $xslParamsHeader)
    	}
    let $transformedHeader := wega:changeNamespace($header, '', ())
    let $document := 
        if(functx:all-whitespace($doc//tei:text)) (: tei:body kommt auch in tei:floatingText vor! :)
    (: Entfernen von Namespace-Deklarationen: siehe http://wiki.apache.org/cocoon/RemoveNamespaces :)
            then (<div id="teiDoc_body">{wega:getLanguageString('correspondenceTextNotYetAvailable', $lang)}</div>)
            else (wega:changeNamespace(transform:transform($doc//tei:text, doc("/db/webapp/xsl/doc_text.xsl"), $xslParamsText), '', ()))
    return ($transformedHeader/*, $document)
};

(:~
 : Returns transcription of diary site
 : (functions for diary_singleView.xql)
 :
 : @author Peter Stadler
 : @param $docID ID of diary entry
 : @param $lang the current language (de|en)
 : @return element
 :)
 
declare function ajax:diary_printTranscription($docID as xs:string, $lang as xs:string) {
    let $doc := wega:doc($docID)
    let $xslParams := <parameters><param name="lang" value="{$lang}"/><param name="transcript" value="true"/></parameters>
    let $dateFormat := if ($lang eq 'en')
        then '%A, %B %d, %Y'
        else '%A, %d. %B %Y'
    return 
        <div class="diaryDay" id="{$doc/tei:ab/string(@xml:id)}">
            <h2>{wega:strftime($dateFormat, xs:date($doc/tei:ab/@n), $lang)}</h2>
            {wega:changeNamespace(transform:transform($doc, doc('/db/webapp/xsl/diary_tableLeft.xsl'), $xslParams), '', ())}
            {wega:changeNamespace(transform:transform($doc, doc('/db/webapp/xsl/diary_tableRight.xsl'), $xslParams), '', ())}
        </div>,
        <div class="clearer"></div>
};

(:~
 : Returns context of diary site
 : (functions for diary_singleView.xql)
 :
 : @author Peter Stadler
 : @param $contextContainer
 : @param $docID ID of diary entry
 : @param $lang the current language (de|en)
 : @return element
 :)

declare function ajax:getDiaryContext($contextContainer as xs:string, $docID as xs:string, $lang as xs:string) {
    let $authorID := 'A002068'
    let $coll := facets:getOrCreateColl('diaries', $authorID)
    let $currPos := functx:index-of-node($coll, $coll//id($docID))
    return 
    <div id="{$contextContainer}">
        <h2>{wega:getLanguageString('context', $lang)}</h2>
        <ul>{
            if($currPos gt 1) 
                then element li {
                    wega:getLanguageString('prevDiaryDay', $lang),
                    <br/>,
                    wega:createDocLink($coll[$currPos - 1]/root(), wega:getNiceDate($coll[$currPos - 1]/xs:date(@n), $lang), $lang, ())
                }
                else (),
            if($currPos lt count($coll)) 
                then element li {
                    wega:getLanguageString('nextDiaryDay', $lang),
                    <br/>,
                    wega:createDocLink($coll[$currPos + 1]/root(), wega:getNiceDate($coll[$currPos + 1]/xs:date(@n), $lang), $lang, ())
                }
                else ()
            }
        </ul>
    </div>
};

(:~
 : Returns context of news
 : (function for news_singleView.xql)
 :
 : @author Peter Stadler
 : @param $contextContainer
 : @param $docID news ID
 : @param $lang the current language (de|en)
 : @return 
 :)

declare function ajax:getNewsContext($contextContainer as xs:string, $docID as xs:string, $lang as xs:string) {
(:    let $authorID := 'A002068':)
    let $coll := facets:getOrCreateColl('news', 'indices')
    let $currPos := functx:index-of-node($coll, $coll//id($docID))
    let $baseHref := wega:getOption('baseHref') 
    return 
    <div id="{$contextContainer}">
        <h2>{wega:getLanguageString('context', $lang)}</h2>
        <ul>{
            if($currPos lt count($coll)) (: Absteigende Sortierung! :)
                then element li {
                    wega:getLanguageString('prevDiaryDay', $lang),
                    <br/>,
                    wega:createDocLink($coll[$currPos + 1]/root(), $coll[$currPos + 1]/string(@xml:id), $lang, ()) (: Absteigende Sortierung! :)
                }
                else (),
            if($currPos gt 1)  (: Absteigende Sortierung! :)
                then element li {
                    wega:getLanguageString('nextDiaryDay', $lang),
                    <br/>,
                    wega:createDocLink($coll[$currPos - 1]/root(), $coll[$currPos - 1]/string(@xml:id), $lang, ()) (: Absteigende Sortierung! :)
                }
                else (),
            element li {
                attribute class {'gotoArchive'},
                element a {
                    attribute href {string-join(($baseHref, $lang, wega:getLanguageString('indices', $lang), wega:getLanguageString('news', $lang)), '/')},
                    attribute title {wega:getLanguageString('newsArchive', $lang)},
                    wega:getLanguageString('goToArchive', $lang)
                }
            }
            }
        </ul>
    </div>
};

(:~
 : True, if collection to the docType is in session
 :
 : @author Peter Stadler
 : @param $docType
 : @return xs:boolean
 :)

(:  Wird gerade erstmal nicht mehr genutzt?? :)
declare function ajax:isFilterColl($docType) {
    let $sessionCollName := facets:getCollName($docType, false())
    let $coll := session:get-attribute($sessionCollName)
    return exists($coll)
};