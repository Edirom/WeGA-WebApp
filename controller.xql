xquery version "3.0" encoding "UTF-8";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "modules/query.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "modules/config.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "modules/core.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "modules/lang.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "modules/str.xqm";
import module namespace controller="http://xquery.weber-gesamtausgabe.de/modules/controller" at "modules/controller.xqm";
import module namespace functx="http://www.functx.com";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;

let $params := tokenize($exist:path, '/')
let $lang := lang:get-set-language($params[2])
let $exist-vars := map {
    'path' := $exist:path,
    'resource' := $exist:resource,
    'controller' := $exist:controller,
    'prefix' := $exist:prefix,
    'lang' := $lang
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
    controller:forward-html('/templates/index.html', map:new(($exist-vars, map:entry('docID', 'home'))))

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

(: Generelle Weiterleitung für Ressourcen :)    
else if (matches($exist:resource, 'A\d{2}[0-9A-F]{4}')) then 
    controller:dispatch($exist-vars)
    
(:
 : Weiterleitung für AJAX requests (alles unterhalb von templates/ajax)
 : Caching muss unterbunden werden
 :)
else if ($exist:resource = xmldb:get-child-resources($config:app-root || '/templates/ajax')) then 
    controller:forward-html('/templates/ajax/' || $exist:resource, map:new(($exist-vars, map:entry('docID', functx:substring-after-last(functx:substring-before-last($exist:path, '/'), '/')))))
    

(:~
 : The CMIF Output of the letters (has to go before the generic *.xml rule) 
~:)
else if ($exist:resource = 'correspDesc.xml') then 
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{map:get($exist-vars, 'controller') || '/modules/correspDesc.xql'}"/>
    </dispatch>

(:
 : XML-Resources
 :)
(:else if (ends-with($exist:resource, '.xml')) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{map:get($exist-vars, 'controller') || '/modules/view-xml.xql'}">
            <set-attribute name="resource" value="{substring-before($exist:resource, '.xml')}"/>
        </forward>
    </dispatch>:)

    
(: Suche :)
else if (matches($exist:path, concat('^/', $lang, '/', lang:get-language-string('search', $lang), '/?$'))) then
   (: Shortcut for IDs, given as query string :)
   if(config:get-doctype-by-id(str:sanitize(string-join(request:get-parameter('q', ''), ' '))) = ('letters','writings','persons','news','diaries')) then controller:dispatch(map:put($exist-vars, 'resource', str:sanitize(string-join(request:get-parameter('q', ''), ' '))))
   else controller:forward-html('/templates/search.html', $exist-vars)

(: Register :)
else if (contains($exist:path, concat('/', lang:get-language-string('indices', $lang)))) then
    controller:dispatch-register($exist-vars)

(: Projekt :)
else if (contains($exist:path, concat('/', lang:get-language-string('project', $lang), '/', $exist:resource))) then
    controller:dispatch-project($exist-vars)

(: Help :)
else if (matches($exist:path, concat('^/', $lang, '/', lang:get-language-string('help', $lang), '/?$'))) then
    controller:forward-html('/templates/var.html', map:new(($exist-vars, map:entry('docID', 'A070004'), map:entry('docType', 'var'))))

(: Korrespondenz :)
else if (matches($exist:path, 'A00[A-F0-9]{4}/' || lang:get-language-string('correspondence', $lang) || '/?$')) then
    controller:redirect-absolute(replace($exist:path, '/' || lang:get-language-string('correspondence', $lang), '.html#correspondence'))

(: Tagebücher :)
else if (matches($exist:path, 'A00[A-F0-9]{4}/' || encode-for-uri(lang:get-language-string('diaries', $lang)) || '/?$')) then
    controller:redirect-absolute(replace($exist:path, '/' || encode-for-uri(lang:get-language-string('diaries', $lang)), '.html#diaries'))

(: Schriften :)
else if (matches($exist:path, 'A00[A-F0-9]{4}/' || lang:get-language-string('writings', $lang) || '/?$')) then
    controller:redirect-absolute(replace($exist:path, '/' || lang:get-language-string('writings', $lang), '.html#writings'))

(: Werke :)
else if (matches($exist:path, 'A00[A-F0-9]{4}/' || lang:get-language-string('works', $lang) || '/?$')) then
    controller:redirect-absolute(replace($exist:path, '/' || lang:get-language-string('works', $lang), '.html#works'))

(: Bibliograpie :)
else if (matches($exist:path, 'A00[A-F0-9]{4}/' || lang:get-language-string('biblio', $lang) || '/?$')) then
    controller:redirect-absolute(replace($exist:path, '/' || lang:get-language-string('biblio', $lang), '.html#biblio'))

(: News :)
else if (matches($exist:path, 'A00[A-F0-9]{4}/' || lang:get-language-string('news', $lang) || '/?$')) then
    controller:redirect-absolute(replace($exist:path, '/' || lang:get-language-string('news', $lang), '.html#news'))

(: IIIF manifest meta data :)
else if (matches($exist:path, '/IIIF/A[0-9A-F]{6}/manifest.json')) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{map:get($exist-vars, 'controller') || '/modules/view-json.xql'}">
            <set-attribute name="docID" value="{substring-after(substring-before($exist:path, '/manifest.json'), 'IIIF/')}"/>
            <set-attribute name="type" value="manifest"/>
        </forward>
    </dispatch>

(: IIIF resource meta data :)
(:else if (matches($exist:path, '/IIIF/A[0-9A-F]{6}/[^/]+/info.json')) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{map:get($exist-vars, 'controller') || '/modules/view-json.xql'}">
            <set-attribute name="docID" value="{substring-before(substring-after($exist:path, 'IIIF/'), '/')}"/>
            <set-attribute name="image" value="{functx:substring-after-last(util:unescape-uri(substring-before($exist:path, '/info.json'), 'UTF-8'), '/')}"/>
            <set-attribute name="type" value="resource"/>
        </forward>
    </dispatch>:)
    
(:else if (contains($exist:path, '/IIIF') and $exist:resource eq 'level0.json') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{map:get($exist-vars, 'controller') || '/templates/ajax/dnb.html'}"/>
        <view>
            <forward url="{map:get($exist-vars, 'controller') || '/modules/view-json.xql'}">
                <set-attribute name="resource" value="{substring-before($exist:resource, '.json')}"/>
            </forward>
        </view>
    </dispatch>
    :)
else if (contains($exist:path, '/IIIF')) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="http://192.168.3.104:9091/digilib2.3.3/Scaler/IIIF{replace(substring-after($exist:path, 'IIIF'), 'default', 'native')}"/>
    </dispatch>

(: Editorial Guidelines :)
(:else if (matches($exist:path, concat('^/', $lang, '/', $editorialGuidelines, '/?$'))) then
    let $js := if(request:get-parameter-names() = $ajaxCrawlerParameter) then 'false' else 'true'
    return
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="{concat($exist:controller, '/modules/var.xql')}">
    	   <add-parameter name="lang" value="{$lang}"/>
    	   <add-parameter name="docID" value="A070001"/>
    	   <add-parameter name="createSecNos" value="true"/>
    	   <add-parameter name="js" value="{$js}"/>
    	</forward>
    </dispatch>:)

(: Editorial Guidelines Works :)
(:else if (matches($exist:path, concat('^/', $lang, '/', $editorialGuidelines-works, '/?$'))) then
    let $js := if(request:get-parameter-names() = $ajaxCrawlerParameter) then 'false' else 'true'
    return
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="{concat($exist:controller, '/modules/var.xql')}">
    	   <add-parameter name="lang" value="{$lang}"/>
    	   <add-parameter name="docID" value="A070010"/>
    	   <add-parameter name="createSecNos" value="true"/>
    	   <add-parameter name="js" value="{$js}"/>
    	</forward>
    </dispatch>:)
    
(: Impressum :)
(:else if ($exist:path eq '/en/About' or $exist:path eq '/de/Impressum') then
    let $js := if(request:get-parameter-names() = $ajaxCrawlerParameter) then 'false' else 'true'
    return
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="{concat($exist:controller, '/modules/var.xql')}">
    	   <add-parameter name="lang" value="{$lang}"/>
    	   <add-parameter name="docID" value="A070002"/>
    	   <add-parameter name="js" value="{$js}"/>
    	</forward>
    </dispatch>:)

(: Ausführliche Weber-Biographie :)
else if ($exist:path eq '/en/A002068/Biography.html' or $exist:path eq '/de/A002068/Biographie.html') then
    controller:forward-html('/templates/var.html', map:new(($exist-vars, map:entry('docID', 'A070003'), map:entry('docType', 'var'))))

(: Help :)
(:else if (matches($exist:path, concat('^/', $lang, '/', $help, '/?$'))) then
    let $js := if(request:get-parameter-names() = $ajaxCrawlerParameter) then 'false' else 'true'
    return
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="{concat($exist:controller, '/modules/var.xql')}">
    	   <add-parameter name="lang" value="{$lang}"/>
    	   <add-parameter name="docID" value="A070004"/>
    	   <add-parameter name="createSecNos" value="true"/>
    	   <add-parameter name="js" value="{$js}"/>
    	</forward>
    </dispatch>:)

(: Project Description :)
(:else if (matches($exist:path, concat('^/', $lang, '/', $projectDescription, '/?$'))) then
    let $js := if(request:get-parameter-names() = $ajaxCrawlerParameter) then 'false' else 'true'
    return
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="{concat($exist:controller, '/modules/var.xql')}">
    	   <add-parameter name="lang" value="{$lang}"/>
    	   <add-parameter name="docID" value="A070006"/>
    	   <add-parameter name="createSecNos" value="true"/>
    	   <add-parameter name="js" value="{$js}"/>
    	</forward>
    </dispatch>:)

(: Kontakt :)
(:else if (matches($exist:path, concat('^/', $lang, '/', wega:getVarURL('A070009',$lang), '/?$'))) then
    let $js := if(request:get-parameter-names() = $ajaxCrawlerParameter) then 'false' else 'true'
    return
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="{concat($exist:controller, '/modules/var.xql')}">
    	   <add-parameter name="lang" value="{$lang}"/>
    	   <add-parameter name="docID" value="A070009"/>
    	   <add-parameter name="js" value="{$js}"/>
    	</forward>
    </dispatch>:)

(: Editionsrichtlinien Werkausgabe :)
(:else if (matches($exist:path, concat('^/', $lang, '/', wega:getVarURL('A070010',$lang), '/?$'))) then
    let $js := if(request:get-parameter-names() = $ajaxCrawlerParameter) then 'false' else 'true'
    return
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="{concat($exist:controller, '/modules/var.xql')}">
    	   <add-parameter name="lang" value="{$lang}"/>
    	   <add-parameter name="docID" value="A070010"/>
    	   <add-parameter name="js" value="{$js}"/>
    	</forward>
    </dispatch>:)

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

(: Publikationen :)
(:else if (matches($exist:path, concat('^/', $lang,'/', $publications, '(/(', $weberStudies, '|', $musicVolumes, '|', $papers, '|', $talks, '))?$'))) then
    local:forwardIndices('publications', $lang):)


(: GND Resolver :)
else if (matches($exist:path, concat('^/', $lang, '/[pg]nd/', '[-0-9X]+$'))) then
    controller:redirect-by-gnd($exist-vars)

(: Shortcut für fffi-db :)
(:else if (matches($exist:path, '^/fffi-db[^/]*$')) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<redirect url="{str:join-path-elements(($lang, $search))}">
    	   <cache-control cache="yes"/>
    	</redirect>
    </dispatch>   :) 


(: PND Beacon :)
else if (matches($exist:path, '^/pnd_beacon.txt$')) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="{concat($exist:controller, '/modules/pnd_beacon.xql')}">
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

(:else if (matches($exist:path, '/webdav')) then 
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <ignore/>
    </dispatch>:)

(: Favicon redirect :)
else if ($exist:path eq '/favicon.ico') then 
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="resources/pix/weber_favicon.ico"/>
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

else controller:lookup-url-mappings($exist-vars)

)
