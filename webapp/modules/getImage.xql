xquery version "1.0" encoding "UTF-8";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace request="http://exist-db.org/xquery/request";
import module namespace functx="http://www.functx.com";
import module namespace wega="http://xquery.weber-gesamtausgabe.de/modules/wega" at "wega.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";

declare option exist:serialize "method=xhtml media-type=text/html indent=no omit-xml-declaration=yes encoding=utf-8";

declare function local:switchImage($docId as xs:string, $pageNo as xs:integer, $lang as xs:string) {
    concat("javascript:letter.loadajaxpage('functions/getImage.xql?id=", $docId, "&#38;lang=", $lang, "&#38;page=", $pageNo, "')")
};

let $lang := request:get-parameter('lang', 'de')
let $docId := request:get-parameter('id', ())
let $page := if(request:get-parameter('page', '') castable as xs:integer) then xs:integer(request:get-parameter('page', '')) else 1
let $doc := core:doc($docId)
let $images := $doc//tei:facsimile/tei:graphic/data(@url)
let $imagesCount := count($images)
(:let $digilibServerAddress := 'localhost:9090':)
let $digilibFn := core:join-path-elements((substring-after(config:getCollectionPath($docId), $config:data-collection-path), $docId, $images[$page]))
let $maxWidth := '700'
let $maxHeight := '700'
let $scaleFactor := 1
let $ww := $scaleFactor
let $wh := $ww
let $wx := 
    1 - $scaleFactor
let $wy := $wx

return (
<div class="digilibMenu">
    <a href="javascript:zoomOut();"><img src="http://books.google.com/googlebooks/images/out_btn.png" alt="Zoom out"/></a>
    <a href="javascript:zoomIn();"><img src="http://books.google.com/googlebooks/images/in_btn.png" alt="Zoom in"/></a>
    {if($page gt 1) 
        then element {'a'} {
                attribute {'href'}{local:switchImage($docId, $page -1, $lang)},
                element {'img'}{
                    attribute {'src'} {'http://books.google.com/googlebooks/images/left_btn.png'},
                    attribute {'alt'} {'Previous image'}
            }
            }
        else <img src="http://books.google.com/googlebooks/images/left_btn.png" alt="Previous image"/>}
    {if($page lt $imagesCount) 
        then element {'a'} {
                attribute {'href'}{local:switchImage($docId, $page +1, $lang)},
                element {'img'}{
                    attribute {'src'} {'http://books.google.com/googlebooks/images/right_btn.png'},
                    attribute {'alt'} {'Next image'}
                }
            }
        else <img src="http://books.google.com/googlebooks/images/right_btn.png" alt="Next image"/>}
</div>,
<div id="picContainer"><img src="{concat(config:get-option('digilibDir'), $digilibFn, '&amp;dw=', $maxWidth, '&amp;ww=', $ww, '&amp;wh=', $wh, '&amp;dh=', $maxHeight, '&amp;wx=', $wx, '&amp;wy=', $wy)}" id="pic"/><img id="hiRes"/></div>,
<div id="picHandler"></div>
)