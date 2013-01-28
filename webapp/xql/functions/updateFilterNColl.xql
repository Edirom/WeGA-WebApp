xquery version "1.0" encoding "UTF-8";
declare default collation "?lang=de;strength=primary";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace cache="http://exist-db.org/xquery/cache";
declare namespace util="http://exist-db.org/xquery/util";
import module namespace wega="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/wega" at "xmldb:exist:///db/webapp/xql/modules/wega.xqm";
import module namespace facets="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/facets" at "xmldb:exist:///db/webapp/xql/modules/facets.xqm";

declare option exist:serialize "method=xhtml media-type=text/html indent=no omit-xml-declaration=yes encoding=utf-8";

let $docType := request:get-parameter('docType',())
let $cacheKey := request:get-parameter('cacheKey',())
let $sessionFilterName := facets:getFilterName($docType)
let $checked := request:get-parameter('checked', ())
let $sessionCollName := facets:getCollName($docType, false())
let $filter := facets:createFilter($checked)
(:let $log := util:log-system-out($filter):)
let $collOrg := facets:getOrCreateColl($docType, $cacheKey)
let $collNew := (:$collOrg:) facets:updateColl($collOrg, $filter)
(:let $log := util:log-system-out(concat('updateFilterNColl: ', count($collNew))):)
let $storeSessionAttributes := (session:set-attribute($sessionCollName, $collNew), session:set-attribute($sessionFilterName, $filter))  
return count(session:get-attribute($sessionCollName))