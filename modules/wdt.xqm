xquery version "3.1";

(:~
 : WeGA document types are defined here in an object oriented manner
 :)
module namespace wdt="http://xquery.weber-gesamtausgabe.de/modules/wdt";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace xhtml="http://www.w3.org/1999/xhtml";

import module namespace functx="http://www.functx.com";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";
import module namespace norm="http://xquery.weber-gesamtausgabe.de/modules/norm" at "norm.xqm";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util" at "wega-util.xqm";
import module namespace bibl="http://xquery.weber-gesamtausgabe.de/modules/bibl" at "bibl.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/str.xqm";
import module namespace date="http://xquery.weber-gesamtausgabe.de/modules/date" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/date.xqm";

declare function wdt:orgs($item as item()*) as map(*) {
    map {
        'name' := 'orgs',
        'prefix' := 'A08',
        'check' := function() as xs:boolean {
            if($item castable as xs:string) then matches($item, '^A08\d{4}$')
            else false()
        },
        'filter' := function() as document-node()* {
            $item[descendant-or-self::tei:org][descendant-or-self::tei:orgName]/root() | $item[ancestor-or-self::tei:org]/root()
        },
        'filter-by-person' := function($personID as xs:string) as document-node()* {
            ()
        },
        'filter-by-date' := function($dateFrom as xs:date?, $dateTo as xs:date?) as document-node()* {
            $wdt:filter-by-date($item, $dateFrom, $dateTo)[ancestor-or-self::tei:org]/root()
        },
        'sort' := function($params as map(*)?) as document-node()* {
            if(sort:has-index('orgs')) then ()
            else (wdt:orgs(())('init-sortIndex')()),
            for $i in wdt:orgs($item)('filter')() order by sort:index('orgs', $i) ascending return $i
            
        },
        'init-collection' := function() as document-node()* {
            core:data-collection('orgs')[descendant::tei:org][descendant-or-self::tei:orgName]
        },
        'init-sortIndex' := function() as item()* {
            wdt:create-index-callback('orgs', wdt:orgs(())('init-collection')(), function($node) { wdt:orgs($node)('title')('txt') }, ())
        },
        'title' := function($serialization as xs:string) as item()? {
            let $org := 
                typeswitch($item)
                case xs:string return core:doc($item)/tei:org
                case xdt:untypedAtomic return core:doc($item)/tei:org
                case document-node() return $item/tei:org
                default return $item/root()/tei:org
            return
                switch($serialization)
                case 'txt' return str:normalize-space($org/tei:orgName[@type = 'reg'])
                case 'html' return <span>{str:normalize-space($org/tei:orgName[@type = 'reg'])}</span> 
                default return core:logToFile('error', 'wdt:orgs()("title"): unsupported serialization "' || $serialization || '"')
        },
        'label-facets' := function() as xs:string {
            let $doc := 
                typeswitch($item)
                case xs:string return core:doc($item)
                case xdt:untypedAtomic return core:doc($item)
                case document-node() return $item
                default return $item/root()
            return
                wdt:orgs($doc)('title')('txt') || ' (' || string-join($doc//tei:state[tei:label='Art der Institution']/tei:desc, ', ') || ')'
        },
        'undated' := (),
        'date' := (),
        'memberOf' := ('sitemap', 'unary-docTypes'), (: index, search :)
        'search' := ()
    }
};

declare function wdt:persons($item as item()*) as map(*) {
    map {
        'name' := 'persons',
        'prefix' := 'A00',
        'check' := function() as xs:boolean {
            if($item castable as xs:string) then matches($item, '^A00[0-9A-F]{4}$')
            else false()
        },
        'filter' := function() as document-node()* {
            $item[descendant-or-self::tei:person][descendant-or-self::tei:persName]/root() | $item[ancestor-or-self::tei:person]/root()
        },
        'filter-by-person' := function($personID as xs:string) as document-node()* {
            (:distinct-values((norm:get-norm-doc('letters')//@addresseeID[contains(., $personID)]/parent::norm:entry | norm:get-norm-doc('letters')//@authorID[contains(., $personID)]/parent::norm:entry)/(@authorID, @addresseeID)/tokenize(., '\s+'))[. != $personID] ! core:doc(.):)
            ()
        },
        'filter-by-date' := function($dateFrom as xs:date?, $dateTo as xs:date?) as document-node()* {
            $wdt:filter-by-date($item, $dateFrom, $dateTo)[ancestor-or-self::tei:person]/root()
        },
        'sort' := function($params as map(*)?) as document-node()* {
            if(sort:has-index('persons')) then ()
            else (wdt:persons(())('init-sortIndex')()),
            for $i in wdt:persons($item)('filter')() order by sort:index('persons', $i) ascending return $i
        },
        'init-collection' := function() as document-node()* {
            core:data-collection('persons')[descendant::tei:person][descendant-or-self::tei:persName]
        },
        'init-sortIndex' := function() as item()* {
            wdt:create-index-callback('persons', wdt:persons(())('init-collection')(), wdt:sort-key-person#1, ())
        },
        'title' := function($serialization as xs:string) as item()? {
            let $person := 
                typeswitch($item)
                case xs:string return core:doc($item)/tei:person
                case xdt:untypedAtomic return core:doc($item)/tei:person
                case document-node() return $item/tei:person
                default return $item/root()/tei:person
            return
                switch($serialization)
                case 'txt' return str:normalize-space(string-join(str:txtFromTEI($person/tei:persName[@type = 'reg'], config:guess-language(())), ''))
                case 'html' return <span>{str:normalize-space(string-join(str:txtFromTEI($person/tei:persName[@type = 'reg'], config:guess-language(())), ''))}</span> 
                default return core:logToFile('error', 'wdt:persons()("title"): unsupported serialization "' || $serialization || '"')
        },
        'label-facets' := function() as xs:string? {
            typeswitch($item)
                case xs:string return norm:get-norm-doc('persons')//norm:entry[@docID=$item]/str:normalize-space(.)
                case xdt:untypedAtomic return norm:get-norm-doc('persons')//norm:entry[@docID=$item]/str:normalize-space(.)
                case document-node() return str:normalize-space(($item//tei:persName[@type = 'reg']))
                case element() return str:normalize-space(($item/root()//tei:persName[@type = 'reg']))
                default return core:logToFile('error', 'wdt:persons()("label-facests"): failed to get string')
        },
        'memberOf' := ('sitemap', 'unary-docTypes'),
        'search' := ()
    }
};

declare function wdt:letters($item as item()*) as map(*) {
    let $constructLetterHead := function($TEI as element(tei:TEI)) as element(tei:title) {
        (: Support for Albumblätter?!? :)
        let $id := $TEI/data(@xml:id)
        let $lang := config:guess-language(())
        let $dateFormat := 
            if ($lang = 'de') then '[FNn], [D]. [MNn] [Y]'
            else '[FNn], [MNn] [D], [Y]'
        let $dateSender := date:printDate(($TEI//tei:correspAction[@type='sent']/tei:date)[1], $lang, lang:get-language-string(?,?,$lang), function() { $dateFormat })
        let $dateAddressee := date:printDate(($TEI//tei:correspAction[@type='received']/tei:date)[1], $lang, lang:get-language-string(?,?,$lang), function() { $dateFormat })
        let $date := 
            if($dateSender) then $dateSender
            else if($dateAddressee) then (lang:get-language-string('received', $lang) || ' ' || $dateAddressee)
            else ()
        let $senderElem := ($TEI//tei:correspAction[@type='sent']/tei:*[self::tei:persName or self::tei:orgName or self::tei:name])[1]
        let $sender := 
            if($senderElem[@key]) then str:printFornameSurname(query:title($senderElem/@key)) 
            else if(functx:all-whitespace($senderElem)) then 'unbekannt' 
            else str:printFornameSurname(str:normalize-space($senderElem)) 
        let $addresseeElem := ($TEI//tei:correspAction[@type='received']/tei:*[self::tei:persName or self::tei:orgName or self::tei:name])[1]
        let $addressee := 
            if($addresseeElem[@key]) then str:printFornameSurname(query:title($addresseeElem/@key)) 
            else if(functx:all-whitespace($addresseeElem)) then 'unbekannt' 
            else str:printFornameSurname(str:normalize-space($addresseeElem))
        let $placeSender := 
            if(query:placeName-elements($TEI//tei:correspAction[@type='sent'])/@key) then query:title((query:placeName-elements($TEI//tei:correspAction[@type='sent'])/@key)[1])
            else str:normalize-space(query:placeName-elements($TEI//tei:correspAction[@type='sent'])[1])
        let $placeAddressee := 
            if(query:placeName-elements($TEI//tei:correspAction[@type='received'])/@key) then query:title((query:placeName-elements($TEI//tei:correspAction[@type='received'])/@key)[1])
            else str:normalize-space(query:placeName-elements($TEI//tei:correspAction[@type='received'])[1])
        return (
            element tei:title {
                concat($sender, ' ', lower-case(lang:get-language-string('to',$lang)), ' ', $addressee),
                if($placeAddressee) then concat(' ', lower-case(lang:get-language-string('in',$lang)), ' ', $placeAddressee) else(),
                <tei:lb/>,
                if($placeSender) then string-join(($placeSender, $date), ', ')
                else $date
            }
        )
    }
    return 
    map {
        'name' := 'letters',
        'prefix' := 'A04',
        'check' := function() as xs:boolean {
            if($item castable as xs:string) then matches($item, '^A04\d{4}$')
            else false()
        },
        'filter' := function() as document-node()* {
            $item/root()/descendant::tei:text[@type = ('albumblatt', 'letter', 'guestbookEntry')]/root()
        },
        'filter-by-person' := function($personID as xs:string) as document-node()* {
            (:$item/root()//tei:persName[@key = $personID][ancestor::tei:correspAction][not(ancestor-or-self::tei:note)]/root() |
            $item/root()//tei:orgName[@key = $personID][ancestor::tei:correspAction][not(ancestor-or-self::tei:note)]/root() |
            $item/root()//tei:rs[ancestor::tei:correspAction][contains(@key, $personID)][not(ancestor-or-self::tei:note)]/root():)
            $item/root()//tei:*[contains(@key, $personID)][ancestor::tei:correspAction][not(ancestor-or-self::tei:note)]/root()
        },
        'filter-by-date' := function($dateFrom as xs:date?, $dateTo as xs:date?) as document-node()* {
            $wdt:filter-by-date($item, $dateFrom, $dateTo)[parent::tei:correspAction]/root()
        },
        'sort' := function($params as map(*)?) as document-node()* {
            if(sort:has-index('letters')) then ()
            else (wdt:letters(())('init-sortIndex')()),
            for $i in wdt:letters($item)('filter')() order by sort:index('letters', $i) ascending return $i
        },
        'init-collection' := function() as document-node()* {
            core:data-collection('letters')/descendant::tei:text[@type = ('albumblatt', 'letter', 'guestbookEntry')]/root()
        },
        'init-sortIndex' := function() as item()* {
            wdt:create-index-callback('letters', wdt:letters(())('init-collection')(), function($node) {
                let $normDate := query:get-normalized-date($node)
                let $n :=  functx:pad-integer-to-length($node//tei:correspAction[@type='sent']/tei:date/data(@n), 4)
                return
                    (if(exists($normDate)) then $normDate else 'xxxx-xx-xx') || $n
            }, ())
        },
        'title' := function($serialization as xs:string) as item()? {
            let $TEI := 
                typeswitch($item)
                case xs:string return core:doc($item)/tei:TEI
                case xdt:untypedAtomic return core:doc($item)/tei:TEI
                case document-node() return $item/tei:TEI
                default return $item/root()/tei:TEI
            let $title-element := 
                if(functx:all-whitespace(($TEI//tei:fileDesc/tei:titleStmt/tei:title[@level = 'a'])[1])) then $constructLetterHead($TEI)
                else ($TEI//tei:fileDesc/tei:titleStmt/tei:title[@level = 'a'])[1]
            return
                switch($serialization)
                case 'txt' return str:normalize-space(replace(string-join(str:txtFromTEI($title-element, config:guess-language(())), ''), '\s*\n+\s*(\S+)', '. $1'))
                case 'html' return wega-util:transform($title-element, doc(concat($config:xsl-collection-path, '/common_main.xsl')), config:get-xsl-params(())) 
                default return core:logToFile('error', 'wdt:letters()("title"): unsupported serialization "' || $serialization || '"')
        },
        'memberOf' := ('search', 'indices', 'sitemap', 'unary-docTypes'),
        'search' := function($query as element(query)) {
            $item[tei:TEI]//tei:body[ft:query(., $query)] | 
            $item[tei:TEI]//tei:correspDesc[ft:query(., $query)] | 
            $item[tei:TEI]//tei:title[ft:query(., $query)] |
            $item[tei:TEI]//tei:note[ft:query(., $query)][@type = ('summary', 'editorial', 'incipit')] |
            $item[tei:TEI]/tei:TEI[ft:query(., $query)]
        }
    }
};

declare function wdt:personsPlus($item as item()*) as map(*) {
    let $filter := function($docs as document-node()*) as document-node()* {
        wdt:orgs($docs)('filter')() | wdt:persons($docs)('filter')()
    }
    return
    map {
        'name' := 'personsPlus',
        'prefix' := (),
        'check' := function() as xs:boolean {
            if($item castable as xs:string) then (wdt:orgs($item)('check')() or wdt:persons($item)('check')())
            else false()
        },
        'filter' := function() as document-node()* {
            $filter($item)
        },
        'filter-by-person' := function($personID as xs:string) as document-node()* {
            () 
        },
        'filter-by-date' := function($dateFrom as xs:date?, $dateTo as xs:date?) as document-node()* {
            $wdt:filter-by-date($item, $dateFrom, $dateTo)/root() => $filter()
        },
        'sort' := function($params as map(*)?) as document-node()* {
            if(sort:has-index('personsPlus')) then ()
            else (wdt:personsPlus(())('init-sortIndex')()),
            for $i in $filter($item) order by sort:index('personsPlus', $i) ascending return $i
        },
        'init-collection' := function() as document-node()* {
            wdt:orgs($item)('init-collection')() | wdt:persons($item)('init-collection')()
        },
        'init-sortIndex' := function() as item()* {
            wdt:create-index-callback('personsPlus', wdt:personsPlus(())('init-collection')(), function($node) {
                if($node/tei:org) then lower-case(str:normalize-space($node//tei:orgName[@type = 'reg']))
                else wdt:sort-key-person($node)
            }, ())
        },
        'memberOf' := ('search', 'indices'),
        'search' := function($query as element(query)) {
            $item[tei:org]/tei:org[ft:query(., $query)] | 
            $item[tei:org]//tei:orgName[ft:query(., $query)][@type] |
            $item[tei:person]/tei:person[ft:query(., $query)] | 
            $item[tei:person]//tei:persName[ft:query(., $query)][@type]
        }
    }
};

declare function wdt:writings($item as item()*) as map(*) {
    let $filter := function($docs as document-node()*) as document-node()* {
        $docs/root()/descendant::tei:text[@type=('performance-review', 'historic-news', 'concert_announcements')]/root() 
    }
    return
    map {
        'name' := 'writings',
        'prefix' := 'A03',
        'check' := function() as xs:boolean {
            if($item castable as xs:string) then matches($item, '^A03\d{4}$')
            else false()
        },
        'filter' := function() as document-node()* {
            $filter($item) 
        },
        'filter-by-person' := function($personID as xs:string) as document-node()* {
            $item/root()//tei:author[@key = $personID][ancestor::tei:fileDesc]/root() => $filter()
        },
        'filter-by-date' := function($dateFrom as xs:date?, $dateTo as xs:date?) as document-node()* {
            $wdt:filter-by-date($item, $dateFrom, $dateTo)[parent::tei:imprint]/root() => $filter()
        },
        'sort' := function($params as map(*)?) as document-node()* {
            if(sort:has-index('writings')) then ()
            else (wdt:writings(())('init-sortIndex')()),
            for $i in $filter($item) order by sort:index('writings', $i) ascending return $i
        },
        'init-collection' := function() as document-node()* {
            core:data-collection('writings')/descendant::tei:text[@type=('performance-review', 'historic-news', 'concert_announcements')]/root() 
        },
        'init-sortIndex' := function() as item()* {
            wdt:create-index-callback('writings', wdt:writings(())('init-collection')(), function($node) {
                let $normDate := query:get-normalized-date($node)
                let $source := query:get-main-source($node)
                let $journal := string-join($source/tei:monogr/tei:title[@level = 'j']/str:normalize-space(.), '. ')
                let $jg := functx:pad-integer-to-length(number($source//tei:biblScope[@unit='jg'][1]), 6)
                let $nr := functx:pad-integer-to-length(number($source//tei:biblScope[@unit='nr'][1]), 6)
                let $pp := functx:pad-integer-to-length(number(functx:substring-before-if-contains($source//tei:biblScope[@unit='pp'][1], '-')), 6)
                return
                    (if(exists($normDate)) then $normDate else 'xxxx-xx-xx') || $journal || $jg || $nr || $pp 
            }, ())
        },
        'title' := function($serialization as xs:string) as item()? {
            let $TEI := 
                typeswitch($item)
                case xs:string return core:doc($item)/tei:TEI
                case xdt:untypedAtomic return core:doc($item)/tei:TEI
                case document-node() return $item/tei:TEI
                default return $item/root()/tei:TEI
            let $title-element := ($TEI//tei:fileDesc/tei:titleStmt/tei:title[@level = 'a'])[1]
            return
                switch($serialization)
                case 'txt' return str:normalize-space(replace(string-join(str:txtFromTEI($title-element, config:guess-language(())), ''), '\s*\n+\s*(\S+)', '. $1'))
                case 'html' return wega-util:transform($title-element, doc(concat($config:xsl-collection-path, '/common_main.xsl')), config:get-xsl-params(())) 
                default return core:logToFile('error', 'wdt:letters()("title"): unsupported serialization "' || $serialization || '"')
        },
        'memberOf' := ('search', 'indices', 'sitemap', 'unary-docTypes'),
        'search' := function($query as element(query)) {
            $item[tei:TEI]//tei:body[ft:query(., $query)] | 
            $item[tei:TEI]//tei:title[ft:query(., $query)] |
            $item[tei:TEI]//tei:note[ft:query(., $query)][@type = ('summary', 'editorial', 'incipit')] |
            $item[tei:TEI]/tei:TEI[ft:query(., $query)]
        }
    }
};

declare function wdt:works($item as item()*) as map(*) {
    map {
        'name' := 'works',
        'prefix' := 'A02',
        'check' := function() as xs:boolean {
            if($item castable as xs:string) then matches($item, '^A02\d{4}$')
            else false()
        },
        'filter' := function() as document-node()* {
            $item/root()[mei:mei][descendant::mei:meiHead]
        },
        'filter-by-person' := function($personID as xs:string) as document-node()* {
            $item/root()/descendant::mei:persName[@dbkey = $personID][@role=('cmp', 'lbt', 'lyr', 'aut', 'trl')][ancestor::mei:fileDesc]/root() 
        },
        'filter-by-date' := function($dateFrom as xs:date?, $dateTo as xs:date?) as document-node()* {
            if(empty(($dateFrom, $dateTo))) then $item/root() 
            (: das muss noch umgeschrieben werden!! :)
            else if(string($dateFrom) = string($dateTo)) then $item//mei:date[@isodate | @startdate | @enddate | @notbefore | @notafter = string($dateFrom)][ancestor::mei:history]/root()
            else if(empty($dateFrom)) then $item//mei:date[@isodate | @startdate | @enddate | @notbefore | @notafter <= string($dateTo)][ancestor::mei:history]/root()
            else if(empty($dateTo)) then $item//mei:date[@isodate | @startdate | @enddate | @notbefore | @notafter >= string($dateFrom)][ancestor::mei:history]/root()
            else ($item//mei:date[@isodate | @startdate | @enddate | @notbefore | @notafter >= string($dateFrom)][@isodate | @startdate | @enddate | @notbefore | @notafter <= string($dateTo)][ancestor::mei:history])/root()
        },
        'sort' := function($params as map(*)?) as document-node()* {
            if(sort:has-index('works')) then ()
            else (wdt:works(())('init-sortIndex')()),
            for $i in wdt:works($item)('filter')() order by sort:index('works', $i) return $i
        },
        'init-collection' := function() as document-node()* {
            core:data-collection('works')[mei:mei][descendant::mei:meiHead]
        },
        'init-sortIndex' := function() as item()* {
            wdt:create-index-callback('works', wdt:works(())('init-collection')(), function($node) { 
                functx:pad-integer-to-length(($node//mei:seriesStmt/mei:title[@level])[1]/xs:int(@n), 4) || 
                $node//mei:altId[@type = 'WeV']/string(@subtype) || 
                functx:pad-integer-to-length($node//mei:altId[@type = 'WeV']/xs:int(@n), 4) || 
                $node//mei:altId[@type = 'WeV']/string() || 
                ($node//mei:title)[1]
            }, ())
        },
        (: Sollte beim Titel noch der Komponist etc. angegeben werden? :)
        'title' := function($serialization as xs:string) as item()* {
            let $mei := 
                typeswitch($item)
                case xs:string return core:doc($item)/mei:mei
                case xdt:untypedAtomic return core:doc($item)/mei:mei
                case document-node() return $item/mei:mei
                default return $item/root()/mei:mei
            let $title-element := ($mei//mei:fileDesc/mei:titleStmt/mei:title[not(@type)])[1]
            return
                switch($serialization)
                case 'txt' return str:normalize-space(replace(string-join(str:txtFromTEI($title-element, config:guess-language(())), ''), '\s*\n+\s*(\S+)', '. $1'))
                case 'html' return <span>{wega-util:transform($title-element, doc(concat($config:xsl-collection-path, '/works.xsl')), config:get-xsl-params(()))}</span> 
                default return core:logToFile('error', 'wdt:works()("title"): unsupported serialization "' || $serialization || '"')
        },
        'label-facets' := function() as xs:string? {
            typeswitch($item)
            case xs:string return norm:get-norm-doc('works')//norm:entry[@docID=$item]/str:normalize-space(.)
            case xdt:untypedAtomic return norm:get-norm-doc('works')//norm:entry[@docID=$item]/str:normalize-space(.)
            case document-node() return str:normalize-space(($item//mei:fileDesc/mei:titleStmt/mei:title[not(@type)])[1])
            case element() return str:normalize-space(($item//mei:fileDesc/mei:titleStmt/mei:title[not(@type)])[1])
            default return core:logToFile('error', 'wdt:works()("label-facests"): failed to get string')
        },
        'memberOf' := ('search', 'indices', 'unary-docTypes'),
        'search' := function($query as element(query)) {
            $item[mei:mei]/mei:mei[ft:query(., $query)] | 
            $item[mei:mei]//mei:title[ft:query(., $query)]
        }
    }
};

declare function wdt:diaries($item as item()*) as map(*) {
    map {
        'name' := 'diaries',
        'prefix' := 'A06',
        'check' := function() as xs:boolean {
            if($item castable as xs:string) then matches($item, '^A06\d{4}$')
            else false()
        },
        'filter' := function() as document-node()* {
            $item/root()[tei:ab/@where]
        },
        'filter-by-person' := function($personID as xs:string) as document-node()* {
            if($personID eq 'A002068') then wdt:diaries(core:data-collection('diaries'))('sort')(map {})
            else ()
        },
        'filter-by-date' := function($dateFrom as xs:date?, $dateTo as xs:date?) as document-node()* {
            if(empty(($dateFrom, $dateTo))) then $item/root() 
            else if(string($dateFrom) = string($dateTo)) then $item/range:field-eq('ab-n', string($dateFrom))/root()
            else if(empty($dateFrom)) then $item/range:field-le('ab-n', string($dateFrom))/root()
            else if(empty($dateTo)) then $item/range:field-ge('ab-n', string($dateFrom))/root()
            else ($item/range:field-ge('ab-n', string($dateFrom)) intersect $item/range:field-le('ab-n', string($dateTo)))/root()
        },
        'sort' := function($params as map(*)?) as document-node()* {
            if(sort:has-index('diaries')) then () 
            else (wdt:diaries(())('init-sortIndex')()),
            for $i in wdt:diaries($item)('filter')() order by sort:index('diaries', $i) ascending return $i
        },
        'init-collection' := function() as document-node()* {
            core:data-collection('diaries')[tei:ab/@where]
        },
        'init-sortIndex' := function() as item()* {
            wdt:create-index-callback('diaries', wdt:diaries(())('init-collection')(), function($node) { query:get-normalized-date($node) }, ())
        },
        'title' := function($serialization as xs:string) as item()? {
            let $ab := 
                typeswitch($item)
                case xs:string return core:doc($item)/tei:ab
                case xdt:untypedAtomic return core:doc($item)/tei:ab
                case document-node() return $item/tei:ab
                default return ()
            let $lang := config:guess-language(())
            let $diaryPlaces as array(xs:string) := query:place-of-diary-day($ab/root())
            let $dateFormat := 
                if ($lang = 'de') then '[FNn], [D]. [MNn] [Y]'
                else '[FNn], [MNn] [D], [Y]'
            let $formattedDate := date:format-date(xs:date($ab/@n), $dateFormat, $lang)
            let $formattedPlaces := 
                switch(array:size($diaryPlaces))
                case 0 return ()
                case 1 return $diaryPlaces(1)
                case 2 return $diaryPlaces(1) || ', ' || $diaryPlaces(2)
                case 3 return $diaryPlaces(1) || ', ' || $diaryPlaces(2) || ', ' || $diaryPlaces(3)
                default return $diaryPlaces(1) || ', …, ' || $diaryPlaces(array:size($diaryPlaces))
            return 
                switch($serialization)
                    case 'txt' return concat($formattedDate, ' (', $formattedPlaces, ')')
                    case 'html' return <span>{$formattedDate}<br/>{$formattedPlaces}</span> 
                    default return core:logToFile('error', 'wdt:diaries()("title"): unsupported serialization "' || $serialization || '"')
        },
        'memberOf' := ('search', 'indices', 'sitemap', 'unary-docTypes'),
        'search' := function($query as element(query)) {
            $item[tei:ab]/tei:ab[ft:query(., $query)]
        }
    }
};

declare function wdt:news($item as item()*) as map(*) {
    let $filter := function($docs as document-node()*) as document-node()* {
        $docs/root()/descendant::tei:text[@type='news']/root()
    }
    return
    map {
        'name' := 'news',
        'prefix' := 'A05',
        'check' := function() as xs:boolean {
            if($item castable as xs:string) then matches($item, '^A05\d{4}$')
            else false()
        },
        'filter' := function() as document-node()* {
            $filter($item)
        },
        'filter-by-person' := function($personID as xs:string) as document-node()* {
            $item/root()/descendant::tei:author[@key = $personID][ancestor::tei:fileDesc]/root() => $filter()
        },
        'filter-by-date' := function($dateFrom as xs:date?, $dateTo as xs:date?) as document-node()* {
            $wdt:filter-by-date($item, $dateFrom, $dateTo)[parent::tei:publicationStmt]/root() => $filter()
        },
        'sort' := function($params as map(*)?) as document-node()* {
            if(sort:has-index('news')) then ()
            else (wdt:news(())('init-sortIndex')()),
            for $i in $filter($item) order by sort:index('news', $i) descending return $i
        },
        'init-collection' := function() as document-node()* {
            core:data-collection('news')[descendant::tei:text]
        },
        'init-sortIndex' := function() as item()* {
            wdt:create-index-callback('news', wdt:news(())('init-collection')(), function($node) { $node//tei:date[parent::tei:publicationStmt]/xs:dateTime(@when) }, ())
        },
        'title' := function($serialization as xs:string) as item()? {
            let $TEI := 
                typeswitch($item)
                case xs:string return core:doc($item)/tei:TEI
                case xdt:untypedAtomic return core:doc($item)/tei:TEI
                case document-node() return $item/tei:TEI
                default return $item/root()/tei:TEI
            let $title-element := ($TEI//tei:fileDesc/tei:titleStmt/tei:title[@level = 'a'])[1]
            return
                switch($serialization)
                case 'txt' return str:normalize-space(replace(string-join(str:txtFromTEI($title-element, config:guess-language(())), ''), '\s*\n+\s*(\S+)', '. $1'))
                case 'html' return wega-util:transform($title-element, doc(concat($config:xsl-collection-path, '/common_main.xsl')), config:get-xsl-params(())) 
                default return core:logToFile('error', 'wdt:letters()("title"): unsupported serialization "' || $serialization || '"')
        },
        'memberOf' := ('search', 'sitemap', 'indices', 'unary-docTypes'),
        'search' := function($query as element(query)) {
            $item[tei:TEI]//tei:body[ft:query(., $query)] | 
            $item[tei:TEI]//tei:title[ft:query(., $query)]
        }
    }
};

declare function wdt:iconography($item as item()*) as map(*) {
    map {
        'name' := 'iconography',
        'prefix' := 'A01',
        'check' := function() as xs:boolean {
            if($item castable as xs:string) then matches($item, '^A01\d{4}$')
            else false()
        },
        'filter' := function() as document-node()* {
            $item/root()[descendant::tei:person/@corresp]
        },
        'filter-by-person' := function($personID as xs:string) as document-node()* {
            $item/root()/descendant::tei:person[@corresp = $personID]/root()
        },
        'filter-by-date' := function($dateFrom as xs:date?, $dateTo as xs:date?) as document-node()* {
            ()
        },
        'sort' := function($params as map(*)?) as document-node()* {
            if(sort:has-index('iconography')) then ()
            else (wdt:iconography(())('init-sortIndex')()),
            for $i in wdt:iconography($item)('filter')() order by sort:index('iconography', $i) descending return $i
        },
        'init-collection' := function() as document-node()* {
            core:data-collection('iconography')[descendant::tei:person/@corresp]
        },
        'init-sortIndex' := function() as item()* {
            wdt:create-index-callback('iconography', wdt:iconography(())('init-collection')(), function($node) { $node//tei:person/data(@corresp) }, ())
        },
        'memberOf' := ('unary-docTypes'),
        'search' := ()
    }
};

declare function wdt:var($item as item()*) as map(*) {
    let $filter := function($docs as document-node()*) as document-node()* {
        $docs/root()/tei:TEI[starts-with(@xml:id, 'A07')]/root()
    }
    return
    map {
        'name' := 'var',
        'prefix' := 'A07',
        'check' := function() as xs:boolean {
            if($item castable as xs:string) then matches($item, '^A07\d{4}$')
            else false()
        },
        'filter' := function() as document-node()* {
            $filter($item)
        },
        'filter-by-person' := function($personID as xs:string) as document-node()* {
            ()
        },
        'filter-by-date' := function($dateFrom as xs:date?, $dateTo as xs:date?) as document-node()* {
            ()
        },
        'sort' := function($params as map(*)?) as document-node()* {
            $filter($item)
        },
        'init-collection' := function() as document-node()* {
            core:data-collection('var')
        },
        'init-sortIndex' := function() as item()* {
            ()
        },
        'title' := function($serialization as xs:string) as item()? {
            let $TEI := 
                typeswitch($item)
                case xs:string return core:doc($item)/tei:TEI
                case xdt:untypedAtomic return core:doc($item)/tei:TEI
                case document-node() return $item/tei:TEI
                default return $item/root()/tei:TEI
            let $lang := config:guess-language(())
            let $title-element := ($TEI//tei:fileDesc/tei:titleStmt/tei:title[@xml:lang=$lang][@level = 'a'], $TEI//tei:fileDesc/tei:titleStmt/tei:title[@level = 'a'])[1]
            return
                switch($serialization)
                case 'txt' return str:normalize-space(replace(string-join(str:txtFromTEI($title-element, config:guess-language(())), ''), '\s*\n+\s*(\S+)', '. $1'))
                case 'html' return wega-util:transform($title-element, doc(concat($config:xsl-collection-path, '/common_main.xsl')), config:get-xsl-params(())) 
                default return core:logToFile('error', 'wdt:letters()("title"): unsupported serialization "' || $serialization || '"')
        },
        'memberOf' := ('unary-docTypes'),
        'search' := function($query as element(query)) {
            $item[tei:TEI]//tei:body[ft:query(., $query)] | 
            $item[tei:TEI]//tei:title[ft:query(., $query)]
        }
    }
};

declare function wdt:biblio($item as item()*) as map(*) {
    let $filter := function($docs as document-node()*) as document-node()* {
        $docs[descendant-or-self::tei:biblStruct][not(ancestor-or-self::tei:TEI)][not(descendant::tei:TEI)]/root() | $docs[ancestor-or-self::tei:biblStruct][not(ancestor::tei:TEI)]/root()
    }
    return
    map {
        'name' := 'biblio',
        'prefix' := 'A11',
        'check' := function() as xs:boolean {
            if($item castable as xs:string) then matches($item, '^A11\d{4}$')
            else false()
        },
        'filter' := function() as document-node()* {
            $filter($item)
        },
        'filter-by-person' := function($personID as xs:string) as document-node()* {
            ($item/root()//tei:author[@key = $personID]/root() | $item/root()//tei:editor[@key = $personID]/root()) => $filter()
        },
        'filter-by-date' := function($dateFrom as xs:date?, $dateTo as xs:date?) as document-node()* {
            $wdt:filter-by-date($item, $dateFrom, $dateTo)[parent::tei:imprint]/root() => $filter()
        },
        'sort' := function($params as map(*)?) as document-node()* {
            if(sort:has-index('biblio')) then ()
            else (wdt:biblio(())('init-sortIndex')()),
            for $i in $filter($item) order by sort:index('biblio', $i) descending return $i
        },
        'init-collection' := function() as document-node()* {
            core:data-collection('biblio')[descendant::tei:monogr]
        },
        'init-sortIndex' := function() as item()* {
            wdt:create-index-callback('biblio', wdt:biblio(())('init-collection')(), function($node) { 
                let $date := query:get-normalized-date($node)
                return
                    (if(exists($date)) then $date else '0000') ||
                    tokenize($node//tei:author, '\s+')[last()]
                }, ())
        },
        'title' := function($serialization as xs:string) as item()? {
            let $biblStruct := 
                typeswitch($item)
                case xs:string return core:doc($item)/tei:biblStruct
                case xdt:untypedAtomic return core:doc($item)/tei:biblStruct
                case document-node() return $item/tei:biblStruct
                default return $item/root()/tei:biblStruct
            let $html-title := bibl:printCitation($biblStruct, <xhtml:p/>, 'de')
            return
                switch($serialization)
                case 'txt' return str:normalize-space($html-title)
                case 'html' return $html-title 
                default return core:logToFile('error', 'wdt:biblio()("title"): unsupported serialization "' || $serialization || '"')
        },
        'memberOf' := ('search', 'indices', 'unary-docTypes'),
        'search' := function($query as element(query)) {
            $item[tei:biblStruct]//tei:biblStruct[ft:query(., $query)] | 
            $item[tei:biblStruct]//tei:title[ft:query(., $query)] | 
            $item[tei:biblStruct]//tei:author[ft:query(., $query)] | 
            $item[tei:biblStruct]//tei:editor[ft:query(., $query)]
        }
    }
};

declare function wdt:places($item as item()*) as map(*) {
    map {
        'name' := 'places',
        'prefix' := 'A13',
        'check' := function() as xs:boolean {
            if($item castable as xs:string) then matches($item, '^A13\d{4}$')
            else false()
        },
        'filter' := function() as document-node()* {
            $item/root()[tei:place][descendant::tei:placeName]
        },
        'filter-by-person' := function($personID as xs:string) as document-node()* {
            $item
        },
        'filter-by-date' := function($dateFrom as xs:date?, $dateTo as xs:date?) as document-node()* {
            ()
        },
        'sort' := function($params as map(*)?) as document-node()* {
            if(sort:has-index('places')) then ()
            else (wdt:places(())('init-sortIndex')()),
            for $i in wdt:places($item)('filter')() order by sort:index('places', $i)  ascending return $i
        },
        'init-collection' := function() as document-node()* {
            core:data-collection('places')[descendant::tei:placeName]
        },
        'init-sortIndex' := function() as item()* {
            wdt:create-index-callback('places', wdt:places(())('init-collection')(), function($node) { str:normalize-space($node//tei:placeName[@type='reg']) }, ())
        },
        'title' := function($serialization as xs:string) as item()? {
            let $place := 
                typeswitch($item)
                case xs:string return core:doc($item)/tei:place
                case xdt:untypedAtomic return core:doc($item)/tei:place
                case document-node() return $item/tei:place
                default return $item/root()/tei:place
            return
                switch($serialization)
                case 'txt' return str:normalize-space($place/tei:placeName[@type = 'reg'])
                case 'html' return <span>{str:normalize-space($place/tei:placeName[@type = 'reg'])}</span> 
                default return core:logToFile('error', 'wdt:places()("title"): unsupported serialization "' || $serialization || '"')
        },
        'memberOf' := ('unary-docTypes', 'search', 'indices'),
        'search' := function($query as element(query)) {
            $item[tei:place]//tei:placeName[ft:query(., $query)] | 
            $item[tei:place]/tei:place[ft:query(., $query)] 
        }
    }
};

declare function wdt:sources($item as item()*) as map(*) {
    map {
        'name' := 'sources',
        'prefix' := 'A22',
        'check' := function() as xs:boolean {
            if($item castable as xs:string) then matches($item, '^A22\d{4}$')
            else false()
        },
        'filter' := function() as document-node()* {
            $item/root()[mei:source][descendant::mei:titleStmt][not(descendant::mei:annot[@type='no-ordinary-record'])]
        },
        'filter-by-person' := function($personID as xs:string) as document-node()* {
            if(config:is-person($personID) or config:is-org($personID)) then $item/root()/descendant::mei:persName[@dbkey = $personID][@role=('cmp', 'lbt', 'lyr', 'aut', 'trl')][ancestor::mei:titleStmt]/root()
            else if(config:is-work($personID)) then $item/root()/descendant::mei:identifier[.=$personID][@type = 'WeGA']/root()
            else ()
        },
        'filter-by-date' := function($dateFrom as xs:date?, $dateTo as xs:date?) as document-node()* {
            () 
        },
        'sort' := function($params as map(*)?) as document-node()* {
            $item
        },
        'init-collection' := function() as document-node()* {
            core:data-collection('sources')[descendant::mei:titleStmt][not(descendant::mei:annot[@type='no-ordinary-record'])]
        },
        'init-sortIndex' := function() as item()* {
            ()
        },
        'title' := function($serialization as xs:string) as item()? {
            let $source := 
                typeswitch($item)
                case xs:string return core:doc($item)/mei:source
                case xdt:untypedAtomic return core:doc($item)/mei:source
                case document-node() return $item/mei:source
                default return $item/root()/mei:source
            let $title-element := ($source/mei:titleStmt/mei:title[not(@type)])[1]
            return
                switch($serialization)
                case 'txt' return str:normalize-space(replace(string-join(str:txtFromTEI($title-element, config:guess-language(())), ''), '\s*\n+\s*(\S+)', '. $1'))
                case 'html' return wega-util:transform($title-element, doc(concat($config:xsl-collection-path, '/common_main.xsl')), config:get-xsl-params(())) 
                default return core:logToFile('error', 'wdt:works()("title"): unsupported serialization "' || $serialization || '"')
        },
        'memberOf' := ('unary-docTypes'),
        'search' := ()
    }
};

declare function wdt:thematicCommentaries($item as item()*) as map(*) {
    map {
        'name' := 'thematicCommentaries',
        'prefix' := 'A09',
        'check' := function() as xs:boolean {
            if($item castable as xs:string) then matches($item, '^A09\d{4}$')
            else false()
        },
        'filter' := function() as document-node()* {
            $item/root()/descendant::tei:text[@type = 'thematicCom']/root()
        },
        'filter-by-person' := function($personID as xs:string) as document-node()* {
            $item/root()//tei:author[@key = $personID][ancestor::tei:fileDesc]/root()
        },
        'filter-by-date' := function($dateFrom as xs:date?, $dateTo as xs:date?) as document-node()* {
            () 
        },
        'sort' := function($params as map(*)?) as document-node()* {
            if(sort:has-index('thematicCommentaries')) then ()
            else (wdt:thematicCommentaries(())('init-sortIndex')()),
            for $i in wdt:thematicCommentaries($item)('filter')() order by sort:index('thematicCommentaries', $i)  ascending return $i
        },
        'init-collection' := function() as document-node()* {
            core:data-collection('thematicCommentaries')/descendant::tei:text[@type='thematicCom']/root()
        },
        'init-sortIndex' := function() as item()* {
            wdt:create-index-callback('thematicCommentaries', wdt:thematicCommentaries(())('init-collection')(), function($node) { replace(str:normalize-space(($node//tei:fileDesc/tei:titleStmt/tei:title[@level = 'a'])[1] ), '^(Der|Die|Das|Eine?)\s', '') }, ())
        },
        'title' := function($serialization as xs:string) as item()? {
            let $TEI := 
                typeswitch($item)
                case xs:string return core:doc($item)/tei:TEI
                case xdt:untypedAtomic return core:doc($item)/tei:TEI
                case document-node() return $item/tei:TEI
                default return $item/root()/tei:TEI
            let $title-element := ($TEI//tei:fileDesc/tei:titleStmt/tei:title[@level = 'a'])[1]
            return
                switch($serialization)
                case 'txt' return str:normalize-space(replace(string-join(str:txtFromTEI($title-element, config:guess-language(())), ''), '\s*\n+\s*(\S+)', '. $1'))
                case 'html' return wega-util:transform($title-element, doc(concat($config:xsl-collection-path, '/common_main.xsl')), config:get-xsl-params(())) 
                default return core:logToFile('error', 'wdt:thematicCommentaries()("title"): unsupported serialization "' || $serialization || '"')
        },
        'memberOf' := ('search', 'indices', 'sitemap', 'unary-docTypes'),
        'search' := function($query as element(query)) {
            $item[tei:TEI]//tei:body[ft:query(., $query)] | 
            $item[tei:TEI]//tei:title[ft:query(., $query)] |
            $item[tei:TEI]/tei:TEI[ft:query(., $query)]
        }
    }
};

declare function wdt:documents($item as item()*) as map(*) {
    let $filter := function($docs as document-node()*) as document-node()* {
        $docs/root()/descendant::tei:text[@type = ('work-related_document', 'personal_document', 'financial_document', 'varia_document', 'notification_document', 'konzertzettel_document')]/root()
    }
    return
    map {
        'name' := 'documents',
        'prefix' := 'A10',
        'check' := function() as xs:boolean {
            if($item castable as xs:string) then matches($item, '^A10\d{4}$')
            else false()
        },
        'filter' := function() as document-node()* {
            $filter($item)
        },
        'filter-by-person' := function($personID as xs:string) as document-node()* {
            $item/root()//tei:author[@key = $personID][ancestor::tei:fileDesc]/root() => $filter()
        },
        'filter-by-date' := function($dateFrom as xs:date?, $dateTo as xs:date?) as document-node()* {
            $wdt:filter-by-date($item, $dateFrom, $dateTo)[parent::tei:creation]/root() => $filter()
        },
        'sort' := function($params as map(*)?) as document-node()* {
            if(sort:has-index('documents')) then ()
            else (wdt:documents(())('init-sortIndex')()),
            for $i in $filter($item) order by sort:index('documents', $i)  ascending return $i
        },
        'init-collection' := function() as document-node()* {
            core:data-collection('documents')/descendant::tei:text[@type=('work-related_document', 'personal_document', 'financial_document', 'varia_document', 'notification_document', 'konzertzettel_document')]/root()
        },
        'init-sortIndex' := function() as item()* {
            wdt:create-index-callback('documents', wdt:documents(())('init-collection')(), function($node) {
                let $normDate := query:get-normalized-date($node)
                let $title := replace(str:normalize-space(($node//tei:fileDesc/tei:titleStmt/tei:title[@level = 'a'])[1] ), '^(Der|Die|Das|Eine?)\s', '')
                return 
                    (if(exists($normDate)) then $normDate else 'xxxx-xx-xx') || $title
            }, ())
        },
        'title' := function($serialization as xs:string) as item()? {
            let $TEI := 
                typeswitch($item)
                case xs:string return core:doc($item)/tei:TEI
                case xdt:untypedAtomic return core:doc($item)/tei:TEI
                case document-node() return $item/tei:TEI
                default return $item/root()/tei:TEI
            let $title-element := ($TEI//tei:fileDesc/tei:titleStmt/tei:title[@level = 'a'])[1]
            return
                switch($serialization)
                case 'txt' return str:normalize-space(replace(string-join(str:txtFromTEI($title-element, config:guess-language(())), ''), '\s*\n+\s*(\S+)', '. $1'))
                case 'html' return wega-util:transform($title-element, doc(concat($config:xsl-collection-path, '/common_main.xsl')), config:get-xsl-params(())) 
                default return core:logToFile('error', 'wdt:documents()("title"): unsupported serialization "' || $serialization || '"')
        },
        'memberOf' := ('search', 'indices', 'sitemap', 'unary-docTypes'),
        'search' := function($query as element(query)) {
            $item[tei:TEI]//tei:body[ft:query(., $query)] | 
            $item[tei:TEI]//tei:title[ft:query(., $query)] |
            $item[tei:TEI]//tei:note[ft:query(., $query)][@type = ('summary', 'editorial', 'incipit')] |
            $item[tei:TEI]/tei:TEI[ft:query(., $query)]
        }
    }
};

declare function wdt:contacts($item as item()*) as map(*) {
    map {
        'name' := 'contacts',
        'prefix' := (),
        'check' := function() as xs:boolean {
            false()
        },
        'filter' := function() as document-node()* {
            ()
        },
        'filter-by-person' := function($personID as xs:string) as document-node()* {
            let $norm-doc := norm:get-norm-doc('letters')
            let $entries := 
                $norm-doc//norm:entry[contains(@addresseeID, $personID)] | 
                $norm-doc//norm:entry[contains(@authorID, $personID)]
            return 
                distinct-values($entries/(@authorID, @addresseeID)/tokenize(., '\s+'))[. != $personID] ! core:doc(.)
        },
        'filter-by-date' := function($dateFrom as xs:date?, $dateTo as xs:date?) as document-node()* {
            ()
        },
        'sort' := function($params as map(*)?) as document-node()* {
            let $correspondence-partners := query:correspondence-partners($params('personID'))
            return
                for $i in $item order by number($correspondence-partners($i/tei:*/data(@xml:id))) descending return $i
        },
        'init-collection' := function() as document-node()* {
            ()
        },
        'init-sortIndex' := function() as item()* {
            ()
        },
        'memberOf' := (),
        'search' := ()
    }
};

declare function wdt:backlinks($item as item()*) as map(*) {
    map {
        'name' := 'backlinks',
        'prefix' := (),
        'check' := function() as xs:boolean {
            false()
        },
        'filter' := function() as document-node()* {
            ()
        },
        'filter-by-person' := function($personID as xs:string) as document-node()* {
            let $docsAuthor := 
                (: currently, can't use core:getOrCreateColl() because of performance loss :)
                core:data-collection('letters')//tei:*[contains(@key, $personID)][ancestor::tei:correspAction][not(ancestor-or-self::tei:note)]/root() |
                core:data-collection('writings')//tei:author[@key = $personID][ancestor::tei:fileDesc]/root()  |
                core:data-collection('news')//tei:author[@key = $personID][ancestor::tei:fileDesc]/root()  |
                core:data-collection('thematicCommentaries')//tei:author[@key = $personID][ancestor::tei:fileDesc]/root()  |
                core:data-collection('documents')//tei:author[@key = $personID][ancestor::tei:fileDesc]/root() |
                core:data-collection('works')//mei:persName[@dbkey = $personID][@role=('cmp', 'lbt', 'lyr', 'aut', 'trl')][ancestor::mei:fileDesc]/root()
            let $docsMentioned := 
                core:data-collection('letters')//tei:*[contains(@key,$personID)][not(ancestor::tei:publicationStmt)]/root() | 
                core:data-collection('diaries')//tei:*[contains(@key,$personID)]/root() |
                core:data-collection('diaries')//tei:ab[contains(@where,$personID)]/root() |
                core:data-collection('writings')//tei:*[contains(@key,$personID)][not(ancestor::tei:publicationStmt)]/root() |
                core:data-collection('persons')//tei:*[contains(@key,$personID)]/root() |
                core:data-collection('news')//tei:*[contains(@key,$personID)][not(ancestor::tei:publicationStmt)]/root() |
                core:data-collection('orgs')//tei:*[contains(@key,$personID)][not(parent::tei:orgName/@type)]/root() |
                core:data-collection('biblio')//tei:term[.=$personID]/root() |
                core:data-collection('thematicCommentaries')//tei:*[contains(@key,$personID)][not(ancestor::tei:publicationStmt)]/root() |
                core:data-collection('documents')//tei:*[contains(@key,$personID)][not(ancestor::tei:publicationStmt)]/root() |
                core:data-collection('var')//tei:*[contains(@key,$personID)][not(ancestor::tei:publicationStmt)]/root() |
                core:data-collection('works')//mei:*[contains(@dbkey,$personID)]/root() |
                (: <ref target="wega:A002068"/> :)
                core:data-collection('letters')//tei:*[contains(@target, 'wega:' || $personID)]/root() |
                core:data-collection('diaries')//tei:*[contains(@target,'wega:' || $personID)]/root() |
                core:data-collection('writings')//tei:*[contains(@target,'wega:' || $personID)]/root() |
                core:data-collection('persons')//tei:*[contains(@target,'wega:' || $personID)]/root() |
                core:data-collection('news')//tei:*[contains(@target,'wega:' || $personID)]/root() |
                core:data-collection('orgs')//tei:*[contains(@target,'wega:' || $personID)]/root() |
                core:data-collection('biblio')//tei:*[contains(@target,'wega:' || $personID)]/root() |
                core:data-collection('thematicCommentaries')//tei:*[contains(@target,'wega:' || $personID)]/root() |
                core:data-collection('documents')//tei:*[contains(@target,'wega:' || $personID)]/root() |
                core:data-collection('var')//tei:*[contains(@target,'wega:' || $personID)]/root() 
            return
                $docsMentioned except $docsAuthor
        },
        'filter-by-date' := function($dateFrom as xs:date?, $dateTo as xs:date?) as document-node()* {
            ()
        },
        'sort' := function($params as map(*)?) as document-node()* {
            $item
        },
        'init-collection' := function() as document-node()* {
            ()
        },
        'init-sortIndex' := function() as item()* {
            ()
        },
        'memberOf' := (),
        'search' := ()
    }
};

declare function wdt:indices($item as item()*) as map(*) {
    map {
        'name' := 'indices',
        'prefix' := (),
        'check' := function() as xs:boolean {
            false()
        },
        'filter' := function() as document-node()* {
            $item()
        },
        'filter-by-person' := function($personID as xs:string) as document-node()* {
            ()
        },
        'filter-by-date' := function($dateFrom as xs:date?, $dateTo as xs:date?) as document-node()* {
            () 
        },
        'sort' := function($params as map(*)?) as document-node()* {
            $item
        },
        'init-collection' := function() as document-node()* {
            for $func in $wdt:functions
            return 
                if($func(())('memberOf') = 'indices') then $func(())('init-collection')()
                else ()
        },
        'init-sortIndex' := function() as item()* {
            for $func in $wdt:functions
            return 
                if($func(())('memberOf') = 'indices') then $func(())('init-sortIndex')()
                else ()
        },
        'memberOf' := (),
        'search' := ()
    }
};

(:~
 : Helper function to avoid trouble with type checks for parameter 2
~:)
declare %private function wdt:create-index-callback($id as xs:string, $item as item()*, $callback as function() as xs:string?, $options as element()?) as item()* {
(:  Probably try to cache the dateTime of index creation?!  :)
    sort:create-index-callback($id, $item, $callback, $options)
};

(:~
 : Helper function for creating a sort key for persons
 : Called by wdt:persons and wdt:personsPlus
~:)
declare %private function wdt:sort-key-person($node as node()) as xs:string? {
    let $sortName :=
        if(functx:all-whitespace($node//tei:persName[@type='reg']/tei:surname[1])) then replace(str:normalize-space(functx:substring-before-match($node//tei:persName[@type='reg'], '\s?,')), '(v[oa][nm]( der)? )|(d[uea]( la)? )', '')
        else str:normalize-space($node//tei:persName[@type='reg']/tei:surname[1])
    let $name := str:normalize-space($node//tei:persName[@type='reg'])
    return 
        lower-case(replace(wega-util:strip-diacritics($sortName || $name), "'", ""))
};

(:~
 : Helper function for filtering a collection by date(s)
 : Called by almost every function of this module
 : This function returns a sequence of (tei or mei) date elements
 : NB: local filters need to be applied to reduce the result set for the respective docType
~:)
declare %private variable $wdt:filter-by-date := function($item, $dateFrom as xs:date?, $dateTo as xs:date?) as node()* {
    if(empty(($dateFrom, $dateTo))) then ()
    else if(string($dateFrom) = string($dateTo)) then ((
        $item/range:field-eq('date-when', string($dateFrom)) | 
        $item/range:field-eq('date-from', string($dateFrom)) | 
        $item/range:field-eq('date-to', string($dateFrom)) |
        $item/range:field-eq('date-notBefore', string($dateFrom)) |
        $item/range:field-eq('date-notAfter', string($dateFrom))
        ))
    else if(empty($dateFrom)) then ((
        $item/range:field-le('date-when', string($dateTo)) | 
        $item/range:field-le('date-from', string($dateTo)) | 
        $item/range:field-le('date-to', string($dateTo)) |
        $item/range:field-le('date-notBefore', string($dateTo)) |
        $item/range:field-le('date-notAfter', string($dateTo))
        ))
    else if(empty($dateTo)) then ((
        $item/range:field-ge('date-when', string($dateFrom)) | 
        $item/range:field-ge('date-from', string($dateFrom)) | 
        $item/range:field-ge('date-to', string($dateFrom)) |
        $item/range:field-ge('date-notBefore', string($dateFrom)) |
        $item/range:field-ge('date-notAfter', string($dateFrom))
        ))
    else ((
        $item/range:field-ge('date-when', string($dateFrom)) | 
        $item/range:field-ge('date-from', string($dateFrom)) | 
        $item/range:field-ge('date-to', string($dateFrom)) |
        $item/range:field-ge('date-notBefore', string($dateFrom)) |
        $item/range:field-ge('date-notAfter', string($dateFrom))
        ) intersect (
        $item/range:field-le('date-when', string($dateTo)) | 
        $item/range:field-le('date-from', string($dateTo)) | 
        $item/range:field-le('date-to', string($dateTo)) |
        $item/range:field-le('date-notBefore', string($dateTo)) |
        $item/range:field-le('date-notAfter', string($dateTo))
        ))
        (:  need to check that these dates are xs:date and not xs:gYear
            because otherwise a search for "from:1817-01-02" "to:1817-01-10"
            would return all <date when="1817"> as well
        :)
};

declare function wdt:members($memberOf as xs:string+) as item()* {
    for $func in $wdt:functions
    return
        if($func(())('memberOf') = $memberOf) then $func
        else ()
};

declare variable $wdt:functions := 
    for $func in inspect:module-functions()
    return 
        if(function-name($func) = (xs:QName('wdt:functions-available'), xs:QName('wdt:lookup'), xs:QName('wdt:members'), xs:QName('wdt:create-index-callback'), xs:QName('wdt:sort-key-person'))) then ()
        else $func
;

declare function wdt:lookup($name as xs:string, $item as item()*) as map(*) {
    try { function-lookup(xs:QName('wdt:' || $name), 1)($item) }
    catch * { core:logToFile('error', 'wdt:lookup(): failed to lookup function "' || $name || '"'  || ' &#10;' || string-join(($err:code, $err:description), ' &#10;')) }
};
