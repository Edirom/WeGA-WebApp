xquery version "3.1" encoding "UTF-8";

(:~
: XQuery functions for fetching and manipulating images
:
: @author Peter Stadler 
:)

module namespace img="http://xquery.weber-gesamtausgabe.de/modules/img";
declare default collation "?lang=de;strength=primary";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace wd="http://www.wikidata.org/prop/direct/";
declare namespace rdfs="http://www.w3.org/2000/01/rdf-schema#";
declare namespace dbp="http://dbpedia.org/property/";
declare namespace dbo="http://dbpedia.org/ontology/";
declare namespace foaf="http://xmlns.com/foaf/0.1/";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace wega="http://www.weber-gesamtausgabe.de";
declare namespace templates="http://exist-db.org/xquery/templates";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";
import module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util" at "wega-util.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "str.xqm";
import module namespace wdt="http://xquery.weber-gesamtausgabe.de/modules/wdt" at "wdt.xqm";
import module namespace controller="http://xquery.weber-gesamtausgabe.de/modules/controller" at "controller.xqm";
(:import module namespace image="http://exist-db.org/xquery/image" at "java:org.exist.xquery.modules.image.ImageModule";:)
import module namespace cache="http://xquery.weber-gesamtausgabe.de/modules/cache" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/cache.xqm";
import module namespace functx="http://www.functx.com";

(:
Person portraits
thumb = x52
small = x60
large = x340
:)


(:~
 : Main function for creating a map of all images (from various sources)
 : for a given person.
~:)
declare 
    %templates:default("lang", "en")
    %templates:wrap
    function img:iconography($node as node(), $model as map(*), $lang as xs:string) as map(*)? {
        let $docType := config:get-doctype-by-id($model?docID)
        let $func := 
            try { function-lookup(xs:QName('img:iconography4' || $docType), 3) } 
            catch * { core:logToFile('error', 'Failed to lookup iconography-function for ' || $docType ) }
        return 
            if(exists($func)) then $func($node, $model, $lang)
            else core:logToFile('debug', 'Missing iconography-function for ' || $docType )
};

