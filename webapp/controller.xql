xquery version "1.0" encoding "UTF-8";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace wega="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/wega" at "xmldb:exist:///db/webapp/xql/modules/wega.xqm";
import module namespace functx="http://www.functx.com" at "xmldb:exist:///db/webapp/xql/modules/functx.xqm";

declare variable $exist:resource external;
declare variable $exist:path external;

declare function local:forwardIndices($menuID as xs:string, $lang as xs:string) as element() {
    let $menu := doc(wega:getOption('menusFile'))//id($menuID)
    let $displayName := 
        if($exist:resource eq wega:getLanguageString($menu/pageName, $lang)) then $menu/entry[1]/displayName/text() 
        else wega:reverseLanguageString($exist:resource, $lang)
        (:if($lang eq 'en') then $exist:resource
        else wega:translateLanguageString(xmldb:decode-uri(xs:anyURI($exist:resource)), $lang, 'en'):)
    let $docType := $menu/entry[./displayName eq $displayName]/docType/text()
(:    let $log := util:log-system-out($displayName):)
    return
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="/xql/register.xql">
    	   <add-parameter name="lang" value="{$lang}"/>
    	   <add-parameter name="docType" value="{$docType}"/>
    	   <add-parameter name="id" value="{$menuID}"/>
    	</forward>
    </dispatch>
};

let $params := tokenize($exist:path, '/')
let $lang := wega:getSetLanguage($params[2])
let $isFunc := matches($exist:path, '/functions/')
let $isUtil := matches($exist:path, '/utilities/')
let $isDoc := matches($exist:resource, 'A0[2-6]')
let $authorID := if($isDoc) then wega:getAuthorOfTeiDoc($exist:resource) else ()
let $isWeberPublication := if(wega:isBiblio($exist:resource)) then wega:isWeberStudies(wega:doc($exist:resource)) else false()
let $indices := if($isUtil or $isFunc) then () else wega:getLanguageString('indices', $lang)
let $persons := if($isUtil or $isFunc) then () else wega:getLanguageString('persons', $lang)
let $letters := if($isUtil or $isFunc) then () else wega:getLanguageString('letters', $lang)
let $correspondence := if($isUtil or $isFunc) then () else wega:getLanguageString('correspondence', $lang)
let $writings := if($isUtil or $isFunc) then () else wega:getLanguageString('writings',$lang)
let $diaries := if($isUtil or $isFunc) then () else encode-for-uri(wega:getLanguageString('diaries',$lang))
let $works := if($isUtil or $isFunc) then () else wega:getLanguageString('works',$lang)
let $news := if($isUtil or $isFunc) then () else wega:getLanguageString('news',$lang)
let $search := if($isUtil or $isFunc) then () else wega:getLanguageString('search',$lang)
let $help := if($isUtil or $isFunc) then () else wega:getLanguageString('help',$lang)
let $projectDescription := if($isUtil or $isFunc) then () else replace(wega:getLanguageString('projectDescription',$lang), '\s', '_')
let $weberStudies := if($isUtil or $isFunc) then () else wega:getLanguageString('weberStudies',$lang)
let $musicVolumes := if($isUtil or $isFunc) then () else encode-for-uri(wega:getLanguageString('musicVolumes',$lang))
let $papers := if($isUtil or $isFunc) then () else encode-for-uri(wega:getLanguageString('papers',$lang))
let $talks := if($isUtil or $isFunc) then () else encode-for-uri(wega:getLanguageString('talks',$lang))
let $publications := if($isUtil or $isFunc) then () else wega:getLanguageString('publications',$lang)
let $bibliography := if($isUtil or $isFunc) then () else wega:getLanguageString('bibliography',$lang)
let $literature := if($isUtil or $isFunc) then () else wega:getLanguageString('literature',$lang)
let $discography := if($isUtil or $isFunc) then () else wega:getLanguageString('discography',$lang)
let $scores := if($isUtil or $isFunc) then () else wega:getLanguageString('scores',$lang)
let $contact := if($isUtil or $isFunc) then () else wega:getLanguageString('contact',$lang)
let $tools := if($isUtil or $isFunc) then () else wega:getLanguageString('tools',$lang)
let $editorialGuidelines := if($isUtil or $isFunc) then () else replace(wega:getLanguageString('editorialGuidelines',$lang), '\s', '_')
let $ajaxCrawlerParameter := '_escaped_fragment_'
let $error404 := 
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="/xql/error.xql">
    	   <add-parameter name="errorCode" value="404"/>
    	   <add-parameter name="lang" value="{$lang}"/>
    	   <cache-control cache="yes"/>
    	</forward>
    </dispatch>

