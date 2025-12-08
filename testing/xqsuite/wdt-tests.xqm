xquery version "3.1";

module namespace wdtt = "http://weber-gesamtausgabe.de/xqsuite/wdt-tests";

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace xhtml = "http://www.w3.org/1999/xhtml";

import module namespace crud = "http://xquery.weber-gesamtausgabe.de/modules/crud" at "xmldb:exist:///db/apps/WeGA-WebApp/modules/crud.xqm";
import module namespace wdt = "http://xquery.weber-gesamtausgabe.de/modules/wdt" at "xmldb:exist:///db/apps/WeGA-WebApp/modules/wdt.xqm";

declare
    %test:args('A064473', 'txt')    %test:assertEquals("Donnerstag, 10. Mai 1810 (Aschaffenburg)")
    %test:args('A064499', 'txt')    %test:assertEquals("Dienstag, 5. Juni 1810 (Mannheim)")
    %test:args('A064473 A064499', 'txt')    %test:assertEquals("Donnerstag, 10. Mai 1810 (Aschaffenburg)", "Dienstag, 5. Juni 1810 (Mannheim)")
    %test:args('A064473', 'html')   %test:assertEquals('<span xmlns="http://www.w3.org/1999/xhtml">Donnerstag, 10. Mai 1810<br/>Aschaffenburg</span>')
    %test:args('A069810', 'txt')    %test:assertEmpty
    %test:args('', 'txt')           %test:assertEmpty
    %test:args('A069810', 'html')   %test:assertEmpty
    %test:args('', 'html')          %test:assertEmpty
    %test:args('', 'foo')           %test:assertEmpty
    %test:args('A064473', 'foo')    %test:assertEmpty
    function wdtt:test-diaries-title($id as xs:string, $serialization as xs:string) as item()* {
        let $docs := tokenize($id, '\s+') ! crud:doc(.)
        return
            wdt:diaries($docs)?title($serialization)
};

declare
    %test:pending('no test files included yet')
    %test:args('A044400', 'txt')    %test:assertEquals("Eigenhändig geschriebenes Verzeichnis von Sachen aus dem Besitz Webers (Anfang 1810)")
    %test:args('A044810', 'txt')    %test:assertEquals("Carl Maria von Weber: Quittung für Johann Vitus Kistner in Leipzig. Leipzig, Sonntag, 5. April 1807")
    %test:args('', 'txt')           %test:assertEmpty
    %test:args('A049810', 'html')   %test:assertEquals('<span xmlns="http://www.w3.org/1999/xhtml" class="tei_title">Carl Maria von Weber: Quittung für Johann Vitus Kistner in Leipzig <br/>Leipzig, Sonntag, 5. April 1807</span>')
    %test:args('A049810 A049811', 'html')   %test:assertEquals('<span xmlns="http://www.w3.org/1999/xhtml" class="tei_title">Carl Maria von Weber: Quittung für Johann Vitus Kistner in Leipzig <br/>Leipzig, Sonntag, 5. April 1807</span>', 'Eigenhändig geschriebenes Verzeichnis von Sachen aus dem Besitz Webers (Anfang 1810)')
    %test:args('', 'html')          %test:assertEmpty
    %test:args('', 'foo')           %test:assertEmpty
    %test:args('A044400', 'foo')    %test:assertEmpty
    function wdtt:test-biblio-title($id as xs:string, $serialization as xs:string) as item()* {
        let $docs := tokenize($id, '\s+') ! crud:doc(.)
        return
            wdt:biblio($docs)?title($serialization)
};

