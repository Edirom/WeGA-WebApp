xquery version "3.0" encoding "UTF-8";

(:
 : XQuery functions for integration with oXygen editor
:)

declare default collation "?lang=de;strength=primary";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace request="http://exist-db.org/xquery/request";
import module namespace norm="http://xquery.weber-gesamtausgabe.de/modules/norm" at "../norm.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "../config.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "../core.xqm";
import module namespace wega="http://xquery.weber-gesamtausgabe.de/modules/wega" at "../wega.xqm";
import module namespace dev="http://xquery.weber-gesamtausgabe.de/modules/dev" at "dev.xqm";
(:import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";:)
(:import module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date" at "date.xqm";:)
(:import module namespace wega="http://xquery.weber-gesamtausgabe.de/modules/wega" at "wega.xqm";:)
(:declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "html5";
declare option output:media-type "text/html";:)


declare function local:list($docType as xs:string) as element(ul){
let $register := norm:get-norm-doc($docType)//norm:entry
let $li-wrap := function($entry as element(norm:entry)) as element(li) {
    <li id="{$entry/data(@docID)}">
        <span>{
            if($docType = ('persons', 'places')) then string($entry)
            else wega:getRegTitle($entry/@docID)
        }</span>
    </li>
}
return 
    <ul>{
        map($li-wrap, $register)
    }</ul>
};

declare function local:id($docType as xs:string) as element(ul){
    let $id := dev:createNewID($docType)
    return 
    <ul>
        <li id="{$id}"><span>{$id}</span></li>
    </ul>
};

let $params := request:get-parameter-names()
return 
    if(count($params) ne 1) then error()
    else if($params = 'persons') then local:list($params)
    else if($params = 'works') then local:list($params)
    else if($params = 'places') then local:list($params)
    else if($params = 'persID') then local:id('persons')
    else if($params = 'letterID') then local:id('letters')
    else if($params = 'writingsID') then local:id('writings')
    else error()
