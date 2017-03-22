xquery version "3.0" encoding "UTF-8";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

import module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util" at "wega-util.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace gl="http://xquery.weber-gesamtausgabe.de/modules/gl" at "gl.xqm";

declare option exist:serialize "method=xml media-type=application/tei+xml indent=no encoding=utf-8";

let $docID := request:get-attribute('docID')
let $specID := request:get-attribute('specID')
let $schemaID := request:get-attribute('schemaID')
let $chapID := request:get-attribute('chapID')
let $dbPath := request:get-attribute('dbPath')
let $content := 
	if(config:get-doctype-by-id($docID)) then try { core:doc(request:get-attribute($docID)) } catch  * {()}
	else if($specID) then gl:spec($specID, $schemaID)
	else if($chapID) then gl:chapter($chapID)
	else if($dbPath) then try {doc($dbPath)} catch * { core:logToFile('error', 'Failed to load XML document at "' || $dbPath  || '"') }
	else ()
return
    wega-util:remove-comments($content)