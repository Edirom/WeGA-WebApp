xquery version "1.0" encoding "UTF-8";
declare default collation "?lang=de;strength=primary";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace session = "http://exist-db.org/xquery/session";
declare namespace response = "http://exist-db.org/xquery/response";
declare namespace request = "http://exist-db.org/xquery/request";
declare namespace util   = "http://exist-db.org/xquery/util";
declare namespace ft     = "http://exist-db.org/xquery/lucene";
import module namespace kwic="http://exist-db.org/xquery/kwic";

import module namespace wega   = "http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/wega" at "xmldb:exist:///db/webapp/xql/modules/wega.xqm";
import module namespace facets = "http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/facets" at "xmldb:exist:///db/webapp/xql/modules/facets.xqm";

declare option exist:serialize "method=xhtml media-type=text/html indent=no omit-xml-declaration=yes encoding=utf-8";

declare function local:checkNodeAncestors($node,$docType) {
    if($docType='persons') then $node[ancestor-or-self::tei:note or ancestor-or-self::tei:event]
    else if($docType='letters' or $docType='writings' or $docType='news') then $node[ancestor-or-self::tei:text]
    else if($docType='diaries') then $node[ancestor-or-self::tei:ab]
    else if($docType='works') then $node[ancestor-or-self::mei:mei]
    else if($docType='biblio') then $node[ancestor-or-self::tei:TEI or ancestor-or-self::tei:biblStruct]
    else()
};

declare function local:getRootNode($node,$docType) {
    if($docType='persons')       then $node/ancestor-or-self::tei:person
    else if($docType='letters')  then $node/ancestor-or-self::tei:TEI
    else if($docType='diaries')  then $node/ancestor-or-self::tei:ab
    else if($docType='writings') then $node/ancestor-or-self::tei:TEI
    else if($docType='works')    then $node/ancestor-or-self::mei:mei
    else if($docType='news')     then $node/ancestor-or-self::tei:TEI
    else if($docType='biblio')   then for $item in $node return if($item/ancestor-or-self::tei:TEI) then $item/ancestor-or-self::tei:TEI else $item/ancestor-or-self::tei:biblStruct
    else if($docType='var')      then $node/ancestor-or-self::tei:TEI
    else()
};

declare function local:createKWIC($item as item(), $lang as xs:string) as element() {
    let $dev := wega:getOption('environment') eq 'development'
    let $kwic := util:catch('*',
        kwic:summarize($item, <config width="40"/>),
        if($dev) then string-join(('kwic:summarize', $item/@xml:id, $util:exception, $util:exception-message), ' ;; ')
        else wega:logToFile('error', string-join(('kwic:summarize', $item/@xml:id, $util:exception, $util:exception-message), ' ;; '))
        )
    let $score    := ft:score($item)
    return 
        element div {
            attribute class {'kwicResult'},
            if($dev) then element p {
                attribute class {'id'},
                if($item/@xml:id) then $item/@xml:id cast as xs:string else()
            }
            else(),
            if($dev and exists($item//mei:altId[@type="JV"])) then element p {
                attribute class {'id'},
                concat("(JV ",$item//mei:altId[@type="JV"],")")
            } 
            else(),
            if($score = 0)
            then let $docTypes   := tokenize('persons letters writings diaries works news biblio var','\s+')
                 let $kwicNew :=
                    for $docType in $docTypes
                    return
                      let $sessionVar := session:get-attribute(concat('id-kwic-',$docType))
                      let $hits := $sessionVar[./root()/descendant-or-self::*/@xml:id = $item/data(@xml:id)]
                      return
                        for $x in $hits
                        (:let $log := util:log-system-out($x):)
                        let $prev       := string-join(local:checkNodeAncestors($x/preceding::text(),$docType),'')
                        let $foll       := string-join(local:checkNodeAncestors($x/following::text(),$docType),'') 
                        let $previous   := if(string-length($prev)<50) then $prev else concat('...',substring($prev,string-length($prev)-50,string-length($prev)))
                        let $following  := if(string-length($foll)<50) then $foll else concat(substring($foll,1,50),'...')
                        (:let $sessionKey := concat('kwic-',local:getRootNode($x,$docType)/data(@xml:id)):)
                        return element p {
                                   element span {attribute class {"previous"},$previous},
                                   element span {attribute class {"hi"},data($x)},
                                   element span {attribute class {"following"},$following}
                               }
                               (:Kein Treffer im Textteil gefunden:)
                 (:let $deletion  := session:remove-attribute(concat('kwic-',$item/data(@xml:id))):)
                 return element p {$kwicNew }
            else if($dev and normalize-space(string-join($kwic,'')) eq '' and false()) (: Nur eine Überlegung :)
                 then element p {'Für dieses Suchergebnis kann leider kein KWIC (keyword in kontext) ausgegeben werden.'}
                 else for $i in 1 to 20
                     return $kwic[$i]
                 ,
                 if($dev) then element p {
                    attribute class {'score'},
                    attribute style {'visibility:hidden'},
                    $score
                 }
                 else()
        }
};

declare function local:createEntry($entry as item(), $clear as xs:boolean, $isSearchResult as xs:boolean, $lang as xs:string) as element()+ {
    let $dev := wega:getOption('environment') eq 'development'
    let $docMetaData := util:catch('*', 
        wega:getDocumentMetaData($entry, $lang, 'listView'), 
        if($dev) then element div {
            attribute class {'item'},
            string-join(('wega:getDocumentMetaData', $entry/@xml:id, $util:exception, $util:exception-message), ' ;; ')
        }
        else wega:logToFile('error', string-join(('wega:getDocumentMetaData', $util:exception, $util:exception-message), ' ;; '))
        )
    return 
        if($isSearchResult) then
            element div {
                attribute class {'searchResultEntry'},
                $docMetaData,
                local:createKWIC($entry,$lang)
            }
        else (
            $docMetaData,
            if ($clear) then <br class="clearer"/> else ()
        )
};

let $lang                   := request:get-parameter('lang', 'de')
let $sessionName            := request:get-parameter('sessionName',())
let $setHeader              := response:set-header('cache-control', 'no-cache')
let $isSearchResult         := $sessionName eq wega:getOption('searchSessionName')
let $coll                   := session:get-attribute($sessionName)
let $countColl              := count($coll)
let $countFrom              := if(request:get-parameter('countFrom','') castable as xs:int)
                               then xs:int(request:get-parameter('countFrom','')) 
                               else 1
let $countTo                := if(request:get-parameter('countTo','') castable as xs:int)
                               then xs:int(request:get-parameter('countTo','')) 
                               else xs:int($countColl)
(:let $maxDefault             := xs:int(wega:getOption('entriesPerPage')):)
let $lastItem               := $countTo - $countFrom + 1 

return
    if ($countColl > 0)
    then (
        for $entry at $count in subsequence($coll, $countFrom, $lastItem)
            let $clear := (not($isSearchResult) and (($count mod 2 eq 0) or ($count + $countFrom -1 eq $countTo)))
(:            let $log := util:log-system-out($count):)
            return local:createEntry($entry, $clear, $isSearchResult, $lang)
        )
   else element div {
            element h2{wega:getLanguageString('emptyResultSet', $lang)}
        }
        