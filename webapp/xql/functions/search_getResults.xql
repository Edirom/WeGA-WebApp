xquery version "1.0" encoding "UTF-8";
declare default collation "?lang=de;strength=primary";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace session = "http://exist-db.org/xquery/session";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace response="http://exist-db.org/xquery/response";
declare namespace util = "http://exist-db.org/xquery/util";
declare namespace ft   = "http://exist-db.org/xquery/lucene";
declare namespace kwic = "http://exist-db.org/xquery/kwic";
import module namespace wega = "http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/wega" at "xmldb:exist:///db/webapp/xql/modules/wega.xqm";
import module namespace facets = "http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/facets" at "xmldb:exist:///db/webapp/xql/modules/facets.xqm";
import module namespace functx="http://www.functx.com" at "xmldb:exist:///db/webapp/xql/modules/functx.xqm";

declare option exist:serialize "method=xhtml media-type=text/html indent=no omit-xml-declaration=yes encoding=utf-8";

declare variable $local:docTypesForSearch := ('persons','letters','writings','diaries','works','news','biblio','var');

declare function local:getCollection($docType as xs:string, $useCache as xs:boolean) {
    if($useCache)
    then facets:getOrCreateColl($docType,'indices')
    else facets:createColl($docType,'indices')
    (:    if($docType eq 'persons')       then collection(wega:getOption('persons'))//tei:person[not(./tei:ref)] (\: exclude duplicates :\)
        else if($docType eq 'letters')  then collection(wega:getOption('letters'))//tei:TEI[not(./tei:ref)]
        else if($docType eq 'diaries')  then collection(wega:getOption('diaries'))//tei:ab
        else if($docType eq 'works')    then collection(wega:getOption('works'))//mei:mei
        else if($docType eq 'news')     then collection(wega:getOption('news'))//tei:TEI
        else if($docType eq 'writings') then collection(wega:getOption('writings'))//tei:TEI[not(./tei:ref)]
        else if($docType eq 'biblio')   then collection(wega:getOption('biblio'))/tei:TEI | collection(wega:getOption('biblio'))/tei:biblStruct
        else if($docType eq 'var')      then collection(wega:getOption('var'))//tei:TEI
        else():)
};


(:~
 : Creates the query-element for a lucene search. For example:
 : <query>
 :   <phrase slop="2">weber carl</phrase>
 :   <bool><term occur="must">weber</term><term occur="must">carl</term></bool>
 : </query>
 :
 : @author Christian Epp
 : @param $searchString the given search string like "weber carl" or "webe*" or "'carl maria'"
 : @param $type can be "fullText", "persName" or "placeName"
 : @return the query as XML or ()
 :)

declare function local:buildQuery($searchString,$type) {
    if($searchString = '') then ''
    else
    let $hasWildcards       := matches($searchString, '.(\*|\?).')
    let $hasQuotationMarks  := matches($searchString,'".+"') or matches($searchString,"'.+'")
    let $hasHyphen          := matches($searchString, '-')
    (:let $searchString		:= replace(replace($searchString,"'",''),'"',''):)
	let $searchSequence     := for $x in tokenize($searchString,'\s+') return replace($x,'_',' ')
    let $query :=
       if($hasHyphen) then $searchString
       else if($hasWildcards)
       then <query><bool>{for $x in $searchSequence return <wildcard occur="must">{lower-case($x)}</wildcard>}</bool></query>
       else 
         if ($type = 'fullText')
         then
           <query>{
               if($hasQuotationMarks)
               then <bool>{for $x in $searchSequence return <phrase occur="must">{$x}</phrase>}</bool>
               else (
                   (: Bei slop=4 wurde "carl maria von weber" überhaupt erst gefunden(ohne die bool-Sachen) :)
                   <phrase slop="4">{$searchString}</phrase>,
                   <bool>{for $x in $searchSequence return <term occur="must">{$x}</term>}</bool>,
                   <bool>{for $x in $searchSequence return <wildcard occur="must">{lower-case($x)}*</wildcard>}</bool>,
                   <bool maxClauseCount="20000">{for $x in $searchSequence return <wildcard occur="must">*{lower-case($x)}*</wildcard>}</bool>
               )}
           </query>
         
         else if ($type = 'persName' or $type = 'placeName' or $type = 'persNameSender' or $type = 'persNameAddressee' or $type = 'occupation')
           then
             <query>{if($hasQuotationMarks)
                   then <bool>{for $x in $searchSequence return <phrase occur="must">{$x}</phrase>}</bool>
                   else <bool>{for $x in $searchSequence return <term occur="must">{$x}</term>}</bool>
             }</query>
         else $searchString
     (:let $log := util:log-system-out($query):)
     return $query
};
(:
 : Hilfsfunktion für Suche in date-Tags
 :)
