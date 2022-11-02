xquery version "3.1" encoding "UTF-8";

(:~
 : Functions for querying data from the WeGA-data app 
:)
module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace gn="http://www.geonames.org/ontology#";
declare namespace range="http://exist-db.org/xquery/range";
declare namespace sort="http://exist-db.org/xquery/sort";
declare namespace map="http://www.w3.org/2005/xpath-functions/map";
declare namespace ft="http://exist-db.org/xquery/lucene";

import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace crud="http://xquery.weber-gesamtausgabe.de/modules/crud" at "crud.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace wdt="http://xquery.weber-gesamtausgabe.de/modules/wdt" at "wdt.xqm";
import module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util" at "wega-util.xqm";
import module namespace er="http://xquery.weber-gesamtausgabe.de/modules/external-requests" at "external-requests.xqm";
import module namespace functx="http://www.functx.com";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/str.xqm";
import module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/date.xqm";

(:~
 : Print the regularised title for a given WeGA ID
 : The function serves as a convenient shortcut to the wdt:* title functions, 
 : e.g. wdt:persons($key)('title')('txt')
 :
 : @param $key the WeGA ID, e.g. A002068
 : @author Peter Stadler
 : @return xs:string
 :)
declare function query:title($key as xs:string) as xs:string {
    let $docType := config:get-doctype-by-id($key) 
    let $response := wdt:lookup($docType, $key)('title')('txt')
    return 
        if(exists($response)) then $response
        else ''
};

(:~
 : Grabs the first author from a TEI document and returns its WeGA ID
 :
 : @author Peter Stadler 
 : @param $item the id of the TEI document (or the document node itself) to grab the author from
 : @return xs:string the WeGA ID
:)
declare function query:get-authorID($doc as document-node()?) as xs:string* {
    let $author-element := query:get-author-element($doc)
    let $id := $author-element/@key | $author-element/@codedval
    return
        if(exists($doc) and count($id) gt 0) then $id ! string(.)
        else if(exists($doc)) then config:get-option('anonymusID')
        else ()
};

(:~
 : Grabs the first author from a TEI document and returns its name (as noted in the document)
 : For the regularized name see query:title()
 :
 : @author Peter Stadler 
 : @param $item the id of the TEI document (or the document node itself) to grab the author from
 : @return xs:string the name of the author
:)
declare function query:get-authorName($doc as document-node()?) as xs:string {
    if(exists($doc)) then 
        if(config:is-diary($doc/tei:ab/@xml:id)) then 'Carl Maria von Weber' (: Diverse Sonderbehandlungen fürs Tagebuch :)
        else normalize-space(query:get-author-element($doc)[1])
    else ''
};

declare function query:get-author-element($doc as document-node()?) as element()* {
    if(config:is-diary($doc/tei:ab/@xml:id)) then <tei:author key="A002068">Weber, Carl Maria von</tei:author> (: Sonderbehandlung fürs Tagebuch :)
    else ( 
        $doc//mei:fileDesc/mei:titleStmt/mei:respStmt/mei:persName[@role = ('cmp', 'aut', 'lbt')] |
        $doc//tei:fileDesc/tei:titleStmt/tei:author
    )
};

(:~
 : Retrieves a document by GND identifier
 :
 : @author Peter Stadler
 : @param $gndID the GND (Gemeinsame Normdatei = German Authority File) identifier
 : @return the documents identified by the identifier
:)
declare function query:doc-by-gnd($gndID as xs:string) as document-node()* {
    core:getOrCreateColl('persons', 'indices', true())//tei:idno[.=$gndID][@type='gnd']/root() |
    core:getOrCreateColl('orgs', 'indices', true())//tei:idno[.=$gndID][@type='gnd']/root() |
    core:getOrCreateColl('works', 'indices', true())//mei:altId[.=$gndID][@type='gnd']/root() 
};


