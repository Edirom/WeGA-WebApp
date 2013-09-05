xquery version "1.0" encoding "UTF-8";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace compression="http://exist-db.org/xquery/compression";
declare namespace response="http://exist-db.org/xquery/response";
import module namespace wega = "http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/wega" at "xmldb:exist:///db/webapp/xql/modules/wega.xqm";
import module namespace functx="http://www.functx.com" at "xmldb:exist:///db/webapp/xql/modules/functx.xqm";
import module namespace facets="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/facets" at "xmldb:exist:///db/webapp/xql/modules/facets.xqm";

declare option exist:serialize "method=xml media-type=application/xml indent=yes omit-xml-declaration=no encoding=utf-8";

declare variable $local:languages := ('en', 'de');
declare variable $local:standardEntries := ('index', 'search', 'help', 'projectDescription', 'contact', 'editorialGuidelines'(:, 'publications':), 'bibliography');
declare variable $local:databaseEntries := ('persons', 'letters', 'writings', 'diaries', (:'works',:) 'news'(:, 'biblio':));

declare function local:getUrlList($type as xs:string, $lang as xs:string) as element(url)* {
    for $x in facets:getOrCreateColl($type, 'indices', true())
    let $lastmod := wega:getLastModifyDateOfDocument(document-uri($x))
    let $loc := wega:createLinkToDoc($x, $lang) 
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
            <url><loc>{string-join((wega:getOption('baseHref'), $lang, replace(wega:getLanguageString($i, $lang), '\s', '_')), '/')}</loc></url>
        }
        {for $k in $local:databaseEntries return local:getUrlList($k, $lang)}
    </urlset>
};

declare function local:createSitemapIndex($fileNames as xs:string*) as element(sitemapindex) {
    <sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        {for $fileName in $fileNames
        return <sitemap><loc>{string-join((wega:getOption('baseHref'), wega:getOption('html_sitemapDir'), $fileName), '/')}</loc></sitemap>
        }
    </sitemapindex>
};

declare function local:getSetSitemap($fileName as xs:string) as xs:base64Binary {
    let $sitemapLang := substring-after(substring-before($fileName, '.'), '_')
    let $folderName := wega:getOption('sitemapDir')
    let $currentDateTimeOfFile := 
        if(xmldb:collection-available($folderName)) then xmldb:last-modified($folderName, $fileName) 
        else (xmldb:create-collection(functx:substring-before-last($folderName, '/'), functx:substring-after-last($folderName, '/')), xmldb:set-collection-permissions($folderName, 'guest', 'guest', 493)) 
    let $updateNecessary := typeswitch($currentDateTimeOfFile) 
	   case xs:dateTime return wega:eXistDbWasUpdatedAfterwards($currentDateTimeOfFile)
	   default return true()
    return 
        if($updateNecessary) then (
            let $newSitemap := local:createSitemap($sitemapLang)
            let $logMessage := concat('Creating sitemap: ', $fileName)
            let $logToFile := wega:logToFile('info', $logMessage)
            return 
                if(exists($newSitemap)) then (
                    let $serializationParameters := ('method=xml', 'media-type=application/xml', 'indent=no', 'omit-xml-declaration=no', 'encoding=utf-8')
                    let $zip := compression:zip(<entry name="{functx:substring-before-last($fileName, '.')}" type="xml" method="deflate">{$newSitemap}</entry>, false())
(:                    let $compressedData := compression:gzip(util:string-to-binary(util:serialize($newSitemap, $serializationParameters))):)
                    let $storedData := xmldb:store($folderName, $fileName, $zip, 'application/zip')
                        (:xmldb:store($folderName, $fileName, $compressedData, 'application/gzip'):) 
                    return util:binary-doc($storedData)
                )
                else ()
        )
        else util:binary-doc(string-join(($folderName, $fileName), '/'))
};

let $appLang := request:get-parameter('lang', 'de')
let $resource := request:get-parameter('resource', '')
let $host := request:get-parameter('host', wega:getOption('baseHref'))
let $properFileNames := for $lang in $local:languages return concat('sitemap_', $lang, '.xml.zip')

return
    if($properFileNames = $resource) then response:stream-binary(local:getSetSitemap($resource), 'application/zip', $resource)
    else local:createSitemapIndex($properFileNames)
