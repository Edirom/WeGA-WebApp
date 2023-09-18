xquery version "3.1" encoding "UTF-8";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace compression="http://exist-db.org/xquery/compression";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace sitemap="http://xquery.weber-gesamtausgabe.de/modules/sitemap";

import module namespace functx="http://www.functx.com";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace controller="http://xquery.weber-gesamtausgabe.de/modules/controller" at "controller.xqm";
import module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util" at "wega-util.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/str.xqm";
import module namespace mycache="http://xquery.weber-gesamtausgabe.de/modules/cache" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/cache.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace wdt="http://xquery.weber-gesamtausgabe.de/modules/wdt" at "wdt.xqm";

declare option output:method "xml";
declare option output:media-type "application/xml";
declare option output:indent "yes";

declare variable $sitemap:languages := ('en', 'de');
declare variable $sitemap:defaultCompression := 'gz'; (: gz or zip :)
declare variable $sitemap:host := config:get-option('permaLinkPrefix');
declare variable $sitemap:standardEntries := ('index', 'search', 'help', 'projectDescription', 'contact', 'editorialGuidelines'(:, 'publications':), 'bibliography', 'specialVolume', 'volContents', 'team');
declare variable $sitemap:databaseEntries := for $func in wdt:members('sitemap') return $func(())('name');

declare function sitemap:getUrlList($type as xs:string, $lang as xs:string) as element(url)* {
    for $x in core:getOrCreateColl($type, 'indices', true())
    (: In rare cases (when a file was deleted from a wrong folder and a file with the same name exists) there are two svn entries :)
    let $lastmod := max($config:svn-change-history-file//id($x/*/@xml:id)/string(@dateTime))
    let $loc := $sitemap:host || controller:create-url-for-doc($x, $lang)
    return 
        <url xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">{
            element loc {$loc},
            if(exists($lastmod)) then element lastmod {$lastmod}
            else ()
        }</url>
};

declare function sitemap:createSitemap($lang as xs:string) as element(urlset) {
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        {for $i in $sitemap:standardEntries return 
            <url><loc>{$sitemap:host || str:join-path-elements(('/', $lang, replace(lang:get-language-string($i, $lang), '\s', '_')))}</loc></url>
        }
        {
        for $k in $sitemap:databaseEntries return sitemap:getUrlList($k, $lang)
        }
    </urlset>
};

declare function sitemap:createSitemapIndex($fileNames as xs:string*) as element(sitemapindex) {
    <sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        {for $fileName in $fileNames
        return <sitemap><loc>{$sitemap:host || str:join-path-elements(('/', config:get-option('html_sitemapDir'), $fileName))}</loc></sitemap>
        }
    </sitemapindex>
};

declare function sitemap:getSetSitemap($fileName as xs:string) as xs:base64Binary {
    let $sitemapLang := substring-after(substring-before($fileName, '.'), '_')
    let $lease := function($dateTimeOfCache) as xs:boolean {
        config:eXistDbWasUpdatedAfterwards($dateTimeOfCache) and $useCache
    }
    let $onFailure := function($errCode as item(), $errDesc as item()?) {
        wega-util:log-to-file('error', concat($errCode, ': ', $errDesc))
    }
    let $callback := function($sitemapLang as xs:string, $fileName as xs:string) as xs:base64Binary? {
        sitemap:createSitemap($sitemapLang) => sitemap:compressXML(functx:substring-before-last($fileName, '.'), functx:substring-after-last($fileName, '.'))
    }
    return 
        mycache:doc(str:join-path-elements(($config:tmp-collection-path, 'sitemap', $fileName)), $callback, ($sitemapLang, $fileName), $lease, $onFailure)
        (:if($updateNecessary) then (
            let $newSitemap := sitemap:createSitemap($sitemapLang)
            let $logMessage := concat('Creating sitemap: ', $fileName)
            let $logToFile := wega-util:log-to-file('info', $logMessage)
            return 
                if(exists($newSitemap)) then (
                    let $compression := functx:substring-after-last($fileName, '.')
                    let $compressedData := sitemap:compressXML($newSitemap, functx:substring-before-last($fileName, '.'), $compression)
                    let $storedData := xmldb:store($folderName, $fileName, $compressedData, sitemap:getMimeType($compression))
                    return util:binary-doc($storedData)
                )
                else ()
        )
        else util:binary-doc(str:join-path-elements(($folderName, $fileName))):)
};

declare function sitemap:getMimeType($compression as xs:string) as xs:string? {
    if($compression eq 'zip') then 'application/zip' 
    else if($compression eq 'gz') then 'application/gzip'
    else ()
};

declare function sitemap:compressXML($xml as element(), $fileName as xs:string, $compression as xs:string) as xs:base64Binary? {
    if($compression eq 'zip') then compression:zip(<entry name="{$fileName}" type="xml" method="deflate">{$xml}</entry>, false())
    else if($compression eq 'gz') then (
        let $serializationParameters := <output:serialization-parameters><output:method>xml</output:method><output:media-type>application/xml</output:media-type><output:indent>no</output:indent></output:serialization-parameters>
        return compression:gzip(util:string-to-binary(serialize($xml, $serializationParameters)))
    )
    else ()
};

let $resource := request:get-parameter('resource', '')
let $compression := if(ends-with($resource, 'zip')) then 'zip' else $sitemap:defaultCompression
let $properFileNames := for $lang in $sitemap:languages return concat('sitemap_', $lang, '.xml.', $compression)

return
    if($properFileNames = $resource) then response:stream-binary(sitemap:getSetSitemap($resource), sitemap:getMimeType($compression), $resource)
    else sitemap:createSitemapIndex($properFileNames)
