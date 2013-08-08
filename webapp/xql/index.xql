xquery version "1.0" encoding "UTF-8";
declare default element namespace "http://www.w3.org/1999/xhtml"; 
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace cache="http://exist-db.org/xquery/cache";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";
declare namespace datetime="http://exist-db.org/xquery/datetime";
import module namespace wega="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/wega" at "xmldb:exist:///db/webapp/xql/modules/wega.xqm";
import module namespace xho="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/xho" at "xmldb:exist:///db/webapp/xql/modules/xho.xqm";
import module namespace ajax="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/ajax" at "xmldb:exist:///db/webapp/xql/modules/ajax.xqm";
import module namespace facets="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/facets" at "xmldb:exist:///db/webapp/xql/modules/facets.xqm";
import module namespace functx="http://www.functx.com" at "xmldb:exist:///db/webapp/xql/modules/functx.xqm";

declare option exist:serialize "method=xhtml media-type=text/html indent=no omit-xml-declaration=yes encoding=utf-8 doctype-public=-//W3C//DTD&#160;XHTML&#160;1.0&#160;Strict//EN doctype-system=http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd";

declare function local:createNewsTeaser($news as document-node(), $lang as xs:string) as element()* {
    let $newsTeaserDate := $news//tei:fileDesc//tei:date/xs:dateTime(@when)
    let $authorID := data($news//tei:titleStmt/tei:author[1]/@key)
    let $dateFormat := if ($lang = 'en')
        then '%A, %B %d, %Y'
        else '%A, %d. %B %Y'
    return (
    element span {
        attribute class {'newsTeaserDate'},
        wega:getLanguageString('websiteNews', wega:strftime($dateFormat, datetime:date-from-dateTime($newsTeaserDate), $lang), $lang)
    },
    element h2 {
        element a {
            attribute href {wega:createLinkToDoc($news, $lang)},
            attribute title {string($news//tei:title[@level='a'])},
            string($news//tei:title[@level='a'])
        }
    },
    element p {
        substring($news//tei:body, 1, 400),
        ' … ',
        element a{
            attribute href {wega:createLinkToDoc($news, $lang)},
            attribute title {wega:getLanguageString('more', $lang)},
            attribute class {'readOn'},
            concat('[', wega:getLanguageString('more', $lang), ']')
        }
    }
    )
};

declare function local:collectMetaData($lang as xs:string) as element(wega:metaData) {
    let $pageTitle := concat('Carl-Maria-von-Weber-Gesamtausgabe', ' – ', wega:getLanguageString('home', $lang)) 
    let $pageDescription := wega:getLanguageString('metaDescriptionIndex', $lang)
    let $commonMetaData := xho:collectCommonMetaData(())
    let $subject := string-join(('Carl Maria von Weber', 'Edition', 'Social Network', wega:getLanguageString('gesamtausgabe', $lang)), '; ')
    return 
    <wega:metaData>
        <title>{$pageTitle}</title>
        {$commonMetaData/*}
        <meta name="DC.title" content="{$pageTitle}"/>
        <meta name="description" content="{$pageDescription}" lang="{$lang}"/>
        <meta name="DC.description" content="{$pageDescription}"/>
        <meta name="DC.creator" content="Peter Stadler"/>
        <meta name="DC.date" content="{xmldb:last-modified(wega:getOption('tmpDir'), concat('todaysEventsFile_', $lang, '.xml'))}" scheme="DCTERMS.W3CDTF"/>
        <meta name="DC.subject" content="{$subject}"/>
        <meta name="DC.language" content="{$lang}" scheme="DCTERMS.RFC3066"/>
        <meta name="DC.rights" content="http://creativecommons.org/licenses/by-nc-sa/3.0/" scheme="DCTERMS.URI"/>
        <meta name="google-site-verification" content="{wega:getOption('googleWebsiteMetatag')}" />
        <meta name="msvalidate.01" content="{wega:getOption('microsoftBingWebsiteMetatag')}" />
    </wega:metaData>
};
 
let $lang := request:get-parameter('lang','')
let $withJS := if(request:get-parameter('js', 'true') eq 'true') then true() else false()
let $date := adjust-date-to-timezone(util:system-date(),())
let $startID := 'A002068'
let $xslParams := <parameters><param name="lang" value="{$lang}"/></parameters>

let $maxNews := xs:integer(wega:getOption('maxNews'))
let $minNews := xs:integer(wega:getOption('minNews'))
let $maxNewsDays := xs:integer(wega:getOption('maxNewsDays'))

let $newsTeaser := 
    let $newsColl :=    subsequence(facets:getOrCreateColl('news', 'indices', true())[days-from-duration($date - xs:date(.//tei:publicationStmt/tei:date/xs:dateTime(@when))) le $maxNewsDays], 1, $maxNews)
    let $newsColl :=    if(count($newsColl) lt $minNews) then subsequence(facets:getOrCreateColl('news', 'indices', true()), 1, $minNews)
                        else $newsColl 
    return
    (
        <h1>{wega:getLanguageString('news', $lang)}</h1>,
        for $news at $i in $newsColl  
        return (
            local:createNewsTeaser($news, $lang),
            if($i ne count($newsColl)) then <hr class="news-teaser-break"/>
            else ()
        )
    )

let $domLoaded := 
    if($withJS) then
    <domLoaded xmlns="">
        <function>
            <name>requestTodaysEvents</name>
            <param>{$date}</param>
            <param>{$lang}</param>
        </function>
    </domLoaded>
    else()
return

<html>
    {xho:createHtmlHead('index.css', 'index_functions.js', local:collectMetaData($lang), $domLoaded, ())}
    <body>
        <div id="container">
            {xho:createHeadContainer($lang)}
            <div id="main">
                <div id="contentLeft">
                   {transform:transform(doc("/db/var/A0700xx/A070005.xml")//tei:text//tei:div[@xml:lang=$lang][1], doc("/db/webapp/xsl/var.xsl"), $xslParams)}
                   <div id="newsTeaser">{$newsTeaser}</div>
                </div>
                <div id="contentRight">
                    {xho:printEditionLinks($startID, $lang),
                    xho:printProjectLinks($lang),
                    if(wega:getOption('environment') eq 'development') then xho:printDevelopmentLinks($lang) else ()}
                    <div>
                        <h1>{wega:getLanguageString('whatHappenedOn', wega:strftime(if($lang eq 'en') then '%B %d' else '%d. %B', $date, $lang), $lang)}</h1>
                        <div id="todaysEvents">
                            {if(not($withJS)) then ajax:getTodaysEvents($date,$lang) else ()}
                            <!-- (: wird onload gefüllt :) -->
                        </div>
                    </div>
                </div>
            </div>
            {xho:createFooter()}         
        </div>
    </body>
</html>
