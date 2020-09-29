xquery version "3.1" encoding "UTF-8";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util" at "wega-util.xqm";
import module namespace crud="http://xquery.weber-gesamtausgabe.de/modules/crud" at "crud.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace gl="http://xquery.weber-gesamtausgabe.de/modules/gl" at "gl.xqm";

declare option output:method "xml";
declare option output:media-type "application/tei+xml";
declare option output:indent "no";
(:declare option exist:serialize "method=xml media-type=application/tei+xml indent=no encoding=utf-8";:)

declare function local:format() as xs:string? {
    let $req-format := request:get-parameter('format', ())
    let $supported := local:available-transformations()
    return
        ($req-format[.=$supported])[1]
};

declare function local:available-transformations() as xs:string* {
    xmldb:get-child-resources($config:xsl-external-schemas-collection-path)[not(.='to-text.xsl')] ! (substring-before(substring-after(., 'to-'), '.xsl')) 
};

let $docID := request:get-attribute('docID')
let $specID := request:get-attribute('specID')
let $schemaID := request:get-attribute('schemaID')
let $chapID := request:get-attribute('chapID')
let $dbPath := request:get-attribute('dbPath')
let $content := 
	if(config:get-doctype-by-id($docID)) then try { crud:doc($docID) } catch  * {()}
	else if($specID) then gl:spec($specID, $schemaID)
	else if($chapID) then gl:chapter($chapID)
	else if($dbPath) then try {doc($dbPath)} catch * { wega-util:log-to-file('error', 'Failed to load XML document at "' || $dbPath  || '"') }
	else ()
let $format := local:format()

(:~ 
 : get the current TEI version on which the customizations are built
 : this is used for injecting the right schema reference for transformed TEI files 
~:)
let $TEIversion := $gl:main-source/tei:TEI/processing-instruction('TEIVERSION')/analyze-string(., '\d+\.\d+\.\d+')/fn:match/text()
let $transformed := 
    if($format) then 
        wega-util:transform(
            $content, 
            doc($config:xsl-external-schemas-collection-path || '/to-' || $format || '.xsl'), 
            config:get-xsl-params( map { 'current-tei-version': $TEIversion, 'facsimileGreenList': config:get-option('facsimileGreenList') } )
        )
    else $content
let $setHeader5 := response:set-header('Access-Control-Allow-Origin', '*')
return
    wega-util:inject-version-info(
        wega-util:process-xml-for-display($transformed)
    )