xquery version "3.1" encoding "UTF-8";

(:~
 :
 :  Module for exporting BEACON files
 :  see https://de.wikipedia.org/wiki/Wikipedia:BEACON
 :
 :)

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace oai="http://www.openarchives.org/OAI/2.0/";

import module namespace functx="http://www.functx.com";
import module namespace crud="http://xquery.weber-gesamtausgabe.de/modules/crud" at "crud.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util" at "wega-util.xqm";
import module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/date.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/str.xqm";
import module namespace mycache="http://xquery.weber-gesamtausgabe.de/modules/cache" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/cache.xqm";
import module namespace lod="http://xquery.weber-gesamtausgabe.de/modules/lod" at "lod.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";
import module namespace wdt="http://xquery.weber-gesamtausgabe.de/modules/wdt" at "wdt.xqm";

declare option output:method "xml";
declare option output:media-type "application/xml";
declare option output:indent "yes";

declare variable $oai:last-modified as xs:dateTime? := 
    if($config:svn-change-history-file/dictionary/@dateTime castable as xs:dateTime) 
    then $config:svn-change-history-file/dictionary/xs:dateTime(@dateTime)
    else (
        let $versionDateSeq := tokenize(config:get-option('versionDate'),'-')
        let $year := subsequence($versionDateSeq,1,1)
        let $month := subsequence($versionDateSeq,2,1)
        let $day := subsequence($versionDateSeq,3,1)
        return
            functx:dateTime($year,$month,$day,0,0,0)
    );

declare %private function oai:response-headers() as empty-sequence() {
    response:set-header('Access-Control-Allow-Origin', '*'),
    response:set-header('Last-Modified', date:rfc822($oai:last-modified)), 
    response:set-header('Cache-Control', 'max-age=300,public')
};

declare function oai:oai($model as map(*)) as node() {
	<OAI-PMH xmlns="http://www.openarchives.org/OAI/2.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/ http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd">
		 <responseDate>{fn:current-dateTime()}</responseDate>
		 <request verb="GetRecord" identifier="{lod:DC.identifier($model)}" metadataPrefix="oai_dc">http://www.openarchives.org/OAI/2.0/oai_dc/</request> 
		 <GetRecord>
			  {oai:record($model)}
		 </GetRecord> 
	</OAI-PMH>      
};

declare function oai:record($model as map(*)) as node() {
    let $docID := $model('docID')
    let $lang := $model('lang')
    return
    	<record xmlns="http://www.openarchives.org/OAI/2.0/">
        	<header>
              <identifier>{lod:DC.identifier($model)}</identifier>
              <datestamp>{fn:current-dateTime()}</datestamp>
              <setSpec>{$model('docType')}</setSpec>
            </header>
            <metadata>
             <oai_dc:dc 
                 xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" 
                 xmlns:dc="http://purl.org/dc/elements/1.1/" 
                 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
                 xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd">
               <dc:title>{lod:page-title($model, $lang)}</dc:title>
               <dc:creator>{lod:DC.creator($model)}</dc:creator>
               <dc:subject>{lod:DC.subject($model, $lang)}</dc:subject>
               <dc:description>{lod:DC.description($model, $lang)}</dc:description>
               <dc:date>{substring($oai:last-modified,1,10)}</dc:date>
               <dc:identifier>{$docID}</dc:identifier>
             </oai_dc:dc>
            </metadata>
            <about> 
              <provenance
                  xmlns="http://www.openarchives.org/OAI/2.0/provenance" 
                  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
                  xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/provenance http://www.openarchives.org/OAI/2.0/provenance.xsd">
                <originDescription harvestDate="{fn:current-dateTime()}" altered="true">
                  <baseURL>{config:get-option('permaLinkPrefix')}</baseURL>
                  <identifier>{$docID}</identifier>
                  <datestamp>{substring($oai:last-modified,1,10)}</datestamp>
                  <metadataNamespace>http://www.openarchives.org/OAI/2.0/oai_dc/</metadataNamespace>
                </originDescription>
              </provenance>
            </about>
    	</record>      
};

let $lang := config:guess-language(())
let $docID := request:get-attribute('docID')
let $doc := crud:doc($docID)
let $model := 
    map { 
        'lang': $lang,
        'docID': $docID,
        'doc': $doc,
        'docType': config:get-doctype-by-id($docID)
    }
return
    (
        oai:response-headers(),
        response:set-status-code(202),
        oai:oai($model)
    )