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
    %test:args('A111057')         %test:assertEquals("<xhtml:span xmlns:xhtml='http://www.w3.org/1999/xhtml' class='title'>Die Rezeption von Carl Maria von Webers „Der Freischütz“ als deutsche Nationaloper. Diplomarbeit zur Magistra der Philosophie (Mag. phil.) an der Universität Wien</xhtml:span>")
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
    %test:args('A112745')         %test:assertEquals("<xhtml:div xmlns:xhtml='http://www.w3.org/1999/xhtml' class='book'><xhtml:span class='author'>Ferdinand Zehentreiter</xhtml:span>, <xhtml:span class='title'>„Dem folgt deutscher Gesang“. Adornos Physiognomik des <span xmlns='http://www.w3.org/1999/xhtml' class='tei_hi_italic'>Freischütz</span></xhtml:span> (<xhtml:span><xhtml:span class='seriesTitle'>Caprices</xhtml:span>, Bd.&#160;1</xhtml:span>), <xhtml:span class='placeNYear'>Hofheim am Taunus 2019</xhtml:span></xhtml:div>")
    %test:args('A110124')         %test:assertEquals("<xhtml:div xmlns:xhtml='http://www.w3.org/1999/xhtml' class='book'><xhtml:span class='editor'>Joachim Veit</xhtml:span>, <xhtml:span class='editor'>Eveline Bartlitz</xhtml:span> und <xhtml:span class='editor'>Dagmar Beck</xhtml:span> (Hg.), <xhtml:span class='title'>„...die Hoffnung muß das Beste thun.“ Die Emser Briefe Carl Maria von Webers an seine Frau</xhtml:span>, <xhtml:span class='placeNYear'>München 2003</xhtml:span></xhtml:div>")
    %test:args('A111337')         %test:assertEquals("<xhtml:div xmlns:xhtml='http://www.w3.org/1999/xhtml' class='book'><xhtml:span class='author'>August Apel</xhtml:span>, <xhtml:span class='title'>Die Freischützsage und ihre Wandlungen. Vom Gespensterbuch zur Oper<xhtml:span class='edition'>, Neuausgabe der Freischützsage aus dem Gespensterbuch</xhtml:span></xhtml:span>, hg. von <xhtml:span class='editor'>Otto Daube</xhtml:span>, <xhtml:span class='placeNYear'>Detmold 1941</xhtml:span></xhtml:div>")
    function bt:test-printBookCitation($a as xs:string) as element() {
        let $doc := crud:doc($a)
        return
            bibl:printBookCitation($doc/tei:biblStruct, <xhtml:div/>, 'de')
};

declare 
    %test:args('A112915')         %test:assertXPath("$result//xhtml:span[@class='idno_URI'] and $result//xhtml:span[@class='title'] and $result//xhtml:span[@class='author'] and $result//xhtml:span[@class='journalTitle']")
    %test:args('A112660')         %test:assertEquals("<xhtml:div xmlns:xhtml='http://www.w3.org/1999/xhtml'><xhtml:span class='author'>Kurt Mey</xhtml:span>, <xhtml:span class='title'>Richard Wagners Webertrauermarsch</xhtml:span>, in: <xhtml:span class='journalTitle'>Die Musik.  Illustrierte Halbmonatsschrift</xhtml:span>, Jg.&#160;6 (1907), Heft&#160;12, S.&#160;331–336</xhtml:div>")
    function bt:test-printArticleCitation($a as xs:string) as element() {
        let $doc := crud:doc($a)
        return
            bibl:printArticleCitation($doc/tei:biblStruct, <xhtml:div/>, 'de')
};

declare 
    %test:args('A110876')         %test:assertEquals(
        "<xhtml:span class='author' xmlns:xhtml='http://www.w3.org/1999/xhtml'>Karl Robert Brachtel</xhtml:span>", 
        ",  [Rezension] ", 
        "<xhtml:span class='title' xmlns:xhtml='http://www.w3.org/1999/xhtml'><a xmlns='http://www.w3.org/1999/xhtml' class='preview biblio A110900' href='/exist/apps/eXide/de/A007979/Bibliographie/A110900.html'>Hans Hoffmann: „Carl Maria von Weber – Leben und Werk“, Druck- und Verlagsgesellschaft, Husum 1978</a></xhtml:span>", 
        ", in: ", 
        "<xhtml:span class='journalTitle' xmlns:xhtml='http://www.w3.org/1999/xhtml'>Das Orchester</xhtml:span>", 
        ", Jg.&#160;27 (1979), S.&#160;774"
    )
    %test:args('A111363')         %test:assertEquals(
        "<xhtml:span class='author' xmlns:xhtml='http://www.w3.org/1999/xhtml'>Ursula Lehmann</xhtml:span>", 
        ",  [Rezension] ", 
        "<xhtml:span class='title' xmlns:xhtml='http://www.w3.org/1999/xhtml'>Wilhelm Pültz: Die Geburt der deutschen Oper. Roman um Carl Maria v. Weber, Erschienen in Leipzig; Hase &amp;amp; Koehler</xhtml:span>", 
        ", in: ", 
        "<xhtml:span class='journalTitle' xmlns:xhtml='http://www.w3.org/1999/xhtml'>Allgemeine Musikzeitung</xhtml:span>", 
        ", Jg.&#160;66 (1939), S.&#160;562"
    )
    function bt:test-printReview($a as xs:string) as node()* {
        let $doc := crud:doc($a)
        return
            bibl:printArticleCitation($doc/tei:biblStruct, <xhtml:div/>, 'de')/node()
};

