xquery version "3.1";

module namespace bt="http://weber-gesamtausgabe.de/xqsuite/biblio-tests";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace xhtml="http://www.w3.org/1999/xhtml";

import module namespace crud="http://xquery.weber-gesamtausgabe.de/modules/crud" at "xmldb:exist:///db/apps/WeGA-WebApp/modules/crud.xqm";
import module namespace bibl="http://xquery.weber-gesamtausgabe.de/modules/bibl" at "xmldb:exist:///db/apps/WeGA-WebApp/modules/bibl.xqm";

declare 
    %test:args('A113127')         %test:assertEquals("<xhtml:span xmlns:xhtml='http://www.w3.org/1999/xhtml' class='author'>Johann Evangelist Engl</xhtml:span>")
    %test:args('A111355')         %test:assertEquals("<xhtml:span xmlns:xhtml='http://www.w3.org/1999/xhtml' class='author'>Lucy Poate Stebbins</xhtml:span>", "<xhtml:span xmlns:xhtml='http://www.w3.org/1999/xhtml' class='author'>Richard Poate Stebbins</xhtml:span>")
    %test:args('A110130')         %test:assertEquals("<xhtml:span xmlns:xhtml='http://www.w3.org/1999/xhtml' class='author'>Dagmar Beck</xhtml:span>", "<xhtml:span xmlns:xhtml='http://www.w3.org/1999/xhtml' class='author'>Joachim Veit</xhtml:span>", "<xhtml:span xmlns:xhtml='http://www.w3.org/1999/xhtml' class='author'>Frank Ziegler</xhtml:span>")
    function bt:test-authors($a as xs:string) as element()+ {
        let $doc := crud:doc($a)
        return
            bibl:printCitation($doc/tei:biblStruct, <xhtml:div/>, 'de')//xhtml:span[@class='author']
};

declare 
    %test:args('A111355')         %test:assertEquals("<xhtml:span xmlns:xhtml='http://www.w3.org/1999/xhtml' class='title'>Enchanted Wanderer.  The Life of Carl Maria von Weber</xhtml:span>")
    %test:args('A111377')         %test:assertEquals("<xhtml:span xmlns:xhtml='http://www.w3.org/1999/xhtml' class='title'>Die Beziehungen Carl Maria v. Webers zu thüringischen Musikern</xhtml:span>")
    %test:args('A111038')         %test:assertEquals("<xhtml:span xmlns:xhtml='http://www.w3.org/1999/xhtml' class='title'>„… wer Flöte bläst, kauft doch allemahl von meinen Werken“. Anton Bernhard Fürstenaus Briefkontakte zum Verlag B. Schott’s Söhne zwischen 1819 und 1825</xhtml:span>")
    %test:args('A111057')         %test:assertEquals("<xhtml:span xmlns:xhtml='http://www.w3.org/1999/xhtml' class='title'>Die Rezeption von Carl Maria von Webers „Der Freischütz“ als deutsche Nationaloper. Diplomarbeit zum Magistra der Philosophie (Mag. phil.) an der Universität Wien</xhtml:span>")
    %test:args('A111055')         %test:assertEquals("<xhtml:span xmlns:xhtml='http://www.w3.org/1999/xhtml' class='title'>Das <xhtml:span class='tei_hi_italic'>Freischütz</xhtml:span>-Libretto: Quellensituation und intertextuelle Referenzen</xhtml:span>")
    function bt:test-title($a as xs:string) as element()+ {
        let $doc := crud:doc($a)
        return
            bibl:printCitation($doc/tei:biblStruct, <xhtml:div/>, 'de')//xhtml:span[@class='title']
};

declare 
    %test:args('A111377')         %test:assertEquals("<xhtml:span xmlns:xhtml='http://www.w3.org/1999/xhtml' class='journalTitle'>Das Thüringer Fähnlein.  Monatshefte für die mitteldeutsche Heimat</xhtml:span>")
    function bt:test-journalTitle($a as xs:string) as element() {
        let $doc := crud:doc($a)
        return
            bibl:printCitation($doc/tei:biblStruct, <xhtml:div/>, 'de')//xhtml:span[@class='journalTitle']
};

