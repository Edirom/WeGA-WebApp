xquery version "3.1" encoding "UTF-8";

(:~
 : Main controller file for the API
 :
 : If you adopt this for your repository, you'll need to do the following:
 : 1. Create an API module and reference it in line XX
 : 2. Adjust settings in this file (path to swagger.json and api prefix) 
 : 3. You must provide a function called 'validate-unknown-param' in your API module which takes two strings as parameters (i.e. the param name and the value)
 : 4. You may provide other functions for checking/validating params. The naming scheme of the function is simply 'validate-$paraName$' and it must accept one string as a parameter (i.e. the param value)
~:)

declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";
(:import module namespace functx="http://www.functx.com";:)

(: Change this line to point at your local api module :)
import module namespace api="http://xquery.weber-gesamtausgabe.de/modules/api" at "../../modules/api.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "../../modules/config.xqm";

import module namespace controller="http://xquery.weber-gesamtausgabe.de/modules/controller" at "../../modules/controller.xqm";

(: Change this line to point at your swagger config file :)
declare variable $local:swagger-config := json-doc($config:swagger-config-path);

(: Change this if you are using a different prefix for your module in line XX :)
declare variable $local:api-module-prefix as xs:string := 'api'; 

(:~
 :  Some eXist environment variables which get passed through
~:)
declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;

declare variable $local:INVALID_PARAMETER := QName("http://xquery.weber-gesamtausgabe.de/modules/api", "ParameterError");

(:~
 :  We create a map object and add these variables
 :  This map gets later forwarded to every subsequent API function 
~:)
declare variable $local:defaults as map() := map {
    'exist:path' := $exist:path, 
    'exist:resource' := $exist:resource, 
    'exist:controller' := $exist:controller, 
    'exist:prefix' := $exist:prefix,
    'swagger:config' := $local:swagger-config
};

(:~
 :  Another map object with the HTTP request parameters
 :  This map gets later forwarded to every subsequent API function 
~:)
declare variable $local:url-parameters as map() := map:new((
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
 :  Try to lookup a function for the requested path and extract path parameters
 :  Swagger paths get mapped to functions by concatenating path segments with dashes, 
 :  e.g. "/foo/bar/baz" --> api:foo-bar-baz() 
 :  Swagger path variables are removed from the path and put into a map() which gets passed on to the function,
 :  e.g. "/foo/{bar}/baz" --> api:foo-baz(map(bar: $bar-value$))
~:)
let $lookup as map()? := 
    (
    for $swagger-path in map:keys($local:swagger-config?paths)
    let $swagger-path-tokens := tokenize($swagger-path, '/')
    let $path-regex := '^' || replace($swagger-path, '\{[^\}]+\}', '[^/]+') || '$'
(:    let $log := util:log-system-out(string-join(($path-regex, $exist:path), ' ; ')):)
    let $possible-matches :=
        if(matches($exist:path, $path-regex)) then 
            let $func-name := string-join($swagger-path-tokens ! replace(., '\{[^\}]+\}', '')[.], '-')
            let $params := for $token at $pos in $swagger-path-tokens return if(contains($token, '{')) then map:entry(replace($token, '[\{\}]', ''), tokenize($exist:path, '/')[$pos]) else ()
            return
                map {
                    'func' := function-lookup(xs:QName($local:api-module-prefix || ':' || $func-name), 1),
                    'path-params' := map:new($params)
                }
        else ()
    (: return the most specific function, e.g. the function "a-b()" is prefered over the function "a(b)" :)
    order by string-length(function-name($possible-matches?func) cast as xs:string) descending
    return 
        $possible-matches
    )[1]

let $validate-unknown-param := function-lookup(xs:QName($local:api-module-prefix || ':validate-unknown-param'), 1)

let $validate-params := function($params as map()?) as map()? {
    if(exists($params)) then
        map:new(
            for $param in $params?*
            let $lookup := function-lookup(xs:QName($local:api-module-prefix || ':validate-' || $param), 1)
            return
                if(exists($lookup)) then $lookup(map:entry($param, $params($param)))
                else if(exists($validate-unknown-param)) then $validate-unknown-param(map:entry($param, $params($param)))
                else (
                    util:log-system-out('It seems you did not provide a validate-unknown-param function'),
                    error($local:INVALID_PARAMETER, 'Unknown parameter "' || $param || '". Details should be provided in the system log.') 
                )
        )
    else ()
}

(:~  
 :   Create response by calling the above function 
 :   Sending one parameter to the function of type map()
 :   If $lookup is empty, return a map() with error message and code
~:)
let $response := function() { 
    typeswitch($lookup?func)
    case empty() return map {'code' := 404, 'message' := 'not implemented', 'fields' := ''}
    default return 
        try { $lookup?func(map:new(($local:defaults, $validate-params($lookup?path-params), $validate-params($local:url-parameters)))) }
        catch * { map {'code' := 404, 'message' := $err:description, 'fields' := 'Error Code: ' ||  $err:code} }
}

(:~
 :  Check HTTP header for 'Accept' key. 
 :  Browsers send a comma separated list of possible values 
~:)
let $accept-header := tokenize(request:get-header('Accept'), '[,;]')

return (:(
    util:log-system-out($exist:path),
    util:log-system-out($exist:resource)
    ):)
    if($exist:resource eq 'swagger.json') then ()
    else if($exist:path eq '/' or not($exist:path)) then controller:redirect-absolute('/index.html')
    else if($exist:resource eq 'index.html') then controller:forward-html('api/v1/index.html', map:new(($local:defaults, map {'lang' := 'en', 'path' := $exist:path, 'controller' := $exist:controller || '/../../' } )))
    else if(contains($exist:path, '/resources/')) then 
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{concat($exist:controller, '/../../resources/', substring-after($exist:path, '/resources/'))}">
                <set-header name="Cache-Control" value="max-age=3600,public"/>
            </forward>
        </dispatch>
    else if($accept-header[.='application/xml']) then local:serialize-xml($response(), if(empty($lookup)) then 'Error' else $exist:resource )
    else if($accept-header[.='application/json']) then local:serialize-json($response())
    else ()
