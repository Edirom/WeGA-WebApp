xquery version "1.0" encoding "UTF-8";
declare default element namespace "http://www.w3.org/1999/xhtml"; 
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace cache="http://exist-db.org/xquery/cache";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace datetime="http://exist-db.org/xquery/datetime" at "java:org.exist.xquery.modules.datetime.DateTimeModule";
import module namespace wega="http://xquery.weber-gesamtausgabe.de/modules/wega" at "wega.xqm";
import module namespace xho="http://xquery.weber-gesamtausgabe.de/modules/xho" at "xho.xqm";
import module namespace ajax="http://xquery.weber-gesamtausgabe.de/modules/ajax" at "ajax.xqm";
import module namespace facets="http://xquery.weber-gesamtausgabe.de/modules/facets" at "facets.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace functx="http://www.functx.com";

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
        lang:get-language-string('websiteNews', wega:strftime($dateFormat, datetime:date-from-dateTime($newsTeaserDate), $lang), $lang)
    },
    element h2 {
        element a {
            attribute href {wega:createLinkToDoc($news, $lang)},
            attribute title {string($news//tei:title[@level='a'])},
            string($news//tei:title[@level='a'])
        }
    },
    element p {
        wega:printPreview(string($news//tei:body), 400),
        ' ',
        element a{
            attribute href {wega:createLinkToDoc($news, $lang)},
            attribute title {lang:get-language-string('more', $lang)},
            attribute class {'readOn'},
            concat('[', lang:get-language-string('more', $lang), ']')
        }
    }
    )
};

declare function local:collectMetaData($lang as xs:string) as element(wega:metaData) {
    let $pageTitle := concat('Carl-Maria-von-Weber-Gesamtausgabe', ' – ', lang:get-language-string('home', $lang)) 
    let $pageDescription := lang:get-language-string('metaDescriptionIndex', $lang)
    let $commonMetaData := xho:collectCommonMetaData(())
    let $subject := string-join(('Carl Maria von Weber', 'Edition', 'Social Network', lang:get-language-string('gesamtausgabe', $lang)), '; ')
    return 
    <wega:metaData>
        <title>{$pageTitle}</title>
        {$commonMetaData/*}
        <meta name="DC.title" content="{$pageTitle}"/>
        <meta name="description" content="{$pageDescription}" lang="{$lang}"/>
        <meta name="DC.description" content="{$pageDescription}"/>
        <meta name="DC.creator" content="Peter Stadler"/>
        <meta name="DC.date" content="{current-dateTime()}" scheme="DCTERMS.W3CDTF"/>
        <meta name="DC.subject" content="{$subject}"/>
        <meta name="DC.language" content="{$lang}" scheme="DCTERMS.RFC3066"/>
        <meta name="DC.rights" content="http://creativecommons.org/licenses/by-nc-sa/3.0/" scheme="DCTERMS.URI"/>
        <meta name="google-site-verification" content="{config:get-option('googleWebsiteMetatag')}" />
        <meta name="msvalidate.01" content="{config:get-option('microsoftBingWebsiteMetatag')}" />
    </wega:metaData>
};
 
let $lang := request:get-parameter('lang','')
let $withJS := if(request:get-parameter('js', 'true') eq 'true') then true() else false()
let $date := adjust-date-to-timezone(util:system-date(),())
let $startID := 'A002068'
let $xslParams := config:get-xsl-params(())

let $maxNews := xs:integer(config:get-option('maxNews'))
let $minNews := xs:integer(config:get-option('minNews'))
let $maxNewsDays := xs:integer(config:get-option('maxNewsDays'))

let $newsTeaser := 
    let $newsColl :=    subsequence(core:getOrCreateColl('news', 'indices', true())[days-from-duration($date - xs:date(.//tei:publicationStmt/tei:date/xs:dateTime(@when))) le $maxNewsDays], 1, $maxNews)
    let $newsColl :=    if(count($newsColl) lt $minNews) then subsequence(core:getOrCreateColl('news', 'indices', true()), 1, $minNews)
                        else $newsColl 
    return
    (
        <h1>{lang:get-language-string('news', $lang)}</h1>,
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
                   {transform:transform(core:doc('A070005')//tei:text//tei:div[@xml:lang=$lang][1], doc(concat($config:xsl-collection-path, "/var.xsl")), $xslParams)}
                   <div id="newsTeaser">{$newsTeaser}</div>
                </div>
                <div id="contentRight">
                    {xho:printEditionLinks($startID, $lang),
                    xho:printProjectLinks($lang),
                    if($config:isDevelopment) then xho:printDevelopmentLinks($lang) else ()}
                    <div>
                        <h1>{lang:get-language-string('whatHappenedOn', wega:strftime(if($lang eq 'en') then '%B %d' else '%d. %B', $date, $lang), $lang)}</h1>
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
