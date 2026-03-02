xquery version "3.1" encoding "UTF-8";

(:~
 : XQuery functions for the Distributed Text Services API
 :)
module namespace api-dts="http://xquery.weber-gesamtausgabe.de/modules/api-dts";

declare namespace map="http://www.w3.org/2005/xpath-functions/map";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";

import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace crud="http://xquery.weber-gesamtausgabe.de/modules/crud" at "crud.xqm";
import module namespace gl="http://xquery.weber-gesamtausgabe.de/modules/gl" at "gl.xqm";
import module namespace lod="http://xquery.weber-gesamtausgabe.de/modules/lod" at "lod.xqm";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";
import module namespace wdt="http://xquery.weber-gesamtausgabe.de/modules/wdt" at "wdt.xqm";
import module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util" at "wega-util.xqm";

declare variable $api-dts:INVALID_PARAMETER := QName("http://xquery.weber-gesamtausgabe.de/modules/api-dts", "ParameterError");
declare variable $api-dts:UNSUPPORTED_ID_SCHEMA := QName("http://xquery.weber-gesamtausgabe.de/modules/api-dts", "UnsupportedIDSchema");
declare variable $api-dts:UNSUPPORTED_TRANSFORMATION := QName("http://xquery.weber-gesamtausgabe.de/modules/api-dts", "UnsupportedTransformation");
declare variable $api-dts:collections :=
    for $func in $wdt:functions
        return
            if(map:contains($func(()), 'dtsCollection')) then $func(())('name')
            else ()
    ;
declare variable $api-dts:rootCollectionLabel := "root"; 
declare variable $api-dts:lang := "en";
declare variable $api-dts:max-limit := 50;
declare variable $api-dts:mediaTypes := function($openapi-conf as map(*)) as xs:string* {
    $openapi-conf?paths?("/dts/document")?get?parameters?*[.?name="mediaType"]?schema?enum?*
};
declare variable $api-dts:INVALID_COLLECTION_ID := QName("http://xquery.weber-gesamtausgabe.de/modules/dts-api", "CollectionIDError");

(:~
 :  Main entry point to the module
 :  This function will dispatch the responses to the respective serialization functions 
 :  depending on the "media-type" property in the `$headers` map
 :
 :  @param $body the body of the response, e.g. a TEI-XML file or a JSON object
 :  @param $headers the HTTP headers of the reponse with a 
 :          mandatory "media-type" key (value e.g. "application/tei+xml") 
 :)
declare function api-dts:dispatch($body as item(), $headers as map(*)) {
    switch($headers?media-type)
    case "application/json" case "application/ld+json" return api-dts:json-response($body, map:remove($headers, "media-type"))
    case "application/tei+xml" case "application/xml" return api-dts:xml-response($body, map:remove($headers, "media-type"))
    case "text/plain" return api-dts:txt-response($body, map:remove($headers, "media-type"))
    default return ()
};

declare function api-dts:json-response($body as map(*), $headers as map(*)) as empty-sequence() {
    let $serializationParameters := ("method=text", "media-type=application/json", "encoding=utf-8")
    let $setHeaders := api-dts:set-headers($headers)
    return 
        response:stream(
            serialize($body, 
                <output:serialization-parameters>
                    <output:method>json</output:method>
                </output:serialization-parameters>
            ), 
            string-join($serializationParameters, " ")
        ) 
};

declare function api-dts:txt-response($body as xs:string, $headers as map(*)) {
    let $serializationParameters := ("method=text", "media-type=text/plain", "encoding=utf-8")
    let $setHeaders := api-dts:set-headers($headers)
    return 
        response:stream(
            serialize($body, 
                <output:serialization-parameters>
                    <output:method>text</output:method>
                </output:serialization-parameters>
            ), 
            string-join($serializationParameters, " ")
        ) 
};

declare function api-dts:xml-response($body as node(), $headers as map(*)) {
    let $setHeaders := api-dts:set-headers(map:put($headers, "Content-Type", "application/tei+xml;charset=utf-8"))
    return
        $body
};

