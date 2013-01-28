xquery version "1.0" encoding "UTF-8";
declare default collation "?lang=de;strength=primary";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace datetime="http://exist-db.org/xquery/datetime";
import module namespace wega="http://xquery.weber-gesamtausgabe.de/webapp/xql/modules/wega" at "xmldb:exist:///db/webapp/xql/modules/wega.xqm";

declare option exist:serialize "method=xhtml media-type=text/html indent=no omit-xml-declaration=yes";

let $docID := request:get-parameter('id','A050001')
let $lang := request:get-parameter('lang','')
let $news := wega:doc($docID)
let $xslParams := <parameters><param name="lang" value="{$lang}"/></parameters>
let $authorID := data($news//tei:titleStmt/tei:author[1]/@key)
let $dateFormat := if ($lang = 'en')
    then '%A, %B %d, %Y'
    else '%A, %d. %B %Y'

return ( 
    element h1 {
        string($news//tei:title[@level='a'])
    },
    wega:changeNamespace(transform:transform($news//tei:body, doc('/db/webapp/xsl/news.xsl'), $xslParams), '', ()),
    element p {
        attribute class {'authorDate'},
        wega:createPersonLink($authorID, $lang, 'fs'), 
        concat(', ', wega:strftime($dateFormat, datetime:date-from-dateTime($news//tei:publicationStmt/tei:date/@when), $lang))
    }
)
