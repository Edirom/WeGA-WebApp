xquery version "3.1";

module namespace wdtt = "http://weber-gesamtausgabe.de/xqsuite/wdt-tests";

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace xhtml = "http://www.w3.org/1999/xhtml";

import module namespace crud = "http://xquery.weber-gesamtausgabe.de/modules/crud" at "xmldb:exist:///db/apps/WeGA-WebApp/modules/crud.xqm";
import module namespace wdt = "http://xquery.weber-gesamtausgabe.de/modules/wdt" at "xmldb:exist:///db/apps/WeGA-WebApp/modules/wdt.xqm";

declare
    %test:args('A064400', 'txt')    %test:assertEquals("Montag, 26. Februar 1810 (Stuttgart, Heilbronn)")
    %test:args('A064810', 'txt')    %test:assertEquals("Sonntag, 11. Januar 1824 (Dresden)")
    %test:args('A064810 A064811', 'txt')    %test:assertEquals("Sonntag, 11. Januar 1824 (Dresden)", "Montag, 12. Januar 1824 (Dresden)")
    %test:args('A064810', 'html')   %test:assertEquals('<span xmlns="http://www.w3.org/1999/xhtml">Sonntag, 11. Januar 1824<br/>Dresden</span>')
    %test:args('A069810', 'txt')    %test:assertEmpty
    %test:args('', 'txt')           %test:assertEmpty
    %test:args('A069810', 'html')   %test:assertEmpty
    %test:args('', 'html')          %test:assertEmpty
    %test:args('', 'foo')           %test:assertEmpty
    %test:args('A064400', 'foo')    %test:assertEmpty
    function wdtt:test-diaries-title($id as xs:string, $serialization as xs:string) as item()* {
        let $docs := tokenize($id, '\s+') ! crud:doc(.)
        return
            wdt:diaries($docs)?title($serialization)
};

declare
    %test:args('A044400', 'txt')    %test:assertEquals("Wilhelm Pötzsch an Friedrich Wilhelm Jähns in Berlin. München, Samstag, 24. Juni 1882")
    %test:args('A044810', 'txt')    %test:assertEquals("Carl Graf von Brühl an Caroline von Weber in Dresden. Berlin, Donnerstag, 22. November 1827")
    %test:args('A049810', 'txt')    %test:assertEquals("Carl Maria von Weber an Karl Theodor (von) Küstner in Leipzig. Dresden, Freitag, 13. Februar 1824")
    %test:args('', 'txt')           %test:assertEmpty
    %test:args('A049810', 'html')   %test:assertEquals('<span xmlns="http://www.w3.org/1999/xhtml" class="tei_title">Carl Maria von Weber an Karl Theodor (von) Küstner  in Leipzig<br/>Dresden, Freitag, 13. Februar 1824</span>')
    %test:args('A049810 A049811', 'html')   %test:assertEquals('<span xmlns="http://www.w3.org/1999/xhtml" class="tei_title">Carl Maria von Weber an Karl Theodor (von) Küstner  in Leipzig<br/>Dresden, Freitag, 13. Februar 1824</span>', '<span xmlns="http://www.w3.org/1999/xhtml" class="tei_title">Carl Maria von Weber an Karl Theodor (von) Küstner  in Leipzig<br/>Dresden, Donnerstag, 13. Januar 1825</span>')
    %test:args('', 'html')          %test:assertEmpty
    %test:args('', 'foo')           %test:assertEmpty
    %test:args('A044400', 'foo')    %test:assertEmpty
    function wdtt:test-letters-title($id as xs:string, $serialization as xs:string) as item()* {
        let $docs := tokenize($id, '\s+') ! crud:doc(.)
        return
            wdt:letters($docs)?title($serialization)
};
