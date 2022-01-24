xquery version "3.0" encoding "UTF-8";

module namespace dev-app="http://xquery.weber-gesamtausgabe.de/modules/dev/dev-app";
(:~
 : App module for development pages
 :
 : @author Peter Stadler 
 : @version 1.0
 :)


declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace templates="http://exist-db.org/xquery/html-templating";
declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace repo="http://exist-db.org/xquery/repo";
import module namespace functx="http://www.functx.com";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/str.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "../config.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "../core.xqm";
import module namespace wdt="http://xquery.weber-gesamtausgabe.de/modules/wdt" at "../wdt.xqm";
import module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util" at "../wega-util.xqm";
import module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/date.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "../lang.xqm";

declare 
    %templates:wrap
    function dev-app:print-examples($node as node(), $model as map(*)) {
        let $key := $node/parent::xhtml:div/data(@id)
        let $hits := 
            switch($key) 
            case 'subst' return core:getOrCreateColl('letters', 'indices', true())//tei:subst/ancestor::tei:p
            case 'add' return core:getOrCreateColl('letters', 'indices', true())//tei:add[not(ancestor::tei:subst)]/ancestor::tei:p
            case 'del' return core:getOrCreateColl('letters', 'indices', true())//tei:del[not(ancestor::tei:subst)]/ancestor::tei:p
            case 'supplied' return core:getOrCreateColl('letters', 'indices', true())//tei:supplied/ancestor::tei:p
            case 'unclear' return core:getOrCreateColl('letters', 'indices', true())//tei:unclear[not(ancestor::tei:choice)]/ancestor::tei:p
            case 'underline1' return core:getOrCreateColl('letters', 'indices', true())//tei:hi[@rend='underline'][string(@n) = ('', '1')]/ancestor::tei:p
            case 'underline2' return core:getOrCreateColl('letters', 'indices', true())//tei:hi[@rend='underline'][@n > 1]/ancestor::tei:p
            case 'latintype' return core:getOrCreateColl('letters', 'indices', true())//tei:hi[@rend='latintype']/ancestor::tei:p
            case 'spaced_out' return core:getOrCreateColl('letters', 'indices', true())//tei:hi[@rend='spaced_out']/ancestor::tei:p
            default return ()
        let $hitsPerPage := 10
        let $maxStartOffset := ceiling(count($hits) div $hitsPerPage) - 1
        let $rand := util:random($maxStartOffset) + 1
        let $tei := <tei:body>{subsequence($hits, $rand, $hitsPerPage) ! <tei:div><tei:head>Beispiel aus {./ancestor::tei:TEI/data(@xml:id)} (<tei:rs key="{./ancestor::tei:TEI/data(@xml:id)}" type="letter">zum Brief</tei:rs>)</tei:head>{.}</tei:div>}</tei:body>
        return ( 
            <h2>{$node/parent::xhtml:div/data(@id)}</h2>,
            wega-util:transform($tei, doc(concat($config:xsl-collection-path, '/letters.xsl')), config:get-xsl-params(()))
        )
};

(:~
 : Get latest ANT log file
 :
 : @author Peter Stadler 
 : @return map with entries 'rev' and 'success'
 :)
declare 
    %templates:wrap
    function dev-app:ant-log($node as node(), $model as map(*)) as map(*) {
        let $rev := config:getCurrentSvnRev()
        return
            if($rev) then 
                map {
                    'ant-log-rev' : $rev,
                    'ant-log-success' : true(),
                    'ant-log-url' : 'https://ci.edirom.de/job/WeGA-update-development/'
                }
            else map {}
};

declare 
	%templates:wrap 
	function dev-app:app-status($node as node(), $model as map(*)) as map(*) {
	    map {
	        'deployment-date' : date:format-date(xs:dateTime($config:repo-descriptor/repo:deployed) cast as xs:date, $config:default-date-picture-string($model?lang), $model?lang)
	    }
};

declare
    %templates:wrap
    function dev-app:newID-docTypes($node as node(), $model as map(*)) as map() {
        let $wega-docTypes := for $func in wdt:members('unary-docTypes') return $func(())('name')
        return 
            map {
                'newID-docTypes' : $wega-docTypes
            }
};

declare
    %templates:wrap
    function dev-app:newID-option($node as node(), $model as map(*)) as element() {
        element { node-name($node) } {
            $node/@class,
            attribute value { $model?newID-docType },
            lang:get-language-string($model?newID-docType, $model?lang)
        }
};

declare
    %templates:wrap
    function dev-app:datatables($node as node(), $model as map(*)) as map() {
        map {'api-base' : config:api-base(())}
};
