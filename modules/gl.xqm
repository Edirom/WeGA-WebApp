xquery version "3.1" encoding "UTF-8";

(:~
 : WeGA XQuery-Module for processing TEI Customization Guidelines
 :
 : @author Peter Stadler 
 : @version 1.0
 :)
 
module namespace gl="http://xquery.weber-gesamtausgabe.de/modules/gl";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace teieg="http://www.tei-c.org/ns/Examples";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace xhtml="http://www.w3.org/1999/xhtml";

import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
(:import module namespace facets="http://xquery.weber-gesamtausgabe.de/modules/facets" at "facets.xqm";:)
import module namespace api="http://xquery.weber-gesamtausgabe.de/modules/api" at "api.xqm";
import module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util" at "wega-util.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "str.xqm";
import module namespace templates="http://exist-db.org/xquery/templates" at "/db/apps/shared-resources/content/templates.xql";
import module namespace functx="http://www.functx.com";

(:~
 : Returns the (compiled) ODD specification for an element, class, datatype, or macro (this is the 2-arity version)
 :
 : @param $specID the identifier of the spec as defined on its @ident attribute, e.g. "p" or "model.pLike"
 : @param $schemaID the identifier of the schema as defined on its @ident attribute, e.g. "wegaLetter"
~:)
declare function gl:spec($specID as xs:string?, $schemaID as xs:string?) as element()? {
	collection($config:app-root || '/guidelines/compiledODD')//tei:schemaSpec[@ident=$schemaID]/tei:*[@ident=$specID]
};

(:~
 : Returns the (compiled) ODD specification for an element, class, datatype, or macro (this is the 1-arity version)
 :
 : @param $path the URL for the spec 
~:)
declare function gl:spec($path as xs:string) as element()? {
	let $pathTokens := tokenize(replace($path, '(/xml|/examples)?\.[xhtml]+$', ''), '/')
	return
		gl:spec($pathTokens[last()], $pathTokens[last() - 1])
};

declare 
	%templates:wrap
	function gl:title($node as node(), $model as map(*)) {
	'Element: ' || $model('specID') || ' (' || $model('schemaID') || ')'
};

declare 
	%templates:wrap
	function gl:spec-details($node as node(), $model as map(*)) as map() {
		let $schemaSpecs := collection($config:app-root || '/guidelines/compiledODD')//tei:schemaSpec
		let $schemaSpec := $schemaSpecs[@ident=$model('schemaID')]
		let $spec := $schemaSpec//tei:*[@ident=$model('specID')]
		let $teiSpec := doc($config:app-root || '/guidelines/compiledODD/p5subset.xml')//tei:*[@ident=$model('specID')]
		let $lang := $model?lang
		let $HTMLSpec := wega-util:transform($spec, doc(concat($config:xsl-collection-path, '/gl.xsl')), config:get-xsl-params(()))
		return
			map {
				'gloss' := $spec/tei:gloss[@xml:lang=$lang],
				'desc' := $spec/tei:desc[@xml:lang=$lang],
				'spec' := $spec,
				'specIDDisplay' := if(contains($model('specID'), '.')) then $model('specID') else '<' || $model('specID') || '>',
				'customizations' := ($schemaSpecs//tei:*[@ident=$model('specID')] except $spec, $teiSpec),
				'remarks' := $HTMLSpec//xhtml:div[@class='remarks'],
				'examples' := $spec/tei:exemplum[@xml:lang='en'] ! gl:print-exemplum(.)
			}
};

(:~
 : grab all examples from our data corpus for some element
~:)
declare 
	%templates:wrap
	function gl:examples($node as node(), $model as map(*)) as map()? {
		let $spec := gl:spec($model('exist:path'))
		let $map := map {
			'element' := $spec/data(@ident), 
			'docType' := gl:schemaIdent2docType($spec/ancestor::tei:schemaSpec/data(@ident)), 
			'namespace' := 'http://www.tei-c.org/ns/1.0', 
			'swagger:config' := json-doc($config:swagger-config-path), 
			'total' := true() 
		}
		let $examples := api:code-findByElement($map)
(:		let $log := util:log-system-out($model('exist:path')):)
		return 
			map:new((
				$map,
				map {
					'search-results' := $examples
				}
			))
};

declare 
	%templates:wrap
	function gl:preview($node as node(), $model as map(*)) as map() {
		let $codeSample := api:codeSample($model('result-page-entry'), $model)
		let $doc := core:doc($codeSample?docID)
		let $docType := config:get-doctype-by-id($codeSample?docID)
		return
			map {
	            'doc' := $doc,
	            'docID' := $codeSample?docID,
	            'relators' := $doc//mei:fileDesc/mei:titleStmt/mei:respStmt/mei:persName[@role],
	            'biblioType' := $doc/tei:biblStruct/data(@type),
	            'workType' := $doc//mei:term/data(@classcode),
	            'codeSample' := $codeSample?codeSample,
	            'icon-src' := '$resources/img/icons/icon_' || $docType || '.png'
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

(:~
 : Create examples from spec files
 : Helper function for gl:spec-details()
~:)
declare %private function gl:print-exemplum($exemplum as element()) as item()* {
	let $serializationParameters := ('method=xml', 'media-type=application/xml', 'indent=no', 'omit-xml-declaration=yes', 'encoding=utf-8')
	return
		util:serialize(core:change-namespace($exemplum, '', ())/*/*, $serializationParameters)
};

(:~
 : A simple mapping from schemaSpec identifiers to WeGA document types
~:)
declare function gl:schemaIdent2docType($schemaID as xs:string) as xs:string {
	lower-case(substring-after($schemaID, 'wega'))
};
