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
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace map="http://www.w3.org/2005/xpath-functions/map";

import module namespace crud="http://xquery.weber-gesamtausgabe.de/modules/crud" at "crud.xqm";
(:import module namespace facets="http://xquery.weber-gesamtausgabe.de/modules/facets" at "facets.xqm";:)
import module namespace api="http://xquery.weber-gesamtausgabe.de/modules/api" at "api.xqm";
import module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util" at "wega-util.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace controller="http://xquery.weber-gesamtausgabe.de/modules/controller" at "controller.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/str.xqm";
import module namespace templates="http://exist-db.org/xquery/html-templating";
import module namespace functx="http://www.functx.com";

declare variable $gl:guidelines-collection-path as xs:string := $config:app-root || '/guidelines';
declare variable $gl:main-source as document-node()? := 
    try { doc(str:join-path-elements(($gl:guidelines-collection-path, 'guidelines-de-wega_all.compiled.xml'))) }
    catch * {wega-util:log-to-file('error', 'failed to load main Guidelines source')};

declare variable $gl:schemaSpec-idents as xs:string* := gl:schemaSpec-idents();

(:~
 : Returns the available chapter identifier
~:)
declare function gl:chapter-idents() as xs:string* {
    $gl:main-source//tei:div[not(ancestor::tei:div)]/data(@xml:id)
};

(:~
 : Returns the chapter indicated by $chapID
~:)
declare function gl:chapter($chapID as xs:string) as element(tei:div)? {
    $gl:main-source//tei:div[@xml:id=$chapID]
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
    if($schemaID) then collection($gl:guidelines-collection-path)//tei:schemaSpec[@ident = $schemaID]
    else $gl:main-source//tei:schemaSpec
};

(:~
 : Returns the available spec identifier for elements, classes, datatypes, and macros
 : for the schemaSpec indicated by $schemaID
~:)
declare function gl:spec-idents($schemaID as xs:string?, $specType as xs:string?) as xs:string* {
    let $schemaSpec := 
        if($schemaID) then gl:schemaSpec($schemaID)
        else $gl:main-source
    return
        switch($specType)
        case 'elements' return $schemaSpec//tei:elementSpec/data(@ident)
        case 'models' return $schemaSpec//tei:classSpec[@type='model']/data(@ident)
        case 'attributes' return $schemaSpec//tei:classSpec[@type='atts']/data(@ident)
        case 'datatypes' return $schemaSpec//tei:dataSpec/data(@ident)
        case 'macros' return $schemaSpec//tei:macroSpec/data(@ident)
        default return $schemaSpec//(tei:elementSpec, tei:classSpec, tei:macroSpec, tei:dataSpec)/data(@ident)
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
	let $schemaID := 
	   if(request:get-parameter('schemaID', ()) = gl:schemaSpec-idents()) then request:get-parameter('schemaID', ())
	   else $gl:main-source//tei:schemaSpec/data(@ident)
	return
		gl:spec(substring-after($pathTokens[last()], 'ref-'), $schemaID)
};

declare 
	%templates:wrap
	function gl:title($node as node(), $model as map(*)) {
	   $model('specID') || ' (' || $model('schemaID') || ')'
};


