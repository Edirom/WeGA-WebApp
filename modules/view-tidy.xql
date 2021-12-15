(:~
 : This is the XQuery which will tidy up the result created by the templating module
 :)
xquery version "3.1" encoding "UTF-8";

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace request="http://exist-db.org/xquery/request";

import module namespace templates="http://exist-db.org/xquery/html-templating" ;
import module namespace functx="http://www.functx.com";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/str.xqm";
import module namespace controller="http://xquery.weber-gesamtausgabe.de/modules/controller" at "controller.xqm";

declare option output:method "xhtml5";
declare option output:media-type "text/html";

declare function local:tidy($node as node()) as node()? {
    typeswitch ($node)
        case document-node() return
            for $child in $node/node() return local:tidy($child)     
                        
        case element() return
            (:if($node/xhtml:a[@class='deactivated']) then ()
            else :)
                element { node-name($node) } {
                    for $attr in $node/@* return local:tidy-attr($attr),
                    for $child in $node/node() return local:tidy($child)
                }
        case comment() return ()
                    
        default return 
            $node
};

declare function local:tidy-attr($node as node()) as node()? {
    let $exist-vars := 
    	map { 
    		'lang' : request:get-attribute('lang'),
    		'exist:prefix' : request:get-attribute('exist:prefix'),
    		'exist:controller' : request:get-attribute('exist:controller')
    	}
    return 
        if(starts-with(node-name($node), 'data-template')) then ()
        
        else if(starts-with($node, '$resources')) then 
            attribute { node-name($node) } {config:link-to-current-app(substring-after($node, '$'))}
        
        else if(starts-with($node, '$link')) then 
            attribute { node-name($node) } {controller:resolve-link(data($node), $exist-vars)}

        else if(starts-with($node, '$dev')) then 
            attribute { node-name($node) } {config:link-to-current-app(substring($node, 2))}
            
        else $node
};

(:
 : The HTML is passed in the request from the controller.
 : Run it through the templating system and return the result.
 :)
let $content := request:get-data()
return
    local:tidy($content)
    