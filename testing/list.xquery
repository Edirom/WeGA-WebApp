xquery version "3.1";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
import module namespace functx="http://www.functx.com";

declare function local:distinct-elements($coll as document-node()*)  {
    let $elementNames := distinct-values($coll//*/local-name())
    for $i in $elementNames
    return
        for $j in $coll//*[local-name() = $i]
        group by $parent := $j/parent::*/node-name(.) 
        order by count($j) descending
        return 
            <element name="{$i}" parent="{$parent}" count="{count($j)}">{$j ! <id>{./root()/*/data(@xml:id)}</id>}</element>
};

declare function local:one-of-each($items as element()*, $counter as xs:int) {
    (:let $singletons as xs:string* := $items[@count=$counter]/string():)
    if(count($items) gt 0) then (
        let $maxes :=
            (
                for $item in $items[@count=$counter]
                let $max := (
                    for $id in $item/id
                    let $count := count($items[id = $id])
                    order by $count descending
                    return
                        string($id)
                    )[1]
                return $max
            )
        return (
            $maxes,
            local:one-of-each($items except ($items[@count=$counter] | $items[id = $maxes]), $counter + 1)
        )
    )
    else ()
};

let $res := local:distinct-elements(collection('/db/apps/WeGA-data/diaries'))
return
(:    $res[@count=1]:)
    for $i in distinct-values(local:one-of-each($res, 1))
    return
        ('http://localhost:8080/exist/apps/WeGA-WebApp/' || $i || '.html')
    