(:~
 : Collecting details about a TEI specification
 : A specification ($spec) could be some tei:*Spec (e.g. tei:elementSpec, or tei:classSpec) 
 : or some descendant tei:attDef or tei:valItem (i.e. everything that might have nested tei:desc, tei:gloss and tei:remarks)
~:)
declare 
	%templates:wrap
	%templates:default("specKey", "")
	function gl:spec-details($node as node(), $model as map(*), $specKey as xs:string) as map(*) {
		let $spec := 
		  if($specKey) then $model($specKey)
		  else gl:spec($model('specID'), $model('schemaID'))
		let $lang := $model?lang
		let $HTMLSpec := wega-util:transform($spec, doc(concat($config:xsl-collection-path, '/var.xsl')), config:get-xsl-params(()))
		let $usage-string := if($spec/@usage) then lang:get-language-string('usage_' || $spec/data(@usage), $model?lang) else ()
		let $examples-selection := $spec/tei:exemplum[@xml:lang=($lang, "mul", "und")]
		let $examples := if (exists($examples-selection)) then $examples-selection else $spec/tei:exemplum[@xml:lang="en"]
		return
			map {
				'gloss' : $spec/tei:gloss[@xml:lang=$lang] ! ('(' || . || ')'),
				'desc' : $spec/tei:desc[@xml:lang=$lang],
				'spec' : $spec,
				'specIDDisplay' : if($spec/self::tei:elementSpec) then '<' || $spec/@ident || '>' else $spec/@ident,
				'remarks' : $HTMLSpec/xhtml:div[@class='remarks'],
				'examples' : $examples ! gl:print-exemplum(.),
				'usage-label' : if ($spec/@usage) then <sup title="{concat("Status: ",$usage-string)}" class="{concat("usage_",$spec/data(@usage))}">{$spec/data(@usage)}</sup> else (),
				'datatype' : $spec/tei:datatype/tei:dataRef/data(@key),
				'closed_values' : $spec/tei:valList[@type='closed']/tei:valItem
			}
};

declare 
	%templates:wrap
	function gl:breadcrumb($node as node(), $model as map(*)) as map(*) {
	   (:util:log-system-out(request:get-parameter-names()),:)
	   map {
	       'specType' : lang:get-language-string(gl:specType(gl:spec($model?specID, $model?schemaID)), $model?lang),
	       'editorialGuidelines-text_specType_url' : config:link-to-current-app(str:join-path-elements((
	           lang:get-language-string('project', $model?lang),
	           lang:get-language-string('editorialGuidelines-text', $model?lang),
	           lang:get-language-string(gl:specType(gl:spec($model('specID'), $model('schemaID'))), $model?lang),
	           lang:get-language-string('index', $model?lang)
	       ))) || '?schemaID=' || $model?schemaID
	   }
};

declare 
    %templates:default("lang", "en")
    function gl:schemaID-filter($node as node(), $model as map(*), $lang as xs:string) as element(label)* {
        let $selected-schema := request:get-parameter('schemaID', ()) 
        return 
            for $schema in gl:schemaSpec-idents()
            let $class := 
                if($schema = $selected-schema) then normalize-space($node/@class) || ' active'
                else normalize-space($node/@class)
(:            let $displayTitle := lang:get-language-string($docType, $lang):)
            order by $schema
            return
                element {node-name($node)} {
                    $node/@*[not(name(.) = 'class')],
                    attribute class {$class},
                    element input {
                        $node/xhtml:input/@*[not(name(.) = 'value')],
                        attribute value {$schema},
                        if($schema = $selected-schema) then attribute checked {'checked'}
                        else ()
                    },
                    $schema
                }
};

