xquery version "3.1" encoding "UTF-8";

(:~
 : Main controller file for the API
 :
 : If you adopt this for your repository, you'll need to do the following:
 : 1. Create an API module and reference it in line XX
 : 2. Adjust settings in this file (path to openapi.json and api prefix) 
 : 3. You must provide a function called 'validate-unknown-param' in your API module which takes two strings as parameters (i.e. the param name and the value)
 : 4. You may provide other functions for checking/validating params. The naming scheme of the function is simply 'validate-$paraName$' and it must accept one string as a parameter (i.e. the param value)
~:)

declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";
declare namespace map="http://www.w3.org/2005/xpath-functions/map";
declare namespace util="http://exist-db.org/xquery/util";
(:import module namespace functx="http://www.functx.com";:)

(: Change this line to point at your local api module :)
import module namespace api="http://xquery.weber-gesamtausgabe.de/modules/api" at "../../modules/api.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "../../modules/config.xqm";

import module namespace controller="http://xquery.weber-gesamtausgabe.de/modules/controller" at "../../modules/controller.xqm";

(: Change this line to point at your openapi config file :)
declare variable $local:openapi-config := json-doc($config:openapi-config-path);

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
declare variable $local:defaults as map(*) := map {
    'exist:path' : $exist:path, 
    'exist:resource' : $exist:resource, 
    'exist:controller' : $exist:controller || '/../../', 
    'exist:prefix' : $exist:prefix
};