declare function local:buildQueryTo($query,$nextMonth) {
    let $yearTo := number(substring($query,1,4))
    (:let $yearTo := number(substring-before($query,'-')):)
    let $result :=
      if(string-length($query) = 4)
      then concat(number($query)+1,'-01-01')
      else if(string-length($query) = 7)
           then concat(if($nextMonth<13) then $yearTo else $yearTo+1,'-',if($nextMonth<13) then if($nextMonth>9) then $nextMonth else concat('0',$nextMonth) else '01','-01')
           else()
    return $result
};

declare function local:getRootNode($node,$docType) {
    if($docType='persons')       then $node/ancestor-or-self::tei:person
    else if($docType='letters')  then $node/ancestor-or-self::tei:TEI
    else if($docType='diaries')  then $node/ancestor-or-self::tei:ab
    else if($docType='writings') then $node/ancestor-or-self::tei:TEI
    else if($docType='works')    then $node/ancestor-or-self::mei:mei
    else if($docType='news')     then $node/ancestor-or-self::tei:TEI
    else if($docType='biblio')   then $node/ancestor-or-self::tei:TEI | $node/ancestor-or-self::tei:biblStruct
(: for $item in $node return if($item/ancestor-or-self::tei:TEI) then $item/ancestor-or-self::tei:TEI else $item/ancestor-or-self::tei:biblStruct :)
    else if($docType='var')      then $node/ancestor-or-self::tei:TEI
    else()
};

declare function local:checkNodeAncestors($node,$docType) {
    if($docType='persons') then $node[ancestor-or-self::tei:note or ancestor-or-self::tei:event]
    else if($docType='letters' or $docType='writings' or $docType='news') then $node[ancestor-or-self::tei:text]
    else if($docType='diaries') then $node[ancestor-or-self::tei:ab]
    else if($docType='works') then $node[ancestor-or-self::mei:mei]
    else if($docType='biblio') then $node[ancestor-or-self::tei:TEI or ancestor-or-self::tei:biblStruct]
    else()
};

declare function local:saveKWIC($result,$docType) {
   for $x in $result
   let $prev       := string-join(local:checkNodeAncestors($x/preceding::text(),$docType),'')
   let $foll       := string-join(local:checkNodeAncestors($x/following::text(),$docType),'') 
   let $previous   := if(string-length($prev)<150) then $prev else concat('...',substring($prev,string-length($prev)-150,string-length($prev)))
   let $following  := if(string-length($foll)<150) then $foll else concat(substring($foll,1,150),'...')
   let $sessionKey := concat('kwic-',local:getRootNode($x,$docType)/data(@xml:id))
   
   return session:set-attribute($sessionKey,($previous,data($x),$following))
};

