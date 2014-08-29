(:~
 : This is the XQuery which will tidy up the result created by the templating module
 :)
xquery version "3.0" encoding "UTF-8";

import module namespace templates="http://exist-db.org/xquery/templates" ;

(:import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";:)
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "str.xqm";
(:import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";:)

declare option exist:serialize "method=html5 media-type=text/html enforce-xhtml=yes";

declare function local:tidy($node as node()) as node() {
    typeswitch ($node)
        case document-node() return
            for $child in $node/node() return local:tidy($child)     
                        
        case element() return                 
            element { node-name($node) } {
                for $attr in $node/@* return local:tidy-attr($attr),
                for $child in $node/node() return local:tidy($child)
            }
                    
        default return 
            $node
};

declare function local:tidy-attr($node as node()) as node()? {
    let $lang := request:get-attribute('lang')
    return 
        if(starts-with(node-name($node), 'data-template')) then ()
        
        else if(starts-with($node, '$resources')) then 
            attribute { node-name($node) } {core:link-to-current-app(substring-after($node, '$'))}
        
        else if(starts-with($node, '$link')) then 
            attribute { node-name($node) } {core:link-to-current-app(str:join-path-elements(($lang, substring-after($node, '$link'))))}
            
        else $node
};

(:
 : The HTML is passed in the request from the controller.
 : Run it through the templating system and return the result.
 :)
let $content := request:get-data()
return
    local:tidy($content)
    