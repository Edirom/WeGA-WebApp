xquery version "3.0" encoding "UTF-8";

declare default collation "?lang=de;strength=primary";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace xhtml="http://www.w3.org/1999/xhtml";
import module namespace wega-http="http://xquery.weber-gesamtausgabe.de/modules/wega-http" at "wega-http.xqm";
(:declare namespace session="http://exist-db.org/xquery/session";:)
(:declare namespace util="http://exist-db.org/xquery/util";:)
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";
import module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang" at "lang.xqm";

declare option exist:serialize "method=html5 media-type=text/html enforce-xhtml=yes";

declare function local:wikipedia($params as map(*)) {
    let $pnd := $params('gnd')
    let $lang := $params('lang')
    let $wikiContent := wega-http:grabExternalResource('wikipedia', $pnd, $lang, true())
    let $wikiUrl := $wikiContent//xhtml:div[@class eq 'printfooter']/xhtml:a[1]/data(@href)
    let $xslParams := config:get-xsl-params(())
    let $name := normalize-space($wikiContent//xhtml:h1[@id = 'firstHeading'])
    let $appendix := if($lang eq 'en') then 
        <p class="linkAppendix">The content of this "Wikipedia" entitled box is taken from the article "<a href='{$wikiUrl}' title='Wikipedia article for {$name}'>{$name}</a>" 
        from <a href="http://en.wikipedia.org">Wikipedia</a>, the free encyclopedia, 
        and is released under a <a href="http://creativecommons.org/licenses/by-sa/3.0/deed.en">CC-BY-SA-license</a>.
        You will find the <a href="{concat(replace($wikiUrl, 'wiki/', 'w/index.php?title='), '&amp;action=history')}" title="Authors and revision history of the Wikipedia Article for {$name}">revision history along with the authors</a> of this article in Wikipedia.</p>
        
        else 
        <p class="linkAppendix">Der Inhalt dieser mit "Wikipedia" bezeichneten Box entstammt dem Artikel "<a href='{$wikiUrl}' title='Wikipedia Artikel zu "{$name}"'>{$name}</a>" 
        aus der freien Enzyklopädie <a href="http://de.wikipedia.org" title="Wikipedia Hauptseite">Wikipedia</a> 
        und steht unter der <a href="http://creativecommons.org/licenses/by-sa/3.0/deed.de">CC-BY-SA-Lizenz</a>. 
        In der Wikipedia findet sich auch die <a href="{concat(replace($wikiUrl, 'wiki/', 'w/index.php?title='), '&amp;action=history')}" title='Autoren und Versionsgeschichte des Wikipedia Artikels zu "{$name}"'>Versionsgeschichte mitsamt Autorennamen</a> für diesen Artikel.</p>

    let $result := if(exists($wikiContent//xhtml:meta)) 
        then (
            <div class="wikipediaText">
                <h2>Wikipedia</h2>
                {transform:transform($wikiContent//xhtml:div[@id='bodyContent'], doc(concat($config:xsl-collection-path, '/person_wikipedia.xsl')), $xslParams)}
                {$appendix}
            </div>
        )
        else <span class="notAvailable">{lang:get-language-string('noWikipediaEntryFound', $lang)}</span>
        
    return 
        core:change-namespace($result, '', ())
};

(:~
 : Grab ADB article from wikisource for a given PND
 :
 : @author Peter Stadler
 : @param $pnd the PND number
 : @param $lang the language variable (de|en)
 : @return div for insertion into a xhtml page 
 :)
 
declare function local:adb($params as map(*)) {
    let $pnd := $params('gnd')
    let $lang := $params('lang')
    let $wikiContent := wega-http:grabExternalResource('adb', $pnd, (), true())
    let $xslParams := config:get-xsl-params(())
    let $name := normalize-space($wikiContent//xhtml:h1[@id = 'firstHeading'])
    let $appendix := transform:transform($wikiContent//xhtml:div[@id='adbcite'], doc(concat($config:xsl-collection-path, '/person_wikipedia.xsl')), <parameters><param name="lang" value="{$lang}"/><param name="mode" value="appendix"/></parameters>)
    let $result := if(exists($wikiContent//xhtml:meta)) 
        then (
            <div class="wikipediaText">
                {transform:transform($wikiContent//xhtml:div[@id='bodyContent'], doc(concat($config:xsl-collection-path, '/person_wikipedia.xsl')), $xslParams)}
                {$appendix}
            </div>
        )
        else <span class="notAvailable">{lang:get-language-string('noADBEntryFound', $lang)}</span>
        
    return 
        core:change-namespace($result, '', ())
};

let $func := request:get-parameter('func', '')
let $params := 
    map:new(
        for $i in request:get-parameter-names()
        return
            map:entry($i, request:get-parameter($i, ''))
    )
return
    try {
        function-lookup(xs:QName('local:' || $func), 1)($params)
    } catch * {
        error()
    }