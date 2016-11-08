xquery version "3.1" encoding "UTF-8";

(:~
 : Functions for collecting HTML metadata
~:)

module namespace html-meta="http://xquery.weber-gesamtausgabe.de/modules/html-meta";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace templates="http://exist-db.org/xquery/templates" at "/db/apps/shared-resources/content/templates.xql";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "str.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";
import module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date" at "date.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace wdt="http://xquery.weber-gesamtausgabe.de/modules/wdt" at "wdt.xqm";

declare 
    %templates:wrap
    %templates:default("lang", "en")
    function html-meta:metadata($node as node(), $model as map(*), $lang as xs:string) as map(*) {
        map {
            'meta-page-title' := html-meta:page-title($model, $lang),
            'DC.contributor' := query:contributors($model('doc')),
            'DC.creator' := html-meta:DC.creator($model),
            'DC.date' := html-meta:DC.date($model),
            'DC.identifier' := html-meta:DC.identifier($model),
            'DC.description' := html-meta:DC.description($model, $lang),
            'DC.subject' := html-meta:DC.subject($model, $lang),
            'DC.rights' := html-meta:DC.rights($model),
            'google-site-verification' := config:get-option('googleWebsiteMetatag'),
            'ms-site-verification' := config:get-option('microsoftBingWebsiteMetatag')
        }
};

(:~
 : Print all items from a sequence identified by $model($key)
~:)
declare function html-meta:each-meta($node as node(), $model as map(*), $key as xs:string) as element(meta)* {
    $model($key) ! element {name($node)} { $node/@*[not(name(.) = 'content')], attribute content {.} }
};

