xquery version "1.0" encoding "UTF-8";
declare default element namespace "http://www.w3.org/1999/xhtml"; 
declare default collation "?lang=de;strength=primary";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace session = "http://exist-db.org/xquery/session";
import module namespace wega="http://xquery.weber-gesamtausgabe.de/modules/wega" at "wega.xqm";
import module namespace xho="http://xquery.weber-gesamtausgabe.de/modules/xho" at "xho.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";

declare option exist:serialize "method=xhtml media-type=text/html indent=no omit-xml-declaration=yes encoding=utf-8 doctype-public=-//W3C//DTD&#160;XHTML&#160;1.0&#160;Strict//EN doctype-system=http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd";

let $lang := request:get-parameter('lang','de')
let $counter := xs:int(request:get-parameter('n',''))
let $value := request:get-parameter('value','')
return
<span class="selectRow">
    <select class="selectRowSelect" name="{concat('cat_', $counter)}" id="{concat('cat_', $counter)}"> 
        <option value="">{lang:get-language-string('no_prefix',$lang)}</option>
        <option value="persName">{lang:get-language-string('persName',$lang)}</option>
        <option value="placeName">{lang:get-language-string('placeName',$lang)}</option>
        <option value="id">Id</option>
        <option value="pnd">PND</option>
        <option value="ks">Kaiserschriften</option>
        <option value="date">{lang:get-language-string('date',$lang)}</option>
        <!--<option value="asksam">asksam</option>
        <option value="occupation">occupation</option>-->
        <!--
        <option>{lang:get-language-string('characterName',$lang)}</option>
        <option>{lang:get-language-string('workName',$lang)}</option>
        -->
    </select>
    <input type="text" name="{concat('input_', $counter)}" id="{concat('input_', $counter)}" maxlength="2048" title="{lang:get-language-string('WeGA-Search',$lang)}" size="55" class="search-input" value="{$value}"/>
    <span class="side-orders" onclick="this.style.visibility='hidden';requestSelectRow('{$lang}', '{$counter + 1}', '')" title="{lang:get-language-string('additionalSearchRow',$lang)}">{lang:get-language-string('more',$lang)}</span>
</span>