declare 
    %test:args('A111038')         %test:assertEquals("<xhtml:span xmlns:xhtml='http://www.w3.org/1999/xhtml' class='collectionTitle'>„Ei, dem alten Herrn zoll’ ich Achtung gern’“. Festschrift für Joachim Veit zum 60. Geburtstag</xhtml:span>")
    %test:args('A110745')         %test:assertEquals("<xhtml:span xmlns:xhtml='http://www.w3.org/1999/xhtml' class='collectionTitle'>Genie, Irrsinn und Ruhm.  Die Komponisten<xhtml:span class='edition'>, 7. völlig neu bearb. Auflage</xhtml:span></xhtml:span>")
    function bt:test-collectionTitle($a as xs:string) as element() {
        let $doc := crud:doc($a)
        return
            bibl:printCitation($doc/tei:biblStruct, <xhtml:div/>, 'de')//xhtml:span[@class='collectionTitle']
};

declare 
    %test:args('A111038')         %test:assertEquals("„Ei, dem alten Herrn zoll’ ich Achtung gern’“. Festschrift für Joachim Veit zum 60. Geburtstag (2016), S. 89–99")
    %test:args('A113127')         %test:assertEquals("Salzburger Volksblatt, Jg. 28, Nr. 95 (28. April 1898), [S. 3]")
    %test:args('A110998')         %test:assertEquals("Schlesien. Eine Vierteljahresschrift für Kunst, Wissenschaft und Volkstum, Jg. 19 (1974), Nr. 3, S. 158–162")
    function bt:test-printJournalCitation($a as xs:string) as xs:string {
        let $doc := crud:doc($a)
        return
            bibl:printJournalCitation($doc/tei:biblStruct/tei:monogr, <xhtml:span/>, 'de')
};

declare 
    %test:args('A112279')         %test:assertEquals("<xhtml:span xmlns:xhtml='http://www.w3.org/1999/xhtml' class='placeNYear'>Leipzig  <xhtml:sup>2</xhtml:sup>1865</xhtml:span>")
    %test:args('A111825')         %test:assertEquals("<xhtml:span xmlns:xhtml='http://www.w3.org/1999/xhtml' class='placeNYear'>München 1915</xhtml:span>")
    %test:args('A110159')         %test:assertEquals("<xhtml:span xmlns:xhtml='http://www.w3.org/1999/xhtml' class='placeNYear'>Stuttgart &amp;amp; Weimar 2002</xhtml:span>")
    %test:args('A110046')         %test:assertEquals("<xhtml:span xmlns:xhtml='http://www.w3.org/1999/xhtml' class='placeNYear'>Köln, Weimar &amp;amp; Wien 2008</xhtml:span>")
    function bt:test-placeNYear($a as xs:string) as element() {
        let $doc := crud:doc($a)
        return
            bibl:printCitation($doc/tei:biblStruct, <xhtml:div/>, 'de')//xhtml:span[@class='placeNYear']
};

declare 
    %test:args('A111057')         %test:assertXPath("$result//xhtml:span[@class='idno_DOI'] and $result//xhtml:span[@class='title'] and $result//xhtml:span[@class='author'] and $result//xhtml:span[@class='placeNYear']")
    function bt:test-printBookCitation($a as xs:string) as element() {
        let $doc := crud:doc($a)
        return
            bibl:printBookCitation($doc/tei:biblStruct, <xhtml:div/>, 'de')
};

declare 
    %test:args('A112915')         %test:assertXPath("$result//xhtml:span[@class='idno_URI'] and $result//xhtml:span[@class='title'] and $result//xhtml:span[@class='author'] and $result//xhtml:span[@class='journalTitle']")
    function bt:test-printArticleCitation($a as xs:string) as element() {
        let $doc := crud:doc($a)
        return
            bibl:printArticleCitation($doc/tei:biblStruct, <xhtml:div/>, 'de')
};

declare 
    %test:args('A113081')         %test:assertXPath("$result//xhtml:span[@class='idno_DOI'] and $result//xhtml:span[@class='title'] and $result//xhtml:span[@class='author'] and $result//xhtml:span[@class='collectionTitle'] and $result//xhtml:span[@class='editor']  and $result//xhtml:span[@class='placeNYear'] and $result//xhtml:span[@class='seriesTitle']")
    function bt:test-printIncollectionCitation($a as xs:string) as element() {
        let $doc := crud:doc($a)
        return
            bibl:printIncollectionCitation($doc/tei:biblStruct, <xhtml:div/>, 'de')
};
