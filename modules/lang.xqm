xquery version "3.0";

(:~
 : XQuery module for providing basic localization functions 
 :)
module namespace lang="http://xquery.weber-gesamtausgabe.de/modules/lang";

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

import module namespace functx="http://www.functx.com";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace wega-util="http://xquery.weber-gesamtausgabe.de/modules/wega-util" at "wega-util.xqm";
import module namespace str="http://xquery.weber-gesamtausgabe.de/modules/str" at "xmldb:exist:///db/apps/WeGA-WebApp-lib/xquery/str.xqm";

(:~ 
 : Get the language catalogue file
 :
 : @author Peter Stadler
 : @param the language switch (en|de)
 : @return document-node
 :)
declare %private function lang:get-language-catalogue($lang as xs:string) as document-node()? {
    (:collection($config:catalogues-collection-path)//tei:text[@type='language-catalogue'][@xml:lang=$lang]/root():)
    doc(str:join-path-elements(($config:catalogues-collection-path, 'dictionary_' || $lang || '.xml')))
};

(:~
 : Get language string only by key
 :
 : @author Peter Stadler
 : @param $key for the dictionary
 : @param $lang the language of the string (en|de)
 : @return xs:string
 :)
declare function lang:get-language-string($key as xs:string, $lang as xs:string) as xs:string? {
    let $catalogue := lang:get-language-catalogue($lang)
    let $lookup := normalize-space($catalogue//id($key))
    return
        if($lookup) then $lookup
        else wega-util:log-to-file('warn', 'No dictionary entry found for ' || $key)
};

(:~
 : Get language string with key and replacements
 :
 : @author Peter Stadler
 : @param $key for the dictionary
 : @param $replacements
 : @param $lang the language of the string (en|de)
 : @return xs:string
 :)
declare function lang:get-language-string($key as xs:string, $replacements as xs:string*, $lang as xs:string) as xs:string? {
    let $catalogue := lang:get-language-catalogue($lang)
    let $catalogueEntry := normalize-space($catalogue//id($key))
    let $placeHolders := 
        for $i at $count in $replacements
        let $x := concat('%',$count)
        return $x
    return 
        if($catalogueEntry) then functx:replace-multi($catalogueEntry,$placeHolders,$replacements)
        else wega-util:log-to-file('warn', 'No dictionary entry found for ' || $key)
};

(:~
 : Tries to do a reverse lookup for a given string and returns its @xml:id 
 : If there are multiple matches they are returned as a sequence, 
 : if no translation is found the empty string is returned
 :  
 : @author Peter Stadler
 : @param $string the string to lookup
 : @param $lang the language of the given string
 : @return xs:NCName* zero or more IDs
 :)
declare function lang:reverse-language-string-lookup($string as xs:string, $lang as xs:string) as xs:string* {
    let $catalogue := lang:get-language-catalogue($lang)
    return 
        $catalogue//entry[lower-case(.) eq lower-case($string)]/string(@xml:id)
        (:$catalogue//tei:item[lower-case(.) eq lower-case($string)]/string(@xml:id):)
};

(:~
 : Tries to translate a string from sourceLang to targetLang using the dictionaries 
 : If no translation is found the empty string is returned
 :  
 : @author Peter Stadler
 : @param $string the string to translate
 : @param $sourceLang the language to translate from
 : @param $targetLang the language to translate to
 : @return xs:string the translated string if successful, otherwise the empty string
 :)
declare function lang:translate-language-string($string as xs:string, $sourceLang as xs:string, $targetLang as xs:string) as xs:string {
    let $targetCatalogue := lang:get-language-catalogue($targetLang)
    let $search := $targetCatalogue//id(lang:reverse-language-string-lookup($string, $sourceLang))[1]
    return normalize-space($search)
};

(:~
 : translate function for use with the templating module
 : The language information must be given in the $model
 :
 : @author Peter Stadler
~:)
declare function lang:translate($node as node(), $model as map(*)) as element() {
    element {'xhtml:' || $node/local-name()} {
        $node/@*[not(starts-with(name(.), 'data-template'))],
        lang:get-language-string(normalize-space($node), $model('lang'))
    }
};
