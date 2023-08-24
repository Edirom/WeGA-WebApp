xquery version "3.1" encoding "UTF-8";

(:~
 : Various utility functions for the WeGA WebApp
:)
module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace wega="http://www.weber-gesamtausgabe.de";
declare namespace http="http://expath.org/ns/http-client";
declare namespace math="http://www.w3.org/2005/xpath-functions/math";
declare namespace owl="http://www.w3.org/2002/07/owl#";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs="http://www.w3.org/2000/01/rdf-schema#";
declare namespace sr="http://www.w3.org/2005/sparql-results#";
declare namespace schema="http://schema.org/";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace range="http://exist-db.org/xquery/range";

import module namespace functx="http://www.functx.com";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace crud="http://xquery.weber-gesamtausgabe.de/modules/crud" at "crud.xqm";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";
import module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/date.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/str.xqm";


(:~
 : Processing XML files for display (and download)
 : Comments and not-greenlisted facsimile information will be removed
 :
 : @author Peter Stadler 
 : @param $nodes the nodes to transform
 : @return transformed nodes
~:)
declare function wega-util:process-xml-for-display($nodes as node()*) as node()* {
    for $node in $nodes
    return
        typeswitch($node)
        case comment() return 
            if($config:isDevelopment) then $node
            else ()
        case element(tei:facsimile) return 
            (: the simpler test '$node = query:facsimile($node/root())' returned always true, for e.g. A041588 with two witnesses :)
            (: probably some too aggressive eXistdb optimization ... :)
            if(some $i in query:facsimile(document { $node/root() }) satisfies deep-equal($i, $node)) then 
                element {node-name($node)} {
                    $node/@*,
                    wega-util:process-xml-for-display($node/node())
                }
            else ()
        case element() return 
            element {node-name($node)} {
                $node/@*,
                wega-util:process-xml-for-display($node/node())
            }
        case document-node() return document { wega-util:process-xml-for-display($node/node()) }
        
        default return $node
};

(:~
 : Add current version information to a TEI file
 : If the file contains a tei:fileDesc a tei:editionStmt is injected,
 : otherwise a comment is written after the root element 
 :
 : @author Peter Stadler 
 : @param $nodes the nodes to transform
 : @return transformed nodes
 :)
