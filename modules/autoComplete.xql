xquery version "1.0" encoding "UTF-8";
declare default collation "?lang=de;strength=primary";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace request = "http://exist-db.org/xquery/request";
declare namespace session = "http://exist-db.org/xquery/session";

declare variable $local:callback := util:function(xs:QName("local:term-callback"), 2);

declare function local:term-callback($term as xs:string, $data as xs:int+) as element()? {
    <entry freq="{$data[2]}">{normalize-space($term)}</entry>
};

declare function local:getIndexKeys() {
    let $c := collection('/db/persons')//tei:person
        return
       	    for $k in util:index-keys($c,'',$local:callback,10000)
       	    order by $k/xs:int(@freq) descending
       	    return $k
};

declare function local:get-autoCompleteList() as item()* {
    let $indexKeys := local:getIndexKeys()
    let $list  := for $x in distinct-values($indexKeys)
                  return if(not(matches($x,'&amp;|"|\?|\(|\)|-|\.|/|>|1|2|3|4|5|6|7|8|9|0')) and string-length($x) gt 1) then $x else()
    return $list
};

declare function local:get-or-set-autoCompleteList() as item()* {
    if(exists(session:get-attribute('autoCompleteList')))
    then session:get-attribute('autoCompleteList')
    else let $list := local:get-autoCompleteList()
         let $save := session:set-attribute('autoCompleteList',$list)
         return $list
};

let $lang  := request:get-parameter('lang','de')
let $query := request:get-parameter('key','')
(:let $delete := session:remove-attribute('autoCompleteList'):)
let $allNamesList  := if($query='') then () else local:get-or-set-autoCompleteList()
let $list := for $x at $i in $allNamesList return if(starts-with(lower-case($x),lower-case($query))) then $x else() 

return
    (:"{query: 'Li',suggestions: ['Liberia','Libyan Arab Jamahiriya','Liechtenstein','Lithuania'],data: ['LR','LY','LI','LT']}":)
    <table style="text-align:left">
    {
    for $x at $i in $list
    return
        if($i lt 10) 
        then 
            <tr>
                <td onclick="selectSuggestion('{$x}','{$lang}')" style="cursor:pointer">{$x}</td>
            </tr> 
        else()
    }
    </table>