(:~
 : Helper function for img:iconography()
 : Creates the iconography for persons
 :
~:)
declare %private function img:iconography4persons($node as node(), $model as map(*), $lang as xs:string) as map(*) {
    let $local-image := img:wega-images($model, $lang)
    let $suppressWikipediaPortrait := core:getOrCreateColl('iconography', $model('docID'), true())//tei:figure[not(tei:graphic)]
    let $beaconMap := (: when loaded via AJAX there's no beaconMap in $model :)
        if(exists($model('beaconMap'))) then $model('beaconMap')
        else try { 
            wega-util:beacon-map(query:get-gnd($model('doc')), config:get-doctype-by-id($model('docID')))
            }
            catch * { map:new() } 
    let $portraitindex-images := 
        if(count(map:keys($beaconMap)[contains(., 'Portraitindex')]) gt 0) then img:portraitindex-images($model, $lang)
        else ()
    let $wikipedia-images := 
        if(not($suppressWikipediaPortrait) and count(map:keys($beaconMap)[contains(., 'Wikipedia-Personenartikel')]) gt 0) then img:wikipedia-images($model, $lang)
        else ()
    let $tripota-images := 
        if(count(map:keys($beaconMap)[contains(., 'GND-Zuordnung')]) gt 0) then img:tripota-images($model, $lang)
        else ()
    let $munich-stadtmuseum-images := 
        if(count(map:keys($beaconMap)[contains(., 'Porträtsammlung')]) gt 0) then img:munich-stadtmuseum-images($model, $lang)
        else ()
    let $iconographyImages := ($local-image, $wikipedia-images, $portraitindex-images, $tripota-images, $munich-stadtmuseum-images)
    let $portrait := ($iconographyImages, img:get-generic-portrait($model, $lang))[1]
    return
        map { 
            'iconographyImages' := $iconographyImages,
            'portrait' := $portrait
        }
};

(:~
 : Helper function for img:iconography()
 : Creates the iconography for places
 :
~:)
declare %private function img:iconography4places($node as node(), $model as map(*), $lang as xs:string) as map(*) {
    let $dbpedia-images := img:dbpedia-images($model, $lang)
    let $coa := 
        for $map in $dbpedia-images 
        return 
            if($map?coa) then $map 
            else ()
    return
        map { 
                'iconographyImages' := $dbpedia-images,
                'portrait' := ($coa, $dbpedia-images, img:get-generic-portrait($model, $lang))[1]
            }
};

(:~
 : Helper function for img:iconography()
 : Creates the iconography for organizations
 :
~:)
declare %private function img:iconography4orgs($node as node(), $model as map(*), $lang as xs:string) as map(*) {
    img:iconography4persons($node, $model, $lang)
};

(:~
 : Helper function for img:iconography()
 : Creates the iconography for works
 :
~:)
declare %private function img:iconography4works($node as node(), $model as map(*), $lang as xs:string) as map(*) {
    let $beaconMap := (: when loaded via AJAX there's no beaconMap in $model :)
        if(exists($model('beaconMap'))) then $model('beaconMap')
        else try { wega-util:beacon-map(query:get-gnd($model('doc')), config:get-doctype-by-id($model('docID'))) } catch * { map:new() }
    let $db := map:keys($beaconMap)[contains(., 'Korrespondierendes Wikidata-Item')]
    let $dbpedia-images := $db ! img:dbpedia-images(map:put($model, 'dbpediaID', analyze-string(.,'Q\d+')/fn:match/text()), $lang)
    return 
    map { 
        'iconographyImages' := $dbpedia-images,
        'portrait' := ( $dbpedia-images, img:get-generic-portrait($model, $lang) )[1]
    }
};


(:~
 : Function for outputting an image from the iconography
 :
 : @return an HTML element <a> with a nested <img>
~:)
declare function img:iconographyImage($node as node(), $model as map(*)) as element(a) {
    <a href="{$model('iconographyImage')('linkTarget')}"><img title="{$model('iconographyImage')('caption')}" alt="{$model('iconographyImage')('caption')}" src="{$model('iconographyImage')('url')('thumb')}"/></a>
};

(:~
 : Helper function for grabbing images from a dbpedia rdf 
 :
 : @author Peter Stadler 
 : @param $model a map with all necessary variables, e.g. docID
 : @param $lang the language variable (de|en)
 :)
declare %private function img:dbpedia-images($model as map(*), $lang as xs:string) as map(*)* {
    let $docType := config:get-doctype-by-id($model?docID)
    let $id := 
        switch($docType)
        case 'places' return $model('doc')//tei:idno[@type='geonames']
        case 'works' return $model?dbpediaID
        default return ()
    let $dbpedia-rdf := 
        if($id) then 
            switch($docType)
            case 'places' return wega-util:dbpedia-from-geonames($id)
            case 'works' return wega-util:grabExternalResource('dbpedia', $id, $docType, $lang)
            default return ()
        else ()
    let $wikiFilenames := 
        distinct-values((
            $dbpedia-rdf//dbp:imageCoa/text(), 
            $dbpedia-rdf//dbp:imageFlag/text(), 
            $dbpedia-rdf//dbp:imagePlan/text(), 
            $dbpedia-rdf//dbp:image/text(), 
            (
                $dbpedia-rdf//dbo:thumbnail[@rdf:resource] |
                $dbpedia-rdf//foaf:depiction[@rdf:resource] |
                $dbpedia-rdf//wd:P18[@rdf:resource]
            ) ! functx:substring-before-if-contains(substring-after(xmldb:decode(./@rdf:resource), 'Special:FilePath/'), '?')
        ))[.] (: prevent the empty string :)
    (: see https://www.mediawiki.org/wiki/API:Imageinfo :)
    let $wikiApiRequestURL := "https://commons.wikimedia.org/w/api.php?action=query&amp;format=xml&amp;prop=imageinfo&amp;iiurlheight=52&amp;iiprop=url%7Csize&amp;titles=" || encode-for-uri(string-join($wikiFilenames ! ('File:' || replace(., '\s|%20', '_')), '|'))
    let $lease := function($currentDateTimeOfFile as xs:dateTime?) as xs:boolean { wega-util:check-if-update-necessary($currentDateTimeOfFile, ()) }
    let $onFailureFunc := function($errCode, $errDesc) {
        core:logToFile('warn', string-join(($errCode, $errDesc), ' ;; '))
    }
    let $wikiApiResponse := 
        if(count($wikiFilenames) gt 0) then cache:doc(str:join-path-elements(($config:tmp-collection-path, 'wikiAPI', $id || '.xml')), wega-util:http-get#1, xs:anyURI($wikiApiRequestURL), $lease, $onFailureFunc)
        else ()
    return
        for $page in $wikiApiResponse//page[not(@missing)]
        let $caption := $page/data(@title)
        let $linkTarget := $page//ii/data(@descriptionurl)
        return 
            map {
                    'caption' := normalize-space(concat($caption,' (', lang:get-language-string('sourceWikipedia', $lang), ')')),
                    'linkTarget' := $linkTarget,
                    'source' := 'Wikimedia',
                    'url' := function($size) {
                        let $iiifInfo := wega-util:wikimedia-iiif($page/data(@title))
                        return
                            switch($size)
                            case 'thumb' case 'small' return 
                                $page//ii/data(@thumburl)
                            case 'large' return
                                if($page//ii/@height > 340) then replace($page//ii/data(@thumburl), '/\d+px\-', '/340px-')
                                else $page//ii/data(@url)
                            default return 
                                $page//ii/data(@url)
                    },
                    'coa' := 'File:' || $dbpedia-rdf//dbp:imageCoa/replace(., '\s', '_') = replace($caption, '\s', '_') (: should return true() for the coat of arms :)
                }
};

(:~
 : Helper function for grabbing images from a wikipedia article 
 :
 : @author Peter Stadler 
 : @param 
 : @param $lang the language variable (de|en)
 : @return 
 :)
declare %private function img:wikipedia-images($model as map(*), $lang as xs:string) as map(*)* {
    let $gnd := query:get-gnd($model('doc'))
    let $wikiArticle := 
        if($gnd) then wega-util:grabExternalResource('wikipedia', $gnd, config:get-doctype-by-id($model('docID')), $lang)
        else ()
    (: Look for images in wikipedia infobox (for organizations and english wikipedia) and thumbnails  :)
    let $pics := $wikiArticle//xhtml:table[contains(@class,'vcard')] | $wikiArticle//xhtml:table[contains(@class,'toptextcells')] | $wikiArticle//xhtml:div[@class='thumbinner']
    let $errorLog := if(count($pics) = 0) then core:logToFile('info', 'img:wikipedia-images(): no images found for GND ' || $gnd) else ()
    return 
        for $div in $pics
        let $tmpPicURI := ($div//xhtml:img[@class='thumbimage']/@src | $div[self::xhtml:table]//xhtml:img[not(@class='thumbimage')]/@src)[1]
        let $thumbURI := (: Achtung: in $pics landen auch andere Medien, z.B. audio. Diese erzeugen dann aber ein leeres $tmpPicURI, da natürlich kein <img/> vorhanden :)
            if(starts-with($tmpPicURI, '//')) then concat('https:', $tmpPicURI) 
            else if(starts-with($tmpPicURI, 'http')) then $tmpPicURI
            else ()
        let $tmpLinkTarget := ($div/xhtml:a/@href | $div[self::xhtml:table]//xhtml:a[xhtml:img]/@href)[1]
        let $linkTarget := 
            (: Create a link to Wikipedia, e.g. https://de.wikipedia.org/wiki/Datei:Constanze_mozart.jpg :)
            (: NB, not all images are found at wikimedia commons due to copyright issues :)
            switch($lang) 
            case 'de' return functx:substring-before-if-contains(replace($tmpLinkTarget, '.+:', 'https://de.wikipedia.org/wiki/Datei:'), '&amp;')
            default return functx:substring-before-if-contains(replace($tmpLinkTarget, '.+:', 'https://en.wikipedia.org/wiki/File:'), '&amp;')
        (:  Wikimedia IIIF
            siehe https://groups.google.com/forum/?hl=en#!topic/iiif-discuss/UTD181dxKtU
            https://github.com/Toollabs/zoomviewer
        :)
        let $caption := 
            if($div[self::xhtml:table]) then ($div/xhtml:tr[.//xhtml:img]/preceding::xhtml:tr)[1] 
            else $div/xhtml:div[@class='thumbcaption']
        return 
            if($thumbURI castable as xs:anyURI) then
                map {
                    'caption' := normalize-space(concat($caption,' (', lang:get-language-string('sourceWikipedia', $lang), ')')),
                    'linkTarget' := $linkTarget,
                    'source' := 'Wikimedia',
                    'url' := function($size) {
                        switch($size)
                        case 'thumb' case 'small' return $thumbURI
                        case 'large' return 
                           let $iiifInfo := wega-util:wikimedia-iiif(functx:substring-after-last($linkTarget, ':'))
                           return
                              try {
                                 if($iiifInfo('height') > 340) then $iiifInfo('@id') || '/full/,340/0/native.jpg'
                                 else $iiifInfo('@id') || '/full/full/0/native.jpg'
                              }
                              catch * { $thumbURI }
                        default return 
                           let $iiifInfo := wega-util:wikimedia-iiif(functx:substring-after-last($linkTarget, ':'))
                           return
                              try { $iiifInfo('@id') || '/full/full/0/native.jpg' }
                              catch * { $thumbURI }
                    }
                }
            else ()
};

(:~
 : Helper function for grabbing images from a portraitindex page
 :
 : @author Peter Stadler 
 : @param 
 : @param $lang the language variable (de|en)
 : @return 
 :)
declare %private function img:portraitindex-images($model as map(*), $lang as xs:string) as map(*)* {
    let $gnd := query:get-gnd($model('doc'))
    let $page := 
        if($gnd) then wega-util:grabExternalResource('portraitindex', $gnd, config:get-doctype-by-id($model('docID')), $lang)
        else ()
    let $pics := $page//xhtml:div[@class='listItemThumbnail']
    let $errorLog := if(count($pics) = 0) then core:logToFile('info', 'img:portraitindex-images(): no images found for GND ' || $gnd) else ()
    return 
        for $div in $pics
        let $picURI := $div//xhtml:img/data(@src)
        return 
            if($picURI castable as xs:anyURI) then
                map {
                    'caption' := normalize-space($div/following-sibling::xhtml:p/xhtml:a) || ', ' || replace(normalize-space(string-join($div/following-sibling::xhtml:p/text(), ' ')), '&#65533;', ' ') || ' (Quelle: Digitaler Portraitindex)',
                    'linkTarget' := $div/xhtml:a/data(@href),
                    'source' := 'Digitaler Portraitindex',
                    'url' := function($size) {
                        $picURI
                    }
                }
            else ()
};

(:~
 : Helper function for grabbing images from a tripota page
 :
 : @author Peter Stadler 
 : @param 
 : @param $lang the language variable (de|en)
 : @return 
 :)
declare %private function img:tripota-images($model as map(*), $lang as xs:string) as map(*)* {
    let $gnd := query:get-gnd($model('doc'))
    let $page := 
        if($gnd) then wega-util:grabExternalResource('tripota', $gnd, config:get-doctype-by-id($model('docID')), $lang)
        else ()
    let $pics := $page//xhtml:td
    let $errorLog := if(count($pics) = 0) then core:logToFile('info', 'img:tripota-images(): no images found for GND ' || $gnd) else ()
    return 
        for $div in $pics
        let $picURI := concat('http://www.tripota.uni-trier.de/',  $div//xhtml:img[starts-with(@src, 'portraits')]/data(@src))
        return 
            if($picURI castable as xs:anyURI) then
                map {
                    'caption' := normalize-space(string-join($div/xhtml:br[2]/following-sibling::node(), ' ')) || ' (Quelle: Trierer Porträtdatenbank)',
                    'linkTarget' := 'http://www.tripota.uni-trier.de/' || $div/xhtml:a[1]/data(@href),
                    'source' := 'Trierer Porträtdatenbank',
                    'url' := function($size) {
                        $picURI
                    }
                }
            else ()
};

(:~
 : Helper function for grabbing images from the Münchner Stadtmuseum
 :
 : @author Peter Stadler 
 : @param 
 : @param $lang the language variable (de|en)
 : @return 
 :)
declare %private function img:munich-stadtmuseum-images($model as map(*), $lang as xs:string) as map(*)* {
    let $gnd := query:get-gnd($model('doc'))
    let $page := 
        if($gnd) then wega-util:grabExternalResource('munich-stadtmuseum', $gnd, config:get-doctype-by-id($model('docID')), $lang)
        else ()
    let $pics := $page//xhtml:a[@class='imagelink'][ancestor::xhtml:div[@id='main']]
    let $errorLog := if(count($pics) = 0) then core:logToFile('info', 'img:munich-stadtmuseum-images(): no images found for GND ' || $gnd) else ()
    return 
        for $a in $pics
        let $picURI := concat('https://stadtmuseum.bayerische-landesbibliothek-online.de', $a/xhtml:img/@src)
        return 
            if($picURI castable as xs:anyURI) then
                map {
                    'caption' := str:normalize-space($a/xhtml:img/@title) || ' (Quelle: Münchner Stadtmuseum)',
                    'linkTarget' := 'https://stadtmuseum.bayerische-landesbibliothek-online.de/pnd/' || $gnd,
                    'source' := 'Münchner Stadtmuseum',
                    'url' := function($size) {
                        $picURI
                    }
                }
            else ()
};

(:~
 : Helper function for adding local (= from the WeGA) images
 :
 : @author Peter Stadler 
 : @param 
 : @param $lang the language variable (de|en)
 : @return 
 :)
declare %private function img:wega-images($model as map(*), $lang as xs:string) as map(*)* {
    let $iiifImageApi := config:get-option('iiifImageApi')
    return
        for $fig in core:getOrCreateColl('iconography', $model('docID'), true())//tei:figure[tei:graphic]
        let $iiifURI := $iiifImageApi || encode-for-uri(string-join(('persons', substring($model('docID'), 1, 5) || 'xx', $model('docID'), $fig/tei:graphic/@url), '/'))
        order by $fig/@n (: markup with <figure n="portrait"> takes precedence  :)
        return 
            map {
                'caption' := normalize-space($fig/preceding::tei:title),
                'linkTarget' := $iiifURI || '/full/full/0/native.jpg',
                'source' := wega-util:transform($fig//tei:bibl, doc(concat($config:xsl-collection-path, '/persons.xsl')), config:get-xsl-params(())),
                'url' := function($size) {
                    switch($size)
                    case 'thumb' return $iiifURI || '/full/,52/0/native.jpg'
                    case 'small' return $iiifURI || '/full/,60/0/native.jpg'
                    case 'large' return $iiifURI || '/full/,340/0/native.jpg'
                    default return $iiifURI || '/full/full/0/native.jpg'
                }
            }
};

(:
http://192.168.3.104:9091/digilib2.3.3/Scaler/IIIF/letters%2FA0412xx%2FA041234%2F1817-07-10_05_AM_Weber_an_Caroline_D-B_1r.tif/1023,1023,1006,1023/,256/0/native.jpg
http://weber-gesamtausgabe.de/digilib/servlet/Scaler?fn=persons/A0020xx/A002068/weber_bardua.jpg&dh=195&mo=q2
http://weber-gesamtausgabe.de/digilib/Scaler/IIIF/letters%2FA0412xx%2FA041234%2F1817-07-10_05_AM_Weber_an_Caroline_D-B_1r.tif/1023,1023,1006,1023/,256/0/native.jpg
http://192.168.3.104:9091/digilib2.3.3/Scaler/IIIF/persons%2FA0020xx%2FA002068%2Fweber_bardua.jpg/0/0/0/native.jpg
https://tools.wmflabs.org/zoomviewer/iiif.php?f=Adam_of_Wurttemberg_by_D.Bossi.jpg
http://tools.wmflabs.org/zoomviewer/iipsrv.fcgi/?iiif=cache/63ba02c8870af5888cd78aebf971b3f9.tif/full/,340/0/native.jpg
http://tools.wmflabs.org/zoomviewer/iipsrv.fcgi/?iiif=cache/63ba02c8870af5888cd78aebf971b3f9.tif
:)


declare 
    %templates:default("lang", "en")
    function img:portrait($node as node(), $model as map(*), $lang as xs:string, $size as xs:string) as element() {
        if(exists($model?portrait)) then 
            let $url := $model('portrait')('url')($size)
            return
                element {node-name($node)} {
                    $node/@*[not(local-name(.) = ('src', 'title', 'alt'))],
                    attribute title {$model('portrait')('caption')},
                    attribute alt {$model('portrait')('caption')},
                    attribute src {$url}
                }
        else $node
};

declare %private function img:get-generic-portrait($model as map(*), $lang as xs:string) as map(*) {
    let $sex := 
        if(config:is-org($model('docID'))) then 'org'
        else if(config:is-place($model('docID'))) then 'place'
        else if($model('doc')//mei:term/data(@classcode) = 'http://d-nb.info/standards/elementset/gnd#MusicalWork') then 'musicalWork'
        else if(config:is-work($model('docID')) and not($model('doc')//mei:term/data(@classcode) = 'http://d-nb.info/standards/elementset/gnd#MusicalWork')) then 'otherWork'
        else $model('doc')//tei:sex/text()
    return
        map {
            'caption' := 'no portrait available',
            'linkTarget' := (),
            'source' := 'Carl-Maria-von-Weber-Gesamtausgabe',
            'url' := function($size) {
                switch($size)
                case 'thumb' case 'small' return 
                    switch($sex)
                    case 'f' return core:link-to-current-app('resources/img/icons/icon_person_frau.png')
                    case 'm' return core:link-to-current-app('resources/img/icons/icon_person_mann.png')
                    case 'org' return core:link-to-current-app('resources/img/icons/icon_orgs.png')
                    case 'place' return core:link-to-current-app('resources/img/icons/icon_places.png')
                    case 'musicalWork' return core:link-to-current-app('resources/img/icons/icon_musicalWorks.png')
                    case 'otherWork' return core:link-to-current-app('resources/img/icons/icon_works.png')
                    default return core:link-to-current-app('resources/img/icons/icon_persons.png')
                default return 
                    switch($sex)
                    case 'f' return core:link-to-current-app('resources/img/icons/icon_person_frau_gross.png')
                    case 'm' return core:link-to-current-app('resources/img/icons/icon_person_mann_gross.png')
                    case 'org' return core:link-to-current-app('resources/img/icons/icon_orgs_gross.png')
                    case 'place' return core:link-to-current-app('resources/img/icons/icon_places_gross.png')
                    case 'musicalWork' return core:link-to-current-app('resources/img/icons/icon_musicalWorks_gross.png')
                    case 'otherWork' return core:link-to-current-app('resources/img/icons/icon_works_gross.png')
                    default return core:link-to-current-app('resources/img/icons/icon_person_unbekannt_gross.png')
            }
        }
};

(:declare function img:iiif-collection() as map(*) {
    map {
        "@context" := "http://iiif.io/api/presentation/2/context.json",
        "@id" := "https://weber-gesamtausgabe.de/IIIF/letters",
        "@type" := "sc:Collection",
        "label" := "Top Level Letters Collection for the Carl-Maria-von-Weber-Gesamtausgabe",
        "viewingHint" := "top",
        "description" := "Description of Collection kommt später",
        "attribution" := "Provided by the WeGA",
        "manifests" := array {
            img:iiif-manifest(core:doc('A040709')//tei:facsimile),
            img:iiif-manifest(core:doc('A040695')//tei:facsimile)
        }
    }
};
:)
(:~
 : Create an IIIF manifest for a TEI facsimile element
 :
 : @param $facsimile a TEI facsimile element
 : @return a manifest object
 :)
declare function img:iiif-manifest($facsimile as element(tei:facsimile)) as map(*) {
    let $iiifImageApi := config:get-option('iiifImageApi')
    let $docID := $facsimile/ancestor::tei:TEI/@xml:id
    let $manifest-id := controller:iiif-manifest-id($facsimile)
    let $label := config:get-doctype-by-id($docID) || ' ' || $docID
    let $desc := wdt:lookup(config:get-doctype-by-id($docID), $docID)('title')('txt')
    let $attribution := img:iiif-manifest-attribution($facsimile)
    return
        map {
            "@context":= "http://iiif.io/api/presentation/2/context.json",
            "@id":= $manifest-id,
            "@type" := "sc:Manifest", 
            "label":= $label,
            "description" := $desc,
            "attribution" := $attribution,
            "license" := query:licence($facsimile/root()),
            "logo" := map {
                "@id" := "https://weber-gesamtausgabe.de/resources/img/logo_weber.png",
                "service" := map {
                    "@context": "http://iiif.io/api/image/2/context.json",
                    "@id": "https://weber-gesamtausgabe.de/resources/img/logo_weber.png",
                    "profile": "http://iiif.io/api/image/2/level2.json"
                }
            },
            "sequences" := [ map {
                "@context" := "http://iiif.io/api/presentation/2/context.json",
                "@id":= replace($manifest-id, 'manifest.json', 'sequence/') || 'default',
                "@type" := "sc:Sequence", 
                "label" := "default",
                "viewingHint": "paged",
                "canvases" := array {
                    $facsimile/tei:graphic ! img:iiif-canvas(.)
                }
            }]
        }
};

(:~
 : Create an IIIF canvas for a TEI graphic element
 :
 : @param $graphic a TEI graphic element
 : @return a canvas object
 :)
declare function img:iiif-canvas($graphic as element(tei:graphic)) as map(*) {
    let $docID := $graphic/ancestor::tei:TEI/@xml:id
    let $iiifImageApi := config:get-option('iiifImageApi')
    let $db-path := substring-after(config:getCollectionPath($docID), $config:data-collection-path || '/')
    let $image-id := $iiifImageApi || encode-for-uri(str:join-path-elements(($db-path, $docID, $graphic/@url)))
    let $page-label := 
        if($graphic/@xml:id) then $graphic/string(@xml:id)
        else 'page' || count($graphic/preceding::tei:graphic) + 1
    let $manifest-id := controller:iiif-manifest-id($graphic/parent::tei:facsimile)
    let $canvas-id := replace($manifest-id, 'manifest.json', 'canvas/') || encode-for-uri($page-label)
    let $image-info :=  parse-json(util:base64-decode(wega-util:http-get(xs:anyURI($image-id))//*:response))
    return 
        map:new((
            map:entry("@context", "http://iiif.io/api/presentation/2/context.json"),
            map:entry("@id", $canvas-id),
            map:entry("@type", "sc:Canvas"),
            map:entry("label", $page-label),
            map:entry("height", xs:integer($image-info?height)),
            map:entry("width", xs:integer($image-info?width)),
            map:entry("images", [ img:iiif-image( map { 
                "image-id" := $image-id,
                "canvas-id" := $canvas-id,
                "manifest-id" := $manifest-id,
                "height" := xs:integer($image-info?height),
                "width" := xs:integer($image-info?width)
            } ) ])
        ))
};

(:~
 : Create an IIIF image object
 :
 : @param 
 : @return a image object
 :)
declare %private function img:iiif-image($model as map()) as map(*) {
    map {
        "@type" := "oa:Annotation",
        "@id" := $model?image-id, 
        "motivation" := "sc:painting",
        "on" := $model?canvas-id,
        "resource" := map {
            "@id" := replace($model?manifest-id, 'manifest', 'images'),
            "@type" := "dctypes:Image",
            "height" := $model?height,
            "width" := $model?width,
            "format" := 'image/jpg',
            "service":= map {
                "@context": "http://iiif.io/api/image/2/context.json", 
                "@id": $model?image-id, 
                "profile": "http://iiif.io/api/image/2/level0.json"
            }
        }
    }
};

(:~
 : Get human readable image attribution information for a digital facsimile 
 : Helper function for img:iiif-manifest()
 :
 : @param $facsimile a TEI facsimile element
 : @return a human readable string referring to the image source
 :)
declare %private function img:iiif-manifest-attribution($facsimile as element(tei:facsimile)) as xs:string {
    let $source := query:facsimile-witness($facsimile)
    return
        typeswitch($source)
        case element(tei:msDesc) return str:normalize-space($source/tei:msIdentifier/tei:repository)
        case element(tei:biblStruct) return str:normalize-space($source/tei:monogr/tei:title[1])
        case element(tei:bibl) return str:normalize-space($source)
        default return 'Carl-Maria-von-Weber-Gesamtausgabe'
};
