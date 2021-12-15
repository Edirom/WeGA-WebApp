xquery version "3.1" encoding "UTF-8";

(:~
 : Functions for collecting HTML metadata
~:)

module namespace lod="http://xquery.weber-gesamtausgabe.de/modules/lod";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace map="http://www.w3.org/2005/xpath-functions/map";

import module namespace templates="http://exist-db.org/xquery/html-templating";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util" at "wega-util.xqm";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace controller="http://xquery.weber-gesamtausgabe.de/modules/controller" at "controller.xqm";
import module namespace wdt="http://xquery.weber-gesamtausgabe.de/modules/wdt" at "wdt.xqm";
import module namespace gl="http://xquery.weber-gesamtausgabe.de/modules/gl" at "gl.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/str.xqm";
import module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/date.xqm";

declare 
    %templates:wrap
    %templates:default("lang", "en")
    function lod:metadata($node as node(), $model as map(*), $lang as xs:string) as map(*) {
        map {
            'meta-page-title' : lod:page-title($model, $lang),
            'DC.contributor' : if($model?specID or $model?schemaID) then query:contributors($gl:main-source) else query:contributors($model('doc')),
            'DC.creator' : lod:DC.creator($model),
            'DC.date' : lod:DC.date($model),
            'DC.identifier' : lod:DC.identifier($model),
            'DC.description' : lod:DC.description($model, $lang),
            'DC.subject' : lod:DC.subject($model, $lang),
            'DC.rights' : query:licence($model?doc),
            'google-site-verification' : config:get-option('googleWebsiteMetatag'),
            'ms-site-verification' : config:get-option('microsoftBingWebsiteMetatag'),
            'jsonld-metadata' : lod:jsonld($model, $lang)
        }
};

(:~
 : Print all items from a sequence identified by $model($key)
~:)
declare function lod:each-meta($node as node(), $model as map(*), $key as xs:string) as element(meta)* {
    $model($key) ! element {node-name($node)} { $node/@*[not(name(.) = 'content')], attribute content {.} }
};

declare 
    %templates:default("lang", "en") 
    function lod:hreflang($node as node(), $model as map(*), $lang as xs:string) as element()* {
        for $l in $config:valid-languages 
        return
            element { node-name($node) } { 
                $node/@*,
                attribute href {
                    if($l eq $lang) then config:get-option('permaLinkPrefix') || request:get-uri()
                    else config:get-option('permaLinkPrefix') || controller:translate-URI(request:get-uri(), $lang, $l)
                },
                attribute hreflang {$l}
            }
};

(:~
 : Collect information about a resource for outputting as JSON-LD
 :)
