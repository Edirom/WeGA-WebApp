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
    function img:iconography($node as node(), $model as map(*), $lang as xs:string) as map(*)* {
        let $local-image := img:wega-images($model, $lang)
        let $suppressExternalPortrait := core:getOrCreateColl('iconography', $model('docID'), true())//tei:figure[not(tei:graphic)]
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
            if(count(map:keys($beaconMap)[.= 'wikipedia']) gt 0) then img:wikipedia-images($model, $lang)
            else ()
        let $tripota-images := 
            if(count(map:keys($beaconMap)[contains(., 'GND-Zuordnung')]) gt 0) then img:tripota-images($model, $lang)
            else ()
        let $iconographyImages := ($local-image, $wikipedia-images, $portraitindex-images, $tripota-images)
        let $portrait := 
            if($suppressExternalPortrait) then img:get-generic-portrait($model, $lang)
            else ($iconographyImages, img:get-generic-portrait($model, $lang))[1]
        return
            map { 
                'iconographyImages' := $iconographyImages,
                'portrait' := $portrait
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
    (: Look for images in wikipedia infobox (for organizations) and thumbnails  :)
    let $pics := $wikiArticle//xhtml:table[contains(@class,'toptextcells')] | $wikiArticle//xhtml:div[@class='thumbinner']
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
            if($div[self::xhtml:table]) then $div/xhtml:tr[.//xhtml:img]/preceding::xhtml:tr[1] 
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
                           let $iiifInfo := wega-util:wikimedia-ifff(functx:substring-after-last($linkTarget, ':'))
                           return
                              try {
                                 if($iiifInfo('height') > 340) then $iiifInfo('@id') || '/full/,340/0/native.jpg'
                                 else $iiifInfo('@id') || '/full/full/0/native.jpg'
                              }
                              catch * { $thumbURI }
                        default return 
                           let $iiifInfo := wega-util:wikimedia-ifff(functx:substring-after-last($linkTarget, ':'))
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
 : Helper function for adding local (= from the WeGA) images
 :
 : @author Peter Stadler 
 : @param 
 : @param $lang the language variable (de|en)
 : @return 
 :)
declare %private function img:wega-images($model as map(*), $lang as xs:string) as map(*)* {
    let $iiifServer := config:get-option('iiifServer')
    return
        for $fig in core:getOrCreateColl('iconography', $model('docID'), true())//tei:figure[tei:graphic]
        (:  Need to double encode URI due to old Apache front end  :)
        let $iiifURI := 
            if(contains($iiifServer, 'euryanthe')) then $iiifServer || encode-for-uri(encode-for-uri(string-join(('persons', substring($model('docID'), 1, 5) || 'xx', $model('docID'), $fig/tei:graphic/@url), '/')))
            else $iiifServer || encode-for-uri(string-join(('persons', substring($model('docID'), 1, 5) || 'xx', $model('docID'), $fig/tei:graphic/@url), '/'))
        order by $fig/@n (: markup with <figure n="portrait"> takes precedence  :)
        return 
            map {
                'caption' := normalize-space($fig/preceding::tei:title),
                'linkTarget' := $iiifURI || '/full/full/0/native.jpg',
                'source' := normalize-space($fig//tei:bibl),
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
        let $url := $model('portrait')('url')($size)
        return
            element {node-name($node)} {
                $node/@*[not(local-name(.) = ('src', 'title', 'alt'))],
                attribute title {$model('portrait')('caption')},
                attribute alt {$model('portrait')('caption')},
                attribute src {$url}
            }
};

declare %private function img:get-generic-portrait($model as map(*), $lang as xs:string) as map(*) {
    let $sex := 
        if(config:is-org($model('docID'))) then 'org'
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
                    default return core:link-to-current-app('resources/img/icons/icon_persons.png')
                default return 
                    switch($sex)
                    case 'f' return core:link-to-current-app('resources/img/icons/icon_person_frau_gross.png')
                    case 'm' return core:link-to-current-app('resources/img/icons/icon_person_mann_gross.png')
                    case 'org' return core:link-to-current-app('resources/img/icons/icon_orgs_gross.png')
                    default return core:link-to-current-app('resources/img/icons/icon_person_unbekannt_gross.png')
            }
        }
};


declare function img:iiif-manifest($docID as xs:string) as map(*) {
    (:let $id := 'letters/A0412xx/A041234/1817-07-10_05_AM_Weber_an_Caroline_D-B_1r.tif'
    let $width := '2030'
    let $height := '2414':)
    let $doc := core:doc($docID)
    let $baseURL := config:get-option('iiifServer')
    let $id := $baseURL || $docID 
    let $label := wdt:lookup(config:get-doctype-by-id($docID), $docID)('title')()
    let $db-path := substring-after(config:getCollectionPath($docID), $config:data-collection-path || '/')
    return
        map {
            "@context":= "http://iiif.io/api/presentation/2/context.json",
            "@id":= $id || '/manifest.json',
            "@type" := "sc:Manifest", 
            "label":= $label,
            "sequences" := [ map {
                "@id":= $id || '/sequences.json',
                "@type" := "sc:Sequence", 
                "label" := "Default", 
                "canvases" := array {
                    for $i at $counter in $doc//tei:facsimile/tei:graphic
                    let $db-path := substring-after(config:getCollectionPath($docID), $config:data-collection-path || '/')
                    (:  Need to double encode URI due to old Apache front end  :)
                    let $image-id := $baseURL || encode-for-uri(encode-for-uri(str:join-path-elements(($db-path, $docID, $i/@url))))
                    let $page-label := 
                        if($i/@xml:id) then $i/string(@xml:id)
                        else 'page' || $counter 
                    return 
                        map:new((
                            map:entry("@type", "sc:Canvas"),
                            map:entry("label", $page-label),
                            map:entry("images", [ map {
                                "@type" := "oa:Annotation",
                                "resource" := map {
                                    "@id" := $id || '/images.json',
                                    "@type" := "dctypes:Image",
                                    "service":= map {
                                        "@context": "http://iiif.io/api/image/2/context.json", 
                                        "@id": $image-id, 
                                        "profile": "http://iiif.io/api/image/2/level0.json"
                                    }
                                }
                            }])
                        ))
                    }
            }]
        }
};
