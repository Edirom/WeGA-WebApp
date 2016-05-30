xquery version "3.1";

(:~
 : WeGA document types are defined here in an object oriented manner
 :)
module namespace wdt="http://xquery.weber-gesamtausgabe.de/modules/wdt";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

(:import module namespace functx="http://www.functx.com";:)
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
            for $i in wdt:orgs($item)('filter')() order by str:normalize-space($i//tei:orgName[@type='reg']) ascending return $i
        },
        'init-collection' := function() as document-node()* {
            core:data-collection('orgs')
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
            for $i in wdt:persons($item)('filter')() order by core:create-sort-persname($i/tei:person) ascending return $i
        },
        'init-collection' := function() as document-node()* {
            core:data-collection('persons')
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
            for $i in wdt:letters($item)('filter')() order by query:get-normalized-date($i) ascending, ($i//tei:correspAction[@type='sent']/tei:date)[1]/@n ascending return $i
        },
        'init-collection' := function() as document-node()* {
            core:data-collection('letters')
        },
        'memberOf' := ('search', 'indices'),
        'search' := function($query as element(query)) {
            $item//tei:body[ft:query(., $query)] | 
            $item//tei:correspDesc[ft:query(., $query)] | 
            $item//tei:title[ft:query(., $query)] |
            $item//tei:note[@type='incipit'][ft:query(., $query)] | 
            $item//tei:note[ft:query(., $query)][@type = 'summary'] |
            $item/tei:TEI[ft:query(., $query)]
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
            $item
        },
        'init-collection' := function() as document-node()* {
            wdt:orgs($item)('init-collection')() | wdt:persons($item)('init-collection')()
        },
        'memberOf' := ('search', 'indices'),
        'search' := function($query as element(query)) {
            $item/tei:org[ft:query(., $query)] | 
            $item//tei:orgName[ft:query(., $query)][@type] |
            $item/tei:person[ft:query(., $query)] | 
            $item//tei:persName[ft:query(., $query)][@type]
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
            for $i in wdt:writings($item)('filter')() order by query:get-normalized-date($i) ascending return $i
        },
        'init-collection' := function() as document-node()* {
            core:data-collection('writings')
        },
        'memberOf' := ('search', 'indices'),
        'search' := function($query as element(query)) {
            $item//tei:body[ft:query(., $query)] | 
            $item//tei:title[ft:query(., $query)] |
            $item/tei:TEI[ft:query(., $query)]
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
            for $i in wdt:works($item)('filter')() 
            order by 
                ($i//mei:seriesStmt/mei:title[@level])[1]/xs:int(@n) ascending, 
                $i//mei:altId[@type = 'WeV']/string(@subtype) ascending, 
                $i//mei:altId[@type = 'WeV']/xs:int(@n) ascending, 
                $i//mei:altId[@type = 'WeV']/string() ascending 
                return $i
        },
        'init-collection' := function() as document-node()* {
            core:data-collection('works')
        },
        'memberOf' := ('search', 'indices'),
        'search' := function($query as element(query)) {
            $item/mei:mei[ft:query(., $query)] | 
            $item//mei:title[ft:query(., $query)]
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
            for $i in wdt:diaries($item)('filter')() order by query:get-normalized-date($i) ascending return $i
        },
        'init-collection' := function() as document-node()* {
            core:data-collection('diaries')
        },
        'memberOf' := ('search', 'indices'),
        'search' := function($query as element(query)) {
            $item/tei:ab[ft:query(., $query)]
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
            for $i in wdt:news($item)('filter')() order by query:get-normalized-date($i) descending return $i
        },
        'init-collection' := function() as document-node()* {
            core:data-collection('news')
        },
        'memberOf' := 'search',
        'search' := function($query as element(query)) {
            $item//tei:body[ft:query(., $query)] | 
            $item//tei:title[ft:query(., $query)]
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
            wdt:iconography($item)('filter')()
        },
        'init-collection' := function() as document-node()* {
            core:data-collection('iconography')
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
            for $i in wdt:biblio($item)('filter')() order by string(query:get-normalized-date($i)) descending return $i
        },
        'init-collection' := function() as document-node()* {
            core:data-collection('biblio')
        },
        'memberOf' := 'search',
        'search' := function($query as element(query)) {
            $item//tei:biblStruct[ft:query(., $query)] | 
            $item//tei:title[ft:query(., $query)] | 
            $item//tei:author[ft:query(., $query)] | 
            $item//tei:editor[ft:query(., $query)]
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
            for $i in wdt:places($item)('filter')() order by str:normalize-space($i//tei:placeName[@type='reg']) ascending return $i
        },
        'init-collection' := function() as document-node()* {
            core:data-collection('places')
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
        'memberOf' := (),
        'search' := ()
    }
};

declare function wdt:functions-available() as item()* {
    for $func in inspect:module-functions()
    return 
        if(not(function-name($func) = (xs:QName('wdt:functions-available'), xs:QName('wdt:lookup')))) then $func
        else ()
};

declare function wdt:lookup($name as xs:string, $item as item()*) as map(*) {
    try { function-lookup(xs:QName('wdt:' || $name), 1)($item) }
    catch * { core:logToFile('error', 'wdt:lookup(): failed to lookup function"' || $name || '"') }
};
