xquery version "1.0" encoding "UTF-8";
declare default collation "?lang=de;strength=primary";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
import module namespace json="http://www.json.org";
import module namespace wega="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/wega" at "xmldb:exist:///db/webapp/xql/modules/wega.xqm";

declare option exist:serialize "method=text media-type=text/javascript indent=no omit-xml-declaration=yes encoding=utf-8";

let $options := for $i in doc($wega:optionsFile)//id('javaScriptOptions')//entry
    return element {$i/string(@xml:id)}{$i/text()} 

return ('options = ', json:xml-to-json(<options>{$options}</options>))