declare
    %test:args('A100329', 'txt')    %test:assertEquals("Eigenhändig geschriebenes Verzeichnis von Sachen aus dem Besitz Webers (Anfang 1810)")
    %test:args('A100038', 'txt')    %test:assertEquals("Carl Maria von Weber: Quittung für Johann Vitus Kistner in Leipzig. Leipzig, Sonntag, 5. April 1807")
    %test:args('', 'txt')           %test:assertEmpty
    %test:args('A100038', 'html')   %test:assertEquals('<span xmlns="http://www.w3.org/1999/xhtml" class="tei_title">Carl Maria von Weber: Quittung für Johann Vitus Kistner in Leipzig
               <br/>Leipzig, Sonntag, 5. April 1807
            </span>')
    %test:args('A100038 A100329', 'html')   %test:assertEquals('<span xmlns="http://www.w3.org/1999/xhtml" class="tei_title">Carl Maria von Weber: Quittung für Johann Vitus Kistner in Leipzig
               <br/>Leipzig, Sonntag, 5. April 1807
            </span>', 'Eigenhändig geschriebenes Verzeichnis von Sachen aus dem Besitz Webers (Anfang 1810)')
    %test:args('', 'html')          %test:assertEmpty
    %test:args('', 'foo')           %test:assertEmpty
    %test:args('A100329', 'foo')    %test:assertEmpty
    function wdtt:test-documents-title($id as xs:string, $serialization as xs:string) as item()* {
        let $docs := tokenize($id, '\s+') ! crud:doc(.)
        return
            wdt:documents($docs)?title($serialization)
};

declare
    %test:args('A045850', 'txt')    %test:assertEquals("Robert Lienau an Carl Gottlieb Röder in Leipzig. Berlin, Freitag, 21. Oktober 1870")
    %test:args('A044228', 'txt')    %test:assertEquals("Henry Lemoine an Friedrich Wilhelm Jähns in Berlin. Paris, Dienstag, 29. Juli 1879")
    %test:args('A042706', 'txt')    %test:assertEquals("Caroline von Weber an Carl Maria von Weber in London. Dresden, Samstag, 4. März 1826 (Nr. 5)")
    %test:args('', 'txt')           %test:assertEmpty
    %test:args('A045850', 'html')   %test:assertEquals('<span xmlns="http://www.w3.org/1999/xhtml" class="tei_title">Robert Lienau an Carl Gottlieb Röder  in Leipzig<br/>Berlin, Freitag, 21. Oktober 1870</span>')
    %test:args('A045850 A044228', 'html')   %test:assertEquals('<span xmlns="http://www.w3.org/1999/xhtml" class="tei_title">Robert Lienau an Carl Gottlieb Röder  in Leipzig<br/>Berlin, Freitag, 21. Oktober 1870</span>', '<span xmlns="http://www.w3.org/1999/xhtml" class="tei_title">Henry Lemoine an Friedrich Wilhelm Jähns  in Berlin<br/>Paris, Dienstag, 29. Juli 1879</span>')
    %test:args('', 'html')          %test:assertEmpty
    %test:args('', 'foo')           %test:assertEmpty
    %test:args('A042706', 'foo')    %test:assertEmpty
    function wdtt:test-letters-title($id as xs:string, $serialization as xs:string) as item()* {
        let $docs := tokenize($id, '\s+') ! crud:doc(.)
        return
            wdt:letters($docs)?title($serialization)
};

declare
    %test:args('A050148', 'txt')    %test:assertEquals("Sieben auf einen Streich – Neuerwerbung eines Manuskripts für die Berliner Weber-Sammlung")
    %test:args('A050258', 'txt')    %test:assertEquals("Wer kennt Parallelstellen in anderen Klavierwerken des frühen 19. Jahrhunderts?")
    %test:args('', 'txt')           %test:assertEmpty
    %test:args('A050148', 'html')   %test:assertEquals('Sieben auf einen Streich – Neuerwerbung eines Manuskripts für die Berliner Weber-Sammlung')
    %test:args('A050148 A050258', 'html')   %test:assertEquals('Sieben auf einen Streich – Neuerwerbung eines Manuskripts für die Berliner Weber-Sammlung', 'Wer kennt Parallelstellen in anderen Klavierwerken des frühen 19. Jahrhunderts?')
    %test:args('', 'html')          %test:assertEmpty
    %test:args('', 'foo')           %test:assertEmpty
    %test:args('A050148', 'foo')    %test:assertEmpty
    function wdtt:test-news-title($id as xs:string, $serialization as xs:string) as item()* {
        let $docs := tokenize($id, '\s+') ! crud:doc(.)
        return
            wdt:news($docs)?title($serialization)
};

declare
    %test:args('A080033', 'txt')    %test:assertEquals("Intendanz Berlin")
    %test:args('A080146', 'txt')    %test:assertEquals("Harmonischer Verein")
    %test:args('', 'txt')           %test:assertEmpty
    %test:args('A080033', 'html')   %test:assertEquals('<span xmlns="http://www.w3.org/1999/xhtml">Intendanz Berlin</span>')
    %test:args('A080033 A080146', 'html')   %test:assertEquals('<span xmlns="http://www.w3.org/1999/xhtml">Intendanz Berlin</span>', '<span xmlns="http://www.w3.org/1999/xhtml">Harmonischer Verein</span>')
    %test:args('', 'html')          %test:assertEmpty
    %test:args('', 'foo')           %test:assertEmpty
    %test:args('A080146', 'foo')    %test:assertEmpty
    function wdtt:test-orgs-title($id as xs:string, $serialization as xs:string) as item()* {
        let $docs := tokenize($id, '\s+') ! crud:doc(.)
        return
            wdt:orgs($docs)?title($serialization)
};

declare
    %test:args('A000224', 'txt')    %test:assertEquals("Breiting, Johann Georg")
    %test:args('A000FA0', 'txt')    %test:assertEquals("Hillebrand, Anna Maria")
    %test:args('', 'txt')           %test:assertEmpty
    %test:args('A000224', 'html')   %test:assertEquals('<span xmlns="http://www.w3.org/1999/xhtml">Breiting, Johann Georg</span>')
    %test:args('A000224 A000FA0', 'html')   %test:assertEquals('<span xmlns="http://www.w3.org/1999/xhtml">Breiting, Johann Georg</span>', '<span xmlns="http://www.w3.org/1999/xhtml">Hillebrand, Anna Maria</span>')
    %test:args('', 'html')          %test:assertEmpty
    %test:args('', 'foo')           %test:assertEmpty
    %test:args('A000FA0', 'foo')    %test:assertEmpty
    function wdtt:test-persons-title($id as xs:string, $serialization as xs:string) as item()* {
        let $docs := tokenize($id, '\s+') ! crud:doc(.)
        return
            wdt:persons($docs)?title($serialization)
};

declare
    %test:args('A130291', 'txt')    %test:assertEquals("Gelnhausen")
    %test:args('', 'txt')           %test:assertEmpty
    %test:args('A130291', 'html')   %test:assertEquals('<span xmlns="http://www.w3.org/1999/xhtml">Gelnhausen</span>')
    %test:args('', 'html')          %test:assertEmpty
    %test:args('', 'foo')           %test:assertEmpty
    %test:args('A130291', 'foo')    %test:assertEmpty
    function wdtt:test-places-title($id as xs:string, $serialization as xs:string) as item()* {
        let $docs := tokenize($id, '\s+') ! crud:doc(.)
        return
            wdt:places($docs)?title($serialization)
};

declare
    %test:pending('no test files included yet')
    %test:args('A044400', 'txt')    %test:assertEquals("Wilhelm Pötzsch an Friedrich Wilhelm Jähns in Berlin. München, Samstag, 24. Juni 1882")
    %test:args('A044810', 'txt')    %test:assertEquals("Carl Graf von Brühl an Caroline von Weber in Dresden. Berlin, Donnerstag, 22. November 1827")
    %test:args('A049810', 'txt')    %test:assertEquals("Carl Maria von Weber an Karl Theodor (von) Küstner in Leipzig. Dresden, Freitag, 13. Februar 1824")
    %test:args('', 'txt')           %test:assertEmpty
    %test:args('A049810', 'html')   %test:assertEquals('<span xmlns="http://www.w3.org/1999/xhtml" class="tei_title">Carl Maria von Weber an Karl Theodor (von) Küstner  in Leipzig<br/>Dresden, Freitag, 13. Februar 1824</span>')
    %test:args('A049810 A049811', 'html')   %test:assertEquals('<span xmlns="http://www.w3.org/1999/xhtml" class="tei_title">Carl Maria von Weber an Karl Theodor (von) Küstner  in Leipzig<br/>Dresden, Freitag, 13. Februar 1824</span>', '<span xmlns="http://www.w3.org/1999/xhtml" class="tei_title">Carl Maria von Weber an Karl Theodor (von) Küstner  in Leipzig<br/>Dresden, Donnerstag, 13. Januar 1825</span>')
    %test:args('', 'html')          %test:assertEmpty
    %test:args('', 'foo')           %test:assertEmpty
    %test:args('A044400', 'foo')    %test:assertEmpty
    function wdtt:test-sources-title($id as xs:string, $serialization as xs:string) as item()* {
        let $docs := tokenize($id, '\s+') ! crud:doc(.)
        return
            wdt:sources($docs)?title($serialization)
};

declare
    %test:args('A090011', 'txt')    %test:assertEquals("Tonkünstlers Leben")
    %test:args('A090178', 'txt')    %test:assertEquals("Der Musikdirektorenposten am Nassauischen Hoftheater in Wiesbaden von 1811 bis 1813")
    %test:args('', 'txt')           %test:assertEmpty
    %test:args('A090011', 'html')   %test:assertEquals('Tonkünstlers Leben')
    %test:args('A090011 A090178', 'html')   %test:assertEquals('Tonkünstlers Leben', 'Der Musikdirektorenposten am Nassauischen Hoftheater in Wiesbaden von 1811 bis 1813')
    %test:args('', 'html')          %test:assertEmpty
    %test:args('', 'foo')           %test:assertEmpty
    %test:args('A090178', 'foo')    %test:assertEmpty
    function wdtt:test-thematicCommentaries-title($id as xs:string, $serialization as xs:string) as item()* {
        let $docs := tokenize($id, '\s+') ! crud:doc(.)
        return
            wdt:thematicCommentaries($docs)?title($serialization)
};

declare
    %test:args('A070001', 'txt')    %test:assertEquals("Editionsrichtlinien zur Ausgabe der Briefe, Tagebücher und Dokumente Webers")
    %test:args('A070012', 'txt')    %test:assertEquals("API Dokumentation")
    %test:args('', 'txt')           %test:assertEmpty
    %test:args('A070001', 'html')   %test:assertEquals('Editionsrichtlinien zur Ausgabe der Briefe, Tagebücher und Dokumente Webers')
    %test:args('A070001 A070012', 'html')   %test:assertEquals('Editionsrichtlinien zur Ausgabe der Briefe, Tagebücher und Dokumente Webers', 'API Dokumentation')
    %test:args('', 'html')          %test:assertEmpty
    %test:args('', 'foo')           %test:assertEmpty
    %test:args('A070012', 'foo')    %test:assertEmpty
    function wdtt:test-var-title($id as xs:string, $serialization as xs:string) as item()* {
        let $docs := tokenize($id, '\s+') ! crud:doc(.)
        return
            wdt:var($docs)?title($serialization)
};

declare
    %test:args('A020002', 'txt')    %test:assertEquals("Missa sancta (Nr. 1) Es-Dur")
    %test:args('A020772', 'txt')    %test:assertEquals("Agnes von Hohenstaufen")
    %test:args('', 'txt')           %test:assertEmpty
    %test:args('A020002', 'html')   %test:assertEquals('<span xmlns="http://www.w3.org/1999/xhtml">Missa sancta (Nr. 1) Es-Dur</span>')
    %test:args('A020002 A020772', 'html')   %test:assertEquals('<span xmlns="http://www.w3.org/1999/xhtml">Missa sancta (Nr. 1) Es-Dur</span>', '<span xmlns="http://www.w3.org/1999/xhtml">Agnes von Hohenstaufen</span>')
    %test:args('', 'html')          %test:assertEmpty
    %test:args('', 'foo')           %test:assertEmpty
    %test:args('A020772', 'foo')    %test:assertEmpty
    function wdtt:test-works-title($id as xs:string, $serialization as xs:string) as item()* {
        let $docs := tokenize($id, '\s+') ! crud:doc(.)
        return
            wdt:works($docs)?title($serialization)
};

declare
    %test:args('A031800', 'txt')    %test:assertEquals("Aufführungsbesprechung Dresden: Jubelkantate von Carl Maria von Weber, 23. September 1818")
    %test:args('A032076', 'txt')    %test:assertEquals("Aufführungsbesprechung in Darmstadt (Hofoper): Euryanthe von Carl Maria von Weber am 27. November 1825")
    %test:args('', 'txt')           %test:assertEmpty
    %test:args('A031800', 'html')   %test:assertEquals('Aufführungsbesprechung Dresden: Jubelkantate von Carl Maria von Weber, 23. September 1818')
    %test:args('A031800 A032076', 'html')   %test:assertEquals('Aufführungsbesprechung Dresden: Jubelkantate von Carl Maria von Weber, 23. September 1818', '<span xmlns="http://www.w3.org/1999/xhtml" class="tei_title">Aufführungsbesprechung in Darmstadt (Hofoper): <span class="tei_hi_italic">Euryanthe</span> von Carl Maria von Weber am 27. November 1825</span>')
    %test:args('', 'html')          %test:assertEmpty
    %test:args('', 'foo')           %test:assertEmpty
    %test:args('A032076', 'foo')    %test:assertEmpty
    function wdtt:test-writings-title($id as xs:string, $serialization as xs:string) as item()* {
        let $docs := tokenize($id, '\s+') ! crud:doc(.)
        return
            wdt:writings($docs)?title($serialization)
};