(:~
 : Retrieves a document by VIAF identifier
 :
 : @author Peter Stadler
 : @param $viafID the VIAF (Virtual International Authority File) identifier
 : @return the documents identified by the identifier
:)
declare function query:doc-by-viaf($viafID as xs:string) as document-node()* {
    let $gndID := er:viaf2gnd($viafID)
    return
        core:getOrCreateColl('persons', 'indices', true())//tei:idno[.=$viafID][@type='viaf']/root() |
        core:getOrCreateColl('orgs', 'indices', true())//tei:idno[.=$viafID][@type='viaf']/root() |
        core:getOrCreateColl('works', 'indices', true())//mei:altId[.=$viafID][@type='viaf']/root() |
        core:getOrCreateColl('persons', 'indices', true())//tei:idno[.=$gndID][@type='gnd']/root() |
        core:getOrCreateColl('orgs', 'indices', true())//tei:idno[.=$gndID][@type='gnd']/root() |
        core:getOrCreateColl('works', 'indices', true())//mei:altId[.=$gndID][@type='gnd']/root() 
};

(:~
 : Retrieves a document by Wikidata Q-identifier
 :
 : @author Peter Stadler
 : @param $wikidataID the Wikidata Q-Identifier
 : @return the documents identified by the identifier
:)
declare function query:doc-by-wikidata($wikidataID as xs:string) as document-node()* {
    let $annotatedDocs := 
        core:getOrCreateColl('persons', 'indices', true())//tei:idno[.=$wikidataID][@type='wikidata']/root() |
        core:getOrCreateColl('orgs', 'indices', true())//tei:idno[.=$wikidataID][@type='wikidata']/root() |
        core:getOrCreateColl('works', 'indices', true())//mei:altId[.=$wikidataID][@type='wikidata']/root()
    let $queriedDocs :=
        if(count($annotatedDocs) lt 1)
        then er:translate-authority-id(<tei:idno type="wikidata">{$wikidataID}</tei:idno>, 'wega') ! crud:doc(.)
        else ()
    return (
        $annotatedDocs, $queriedDocs
    )
};

