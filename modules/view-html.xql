(:~
 : This is the main XQuery which will (by default) be called by controller.xql
 : to process any URI ending with ".html". It receives the HTML from
 : the controller and passes it to the templating system.
 :)
xquery version "3.1";

import module namespace templates="http://exist-db.org/xquery/html-templating";

(: 
 : The following modules provide functions which will be called by the 
 : templating.
 :)
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace crud="http://xquery.weber-gesamtausgabe.de/modules/crud" at "crud.xqm";
import module namespace app="http://xquery.weber-gesamtausgabe.de/modules/app" at "app.xqm";
import module namespace app-shared="http://xquery.weber-gesamtausgabe.de/modules/app-shared" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/app-shared.xqm";
import module namespace img="http://xquery.weber-gesamtausgabe.de/modules/img" at "img.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace facets="http://xquery.weber-gesamtausgabe.de/modules/facets" at "facets.xqm";
import module namespace search="http://xquery.weber-gesamtausgabe.de/modules/search" at "search.xqm";
import module namespace lod="http://xquery.weber-gesamtausgabe.de/modules/lod" at "lod.xqm";
import module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util" at "wega-util.xqm";
import module namespace dev-app="http://xquery.weber-gesamtausgabe.de/modules/dev/dev-app" at "dev/dev-app.xqm";
import module namespace gl="http://xquery.weber-gesamtausgabe.de/modules/gl" at "gl.xqm";

declare option output:method "xhtml5";
declare option output:media-type "text/html";

let $config := map {
    $templates:CONFIG_APP_ROOT : $config:app-root,
    $templates:CONFIG_STOP_ON_ERROR : true()
}

(:~
 : Initialise the model map for the templating 
 : with the attributes that are passed by the controller
~:)
let $model := 
	map:merge((
		(
		for $var in request:attribute-names()
		return
			map:entry($var, request:get-attribute($var))
		),
		map:entry('environment', config:get-option('environment')),
		if(config:get-doctype-by-id(request:get-attribute('docID'))) then
		  map:entry('doc', try { crud:doc(request:get-attribute('docID')) } catch * {()})
	    else ()
	))
    
(:~
 : We have to provide a lookup function to templates:apply to help it
 : find functions in the imported application modules. The templates
 : module cannot see the application modules, but the inline function
 : below does see them.
~:)
let $lookup := function($functionName as xs:string, $arity as xs:int) {
    try { function-lookup(xs:QName($functionName), $arity) } 
    catch * {()}
}
(:~
 : The HTML is passed in the request from the controller.
 : Run it through the templating system and return the result.
~:)
let $content := request:get-data()
let $modified := request:get-attribute('modified') = 'true'
return 
    if($modified) then (:wega-util:stopwatch(templates:apply#4, ($content, $lookup, $model, $config), ()):)
        templates:apply($content, $lookup, $model, $config)
    else ( 
        (:util:log-system-out('cached ' || $model('docID')),:) 
        response:set-status-code( 304 )
    )
