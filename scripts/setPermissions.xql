xquery version "1.0" encoding "UTF-8";

(:~
: Set permissions for a production system
:
: @author Peter Stadler 
: @version 1.1
:)

declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";
declare namespace sm="http://exist-db.org/xquery/securitymanager";

declare variable $local:data-collections := ('biblio', 'diaries', 'iconography', 'letters', 'news', 'persons', 'var', 'webapp', 'works', 'writings');
declare variable $local:webapp-collection := 'webapp';

declare function local:set-collection-permissions($collection-uri as xs:string, $user-id as xs:string, $group-id as xs:string, $permissions as xs:string, $recursive as xs:boolean) as empty() {
    let $setCollectionPermission := local:set-combined-permissions($collection-uri, $user-id, $group-id, $permissions)
    let $setFilePermissions := 
        for $file in xmldb:get-child-resources($collection-uri)
        return 
            if(ends-with($file, 'xql')) then local:set-combined-permissions(concat($collection-uri, '/', $file), $user-id, $group-id, $permissions) (: make XQueries executable :)
            else local:set-combined-permissions(concat($collection-uri, '/', $file), $user-id, $group-id, '744')
    return 
        if($recursive) then 
            for $coll in xmldb:get-child-collections($collection-uri)
            return local:set-collection-permissions(string-join(($collection-uri, $coll), '/'), $user-id, $group-id, $permissions, $recursive)
        else ()
};

declare function local:set-combined-permissions($resource as xs:string, $user-id as xs:string, $group-id as xs:string, $permissions as xs:string) as empty() {
    if($resource castable as xs:anyURI) then (
        sm:chown(xs:anyURI($resource), $user-id),
        sm:chgrp(xs:anyURI($resource), $group-id),
        sm:chmod(xs:anyURI($resource), sm:octal-to-mode($permissions))
    )
    else ()
};

(: set all data collections and resources recursively to admin:dba with 755 :)
for $coll in $local:data-collections return 
    local:set-collection-permissions(concat('/db/', $coll), 'admin', 'dba', '755', true()),

(: create temporary collection if not available:)
if(xmldb:collection-available(string-join(('/db', $local:webapp-collection, 'tmp'), '/'))) then ()
else xmldb:create-collection(string-join(('/db', $local:webapp-collection), '/'), 'tmp'),

(: set special permissions for temporary collections and resources :)
local:set-collection-permissions('/db/webapp/tmp', 'guest', 'guest', '744', true())
