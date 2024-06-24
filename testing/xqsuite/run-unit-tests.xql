xquery version "3.1";
 
(: the following line must be added to each of the modules that include unit tests :)
import module namespace test="http://exist-db.org/xquery/xqsuite" at "resource:org/exist/xquery/lib/xqsuite/xqsuite.xql";
 
import module namespace bt="http://weber-gesamtausgabe.de/xqsuite/biblio-tests" at "biblio-tests.xqm";

(: the test:suite() function will run all the test-annotated functions in the module whose namespace URI you provide :)
test:suite((
    util:list-functions("http://weber-gesamtausgabe.de/xqsuite/biblio-tests")
))