(:~
 :  DTS Entry Endpoint
 :)
declare function api-dts:dts($model as map(*)) as map(*) {
    map {
        "body":
            map {
                "@context": "https://dtsapi.org/context/v1.0.json",
                "@id": config:api-base($model("openapi:config")) || "/dts",
                "@type": "EntryPoint",
                "dtsVersion": "1.0",
                "collection": config:api-base($model("openapi:config")) || "/dts/collection{?id}",
                "document": config:api-base($model("openapi:config")) || "/dts/document{?resource,ref,start,end}",
                "navigation": config:api-base($model("openapi:config")) || "/dts/navigation{?resource,ref}"
            },
        "headers": map {
            "media-type": "application/json"
        }
    }
};

(:~
 :  DTS Document endpoint
 :)
declare function api-dts:dts-document($model as map(*)) as map(*) {
    let $internalFormat :=
        if($model?mediaType)
        then $model?mediaType
        else "tei_all"
    let $responseMediaType := 
        switch($internalFormat)
        case "text" return "text/plain"
        default return "application/tei+xml"
    let $doc.wega := query:doc-by-any-id($model?resource)
    let $doc :=
        switch($model?mediaType)
        case "wega" return $doc.wega
        default return api-dts:process-xml-document($doc.wega, $internalFormat)
    return
        map {
            "body": $doc,
            "headers": map {
                "media-type": $responseMediaType
            }
        }
};

(:~
 :  DTS Collection endpoint
 :)