return (
if($isFunc) then  
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{concat('/xql/functions/', $exist:resource)}">
            <cache-control cache="yes"/>
        </forward>
    </dispatch>
    
else if($isUtil) then  
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{concat('/xql/utilities/', $exist:resource)}">
            <add-parameter name="lang" value="{$lang}"/>
            <cache-control cache="yes"/>
        </forward>
    </dispatch>

(: Wenn kein Apache vorgeschaltet ist, dann hier die Verzeichnisse css, jscript, pix auf den eXist-Jetty durchgeben :)
else if(matches($exist:path, 'css|jscript|pix|fonts')) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <ignore/>
    </dispatch>

(: 
 :  Startseiten-Weiterleitung 1
 :  Nackte Server-URL (evtl. mit Angabe der Sprache)
:)
else if (matches($exist:path, '^/?(en/?|de/?)?$')) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{concat('/', $lang, '/Index')}"/>
    </dispatch>

(: 
 :  Startseiten-Weiterleitung 2
 :  Diverse Index Variationen
 :  Achtung: .php hier nicht aufnehmen, dies wird mit den typo3ContentMappings abgefragt
:)
else if (matches($exist:path, '^/[Ii]ndex(\.(htm|html|xml)|/)?$')) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{concat('/', $lang, '/Index')}"/>
    </dispatch>
        
else if (matches($exist:path, '^/(en/|de/)(Index)?$')) then
    let $js := if(request:get-parameter-names() = $ajaxCrawlerParameter) then 'false' else 'true'
    return
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="/xql/index.xql">
    	   <add-parameter name="lang" value="{$lang}"/>
    	   <add-parameter name="js" value="{$js}"/>
    	</forward>
    </dispatch>

(: Suche :)
else if (matches($exist:path, concat('^/', $lang, '/', $search, '/?$'))) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="/xql/search.xql">
    	   <add-parameter name="lang" value="{$lang}"/>
    	</forward>
    </dispatch>

(: Register :)
else if (matches($exist:path, concat('^/', $lang,'/', $indices, '(/(', $persons, '|', $letters, '|', $diaries, '|', $writings, '|', $works, '|', $news, '))?$'))) then
    let $docType := if(matches($exist:resource, $indices))
        then 'persons' (: Default Register :)
        else if($lang eq 'en')
            then $exist:resource
            else wega:translateLanguageString(xmldb:decode-uri(xs:anyURI($exist:resource)), $lang, 'en')
    return 
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="/xql/register.xql">
    	   <add-parameter name="lang" value="{$lang}"/>
    	   <add-parameter name="docType" value="{lower-case($docType)}"/>
    	   <add-parameter name="id" value="indices"/>
    	</forward>
    </dispatch>

(: Editorial Guidelines :)
else if (matches($exist:path, concat('^/', $lang, '/', $editorialGuidelines, '/?$'))) then
    let $js := if(request:get-parameter-names() = $ajaxCrawlerParameter) then 'false' else 'true'
    return
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="/xql/var.xql">
    	   <add-parameter name="lang" value="{$lang}"/>
    	   <add-parameter name="docID" value="A070001"/>
    	   <add-parameter name="createToc" value="true"/>
    	   <add-parameter name="createSecNos" value="true"/>
    	   <add-parameter name="js" value="{$js}"/>
    	</forward>
    </dispatch>

(: Impressum :)
else if ($exist:path eq '/en/About' or $exist:path eq '/de/Impressum') then
    let $js := if(request:get-parameter-names() = $ajaxCrawlerParameter) then 'false' else 'true'
    return
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="/xql/var.xql">
    	   <add-parameter name="lang" value="{$lang}"/>
    	   <add-parameter name="docID" value="A070002"/>
    	   <add-parameter name="js" value="{$js}"/>
    	</forward>
    </dispatch>

(: Ausführliche Weber-Biographie :)
else if ($exist:path eq '/en/Biography' or $exist:path eq '/de/Biographie') then
    let $js := if(request:get-parameter-names() = $ajaxCrawlerParameter) then 'false' else 'true'
    return
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="/xql/var.xql">
    	   <add-parameter name="lang" value="{$lang}"/>
    	   <add-parameter name="docID" value="A070003"/>
    	   <add-parameter name="createToc" value="true"/>
    	   <add-parameter name="createSecNos" value="true"/>
    	   <add-parameter name="js" value="{$js}"/>
    	</forward>
    </dispatch>

(: Help :)
else if (matches($exist:path, concat('^/', $lang, '/', $help, '/?$'))) then
    let $js := if(request:get-parameter-names() = $ajaxCrawlerParameter) then 'false' else 'true'
    return
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="/xql/var.xql">
    	   <add-parameter name="lang" value="{$lang}"/>
    	   <add-parameter name="docID" value="A070004"/>
    	   <add-parameter name="createToc" value="true"/>
    	   <add-parameter name="createSecNos" value="true"/>
    	   <add-parameter name="js" value="{$js}"/>
    	</forward>
    </dispatch>

(: Project Description :)
else if (matches($exist:path, concat('^/', $lang, '/', $projectDescription, '/?$'))) then
    let $js := if(request:get-parameter-names() = $ajaxCrawlerParameter) then 'false' else 'true'
    return
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="/xql/var.xql">
    	   <add-parameter name="lang" value="{$lang}"/>
    	   <add-parameter name="docID" value="A070006"/>
    	   <add-parameter name="createToc" value="true"/>
    	   <add-parameter name="createSecNos" value="true"/>
    	   <add-parameter name="js" value="{$js}"/>
    	</forward>
    </dispatch>

(: Kontakt :)
else if (matches($exist:path, concat('^/', $lang, '/', wega:getVarURL('A070009',$lang), '/?$'))) then
    let $js := if(request:get-parameter-names() = $ajaxCrawlerParameter) then 'false' else 'true'
    return
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="/xql/var.xql">
    	   <add-parameter name="lang" value="{$lang}"/>
    	   <add-parameter name="docID" value="A070009"/>
    	   <add-parameter name="js" value="{$js}"/>
    	</forward>
    </dispatch>

(: Editionsrichtlinien Werkausgabe :)
(:else if (matches($exist:path, concat('^/', $lang, '/', wega:getVarURL('A070010',$lang), '/?$'))) then
    let $js := if(request:get-parameter-names() = $ajaxCrawlerParameter) then 'false' else 'true'
    return
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="/xql/var.xql">
    	   <add-parameter name="lang" value="{$lang}"/>
    	   <add-parameter name="docID" value="A070010"/>
    	   <add-parameter name="js" value="{$js}"/>
    	</forward>
    </dispatch>:)

(: Weber-Studien Einzelansicht:)
else if ($isWeberPublication and matches($exist:path, concat('^/', $lang, '/', $publications, '/', $weberStudies, '/', 'A11\d{4}/?$'))) then
    let $js := if(request:get-parameter-names() = $ajaxCrawlerParameter) then 'false' else 'true'
    return
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="/xql/var.xql">
    	   <add-parameter name="lang" value="{$lang}"/>
    	   <add-parameter name="docID" value="{$exist:resource}"/>
    	   <add-parameter name="js" value="{$js}"/>
    	</forward>
    </dispatch>

(: Publikationen :)
else if (matches($exist:path, concat('^/', $lang,'/', $publications, '(/(', $weberStudies, '|', $musicVolumes, '|', $papers, '|', $talks, '))?$'))) then
    local:forwardIndices('publications', $lang)

(: Bibliography :)
else if (matches($exist:path, concat('^/', $lang,'/', $bibliography, '(/(', $literature, '|', $discography, '|', $scores, '))?$'))) then
    local:forwardIndices('bibliography', $lang)

(: Tools :)
else if (wega:getOption('environment') eq 'development' and matches($exist:path, concat('^/', $lang, '/', $tools, '/?$'))) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="/xql/tools.xql">
    	   <add-parameter name="lang" value="{$lang}"/>
    	</forward>
    </dispatch>

(: Personen - Weiterleitung :)
else if (matches($exist:path, '^/A00\d{4}/?$')) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{concat('/', $lang, '/', $exist:resource)}"/>
    </dispatch>

(: Schrift - Weiterleitung :)
else if (matches($exist:path, '^/(de/|en/)?A03\d{4}/?$') and $authorID ne '') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{concat('/', $lang, '/', $authorID, '/', $writings, '/', $exist:resource)}"/>
    </dispatch>

(: Brief - Weiterleitung :)
else if (matches($exist:path, '^/(de/|en/)?A04\d{4}/?$') and $authorID ne '') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{concat('/', $lang, '/', $authorID, '/', $correspondence, '/', $exist:resource)}"/>
    </dispatch>

(: Tagebuch - Weiterleitung :)
else if (matches($exist:path, '^/(de/|en/)?A06\d{4}/?$')) then
    let $authorID := 'A002068'
    return 
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        	<redirect url="{concat('/', $lang, '/', $authorID, '/', $diaries, '/', $exist:resource)}"/>
        </dispatch>
        
(: News - Weiterleitung :)
else if (matches($exist:path, '^/(de/|en/)?A05\d{4}/?$') and $authorID ne '') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{concat('/', $lang, '/', $authorID, '/', $news, '/', $exist:resource)}"/>
    </dispatch>

(: Personen - Briefliste :)
else if (matches($exist:path, concat('^/', $lang, '/A00\d{4}/', $correspondence, '/?$'))) then
    let $authorID := string-join(functx:get-matches($exist:path, 'A00\d{4}'), '')
    return 
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        	<forward url="/xql/register.xql">
        	   <add-parameter name="lang" value="{$lang}"/>
        	   <add-parameter name="docType" value="letters"/>
        	   <add-parameter name="id" value="{$authorID}"/>
        	</forward>
        </dispatch>

(: Personen - Schriftenliste :)
else if (matches($exist:path, concat('^/', $lang, '/A00\d{4}/', $writings, '/?$'))) then
    let $authorID := string-join(functx:get-matches($exist:path, 'A00\d{4}'),'')
    return 
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="/xql/register.xql">
    	   <add-parameter name="lang" value="{$lang}"/>
    	   <add-parameter name="docType" value="writings"/>
    	   <add-parameter name="id" value="{$authorID}"/>
    	</forward>
    </dispatch>

(: Personen - Werkeliste :)
else if (matches($exist:path, concat('^/', $lang, '/A00\d{4}/', $works, '/?$'))) then
    let $authorID := string-join(functx:get-matches($exist:path, 'A00\d{4}'),'')
    return 
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="/xql/register.xql">
    	   <add-parameter name="lang" value="{$lang}"/>
    	   <add-parameter name="docType" value="works"/>
    	   <add-parameter name="id" value="{$authorID}"/>
    	</forward>
    </dispatch>

(: Personen - Tagebuchliste :)
else if (matches($exist:path, concat('^/', $lang, '/A002068/', $diaries, '/?$'))) then
    let $authorID := 'A002068'
    return 
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="/xql/register.xql">
    	   <add-parameter name="lang" value="{$lang}"/>
    	   <add-parameter name="docType" value="diaries"/>
    	   <add-parameter name="id" value="{$authorID}"/>
    	</forward>
    </dispatch>
    
(: Personen - Einzelansicht :)
else if (matches($exist:path, concat('^/', $lang, '/A00\d{4}/?$'))) then
    let $js := if(request:get-parameter-names() = $ajaxCrawlerParameter) then 'false' else 'true'
    let $person := wega:doc($exist:resource)/tei:person
    return if(exists($person)) then 
        if($person/tei:ref) then ( 
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <redirect url="/{string-join(($lang, $person/tei:ref/@target), '/')}"/>
            </dispatch>
        )
        else
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            	<forward url="/xql/person_singleView.xql">
            	   <add-parameter name="lang" value="{$lang}"/>
            	   <add-parameter name="id" value="{$exist:resource}"/>
            	   <add-parameter name="js" value="{$js}"/>
            	</forward>
            </dispatch>
    else $error404

(: Brief - Einzelansicht :)
else if (matches($exist:path, concat('^/', $lang, '/', $authorID,'/', $correspondence,'/', 'A04\d{4}/?$'))) then
        let $js := if(request:get-parameter-names() = $ajaxCrawlerParameter) then 'false' else 'true'
        let $doc := wega:doc($exist:resource)/tei:TEI
        return if(exists($doc)) then 
            if($doc/tei:ref) then 
                <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                    <redirect url="/{string-join(($lang, $doc/tei:ref/@target), '/')}"/>
                </dispatch>
            else 
                <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                	<forward url="/xql/letter_singleView.xql">
                	   <add-parameter name="lang" value="{$lang}"/>
                	   <add-parameter name="id" value="{$exist:resource}"/>
                	   <add-parameter name="js" value="{$js}"/>
                	</forward>
                </dispatch>
        else $error404

(: Schriften - Einzelansicht :)
else if (matches($exist:path, concat('^/', $lang, '/', $authorID,'/', $writings, '/', 'A03\d{4}/?$'))) then
        let $js := if(request:get-parameter-names() = $ajaxCrawlerParameter) then 'false' else 'true'
        let $doc := wega:doc($exist:resource)/tei:TEI
        return if(exists($doc)) then 
            if($doc/tei:ref) then 
                <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                    <redirect url="/{string-join(($lang, $doc/tei:ref/@target), '/')}"/>
                </dispatch>
            else 
                <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                	<forward url="/xql/doc_singleView.xql">
                	   <add-parameter name="lang" value="{$lang}"/>
                	   <add-parameter name="id" value="{$exist:resource}"/>
                	   <add-parameter name="js" value="{$js}"/>
                	</forward>
                </dispatch>
        else $error404

(: Tagebuch - Einzelansicht :)
else if (matches($exist:path, concat('^/', $lang, '/', 'A002068', '/', $diaries, '/', 'A06\d{4}/?$'))) then
        let $js := if(request:get-parameter-names() = $ajaxCrawlerParameter) then 'false' else 'true'
        return
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        	<forward url="/xql/diary_singleView.xql">
        	   <add-parameter name="lang" value="{$lang}"/>
        	   <add-parameter name="id" value="{$exist:resource}"/>
        	   <add-parameter name="js" value="{$js}"/>
        	</forward>
        </dispatch>

(: News - Einzelansicht :)
else if (matches($exist:path, concat('^/', $lang, '/', $authorID,'/', $news, '/', 'A05\d{4}/?$'))) then
        let $js := if(request:get-parameter-names() = $ajaxCrawlerParameter) then 'false' else 'true'
        let $doc := wega:doc($exist:resource)/tei:TEI
        return if(exists($doc)) then 
            if($doc/tei:ref) then 
                <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                    <redirect url="/{string-join(($lang, $doc/tei:ref/@target), '/')}"/>
                </dispatch>
            else 
                <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                	<forward url="/xql/news_singleView.xql">
                	   <add-parameter name="lang" value="{$lang}"/>
                	   <add-parameter name="id" value="{$exist:resource}"/>
                	   <add-parameter name="js" value="{$js}"/>
                	</forward>
                </dispatch>
        else $error404

(: PND Resolver :)
else if (matches($exist:path, concat('^/', $lang, '/pnd/', '[0-9]{8,9}[0-9X]$'))) then
    let $id := wega:getIDByPND($exist:resource)
    return if($id ne '') then
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        	<redirect url="{concat('/', $lang, '/', $id)}"/>
        </dispatch>
    else $error404

(: Shortcut für Weber-Korrespondenz :)
else if (matches($exist:path, concat('^/', lower-case($letters), '/?$'))) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<redirect url="/{string-join(($lang, 'A002068', $correspondence), '/')}">
    	   <cache-control cache="yes"/>
    	</redirect>
    </dispatch>

(: Shortcut für Weber-Tagebücher :)
else if (matches($exist:path, concat('^/', lower-case($diaries), '/?$'))) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<redirect url="/{string-join(($lang, 'A002068', $diaries), '/')}">
    	   <cache-control cache="yes"/>
    	</redirect>
    </dispatch>

(: Shortcut für fffi-db :)
else if (matches($exist:path, '^/fffi-db.*$')) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<redirect url="/{string-join(($lang, $search), '/')}">
    	   <cache-control cache="yes"/>
    	</redirect>
    </dispatch>    

(: Shortcut für Aktuelles :)
else if (matches($exist:path, '^/aktuelles.html$')) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<redirect url="/{string-join(($lang, $indices, $news), '/')}">
    	   <cache-control cache="yes"/>
    	</redirect>
    </dispatch> 

(: Shortcut für Bibliographie :)
else if (matches($exist:path, '^/weberbiblio.html$')) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<redirect url="/{string-join(($lang, $bibliography), '/')}">
    	   <cache-control cache="yes"/>
    	</redirect>
    </dispatch> 

(: Shortcut für Werkverzeichnis :)
else if (matches($exist:path, '^/wev_kurzfassung.html$')) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<redirect url="/{string-join(($lang, 'A002068', $works), '/')}">
    	   <cache-control cache="yes"/>
    	</redirect>
    </dispatch> 

(: typo3ContentMappings :)
else if (matches($exist:path, '^/index.php$')) then
    let $param := request:get-parameter('id', '10')
    let $newPath := doc(wega:getOption('typo3ContentMappings'))//entry[@oldID = $param]
    return if($newPath ne '') then 
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        	<redirect url="{$newPath}">
        	</redirect>
        </dispatch>
     else $error404

(: PND Beacon :)
else if (matches($exist:path, '^/pnd_beacon.txt$')) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="/xql/utilities/createPNDBeacon.xql">
    	   <cache-control cache="yes"/>
    	</forward>
    </dispatch>

(: Sitemap :)
else if (matches($exist:path, '^/sitemap(/?|/index.xml)?$') or matches($exist:path, '^/sitemap/sitemap_(en|de).xml.gz$')) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="/xql/utilities/createSiteMap.xql">
    	   <add-parameter name="lang" value="{$lang}"/>
    	   <add-parameter name="resource" value="{$exist:resource}"/>
    	</forward>
    </dispatch>

(: JMX Statusinformationen :)
else if (wega:getOption('environment') eq 'development' and $exist:path eq '/status') then 
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <ignore/>
    </dispatch>

else if (matches($exist:path, '/webdav')) then 
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <ignore/>
    </dispatch>
    
else if (matches($exist:path, 'blank.html')) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    	<forward url="/jscript/blank.html">
    	</forward>
    </dispatch>

else $error404
)