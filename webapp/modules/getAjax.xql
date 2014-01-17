xquery version "1.0" encoding "UTF-8";
declare default collation "?lang=de;strength=primary";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace session="http://exist-db.org/xquery/session";
declare namespace util="http://exist-db.org/xquery/util";
import module namespace ajax="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/ajax" at "ajax.xqm";
import module namespace wega="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/wega" at "wega.xqm";
import module namespace dev="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/dev" at "dev.xqm";
import module namespace facets="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/facets" at "facets.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";

declare option exist:serialize "method=xhtml media-type=text/html indent=no omit-xml-declaration=yes encoding=utf-8";

let $function := request:get-parameter('function','')
let $lang := request:get-parameter('lang', '')
return
    if($function='getIconography') then 
        let $id := tokenize(request:get-parameter('id','A002068'), '\s')[1]
        let $pnd := request:get-parameter('pnd',())
        return ajax:getIconography($id,$pnd,$lang)
        
    else if($function='getMetaData') then
        let $id := request:get-parameter('id','A002068')
        let $usage := request:get-parameter('usage',())
        return wega:getDocumentMetaData($id, $lang, $usage)
        
    else if($function='getPersonCorrespondents') then
        let $id := request:get-parameter('id','A002068')
        let $correspondents := request:get-parameter('correspondents','sender')
        let $fromOffset := request:get-parameter('fromOffset','')
        let $toOffset := request:get-parameter('toOffset','')
        return ajax:printCorrespondents($id,$lang,$fromOffset,$toOffset,$correspondents,12)
        
    else if($function='getBiography') then
        let $id := request:get-parameter('id','A002068')
        return ajax:getBiography($id,$lang)
        
    else if($function='getListFromEntriesWithKey') then
        let $docID := request:get-parameter('id','A041453')
        let $entry := request:get-parameter('entry', ())
        return ajax:getListFromEntriesWithKey($docID,$lang,$entry)
    
    else if($function='requestLetterContext') then
        let $docID := request:get-parameter('id', 'A040914')
        return ajax:requestLetterContext($docID, $lang)
        
    else if($function='getListFromEntriesWithoutKey') then
        let $docID := request:get-parameter('id',())
        let $entry := request:get-parameter('entry', ())    
        return ajax:getListFromEntriesWithoutKey($docID,$lang,$entry)
        
    else if($function='printTranscription') then
        let $docID := request:get-parameter('id','')
        return ajax:printTranscription($docID,$lang)
    
    else if($function eq 'getDiaryContext') then
        let $contextContainer := request:get-parameter('contextContainer','')
        let $docID := request:get-parameter('id','A060141')
        return ajax:getDiaryContext($contextContainer, $docID, $lang)
        
    else if($function eq 'diary_printTranscription') then
        let $docID := request:get-parameter('docID','A060141')
        return ajax:diary_printTranscription($docID, $lang)
    
    else if($function eq 'getNewsContext') then
        let $contextContainer := request:get-parameter('contextContainer','')
        let $docID := request:get-parameter('id','A050001')
        return ajax:getNewsContext($contextContainer, $docID, $lang) 
        
    else if($function eq 'showToolsTab' and config:get-option('environment') eq 'development') then
        let $docType := request:get-parameter('docType','common')
        return dev:showToolsTab($docType, $lang) 

    else if($function eq 'generateID' and config:get-option('environment') eq 'development') then
        let $docType := 
            if($lang eq 'en') then request:get-parameter('docType','common')
            else doc(config:get-option(concat('dic_', $lang)))//entry[lower-case(.) eq lower-case(request:get-parameter('docType', 'Personen'))]/string(@xml:id)
        return dev:createNewID($docType) 

    else if($function eq 'validateIDs' and config:get-option('environment') eq 'development') then
        let $docType := 
            if($lang eq 'en') then request:get-parameter('docType','common')
            else doc(config:get-option(concat('dic_', $lang)))//entry[lower-case(.) eq lower-case(request:get-parameter('docType', 'Personen'))]/string(@xml:id)
        return dev:validateIDs($docType)
    
    else if($function eq 'validatePNDs' and config:get-option('environment') eq 'development') then
        let $docType := 
            if($lang eq 'en') then request:get-parameter('docType','common')
            else doc(config:get-option(concat('dic_', $lang)))//entry[lower-case(.) eq lower-case(request:get-parameter('docType', 'Personen'))]/string(@xml:id)
        return dev:validatePNDs($docType)
    
    else if($function eq 'validatePaths' and config:get-option('environment') eq 'development') then
        let $docType := 
            if($lang eq 'en') then request:get-parameter('docType','common')
            else doc(config:get-option(concat('dic_', $lang)))//entry[lower-case(.) eq lower-case(request:get-parameter('docType', 'Personen'))]/string(@xml:id)
        return dev:validatePaths($docType)
        
    else if($function eq 'getTodaysEvents') then
        let $date := if(request:get-parameter('date',()) castable as xs:date) then request:get-parameter('date',()) else ()
        return ajax:getTodaysEvents($date,$lang)

    else if($function eq 'getWikipedia') then
        let $pnd := request:get-parameter('pnd','')
        return ajax:getWikipedia($pnd,$lang)

    else if($function eq 'getADB') then
        let $pnd := request:get-parameter('pnd','')
        return ajax:getADB($pnd,$lang)

    else if($function eq 'getDNB') then
        let $pnd := request:get-parameter('pnd','')
        return ajax:getDNB($pnd,$lang)

    else if($function eq 'getPNDBeacons') then
        let $pnd := request:get-parameter('pnd','')
        let $name := request:get-parameter('name','')
        return ajax:getPNDBeacons($pnd,$name,$lang)
    
    else if($function eq 'isFilterColl') then 
        let $docType := request:get-parameter('docType','')
        return ajax:isFilterColl($docType)
        
    else if($function eq 'search_testID') then 
        let $id := request:get-parameter('id','')
        let $doc := core:doc($id)
        return if(exists($doc)) then wega:createLinkToDoc($doc, $lang) else ()

    else if($function eq 'getFacetCategories') then
        let $setResponseHeader := response:set-header('cache-control', 'no-cache')
        let $docType := request:get-parameter('docType',())
        let $facetCategories := facets:getFacetCategories($docType) 
        let $writeFacetCategories := session:set-attribute('facetCategories', $facetCategories)
        return count($facetCategories//facets:entry)
        
    else if($function eq 'createFacetFromFacetFile') then
    	let $setResponseHeader := response:set-header('cache-control', 'no-cache')
        let $id := request:get-parameter('id','')
        let $docType := request:get-parameter('docType',())
        let $facetCategories := session:get-attribute('facetCategories')
        let $entryNo := 1 + count($facetCategories//facets:entry) - request:get-parameter('entryNo','') cast as xs:int
        return facets:createFacetFromFacetFile($facetCategories//facets:entry[$entryNo], $id, $docType, $lang)
    
	else if($function eq 'createChronoAlphaMenu') then
		let $setResponseHeader := response:set-header('cache-control', 'no-cache')
        let $id := request:get-parameter('id','')
        let $docType := request:get-parameter('docType',())
        return 
        	if($docType eq 'writings') then facets:createChronoList($docType, $lang)
        	else if($docType eq 'letters') then facets:createChronoList($docType, $lang)
        	else if($docType eq 'diaries') then facets:createChronoList($docType, $lang)
        	else if($docType eq 'works') then facets:getSeries($docType, $lang)
        	else if($docType eq 'persons') then facets:createAlphabetList($docType, $lang)
        	else if($docType eq 'news') then facets:createChronoList($docType, $lang)
        	else if($docType eq 'biblio') then facets:createChronoList($docType, $lang)
        	else ()
    
    else if($function eq 'getSubMenu') then
    	let $setResponseHeader := response:set-header('cache-control', 'no-cache')
        let $entriesSessionName := request:get-parameter('entriesSessionName','')
        let $orderSessionName := request:get-parameter('orderSessionName','')
        return 
        	if(matches($entriesSessionName, 'persons')) then facets:createAlphabetListUl($entriesSessionName, $orderSessionName, $lang, 1)
        	else facets:createYearAndMonthUl($entriesSessionName, $orderSessionName, $lang, 1)

    else()
