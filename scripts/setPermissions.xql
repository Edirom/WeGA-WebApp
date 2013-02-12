xquery version "1.0" encoding "UTF-8";

(:~
: Set permissions for a production system
:
: @author Peter Stadler 
: @version 1.0
:)

declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";

declare function local:set-collection-permissions($collection-uri as xs:string, $user-id as xs:string, $group-id as xs:string, $permissions as xs:integer, $recursive as xs:boolean) as empty() {
    let $setFilePermissions := 
        for $file in xmldb:get-child-resources($collection-uri)
        return xmldb:set-resource-permissions($collection-uri, $file, $user-id, $group-id, $permissions)
    let $setCollectionPermission := xmldb:set-collection-permissions($collection-uri, $user-id, $group-id, $permissions)
    return 
        if($recursive) then 
            for $coll in xmldb:get-child-collections($collection-uri)
            return local:set-collection-permissions(string-join(($collection-uri, $coll), '/'), $user-id, $group-id, $permissions, $recursive)
        else ()
};

(: First, set all collections and resources recursively to admin:dba with 744 :)
local:set-collection-permissions('/db', 'admin', 'dba', util:base-to-integer(744, 8), true()),

(: Second, set special permissions for temporary collections and resources :)
local:set-collection-permissions('/db/webapp/tmp', 'guest', 'guest', util:base-to-integer(744, 8), true())
