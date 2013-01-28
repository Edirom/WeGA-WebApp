(:~
 : XQuery for use with the JUnit Test
 :
 : @author Peter Stadler 
 : @version 1.0
 :)

xquery version "1.0" encoding "UTF-8";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace mei="http://www.music-encoding.org/ns/mei";

declare option exist:serialize "method=text media-type=text/plain indent=no omit-xml-declaration=yes encoding=utf-8";

let $type := request:get-parameter('type','persons')
let $firstElem := number(request:get-parameter('firstElem','1'))

let $coll := if($type eq 'persons') then collection('/db/persons')/tei:person
             else if($type eq 'letters') then collection('/db/letters')/tei:TEI
             else if($type eq 'writings') then collection('/db/writings')/tei:TEI
             else if($type eq 'diaries') then collection('/db/diaries')/tei:ab
             else if($type eq 'works') then collection('/db/works')/mei:mei
             else if($type eq 'news') then collection('/db/news')/tei:TEI
             else()
return
<html><head/><body>{
for $x at $i in data($coll/@xml:id) return if ($i > $firstElem) then $x else ()
}</body></html>