(:~
 : Helper function for creating the page description
~:)
declare %private function html-meta:DC.description($model as map(*), $lang as xs:string) as xs:string? {
    switch($model('docID'))
    case 'indices' return lang:get-language-string('metaDescriptionIndex-' || $model('docType'), $lang)
    case 'home' return lang:get-language-string('metaDescriptionIndex', $lang)
    case 'search' return lang:get-language-string('metaDescriptionSearch', $lang)
    default return
        switch($model('docType'))
        case 'persons' return 
            let $dates := concat(date:printDate($model('doc')//tei:birth/tei:date[1],$lang), '–', date:printDate($model('doc')//tei:death/tei:date[1],$lang))
            let $occupations := string-join($model('doc')//tei:occupation/normalize-space(), ', ')
            let $placesOfAction := string-join($model('doc')//tei:residence/normalize-space(), ', ')
            return concat(
                lang:get-language-string('bioInfoAbout', $lang), ' ', 
                str:printFornameSurname(query:title($model('docID'))),'. ',
                lang:get-language-string('pnd_dates', $lang), ': ', 
                $dates, '. ',
                lang:get-language-string('occupations', $lang), ': ',
                $occupations, '. ',
                lang:get-language-string('placesOfAction', $lang), ': ', 
                $placesOfAction
            )
        case 'letters' case 'writings' return str:normalize-space($model('doc')//tei:note[@type='summary'])
        case 'diaries' return str:shorten-text($model('doc')/tei:ab, 150)
        case 'news' case 'var' case 'thematicCommentaries' return str:shorten-text(string-join($model('doc')//tei:text//tei:p[not(starts-with(., 'Sorry'))], ' '), 150)
        case 'orgs' return wdt:orgs($model('doc'))('title')('txt') || ': ' || str:list($model('doc')//tei:state[tei:label='Art der Institution']/tei:desc, $lang, 0)
        default return core:logToFile('warn', 'Missing HTML meta description for ' || $model('docID') || ' – ' || $model('docType') || ' – ' || request:get-uri())
};

(:~
 : Helper function for creating the page title
~:)
declare %private function html-meta:page-title($model as map(*), $lang as xs:string) as xs:string? {
    switch($model('docID'))
    case 'indices' return 'Carl-Maria-von-Weber-Gesamtausgabe – ' || lang:get-language-string('metaTitleIndex-' || $model('docType'), $lang)
    case 'home' return lang:get-language-string('metaTitleIndex-home', $lang)
    case 'search' return lang:get-language-string('metaTitleIndex-search', $lang)
    default return  
        switch($model('docType'))
        case 'persons' return concat(str:printFornameSurname(query:title($model('docID'))), ' – ', lang:get-language-string('tabTitle_bio', $lang))
        case 'letters' case 'writings' case 'news' case 'var' case 'thematicCommentaries' return wdt:lookup($model('docType'), $model('doc'))('title')('txt')
        case 'diaries' return concat(query:get-authorName($model('doc')), ' – ', lang:get-language-string('diarySingleViewTitle', wdt:lookup($model('docType'), $model('doc'))('title')('txt'), $lang))
        case 'orgs' return query:title($model('docID')) || ' (' || str:list($model('doc')//tei:state[tei:label='Art der Institution']/tei:desc, $lang, 0) || ') – ' || lang:get-language-string('tabTitle_bioOrgs', $lang)
        default return core:logToFile('warn', 'Missing HTML page title for ' || $model('docID') || ' – ' || $model('docType') || ' – ' || request:get-uri())
};

(:~
 : Helper function for creating the page title
~:)
declare %private function html-meta:DC.subject($model as map(*), $lang as xs:string) as xs:string? {
    switch($model('docID'))
    case 'indices' return 'Index'
    case 'home' return 'Carl Maria von Weber; Digitale Edition; Gesamtausgabe; Collected Works; Digital Edition'
    case 'search' return lang:get-language-string('search', $lang)
    default return
        switch($model('docType'))
        case 'persons' return lang:get-language-string('bio', $lang)
        case 'letters' case 'thematicCommentaries' return lang:get-language-string($model('doc')//tei:text/@type, $lang)
        case 'writings' return 'Historic Newspaper; Writing'
        case 'diaries' return string-join((lang:get-language-string('diary', $lang), query:get-authorName($model('doc'))), '; ')
        case 'news' return string-join($model('doc')//tei:keywords/tei:term, '; ')
        case 'var' return 'Varia'
        case 'orgs' return lang:get-language-string('orgs', $lang)
        default return ()
};

(:~
 : Helper function for collecting licensing information
~:)
declare %private function html-meta:DC.rights($model as map(*)) as xs:anyURI {
    if($model('doc')//tei:licence/@target castable as xs:anyURI) then xs:anyURI($model('doc')//tei:licence/@target)
    else xs:anyURI('https://creativecommons.org/licenses/by/4.0/') 
};

(:~
 : Helper function for collecting creator information
~:)
declare %private function html-meta:DC.creator($model as map(*)) as xs:string? {
    if($model('docID') = ('indices', 'home', 'search')) then 'Carl-Maria-von-Weber-Gesamtausgabe'
    else if(config:get-doctype-by-id($model('docID'))) then map:get(config:get-svn-props($model('docID')), 'author')
    else ()
};

(:~
 : Helper function for collecting date information
~:)
declare %private function html-meta:DC.date($model as map(*)) as xs:string? {
    if($model('docID') = ('indices', 'home', 'search')) then string(config:getDateTimeOfLastDBUpdate())
    else if(config:get-doctype-by-id($model('docID')) and exists(config:get-svn-props($model('docID')))) then map:get(config:get-svn-props($model('docID')), 'dateTime')
    else ()
};

(:~
 : Helper function for collecting identifier information
~:)
declare %private function html-meta:DC.identifier($model as map(*)) as xs:string? {
    if($model('docID') = ('indices', 'search')) then request:get-url()
    else if($model('docID') = 'home') then 'http://weber-gesamtausgabe.de'
    else if(config:get-doctype-by-id($model('docID'))) then core:permalink($model('docID'))
    else ()
};
