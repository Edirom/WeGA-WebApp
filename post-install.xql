xquery version "1.0";

import module namespace xdb="http://exist-db.org/xquery/xmldb";
import module namespace sm="http://exist-db.org/xquery/securitymanager";
(: need to import core module here for logging in config module :)
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "modules/core.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "modules/config.xqm";

(: The following external variables are set by the repo:deploy function :)

(: file path pointing to the exist installation directory :)
declare variable $home external;
(: path to the directory containing the unpacked .xar package :)
declare variable $dir external;
(: the target collection into which the app is deployed :)
declare variable $target external;

declare function local:mkcol-recursive($collection, $components) {
    if (exists($components)) then
        let $newColl := concat($collection, "/", $components[1])
        return (
            xdb:create-collection($collection, $components[1]),
            local:mkcol-recursive($newColl, subsequence($components, 2))
        )
    else
        ()
};

declare function local:set-options() as item()* {
    for $opt in available-environment-variables()[starts-with(., 'WEGA_WEBAPP_')]
    return
        if(starts-with($opt, 'WEGA_WEBAPP_OPENAPI_'))
        then config:set-openapi-option(substring($opt, 21), string(environment-variable($opt)))
        else config:set-option(substring($opt, 13), string(environment-variable($opt)))
};

(: Helper function to recursively create a collection hierarchy. :)
declare function local:mkcol($collection, $path) {
    local:mkcol-recursive($collection, tokenize($path, "/"))
};

(: create tmp collection for caching all sorts of downloaded files :)
sm:chown(xs:anyURI(xdb:create-collection($target, 'tmp')), 'guest'),

(: create a logs collection for upload of ANT logs (only needed for development) :)
sm:chown(xs:anyURI(xdb:create-collection(concat($target, '/tmp'), 'logs')), 'guest'),

(: set options passed as environment variables :)
local:set-options(),

(: store the collection configuration :)
local:mkcol("/db/system/config", $target), 
xdb:store-files-from-pattern(concat("/system/config", $target), concat($dir, '/indices'), "**/*.xconf", (), true()),
xdb:reindex($target)
