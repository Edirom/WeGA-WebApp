xquery version "3.0" encoding "UTF-8";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace compression="http://exist-db.org/xquery/compression";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace sm="http://exist-db.org/xquery/securitymanager";
import module namespace functx="http://www.functx.com";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace app="http://xquery.weber-gesamtausgabe.de/modules/app" at "app.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "str";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace wdt="http://xquery.weber-gesamtausgabe.de/modules/wdt" at "lang.xqm";

declare option exist:serialize "method=xml media-type=application/xml indent=yes omit-xml-declaration=no encoding=utf-8";

declare variable $local:languages := ('en', 'de');
declare variable $local:defaultCompression := 'gz'; (: gz or zip :)
declare variable $local:host := config:get-option('permaLinkPrefix');
declare variable $local:standardEntries := ('index', 'search', 'help', 'projectDescription', 'contact', 'editorialGuidelines'(:, 'publications':), 'bibliography');
declare variable $local:databaseEntries := for $func in wdt:members('sitemap') return $func(())('name');

declare function local:getUrlList($type as xs:string, $lang as xs:string) as element(url)* {
    for $x in core:getOrCreateColl($type, 'indices', true())
    (: In rare cases (when a file was deleted from a wrong folder and a file with the same name exists) there are two svn entries :)
    let $lastmod := max($config:svn-change-history-file//id($x/*/@xml:id)/string(@dateTime))
    let $loc := $local:host || app:createUrlForDoc($x, $lang)
    return 
        <url xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">{
            element loc {$loc},
            if(exists($lastmod)) then element lastmod {$lastmod}
            else ()
        }</url>
};

declare function local:createSitemap($lang as xs:string) as element(urlset) {
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        {for $i in $local:standardEntries return 
            <url><loc>{$local:host || str:join-path-elements(('/', $lang, replace(lang:get-language-string($i, $lang), '\s', '_')))}</loc></url>
        }
        {
        for $k in $local:databaseEntries return local:getUrlList($k, $lang)
        }
    </urlset>
};

declare function local:createSitemapIndex($fileNames as xs:string*) as element(sitemapindex) {
    <sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        {for $fileName in $fileNames
        return <sitemap><loc>{$local:host || str:join-path-elements(('/', config:get-option('html_sitemapDir'), $fileName))}</loc></sitemap>
        }
    </sitemapindex>
};

declare function local:getSetSitemap($fileName as xs:string) as xs:base64Binary {
    let $sitemapLang := substring-after(substring-before($fileName, '.'), '_')
    let $folderName := config:get-option('sitemapDir')
    let $currentDateTimeOfFile := 
        if(xmldb:collection-available($folderName)) then xmldb:last-modified($folderName, $fileName) 
        else local:createSitemapCollection($folderName) 
    let $updateNecessary := typeswitch($currentDateTimeOfFile) 
	   case xs:dateTime return config:eXistDbWasUpdatedAfterwards($currentDateTimeOfFile) or not(util:binary-doc-available(str:join-path-elements(($folderName, $fileName))))
	   default return true()
    return 
        if($updateNecessary) then (
            let $newSitemap := local:createSitemap($sitemapLang)
            let $logMessage := concat('Creating sitemap: ', $fileName)
            let $logToFile := core:logToFile('info', $logMessage)
            return 
                if(exists($newSitemap)) then (
                    let $compression := functx:substring-after-last($fileName, '.')
                    let $compressedData := local:compressXML($newSitemap, functx:substring-before-last($fileName, '.'), $compression)
                    let $storedData := xmldb:store($folderName, $fileName, $compressedData, local:getMimeType($compression))
                    return util:binary-doc($storedData)
                )
                else ()
        )
        else util:binary-doc(str:join-path-elements(($folderName, $fileName)))
};

declare function local:getMimeType($compression as xs:string) as xs:string? {
    if($compression eq 'zip') then 'application/zip' 
    else if($compression eq 'gz') then 'application/gzip'
    else ()
};

declare function local:createSitemapCollection($path as xs:string) as empty() {
    let $createCollection := 
        try { xmldb:create-collection(functx:substring-before-last($path, '/'), functx:substring-after-last($path, '/')) }
        catch * {core:logToFile('error', 'failed to create sitemap collection')}
    let $setPermissions :=
        if(xmldb:collection-available($path)) then (
            sm:chown(xs:anyURI($path), 'guest'),
            sm:chgrp(xs:anyURI($path), 'guest'),
            sm:chmod(xs:anyURI($path), sm:octal-to-mode('755'))
        )
        else ()
    return ()
};

declare function local:compressXML($xml as element(), $fileName as xs:string, $compression as xs:string) as xs:base64Binary? {
    if($compression eq 'zip') then compression:zip(<entry name="{$fileName}" type="xml" method="deflate">{$xml}</entry>, false())
    else if($compression eq 'gz') then (
        let $serializationParameters := ('method=xml', 'media-type=application/xml', 'indent=no', 'omit-xml-declaration=no', 'encoding=utf-8')
        return compression:gzip(util:string-to-binary(util:serialize($xml, $serializationParameters)))
    )
    else ()
};

let $resource := request:get-parameter('resource', '')
let $compression := if(ends-with($resource, 'zip')) then 'zip' else $local:defaultCompression
let $properFileNames := for $lang in $local:languages return concat('sitemap_', $lang, '.xml.', $compression)

return
    if($properFileNames = $resource) then response:stream-binary(local:getSetSitemap($resource), local:getMimeType($compression), $resource)
    else local:createSitemapIndex($properFileNames)
