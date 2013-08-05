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

declare variable $local:data-collections := ('biblio', 'diaries', 'iconography', 'letters', 'news', 'odd', 'persons', 'var', 'works', 'writings');
declare variable $local:webapp-collection := 'webapp';

declare function local:set-collection-permissions($collection-uri as xs:string, $user-id as xs:string, $group-id as xs:string, $permissions as xs:integer, $recursive as xs:boolean) as empty() {
    let $setFilePermissions := 
        for $file in xmldb:get-child-resources($collection-uri)
        return 
            if(ends-with($file, 'xql')) then xmldb:set-resource-permissions($collection-uri, $file, $user-id, $group-id, util:base-to-integer(755, 8)) (: make XQueries executable :)
            else xmldb:set-resource-permissions($collection-uri, $file, $user-id, $group-id, $permissions)
    let $setCollectionPermission := xmldb:set-collection-permissions($collection-uri, $user-id, $group-id, $permissions)
    return 
        if($recursive) then 
            for $coll in xmldb:get-child-collections($collection-uri)
            return local:set-collection-permissions(string-join(($collection-uri, $coll), '/'), $user-id, $group-id, $permissions, $recursive)
        else ()
};

(: set all data collections and resources recursively to admin:dba with 744 :)
for $coll in $local:data-collections return 
    local:set-collection-permissions(concat('/db/', $coll), 'admin', 'dba', util:base-to-integer(744, 8), true()),

(: set webapp collection to admin:dba with 755 :)
local:set-collection-permissions(concat('/db/', $local:webapp-collection), 'admin', 'dba', util:base-to-integer(755, 8), true()),

(: create temporary collection if not available:)
if(xmldb:collection-available(string-join(('/db', $local:webapp-collection, 'tmp'), '/'))) then ()
else xmldb:create-collection(string-join(('/db', $local:webapp-collection), '/'), 'tmp'),

(: set special permissions for temporary collections and resources :)
local:set-collection-permissions('/db/webapp/tmp', 'guest', 'guest', util:base-to-integer(744, 8), true())
