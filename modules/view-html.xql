(:~
 : This is the main XQuery which will (by default) be called by controller.xql
 : to process any URI ending with ".html". It receives the HTML from
 : the controller and passes it to the templating system.
 :)
xquery version "3.0";

import module namespace templates="http://exist-db.org/xquery/templates" ;

(: 
 : The following modules provide functions which will be called by the 
 : templating.
 :)
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace app="http://xquery.weber-gesamtausgabe.de/modules/app" at "app.xqm";
import module namespace img="http://xquery.weber-gesamtausgabe.de/modules/img" at "img.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace facets="http://xquery.weber-gesamtausgabe.de/modules/facets" at "facets.xqm";
import module namespace search="http://xquery.weber-gesamtausgabe.de/modules/search" at "search.xqm";

declare option exist:serialize "method=xhtml5 media-type=text/html enforce-xhtml=yes";

let $config := map {
    $templates:CONFIG_APP_ROOT := $config:app-root,
    $templates:CONFIG_STOP_ON_ERROR := true()
}

let $model := 
    typeswitch (request:get-attribute('docID'))
    case xs:string return 
        map {
            'docID' := request:get-attribute('docID'),
            'docType' := request:get-attribute('docType'),
            'doc' := core:doc(request:get-attribute('docID')),
            'page-title' := 'Eine Seite aus der WeGA'
        }
    default return ()
    
(:
 : We have to provide a lookup function to templates:apply to help it
 : find functions in the imported application modules. The templates
 : module cannot see the application modules, but the inline function
 : below does see them.
 :)
let $lookup := function($functionName as xs:string, $arity as xs:int) {
    try {
        function-lookup(xs:QName($functionName), $arity)
    } catch * {
        ()
    }
}
(:
 : The HTML is passed in the request from the controller.
 : Run it through the templating system and return the result.
 :)
let $content := request:get-data()
let $startTime := util:system-time()
return (
    templates:apply($content, $lookup, $model, $config),
    util:log-system-out('view-html: ' || string(seconds-from-duration(util:system-time() - $startTime)))
    )
