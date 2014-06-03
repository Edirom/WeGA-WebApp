xquery version "3.0" encoding "UTF-8";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace response="http://exist-db.org/xquery/response";
(:declare namespace xmldb="http://exist-db.org/xquery/xmldb";:)
(:import module namespace wega="http://xquery.weber-gesamtausgabe.de/modules/wega" at "modules/wega.xqm";:)
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
(:import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "modules/lang.xqm";:)
import module namespace functx="http://www.functx.com";

let $exist.path := request:get-parameter('exist.path', '')
let $file.path := core:join-path-elements(($config:data-collection-path, $exist.path))
let $file.name := functx:substring-after-last($file.path, '/')
(:let $file.ext := functx:substring-after-last($file.name, '.'):)
let $content-type := 'application/xml'
let $log := util:log-system-out($file.path)
return 
    if(util:is-binary-doc($file.path)) then response:stream-binary(util:binary-doc($file.path), $content-type, $file.name)
    else if(doc-available($file.path)) then doc($file.path)
    (:else if(doc-available($file.path)) then response:stream(doc($file.path), 'method=xml media-type=application/xml indent=yes omit-xml-declaration=no encoding=utf-8'):)
    else error()