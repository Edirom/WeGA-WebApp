xquery version "3.1";
 
(: the following line must be added to each of the modules that include unit tests :)
import module namespace test="http://exist-db.org/xquery/xqsuite" at "resource:org/exist/xquery/lib/xqsuite/xqsuite.xql";
 
(:import module namespace wust="http://xquery.weber-gesamtausgabe.de/modules/wega-util-shared-tests" at "wega-util-shared-tests.xqm";
import module namespace dt="http://xquery.weber-gesamtausgabe.de/modules/date-tests" at "date-tests.xqm";
import module namespace st="http://xquery.weber-gesamtausgabe.de/modules/str-tests" at "str-tests.xqm";
import module namespace mt="http://xquery.weber-gesamtausgabe.de/modules/math-tests" at "math-tests.xqm";
import module namespace geot="http://xquery.weber-gesamtausgabe.de/modules/geo-tests" at "geo-tests.xqm";:)

(: the test:suite() function will run all the test-annotated functions in the module whose namespace URI you provide :)
test:suite((
    util:list-functions("http://weber-gesamtausgabe.de/xqsuite/biblio-tests")
))