declare 
	%templates:wrap
	function gl:spec-customizations($node as node(), $model as map(*)) as map(*) {
		let $schemaSpecs := collection($gl:guidelines-collection-path)//tei:schemaSpec
		let $spec := $model?spec (:gl:spec($model('specID'), $model('schemaID')):)
		let $teiSpec := doc(str:join-path-elements(($gl:guidelines-collection-path, 'p5subset.xml')))//(tei:elementSpec, tei:classSpec, tei:macroSpec, tei:dataSpec)[@ident=$model('specID')]
		return
			map {
				'customizations' : ($schemaSpecs//(tei:elementSpec, tei:classSpec, tei:macroSpec, tei:dataSpec)[@ident=$model('specID')] except $spec, $teiSpec)
			}
};

declare 
	%templates:wrap
	function gl:attributes($node as node(), $model as map(*)) as map(*)? {
	   let $spec := $model?spec
	   let $attClasses := $spec/tei:classes/tei:memberOf[starts-with(@key, 'att.')]/@key
	   let $attRefs := 
	       for $att in $spec//tei:attRef
	       return $spec/ancestor::tei:schemaSpec/tei:classSpec[@ident = $att/@class]//tei:attDef[@ident=$att/@name]
	   let $localAtts :=  $spec//tei:attDef[not(@mode='delete')] | $attRefs
	   return
	       if(count($attClasses | $localAtts) gt 0) then
    	       map {
    				'attributes' : $attClasses | $localAtts,
    				'attClasses' : $attClasses,
    				'localAtts' : $localAtts
    			}
    		else ()
};

declare 
	%templates:wrap
	function gl:members($node as node(), $model as map(*)) as map(*)? {
	   let $spec := $model?spec
(:	   let $schema := $spec/ancestor::tei:schemaSpec:)
	   let $members := gl:class-members($spec)
	   return
	       if(count($members) gt 0) then
    	       map {
    	           'members' : for $i in $members order by $i/@ident return $i 
    	       }
           else ()
};

declare 
	%templates:wrap
	function gl:print-member($node as node(), $model as map(*)) {
	   element a {
            attribute href {
                gl:link-to-spec(($model?member)/data(@ident), $model?lang, 'html', $model?schemaID)
            },
            if(($model?member)/self::tei:classSpec) then (
                ($model?member)/data(@ident),
                ' [',
                <small>{gl:class-members($model?member)/@ident/data()}</small>,
                ']'
            )
            else ($model?member)/data(@ident)
        }
};

(:~
 : grab all examples from our data corpus for some element
~:)
declare 
	%templates:wrap
	function gl:examples($node as node(), $model as map(*)) as map(*)? {
		let $spec := gl:spec($model('exist:path'))
		let $map := map {
			'element' : $spec/data(@ident), 
			'docType' : gl:schemaIdent2docType($spec/ancestor::tei:schemaSpec/data(@ident)), 
			'namespace' : 'http://www.tei-c.org/ns/1.0', 
			'openapi:config' : json-doc($config:openapi-config-path), 
			'total' : true() 
		}
		let $examples := api:code-findByElement($map)
(:		let $log := util:log-system-out($model('exist:path')):)
		return 
			map:merge((
				$map,
				map {
					'search-results' : $examples
				}
			))
};

(:~
 : Outputting Guidelines prose chapters 
~:)
declare 
	%templates:wrap
	function gl:doc-details($node as node(), $model as map(*)) as map(*)? {
        let $chapter := (
            gl:chapter($model?chapID),
            (: inject divGen for creating chapter endnotes :)
            if(gl:chapter($model?chapID)//tei:note) then <tei:back><tei:divGen type="endNotes"/></tei:back>
            else ()
        )
		let $secNoOffset := count($chapter/preceding-sibling::tei:div)
		return
			map {
				'transcription' : wega-util:transform($chapter, doc(concat($config:xsl-collection-path, '/var.xsl')), config:get-xsl-params(map { 'main-source-path' : document-uri($gl:main-source), 'createSecNos' : 'true', 'secNoOffset' : $secNoOffset }))
			}
};

declare 
    %templates:wrap 
    %templates:default("type", "toc")
    function gl:divGen($node as node(), $model as map(*), $type as xs:string) as map(*) {
        let $recurse := function($div as element(tei:div), $depth as xs:string?, $callBack as function() as map(*)?) as map(*)? {
            let $new-depth := string-join(($depth, count($div/preceding-sibling::tei:div) + 1), '.&#8201;')
            return
                map {
                    'label' : $new-depth || ' ' || str:normalize-space($div/tei:head[not(@type='sub')]),
                    'url' :  config:link-to-current-app(str:join-path-elements((lang:get-language-string('project', $model?lang),lang:get-language-string('editorialGuidelines-text', $model?lang)))) || '/' || ($div/ancestor-or-self::tei:div)[1]/data(@xml:id) || '.html' || ( if($div/parent::tei:div) then '#' || data($div/@xml:id) else () ),
                    'sub-items' : for $sub-item in $div/tei:div return $callBack($sub-item, $new-depth, $callBack)
                }
        }
        let $items :=  
            for $div in $gl:main-source//tei:body/tei:div[@xml:lang = $model?lang]
            return 
                $recurse($div, (), $recurse)
        
        return
            map {
                 'divGen-items' : $items
            }
};

declare function gl:print-divGen-item($node as node(), $model as map(*)) {
    element span {
    attribute class {"toggle-toc-item"},
        <i class="fa fa-plus-square" aria-hidden="true" style="display:none;"/>,
        <i class="fa fa-minus-square" aria-hidden="true"/>
    },
    element {node-name($node)} {
        $node/@*[not(name(.) = 'class')],        
        element a {
            attribute href {$model?divGen-item?url},
            $model?divGen-item?label
       }
    },
    if(count($model?divGen-item?sub-items) gt 0) then (
        element ul {
            for $item in $model?divGen-item?sub-items
            return
                <li>{gl:print-divGen-item($node, map {'divGen-item' : $item})}</li>
        } )
    else ()
};

declare 
	%templates:wrap
	%templates:default("lang", "en")
	function gl:preview($node as node(), $model as map(*), $lang as xs:string) as map(*) {
		let $codeSample := api:codeSample($model('result-page-entry'), $model)
		let $doc := crud:doc($codeSample?docID)
		let $docType := config:get-doctype-by-id($codeSample?docID)
		return
			map {
	            'doc' : $doc,
	            'docID' : $codeSample?docID,
	            'docURL' : controller:create-url-for-doc($doc, $lang),
	            'relators' : $doc//mei:fileDesc/mei:titleStmt/mei:respStmt/mei:persName[@role],
	            'biblioType' : $doc/tei:biblStruct/data(@type),
	            'workType' : $doc//mei:term/data(@class),
	            'codeSample' : $codeSample?codeSample,
	            'icon-src' : '$resources/img/icons/icon_' || $docType || '.png'
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
		element {node-name($node)} {
	        $node/@*[not(local-name(.) eq 'class')],
	        attribute class {string-join((tokenize($node/@class, '\s+'), if($modified) then 'bg-warning' else 'bg-success'), ' ')},
	        element a {
	        	attribute href {$data?url},
	        	$data?customizationIdent || ' (' || (if($modified) then 'modified' else 'unmodified') || ')'
        	}
	    }
};

declare function gl:print-attributeClass($node as node(), $model as map(*)) {
    let $att2span := function($spec as element()) {
        element span {
            attribute class {
                if($model?spec//tei:attDef[@ident=$spec/@ident]) then 'unusedattribute'
                else 'attribute'
            },
            data($spec/@ident)
        }
    }
    let $atts := for $att in gl:spec($model?attClass, $model?schemaID)//tei:attDef order by $att/@ident return $att
    return
        element a {
            attribute href {
                gl:link-to-spec($model?attClass, $model?lang, 'html', $model?schemaID)
            },
            data($model?attClass),
            ' (',
            for $att at $count in $atts
            return (
                $att2span($att),
                if(count($atts) eq $count) then ''
                else ', '
            )
            ,')'
        }
};

declare 
    %templates:wrap
    function gl:chapter-heading($node as node(), $model as map(*)) as xs:string {
        let $chapter-heading := 
            (: elements and attributes index :)
            if(starts-with($model?chapID, 'index-')) then lang:get-language-string(substring-after($model?chapID, 'index-'), $model?lang) || ' (' || $model?schemaID || ')'
            (: 'normal' chapters from the Guidelines :)
            else gl:chapter($model?chapID)/tei:head[not(@type='sub')]
        return
            str:normalize-space($chapter-heading)
};

(:~
 : List all specs to be displayed on an e.g. "index of elements"
~:)
declare 
    %templates:wrap
    function gl:spec-list($node as node(), $model as map(*)) as map(*)? {
        let $chapID := if (exists($node/@data-chapID)) then $node/@data-chapID/string() else $model?chapID
        let $specType := substring-after($chapID, 'index-')
        let $specIDs := gl:spec-idents($model?schemaID, $specType)
        return 
            map {
                'spec-list' : 
                    for $id in $specIDs
                    group by $initial := lower-case(substring(functx:substring-after-if-contains($id,"att."), 1, 1))
                    order by $initial
                    return 
                         map {
                            'label' : $initial,
                            'items' : $id
                         }
                        
            }
};

declare function gl:spec-list-items($node as node(), $model as map(*)) as map(*)? {
    let $links := 
        for $i in $model?specs-by-initial?items
        let $url := gl:link-to-spec($i, $model?lang, 'html', $model?schemaID)
        return 
            element a {
                attribute href {$url},
                $i
            }
    return 
    map {
        'label' : $model?specs-by-initial?label,
        'items' : $links
    }
};

(:~
 : Create a link to $specID
 : When $schemaID is given the link is created to this specific schema,
 : otherwise the main Guidelines source ($gl:main-source) is targeted.
~:)
declare %private function gl:link-to-spec($specID as xs:string, $lang as xs:string, $suffix as xs:string, $schemaID as xs:string?) as xs:string? {
    let $spec-type := 
        if(starts-with($specID, 'att.')) then lang:get-language-string('attributes', $lang)
        else if(starts-with($specID, 'model.')) then lang:get-language-string('classes', $lang)
        (: to be continued :)
        else lang:get-language-string('elements', $lang)
    let $url-param := if($schemaID) then ('?schemaID=' || $schemaID) else ()
    return
        config:link-to-current-app(
    		str:join-path-elements((
    			$lang,
    			lang:get-language-string('project', $lang),
    			lang:get-language-string('editorialGuidelines-text', $lang),
    			$spec-type,
    			'ref-' || $specID || '.' || $suffix))
    	) 
    	|| $url-param
};

(:~
 : Helper function for gl:print-customization()
~:)
declare %private function gl:tei-source($spec as element()) as map(*) {
	let $specID := $spec/@ident
	let $teiVersion := $spec/root()//tei:teiHeader/tei:fileDesc/tei:editionStmt/tei:edition/tei:ref[matches(., '^\d+\.\d+\.\d+$')]/data()
	let $url := 'http://www.tei-c.org/Vault/P5/' || $teiVersion || '/doc/tei-p5-doc/en/html/ref-' || $specID || '.html'
	let $customizationIdent := 'TEI version ' || $teiVersion
	return
		map {
			'customizationIdent' : $customizationIdent,
			'url' : $url
		}
};

(:~
 : Helper function for gl:print-customization()
~:)
declare %private function gl:wega-customization($model as map(*)) as map(*) {
	let $specID := $model?customization/@ident
	let $customizationIdent := $model?customization/ancestor::tei:schemaSpec/data(@ident)
	let $url := gl:link-to-spec($specID, $model?lang, 'html', $customizationIdent)
	return
		map {
			'customizationIdent' : $customizationIdent,
			'url' : $url
		}
};

(:~
 : Create examples from spec files
 : Helper function for gl:spec-details()
~:)
declare %private function gl:print-exemplum($exemplum as element()) as item()* {
	let $serializationParameters := 
	   <output:serialization-parameters>
	       <output:method>xml</output:method>
	       <output:indent>no</output:indent>
	       <output:media-type>application/xml</output:media-type>
	       <output:omit-xml-declaration>yes</output:omit-xml-declaration>
	       <output:encoding>utf-8</output:encoding>
       </output:serialization-parameters>
	return
		serialize(functx:change-element-ns-deep($exemplum, '', '')/*/*, $serializationParameters)
};

(:~
 : A simple mapping from schemaSpec identifiers to WeGA document types
~:)
declare function gl:schemaIdent2docType($schemaID as xs:string?) as xs:string? {
	if(matches($schemaID, '^wega[A-Z]')) then lower-case(substring-after($schemaID, 'wega'))
	else ()
};

declare %private function gl:class-members($spec as element()) as element()* {
    $spec/ancestor::tei:schemaSpec//(tei:elementSpec, tei:classSpec)[tei:classes/tei:memberOf[@key = $spec/@ident][not(@mode='delete')]]
};

declare %private function gl:specType($spec as element()) as xs:string? {
    if($spec/self::tei:elementSpec) then 'elements'
    else if($spec/self::tei:classSpec[@type='model']) then 'models'
    else if($spec/self::tei:classSpec[@type='atts']) then 'attributes'
    else if($spec/self::tei:dataSpec) then 'datatypes'
    else if($spec/self::tei:macroSpec) then 'macros'
    else ()
};