(:~
 :  Another map object with the HTTP request parameters
 :  This map gets later forwarded to every subsequent API function 
~:)
declare variable $local:url-parameters as map(*) := map:merge((
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
    let $responseBody :=
        if($response instance of map(*) and map:contains($response,'results')) then $response?results
        else if($response instance of map(*) and map:contains($response,'code')) then $response
        else map {'code' : 500, 'message' : 'Internal server error', 'fields' : ''} 
    let $setHeader1 := response:set-header('cache-control','max-age=0, no-cache, no-store')
    let $setHeader2 := response:set-header('pragma','no-cache')
    let $setHeader3 := 
        if($response instance of map(*) and map:contains($response,'code')) 
        then response:set-status-code($response?code) 
        else if($responseBody instance of map(*) and map:contains($responseBody,'code')) 
        then response:set-status-code($responseBody?code)
        else ()
    let $setHeader4 := 
        if($response instance of map(*) and map:contains($response,'totalRecordCount'))
        then response:set-header('totalRecordCount', $response?totalRecordCount)
        else ()
    let $setHeader4.5 := 
        if($response instance of map(*) and map:contains($response,'filteredRecordCount'))
        then response:set-header('filteredRecordCount', $response?filteredRecordCount)
        else ()
    let $setHeader5 := response:set-header('Access-Control-Allow-Origin', '*')
    let $setHeader6 := response:set-header('Access-Control-Expose-Headers', 'totalrecordcount, filteredrecordcount')
    return 
        response:stream(
            serialize($responseBody, 
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
    let $setHeader3 := 
        if($response[1] instance of map(*) and map:contains($response[1],'code')) 
        then response:set-status-code($response[1]?code) 
        else ()
    let $setHeader4 := 
        if($response[1] instance of map(*) and map:contains($response[1],'totalRecordCount'))
        then response:set-header('totalRecordCount', $response[1]?totalRecordCount)
        else ()
    let $setHeader4.5 := 
        if($response instance of map(*) and map:contains($response,'filteredRecordCount'))
        then response:set-header('filteredRecordCount', $response?filteredRecordCount)
        else ()
    let $setHeader5 := response:set-header('Access-Control-Allow-Origin', '*')
    let $setHeader6 := response:set-header('Access-Control-Expose-Headers', 'totalrecordcount, filteredrecordcount')
    return
        element {$root} {
            for $i in subsequence($response, if(count($response) gt 1) then 2 else 1)
            return 
                typeswitch($i)
                case map(*) return map:keys($i) ! local:serialize-xml($i(.), .)
                case function() as item() return <array>{ for $j in $i?* return local:serialize-xml($j, 'root')/node() }</array>
                default return $response
        }
};

(:~
 :  Try to lookup a function for the requested path and extract path parameters
 :  openapi paths get mapped to functions by concatenating path segments with dashes, 
 :  e.g. "/foo/bar/baz" --> api:foo-bar-baz() 
 :  openapi path variables are removed from the path and put into a map{} which gets passed on to the function,
 :  e.g. "/foo/{bar}/baz" --> api:foo-baz(map{bar: $bar-value$})
~:)
let $lookup as map(*)? := 
    (
    for $openapi-path in map:keys($local:openapi-config?paths)
    let $openapi-path-tokens := tokenize($openapi-path, '/')
    let $path-regex := '^' || replace($openapi-path, '\{[^\}]+\}', '[^/]+') || '$'
(:    let $log := util:log-system-out(string-join(($path-regex, $exist:path), ' ; ')):)
    let $possible-matches :=
        if(matches($exist:path, $path-regex)) then 
            let $func-name := string-join($openapi-path-tokens ! replace(., '\{[^\}]+\}', '')[.], '-')
            let $params := for $token at $pos in $openapi-path-tokens return if(contains($token, '{')) then map:entry(replace($token, '[\{\}]', ''), xmldb:decode(tokenize($exist:path, '/')[$pos])) else ()
            return
                map {
                    'func' : function-lookup(xs:QName($local:api-module-prefix || ':' || $func-name), 1),
                    'path-params' : map:merge($params)
                }
        else ()
    (: return the most specific function, e.g. the function "a-b()" is prefered over the function "a(b)" :)
    order by string-length(function-name($possible-matches?func) cast as xs:string) descending
    return 
        $possible-matches
    )[1]

let $validate-unknown-param := function-lookup(xs:QName($local:api-module-prefix || ':validate-unknown-param'), 1)

let $validate-params := function($params as map(*)?) as map(*)? {
    if(exists($params)) then
        map:merge(
            for $param in map:keys($params)
            let $lookup := function-lookup(xs:QName($local:api-module-prefix || ':validate-' || $param), 1)
            return
                if(exists($lookup)) then $lookup(map {$param : $params($param), 'openapi:config' : $local:openapi-config })
                else if(exists($validate-unknown-param)) then $validate-unknown-param(map {$param : $params($param), 'openapi:config' : $local:openapi-config })
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
let $response := function($lookup as map(*)) { 
   (: typeswitch($lookup?func)
    case empty-sequence() return $unknown-function
    default return :)
        try { $lookup?func(map:merge(($local:defaults, map {'openapi:config' : $local:openapi-config}, $validate-params($lookup?path-params), $validate-params($local:url-parameters)))) }
        catch * { map {'code' : 404, 'message' : $err:description, 'fields' : 'Error Code: ' ||  $err:code} }
}

(:~
 :  Check HTTP header for 'Accept' key. 
 :  Browsers send a comma separated list of possible values 
~:)
let $accept-header := tokenize(request:get-header('Accept'), '[,;]')
let $unknown-function := 
     map {'code' : 404, 'message' : 'Unknown/unsupported API function. Please refer to the openapi.json file for supported functions.', 'fields' : ''}

return (:(
    util:log-system-out($exist:path),
    util:log-system-out($exist:resource)
    ):)
    if($exist:resource = ('openapi.json', 'swagger.json')) then response:set-header('Access-Control-Allow-Origin', '*')
    else if($exist:path eq '/' or not($exist:path)) then controller:redirect-absolute('/index.html')
    else if($exist:resource eq 'index.html') then controller:forward-html('api/v1/index.html', map:merge(($local:defaults, map {'lang' : 'en'} )))
    else if(contains($exist:path, '/resources/')) then 
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{concat($exist:controller, '/../../resources/', substring-after($exist:path, '/resources/'))}">
                <set-header name="Cache-Control" value="max-age=3600,public"/>
            </forward>
        </dispatch>
    else if(exists($lookup)) then 
        if($accept-header[.='application/xml']) then local:serialize-xml($response($lookup), if(empty($lookup)) then 'Error' else $exist:resource )
        else local:serialize-json($response($lookup))
        (:else if($accept-header[.='application/json']) then local:serialize-json($response($lookup))
        else local:serialize-xml(map { 'msg':= 'Unknown/unsupported HTTP Accept Header. Please refer to the openapi.json file for supported response formats.', 'code':= 406 }, 'apiResponse'):)
    else if($accept-header[.='application/xml']) then local:serialize-xml($unknown-function, 'apiResponse')
    else local:serialize-json($unknown-function)
