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

declare variable $gl:guidelines-collection-path as xs:string := $config:app-root || '/guidelines';
declare variable $gl:main-source as document-node() := 
    try { doc(str:join-path-elements(($gl:guidelines-collection-path, 'guidelines-de-wega_all.compiled.xml'))) }
    catch * {core:logToFile('error', 'failed to load main Guidelines source')};

(:~
 : Returns the available chapter identifier
~:)
declare function gl:chapter-idents() as xs:string* {
    $gl:main-source//(tei:div, tei:divGen)[not(ancestor::tei:div)]/data(@xml:id)
};

(:~
 : Returns the chapter indicated by $chapID
~:)
declare function gl:chapter($chapID as xs:string) as element(tei:div)? {
    $gl:main-source//(tei:div, tei:divGen)[@xml:id=$chapID]
};

(:~
 : Returns the available schemaSpec identifier
~:)
declare function gl:schemaSpec-idents() as xs:string* {
    collection($gl:guidelines-collection-path)//tei:schemaSpec/data(@ident)
};

(:~
 : Returns the schemaSpec indicated by $schemaID
~:)
declare function gl:schemaSpec($schemaID as xs:string?) as element(tei:schemaSpec)? {
    collection($gl:guidelines-collection-path)//tei:schemaSpec[@ident = $schemaID]
};

(:~
 : Returns the available spec identifier for elements, classes, datatypes, and macros
 : for the schemaSpec indicated by $schemaID
~:)
declare function gl:spec-idents($schemaID as xs:string) as xs:string* {
     gl:schemaSpec($schemaID)//(tei:elementSpec, tei:classSpec, tei:macroSpec, tei:dataSpec)/data(@ident)
};

(:~
 : Returns the (compiled) ODD specification for an element, class, datatype, or macro (this is the 2-arity version)
 :
 : @param $specID the identifier of the spec as defined on its @ident attribute, e.g. "p" or "model.pLike"
 : @param $schemaID the identifier of the schema as defined on its @ident attribute, e.g. "wegaLetter"
~:)
declare function gl:spec($specID as xs:string?, $schemaID as xs:string?) as element()? {
	gl:schemaSpec($schemaID)/(tei:elementSpec, tei:classSpec, tei:macroSpec, tei:dataSpec)[@ident=$specID]
};

(:~
 : Returns the (compiled) ODD specification for an element, class, datatype, or macro (this is the 1-arity version)
 : Helper function for gl:examples() and app:xml-prettify(), where the request is made via AJAX
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
	%templates:default("specKey", "")
	function gl:spec-details($node as node(), $model as map(*), $specKey as xs:string) as map() {
		let $spec := 
		  if($specKey) then $model($specKey)
		  else gl:spec($model('specID'), $model('schemaID'))
		let $lang := $model?lang
		let $HTMLSpec := wega-util:transform($spec, doc(concat($config:xsl-collection-path, '/var.xsl')), config:get-xsl-params(()))
		return
			map {
				'gloss' := $spec/tei:gloss[@xml:lang=$lang] ! ('(' || . || ')'),
				'desc' := $spec/tei:desc[@xml:lang=$lang],
				'spec' := $spec,
				'specIDDisplay' := if($spec/self::tei:elementSpec) then '<' || $spec/@ident || '>' else $spec/@ident,
				'remarks' := $HTMLSpec//xhtml:div[@class='remarks'],
				'examples' := $spec/tei:exemplum[@xml:lang='en'] ! gl:print-exemplum(.)
			}
};

declare 
	%templates:wrap
	function gl:spec-customizations($node as node(), $model as map(*)) as map() {
		let $schemaSpecs := collection($gl:guidelines-collection-path)//tei:schemaSpec
		let $spec := $model?spec (:gl:spec($model('specID'), $model('schemaID')):)
		let $teiSpec := doc(str:join-path-elements(($gl:guidelines-collection-path, 'p5subset.xml')))//(tei:elementSpec, tei:classSpec, tei:macroSpec, tei:dataSpec)[@ident=$model('specID')]
		return
			map {
				'customizations' := ($schemaSpecs//(tei:elementSpec, tei:classSpec, tei:macroSpec, tei:dataSpec)[@ident=$model('specID')] except $spec, $teiSpec)
			}
};

declare 
	%templates:wrap
	function gl:attributes($node as node(), $model as map(*)) as map()? {
	   let $spec := $model?spec
	   let $attClasses := $spec/tei:classes/tei:memberOf[starts-with(@key, 'att.')]/@key
	   let $localAtts :=  $spec//tei:attDef[not(@mode='delete')] | $spec//tei:attRef
	   return
	       if(count($attClasses | $localAtts) gt 0) then
    	       map {
    				'attributes' := $attClasses | $localAtts,
    				'attClasses' := $attClasses,
    				'localAtts' := $localAtts
    			}
    		else ()
};

declare 
	%templates:wrap
	function gl:members($node as node(), $model as map(*)) as map()? {
	   let $spec := $model?spec
	   let $schema := $spec/ancestor::tei:schemaSpec
	   let $members := $schema//tei:elementSpec[tei:classes/tei:memberOf/@key = $spec/@ident]
	   return
	       if(count($members) gt 0) then
    	       map {
    	           'members' := $members 
    	       }
           else ()
};

declare 
	%templates:wrap
	function gl:print-member($node as node(), $model as map(*)) {
	   element a {
            attribute href {
                gl:link-to-spec(($model?member)/data(@ident), $model?lang, $model?schemaID) || '.html'
            },
            ($model?member)/data(@ident)
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

(:~
 : Outputting Guidelines prose chapters 
~:)
declare 
	%templates:wrap
	function gl:doc-details($node as node(), $model as map(*)) as map()? {
		let $chapter := gl:chapter($model?chapID)
		return
			map {
				'transcription' := wega-util:transform($chapter, doc(concat($config:xsl-collection-path, '/var.xsl')), config:get-xsl-params(()))
			}
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

declare function gl:print-attributeClass($node as node(), $model as map(*)) {
    let $att2span := function($attID as node()) {
        element span {
            attribute class {
                if($model?spec//tei:attDef[@ident=$attID]) then 'unusedattribute'
                else 'attribute'
            },
            data($attID)
        }
    }
    return
        element a {
            attribute href {
                gl:link-to-spec($model?attClass, $model?lang, $model?schemaID) || '.html'
            },
            data($model?attClass),
            ' (',
            gl:spec($model?attClass, $model?schemaID)//tei:attDef/@ident ! ($att2span(.))
            ,')'
        }
};

(:~
 : Create a link to $specID (without file extension suffix)
 : When $schemaID is given the link is created to this specific schema,
 : otherwise the main Guidelines source ($gl:main-source) is targeted.
~:)
declare %private function gl:link-to-spec($specID as xs:string, $lang as xs:string, $schemaID as xs:string?) as xs:string? {
    core:link-to-current-app(
		str:join-path-elements((
			$lang,
			lang:get-language-string('project', $lang),
			lang:get-language-string('editorialGuidelines-text', $lang),
			if($schemaID) then $schemaID else $gl:main-source/@ident,
			'ref-' || $specID ))
	)
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
	let $url := gl:link-to-spec($specID, $model?lang, $customizationIdent) || '.html'
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
