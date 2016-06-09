xquery version "3.1";

(:~
 : WeGA document types are defined here in an object oriented manner
 :)
module namespace wdt="http://xquery.weber-gesamtausgabe.de/modules/wdt";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

import module namespace functx="http://www.functx.com";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "str.xqm";
import module namespace query="http://xquery.weber-gesamtausgabe.de/modules/query" at "query.xqm";
import module namespace norm="http://xquery.weber-gesamtausgabe.de/modules/norm" at "norm.xqm";


declare function wdt:orgs($item as item()*) as map(*) {
    map {
        'name' := 'orgs',
        'prefix' := 'A08',
        'check' := function() as xs:boolean {
            if($item castable as xs:string) then matches($item, '^A08\d{4}$')
            else false()
        },
        'filter' := function() as document-node()* {
            $item[descendant-or-self::tei:org][descendant-or-self::tei:orgName]/root() | $item[ancestor::tei:org]/root()
        },
        'filter-by-person' := function($personID as xs:string) as document-node()* {
            ()
        },
        'sort' := function($params as map(*)?) as document-node()* {
            if(sort:has-index('orgs')) then ()
            else (wdt:orgs(())('init-sortIndex')()),
            for $i in wdt:orgs($item)('filter')() order by sort:index('orgs', $i) ascending return $i
            
        },
        'init-collection' := function() as document-node()* {
            wdt:orgs(core:data-collection('orgs'))('filter')()
        },
        'init-sortIndex' := function() as item()* {
            wdt:create-index-callback('orgs', wdt:orgs(())('init-collection')(), function($node) { str:normalize-space($node//tei:orgName[@type='reg']) }, ())
        },
        'title' := (),
        'undated' := (),
        'date' := (),
        'memberOf' := (), (: index, search :)
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
            $item[descendant-or-self::tei:person][descendant-or-self::tei:persName]/root() | $item[ancestor::tei:person]/root()
        },
        'filter-by-person' := function($personID as xs:string) as document-node()* {
            (:distinct-values((norm:get-norm-doc('letters')//@addresseeID[contains(., $personID)]/parent::norm:entry | norm:get-norm-doc('letters')//@authorID[contains(., $personID)]/parent::norm:entry)/(@authorID, @addresseeID)/tokenize(., '\s+'))[. != $personID] ! core:doc(.):)
            ()
        },
        'sort' := function($params as map(*)?) as document-node()* {
            if(sort:has-index('persons')) then ()
            else (wdt:persons(())('init-sortIndex')()),
            for $i in wdt:persons($item)('filter')() order by sort:index('persons', $i) ascending return $i
        },
        'init-collection' := function() as document-node()* {
            wdt:persons(core:data-collection('persons'))('filter')()
        },
        'init-sortIndex' := function() as item()* {
            wdt:create-index-callback('persons', wdt:persons(())('init-collection')(), function($node) { 
                let $sortName :=
                    if(functx:all-whitespace($node//tei:persName[@type='reg']/tei:surname[1])) then str:normalize-space(functx:substring-before-match($node//tei:persName[@type='reg'], '\s?,'))
                    else str:normalize-space($node//tei:persName[@type='reg']/tei:surname[1])
                let $name := str:normalize-space($node//tei:persName[@type='reg'])
                return $sortName || $name
            }, ())
        },
        'memberOf' := (),
        'search' := ()
    }
};

declare function wdt:letters($item as item()*) as map(*) {
    map {
        'name' := 'letters',
        'prefix' := 'A04',
        'check' := function() as xs:boolean {
            if($item castable as xs:string) then matches($item, '^A04\d{4}$')
            else false()
        },
        'filter' := function() as document-node()* {
            $item/following::tei:text[@type=('albumblatt', 'letter', 'guestbookEntry')]/root() | $item/preceding::tei:text[@type=('albumblatt', 'letter', 'guestbookEntry')]/root() | $item/self::tei:text[@type=('albumblatt', 'letter', 'guestbookEntry')]/root()
        },
        'filter-by-person' := function($personID as xs:string) as document-node()* {
            $item/following::tei:*[@key = $personID][ancestor-or-self::tei:correspAction][not(ancestor-or-self::tei:note)]/root() | $item/preceding::tei:*[@key = $personID][ancestor-or-self::tei:correspAction][not(ancestor-or-self::tei:note)]/root() 
        },
        'sort' := function($params as map(*)?) as document-node()* {
            if(sort:has-index('letters')) then ()
            else (wdt:letters(())('init-sortIndex')()),
            for $i in wdt:letters($item)('filter')() order by sort:index('letters', $i) ascending return $i
        },
        'init-collection' := function() as document-node()* {
            wdt:letters(core:data-collection('letters'))('filter')()
        },
        'init-sortIndex' := function() as item()* {
            wdt:create-index-callback('letters', wdt:letters(())('init-collection')(), function($node) {
                let $normDate := query:get-normalized-date($node)
                let $n :=  functx:pad-integer-to-length($node//tei:correspAction[@type='sent']/tei:date/data(@n), 4)
                return
                    (if(exists($normDate)) then $normDate else 'xxxx-xx-xx') || $n
            }, ())
        },
        'memberOf' := ('search', 'indices'),
        'search' := function($query as element(query)) {
            $item[tei:TEI]//tei:body[ft:query(., $query)] | 
            $item[tei:TEI]//tei:correspDesc[ft:query(., $query)] | 
            $item[tei:TEI]//tei:title[ft:query(., $query)] |
            $item[tei:TEI]//tei:note[@type='incipit'][ft:query(., $query)] | 
            $item[tei:TEI]//tei:note[ft:query(., $query)][@type = 'summary'] |
            $item[tei:TEI]/tei:TEI[ft:query(., $query)]
        }
    }
};

declare function wdt:personsPlus($item as item()*) as map(*) {
    map {
        'name' := 'personsPlus',
        'prefix' := (),
        'check' := function() as xs:boolean {
            if($item castable as xs:string) then (wdt:orgs($item)('check')() or wdt:persons($item)('check')())
            else false()
        },
        'filter' := function() as document-node()* {
            wdt:orgs($item)('filter')() | wdt:persons($item)('filter')()
        },
        'filter-by-person' := function($personID as xs:string) as document-node()* {
            () 
        },
        'sort' := function($params as map(*)?) as document-node()* {
            if(sort:has-index('personsPlus')) then ()
            else (wdt:personsPlus(())('init-sortIndex')()),
            for $i in $item order by sort:index('personsPlus', $i) ascending return $i
        },
        'init-collection' := function() as document-node()* {
            wdt:orgs($item)('init-collection')() | wdt:persons($item)('init-collection')()
        },
        'init-sortIndex' := function() as item()* {
            wdt:create-index-callback('personsPlus', wdt:personsPlus(())('init-collection')(), function($node) {
                let $sortName :=
                    if($node/tei:org) then str:normalize-space($node//tei:orgName[@type='reg'])
                    else if(functx:all-whitespace($node//tei:persName[@type='reg']/tei:surname[1])) then str:normalize-space(functx:substring-before-match($node//tei:persName[@type='reg'], '\s?,'))
                    else str:normalize-space($node//tei:persName[@type='reg']/tei:surname[1])
                let $name := str:normalize-space($node//tei:persName[@type='reg'])
                return $sortName || $name
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
    map {
        'name' := 'writings',
        'prefix' := 'A03',
        'check' := function() as xs:boolean {
            if($item castable as xs:string) then matches($item, '^A03\d{4}$')
            else false()
        },
        'filter' := function() as document-node()* {
            $item/following::tei:text[@type=('performance-review', 'historic-news')]/root() | $item/preceding::tei:text[@type=('performance-review', 'historic-news')]/root() | $item/self::tei:text[@type=('performance-review', 'historic-news')]/root()
        },
        'filter-by-person' := function($personID as xs:string) as document-node()* {
            $item/following::tei:author[@key = $personID][ancestor::tei:fileDesc]/root() | $item/preceding::tei:author[@key = $personID][ancestor::tei:fileDesc]/root()
        },
        'sort' := function($params as map(*)?) as document-node()* {
            if(sort:has-index('writings')) then ()
            else (wdt:writings(())('init-sortIndex')()),
            for $i in wdt:writings($item)('filter')() order by sort:index('writings', $i) ascending return $i
        },
        'init-collection' := function() as document-node()* {
            wdt:writings(core:data-collection('writings'))('filter')()
        },
        'init-sortIndex' := function() as item()* {
            wdt:create-index-callback('writings', wdt:writings(())('init-collection')(), function($node) {
                let $normDate := query:get-normalized-date($node)
                let $source := query:get-main-source($node)
                let $journal :=  string-join($source/tei:monogr/tei:title[@level = 'j']/str:normalize-space(.), '. ')
                return
                    (if(exists($normDate)) then $normDate else 'xxxx-xx-xx') || $journal
            }, ())
        },
        'memberOf' := ('search', 'indices'),
        'search' := function($query as element(query)) {
            $item[tei:TEI]//tei:body[ft:query(., $query)] | 
            $item[tei:TEI]//tei:title[ft:query(., $query)] |
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
            $item[descendant-or-self::mei:mei][descendant::mei:meiHead]/root() | $item[ancestor::mei:mei]/root()
        },
        'filter-by-person' := function($personID as xs:string) as document-node()* {
            $item/following::mei:persName[@dbkey = $personID][@role=('cmp', 'lbt', 'lyr')][ancestor::mei:fileDesc]/root() | $item/preceding::mei:persName[@dbkey = $personID][@role=('cmp', 'lbt', 'lyr')][ancestor::mei:fileDesc]/root() | $item/self::mei:persName[@dbkey = $personID][@role=('cmp', 'lbt', 'lyr')][ancestor::mei:fileDesc]/root()
        },
        'sort' := function($params as map(*)?) as document-node()* {
            if(sort:has-index('works')) then ()
            else (wdt:works(())('init-sortIndex')()),
            for $i in wdt:works($item)('filter')() order by sort:index('works', $i) return $i
        },
        'init-collection' := function() as document-node()* {
            wdt:works(core:data-collection('works'))('filter')()
        },
        'init-sortIndex' := function() as item()* {
            wdt:create-index-callback('works', wdt:works(())('init-collection')(), function($node) { 
                functx:pad-integer-to-length(($node//mei:seriesStmt/mei:title[@level])[1]/xs:int(@n), 4) || 
                $node//mei:altId[@type = 'WeV']/string(@subtype) || 
                functx:pad-integer-to-length($node//mei:altId[@type = 'WeV']/xs:int(@n), 4) || 
                $node//mei:altId[@type = 'WeV']/string()
            }, ())
        },
        'memberOf' := ('search', 'indices'),
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
            $item[descendant-or-self::tei:ab/@where]/root() | $item[ancestor::tei:ab/@where]/root()
        },
        'filter-by-person' := function($personID as xs:string) as document-node()* {
            if($personID eq 'A002068') then wdt:diaries(core:data-collection('diaries'))('sort')(map {})
            else ()
        },
        'sort' := function($params as map(*)?) as document-node()* {
            if(sort:has-index('diaries')) then ()
            else (wdt:diaries(())('init-sortIndex')()),
            for $i in wdt:diaries($item)('filter')() order by sort:index('diaries', $i) ascending return $i
        },
        'init-collection' := function() as document-node()* {
            wdt:diaries(core:data-collection('diaries'))('filter')()
        },
        'init-sortIndex' := function() as item()* {
            wdt:create-index-callback('diaries', wdt:diaries(())('init-collection')(), function($node) { query:get-normalized-date($node) }, ())
        },
        'memberOf' := ('search', 'indices'),
        'search' := function($query as element(query)) {
            $item[tei:ab]/tei:ab[ft:query(., $query)]
        }
    }
};

declare function wdt:news($item as item()*) as map(*) {
    map {
        'name' := 'news',
        'prefix' := 'A05',
        'check' := function() as xs:boolean {
            if($item castable as xs:string) then matches($item, '^A05\d{4}$')
            else false()
        },
        'filter' := function() as document-node()* {
            $item/following::tei:text[@type='news']/root() | $item/preceding::tei:text[@type='news']/root() | $item/self::tei:text[@type='news']/root()
        },
        'filter-by-person' := function($personID as xs:string) as document-node()* {
            $item/following::tei:author[@key = $personID][ancestor::tei:fileDesc]/root() | $item/preceding::tei:author[@key = $personID][ancestor::tei:fileDesc]/root()
        },
        'sort' := function($params as map(*)?) as document-node()* {
            if(sort:has-index('news')) then ()
            else (wdt:news(())('init-sortIndex')()),
            for $i in wdt:news($item)('filter')() order by sort:index('news', $i) descending return $i
        },
        'init-collection' := function() as document-node()* {
            wdt:news(core:data-collection('news'))('filter')()
        },
        'init-sortIndex' := function() as item()* {
            wdt:create-index-callback('news', wdt:news(())('init-collection')(), function($node) { query:get-normalized-date($node) }, ())
        },
        'memberOf' := 'search',
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
            $item[following::tei:person/@corresp]/root() | $item[preceding::tei:person/@corresp]/root() | $item[self::tei:person/@corresp]/root()
        },
        'filter-by-person' := function($personID as xs:string) as document-node()* {
            $item/following::tei:person[@corresp = $personID]/root() | $item/preceding::tei:person[@corresp = $personID]/root() | $item/self::tei:person[@corresp = $personID]/root()
        },
        'sort' := function($params as map(*)?) as document-node()* {
            if(sort:has-index('iconography')) then ()
            else (wdt:iconography(())('init-sortIndex')()),
            for $i in wdt:iconography($item)('filter')() order by sort:index('iconography', $i) descending return $i
        },
        'init-collection' := function() as document-node()* {
            wdt:iconography(core:data-collection('iconography'))('filter')()
        },
        'init-sortIndex' := function() as item()* {
            wdt:create-index-callback('iconography', wdt:iconography(())('init-collection')(), function($node) { $node//tei:person/data(@corresp) }, ())
        },
        'memberOf' := (),
        'search' := ()
    }
};

declare function wdt:var($item as item()*) as map(*) {
    map {
        'name' := 'var',
        'prefix' := 'A07',
        'check' := function() as xs:boolean {
            if($item castable as xs:string) then matches($item, '^A07\d{4}$')
            else false()
        },
        'filter' := function() as document-node()* {
            $item
        },
        'filter-by-person' := function($personID as xs:string) as document-node()* {
            ()
        },
        'sort' := function($params as map(*)?) as document-node()* {
            wdt:var($item)('filter')()
        },
        'init-collection' := function() as document-node()* {
            core:data-collection('var')
        },
        'init-sortIndex' := function() as item()* {
            ()
        },
        'memberOf' := (),
        'search' := ()
    }
};

declare function wdt:biblio($item as item()*) as map(*) {
    map {
        'name' := 'biblio',
        'prefix' := 'A11',
        'check' := function() as xs:boolean {
            if($item castable as xs:string) then matches($item, '^A11\d{4}$')
            else false()
        },
        'filter' := function() as document-node()* {
            $item[descendant-or-self::tei:biblStruct][not(ancestor-or-self::tei:TEI)]/root() | $item[ancestor::tei:biblStruct][not(ancestor::tei:TEI)]/root()
        },
        'filter-by-person' := function($personID as xs:string) as document-node()* {
            wdt:biblio($item)('filter')()//tei:author[@key = $personID]/root() | wdt:biblio($item)('filter')()//tei:editor[@key = $personID]/root() 
        },
        'sort' := function($params as map(*)?) as document-node()* {
            if(sort:has-index('biblio')) then ()
            else (wdt:biblio(())('init-sortIndex')()),
            for $i in wdt:biblio($item)('filter')() order by sort:index('biblio', $i) descending return $i
        },
        'init-collection' := function() as document-node()* {
            wdt:biblio(core:data-collection('biblio'))('filter')()
        },
        'init-sortIndex' := function() as item()* {
            wdt:create-index-callback('biblio', wdt:biblio(())('init-collection')(), function($node) { string(query:get-normalized-date($node)) }, ())
        },
        'memberOf' := 'search',
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
            $item[descendant-or-self::tei:place][not(ancestor-or-self::tei:TEI)]/root() | $item[ancestor::tei:place][not(ancestor::tei:TEI)]/root()
        },
        'filter-by-person' := function($personID as xs:string) as document-node()* {
            $item
        },
        'sort' := function($params as map(*)?) as document-node()* {
            if(sort:has-index('places')) then ()
            else (wdt:places(())('init-sortIndex')()),
            for $i in wdt:places($item)('filter')() order by sort:index('places', $i)  ascending return $i
        },
        'init-collection' := function() as document-node()* {
            wdt:places(core:data-collection('places'))('filter')()
        },
        'init-sortIndex' := function() as item()* {
            wdt:create-index-callback('places', wdt:places(())('init-collection')(), function($node) { str:normalize-space($node//tei:placeName[@type='reg']) }, ())
        },
        'memberOf' := (),
        'search' := ()
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
            ()
        },
        'filter-by-person' := function($personID as xs:string) as document-node()* {
            ()
        },
        'sort' := function($params as map(*)?) as document-node()* {
            ()
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
            distinct-values((norm:get-norm-doc('letters')//@addresseeID[contains(., $personID)]/parent::norm:entry | norm:get-norm-doc('letters')//@authorID[contains(., $personID)]/parent::norm:entry)/(@authorID, @addresseeID)/tokenize(., '\s+'))[. != $personID] ! core:doc(.)
        },
        'sort' := function($params as map(*)?) as document-node()* {
            for $i in $item order by number(query:correspondence-partners($i/tei:*/@xml:id)($params('personID'))) descending return $i
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
            (core:data-collection('letters')//@key[.=$personID][not(parent::tei:author)]/root() except core:data-collection('letters')//@key[.=$personID][ancestor::tei:correspAction]/root()) | 
            core:data-collection('diaries')//@key[.=$personID][not(parent::tei:author)]/root() |
            core:data-collection('writings')//@key[.=$personID][not(parent::tei:author)]/root() |
            core:data-collection('persons')//@key[.=$personID][not(parent::tei:persName/@type)]/root() |
            core:data-collection('news')//@key[.=$personID][not(parent::tei:author)]/root() |
            core:data-collection('orgs')//@key[.=$personID][not(parent::tei:orgName/@type)]/root() |
            core:data-collection('biblio')//tei:term[.=$personID]/root()
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
        'sort' := function($params as map(*)?) as document-node()* {
            $item
        },
        'init-collection' := function() as document-node()* {
            for $func in wdt:functions-available()
            return 
                if($func(())('memberOf') = 'indices') then $func(())('init-collection')()
                else ()
        },
        'init-sortIndex' := function() as item()* {
            for $func in wdt:functions-available()
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

declare function wdt:functions-available() as item()* {
    for $func in inspect:module-functions()
    return 
        if(not(function-name($func) = (xs:QName('wdt:functions-available'), xs:QName('wdt:lookup'), xs:QName('wdt:create-index-callback')))) then $func
        else ()
};

declare function wdt:lookup($name as xs:string, $item as item()*) as map(*) {
    try { function-lookup(xs:QName('wdt:' || $name), 1)($item) }
    catch * { core:logToFile('error', 'wdt:lookup(): failed to lookup function"' || $name || '"') }
};
