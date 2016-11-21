xquery version "3.0";

(:~
 : A set of helper functions to access the application context from
 : within a module.
 :)
module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config";

declare namespace repo="http://exist-db.org/xquery/repo";
declare namespace expath="http://expath.org/ns/pkg";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace functx="http://www.functx.com";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "str.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";
import module namespace norm="http://xquery.weber-gesamtausgabe.de/modules/norm" at "norm.xqm";
import module namespace wdt="http://xquery.weber-gesamtausgabe.de/modules/wdt" at "wdt.xqm";

(: 
    Determine the application root collection from the current module load path.
:)
declare variable $config:app-root as xs:string := 
    let $rawPath := replace(system:get-module-load-path(), '/null/', '//')
    let $modulePath :=
        (: strip the xmldb: part :)
        if (starts-with($rawPath, "xmldb:exist://")) then
            if (starts-with($rawPath, "xmldb:exist://embedded-eXist-server")) then
                substring($rawPath, 36)
            else
                substring($rawPath, 15)
        else
            $rawPath
    return
        substring-before($modulePath, "/modules")
;

declare variable $config:catalogues-collection-path as xs:string := $config:app-root || '/catalogues';
declare variable $config:options-file-path as xs:string := $config:catalogues-collection-path || '/options.xml';
declare variable $config:options-file as document-node() := doc($config:options-file-path);
declare variable $config:data-collection-path as xs:string := '/db/apps/WeGA-data';
declare variable $config:svn-change-history-file as document-node()? := 
    if(doc-available($config:data-collection-path || '/subversionHistory.xml')) then doc($config:data-collection-path || '/subversionHistory.xml')
    else ();
declare variable $config:tmp-collection-path as xs:string := $config:app-root || '/tmp';
declare variable $config:xsl-collection-path as xs:string := $config:app-root || '/xsl';
declare variable $config:smufl-decl-file-path as xs:string := $config:catalogues-collection-path || '/charDecl.xml';

declare variable $config:isDevelopment as xs:boolean := $config:options-file/id('environment') eq 'development';

declare variable $config:repo-descriptor as element(repo:meta) := doc(concat($config:app-root, "/repo.xml"))/repo:meta;

declare variable $config:expath-descriptor as element(expath:package)  := doc(concat($config:app-root, "/expath-pkg.xml"))/expath:package;

declare variable $config:valid-resource-suffixes as xs:string* := ('html', 'htm', 'json', 'xml', 'tei');

(: The first language is the default language :)
declare variable $config:valid-languages as xs:string* := ('de', 'en');

declare variable $config:default-entries-per-page as xs:int := 10; 


(: Temporarily suppressing internal links to persons, works etc. since those are not reliable :)
declare variable $config:diaryYearsToSuppress as xs:integer* := 
    if($config:isDevelopment) then () 
    else (1811 to 1816, 1821 to 1823);


(:~
 : Resolve the given path using the current application context.
 : If the app resides in the file system,
 :)
declare function config:resolve($relPath as xs:string) {
    if (starts-with($config:app-root, "/db")) then
        doc(concat($config:app-root, "/", $relPath))
    else
        doc(concat("file://", $config:app-root, "/", $relPath))
};

(:~
 : Returns the repo.xml descriptor for the current application.
 :)
declare function config:repo-descriptor() as element(repo:meta) {
    $config:repo-descriptor
};

(:~
 : Returns the expath-pkg.xml descriptor for the current application.
 :)
declare function config:expath-descriptor() as element(expath:package) {
    $config:expath-descriptor
};

declare %templates:wrap function config:app-title($node as node(), $model as map(*)) as text() {
    $config:expath-descriptor/expath:title/text()
};

(:~
 :  Returns the requested option value from an option file given by the variable $wega:optionsFile
 :  
 : @author Peter Stadler
 : @param $key the key to look for in the options file
 : @return xs:string the option value as string identified by the key otherwise the empty sequence
 :)
declare function config:get-option($key as xs:string?) as xs:string? {
    let $result :=
        switch ($key)
            (: this serves as a shortcut for legacy code :)
            (: Please use core:link-to-current-app() directly! :)
            case 'baseHref' return core:link-to-current-app(())
            default return str:normalize-space($config:options-file/id($key))
    return
        if($result) then $result
        else core:logToFile('warn', 'config:get-option(): unable to retrieve the key "' || $key || '"')
};