declare function api-dts:dts-collection($model as map(*)) as map(*) {
    let $id.map :=
        if(map:contains($model, 'id')) then api-dts:decode-dts-id($model?id)
        else api-dts:encode-dts-id($api-dts:rootCollectionLabel, ()) => api-dts:decode-dts-id()
    let $offset :=
        if($model?page) then ($model?page - 1) * $api-dts:max-limit + 1
        else 1
    let $body := 
        if($id.map?dtsType eq 'Resource') 
        then $id.map?func($model("openapi:config"))
        else $id.map?func($offset, $api-dts:max-limit, api-dts:encode-dts-id#2, api-dts:endpoint-template(config:api-base($model("openapi:config")), ?, ?))
    return
        map {
            "body": $body 
                => map:put("@context", "https://dtsapi.org/context/v1.0.json")
                => map:put("dtsVersion", "1.0"),
            "headers": map {
                    "media-type": "application/ld+json"
                }
        }
};


declare %private function api-dts:create-root-collection(
    $offset as xs:int, $limit as xs:int, 
    $encode-dts-id as function(xs:string) as xs:string, 
    $collection-endpoint-template as function(xs:string) as xs:string) as map(*) {
        let $member :=
            for $m in $api-dts:collections
            order by $m
            return $m
        let $memberArray := 
            array {
                for $m in subsequence($member, $offset, $limit)
                let $id.map := 
                    api-dts:encode-dts-id($m, ())
                    => api-dts:decode-dts-id()
                return $id.map?func($offset, 0, api-dts:encode-dts-id#2, $collection-endpoint-template) 
            }
        let $dtsID := api-dts:encode-dts-id($api-dts:rootCollectionLabel, ())
        return
             map {
                "@id": $dtsID,
                "@type": "Collection",
                "collection": $collection-endpoint-template($dtsID),
                "title": $api-dts:rootCollectionLabel,
                "description": "The root collection of the digital edition of the Carl-Maria-von-Weber-Gesamtausgabe (WeGA)",
                "totalChildren": count($member),
                "totalParents": 0,
                "member": $memberArray
             }
};


declare function api-dts:endpoint-template($api-base as xs:string, $dtsID as xs:string, $endpoint as xs:string) as xs:string {
    $api-base || "/dts/" || $endpoint || "?id=" || $dtsID ||  "{&amp;page,nav}"
};

(:~
 :  Encode collection and subcollection labels to a DTS ID
 :
 :  @param $collectionLabel the first level collection label, e.g. "letters", "writings"
 :  @param $subcollectionLabel the second level collection label, e.g. "A002068"
 :  @return a base64 encoded string that can be used as a DTS ID for the collection endpoint
 :)
declare function api-dts:encode-dts-id($collectionLabel as xs:string?, $subcollectionLabel as xs:string?) as xs:string {
    string-join(($collectionLabel, $subcollectionLabel), '#') => encode-for-uri()
};

(:~
 :  Decode a DTS ID to its individual parts
 :
 :  @param $dtsID the DTS ID
 :  @return a map with the keys {collectionLabel|subcollectionLabel|dtsID|func} where
 :      collectionLabel = the first level of the collection (e.g. "wega", "documents", "letters", etc.),
 :      subcollectionLabel = the second level of the collection (e.g. "indices", "A002068", etc.),
 :      dtsID = the original, encoded DTS ID,
 :      func = function to generate the response
 :)
declare function api-dts:decode-dts-id($dtsID as xs:string?) as map(*)? {
    let $parts := $dtsID => xmldb:decode() => tokenize('#')
    let $doc.wega := 
        try { query:doc-by-any-id($parts[1]) }
        catch query:UnsupportedIDSchema {()}
    let $func :=
        switch(count($parts))
        case 2 return 
            try { wdt:lookup($parts[1], ())?dtsSubcollection(?,?,?,?,$parts[2]) }
            catch * {()}
        case 1 return 
            if($parts[1] eq $api-dts:rootCollectionLabel)
            then api-dts:create-root-collection#4
            else if($parts[1] = $api-dts:collections)
            then
                try { wdt:lookup($parts[1], ())?dtsCollection }
                catch * {()}
            else if($doc.wega)
            then api-dts:collection-resource($doc.wega, ?)
            else ()
        default return ()
    let $dtsType :=
        if($doc.wega)
        then 'Resource'
        else 'Collection'
    return
        if(exists($func))
        then
            map {
                "collectionLabel": $parts[1],
                "subcollectionLabel": $parts[2],
                "dtsID": $dtsID,
                "dtsType": $dtsType,
                "func": $func
            }
        else error($api-dts:INVALID_COLLECTION_ID, 'Invalid collection ID "' || $dtsID || '"')
};

(:~
 :  Return metadata object for a `Resource`
 :
 :  @param $doc the TEI or MEI document
 :  @param $openapi-conf the OpenAPI configuration as a map,
 :      needed to compute the API base URL and the
 :      available media types for the document endpoint
 :  @return a map object adhering to the DTS scheme for
 :      collection API Responses of type `Resource`
 :)
declare %private function api-dts:collection-resource($doc as document-node(), $openapi-conf as map(*)) as map(*) {
    let $docID := $doc/*/data(@xml:id)
    let $api.base := config:api-base($openapi-conf) 
    let $collection.endpoint := $api.base || "/dts/collection?id=" || $docID 
    let $navigation.endpoint := $api.base || "/dts/navigation?resource=" || $docID || "{&amp;ref}"
    let $document.endpoint := $api.base || "/dts/document?resource=" || $docID || "{&amp;ref,start,end}"
    let $docType := config:get-doctype-by-id($docID)
    let $model := 
        map {
            "doc": $doc,
            "docID": $docID,
            "docType": $docType
        }
    let $lod.metadata := lod:metadata(<head/>, $model, $api-dts:lang) 
    return
    map {
            "@context": "https://dtsapi.org/context/v1.0.json",
            "@id": $docID,
            "@type": "Resource",
            "dtsVersion": "1.0",
            "title": $lod.metadata?meta-page-title,
            "totalParents": "to be computed",
            "description": $lod.metadata?DC.description,
            "collection": $collection.endpoint,
            "navigation": $navigation.endpoint,
            "document": $document.endpoint,
            "mediaTypes": array { $api-dts:mediaTypes($openapi-conf) }
        }
};


declare %private function api-dts:process-xml-document($doc as document-node(), $format as xs:string) as item()? {
    let $TEIversion := $gl:main-source/tei:TEI/processing-instruction('TEIVERSION')/analyze-string(., '\d+\.\d+\.\d+')/fn:match/text()
    let $availableTransformations := xmldb:get-child-resources($config:xsl-external-schemas-collection-path) ! (substring-before(substring-after(., 'to-'), '.xsl')) 
    let $doc.transformed := 
        if($format = $availableTransformations)
        then
            wega-util:transform(
                $doc, 
                doc($config:xsl-external-schemas-collection-path || '/to-' || $format || '.xsl'), 
                config:get-xsl-params( map { 'current-tei-version': $TEIversion, 'facsimileGreenList': config:get-option('facsimileGreenList') } )
            )
        else error($api-dts:UNSUPPORTED_TRANSFORMATION, "No transformation available for `" || $format || "`." )
    return
        if($format eq "text")
        then api-dts:create-text-header($doc) || '&#10;&#10;' || string-join($doc.transformed, ' ')
        else document { wega-util:process-xml-for-display($doc.transformed) => wega-util:inject-version-info() }
};

(:~
 : Check parameter resource
 : only one value allowed
~:)
declare function api-dts:validate-resource($model as map(*)) as map(*)? {
    if($model?resource castable as xs:string) then $model
    else error($api-dts:INVALID_PARAMETER, "Unsupported value for parameter 'resource'." )
};

(:~
 : Check parameter mediaType
 : only one value allowed
~:)
declare function api-dts:validate-mediaType($model as map(*)) as map(*)? {
    if($model?mediaType castable as xs:string and $model?mediaType = $api-dts:mediaTypes($model('openapi:config'))) then $model
    else error($api-dts:INVALID_PARAMETER, "Unsupported value for parameter 'mediaType'." )
};

(:~
 : Check parameter id
 : only one value allowed
~:)
declare function api-dts:validate-id($model as map(*)) as map(*)? {
    if($model?id castable as xs:string) then $model
    else error($api-dts:INVALID_PARAMETER, "Unsupported value for parameter 'id'." )
};

(:~
 : Check parameter page
 : only one value allowed
~:)
declare function api-dts:validate-page($model as map(*)) as map(*)? {
    if($model?page castable as xs:positiveInteger) then $model
    else error($api-dts:INVALID_PARAMETER, "Unsupported value for parameter 'page'." )
};

(:~
 : Check parameter nav
 : only one value allowed
~:)
declare function api-dts:validate-nav($model as map(*)) as map(*)? {
    if($model?nav castable as xs:string and $model?nav=("parents", "children")) then $model
    else error($api-dts:INVALID_PARAMETER, "Unsupported value for parameter 'nav'." )
};

declare %private function api-dts:set-headers($headers as map(*)?) as empty-sequence()  {
    response:set-header("cache-control","max-age=0, no-cache, no-store"),
    response:set-header("Access-Control-Allow-Origin", "*"),
    response:set-header("pragma","no-cache"),
    if($headers instance of map(*))
    then map:keys($headers) ! response:set-header(., $headers(.))
    else ()
};

(:~
 :  Helper function for `api-dts:process-xml-document#2`
 :)
declare %private function api-dts:create-text-header($doc as document-node()) as xs:string {
    let $docID := $doc/*/data(@xml:id)
    let $model := 
        map { 
            'lang': $api-dts:lang,
            'docID': $docID,
            'doc': $doc,
            'docType': config:get-doctype-by-id($docID)
        }
    let $lod := lod:metadata(<head/>, $model, $api-dts:lang)
    let $author := '## Author: ' || query:get-authorName($doc)
    let $title := '## Title: ' || $lod?meta-page-title
    let $version := '## Version: ' || config:expath-descriptor()/@version
    let $origin := '## Origin: ' || config:permalink($docID)
    let $license := '## License: ' || $lod?DC.rights
    return
        string-join(($title,$author,$version,$origin,$license), '&#10;')
};
