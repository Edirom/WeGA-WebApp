xquery version "3.1" encoding "UTF-8";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "modules/config.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "modules/lang.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/str.xqm";
import module namespace search="http://xquery.weber-gesamtausgabe.de/modules/search" at "modules/search.xqm";
import module namespace controller="http://xquery.weber-gesamtausgabe.de/modules/controller" at "modules/controller.xqm";
import module namespace functx="http://www.functx.com";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;

let $lang := config:guess-language(())
let $exist-vars := map {
    'exist:path' : $exist:path,
    'exist:resource' : $exist:resource,
    'exist:controller' : $exist:controller,
    'exist:prefix' : $exist:prefix,
    'lang' : $lang
    }

return (

(: Wenn kein Apache vorgeschaltet ist, dann hier die Verzeichnisse css, jscript, pix auf den eXist-Jetty durchgeben :)
if(contains($exist:path, '/$resources/')) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{concat($exist:controller, '/resources/', substring-after($exist:path, '/$resources/'))}">
            <set-header name="Cache-Control" value="max-age=3600,public"/>
        </forward>
    </dispatch>

else if(starts-with($exist:path, '/resources/')) then response:set-header('Cache-Control', 'max-age=3600,public') 

else if(starts-with($exist:path, '/digilib/')) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <ignore/>
    </dispatch>

(: 
 :  Startseiten-Weiterleitung 1
 :  Nackte Server-URL (evtl. mit Angabe der Sprache)
:)
else if (matches($exist:path, '^/?(en/?|de/?)?$')) then
    controller:redirect-absolute('/' || $lang || '/Index')

(: 
 :  Startseiten-Weiterleitung 2
 :  Diverse Index Variationen
 :  Achtung: .php hier nicht aufnehmen, dies wird mit den typo3ContentMappings abgefragt
:)
else if (matches($exist:path, '^/[Ii]ndex(\.(htm|html|xml)|/)?$')) then
    controller:redirect-absolute('/' || $lang || '/Index')
        
else if (matches($exist:path, '^/(en/|de/)(Index)?$')) then
    controller:forward-html('/templates/index.html', map:merge(($exist-vars, map:entry('docID', 'home'))))

(:
 : Virtual directory structure for persons:
 : |- A002068.xml
 : |- A002068.html
 : |- A002068.json
 : |- A002068
 :      |- adb.html
 :      |- wikipedia.html
 :      |- dnb.html
 :      |- xml.html
 :      |- popover.html
 :      |- Korrespondenz
 :      |- Tagebücher
 :      |- Biographie.html (nur bei Weber)
 :
 :)

(:~
 : Resolving von allen Dokument-IDs, die als resource angesprochen werden,
 : d.h. letzer Teil des URL-Pfades sind.
 :)    
else if (matches($exist:resource, '^' || config:get-option('generalIdPattern') || '(\.\w{3,6})?$')) then 
    controller:dispatch($exist-vars)
    
(:
 : Weiterleitung für AJAX requests (alles unterhalb von templates/ajax)
 : Caching muss unterbunden werden
 :)
else if ($exist:resource = xmldb:get-child-resources($config:app-root || '/templates/ajax')) then 
    controller:forward-html('/templates/ajax/' || $exist:resource, map:merge(($exist-vars, map:entry('docID', functx:substring-after-last(functx:substring-before-last($exist:path, '/'), '/')))))

(: Suche :)
else if (matches($exist:path, concat('^/', $lang, '/', lang:get-language-string('search', $lang), '/?$'))) then
   (: Shortcut for IDs, given as query string :)
   if(config:get-combined-doctype-by-id(str:normalize-space(str:sanitize(string-join(request:get-parameter('q', ''), ' ')))) = ($search:wega-docTypes, 'var', 'addenda')) then controller:dispatch(map:put($exist-vars, 'exist:resource', str:normalize-space(str:sanitize(string-join(request:get-parameter('q', ''), ' ')))))
   else controller:forward-html('/templates/search.html', map:merge(($exist-vars, map:entry('docID', 'search'))))

(: Register :)
else if (contains($exist:path, concat('/', lang:get-language-string('indices', $lang)))) then
    controller:dispatch-register($exist-vars)

(: Guidelines – need to go before the general 'project' dispatch :)
else if (contains($exist:path, concat('/', replace(lang:get-language-string('editorialGuidelines-text', $lang), '\s+', '_'), '/'))) then 
    controller:dispatch-editorialGuidelines-text($exist-vars)
    
(: Projekt :)
else if (contains($exist:path, concat('/', lang:get-language-string('project', $lang), '/', $exist:resource))) then
    controller:dispatch-project($exist-vars)

(: Help :)
else if (contains($exist:path, concat('/', lang:get-language-string('help', $lang), '/', $exist:resource))) then
    controller:dispatch-help($exist-vars)

(: Korrespondenz :)
else if (matches($exist:path, config:get-option('personsPlusIdPattern') || '/' || lang:get-language-string('correspondence', $lang) || '/?$')) then
    controller:redirect-absolute('/' || replace($exist:path, '/' || lang:get-language-string('correspondence', $lang), '.html#correspondence'))

(: Tagebücher :)
else if (matches($exist:path, config:get-option('personsIdPattern') || '/' || controller:url-encode(lang:get-language-string('diaries', $lang)) || '/?$')) then
    controller:redirect-absolute('/' || replace($exist:path, '/' || controller:url-encode(lang:get-language-string('diaries', $lang)), '.html#diaries'))

(: Schriften :)
else if (matches($exist:path, config:get-option('personsPlusIdPattern') || '/' || lang:get-language-string('writings', $lang) || '/?$')) then
    controller:redirect-absolute('/' || replace($exist:path, '/' || lang:get-language-string('writings', $lang), '.html#writings'))

(: Werke :)
else if (matches($exist:path, config:get-option('personsPlusIdPattern') || '/' || lang:get-language-string('works', $lang) || '/?$')) then
    controller:redirect-absolute('/' || replace($exist:path, '/' || lang:get-language-string('works', $lang), '.html#works'))

(: Bibliographie :)
else if (matches($exist:path, config:get-option('personsPlusIdPattern') || '/' || lang:get-language-string('biblio', $lang) || '/?$')) then
    controller:redirect-absolute('/' || replace($exist:path, '/' || lang:get-language-string('biblio', $lang), '.html#biblio'))

(: News :)
else if (matches($exist:path, config:get-option('personsPlusIdPattern') || '/' || lang:get-language-string('news', $lang) || '/?$')) then
    controller:redirect-absolute('/' || replace($exist:path, '/' || lang:get-language-string('news', $lang), '.html#news'))

(: Themenkommentare :)
else if (matches($exist:path, config:get-option('personsPlusIdPattern') || '/' || controller:url-encode(lang:get-language-string('thematicCommentaries', $lang)) || '/?$')) then
    controller:redirect-absolute('/' || replace($exist:path, '/' || controller:url-encode(lang:get-language-string('thematicCommentaries', $lang)), '.html#thematicCommentaries'))

(: Dokumente :)
else if (matches($exist:path, config:get-option('personsPlusIdPattern') || '/' || lang:get-language-string('documents', $lang) || '/?$')) then
    controller:redirect-absolute('/' || replace($exist:path, '/' || lang:get-language-string('documents', $lang), '.html#documents'))
    
(: IIIF manifest meta data :)
else if (matches($exist:path, '/IIIF/' || config:get-option('generalIdPattern') || '(.*)/manifest.json')) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{concat($exist:controller, '/modules/view-json.xql')}">
            <set-attribute name="docID" value="{substring(substring-after($exist:path, 'IIIF/'), 1, 7)}"/>
            <set-attribute name="sourceID" value="{substring(substring-after(substring-before($exist:path, '/manifest.json'), 'IIIF/'), 8)}"/>
            <set-attribute name="type" value="manifest"/>
        </forward>
    </dispatch>

(: IIIF collection meta data :)
(:else if (matches($exist:path, '/IIIF/letters/collection.json')) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{concat($exist:controller, '/modules/view-json.xql')}">
            <set-attribute name="docID" value="letters"/>
            <set-attribute name="type" value="collection"/>
        </forward>
    </dispatch>
:)
(: Ausführliche Weber-Biographie :)
else if ($exist:path eq '/en/A002068/Biography.html' or $exist:path eq '/de/A002068/Biographie.html') then
    controller:forward-html('/templates/var.html', map:merge(($exist-vars, map:entry('docID', 'A070003'), map:entry('docType', 'var'))))

(: Bartlitz Sonderband :)
else if ($exist:path eq '/de/Sonderband.html' or $exist:path eq '/en/Special_Volume.html') then
    controller:forward-html('/templates/var.html', map:merge(($exist-vars, map:entry('docID', 'A070090'), map:entry('docType', 'var'))))
    
(: Weber-Studien Einzelansicht:)
(:else if ($isWeberPublication and matches($exist:path, concat('^/', $lang, '/', $publications, '/', $weberStudies, '/', 'A11\d{4}/?$'))) then
    let $js := if(request:get-parameter-names() = $ajaxCrawlerParameter) then 'false' else 'true'
    return
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="{concat($exist:controller, '/modules/var.xql')}">
    	   <add-parameter name="lang" value="{$lang}"/>
    	   <add-parameter name="docID" value="{$exist:resource}"/>
    	   <add-parameter name="js" value="{$js}"/>
    	</forward>
    </dispatch>:)

(: GND Resolver :)
else if (matches($exist:path, concat('^/', $lang, '/[pg]nd/', '[-0-9X]+(\.\w+)?$'))) then
    controller:redirect-by-gnd($exist-vars)

(: PND Beacon :)
else if (matches($exist:path, '^/pnd_beacon.txt$')) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="{concat($exist:controller, '/modules/beacon.xql')}">
    	   <set-attribute name="beacon" value="pnd"/>
    	   <cache-control cache="yes"/>
    	</forward>
    </dispatch>

(: GKD Beacon :)
else if (matches($exist:path, '^/gkd_beacon.txt$')) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="{concat($exist:controller, '/modules/beacon.xql')}">
    	   <set-attribute name="beacon" value="gkd"/>
    	   <cache-control cache="yes"/>
    	</forward>
    </dispatch>

(: Works Beacon :)
else if (matches($exist:path, '^/works_beacon.txt$')) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="{concat($exist:controller, '/modules/beacon.xql')}">
    	   <set-attribute name="beacon" value="works"/>
    	   <cache-control cache="yes"/>
    	</forward>
    </dispatch>
    
(: correspDesc Beacon :)
else if (matches($exist:path, '^/correspDesc.xml$')) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="{concat($exist:controller, '/modules/correspDesc.xql')}">
    	   <cache-control cache="yes"/>
    	</forward>
    </dispatch>
    
(: Sitemap :)
else if (matches($exist:path, '^/sitemap(/?|/index.xml)?$') or matches($exist:path, '^/sitemap/sitemap_(en|de).xml.(gz|zip)$')) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="{concat($exist:controller, '/modules/sitemap.xql')}">
    	   <add-parameter name="lang" value="{$lang}"/>
    	   <add-parameter name="resource" value="{$exist:resource}"/>
    	</forward>
    </dispatch>

(: JMX Statusinformationen :)
else if ($config:isDevelopment and $exist:path eq '/status') then 
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <ignore/>
    </dispatch>

(: Favicon redirects. Need to go after IIIF redirects! :)
else if ($exist:resource = xmldb:get-child-resources($config:app-root || '/resources/favicons')) then 
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{concat('resources/favicons/', $exist:resource)}"/>
    </dispatch>


(: Schemata zum Download :)
(: Redirect latest to Github :)
(:
else if (matches($exist:path, '^/schema/latest/')) then 
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{concat('https://raw.githubusercontent.com/Edirom/WeGA-ODD/master/schema/', substring-after($exist:path, '/schema/latest/'))}"/>
    </dispatch>

else if (matches($exist:path, '^/schema/v\d+\.\d+\.\d+/')) then 
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{concat($exist:controller, '/modules/schema.xql')}">
    	   <add-parameter name="exist.path" value="{$exist:path}"/>
    	</forward>
        <error-handler>
            {controller:error($exist-vars, 404)/exist:forward}
		</error-handler>
    </dispatch>
:)

(: general forwarding of folder 'dev' for development XQueries :)
else if($config:isDevelopment and starts-with($exist:path, '/dev/')) then 
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{concat($exist:controller, '/modules/dev/', $exist:resource)}"/>
    </dispatch>

(: general forwarding of folder '/de/dev' for development HTML pages :)
else if($config:isDevelopment and starts-with($exist:path, '/de/dev/')) then 
    controller:forward-html('/templates/dev/' || $exist:resource, $exist-vars)
    
else if($config:isDevelopment and starts-with($exist:path, '/logs/')) then 
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{concat($exist:controller, '/tmp/logs/', $exist:resource)}">
            <set-header name="Content-Type" value="text/plain"/>
        </forward>
    </dispatch>

(: typo3ContentMappings :)
else if($exist:resource = 'index.php') then controller:lookup-typo3-mappings($exist-vars)

else if(matches($exist:path, '^/api/?$')) then 
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{config:api-base(())}"/>
    </dispatch>

else controller:lookup-url-mappings($exist-vars)

)
