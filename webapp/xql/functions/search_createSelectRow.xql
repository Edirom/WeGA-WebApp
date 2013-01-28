xquery version "1.0" encoding "UTF-8";
declare default element namespace "http://www.w3.org/1999/xhtml"; 
declare default collation "?lang=de;strength=primary";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace session = "http://exist-db.org/xquery/session";
import module namespace wega="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/wega" at "xmldb:exist:///db/webapp/xql/modules/wega.xqm";
import module namespace xho="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/xho" at "xmldb:exist:///db/webapp/xql/modules/xho.xqm";

declare option exist:serialize "method=xhtml media-type=text/html indent=no omit-xml-declaration=yes encoding=utf-8 doctype-public=-//W3C//DTD&#160;XHTML&#160;1.0&#160;Strict//EN doctype-system=http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd";

let $lang := request:get-parameter('lang','de')
let $counter := xs:int(request:get-parameter('n',''))
let $value := request:get-parameter('value','')
return
<span class="selectRow">
    <select class="selectRowSelect" name="{concat('cat_', $counter)}" id="{concat('cat_', $counter)}"> 
        <option value="">{wega:getLanguageString('no_prefix',$lang)}</option>
        <option value="persName">{wega:getLanguageString('persName',$lang)}</option>
        <option value="placeName">{wega:getLanguageString('placeName',$lang)}</option>
        <option value="id">Id</option>
        <option value="pnd">PND</option>
        <option value="ks">Kaiserschriften</option>
        <option value="date">{wega:getLanguageString('date',$lang)}</option>
        <!--<option value="asksam">asksam</option>
        <option value="occupation">occupation</option>-->
        <!--
        <option>{wega:getLanguageString('characterName',$lang)}</option>
        <option>{wega:getLanguageString('workName',$lang)}</option>
        -->
    </select>
    <input type="text" name="{concat('input_', $counter)}" id="{concat('input_', $counter)}" maxlength="2048" title="{wega:getLanguageString('WeGA-Search',$lang)}" size="55" class="search-input" value="{$value}"/>
    <span class="side-orders" onclick="this.style.visibility='hidden';requestSelectRow('{$lang}', '{$counter + 1}', '')" title="{wega:getLanguageString('additionalSearchRow',$lang)}">{wega:getLanguageString('more',$lang)}</span>
</span>