xquery version "3.0" encoding "UTF-8";

import module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util" at "wega-util.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";

declare option exist:serialize "method=xml media-type=application/tei+xml";

let $content := core:doc(request:get-attribute('resource'))
return
    wega-util:remove-comments($content)