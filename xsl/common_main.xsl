<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:wega="http://xquery.weber-gesamtausgabe.de/webapp/functions/utilities" 
    xmlns:tei="http://www.tei-c.org/ns/1.0" 
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:rng="http://relaxng.org/ns/structure/1.0" 
    xmlns:functx="http://www.functx.com" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:mei="http://www.music-encoding.org/ns/mei" version="2.0">
    
    <xsl:output encoding="UTF-8" method="html" omit-xml-declaration="yes" indent="no"/>

    <!--  *********************************************  -->
    <!--  *             Global Variables              *  -->
    <!--  *********************************************  -->
<!--    <xsl:variable name="optionsFile" select="'/db/webapp/xml/wegaOptions.xml'"/>-->
    <xsl:variable name="blockLevelElements" as="xs:string+" select="('item', 'p')"/>
    <xsl:variable name="musical-symbols" as="xs:string" select="'[&#x1d100;-&#x1d1ff;♭-♯]+'"/>
    <xsl:param name="optionsFile"/>
    <xsl:param name="baseHref"/>
    <xsl:param name="lang"/>
    <xsl:param name="dbPath"/>
    <xsl:param name="docID"/>
    <xsl:param name="transcript"/>
    <xsl:param name="smufl-decl"/>
    <xsl:param name="data-collection-path"/>
    <xsl:param name="suppressLinks"/><!-- Suppress internal links to persons, works etc. as well as tool tips -->
    
    <xsl:key name="charDecl" match="tei:char" use="@xml:id"/>

    <!--  *********************************************  -->
    <!--  *             Global Functions              *  -->
    <!--  *********************************************  -->

    <xsl:function name="wega:getAuthorFromTeiDoc" as="xs:string">
        <xsl:param name="docID" as="xs:string"/>
        <!-- construct path to File (collection function does not work! cf. http://exist.2174344.n4.nabble.com/error-with-collection-in-XSLT-within-eXist-td2189008.html) -->
        <xsl:variable name="pathToDoc" select="concat(wega:getCollectionPath($docID), '/', $docID, '.xml')"/>
        <xsl:variable name="docAvailable" select="doc-available($pathToDoc)"/>
        <xsl:choose>
            <xsl:when test="wega:isWork($docID) and $docAvailable">
                <xsl:choose>
                    <xsl:when test="doc($pathToDoc)//mei:titleStmt/mei:respStmt/mei:persName[@role = 'cmp'][1]/@dbkey">
                        <xsl:value-of select="doc($pathToDoc)//mei:titleStmt/mei:respStmt/mei:persName[@role = 'cmp'][1]/string(@dbkey)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="wega:getOption('anonymusID')"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="wega:isDiary($docID) and $docAvailable">
                <xsl:value-of select="'A002068'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="$docAvailable">
                        <xsl:choose>
                            <xsl:when test="doc($pathToDoc)//tei:fileDesc//tei:titleStmt//tei:author[1]/@key">
                                <xsl:value-of select="doc($pathToDoc)//tei:fileDesc//tei:titleStmt//tei:author[1]/string(@key)"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="wega:getOption('anonymusID')"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="''"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="wega:getCollectionPath" as="xs:string">
        <xsl:param name="docID" as="xs:string"/>
        <xsl:value-of select="string-join(($data-collection-path, wega:get-doctype-by-id($docID), concat(substring($docID, 1, 5), 'xx')), '/')"/>
    </xsl:function>

    <xsl:function name="wega:getOption" as="xs:string">
        <xsl:param name="key" as="xs:string"/>
        <xsl:value-of select="doc($optionsFile)//entry[@xml:id = $key]/text()"/>
    </xsl:function>

    <xsl:function name="wega:getLanguageString" as="xs:string">
        <xsl:param name="key" as="xs:string"/>
        <xsl:param name="lang" as="xs:string"/>
        <xsl:value-of select="doc(wega:getOption(concat('dic_', $lang)))//entry[@xml:id = $key]/text()"/>
    </xsl:function>

    <xsl:function name="wega:isPerson" as="xs:boolean">
        <xsl:param name="docID" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="matches($docID, '^A00\d{4}$')">
                <xsl:value-of select="true()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="false()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="wega:isIconography" as="xs:boolean">
        <xsl:param name="docID" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="matches($docID, '^A01\d{4}$')">
                <xsl:value-of select="true()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="false()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="wega:isWork" as="xs:boolean">
        <xsl:param name="docID" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="matches($docID, '^A02\d{4}$')">
                <xsl:value-of select="true()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="false()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="wega:isWriting" as="xs:boolean">
        <xsl:param name="docID" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="matches($docID, '^A03\d{4}$')">
                <xsl:value-of select="true()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="false()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="wega:isLetter" as="xs:boolean">
        <xsl:param name="docID" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="matches($docID, '^A04\d{4}$')">
                <xsl:value-of select="true()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="false()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="wega:isNews" as="xs:boolean">
        <xsl:param name="docID" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="matches($docID, '^A05\d{4}$')">
                <xsl:value-of select="true()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="false()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="wega:isDiary" as="xs:boolean">
        <xsl:param name="docID" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="matches($docID, '^A06\d{4}$')">
                <xsl:value-of select="true()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="false()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="wega:isVar" as="xs:boolean">
        <xsl:param name="docID" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="matches($docID, '^A07\d{4}$')">
                <xsl:value-of select="true()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="false()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="wega:isBiblio" as="xs:boolean">
        <xsl:param name="docID" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="matches($docID, '^A11\d{4}$')">
                <xsl:value-of select="true()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="false()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="wega:isPlace" as="xs:boolean">
        <xsl:param name="docID" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="matches($docID, '^A13\d{4}$')">
                <xsl:value-of select="true()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="false()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="wega:isSource" as="xs:boolean">
        <xsl:param name="docID" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="matches($docID, '^A22\d{4}$')">
                <xsl:value-of select="true()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="false()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="wega:get-doctype-by-id" as="xs:string?">
        <xsl:param name="docID" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="wega:isPerson($docID)">
                <xsl:value-of select="'persons'"/>
            </xsl:when>
            <xsl:when test="wega:isIconography($docID)">
                <xsl:value-of select="'iconography'"/>
            </xsl:when>
            <xsl:when test="wega:isWork($docID)">
                <xsl:value-of select="'works'"/>
            </xsl:when>
            <xsl:when test="wega:isWriting($docID)">
                <xsl:value-of select="'writings'"/>
            </xsl:when>
            <xsl:when test="wega:isLetter($docID)">
                <xsl:value-of select="'letters'"/>
            </xsl:when>
            <xsl:when test="wega:isNews($docID)">
                <xsl:value-of select="'news'"/>
            </xsl:when>
            <xsl:when test="wega:isDiary($docID)">
                <xsl:value-of select="'diaries'"/>
            </xsl:when>
            <xsl:when test="wega:isVar($docID)">
                <xsl:value-of select="'var'"/>
            </xsl:when>
            <xsl:when test="wega:isBiblio($docID)">
                <xsl:value-of select="'biblio'"/>
            </xsl:when>
            <xsl:when test="wega:isPlace($docID)">
                <xsl:value-of select="'places'"/>
            </xsl:when>
            <xsl:when test="wega:isSource($docID)">
                <xsl:value-of select="'sources'"/>
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="wega:createLinkToDoc" as="xs:string?">
        <xsl:param name="docID" as="xs:string"/>
        <xsl:param name="lang" as="xs:string"/>
        <xsl:variable name="authorID">
            <xsl:choose>
                <xsl:when test="wega:isPerson($docID)"/>
                <xsl:otherwise>
                    <xsl:value-of select="wega:getAuthorFromTeiDoc($docID)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="folder">
            <xsl:choose>
                <xsl:when test="wega:isWork($docID)">
                    <xsl:value-of select="wega:getLanguageString('works', $lang)"/>
                </xsl:when>
                <xsl:when test="wega:isWriting($docID)">
                    <xsl:value-of select="wega:getLanguageString('writings', $lang)"/>
                </xsl:when>
                <xsl:when test="wega:isLetter($docID)">
                    <xsl:value-of select="wega:getLanguageString('correspondence', $lang)"/>
                </xsl:when>
                <xsl:when test="wega:isNews($docID)">
                    <xsl:value-of select="wega:getLanguageString('news', $lang)"/>
                </xsl:when>
                <xsl:when test="wega:isDiary($docID)">
                    <xsl:value-of select="wega:getLanguageString('diaries', $lang)"/>
                </xsl:when>
                <xsl:otherwise/>
            </xsl:choose>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="wega:isPerson($docID)">
                <xsl:value-of select="concat(wega:join-path-elements(($baseHref, $lang, $docID)), '.html')"/>
            </xsl:when>
            <xsl:when test="exists($folder) and $authorID ne ''">
                <xsl:value-of select="concat(wega:join-path-elements(($baseHref, $lang, $authorID, $folder, $docID)), '.html')"/>
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="wega:obfuscateEmail" as="xs:string">
        <xsl:param name="email" as="xs:string"/>
        <xsl:value-of select="string-join(tokenize($email, ' [at] '), ' [ at ] ')"/>
    </xsl:function>

    <xsl:function name="wega:encryptString" as="xs:integer+">
        <xsl:param name="string" as="xs:string"/>
        <xsl:param name="salt" as="xs:integer?"/>
        <xsl:variable name="mySalt" as="xs:integer">
            <xsl:choose>
                <xsl:when test="$salt != 0">
                    <xsl:value-of select="$salt"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="wega:getOption('salt')"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:sequence select="for $k in string-to-codepoints($string) return $k * $mySalt"/>
    </xsl:function>

    <xsl:function name="wega:addCurrencySymbolIfNecessary" as="element(xhtml:span)?">
        <xsl:param name="measure" as="element(tei:measure)"/>
        <!-- Wenn kein Währungssymbol angegeben ist, setzen wir eins hinzu -->
        <xsl:if test="matches(normalize-space($measure),'^\d+\.?$') and $measure/@quantity &gt; 0">
            <xsl:element name="span">
                <xsl:attribute name="class" select="'tei_supplied'"/>
                <xsl:value-of select="concat(' ', $measure/@unit)"/>
            </xsl:element>
        </xsl:if>
    </xsl:function>

    <xsl:function name="wega:createLightboxAnchor" as="element()?">
        <xsl:param name="href" as="xs:string"/>
        <xsl:param name="title" as="xs:string"/>
        <xsl:param name="group" as="xs:string"/>
        <!-- muss kleingeschrieben sein! -->
        <xsl:param name="content" as="item()*"/>
        <xsl:variable name="options" as="xs:string" select="concat('group:',$group)"/>
        <xsl:element name="a">
            <xsl:attribute name="href" select="$href"/>
            <xsl:attribute name="class" select="string('lytebox')"/>
            <xsl:attribute name="data-lyte-options" select="$options"/>
            <xsl:attribute name="data-title" select="$title"/>
            <xsl:sequence select="$content"/>
        </xsl:element>
    </xsl:function>

    <xsl:function name="wega:getTextAlignment" as="xs:string">
        <xsl:param name="rend" as="xs:string?"/>
        <xsl:param name="default" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="$rend = ('left', 'right', 'center')">
                <xsl:value-of select="concat('textAlign-', $rend)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat('textAlign-', $default)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="wega:computeMedian" as="xs:double?">
        <xsl:param name="numbers" as="xs:double*"/>
        <xsl:variable name="orderedNumbers" as="xs:double*">
            <xsl:for-each select="$numbers">
                <xsl:sort select="."/>
                <xsl:value-of select="."/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="middle" as="xs:double" select="(count($orderedNumbers) + 1) div 2"/>
        <xsl:value-of select="avg(($orderedNumbers[ceiling($middle)], $orderedNumbers[floor($middle)]))"/>
    </xsl:function>
    
    <xsl:function name="wega:join-path-elements" as="xs:string">
        <xsl:param name="segs" as="xs:string*"/>
        <xsl:value-of select="replace(string-join(('/', $segs), '/'), '/+', '/')"/>
    </xsl:function>
        
    <xsl:function name="wega:hex2dec" as="xs:integer?">
        <!-- Taken from http://blog.sam.liddicott.com/2006/04/xslt-hex-to-decimal-conversion.html -->
        <xsl:param name="str" as="xs:string"/>
        <xsl:if test="$str != ''">
            <xsl:variable name="len" select="string-length($str)"/>
            <xsl:value-of select="                 if ( $len lt 2 ) then string-length(substring-before('0 1 2 3 4 5 6 7 8 9 AaBbCcDdEeFf',$str)) idiv 2                 else wega:hex2dec(substring($str,1,$len - 1))*16 + wega:hex2dec(substring($str,$len))                 "/>
        </xsl:if>
    </xsl:function>
        
    <!--  *********************************************  -->
    <!--  * Functx - Funktionen http://www.functx.com *  -->
    <!--  *********************************************  -->
    <xsl:function name="functx:replace-multi" as="xs:string?">
        <xsl:param name="arg" as="xs:string?"/>
        <xsl:param name="changeFrom" as="xs:string*"/>
        <xsl:param name="changeTo" as="xs:string*"/>
        <xsl:sequence select="if (count($changeFrom) &gt; 0)              then functx:replace-multi(replace($arg, $changeFrom[1], functx:if-absent($changeTo[1],'')), $changeFrom[position() &gt; 1], $changeTo[position() &gt; 1])              else $arg"/>
    </xsl:function>
    <xsl:function name="functx:if-absent" as="item()*">
        <xsl:param name="arg" as="item()*"/>
        <xsl:param name="value" as="item()*"/>
        <xsl:sequence select="if (exists($arg)) then $arg else $value"/>
    </xsl:function>

    <!--  *********************************************  -->
    <!--  *            Named Templates                *  -->
    <!--  *********************************************  -->
    <xsl:template name="dots">
        <xsl:param name="count" select="1"/>
        <xsl:if test="$count &gt; 0">
            <xsl:text>&#160;</xsl:text>
            <xsl:call-template name="dots">
                <xsl:with-param name="count" select="$count - 1"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <xsl:template name="popover">
        <!--<xsl:param name="id"/>-->
        <xsl:variable name="id">
            <xsl:choose>
                <xsl:when test="@xml:id">
                    <xsl:value-of select="@xml:id"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="generate-id(.)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="./descendant::*[local-name(.) = $blockLevelElements]"/>
            <xsl:otherwise>
               <xsl:element name="a">
                  <xsl:attribute name="class">noteMarker</xsl:attribute>
                  <xsl:attribute name="data-toggle">popover</xsl:attribute>
                  <xsl:attribute name="data-trigger">focus</xsl:attribute>
<!--                  <xsl:attribute name="title" select="normalize-space(@type)"/>-->
                  <xsl:attribute name="tabindex">0</xsl:attribute>
                  <xsl:attribute name="data-ref" select="$id"/>
                  <!--<xsl:attribute name="id">
                     <xsl:value-of select="concat('noteMarker_',$no)"/>
                  </xsl:attribute>-->
                  <xsl:text>*</xsl:text>
                </xsl:element>
                <!--<xsl:element name="span">
                    <xsl:attribute name="class" select="'inlineNote'"/>
                    <xsl:attribute name="id">
                        <xsl:value-of select="concat('note_',$no)"/>
                    </xsl:attribute>
                    <xsl:apply-templates/>
                </xsl:element>-->
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="createEndnotes">
        <xsl:element name="div">
            <xsl:attribute name="id" select="'endNotes'"/>
            <xsl:element name="ul">
                <xsl:for-each select="//tei:footNote">
                    <xsl:element name="li">
                        <xsl:attribute name="id" select="./@xml:id"/>
                        <xsl:apply-templates/>
                    </xsl:element>
                </xsl:for-each>
            </xsl:element>
        </xsl:element>
    </xsl:template>

    <!--  *********************************************  -->
    <!--  *                  Templates                *  -->
    <!--  *********************************************  -->
    <xsl:template match="tei:reg"/>

    <xsl:template match="tei:lb" priority="0.5">
        <xsl:if test="@type='inWord'">
            <xsl:element name="span">
                <xsl:attribute name="class" select="'break_inWord'"/>
                <xsl:text>-</xsl:text>
            </xsl:element>
        </xsl:if>
        <xsl:element name="br"/>
    </xsl:template>

    <!-- 
        tei:seg und tei:signed mit @rend werden schon als block-level-Elemente gesetzt, 
        brauchen daher keinen Zeilenumbruch mehr 
    -->
    <xsl:template match="tei:lb[following-sibling::*[1] = following-sibling::tei:seg[@rend]]" priority="0.6"/>
    <xsl:template match="tei:lb[following-sibling::*[1] = following-sibling::tei:signed[@rend]]" priority="0.6"/>

    <xsl:template match="text()">
        <xsl:variable name="regex" select="string-join((&#34;'&#34;, $musical-symbols), '|')"/>
        <xsl:analyze-string select="." regex="{$regex}">
            <xsl:matching-substring>
                <!--       Ersetzen von Pfundzeichen in Bild         -->
                <!--<xsl:if test="matches(.,'℔')">
                    <xsl:element name="span">
                    <xsl:attribute name="class" select="'pfund'"/>
                    <xsl:text>℔</xsl:text>
                    </xsl:element>
                </xsl:if>-->
                <!-- Ersetzen von normalem Apostroph in typographisches -->
                <xsl:if test="matches(.,&#34;'&#34;)">
                    <xsl:text>’</xsl:text>
                </xsl:if>
                <!-- Umschliessen von musikalischen Symbolen mit html:span -->
                <xsl:if test="matches(., $musical-symbols)">
                    <xsl:element name="span">
                        <xsl:attribute name="class" select="'musical-symbols'"/>
                        <xsl:value-of select="."/>
                    </xsl:element>
                </xsl:if>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:copy/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:template>

    <xsl:template match="tei:hi[@rend='underline']">
        <xsl:element name="span">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class">
                <xsl:choose>
                    <xsl:when test="@n &gt; 1 or ancestor::tei:hi[@rend='underline']">
                        <xsl:value-of select="'tei_hi_underline2andMore'"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'tei_hi_underline1'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <!--  Hier mit priority 0.5, da in Briefen und Tagebüchern unterschiedlich behandelt  -->
    <xsl:template match="tei:pb|tei:cb" priority="0.5">
        <xsl:variable name="division-sign" as="xs:string">
            <xsl:choose>
                <xsl:when test="local-name() eq 'pb'">
                    <xsl:value-of select="' | '"/> <!-- senkrechter Strich („|“) aka pipe -->
                </xsl:when>
                <xsl:when test="local-name() eq 'cb'">
                    <xsl:value-of select="' ¦ '"/> <!-- in der Mitte unterbrochener („¦“) senkrechter Strich -->
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:element name="span">
            <xsl:attribute name="class" select="concat('tei_', local-name())"/>
            <!-- breaks between block level elements -->
            <xsl:if test="parent::tei:div or parent::tei:body">
                <xsl:attribute name="class" select="concat('tei_', local-name(), '_block')"/>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="@type='inWord'">
                    <xsl:value-of select="normalize-space($division-sign)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$division-sign"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>

    <xsl:template match="tei:space">
        <!--        <xsl:text>[</xsl:text>-->
        <xsl:call-template name="dots">
            <xsl:with-param name="count">
                <xsl:value-of select="@quantity"/>
                <!--                <xsl:value-of select="substring-before(@extent,' ')"/>-->
            </xsl:with-param>
        </xsl:call-template>
        <!--        <xsl:text>] </xsl:text>-->
    </xsl:template>
    <xsl:template match="tei:table">
        <xsl:element name="table">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:element name="tbody">
                <xsl:variable name="currNode" select="."/>
                <!-- Bestimmung der Breite der Tabellenspalten -->
                <xsl:variable name="define-width-of-cells" as="xs:double*">
                    <xsl:choose>
                <!-- 
                    Mittels median wird eine alternative Berechnung der Spaltenbreiten angeboten
                    Dabei wird nicht das arithmetische Mittel der Zeichenlängen der jeweiligen Spalten genommen,
                    sonderen eben der Median, damit extreme Ausreißer nicht so ins Gewicht fallen.
                    (siehe  z.B. Tabelle in A040603)
                -->
                        <xsl:when test="@rend = 'median'">
                            <xsl:for-each select="(1 to count($currNode/tei:row[1]/tei:cell))">
                                <xsl:variable name="counter" as="xs:integer">
                                    <xsl:value-of select="position()"/>
                                </xsl:variable>
                                <xsl:value-of select="wega:computeMedian($currNode/tei:row/tei:cell[$counter]/string-length())"/>
                            </xsl:for-each>
                        </xsl:when>
                        <!-- 
                            Fieser Hack zum Ausrichten der Tabellen in der Bandübersicht
                            Könnnte und sollte man mal generisch machen …
                        -->
                        <xsl:when test="$docID = 'A070011'">
                            <xsl:copy-of select="(1,8,1)"/>
                        </xsl:when>
                        <xsl:otherwise/>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="widths" as="xs:double*">
                    <xsl:for-each select="$define-width-of-cells">
                        <xsl:value-of select="round-half-to-even(100 div (sum($define-width-of-cells) div .), 2)"/>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:apply-templates>
                    <xsl:with-param name="widths" select="$widths" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:element>
        </xsl:element>
    </xsl:template>
    <xsl:template match="tei:row">
        <xsl:element name="tr">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:if test="@rend">
                <!-- The value of the @rend attribute gets passed through as class name(s) -->
                <xsl:attribute name="class" select="@rend"/>
            </xsl:if>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="tei:cell">
        <xsl:param name="widths" as="xs:double*" tunnel="yes"/>
        <xsl:variable name="counter" as="xs:integer" select="position()"/>
        <xsl:choose>
            <xsl:when test="parent::tei:row[@role='label']">
                <xsl:element name="th">
                    <xsl:apply-templates select="@xml:id|@rows|@cols"/>
                    <xsl:apply-templates/>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <xsl:element name="td">
                    <xsl:apply-templates select="@xml:id|@rows|@cols"/>
                    <xsl:if test="exists($widths)">
                        <xsl:attribute name="style">
                            <xsl:value-of select="concat('width:', $widths[$counter], '%')"/>
                        </xsl:attribute>
                    </xsl:if>
                    <xsl:apply-templates/>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tei:floatingText">
        <xsl:choose>
            <xsl:when test="@type='poem'">
                <xsl:element name="div">
                    <xsl:apply-templates select="@xml:id"/>
                    <xsl:attribute name="class" select="'poem'"/>
                    <xsl:apply-templates select="./tei:body/*"/>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tei:lg">
        <xsl:element name="div">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class" select="'lg'"/>
            <xsl:apply-templates/>
            <!--<xsl:for-each select="./tei:l">
                <xsl:apply-templates/>
                <xsl:if test="not(position()=last())">
                    <xsl:element name="br"/>
                </xsl:if>
            </xsl:for-each>-->
        </xsl:element>
    </xsl:template>

    <xsl:template match="tei:l">
        <xsl:element name="span">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class" select="'verseLine'"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="tei:figure" priority="0.5">
        <xsl:variable name="digilibDir" select="wega:getOption('digilibDir')"/>
        <xsl:variable name="figureHeight" select="wega:getOption('figureHeight')"/>
        <xsl:variable name="localURL" select="wega:join-path-elements((replace(wega:getCollectionPath($docID), $data-collection-path, ''), $docID, tei:graphic/@url))"/>
        <xsl:variable name="href" select="concat($digilibDir, $localURL, '&amp;mo=file')"/>
        <xsl:variable name="title" select="normalize-space(tei:figDesc)"/>
        <xsl:choose>
            <!-- External URLs -->
            <xsl:when test="starts-with(tei:graphic/@url, 'http')">
                <xsl:element name="img">
                    <xsl:apply-templates select="@xml:id"/>
                    <xsl:attribute name="alt" select="$title"/>
                    <xsl:attribute name="src" select="data(tei:graphic/@url)"/>
                    <xsl:attribute name="class" select="'teaserImage'"/>
                </xsl:element>
            </xsl:when>
            <!-- Local images -->
            <xsl:otherwise>
                <xsl:variable name="content">
                    <xsl:element name="img">
                        <xsl:apply-templates select="@xml:id"/>
                        <xsl:attribute name="alt" select="$title"/>
                        <xsl:attribute name="height" select="$figureHeight"/>
                        <xsl:attribute name="src" select="concat($digilibDir, $localURL, '&amp;dh=', $figureHeight, '&amp;mo=q2,png')"/>
                        <xsl:attribute name="class" select="'figure'"/>
                    </xsl:element>
                </xsl:variable>
                <xsl:sequence select="wega:createLightboxAnchor($href,$title,'doc',$content)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tei:list">
        <xsl:choose>
            <xsl:when test="@type = 'ordered'">
                <xsl:element name="ol">
                    <xsl:apply-templates select="@xml:id"/>
                    <xsl:attribute name="class" select="'tei_orderedList'"/>
                    <xsl:apply-templates/>
                </xsl:element>
            </xsl:when>
            <xsl:when test="@type = 'simple'">
                <xsl:element name="ul">
                    <xsl:apply-templates select="@xml:id"/>
                    <xsl:attribute name="class" select="'tei_simpleList'"/>
                    <xsl:apply-templates/>
                </xsl:element>
            </xsl:when>
            <xsl:when test="@type = 'gloss'">
                <xsl:element name="dl">
                    <xsl:apply-templates select="@xml:id"/>
                    <xsl:attribute name="class" select="'tei_glossList'"/>
                    <xsl:apply-templates/>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <xsl:element name="ul">
                    <xsl:apply-templates select="@xml:id"/>
                    <xsl:apply-templates/>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tei:item[parent::tei:list/@type='gloss']" priority="2">
        <xsl:element name="dd">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:item[parent::tei:list]">
        <xsl:element name="li">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="tei:label[parent::tei:list/@type='gloss']">
        <xsl:element name="dt">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

    <!-- Überschriften innerhalb einer floatingText-Umgebung -->
    <xsl:template match="tei:head[ancestor::tei:floatingText][not(parent::tei:list)]" priority="0.6">
        <xsl:variable name="minHeadLevel" as="xs:integer" select="2"/>
        <xsl:variable name="increments" as="xs:integer">
            <!-- Wenn es ein Untertitel ist bzw. der Titel einer Linegroup wird der Level hochgezählt -->
            <xsl:value-of select="count(parent::tei:lg | .[@type='sub'])"/>
        </xsl:variable>
        <xsl:element name="{concat('h', $minHeadLevel + $increments)}">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

    <!-- Überschriften innerhalb einer Listen-Umgebung -->
    <xsl:template match="tei:head[parent::tei:list]">
        <xsl:element name="li">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class">
                <xsl:choose>
                    <xsl:when test="@type='sub'">
                        <xsl:value-of select="'listSubTitle'"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="'listTitle'"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <!-- Überschriften innerhalb einer table-Umgebung -->
    <xsl:template match="tei:head[parent::tei:table]">
        <xsl:element name="caption">
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="tei:footNote"/>

    <xsl:template match="tei:g">
        <xsl:variable name="charName" select="substring-after(@ref, 'http://edirom.de/smufl-browser/')" as="xs:string"/>
        <xsl:element name="span">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:choose>
                <xsl:when test="@type='smufl'">
                    <xsl:attribute name="class" select="'musical-symbols'"/>
                    <xsl:variable name="smufl-codepoint" select="key('charDecl', $charName, doc($smufl-decl))/tei:mapping[@type='smufl']"/>
                    <xsl:value-of select="codepoints-to-string(wega:hex2dec(substring-after($smufl-codepoint, 'U+')))"/>
                </xsl:when>
                <xsl:otherwise>
            <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>

    <!--
        Ein <signed> wird standardmäßig rechtsbündig gesetzt und in eine eigene Zeile (display:block)
    -->
    <xsl:template match="tei:signed" priority="0.5">
        <xsl:element name="span">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class" select="string-join(('tei_signed', wega:getTextAlignment(@rend, 'right')), ' ')"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

    <!--
        Ein <seg> mit @rend wird standardmäßig linksbündig gesetzt und in eine eigene Zeile (display:block)
    -->
    <xsl:template match="tei:seg[@rend]" priority="0.5">
        <xsl:element name="span">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class" select="string-join(('tei_segBlock', wega:getTextAlignment(@rend, 'left')), ' ')"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="tei:closer" priority="0.5">
        <xsl:element name="p">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class" select="'tei_closer'"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:q" priority="0.5">
        <!-- Always(!) surround with quotation marks -->
        <xsl:choose>
            <!-- German (double) quotation marks -->
            <xsl:when test="$lang eq 'de'">
                <xsl:text>&#x201E;</xsl:text>
                <xsl:apply-templates/>
                <xsl:text>&#x201C;</xsl:text>
            </xsl:when>
            <!-- English (double) quotation marks as default -->
            <xsl:otherwise>
                <xsl:text>&#x201C;</xsl:text>
                <xsl:apply-templates/>
                <xsl:text>&#x201D;</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="tei:quote" priority="0.5">
        <!-- Surround with quotation marks if @rend is set -->
        <xsl:choose>
            <!-- German double quotation marks -->
            <xsl:when test="$lang eq 'de' and @rend='double-quotes'">
                <xsl:text>&#x201E;</xsl:text>
                <xsl:apply-templates/>
                <xsl:text>&#x201C;</xsl:text>
            </xsl:when>
            <xsl:when test="$lang eq 'en' and @rend='double-quotes'">
                <xsl:text>&#x201C;</xsl:text>
                <xsl:apply-templates/>
                <xsl:text>&#x201D;</xsl:text>
            </xsl:when>
            <!-- German single quotation marks -->
            <xsl:when test="$lang eq 'de' and @rend='single-quotes'">
                <xsl:text>&#x201A;</xsl:text>
                <xsl:apply-templates/>
                <xsl:text>&#x2018;</xsl:text>
            </xsl:when>
            <xsl:when test="$lang eq 'en' and @rend='single-quotes'">
                <xsl:text>&#x2018;</xsl:text>
                <xsl:apply-templates/>
                <xsl:text>&#x2019;</xsl:text>
            </xsl:when>
            <!-- no quotation marks as default -->
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Default template for TEI elements -->
    <!-- will be turned into html:span with class tei_elementName_attributeRendValue -->
    <xsl:template match="tei:*">
        <xsl:element name="span">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class" select="string-join(('tei', local-name(), @rend), '_')"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="@xml:id">
        <xsl:attribute name="id">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>
    
    <xsl:template match="@rows">
        <xsl:attribute name="rowspan">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>
        
    <xsl:template match="@cols">
        <xsl:attribute name="colspan">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>
    
</xsl:stylesheet>