declare 
    %test:args('A113081')         %test:assertXPath("$result//xhtml:span[@class='idno_DOI'] and $result//xhtml:span[@class='title'] and $result//xhtml:span[@class='author'] and $result//xhtml:span[@class='collectionTitle'] and $result//xhtml:span[@class='editor']  and $result//xhtml:span[@class='placeNYear'] and $result//xhtml:span[@class='seriesTitle']")
    %test:args('A110779')         %test:assertEquals("<xhtml:div xmlns:xhtml='http://www.w3.org/1999/xhtml'><xhtml:span class='author'>Joachim Veit</xhtml:span>, <xhtml:span class='title'>Zum Formproblem in den Kopfsätzen der Sinfonien Carl Maria von Webers</xhtml:span>, in: <xhtml:span class='collectionTitle'>Festschrift Arno Forchert zum 60. Gebrutstag</xhtml:span>, hg. von <xhtml:span class='editor'>Gerhard Allroggen</xhtml:span> und <xhtml:span class='editor'>Detlef Altenburg</xhtml:span>, <xhtml:span class='placeNYear'>Kassel 1986</xhtml:span>, S.&#160;184–199</xhtml:div>")
    %test:args('A112665')         %test:assertEquals("<xhtml:div xmlns:xhtml='http://www.w3.org/1999/xhtml'><xhtml:span class='author'>Romy Donath</xhtml:span>, <xhtml:span class='title'>Deutsche Nationaloper oder romantische Gruselstory?</xhtml:span>, in: <xhtml:span class='collectionTitle'>200 Jahre Freischütz.  Festschrift des Carl-Maria-von-Weber-Museums</xhtml:span>, hg. von <xhtml:span class='editor'>ders.</xhtml:span>, <xhtml:span class='placeNYear'>Niederjahna 2021</xhtml:span>, S.&#160;7–29</xhtml:div>")
    %test:args('A111266')         %test:assertEquals("<xhtml:div xmlns:xhtml='http://www.w3.org/1999/xhtml'><xhtml:span class='author'>Günter Haußwald</xhtml:span>, <xhtml:span class='title'>Zur Dramaturgie des „Freischütz“</xhtml:span>, in: <xhtml:span class='collectionTitle'>Carl Maria von Weber.  Eine Gedenkschrift</xhtml:span>, hg. von <xhtml:span class='editor'>dems.</xhtml:span>, <xhtml:span class='placeNYear'>Dresden 1951</xhtml:span>, S.&#160;139–151</xhtml:div>")
    function bt:test-printIncollectionCitation($a as xs:string) as element() {
        let $doc := crud:doc($a)
        return
            bibl:printIncollectionCitation($doc/tei:biblStruct, <xhtml:div/>, 'de')
};

declare 
    %test:args('A110779')         %test:assertEquals("<xhtml:span xmlns:xhtml='http://www.w3.org/1999/xhtml' class='editor'>Gerhard Allroggen</xhtml:span>", "<xhtml:span xmlns:xhtml='http://www.w3.org/1999/xhtml' class='editor'>Detlef Altenburg</xhtml:span>")
    %test:args('A110211')         %test:assertEquals("<xhtml:span xmlns:xhtml='http://www.w3.org/1999/xhtml' class='editor'>Bernhard R. Appel</xhtml:span>", "<xhtml:span xmlns:xhtml='http://www.w3.org/1999/xhtml' class='editor'>Joachim Veit</xhtml:span>")
    %test:args('A112665')         %test:assertEquals("<xhtml:span xmlns:xhtml='http://www.w3.org/1999/xhtml' class='editor'>ders.</xhtml:span>")
    %test:args('A111266')         %test:assertEquals("<xhtml:span xmlns:xhtml='http://www.w3.org/1999/xhtml' class='editor'>dems.</xhtml:span>")
    %test:args('A110035')         %test:assertEquals("<xhtml:span xmlns:xhtml='http://www.w3.org/1999/xhtml' class='editor'>dens.</xhtml:span>")
    function bt:test-ed-by($a as xs:string) as element()* {
        let $doc := crud:doc($a)
        return
            bibl:printIncollectionCitation($doc/tei:biblStruct, <xhtml:div/>, 'de')//xhtml:span[@class='editor']
};
