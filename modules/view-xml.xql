xquery version "3.0" encoding "UTF-8";

import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";

declare option exist:serialize "method=xml media-type=application/octet-stream";

let $content := core:doc(request:get-attribute('resource'))
return
    $content