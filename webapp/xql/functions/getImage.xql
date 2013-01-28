xquery version "1.0" encoding "UTF-8";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace request="http://exist-db.org/xquery/request";
import module namespace functx="http://www.functx.com" at "xmldb:exist:///db/webapp/xql/modules/functx.xqm";
import module namespace wega="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/wega" at "xmldb:exist:///db/webapp/xql/modules/wega.xqm";

declare option exist:serialize "method=xhtml media-type=text/html indent=no omit-xml-declaration=yes encoding=utf-8";

declare function local:switchImage($docId as xs:string, $pageNo as xs:integer, $lang as xs:string) {
    concat("javascript:letter.loadajaxpage('functions/getImage.xql?id=", $docId, "&#38;lang=", $lang, "&#38;page=", $pageNo, "')")
};

let $lang := request:get-parameter('lang', 'de')
let $docId := request:get-parameter('id', '')
let $page := if (request:get-parameter('page', '') castable as xs:integer) then xs:integer(request:get-parameter('page', '')) else 1
let $doc := if(empty($docId)) then() else wega:doc($docId)
let $images := $doc//tei:facsimile/tei:graphic/data(@url)
let $imagesCount := count($images)
(:let $digilibServerAddress := 'localhost:9090':)
let $digilibFn := concat(functx:replace-multi(document-uri($doc), ('/db/', '\.xml'), ('/', '/')), $images[$page])
(:let $jsCall := concat("javascript: letter.loadajaxpage('functions/getImage.xql?id=", $docId, "&#38;lang=", $lang, "&#38;page=") :)

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
<div id="picContainer"><img src="{concat(wega:getOption('digilibDir'), $digilibFn, '&amp;dw=', $maxWidth, '&amp;ww=', $ww, '&amp;wh=', $wh, '&amp;dh=', $maxHeight, '&amp;wx=', $wx, '&amp;wy=', $wy)}" id="pic"/><img id="hiRes"/></div>,
<div id="picHandler"></div>
)