declare function wega-util:inject-version-info($nodes as node()*) as item()* {
    for $node in $nodes
    return
        if($node instance of processing-instruction()) then (
            (: replace the schema location from development to current stable version :)
            if($node[ancestor::node()]) then $node
            else (
                processing-instruction xml-model {replace($node, '(main|master|develop)', 'v' || config:get-option('ODDversion'))}
            )
        )
        (: inject editionStmt element after the titleStmt :)
        else if($node instance of element(tei:titleStmt)) then (
            if($node/parent::tei:fileDesc/parent::tei:teiHeader/parent::tei:TEI) then ( (: make sure we're dealing with the right titleStmt :)
                let $editionStmt := wega-util:editionStmt()
                return (
                    $node,
                    '&#10;&#9;&#9;&#9;', (: Indentation :)
                    element {QName('http://www.tei-c.org/ns/1.0', 'editionStmt')} {
                        '&#10;&#9;&#9;&#9;&#9;',
                        element {QName('http://www.tei-c.org/ns/1.0', 'p')} {
                            $editionStmt?version
                        },
                        '&#10;&#9;&#9;&#9;&#9;',
                        element {QName('http://www.tei-c.org/ns/1.0', 'p')} {
                            $editionStmt?download
                        },
                        '&#10;&#9;&#9;&#9;'
                    }
                )
            )
            else $node
        )
        
        else if($node instance of element(tei:text)) then $node (: shortcut :)
        
        (: inject version information as comment after the root element :)
        else if($node instance of element(tei:ab)) then wega-util:editionStmt2comment($node)
        else if($node instance of element(tei:person)) then wega-util:editionStmt2comment($node)
        else if($node instance of element(tei:place)) then wega-util:editionStmt2comment($node)
        else if($node instance of element(tei:biblStruct)) then wega-util:editionStmt2comment($node)
        else if($node instance of element(tei:org)) then wega-util:editionStmt2comment($node)
        
        (: fallback: identity transformation :)
        else if($node instance of element()) then 
            element {node-name($node)} {
                $node/@*,
                wega-util:inject-version-info($node/node())
            }
        else if($node instance of document-node()) then document { wega-util:inject-version-info($node/node()) }
        else $node
};

(:~
 : Helper function for wega-util:inject-version-info()
~:)
declare %private function wega-util:editionStmt() as map(*) {
    let $lang := config:guess-language(())
    return
        map {
            'version' :    lang:get-language-string(
                                'versionInformation', (
                                    config:expath-descriptor()/@version, 
                                    date:format-date(xs:date(config:get-option('versionDate')), $config:default-date-picture-string($lang), $lang)
                                ), 
                                $lang
                            ),
            'download' : lang:get-language-string('downloaded_on', $lang) || ': ' || current-dateTime()
        }
};

(:~
 : Helper function for wega-util:inject-version-info()
~:)
declare %private function wega-util:editionStmt2comment($node as node()?) as node()? {
    if($node[ancestor::node()]) then $node
    else (
        let $editionStmt := wega-util:editionStmt()
        return (
            element {node-name($node)} {
                $node/@*,
                comment {$editionStmt?version || '. ' || $editionStmt?download },
                $node/node()
            }
        )
    )
};

(:~
 : Recursively remove idiosyncratic WeGA elements ('workName', 'characterName') and turn them into generic TEI <rs> elements
 :
 : @author Peter Stadler 
 : @param $nodes the nodes to transform
 : @return transformed nodes
~:)
declare function wega-util:substitute-wega-element-additions($nodes as node()*) as node()* {
    for $node in $nodes
    return
        if($node instance of processing-instruction()) then $node
        else if($node instance of comment()) then $node
        else if($node instance of element(tei:workName) or $node instance of element(tei:characterName)) then
            element {QName('http://www.tei-c.org/ns/1.0', 'rs')} {
                $node/@*,
                attribute type { substring-before(local-name($node), 'Name') },
                wega-util:substitute-wega-element-additions($node/node())
            }
        else if($node instance of element()) then 
            element {node-name($node)} {
                $node/@*,
                wega-util:substitute-wega-element-additions($node/node())
            }
        else if($node instance of document-node()) then document { wega-util:substitute-wega-element-additions($node/node()) }
        else $node
};

(:~
 : A wrapper function around eXist's transform:transform()
 : Applies a shortcut for empty and text only contents
~:)
declare function wega-util:transform($node-tree as node()*, $stylesheet as item(), $parameters as node()?) as item()* {
    if(every $i in $node-tree satisfies functx:all-whitespace($i)) then () 
    else if($node-tree/*) then transform:transform($node-tree, $stylesheet, $parameters)
    else $node-tree ! str:normalize-space(.)
};

(:~
 : A function for logging the query times
 :
 : @param $func the function to watch
 : @param $func-params the function parameters
 : @param $mesg an optional message to append for the logging
 : @return Timing information is written into the log file and the results of $func are returned 
~:)
declare function wega-util:stopwatch($func as function() as item(), $func-params as item()*, $mesg as xs:string?) as item()* {
    let $startTime := util:system-time()
    let $result := 
        if(count($func-params) eq 0) then $func()
        else if(count($func-params) eq 1) then $func($func-params)
        else if(count($func-params) eq 2) then $func($func-params[1], $func-params[2])
        else if(count($func-params) eq 3) then $func($func-params[1], $func-params[2], $func-params[3])
        else if(count($func-params) eq 4) then $func($func-params[1], $func-params[2], $func-params[3], $func-params[4])
        else error(xs:QName('wega-util:error'), 'Too many arguments to callback function of wega-util:stopwatch()')
    let $message := 
        if(exists($mesg)) then ' [' || $mesg || ']'
        else ()
    return (
        $result, 
        wega-util:log-to-file('debug', 'stopwatch (' || function-name($func) || '): ' || string(seconds-from-duration(util:system-time() - $startTime)) || $message)
    )
};

(:~
 : Creates a simple text version of a TEI document (or fragment)
 : by resolving choices, substitutions and removing notes
 : (used for e.g. wordOfTheDay and several titles)
 :
 : @param $nodes the nodes to transform
~:)
declare function wega-util:txtFromTEI($nodes as node()*) as xs:string* {
    for $node in $nodes
    return
        typeswitch($node)
        case element(tei:forename) return 
        	if($node/@cert) then ($node/child::node() ! wega-util:txtFromTEI(.), '(?)') 
        	else $node/child::node() ! wega-util:txtFromTEI(.)
        case element(tei:del) return ()
        case element(tei:subst) return $node/child::element() ! wega-util:txtFromTEI(.)
        case element(tei:note) return ()
        case element(tei:lb) return 
            if($node[@type='inWord' or @break='no']) then ()
            else '&#10;'
        case element(tei:pb) return 
            if($node[@type='inWord' or @break='no']) then ()
            else ' '
        case element(tei:cb) return 
            if($node[@type='inWord' or @break='no']) then ()
            else ' '
        case element(tei:q) return 
            if((count($node/ancestor::tei:q | $node/ancestor::tei:quote) mod 2) = 0) then str:enquote($node/child::node() ! wega-util:txtFromTEI(.), config:guess-language(()))
            else str:enquote-single($node/child::node() ! wega-util:txtFromTEI(.), config:guess-language(()))
        case element(tei:quote) return 
            if($node[@rend='double-quotes']) then str:enquote($node/child::node() ! wega-util:txtFromTEI(.), config:guess-language(()))
            else str:enquote-single($node/child::node() ! wega-util:txtFromTEI(.), config:guess-language(()))
        case element(tei:supplied) return ('[', $node/child::node() ! wega-util:txtFromTEI(.), ']') 
        case text() return replace($node, '\n+', ' ')
        case document-node() return $node/child::node() ! wega-util:txtFromTEI(.) 
        case processing-instruction() return ()
        case comment() return ()
        default return $node/child::node() ! wega-util:txtFromTEI(.)
};

(:~
 : Removes descendant elements from all of the nodes in $nodes based on the class name.
 : Inspired by functx:remove-elements-deep
~:)
declare function wega-util:remove-elements-by-class($nodes as node()*, $classes as xs:string*) as node()* {
	if($nodes/descendant-or-self::*[@class = tokenize($classes, '\s+')]) then
	    for $node in $nodes
	    return
	        typeswitch($node)
	        case element() return
	            if ($node[@class = tokenize($classes, '\s+')]) then ()
	            else 
	                element { node-name($node) } { 
	                    $node/@*,
	                    wega-util:remove-elements-by-class($node/node(), $classes)
	                }
	        case document-node() return document { wega-util:remove-elements-by-class($node/node(), $classes) }
	        default return $node
    else $nodes
};

(:~
 : Helper function for computing geo loc distances 
~:)
declare %private function wega-util:deg2rad($deg as xs:double) as xs:double {
   $deg * ( math:pi() div 180 )
};

(:~
 : The haversine distance of two points on the Earth
 : NB: The implementation seems buggy!
 : Compare with http://www.movable-type.co.uk/scripts/latlong.html
~:)
declare function wega-util:haversine-distance($lat1 as xs:double, $lon1 as xs:double, $lat2 as xs:double, $lon2 as xs:double) as xs:double {
   let $radius-of-earth := 6371 (: Radius of the earth in km :)
   let $p := 0.017453292519943295 (: Math.PI / 180 :)
   let $dLat := $lat2 - $lat1 (:local:deg2rad($lat2 - $lat1):)
   let $dLon := $lon2 - $lon1 (:local:deg2rad($lon2 - $lon1):)
   let $a :=
      0.5 - math:cos($dLat * $p) div 2 +
      math:cos($lat1 * $p) * math:cos($lat2 * $p) *
      (1 - math:cos($dLon * $p)) div 2
   return
      2 * $radius-of-earth * math:sin(math:sqrt($a))
};

(:~
 : The "Spherical Law of Cosines" distance of two points on the Earth
 : Outlined at http://www.movable-type.co.uk/scripts/latlong.html
~:)
declare function wega-util:spherical-law-of-cosines-distance($latLon1 as array(*), $latLon2 as array(*)) as xs:double {
   let $radius-of-earth := 6371 (: Radius of the earth in km :)
   let $dLon := wega-util:deg2rad($latLon2(2) - $latLon1(2))
   let $a :=
      math:sin(wega-util:deg2rad($latLon1(1))) * math:sin(wega-util:deg2rad($latLon2(1))) +
      math:cos(wega-util:deg2rad($latLon1(1))) * math:cos(wega-util:deg2rad($latLon2(1))) *
      math:cos($dLon)
   return
      math:acos($a) * $radius-of-earth 
};

declare function wega-util:distance-between-places($placeID1 as xs:string, $placeID2 as xs:string) as xs:double {
   let $places := crud:data-collection('places')
   let $latLon1 := array { tokenize($places/id($placeID1)//tei:geo, '\s+') ! . cast as xs:double }
   let $latLon2 := array { tokenize($places/id($placeID2)//tei:geo, '\s+') ! . cast as xs:double }
   return 
      wega-util:spherical-law-of-cosines-distance($latLon1, $latLon2)
};

(:~
 :  Checker whether we need to update a given (cached) file
 :  (Helper function for caching functions, e.g. cache:doc() from namespace http://xquery.weber-gesamtausgabe.de/modules/cache )
 :
 :  @param $currentDateTimeOfFile the last modification date of the file
 :  @param $lease the maximum lease duration for that file
 :  @return true() or false() 
~:)
declare function wega-util:check-if-update-necessary($currentDateTimeOfFile as xs:dateTime?, $lease as xs:dayTimeDuration?) as xs:boolean {
    let $my-lease :=
        if(exists($lease)) then $lease
        else 
            try { config:get-option('lease-duration') cast as xs:dayTimeDuration }
            catch * { xs:dayTimeDuration('P1D'), wega-util:log-to-file('error', string-join(('wega-util:check-if-update-necessary', $err:code, $err:description, ' no default "lease-duration" with the datatype xs:dayTimeDuration was found in the options file. Moving on with caching for one day, i.e. "P1D.'), ' ;; '))}
    return
        (: Aktualisierung entweder bei geänderter Datenbank oder bei veraltetem Cache :) 
        config:eXistDbWasUpdatedAfterwards($currentDateTimeOfFile) or $currentDateTimeOfFile + $my-lease lt current-dateTime()
        (: oder bei nicht vorhandener Datei oder nicht vorhandenem $lease:)
        or empty($my-lease) or empty($currentDateTimeOfFile)
};

(:~ 
 : Print forename surname from a TEI persName element
 : In contrast to str:print-forename-surname() this function checks the appearance of forenames, i.e.
 : <persName type="reg"><forename>Eugen</forename> <forename>Friedrich</forename> <forename>Heinrich</forename>, <roleName>Herzog</roleName> <nameLink>von</nameLink> Württemberg</persName>
 : is turned into "Eugen Friedrich Heinrich, Herzog von Württemberg" rather than "Herzog von Württemberg Eugen Friedrich Heinrich"
 :
 : @param $name a tei persName element
 : @author Peter Stadler
 : @return xs:string
 :)
declare function wega-util:print-forename-surname-from-nameLike-element($nameLikeElement as element()?) as xs:string? {
    let $id := $nameLikeElement/(@key, @codedval)
    return
        (: the most specific case first: a reg-name with leading forename, e.g. `<persName type="reg"><forename>Eugen</forename> <forename>Friedrich</forename>…`  :)
        if(($nameLikeElement/element()[1])[self::tei:forename]) then str:normalize-space($nameLikeElement)
        (: any other persName will recursively apply this function :)
        else if($id and config:is-person($id)) then wega-util:print-forename-surname-from-nameLike-element(crud:doc($id)//tei:persName[@type='reg'])
        (: the default case for persnames: swap the order of forename und surname :)
        else if($nameLikeElement[@type='reg']) then str:print-forename-surname($nameLikeElement)
        (: org with key:)
        else if($id and config:is-org($id)) then query:title($id)
        (: any name without key / or multiple keys, e.g. `<rs type="persons" key="A001234 A004321">:)
        (: NB: there may be nested elements (e.g. <supplied> in bibliographies) which we need to process first :)
        else if (not(functx:all-whitespace($nameLikeElement))) then str:print-forename-surname(wega-util:transform($nameLikeElement, doc(concat($config:xsl-collection-path, '/var.xsl')), config:get-xsl-params(())))
        (: fallback: anonymous :)
        else query:title(config:get-option('anonymusID'))
};

(:~
 : Infer our local settlement WeGA ID from a RISM siglum
 :
 : @param $siglum a RISM siglum (see http://www.rism.info/en/sigla.html)
 : @return the corresponding WeGA ID for the settlement
 :)
declare function wega-util:settlement-key-from-rism-siglum($siglum as xs:string) as xs:string {
    let $keys := crud:data-collection('letters')//tei:repository[range:field-eq('rism-siglum', $siglum)]/preceding-sibling::tei:settlement/@key
    return string($keys[1])
};

(:~
 : Write log message to log file
 :
 : @author Peter Stadler
 : @param $priority to be used by util:log-app:  'error', 'warn', 'debug', 'info', 'trace'
 : @param $message the log message
:)
declare function wega-util:log-to-file($priority as xs:string, $message as xs:string) as empty-sequence() {
    let $file := config:get-option('errorLogFile')
    let $message := concat($message, ' (rev. ', config:getCurrentSvnRev(), ')')
    return (
        util:log-app($priority, $file, $message),
        if($config:isDevelopment and ($priority = ('error', 'warn', 'debug'))) then util:log-system-out($message)
        else ()
    )
};
