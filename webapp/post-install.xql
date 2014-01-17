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

(: create tmp collection for caching all sorts of downloaded files :)
sm:chown(xs:anyURI(xdb:create-collection($target, 'tmp')), 'guest')