(:~
 : Return GND for persons, organizations, places and works
 :
 : @author Peter Stadler
 : @param $item may be xs:string (the WeGA ID), document-node() or some root element
 : @return the GND as xs:string, or empty sequence if nothing was found 
:)
declare function query:get-gnd($item as item()?) as xs:string? {
    let $doc := 
        typeswitch($item)
            case xs:string return crud:doc($item)
            case xs:untypedAtomic return crud:doc(string($item))
            case attribute() return crud:doc(string($item))
            case element() return $item
            case document-node() return $item
            default return ()
    return
        (: WARNING: there might be several IDs of the same kind :)
        if($doc//tei:idno[@type = 'gnd']) then ($doc//tei:idno[@type = 'gnd'])[1]
        else if($doc//tei:idno[@type='viaf']) then ($doc//tei:idno[@type='viaf'] ! er:translate-authority-id(., 'gnd'))[1]
        else if($doc//tei:idno[@type='geonames']) then ($doc//tei:idno[@type='geonames'] ! er:translate-authority-id(., 'gnd'))[1]
        else if($doc//mei:altId[@type = 'gnd']) then ($doc//mei:altId[@type = 'gnd'])[1]
        else ()
};

(:~
 : Return VIAF ID for persons, organizations, places and works
 :
 : @author Peter Stadler
 : @param $item may be xs:string (the WeGA ID), document-node() or some root element
 : @return the VIAF ID as xs:string, or empty sequence if nothing was found 
:)
declare function query:get-viaf($item as item()?) as xs:string? {
    let $doc := 
        typeswitch($item)
            case xs:string return crud:doc($item)
            case xs:untypedAtomic return crud:doc(string($item))
            case attribute() return crud:doc(string($item))
            case element() return $item
            case document-node() return $item
            default return ()
    return
        (: WARNING: there might be several IDs of the same kind :)
        if($doc//tei:idno[@type = 'viaf']) then ($doc//tei:idno[@type = 'viaf'])[1]
        else if($doc//tei:idno[@type='gnd']) then ($doc//tei:idno[@type='gnd'] ! er:translate-authority-id(., 'viaf'))[1]
        else if($doc//tei:idno[@type='geonames']) then ($doc//tei:idno[@type='geonames'] ! er:translate-authority-id(., 'viaf'))[1]
        else if($doc//mei:altId[@type = 'viaf']) then ($doc//mei:altId[@type = 'viaf'])[1]
        else if($doc//mei:altId[@type='gnd']) then ($doc//mei:altId[@type='gnd'] ! er:translate-authority-id(., 'viaf'))[1]
        else ()
};


(:~
 : Return Geonames ID for places
 :
 : @author Peter Stadler
 : @param $item may be xs:string (the WeGA ID), document-node() (of a place file), or a tei:place element
 : @return the Geonames ID as xs:string, or empty sequence if nothing was found 
:)
declare function query:get-geonamesID($item as item()?) as xs:string? {
    let $doc := 
        typeswitch($item)
            case xs:string return crud:doc($item)
            case xs:untypedAtomic return crud:doc(string($item))
            case attribute() return crud:doc(string($item))
            case element() return $item
            case document-node() return $item
            default return ()
    return
        if($doc/descendant-or-self::tei:place) then $doc//tei:idno[@type='geonames']
        else ()
};

(:~
 : Return the main GeoNames name of a place
 :
 : @param $gn-url the GeoNames URL for a place, e.g. http://sws.geonames.org/2921044/
 : @return the main name as given in the GeoNames RDF as gn:name 
:)
declare function query:get-geonames-name($gn-id as xs:string) as xs:string? {
    er:grabExternalResource('geonames', $gn-id, '', ())//gn:name
};


(:~ 
 : Gets events of the day for a certain date
 :
 : @author Peter Stadler
 : @param $date todays date
 : @return tei:date* tei:date elements that match given day and month of $date
 :)
declare function query:getTodaysEvents($date as xs:date) as node()* {
    let $day := functx:pad-integer-to-length(day-from-date($date), 2)
    let $month := functx:pad-integer-to-length(month-from-date($date), 2)
    let $month-day := concat('-', $month, '-', $day)
    return 
        core:getOrCreateColl('letters', 'indices', true())//tei:correspAction[@type='sent']/tei:date[contains(@when, $month-day)][following::tei:text//tei:p] union
        core:getOrCreateColl('persons', 'indices', true())//tei:date[contains(@when, $month-day)][not(preceding-sibling::tei:date[contains(@when, $month-day)])][parent::tei:birth or parent::tei:death][ancestor::tei:person/@source='WeGA']
};

(:~
 : Fetches the main title element
 :
 : @author Peter Stadler
 : @param $doc the TEI document
 : @return 
 :)
declare function query:get-title-element($doc as document-node(), $lang as xs:string) as element()? {
    let $docID := $doc/*/data(@xml:id)
    return
        if(config:is-diary($docID)) then <tei:date>{$doc/tei:ab/data(@n)}</tei:date>
        else if(config:is-work($docID)) then ($doc//mei:fileDesc/mei:titleStmt/mei:title[not(@type)])[1]
        else if(config:is-var($docID)) then ($doc//tei:title[@level = 'a'][@xml:lang = $lang])[1]
        else ($doc//tei:fileDesc/tei:titleStmt/tei:title[@level = 'a'])[1]
};

(:~
 : Get the main text source of an electronic document
 : This is a simple wrapper around query:text-sources() to enforce a single, main source
 : 
 : @param $doc the TEI or MEI document
 : @return the element describing the main source, e.g. a <tei:bibl> element or a <tei:msDesc> element  
 :)
declare function query:get-main-source($doc as document-node()) as element()? {
    let $sources := query:text-sources($doc)
    return
        if(count($sources) gt 1) then $sources/parent::tei:witness[@n='1']/* | $sources/parent::tei:listBibl/tei:*[1]
        else $sources
};

(:~
 : Get the text sources of an electronic document
 :
 : @param $doc the TEI or MEI document
 : @return the elements describing the sources, e.g. a <tei:bibl> element or a <tei:msDesc> element  
 :)
declare function query:text-sources($doc as document-node()) as element()* {
    let $docID := $doc/*/data(@xml:id)
    let $docType := config:get-doctype-by-id($docID)
    let $source := 
        switch($docType)
        case 'diaries' return 
            <tei:msDesc>
               <tei:msIdentifier>
                  <tei:country>D</tei:country>
                  <tei:settlement>Berlin</tei:settlement>
                  <tei:repository n="D-B">Staatsbibliothek zu Berlin – Preußischer Kulturbesitz</tei:repository>
                  <tei:idno>Mus. ms. autogr. theor. C. M. v. Weber WFN 1</tei:idno>
               </tei:msIdentifier>
            </tei:msDesc>
        case 'works' case 'sources' return () (:$model('doc')//mei:sourceDesc:)
        case 'biblio' return $doc/tei:biblStruct
        default return $doc//tei:sourceDesc/tei:*
    return 
        typeswitch($source)
        case element(tei:listWit) return $source/tei:witness/tei:*
        case element(tei:listBibl) return $source/tei:*
        default return $source
};

(:~
 : Get the normalized date for a document
 : NB: This should be aligned with the function `facets:normalize-date()` from the WeGA-data facets module! 
 :
 : @author Peter Stadler
 : @param $doc the TEI document
 : @return xs:date
 :)
declare function query:get-normalized-date($doc as document-node()) as xs:date? {
    let $docID := $doc/*/data(@xml:id)
    let $date := 
        switch(config:get-doctype-by-id($docID))
        (: for Weber writings the creation date should take precedence over the publication date :)
        case 'writings' return date:getOneNormalizedDate(($doc[query:get-authorID(.) = 'A002068']//tei:creation/tei:date[@* except @cert],query:get-main-source($doc)/tei:monogr/tei:imprint/tei:date)[1], true())
        case 'letters' return date:getOneNormalizedDate(($doc//tei:correspAction[@type='sent']/tei:date, $doc//tei:correspAction[@type='received']/tei:date)[1], true())
        case 'biblio' return date:getOneNormalizedDate($doc//tei:imprint[1]/tei:date, true())
        case 'diaries' return $doc/tei:ab/data(@n)
        case 'news' return $doc//tei:date[parent::tei:publicationStmt]/substring(@when,1,10)
        case 'documents' return date:getOneNormalizedDate($doc//tei:creation/tei:date, true())
        default return () 
    return 
        if($date castable as xs:date) then $date cast as xs:date
        else ()
};

(:~
 : see also $search:valid-params
~:)
declare function query:get-facets($collection as node()*, $facet as xs:string) as item()* {
    switch($facet)
    case 'sender' return $collection//tei:correspAction[range:eq(@type,'sent')]//@key[parent::tei:persName or parent::name or parent::tei:orgName]
    case 'addressee' return $collection//tei:correspAction[range:eq(@type,'received')]//@key[parent::tei:persName or parent::name or parent::tei:orgName]
    case 'docStatus' return $collection/*/@status | $collection//tei:revisionDesc/@status
    case 'placeOfSender' return $collection//tei:settlement[parent::tei:correspAction/@type='sent']/@key
    case 'placeOfAddressee' return $collection//tei:settlement[parent::tei:correspAction/@type='received']/@key
    case 'journals' return $collection//tei:title[@level='j'][not(@type='sub')][ancestor::tei:sourceDesc]
    case 'places' return $collection//tei:settlement[ancestor::tei:text or ancestor::tei:ab]/@key
    case 'dedicatees' return $collection//mei:persName[@role='dte']/@codedval
    case 'lyricists' return $collection//mei:persName[@role='lyr']/@codedval
    case 'librettists' return $collection//mei:persName[@role='lbt']/@codedval
    case 'composers' return $collection//mei:persName[@role=('cmp','aut')]/@codedval
    case 'docSource' return $collection/tei:person/@source
    case 'occupations' return $collection//tei:occupation | $collection//tei:label[.='Art der Institution']/following-sibling::tei:desc
    case 'residences' return $collection//tei:settlement[parent::tei:residence]/@key | $collection//tei:label[.='Ort']/following-sibling::tei:desc/tei:settlement/@key
        (: index-keys does not work with multiple whitespace separated keys
            probably need to change to ft:query() someday?!
        :)
    case 'persons' return ($collection//tei:persName[ancestor::tei:text or ancestor::tei:ab]/@key | $collection//tei:rs[@type='person'][ancestor::tei:text or ancestor::tei:ab]/@key)
    case 'works' return $collection//tei:workName[ancestor::tei:text or ancestor::tei:ab]/@key[string-length(.) = 7] | $collection//tei:rs[@type='work'][ancestor::tei:text or ancestor::tei:ab]/@key[string-length(.) = 7]
    case 'authors' return $collection//tei:author/@key
    case 'editors' return $collection//tei:editor/@key
    case 'biblioType' return $collection/tei:biblStruct/@type
    case 'docTypeSubClass' return $collection//tei:text/@type
    case 'sex' return $collection//tei:sex | $collection//tei:label[.='Art der Institution'] (:/following-sibling::tei:desc:)
    case 'forenames' return $collection//tei:forename[not(@full)]
    case 'surnames' return $collection//tei:surname | $collection//tei:orgName[@type]
    case 'einrichtungsform' return $collection//mei:term[@label='einrichtungsform']
    case 'vorlageform' return $collection//mei:term[@label='vorlageform']
    case 'asksam-cat' return $collection//mei:term[@label='asksam-cat']
    case 'placenames' return $collection//tei:placeName[@type='reg']
    case 'repository' return $collection//tei:repository/@n
    case 'series' return $collection//mei:seriesStmt/mei:title[@level='s']
    case 'keywords' return $collection//tei:term[parent::tei:keywords]
    case 'docLang' return $collection//tei:language/@ident
    case 'workTitle' return $collection//mei:title[parent::mei:titleStmt]
    case 'geonamesFeatureClass' return $collection//tei:place/@typeof
    default return ()
};

(:~
 :  Compute correspondence partners
 :  For each correspondent (addressees and senders) of $id 
 :  the sum of incoming and outgoing correspondence will be computed  
 :
 :  @param $id the person ID for which to compute the partners
 :  @return a map object with all correspondence partner IDs and the respective weights, 
 :      e.g. map {"A000915": 2, "A008673": 57}  
 :)
declare function query:correspondence-partners($id as xs:string) as map(*) {
    let $id-as-sender := map {  "facets": map { "sender": $id } }
    let $id-as-addressee := map { "facets": map { "addressee": $id } }
    let $result1 := crud:data-collection('letters')/tei:TEI[ft:query(., (), $id-as-sender)] 
    let $facets1 := ft:facets($result1, "addressee", ())
    let $result2 := crud:data-collection('letters')/tei:TEI[ft:query(., (), $id-as-addressee)] 
    let $facets2 := ft:facets($result2, "sender", ())
    return
        map:merge((
            $facets2,
            map:for-each($facets1, function($label, $count) {
                map:entry($label, sum(($count, $facets2($label))))
            })
        ))
};

(:~
 : Lookup the places of a diary entry
 :
 : @param $diaryDay the document with the diary entry 
 : @return an array of strings with the canonical names of the places 
~:)
declare function query:place-of-diary-day($diaryDay as document-node()) as array(xs:string) {
    let $placeIDs := tokenize($diaryDay/tei:ab/@where, '\s+')[config:is-place(.)]
    return
        array {
            $placeIDs ! query:title(.)
        }
};

(:~
 : Extract all contributors from the document
~:)
declare function query:contributors($doc as document-node()?) as xs:string* {
    let $contributors := 
        $doc//tei:fileDesc/tei:titleStmt/(tei:author | tei:editor) |
        $doc//tei:respStmt/tei:name |
        $doc//mei:respStmt/mei:persName
    return
        distinct-values($contributors ! str:normalize-space(.))
};

(:~
 : Query the letter context, i.e. preceding and following letters
 :
 : @param $doc the TEI document with correspondence information provided in tei:correspDesc
 : @param $senderID optional sender ID for co-authorship letters. If none is provided, the first sender in $doc will be taken.
 : @return a map object with objects representing 'context-letter-absolute-prev', 'context-letter-absolute-next',
 :      'context-letter-korrespondenzstelle-prev', and 'context-letter-korrespondenzstelle-next', e.g.  { 'context-letter-absolute-prev': { 'fromTo': 'to', 'doc': document-node() } } 
~:)
declare function query:correspContext($doc as document-node(), $senderID as xs:string?) as map(*)? {
    let $docID := $doc/tei:TEI/data(@xml:id)
    let $authorID := 
        if($doc//tei:correspAction[@type='sent']/tei:*[self::tei:persName or self::tei:orgName or self::tei:name][@key=$senderID])
        then $senderID
        else ($doc//tei:correspAction[@type='sent']/tei:*[self::tei:persName or self::tei:orgName or self::tei:name])[1]/@key
    let $addresseeID := ($doc//tei:correspAction[@type='received']/tei:*[self::tei:persName or self::tei:orgName or self::tei:name])[1]/@key
    let $authorColl := 
        if($authorID) then core:getOrCreateColl('letters', $authorID, true())
        else ()
    let $indexOfCurrentLetter := sort:index('letters', $doc)
    
    (: Vorausgehender Brief in der Liste des Autors (= vorheriger von-Brief) :)
    (: Need to create the collection outside of the call to wdt:letters() because of performance issues :)
    let $prevLetterFromSenderColl := $authorColl[sort:index('letters', .) lt $indexOfCurrentLetter]//tei:correspAction[@type='sent']/tei:*[self::tei:persName or self::tei:orgName or self::tei:name][@key=$authorID]
    let $prevLetterFromSender := wdt:letters($prevLetterFromSenderColl)('sort')(())[last()]/root()
    (: Vorausgehender Brief in der Liste an den Autors (= vorheriger an-Brief) :)
    let $prevLetterToSenderColl := $authorColl[sort:index('letters', .) lt $indexOfCurrentLetter]//tei:correspAction[@type='received']/tei:*[self::tei:persName or self::tei:orgName or self::tei:name][@key=$authorID]
    let $prevLetterToSender := wdt:letters($prevLetterToSenderColl)('sort')(())[last()]/root()
    (: Nächster Brief in der Liste des Autors (= nächster von-Brief) :)
    let $nextLetterFromSenderColl := $authorColl[sort:index('letters', .) gt $indexOfCurrentLetter]//tei:correspAction[@type='sent']/tei:*[self::tei:persName or self::tei:orgName or self::tei:name][@key=$authorID]
    let $nextLetterFromSender := wdt:letters($nextLetterFromSenderColl)('sort')(())[1]/root()
    (: Nächster Brief in der Liste an den Autor (= nächster an-Brief) :)
    let $nextLetterToSenderColl := $authorColl[sort:index('letters', .) gt $indexOfCurrentLetter]//tei:correspAction[@type='received']/tei:*[self::tei:persName or self::tei:orgName or self::tei:name][@key=$authorID]
    let $nextLetterToSender := wdt:letters($nextLetterToSenderColl)('sort')(())[1]/root()
    (: Direkter vorausgehender Brief des Korrespondenzpartners (worauf dieser eine Antwort ist) :)
    let $prevLetterFromAddressee :=
        if($doc//tei:correspContext) then crud:doc($doc//tei:correspContext/tei:ref[@type='previousLetterFromAddressee']/string(@target))
        else (
            let $prevLetterFromAddresseeColl := $authorColl[sort:index('letters', .) lt $indexOfCurrentLetter]//tei:correspAction[@type='sent']/tei:*[self::tei:persName or self::tei:orgName or self::tei:name][@key=$addresseeID]
            return wdt:letters($prevLetterFromAddresseeColl)('sort')(())[last()]/root()
        )
    (: Direkter vorausgehender Brief des Autors an den Korrespondenzpartner :)
    let $prevLetterFromAuthorToAddresseeColl := $authorColl[sort:index('letters', .) lt $indexOfCurrentLetter]//tei:correspAction[@type='received']/tei:*[self::tei:persName or self::tei:orgName or self::tei:name][@key=$addresseeID]
    let $prevLetterFromAuthorToAddressee := wdt:letters($prevLetterFromAuthorToAddresseeColl)('sort')(())[last()]/root()
    (: Direkter Antwortbrief des Adressaten:)
    let $replyLetterFromAddressee := 
        if($doc//tei:correspContext) then crud:doc($doc//tei:correspContext/tei:ref[@type='nextLetterFromAddressee']/string(@target))
        else (
            let $replyLetterFromAddresseeColl := $authorColl[sort:index('letters', .) gt $indexOfCurrentLetter]//tei:correspAction[@type='sent']/tei:*[self::tei:persName or self::tei:orgName or self::tei:name][@key=$addresseeID]
            return wdt:letters($replyLetterFromAddresseeColl)('sort')(())[1]/root()
        )
    (: Antwort des Autors auf die Antwort des Adressaten :)
    let $replyLetterFromSenderColl := $authorColl[sort:index('letters', .) gt $indexOfCurrentLetter]//tei:correspAction[@type='received']/tei:*[self::tei:persName or self::tei:orgName or self::tei:name][@key=$addresseeID]
    let $replyLetterFromSender := wdt:letters($replyLetterFromSenderColl)('sort')(())[1]/root()
    
    let $create-map := function($letter as document-node()?, $fromTo as xs:string) as map(*)? {
        if($letter and exists(query:get-normalized-date($letter))) then
            map {
                'fromTo' : $fromTo,
                'doc' : $letter
            }
        else ()
    }
    
    return
        if($prevLetterFromSender,$prevLetterToSender,$nextLetterFromSender,$nextLetterToSender,$prevLetterFromAuthorToAddressee,$prevLetterFromAddressee,$replyLetterFromSender,$replyLetterFromAddressee) then  
            map {
                'context-letter-absolute-prev' : ($create-map($prevLetterFromSender, 'to'), $create-map($prevLetterToSender, 'from')),
                'context-letter-absolute-next' : ($create-map($nextLetterFromSender, 'to'), $create-map($nextLetterToSender, 'from')),
                'context-letter-korrespondenzstelle-prev' : ($create-map($prevLetterFromAuthorToAddressee, 'to'), $create-map($prevLetterFromAddressee, 'from')),
                'context-letter-korrespondenzstelle-next' : ($create-map($replyLetterFromSender, 'to'), $create-map($replyLetterFromAddressee, 'from'))
            }
        else ()
};

(:~
 : Return the TEI facsimile elements if present and on the greenlist supplied in the options file.
 : External references to IIIF manifests via the @sameAs attribute on the tei:facsimile element are *always* passed on
 :
 : @param $doc the TEI document to look for the facsimile elements
 : @return TEI facsimile elements if available, the empty sequence otherwise
~:)
declare function query:facsimile($doc as document-node()?) as element(tei:facsimile)* {
    let $facsimileGreenList := tokenize(config:get-option('facsimileGreenList'), '\s+')
    return
        if($config:isDevelopment) then $doc//tei:facsimile[tei:graphic/@url or tei:graphic/@sameAs or @sameAs]
(:        else if($doc//tei:repository[@n=$facsimileGreenList]) then $doc//tei:facsimile[tei:graphic/@url or @sameAs castable as xs:anyURI]:)
(:        else if($doc//tei:facsimile[@sameAs castable as xs:anyURI]) then $doc//tei:facsimile:)
        else $doc//tei:facsimile[@sameAs castable as xs:anyURI] 
            | $doc//tei:facsimile[query:facsimile-witness(.)//tei:repository[@n=$facsimileGreenList]][tei:graphic/@url or tei:graphic/@sameAs]
            | $doc//tei:facsimile[tei:graphic[starts-with(@url, 'http')]]
};

(:~
 : Return the appropriate source element for a given TEI facsimile element
 : (this is the inverse function of query:witness-facsimile())
 :
 : @param $facsimile the TEI facsimile element
 : @return a TEI 'biblLike' element describing the source (e.g. msDesc, or biblStruct) if available, the empty sequence otherwise
~:)
declare function query:facsimile-witness($facsimile as element(tei:facsimile)) as element()? {
    let $sourceID := substring($facsimile/@source, 2)
    let $source :=
        if($sourceID) then $facsimile/preceding::tei:sourceDesc//tei:*[@xml:id=$sourceID]
        else $facsimile/preceding::tei:sourceDesc/tei:*
    return
        if($source[self::tei:witness]) then $source/*
        else $source
};

(:~
 : Return the appropriate TEI facsimile element for a given source (aka biblLike) element
 : (this is the inverse function of query:facsimile-witness())
 :
 : @param $source the TEI 'biblLike' element (e.g. msDesc, or biblStruct)
 : @return a TEI facsimile element if available, the empty sequence otherwise
~:)
declare function query:witness-facsimile($source as element()) as element(tei:facsimile)? {
    let $sourceID := ($source/@xml:id, $source/parent::tei:witness/@xml:id)[1] (: the ID can be given on the 'biblLike' element itself or the parent witness element :) 
    return 
        if($sourceID) then $source/following::tei:facsimile[@source = concat('#', $sourceID)]
        else $source/following::tei:facsimile[not(@source)]
};


(:~
 : Query the related documents (drafts, etc.) for a given document
 :
 : @return a map with only one key 'context-relatedItems'. 
 :      The value of this key is a sequence of maps, each containing the keys 'context-relatedItem-type', 'context-relatedItem-doc' and 'context-relatedItem-n'
~:)
declare function query:context-relatedItems($doc as document-node()?) as map(*)? {
    let $relatedItems :=  
        for $relatedItem in $doc//tei:notesStmt/tei:relatedItem
        return 
            map {
                'context-relatedItem-type': data($relatedItem/@type),
                'context-relatedItem-doc': crud:doc(substring-after($relatedItem/@target, ':')),
                'context-relatedItem-n': data($relatedItem/@n)
            }
    return
        if(exists($relatedItems)) then 
            map { 
                'context-relatedItems' : $relatedItems
            }
        else ()
};

(:~
 :  Return the child elements that encode placeName information, i.e. 
 :    tei:placeName, tei:settlement, tei:region or tei:country
 :
 :  @param $parent-nodes the parent node of the placeName elements, e.g. tei:birth or tei:correspAction
 :  @return a sequence of elements
~:)
declare function query:placeName-elements($parent-nodes as node()*) as node()* {
    for $parent in $parent-nodes
    return $parent/*[self::tei:placeName or self::tei:settlement or self::tei:region or self::tei:country]
};

(:~
 :  Return persnames responsible for a work
 :
 :  @param $doc the TEI or MEI document to look for the relators
 :  @return mei:persName or tei:persName elements
~:)
declare function query:relators($doc as document-node()?) as element()* {
    $doc//mei:fileDesc/mei:titleStmt/mei:respStmt/mei:persName[@role][not(@role='dte')] | query:get-author-element($doc)
};

(:~
 :  Return licencing information
 : 
 :  @param $doc the TEI or MEI document to look for a licence
 :  @return licence as xs:anyURI if given in the document, 'https://creativecommons.org/licenses/by/4.0/' otherwise
~:)
declare function query:licence($doc as document-node()?) as xs:anyURI {
    if($doc//tei:licence/@target castable as xs:anyURI) then xs:anyURI($doc//tei:licence/@target)
    else xs:anyURI('https://creativecommons.org/licenses/by/4.0/') 
};

(:~
 :  Return the incipit of a document
 :  @param $doc a TEI document
 :  @return the incipit as a the note element
~:)
declare function query:incipit($doc as document-node()?) as element(tei:note)? {
    $doc//tei:note[@type='incipit']
};

(:~
 :  Return the general remark of a document
 :  @param $doc a TEI document
 :  @return the general remark as a note element
~:)
declare function query:generalRemark($doc as document-node()?) as element(tei:note)? {
    $doc//tei:note[@type='editorial']
};

(:~
 :  Return the summary of a document
 :  @param $doc a TEI document
 :  @param $lang the language code, e.g. "de" or "en"
 :  @return the summary as a note element
~:)
declare function query:summary($doc as document-node()?, $lang as xs:string?) as element(tei:note)? {
    let $summaries := $doc//tei:note[@type='summary']
    return
        if($summaries[@xml:lang = $lang]) then $summaries[@xml:lang = $lang]
        else $summaries[1] (: always return a summary if possible :)
};
