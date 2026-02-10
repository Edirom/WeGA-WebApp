xquery version "3.1";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

(: the following line must be added to each of the modules that include unit tests :)
import module namespace test="http://exist-db.org/xquery/xqsuite" at "resource:org/exist/xquery/lib/xqsuite/xqsuite.xql";

import module namespace bt="http://weber-gesamtausgabe.de/xqsuite/biblio-tests" at "biblio-tests.xqm";
import module namespace wdtt="http://weber-gesamtausgabe.de/xqsuite/wdt-tests" at "wdt-tests.xqm";

declare option output:method "xml";
declare option output:media-type "application/xml";
declare option output:indent "yes";

(: the test:suite() function will run all the test-annotated functions in the module whose namespace URI you provide :)
test:suite((
    util:list-functions("http://weber-gesamtausgabe.de/xqsuite/biblio-tests"),
    util:list-functions("http://weber-gesamtausgabe.de/xqsuite/wdt-tests")
))