declare function lod:jsonld($model as map(*), $lang as xs:string) as map(*) {
    let $schema.org-type := lod:schema.org-type($model)
    let $identifier := lod:DC.identifier($model)
    let $url := 
        (: multiple URLs are generated when the document features multiple authors :)
        if($model?doc) then controller:path-to-resource($model?doc, $lang) ! config:permalink(.)
        else $identifier
    let $jsonld-common := map {
        '@id': $identifier,
        '@type': $schema.org-type,
        '@context': 'http://schema.org',
        'url': $url,
        'name': 
            if($schema.org-type = ('Person', 'Organization', 'Place')) then wdt:lookup(config:get-doctype-by-id($model?docID), $model?doc)('title')('txt')
            else lod:page-title($model, $lang),
        'description': lod:DC.description($model, $lang)
    }
    let $publisher := map {
        'name':'Carl-Maria-von-Weber-Gesamtausgabe',
        'url':'http://weber-gesamtausgabe.de',
        '@type':'Organization'
    }
    let $funder := map {
        'name':'Akademie der Wissenschaften und der Literatur, Mainz',
        'url':'http://adwmainz.de',
        '@type':'Organization'
    }
    let $mentions := () 
        (: too expensive with present implementation! :)
        (:array {
            distinct-values(($model?doc//tei:text//tei:*[@key] | $model?doc/tei:ab//tei:*[@key])/@key) ! lod:jsonld-entity(<tei:rs key="{.}"/>, $lang)
        }:)
    let $homepageSpecials := 
        if($model?docID = 'home') then map { 
            'image': config:permalink('resources/img/logo_weber.png'),
            'logo': config:permalink('resources/favicons/mstile-150x150.png'),
            "potentialAction": array { 
                map {
                    "@type": "SearchAction",
                    "target": config:permalink('de/Suche?q={search_term_string}'),
                    "query-input": "required name=search_term_string"
                }
            }
        }
        else ()
    return
        map:merge((
            $jsonld-common, (: always included :)
            
            $homepageSpecials, (: specials for the landing page :)
            
            if($schema.org-type = ('CreativeWork', 'Article', 'NewsArticle')) then map:merge((
                $jsonld-common,
                map {'funder': $funder},
                map {'publisher': $publisher},
                map {'license': query:licence($model?doc)},
                map {'author': array { $model?doc//tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:author ! lod:jsonld-entity(., $lang) }},
                if(count($mentions) gt 0) then map {'mentions': $mentions} else ()
            )) 
            else if($schema.org-type = ('Person', 'Organization', 'Place')) then 
                if(query:get-gnd($model?doc)) then 
                    map {'sameAs': config:get-option('dnb') || query:get-gnd($model?doc) }
                else ()
            else ()
        ))
};

(:~
 : Helper function for setting a schema.org type
 :)
declare %private function lod:schema.org-type($model as map(*)) as xs:string {
    if($model?docID = 'home') 
    then 'WebSite' 
    else 
        switch(config:get-doctype-by-id($model?docID))
        case 'news' return 'NewsArticle'
        case 'persons' return 'Person'
        case 'orgs' return 'Organization'
        case 'places' return 'Place'
        case 'addenda' case 'thematicCommentary' return 'Article'
        default return 'CreativeWork'
};

(:~
 : Helper function for outputting entity information
 :)
declare %private function lod:jsonld-entity($elem as element(), $lang as xs:string) as map(*)* {
    typeswitch($elem)
    case element(tei:rs) return tokenize(normalize-space($elem/@key), '\s') ! lod:jsonld-entity(<tei:name key="{.}"/>, $lang) 
    default return
        map:merge((
            map {
                'name': if($elem/@key) then query:title($elem/@key) else str:normalize-space($elem),
                '@type': 
                    if($elem/@key) then lod:schema.org-type(map { 'docID': $elem/@key })
                    else if($elem/self::tei:orgName or $elem/self::tei:rs[@type='org']) then 'Organization'
                    else if($elem/self::tei:persName or $elem/self::tei:author or $elem/self::tei:rs[@type='person']) then 'Person'
                    else if($elem/self::tei:settlement or $elem/self::tei:placeName or $elem/self::tei:region or $elem/self::tei:country or $elem/self::tei:rs[@type='place']) then 'Place'
                    else wega-util:log-to-file('debug',  'Failed to infer schema.org type for ' || serialize($elem))
            },
            if($elem/@key) then map {
                '@id': config:permalink($elem/@key),
                'url': config:permalink($lang || '/' || $elem/@key)
            }
            else (),
            if(query:get-gnd($elem/@key)) then map {
                'sameAs': config:get-option('dnb') || query:get-gnd($elem/@key)
            }
            else ()
        ))
};


(:~
 : Helper function for creating the page description
~:)
declare %private function lod:DC.description($model as map(*), $lang as xs:string) as xs:string? {
    if($model?specID) then lang:get-language-string('metaDescriptionGuidelinesSpecs', ($model?specID), $lang)
    else if($model?chapID) then 
        switch($model?chapID)
        case 'toc' return lang:get-language-string('toc', $lang)
        case 'index-elements' case 'index-attributes' case 'index-classes' case 'index-datatypes' return lang:get-language-string('metaDescriptionGuidelines-' || $model?chapID, $lang)
        default return str:shorten-TEI(gl:chapter($model?chapID)//tei:p, 150, $lang) 
    else 
        switch($model('docID'))
        case 'indices' return lang:get-language-string('metaDescriptionIndex-' || $model('docType'), $lang)
        case 'home' return lang:get-language-string('metaDescriptionIndex', $lang)
        case 'search' return lang:get-language-string('metaDescriptionSearch', $lang)
        default return
            switch($model('docType'))
            case 'persons' return 
                let $dates := concat(date:printDate($model('doc')//tei:birth/tei:date[1],$lang,lang:get-language-string#3, $config:default-date-picture-string), '–', date:printDate($model('doc')//tei:death/tei:date[1],$lang,lang:get-language-string#3, $config:default-date-picture-string))
                let $occupations := string-join($model('doc')//tei:occupation/normalize-space(), ', ')
                let $placesOfAction := string-join($model('doc')//tei:residence/normalize-space(), ', ')
                return concat(
                    lang:get-language-string('bioInfoAbout', $lang), ' ', 
                    str:print-forename-surname(query:title($model('docID'))),'. ',
                    lang:get-language-string('pnd_dates', $lang), ': ', 
                    $dates, '. ',
                    lang:get-language-string('occupations', $lang), ': ',
                    $occupations, '. ',
                    lang:get-language-string('placesOfAction', $lang), ': ', 
                    $placesOfAction
                )
            case 'letters' case 'writings' case 'documents' return str:normalize-space($model('doc')//tei:note[@type='summary'])
            case 'diaries' return str:shorten-TEI($model('doc')/tei:ab, 150, $lang)
            case 'news' case 'var' case 'thematicCommentaries' return str:shorten-TEI($model('doc')//tei:text//tei:p[not(starts-with(., 'Sorry'))], 150, $lang)
            case 'orgs' return wdt:orgs($model('doc'))('title')('txt') || ': ' || str:list($model('doc')//tei:state[tei:label='Art der Institution']/tei:desc, $lang, 0, lang:get-language-string#2)
            case 'places' return lang:get-language-string('place', $lang)
            case 'works' return lang:get-language-string('workName', $lang)
            case 'addenda' return lang:get-language-string($model?docType, $lang)
            case 'error' return lang:get-language-string('metaDescriptionError', $lang)
            default return wega-util:log-to-file('warn', 'Missing HTML meta description for ' || $model('docID') || ' – ' || $model('docType') || ' – ' || request:get-uri())
};

(:~
 : Helper function for creating the page title
~:)
declare %private function lod:page-title($model as map(*), $lang as xs:string) as xs:string? {
    if($model?specID) then lang:get-language-string('metaTitleGuidelinesSpecs', ($model?specID, $model?schemaID), $lang)
    else if($model?chapID) then 
        switch($model?chapID)
        case 'toc' return lang:get-language-string('editorialGuidelines-text', $lang)
        case 'index-elements' case 'index-attributes' case 'index-classes' case 'index-datatypes' return lang:get-language-string('metaTitleGuidelines-' || $model?chapID, $lang)
        default return gl:chapter-heading(<a/>, $model)
    else
        switch($model('docID'))
        case 'indices' return 'Carl-Maria-von-Weber-Gesamtausgabe – ' || lang:get-language-string('metaTitleIndex-' || $model('docType'), $lang)
        case 'home' return lang:get-language-string('metaTitleIndex-home', $lang)
        case 'search' return lang:get-language-string('metaTitleIndex-search', $lang)
        default return  
            switch($model('docType'))
            case 'persons' return concat(str:print-forename-surname(query:title($model('docID'))), ' – ', lang:get-language-string('tabTitle_bio', $lang))
            case 'letters' case 'writings' case 'news' case 'var' case 'thematicCommentaries' case 'documents' case 'places' case 'works' case 'addenda' return wdt:lookup($model('docType'), $model('doc'))('title')('txt')
            case 'diaries' return concat(query:get-authorName($model('doc')), ' – ', lang:get-language-string('diarySingleViewTitle', wdt:lookup($model('docType'), $model('doc'))('title')('txt'), $lang))
            case 'orgs' return query:title($model('docID')) || ' (' || str:list($model('doc')//tei:state[tei:label='Art der Institution']/tei:desc, $lang, 0, lang:get-language-string#2) || ') – ' || lang:get-language-string('tabTitle_bioOrgs', $lang)
            case 'error' return lang:get-language-string('metaTitleError', $lang)
            default return wega-util:log-to-file('warn', 'Missing HTML page title for ' || $model('docID') || ' – ' || $model('docType') || ' – ' || request:get-uri())
};

(:~
 : Helper function for creating the page title
~:)
declare %private function lod:DC.subject($model as map(*), $lang as xs:string) as xs:string? {
    if($model?specID or $model?chapID) then 'Guidelines; Encoding'
    else 
        switch($model('docID'))
        case 'indices' return 'Index'
        case 'home' return 'Carl Maria von Weber; Digitale Edition; Gesamtausgabe; Collected Works; Digital Edition'
        case 'search' return lang:get-language-string('search', $lang)
        default return
            switch($model('docType'))
            case 'persons' return lang:get-language-string('bio', $lang)
            case 'letters' case 'thematicCommentaries' case 'documents' return lang:get-language-string($model('doc')//tei:text/@type, $lang)
            case 'writings' return 'Historic Newspaper; Writing'
            case 'diaries' return string-join((lang:get-language-string('diary', $lang), query:get-authorName($model('doc'))), '; ')
            case 'news' return string-join($model('doc')//tei:keywords/tei:term, '; ')
            case 'var' return 'Varia'
            case 'orgs' case 'works' case 'addenda' return lang:get-language-string($model?docType, $lang)
            case 'places' return 'Geographica'
            default return ()
};

(:~
 : Helper function for collecting creator information
~:)
declare %private function lod:DC.creator($model as map(*)) as xs:string? {
    if($model('docID') = ('indices', 'home', 'search')) then 'Carl-Maria-von-Weber-Gesamtausgabe'
    else if($model?specID or $model?chapID) then 'Carl-Maria-von-Weber-Gesamtausgabe'
    else if(config:get-doctype-by-id($model('docID'))) then map:get(config:get-svn-props($model('docID')), 'author')
    else ()
};

(:~
 : Helper function for collecting date information
~:)
declare %private function lod:DC.date($model as map(*)) as xs:string? {
    if($model('docID') = ('indices', 'home', 'search')) then string(config:getDateTimeOfLastDBUpdate())
    else if($model?specID or $model?chapID) then string(config:getDateTimeOfLastDBUpdate())
    else if(config:get-doctype-by-id($model('docID')) and exists(config:get-svn-props($model('docID')))) then map:get(config:get-svn-props($model('docID')), 'dateTime')
    else ()
};

(:~
 : Helper function for collecting identifier information
~:)
declare %private function lod:DC.identifier($model as map(*)) as xs:string? {
    if($model('docID') = ('indices', 'search')) then request:get-url()
    else if($model('docID') = 'home') then 'http://weber-gesamtausgabe.de'
    else if($model?specID or $model?chapID) then request:get-url()
    else if(config:get-doctype-by-id($model('docID'))) then config:permalink($model('docID'))
    else ()
};
