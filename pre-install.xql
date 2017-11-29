xquery version "1.0";

import module namespace xdb="http://exist-db.org/xquery/xmldb";
import module namespace sm="http://exist-db.org/xquery/securitymanager";

(: The following external variables are set by the repo:deploy function :)

(: file path pointing to the exist installation directory :)
declare variable $home external;
(: path to the directory containing the unpacked .xar package :)
declare variable $dir external;
(: the target collection into which the app is deployed :)
declare variable $target external;

(:~
 : Need to remove the RestXQ trigger due to a bug with circular module imports,
 : see https://github.com/eXist-db/exist/issues/1010 and http://markmail.org/message/jmftuswia4icviht
~:)
if(doc-available('/db/system/config/db/collection.xconf')) then
    xdb:remove('/db/system/config/db', 'collection.xconf')
else ()
