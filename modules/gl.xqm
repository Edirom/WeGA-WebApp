xquery version "3.1" encoding "UTF-8";

(:~
 : WeGA XQuery-Module for processing TEI Customization Guidelines
 :
 : @author Peter Stadler 
 : @version 1.0
 :)
 
module namespace gl="http://xquery.weber-gesamtausgabe.de/modules/gl";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
(:import module namespace facets="http://xquery.weber-gesamtausgabe.de/modules/facets" at "facets.xqm";:)
(:import module namespace search="http://xquery.weber-gesamtausgabe.de/modules/search" at "search.xqm";:)
(:import module namespace wdt="http://xquery.weber-gesamtausgabe.de/modules/wdt" at "wdt.xqm";:)
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "str.xqm";
import module namespace templates="http://exist-db.org/xquery/templates" at "/db/apps/shared-resources/content/templates.xql";

declare 
	%templates:wrap
	function gl:title($node as node(), $model as map(*)) {
	'Element: ' || $model('specID') || ' (' || $model('schema') || ')'
};

declare 
	%templates:wrap
	function gl:spec-details($node as node(), $model as map(*)) as map() {
		let $schemaSpecs := collection($config:app-root || '/guidelines/compiledODD')//tei:schemaSpec
		let $schemaSpec := $schemaSpecs[@ident=$model('schema')]
		let $spec := $schemaSpec//tei:*[@ident=$model('specID')]
		let $teiSpec := doc($config:app-root || '/guidelines/compiledODD/p5subset.xml')//tei:*[@ident=$model('specID')]
		let $lang := $model?lang
		
(:		let $log := util:log-system-out(count($schemaSpecs//tei:*[@ident=$model('specID')] except $spec)):)
		return
			map {
				'gloss' := $spec/tei:gloss[@xml:lang=$lang],
				'desc' := $spec/tei:desc[@xml:lang=$lang],
				'spec' := $spec,
				'customizations' := ($schemaSpecs//tei:*[@ident=$model('specID')] except $spec, $teiSpec)
			}
};

declare function gl:print-customization($node as node(), $model as map(*)) {
	let $modified := (:if(deep-equal($model?customization, $model?spec)):)
		(: Just a simple heuristic since deep-equal is too slow :)
		string-join(($model?customization//@* | $model?customization//text()), '') != string-join(($model?spec//@* | $model?spec//text()), '')
	let $data := 
		if ($model?customization/ancestor::tei:schemaSpec) then gl:wega-customization($model) 
		else gl:tei-source($model?customization)
	return
		element {name($node)} {
	        $node/@*[not(local-name(.) eq 'class')],
	        attribute class {string-join((tokenize($node/@class, '\s+'), if($modified) then 'bg-warning' else 'bg-success'), ' ')},
	        element a {
	        	attribute href {$data?url},
	        	$data?customizationIdent || ' (' || (if($modified) then 'modified' else 'unmodified') || ')'
        	}
	    }
};

(:~
 : Helper function for gl:print-customization()
~:)
declare %private function gl:tei-source($spec as element()) as map() {
	let $specID := $spec/@ident
	let $teiVersion := $spec/root()//tei:teiHeader/tei:fileDesc/tei:editionStmt/tei:edition/tei:ref[matches(., '^\d+\.\d+\.\d+$')]/data()
	let $url := 'http://www.tei-c.org/Vault/P5/' || $teiVersion || '/doc/tei-p5-doc/en/html/ref-' || $specID || '.html'
	let $customizationIdent := 'TEI version ' || $teiVersion
	return
		map {
			'customizationIdent' := $customizationIdent,
			'url' := $url
		}
};

(:~
 : Helper function for gl:print-customization()
~:)
declare %private function gl:wega-customization($model as map(*)) as map() {
	let $specID := $model?customization/@ident
	let $customizationIdent := $model?customization/ancestor::tei:schemaSpec/data(@ident)
	let $url := core:link-to-current-app(str:join-path-elements(($model?lang,lang:get-language-string('project', $model?lang),lang:get-language-string('editorialGuidelines-text', $model?lang),$customizationIdent,$specID))) || '.html'
	return
		map {
			'customizationIdent' := $customizationIdent,
			'url' := $url
		}
};
