xquery version "3.1" encoding "UTF-8";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";
(:import module namespace functx="http://www.functx.com";:)

(: Change this line to point at your local api module :)
import module namespace api="http://xquery.weber-gesamtausgabe.de/modules/api" at "../../modules/api.xqm";

import module namespace controller="http://xquery.weber-gesamtausgabe.de/modules/controller" at "../../modules/controller.xqm";

(: Change this line to point at your swagger config file :)
declare variable $local:swagger-config := json-doc('xmldb:exist:///db/apps/WeGA-WebApp/api/v1/swagger.json');

(:~
 :  Some eXist environment variables which get passed through
~:)
declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;

(:~
 :  We create a map object and add these variables together with the HTTP request parameters
 :  This map gets forwarded to every subsequent API function 
~:)
declare variable $local:model as map() := map:new(( 
    map {
        'exist:path' := $exist:path, 
        'exist:resource' := $exist:resource, 
        'exist:controller' := $exist:controller, 
        'exist:prefix' := $exist:prefix,
        'swagger:config' := $local:swagger-config
    },
    for $i in request:get-parameter-names() return map:entry($i, request:get-parameter($i, ''))
));

(:~
 :  Serialize output as JSON
 :
 :  @param $response the output to be serialized
 :  @return          no return value. The output gets streamed directly to the servlet's output stream via response:stream(). 
~:)
declare function local:serialize-json($response as item()*) {
    let $serializationParameters := ('method=text', 'media-type=application/json', 'encoding=utf-8')
    let $setHeader1 := response:set-header('cache-control','max-age=0, no-cache, no-store')
    let $setHeader2 := response:set-header('pragma','no-cache')
    let $setHeader3 := if($response instance of map() and $response?code) then response:set-status-code($response?code) else ()
    (:let $setHeader3 := 
        if(exists($response)) then response:set-header('ETag', util:hash($response, 'md5'))
        else ():)
    return 
        response:stream(
            serialize($response, 
                <output:serialization-parameters>
                    <output:method>json</output:method>
                </output:serialization-parameters>
            ), 
            string-join($serializationParameters, ' ')
        )      
};

(:~
 :  Serialize output as XML
 : 
 :  @param $response the output to be serialized
 :  @param $root     the name of the root element
 :  @return          an XML fragment 
~:)
declare function local:serialize-xml($response as item()*, $root as xs:string) as element() {
    let $setHeader3 := if($response instance of map() and $response?code) then response:set-status-code($response?code) else ()
    return
        element {$root} {
            for $i in $response
            return 
                typeswitch($i)
                case map() return $i?* ! local:serialize-xml($i(.), .)
                case function() as item() return <array>{ for $j in $i?* return local:serialize-xml($j, 'root')/node() }</array>
                default return $response
        }
};

(:~
 :  Try to lookup a function for requested path
 :  Swagger paths get mapped to functions by concatenating path segments with dashes, 
 :  e.g. "/foo/bar/baz" --> api:foo-bar-baz() 
 :  Swagger path variables are removed from the path and put into a map() which gets passed on to the function,
 :  e.g. "/foo/{bar}/baz" --> api:foo-baz(map(bar: $bar-value$))
~:)
let $lookup := 
    for $swagger-path in map:keys($local:swagger-config?paths)
    let $swagger-path-tokens := tokenize($swagger-path, '/')
    let $path-regex := '^' || replace($swagger-path, '\{[^\}]+\}', '[^/]+') || '$'
(:    let $log := util:log-system-out(string-join(($path-regex, $exist:path), ' ; ')):)
    return
        if(matches($exist:path, $path-regex)) then 
            let $func-name := string-join($swagger-path-tokens ! replace(., '\{[^\}]+\}', '')[.], '-')
            let $params := for $token at $pos in $swagger-path-tokens return if(contains($token, '{')) then map:entry(replace($token, '[\{\}]', ''), tokenize($exist:path, '/')[$pos]) else ()
            return
                ( 
                    function-lookup(xs:QName('api:' || $func-name), 1),
                    map:new($params)
                )
        else ()

(:~  
 :   Create response by calling the above function 
 :   Sending one parameter to the function of type map()
 :   If $lookup is empty, return a map() with error message and code
~:)
let $response := 
    typeswitch($lookup[1])
    case empty() return map {'code' := 404, 'message' := 'not implemented', 'fields' := ''}
    case map() return map {'code' := 404, 'message' := 'not implemented', 'fields' := ''} (: failed function lookup but params are present:)
    default return 
        try { $lookup[1](map:new(($local:model, $lookup[2]))) }
        catch * { map {'code' := 404, 'message' := $err:description, 'fields' := 'Error Code: ' ||  $err:code} }

(:~
 :  Check HTTP header for 'Accept' key. 
 :  Browsers send a comma separated list of possible values 
~:)
let $accept-header := tokenize(request:get-header('Accept'), '[,;]')

return
    if($exist:resource eq 'swagger.json') then ()
    else if($exist:path eq '/') then controller:redirect-absolute('/index.html')
    else if($exist:resource eq 'index.html') then controller:forward-html('api/v1/index.html', map:new(($local:model, map {'lang' := 'en', 'path' := $exist:path, 'controller' := $exist:controller || '/../../' } )))
    else if(contains($exist:path, '/resources/')) then 
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{concat($exist:controller, '/../../resources/', substring-after($exist:path, '/resources/'))}">
                <set-header name="Cache-Control" value="max-age=3600,public"/>
            </forward>
        </dispatch>
    else if($accept-header[.='application/xml']) then local:serialize-xml($response, if(empty($lookup)) then 'Error' else $exist:resource )
    else if($accept-header[.='application/json']) then local:serialize-json($response)
    else ()