(:~
 : Get options from options file
 :
 : @author Peter Stadler
 : @param $key
 : @param $replacements
 : @return xs:string
 :)
declare function config:get-option($key as xs:string?, $replacements as xs:string*) as xs:string {
    let $dic := $config:options-file
    let $item := $dic//id($key)
    let $placeHolders := 
        for $i at $count in $replacements
        let $x := concat('%',$count)
        return $x
    return functx:replace-multi($item,$placeHolders,$replacements)
};

(:~
 : Gets document type by ID
 : Serves as a general validation service for our ID taxonomy
 :
 : @author Peter Stadler
 : @param $id 
 : @return xs:string document type
:)
declare function config:get-doctype-by-id($id as xs:string?) as xs:string? {
    for $func in $wdt:functions
    return 
        if($func($id)('check')() and $func($id)('prefix')) then $func($id)('name')
        else ()
};

declare function config:get-combined-doctype-by-id($id as xs:string?) as xs:string* {
    for $func in $wdt:functions
    return 
        if($func($id)('check')()) then $func($id)('name')
        else ()
};

(:~
 : Checks whether a given id matches the WeGA pattern of person ids
 :
 : @author Peter Stadler
 : @param $docID the id to test as string
 : @return xs:boolean
:)
declare function config:is-person($docID as xs:string?) as xs:boolean {
    matches($docID, '^A00[0-9A-F]{4}$')
};

(:~
 : Checks whether a given id matches the WeGA pattern of iconography ids
 :
 : @author Peter Stadler
 : @param $docID the id to test as string
 : @return xs:boolean
:)
declare function config:is-iconography($docID as xs:string?) as xs:boolean {
    matches($docID, '^A01\d{4}$')
};

(:~
 : Checks whether a given id matches the WeGA pattern of work ids
 :
 : @author Peter Stadler
 : @param $docID the id to test as string
 : @return xs:boolean
:)
declare function config:is-work($docID as xs:string?) as xs:boolean {
    matches($docID, '^A02\d{4}$')
};

(:~
 : Checks whether a given id matches the WeGA pattern of writing ids
 :
 : @author Peter Stadler
 : @param $docID the id to test as string
 : @return xs:boolean
:)
declare function config:is-writing($docID as xs:string?) as xs:boolean {
    matches($docID, '^A03\d{4}$')
};

(:~
 : Checks whether a given id matches the WeGA pattern of letter ids
 :
 : @author Peter Stadler
 : @param $docID the id to test as string
 : @return xs:boolean
:)
declare function config:is-letter($docID as xs:string?) as xs:boolean {
    matches($docID, '^A04\d{4}$')
};

(:~
 : Checks whether a given id matches the WeGA pattern of news ids
 :
 : @author Peter Stadler
 : @param $docID the id to test as string
 : @return xs:boolean
:)
declare function config:is-news($docID as xs:string?) as xs:boolean {
    matches($docID, '^A05\d{4}$')
};

(:~
 : Checks whether a given id matches the WeGA pattern of diary ids
 :
 : @author Peter Stadler
 : @param $docID the id to test as string
 : @return xs:boolean
:)
declare function config:is-diary($docID as xs:string?) as xs:boolean {
    matches($docID, '^A06\d{4}$')
};

(:~
 : Checks whether a given id matches the WeGA pattern of var ids
 :
 : @author Peter Stadler
 : @param $docID the id to test as string
 : @return xs:boolean
:)
declare function config:is-var($docID as xs:string?) as xs:boolean {
    matches($docID, '^A07\d{4}$')
};

(:~
 : Checks whether a given id matches the WeGA pattern of biblio ids
 :
 : @author Peter Stadler
 : @param $docID the id to test as string
 : @return xs:boolean
:)
declare function config:is-biblio($docID as xs:string?) as xs:boolean {
    matches($docID, '^A11\d{4}$')
};

(:~
 : Checks whether a given id matches the WeGA pattern of places ids
 :
 : @author Peter Stadler
 : @param $docID the id to test as string
 : @return xs:boolean
:)
declare function config:is-place($docID as xs:string?) as xs:boolean {
    matches($docID, '^A13\d{4}$')
};

(:~
 : Checks whether a given id matches the WeGA pattern of sources ids
 :
 : @author Peter Stadler
 : @param $docID the id to test as string
 : @return xs:boolean
:)
declare function config:is-source($docID as xs:string?) as xs:boolean {
    matches($docID, '^A22\d{4}$')
};

