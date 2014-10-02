xquery version "3.0" encoding "UTF-8";

(:~
: xQuery functions for (dynamically) creating JavaScript tags 
: @author Peter Stadler 
:)

module namespace js="http://xquery.weber-gesamtausgabe.de/modules/js";
declare default collation "?lang=de;strength=primary";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace wega="http://www.weber-gesamtausgabe.de";
declare namespace templates="http://exist-db.org/xquery/templates";
import module namespace config="http://xquery.weber-gesamtausgabe.de/modules/config" at "config.xqm";
import module namespace core="http://xquery.weber-gesamtausgabe.de/modules/core" at "core.xqm";

declare function js:obfuscate-email() as element(script) {
    let $email := config:get-option('bugEmail')
    return
        <script type="text/javascript">
            var e = "{substring-before($email, '@')}";
            var t = "{substring-after($email, '@')}";
            var r = '' + e + '@' + t ;
            $('.obfuscate-email').attr('href',' mailto:' +r).html(r);
        </script>
};

declare function js:load-portrait($model as map(*)) as element(script) {
    let $docID := $model('docID')
    return
        <script type="text/javascript">
            $('#portrait').mask("Loading...");
            $.get('{$docID || '/img.html'}', function(data) {{
                $('#portrait-placeholder').remove();
                $('#portrait').html(data);
                $('#portrait').hide();
                $('#portrait').unmask();
                $('#portrait').fadeIn();
            }});
        </script>
};