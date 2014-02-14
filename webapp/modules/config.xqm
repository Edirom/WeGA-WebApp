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

(: 
    Determine the application root collection from the current module load path.
:)
declare variable $config:app-root as xs:string := 
    let $rawPath := system:get-module-load-path()
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
declare variable $config:svn-change-history-file as document-node()? := 
    if(doc-available($config:catalogues-collection-path || '/svnChangeHistory.xml')) then doc($config:catalogues-collection-path || '/svnChangeHistory.xml')
    else ();
declare variable $config:data-collection-path as xs:string := '/db/apps/WeGA-data';
declare variable $config:tmp-collection-path as xs:string := $config:app-root || '/tmp';
declare variable $config:xsl-collection-path as xs:string := $config:app-root || '/xsl';

declare variable $config:isDevelopment as xs:boolean := config:get-option('environment') eq 'development';

declare variable $config:repo-descriptor as element(repo:meta) := doc(concat($config:app-root, "/repo.xml"))/repo:meta;

declare variable $config:expath-descriptor as element(expath:package)  := doc(concat($config:app-root, "/expath-pkg.xml"))/expath:package;

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

declare function config:app-meta($node as node(), $model as map(*)) as element()* {
    <meta xmlns="http://www.w3.org/1999/xhtml" name="description" content="{$config:repo-descriptor/repo:description/text()}"/>,
    for $author in $config:repo-descriptor/repo:author
    return
        <meta xmlns="http://www.w3.org/1999/xhtml" name="creator" content="{$author/text()}"/>
};

(:~
 : For debugging: generates a table showing all properties defined
 : in the application descriptors.
 :)
(:declare function config:app-info($node as node(), $model as map(*)) {
    let $expath := config:expath-descriptor()
    let $repo := config:repo-descriptor()
    return
        <table class="app-info">
            <tr>
                <td>app collection:</td>
                <td>{$config:app-root}</td>
            </tr>
            {
                for $attr in ($expath/@*, $expath/*, $repo/*)
                return
                    <tr>
                        <td>{node-name($attr)}:</td>
                        <td>{$attr/string()}</td>
                    </tr>
            }
            <tr>
                <td>Controller:</td>
                <td>{ request:get-attribute("$exist:controller") }</td>
            </tr>
        </table>
};:)

(:~
 :  Returns the requested option value from an option file given by the variable $wega:optionsFile
 :  
 : @author Peter Stadler
 : @param $key the key to look for in the options file
 : @return xs:string the option value as string identified by the key otherwise the empty string
 :)
declare function config:get-option($key as xs:string?) as xs:string {
    switch ($key)
        (: this serves as a shortcut for legacy code :)
        (: Please use core:link-to-current-app() directly! :)
        case 'baseHref' return core:link-to-current-app(())
        default return (
            let $dic := $config:options-file
            let $item := $dic//id($key)
            return normalize-space($item)
        )
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
    if(config:is-person($id)) then 'persons'
    else if(config:is-writing($id)) then 'writings'
    else if(config:is-work($id)) then 'works'
    else if(config:is-diary($id)) then 'diaries'
    else if(config:is-letter($id)) then 'letters'
    else if(config:is-news($id)) then 'news'
    else if(config:is-iconography($id)) then 'iconography'
    else if(config:is-var($id)) then 'var'
    else if(config:is-biblio($id)) then 'biblio'
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
    matches($docID, '^A00\d{4}$')
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
 : Checks whether a given document is from the series "Weber-Studien" published by the WeGA
 :
 : @author Peter Stadler
 : @param $docID the id to test as string
 : @return xs:boolean
:)
declare function config:is-weberStudies($doc as document-node()) as xs:boolean {
    $doc//tei:series/tei:title[@level = 's'] = 'Weber-Studien'
};

(:~
 : Checks whether a given string matches the defined types of bibliographic objects
 :
 : @author Peter Stadler
 : @param $string the string to test
 : @return xs:boolean
:)
declare function config:is-biblioType($string as xs:string) as xs:boolean {
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
        if(exists($docType)) then string-join(($config:data-collection-path, $docType, replace($docID, '\d{2}$', 'xx')), '/') 
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
    if($config:svn-change-history-file) then xmldb:last-modified($config:catalogues-collection-path, 'svnChangeHistory.xml')
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
 : Create parameters for xsl transformations 
 :
 : @author Peter Stadler
 : @return parameters
:)
declare function config:get-xsl-params($params as map()?) as element(parameters) {
    <parameters>
        <param name="lang" value="{session:get-attribute('lang')}"/>
        <param name="optionsFile" value="{$config:options-file-path}"/>
        <param name="baseHref" value="{core:link-to-current-app(())}"/>
        {if(exists($params)) then 
            for $i in map:keys($params)
            return 
                <param name="{$i}" value="{map:get($params, $i)}"/>
        else ()
        }
    </parameters>
};