(:~
 : Checks whether a given id matches the WeGA pattern of org ids
 :
 : @author Peter Stadler
 : @param $docID the id to test as string
 : @return xs:boolean
:)
declare function config:is-org($docID as xs:string?) as xs:boolean {
    matches($docID, '^A08[0-9A-F]{4}$')
};

(:~
 : Checks whether a given document is from the series "Weber-Studien" published by the WeGA
 :
 : @author Peter Stadler
 : @param $docID the id to test as string
 : @return xs:boolean
:)
declare function config:is-weberStudies($doc as document-node()?) as xs:boolean {
    $doc//tei:series/tei:title[@level = 's'] = 'Weber-Studien'
};

(:~
 : Checks whether a given string matches the defined types of bibliographic objects
 :
 : @author Peter Stadler
 : @param $string the string to test
 : @return xs:boolean
:)
declare function config:is-biblioType($string as xs:string?) as xs:boolean {
    $string = ('mastersthesis', 'inbook', 'online', 'review', 'book', 'misc', 'inproceedings', 'article', 'score', 'incollection', 'phdthesis')
};

(:~
 : Checks the id for well-formedness and returns its collection path. Doesn't check for availability!
 :
 : @author Peter Stadler
 : @param $docID the id of the TEI document
 : @return xs:string the collection path of the document 
:)
declare function config:getCollectionPath($docID as xs:string) as xs:string? {
    let $docType := config:get-doctype-by-id($docID)
    return 
        if(exists($docType)) then str:join-path-elements(($config:data-collection-path, $docType, replace($docID, '[0-9A-F]{2}$', 'xx'))) 
        else ()
};

(:~
 : Returns whether WeGA-data was updated after a given dateTime. 
 : If $dateTime is not castable as xs:dateTime or $config:svn-change-history-file is not present it returns true().
 :
 : @author Peter Stadler
 : @param $dateTime the date to check
 : @return xs:boolean
:)
declare function config:eXistDbWasUpdatedAfterwards($dateTime as xs:dateTime?) as xs:boolean {
    if($dateTime castable as xs:dateTime) then config:getDateTimeOfLastDBUpdate() > ($dateTime cast as xs:dateTime)
    else true()
};

(:~
 : Retrieves the dateTime of last eXist-db update by checking svnChangeHistoryFile
 :
 : @author Peter Stadler
 : @return xs:dateTime
:)
declare function config:getDateTimeOfLastDBUpdate() as xs:dateTime? {
    if($config:svn-change-history-file) then xmldb:last-modified($config:data-collection-path, 'subversionHistory.xml')
    else ()
};

(:~
 : Returns the current head revision of the database as given by the 'svnChangeHistoryFile'
 :
 : @author Peter Stadler
 : @return xs:int
:)
declare function config:getCurrentSvnRev() as xs:int? {
    if($config:svn-change-history-file/dictionary/@head castable as xs:int) then $config:svn-change-history-file/dictionary/@head cast as xs:int
    else ()
};

(:~
 : Retrieves some subversion properties (latest revision, author, dateTime) for a given document ID
 :
 : @author Peter Stadler
 : @param $docID the document ID
 : @return map()
:)

declare function config:get-svn-props($docID as xs:string) as map() {
    map:new(
        for $prop in $config:svn-change-history-file//id($docID)/@*
        return map:entry(local-name($prop), data($prop))
    )
};


(:~
 : Create parameters for xsl transformations 
 :
 : @author Peter Stadler
 : @return parameters
:)
declare function config:get-xsl-params($params as map()?) as element(parameters) {
    <parameters>
        <param name="lang" value="{lang:get-set-language(())}"/>
        <param name="optionsFile" value="{$config:options-file-path}"/>
        <param name="baseHref" value="{core:link-to-current-app(())}"/>
        <param name="smufl-decl" value="{$config:smufl-decl-file-path}"/>
        <param name="data-collection-path" value="{$config:data-collection-path}"/>
        {if(exists($params)) then 
            for $i in map:keys($params)
            return 
                <param name="{$i}" value="{map:get($params, $i)}"/>
        else ()
        }
    </parameters>
};

declare function config:entries-per-page() as xs:int {
(:    Klappt irgendwie nicht?!? :)
    (:$config:default-entries-per-page:)
    10
};