declare function local:searchForId($coll,$query,$docType) {
    let $doc := $coll/id($query)
    let $firstDoc := if($doc) then session:set-attribute('firstDoc',$doc) else()
    let $sessionKey := concat('kwic-',local:getRootNode($doc,$docType)/data(@xml:id))
    let $kwic := session:set-attribute($sessionKey,('Name:',data($doc//tei:persName[@type="reg"])))
    
    let $result :=
        if($docType eq 'works')
        then $coll//mei:persName[@dbkey = $query]
        else $coll//tei:persName[@key = $query] | $coll//tei:rs[@type='person' and @key = $query] (:| $coll//tei:rs[@type='persons' and ft:query(./@key,$query)]:) | $coll//tei:workName[@key = $query]
    (:let $log := util:log-system-out(count($result)):)
    let $p := session:set-attribute(concat('id-kwic-',$docType),$result)
    return local:getRootNode($result,$docType)
};

declare function local:searchForPND($coll,$query,$docType) {
    let $person := $coll//tei:idno[.=$query][@type="gnd"]/parent::tei:person
    let $firstDoc := if($person) then session:set-attribute('firstDoc',$person) else()    
    let $personId := if($person) then $person/@xml:id cast as xs:string else()
    return local:searchForId($coll,$personId,$docType)
};

declare function local:searchForKS($coll,$query,$docType) {
    let $result := if($query="*") then $coll//tei:idno[@type='KS'] else $coll//tei:idno[@type='KS' and @n=$query]
    return local:getRootNode($result,$docType)
};

declare function local:searchForDate($coll,$query,$docType) {
    let $nextMonth := number(substring($query,6,7))+1
    let $query     := if(string-length($query) = 4) then concat($query,'-01-01') else if(string-length($query) = 7) then concat($query,'-01') else $query
    let $queryTo   := local:buildQueryTo($query,$nextMonth)
    let $queryTo   := if($queryTo) then xs:date($queryTo) else()
    let $result :=
        if(not($query castable as xs:date)) then ()
        else 
            let $query := xs:date($query)
            return
                if($queryTo)
                then if($docType eq 'works')
                     then $coll//mei:date[(@notbefore >= $query and @notafter < $queryTo) or (@from >= xs:date($query) and @to < $queryTo) or (@reg >= $query and @reg < $queryTo)]
                     else $coll//tei:date[(@notBefore >= $query and @notAfter < $queryTo) or (@from >= $query and @to < $queryTo) or (@when >= $query and @when < $queryTo)]
                else if($docType eq 'works')
                     then 
                        for $d in $coll//mei:date
                        return (: Abfragen, ob die Daten in den Datein korrekt sind... :)
                            if($d/@notbefore and $d/@notbefore castable as xs:date and $d/@notafter castable as xs:date) then $d[@notbefore <= $query and @notafter >= $query]
                            else if($d/@from and $d/@from castable as xs:date and $d/@to castable as xs:date) then $d[@from <= $query and @to >= $query]
                            else $d[@reg  = $query]
                            (:$coll//mei:date[(@notbefore <= $query and @notafter >= $query)  or (@from <= $query and @to >= $query)  or @reg  = $query]:)
                     else $coll//tei:date[(@notBefore <= $query and @notAfter >= $query)  or (@from <= $query and @to >= $query)  or @when = $query]
    return local:getRootNode($result,$docType)
};

declare function local:searchForPersName($coll,$query,$docType) {
    let $result :=
        if($docType eq 'works')
        then $coll//mei:persName[ft:query(., $query)]
        else let $temp := $coll//tei:persName[ft:query(., $query)]
             return if($docType eq 'person')
                    then $temp | $coll//tei:surname[ft:query(., $query)]
                    else if($docType eq 'news' or $docType eq 'letters' or $docType eq 'diaries')
                         then $temp | $coll//tei:body//tei:rs[ft:query(.[@type eq 'person'],$query)] | $coll//tei:body//tei:rs[ft:query(.[@type eq 'persons'],$query)] 
                         else $temp
    return local:getRootNode($result,$docType)
};

declare function local:searchFullText($coll,$query,$docType) {
     let $result :=
        if($docType='persons')       then $coll//tei:person[ft:query(., $query)] | $coll//tei:persName[@type][ft:query(., $query)]
        else if($docType='letters')  then $coll//tei:body[ft:query(., $query)]   | $coll//tei:correspDesc[ft:query(., $query)] | $coll//tei:title[ft:query(., $query)] |
                                          $coll//tei:incipit[ft:query(., $query)] | $coll//tei:note[ft:query(.[@type eq 'summary'], $query)]
        else if($docType='diaries')  then $coll//tei:ab[ft:query(., $query)]
        else if($docType='writings') then $coll//tei:body[ft:query(., $query)]/ancestor::tei:TEI | $coll//tei:title[ft:query(., $query)]/ancestor::tei:TEI
        else if($docType='works')    then $coll//mei:mei[ft:query(., $query)] | $coll//mei:title[ft:query(., $query)]
        else if($docType='news')     then $coll//tei:body[ft:query(., $query)]/ancestor::tei:TEI | $coll//tei:title[ft:query(., $query)]/ancestor::tei:TEI
        else if($docType='biblio')   then $coll//tei:text[ft:query(., $query)] | $coll//tei:biblStruct[ft:query(., $query)] | $coll//tei:title[ft:query(., $query)] | $coll//tei:author[ft:query(., $query)] | $coll//tei:editor[ft:query(., $query)]
        else if($docType='var')      then collection('/db/var')//tei:body[ft:query(.,$query)]/ancestor::tei:TEI | collection('/db/var')//tei:title[ft:query(.,$query)]/ancestor::tei:TEI
        else()
    return local:getRootNode($result,$docType)
};

(:~
 : Creates the collection of documents that match the specified query
 :
 : @author Christian Epp
 : @param $docType can be "persons","letters" or "diaries". defines, in which collection to search
 : @param $searchFilter search syntax expression
 : @param $query the <query/>-element for lucene search or a string, when the searchFilter is "date","id" oder "pnd"
 : @return the resulting sequence of documents 
 :)
declare function local:createSearchField($docType,$searchFilter,$query) {
  let $coll      := local:getCollection($docType,true())
  (:let $log := util:log-system-out(concat('#',$query)):)
  return
    if($searchFilter='fullText')      then local:searchFullText($coll,$query,$docType)
    else if($searchFilter='persName') then local:searchForPersName($coll,$query,$docType)
    else if($searchFilter='id')       then local:searchForId($coll,$query,$docType)
    else if($searchFilter='pnd')      then local:searchForPND($coll,$query,$docType)
    else if($searchFilter='ks')       then local:searchForKS($coll,$query,$docType)
    else if($searchFilter='date')     then local:searchForDate($coll,$query,$docType)
    
    else if($docType='persons')
         then if($searchFilter='placeName')         then $coll//tei:person[ft:query(.//tei:residence, $query)] | $coll//tei:person[ft:query(.//tei:placeName, $query)]
         (:else if($searchFilter='pnd')               then $coll//tei:person[@corresp = $query]:)
         else if($searchFilter='asksam')            then for $x at $i in $coll//tei:person/comment() return if(contains(lower-case($x), lower-case($query))) then($x/root()/tei:person) else()
         else if($searchFilter='occupation')        then $coll//tei:person//tei:occupation[ft:query(., $query)]/ancestor::tei:person
         else()
    else if($docType='letters')
         then if($searchFilter='persNameSender')    then $coll//tei:correspDesc/tei:sender/tei:persName[ft:query(.,$query)]/ancestor::tei:TEI
         else if($searchFilter='persNameAddressee') then $coll//tei:correspDesc/tei:addressee/tei:persName[ft:query(.,$query)]/ancestor::tei:TEI
         else if($searchFilter='asksam')            then for $x at $i in $coll//tei:TEI/comment() return if(contains(lower-case($x), lower-case($query))) then($x/root()/tei:TEI) else()
         else()
    else()
};

(:~
 : Helps local:getResults() to intersect results of different types. This one is for lucene search
 :
 : @author Christian Epp
 : @param $result the results up to this point
 : @param $docType can be "persons","letters" or "diaries". defines, in which collection to search
 : @param $searchFilter search syntax expression
 : @param $query the <query/>-element for lucene search or a string, when the searchFilter is "date","id" or "pnd"
 : @return sequence of documents
 :)
 
declare function local:intersectLuceneResults($result, $docType, $searchFilter, $query) {
    if($query = '') then $result
    else
        if(empty($result)) then local:createSearchField($docType, $searchFilter, $query)
        else $result intersect  local:createSearchField($docType, $searchFilter, $query)
};

(:~
 : Helps local:getResults() to intersect results of different types. This is for search without lucene
 :
 : @author Christian Epp
 : @param $result the results up to this point
 : @param $docType can be "persons","letters" or "diaries". defines, in which collection to search
 : @param $searchFilter search syntax expression
 : @param $querySeq sequence of <query/>-elements for lucene search or
 : @return sequence of documents
 :)
 
declare function local:intersectOtherResults($result, $docType, $searchFilter, $querySeq) {
	if(count($querySeq) = 0) then $result
	else if(count($querySeq) = 1)
		 then $result intersect local:createSearchField($docType,$searchFilter,$querySeq[1])
		 else $result intersect local:createSearchField($docType,$searchFilter,$querySeq[1]) intersect local:intersectOtherResults($result, $docType, $searchFilter, remove($querySeq,1)) 
};

(:declare function local:getOneResult($docType,$searchFilter) {
    if(request:get-parameter-names() = $searchFilter)
    then local:createSearchField($docType, $searchFilter, request:get-parameter($searchFilter,''))
    else()
};:)

(:declare function local:intersection($resultSeq) {
    if(exists($resultSeq[2])) then $resultSeq[1] intersect local:intersection(remove($resultSeq,1)) else $resultSeq[1]
};:)

(:~
 : Gives the complete results for a given document type
 : 
 : @author Christian Epp
 : @param $searchStringSequence sequence of search strings split up by search syntax expressions
 : @param $docType can be "persons","letters" or "diaries". defines, in which collection to search
 : @return sequence of root nodes
 :)
 
declare function local:getResults($docType as xs:string) as element()* {
    if(request:get-parameter('searchString','')='') then local:getCollection($docType,true())
    else
        let $result := local:intersectLuceneResults((), $docType, 'fullText',          local:buildQuery(request:get-parameter('fullText',''),'fullText'))
        let $result := local:intersectLuceneResults($result, $docType, 'persName',          local:buildQuery(request:get-parameter('persName',''),'persName'))
        let $result := local:intersectLuceneResults($result, $docType, 'persNameSender',    local:buildQuery(request:get-parameter('persNameSender',''),'persNameSender'))
        let $result := local:intersectLuceneResults($result, $docType, 'persNameAddressee', local:buildQuery(request:get-parameter('persNameAddressee',''),'persNameAddressee'))
        let $result := local:intersectLuceneResults($result, $docType, 'placeName',         local:buildQuery(request:get-parameter('placeName',''),'placeName'))
        let $result := local:intersectLuceneResults($result, $docType, 'occupation',        local:buildQuery(request:get-parameter('occupation',''),'occupation'))
        let $result := local:intersectOtherResults( $result, $docType, 'date',   tokenize(request:get-parameter('date',''),'\s+'))
        let $result := local:intersectOtherResults( $result, $docType, 'id',     tokenize(request:get-parameter('id',''),'\s+'))
        let $result := local:intersectOtherResults( $result, $docType, 'pnd',    tokenize(request:get-parameter('pnd',''),'\s+'))
        let $result := local:intersectOtherResults( $result, $docType, 'asksam', tokenize(request:get-parameter('asksam',''),'\s+'))
        let $result := local:intersectOtherResults( $result, $docType, 'ks',     tokenize(request:get-parameter('ks',''),'\s+'))
        return $result
};

    (:
        Hier zum Testen:
          declare namespace tei="http://www.tei-c.org/ns/1.0";
          let $r1 := collection('/db/persons')//tei:persName[ft:query(.,'peter')]/root()
          let $r2 := collection('/db/persons')//tei:persName[ft:query(.,'fuchs')]/root()
          let $result := ($r1,$r2)
          return $result[1] intersect $result[2]
        Wenn man am Ende "$r1 intersect $r2" schreibt, geht es :(
    :)


(:~
 : special function only used if one searches for a single date
 :
 : @author Christian Epp
 : @param $searchString the given date string like "1817-01-01" or "1817"
 : @param $docType can be "persons","letters" or "diaries". defines, in which collection to search 
 : @return sequence of documents
 :)
declare function local:getOnlyOneDateResults($searchString,$docType) {
    let $query     := replace($searchString,'"','')
    let $nextMonth := number(substring($query,6,7))+1
    let $queryTo   := local:buildQueryTo($query,$nextMonth)
    let $queryTo   := if($queryTo) then xs:date($queryTo) else()
    let $query     := if(string-length($query) = 4) then concat($query,'-01-01') else if(string-length($query) = 7) then concat($query,'-01') else $query
    let $coll      := local:getCollection($docType,true())
    
    let $coll1 :=  
        if(exists($queryTo))
        then if($docType = 'works') (: q<=w<qt | q<=f & t<qt :)
             then $coll//mei:date[(@reg  >= xs:date($query) and @reg  < xs:date($queryTo)) or (@from >= xs:date($query) and @to < xs:date($queryTo))]
             else $coll//tei:date[(@when >= xs:date($query) and @when < xs:date($queryTo)) or (@from >= xs:date($query) and @to < xs:date($queryTo))]
        else if($docType = 'works') (: w=d | f<=d<=t :)
             then $coll//mei:date[@reg  = xs:date($query) or (@from <= xs:date($query) and @to >= xs:date($query))]
             else $coll//tei:date[@when = xs:date($query) or (@from <= xs:date($query) and @to >= xs:date($query))]
    let $coll2 :=
        if(exists($queryTo))
        then if($docType = 'works') (: q<=nb & na<qt :)
             then $coll//mei:date[@notBefore >= xs:date($query) and @notAfter < xs:date($queryTo)]
             else $coll//tei:date[@notBefore >= xs:date($query) and @notAfter < xs:date($queryTo)]
        else if($docType = 'works') (: nb<=q<=na :)
             then $coll//mei:date[@notBefore <= xs:date($query) and @notAfter >= xs:date($query)]
             else $coll//tei:date[@notBefore <= xs:date($query) and @notAfter >= xs:date($query)]
    let $result1 := if($query castable as xs:date) then local:getRootNode($coll1,$docType) else()
    let $result2 := if($query castable as xs:date) then local:getRootNode($coll2,$docType) else()
    return $result1 | $result2
};

(: ############################# :)

let $lang         := request:get-parameter('lang','de')
let $setHeader    := response:set-header('cache-control','no-cache')
let $searchString := request:get-parameter('searchString','')
let $docTypes := functx:value-intersect($local:docTypesForSearch, request:get-parameter('collection',$local:docTypesForSearch)) (: Never trust user input :)
    
(:let $log := util:log-system-out($docTypes):)

let $numberOfSearchItems := count(distinct-values(tokenize($searchString,'\s+')))

let $search := if(request:get-parameter-names() = "date" and  $numberOfSearchItems = 1)
    then for $docType in $docTypes return local:getOnlyOneDateResults(distinct-values(tokenize(request:get-parameter('date',''),'\s+')),$docType) 
    else for $docType in $docTypes return local:getResults($docType)

let $searchResults := for $x in $search order by ft:score($x) descending, $x(://tei:persName[@type="reg"]:) ascending return $x
let $firstDoc := session:get-attribute('firstDoc')
let $searchResults := ($firstDoc,$searchResults except $firstDoc)
let $firstDoc := session:remove-attribute('firstDoc')
let $deletion := session:remove-attribute(wega:getOption('searchSessionName'))
let $result := session:set-attribute(wega:getOption('searchSessionName'), $searchResults) (: Speichert das Ergebnis in der Sessionvariable :)
return count($searchResults)
