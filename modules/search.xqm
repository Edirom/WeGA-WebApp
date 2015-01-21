xquery version "3.0" encoding "UTF-8";

module namespace search="http://xquery.weber-gesamtausgabe.de/modules/search";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace templates="http://exist-db.org/xquery/templates";

import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";


(:~
 : All results
~:)
declare 
(:    %templates:default("page", "1"):)
    %templates:default("docType", "letters")
    %templates:wrap
    function search:results($node as node(), $model as map(*), $docType as xs:string) as map(*) {
        map {
            'search-results' := core:getOrCreateColl($docType, $model('docID'), true())
        }
};

declare 
    %templates:wrap
    function search:results-count($node as node(), $model as map(*)) as xs:string {
        count($model('search-results')) || ' Suchergebnisse'
};

(:~
 : results for one page
~:)
declare 
    %templates:wrap
    function search:result-page($node as node(), $model as map(*)) as map(*) {
        map {
            'result-page-entries' := subsequence($model('search-results'),1,10)
        }
};

(:~
 : Wrapper for dispatching various document types
 : Simply redirects to the right fragment from 'templates/includes'
 :
 :)
declare function search:dispatch-preview($node as node(), $model as map(*)) {
    let $docType := config:get-doctype-by-id($model('result-page-entry')/*/data(@xml:id))
    return
        templates:include($node, $model, 'templates/includes/preview-' || $docType || '.html')
};
