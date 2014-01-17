<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:wega="http://xquery.weber-gesamtausgabe.de/webapp/functions/utilities" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:rng="http://relaxng.org/ns/structure/1.0" xmlns:functx="http://www.functx.com" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:mei="http://www.music-encoding.org/ns/mei" version="2.0">
    <xsl:output encoding="UTF-8" method="html" omit-xml-declaration="yes" indent="no"/>

    <!--  *********************************************  -->
    <!--  *             Global Variables              *  -->
    <!--  *********************************************  -->
<!--    <xsl:variable name="optionsFile" select="'/db/webapp/xml/wegaOptions.xml'"/>-->
    <xsl:variable name="blockLevelElements" as="xs:string+" select="('item', 'p')"/>
    <xsl:variable name="musical-symbols" as="xs:string" select="'[&#x1d100;-&#x1d1ff;♭-♯]+'"/>
    <xsl:param name="optionsFile"/>
    <xsl:param name="lang"/>
    <xsl:param name="dbPath"/>
    <xsl:param name="docID"/>
    <xsl:param name="transcript"/>
    <xsl:param name="suppressLinks"/><!-- Suppress internal links to persons, works etc. as well as tool tips -->

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
        <xsl:choose>
            <xsl:when test="wega:isPerson($docID)">
                <xsl:value-of select="concat(wega:getOption('persons'), '/', substring($docID, 1, 5), 'xx')"/>
            </xsl:when>
            <xsl:when test="wega:isIconography($docID)">
                <xsl:value-of select="concat(wega:getOption('iconography'), '/', substring($docID, 1, 5), 'xx')"/>
            </xsl:when>
            <xsl:when test="wega:isWork($docID)">
                <xsl:value-of select="concat(wega:getOption('works'), '/', substring($docID, 1, 5), 'xx')"/>
            </xsl:when>
            <xsl:when test="wega:isWriting($docID)">
                <xsl:value-of select="concat(wega:getOption('writings'), '/', substring($docID, 1, 5), 'xx')"/>
            </xsl:when>
            <xsl:when test="wega:isLetter($docID)">
                <xsl:value-of select="concat(wega:getOption('letters'), '/', substring($docID, 1, 5), 'xx')"/>
            </xsl:when>
            <xsl:when test="wega:isNews($docID)">
                <xsl:value-of select="concat(wega:getOption('news'), '/', substring($docID, 1, 5), 'xx')"/>
            </xsl:when>
            <xsl:when test="wega:isDiary($docID)">
                <xsl:value-of select="concat(wega:getOption('diaries'), '/', substring($docID, 1, 5), 'xx')"/>
            </xsl:when>
            <xsl:when test="wega:isVar($docID)">
                <xsl:value-of select="concat(wega:getOption('var'), '/', substring($docID, 1, 5), 'xx')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'unknown'"/>
            </xsl:otherwise>
        </xsl:choose>
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

    <xsl:function name="wega:createLinkToDoc" as="xs:string?">
        <xsl:param name="docID" as="xs:string"/>
        <xsl:param name="lang" as="xs:string"/>
        <xsl:variable name="baseHref" select="wega:getOption('baseHref')"/>
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
                <xsl:value-of select="string-join(($baseHref, $lang, $docID), '/')"/>
            </xsl:when>
            <xsl:when test="exists($folder) and $authorID ne ''">
                <xsl:value-of select="string-join(($baseHref, $lang, $authorID, $folder, $docID), '/')"/>
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

    <xsl:function name="wega:addCurrencySymbolIfNecessary" as="element()?">
        <xsl:param name="node" as="node()"/>
        <!-- Wenn kein Währungssymbol angegeben ist, setzen wir eins hinzu -->
        <xsl:if test="not(matches($node,'[a-zƒ]')) and $node/@quantity &gt; 0">
            <xsl:element name="span">
                <xsl:attribute name="class" select="'tei_supplied'"/>
                <xsl:value-of select="concat(' ', $node/@unit)"/>
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

    <xsl:template name="createSimpleToolTip">
        <xsl:param name="no"/>
        <xsl:choose>
            <xsl:when test="./descendant::*[local-name(.) = $blockLevelElements]"/>
            <xsl:otherwise>
                <xsl:element name="span">
                    <xsl:attribute name="class" select="'teiLetter_noteDefinitionMark'"/>
                    <xsl:attribute name="onmouseout" select="'UnTip()'"/>
                    <xsl:attribute name="onmouseover">
                        <xsl:text>TagToTip('</xsl:text>
                        <xsl:value-of select="concat('note_',$no)"/>
                        <!-- <xsl:apply-templates />-->
                        <xsl:text>')</xsl:text>
                    </xsl:attribute>
                    <xsl:attribute name="id">
                        <xsl:value-of select="concat('noteDefinitionMark_',$no)"/>
                    </xsl:attribute>
                    <xsl:text>*</xsl:text>
                </xsl:element>
                <xsl:element name="span">
                    <xsl:attribute name="class" select="'teiLetter_noteInline'"/>
                    <xsl:attribute name="id">
                        <xsl:value-of select="concat('note_',$no)"/>
                    </xsl:attribute>
                    <xsl:apply-templates/>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="addCurrencySymbolIfNecessary">
        <xsl:param name="node" as="node()"/>
        <!-- Wenn kein Währungssymbol angegeben ist, setzen wir eins hinzu -->
        <xsl:if test="not(matches($node,'[a-zƒ]')) and $node/@quantity &gt; 0">
            <xsl:element name="span">
                <xsl:attribute name="class" select="'tei_supplied'"/>
                <xsl:choose>
                    <xsl:when test="$node/@unit eq 'f'">
                        <xsl:value-of select="' ƒ'"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="concat(' ', $node/@unit)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:element>
        </xsl:if>
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
    <xsl:template match="tei:hi">
        <xsl:element name="span">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class">
                <xsl:choose>
                    <xsl:when test="@rend='latintype'">
                        <xsl:value-of select="'tei_hiLatin'"/>
                    </xsl:when>
                    <xsl:when test="@rend='superscript'">
                        <xsl:value-of select="'tei_hiSuperscript'"/>
                    </xsl:when>
                    <xsl:when test="@rend='subscript'">
                        <xsl:value-of select="'tei_hiSubscript'"/>
                    </xsl:when>
                    <xsl:when test="@rend='italic'">
                        <xsl:value-of select="'tei_hiItalic'"/>
                    </xsl:when>
                    <xsl:when test="@rend='bold'">
                        <xsl:value-of select="'tei_hiBold'"/>
                    </xsl:when>
                    <xsl:when test="@rend='spaced_out'">
                        <xsl:value-of select="'tei_hiSpacedOut'"/>
                    </xsl:when>
                    <xsl:when test="@rend='antiqua'">
                        <xsl:value-of select="'tei_hiAntiqua'"/>
                    </xsl:when>
                    <xsl:when test="@rend='small-caps'">
                        <xsl:value-of select="'tei_hiSmallCaps'"/>
                    </xsl:when>
                    <xsl:when test="@rend='underline'">
                        <xsl:choose>
                            <xsl:when test="@n &gt; 1 or ancestor::tei:hi[@rend='underline']">
                                <xsl:value-of select="'tei_hiUnderline2andMore'"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="'tei_hiUnderline1'"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:if test="wega:getOption('environment') eq 'development'">
                            <xsl:value-of select="'tei_cssUndefined'"/>
                        </xsl:if>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="tei:del[not(parent::tei:subst)]">
        <xsl:element name="span">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class" select="'tei_del'"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="tei:add[not(parent::tei:subst)]">
        <xsl:element name="span">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class">
                <xsl:text>tei_add</xsl:text>
                <xsl:choose>
                    <xsl:when test="@place='above'">
                        <xsl:text> tei_hiSuperscript</xsl:text>
                    </xsl:when>
                    <xsl:when test="@place='below'">
                        <xsl:text> tei_hiSubscript</xsl:text>
                    </xsl:when>
                    <!--<xsl:when test="./tei:add[@place='margin']">
                        <xsl:text>Ersetzung am Rand. </xsl:text>
                    </xsl:when>-->
                    <!--<xsl:when test="./tei:add[@place='mixed']">
                        <xsl:text>Ersetzung an mehreren Stellen. </xsl:text>
                        </xsl:when>-->
                </xsl:choose>
            </xsl:attribute>
            <xsl:apply-templates/>
            <xsl:if test="@place='margin' or @place='inline'">
                <xsl:variable name="addInlineID">
                    <xsl:value-of select="generate-id(.)"/>
                </xsl:variable>
                <xsl:element name="span">
                    <xsl:attribute name="class" select="'teiLetter_noteDefinitionMark'"/>
                    <xsl:attribute name="onmouseout" select="'UnTip()'"/>
                    <xsl:attribute name="onmouseover">
                        <xsl:text>TagToTip('</xsl:text>
                        <xsl:value-of select="concat('subst_',$addInlineID)"/>
                        <xsl:text>')</xsl:text>
                    </xsl:attribute>
                    <xsl:text>*</xsl:text>
                </xsl:element>
                <xsl:element name="span">
                    <xsl:attribute name="class" select="'teiLetter_noteInline'"/>
                    <xsl:attribute name="id">
                        <xsl:value-of select="concat('subst_',$addInlineID)"/>
                    </xsl:attribute>
                    <xsl:choose>
                        <xsl:when test="@place='margin'">
                            <xsl:value-of select="wega:getLanguageString('addMargin', $lang)"/>
                        </xsl:when>
                        <xsl:when test="@place='inline'">
                            <xsl:value-of select="wega:getLanguageString('addInline', $lang)"/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:element>
            </xsl:if>
        </xsl:element>
    </xsl:template>
    <xsl:template match="tei:subst">
        <xsl:variable name="substInlineID">
            <xsl:value-of select="generate-id(.)"/>
        </xsl:variable>
        <xsl:element name="span">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class" select="'tei_subst'"/>
            <xsl:value-of select="./tei:add"/>
            <xsl:element name="span">
                <xsl:attribute name="class" select="'teiLetter_noteDefinitionMark'"/>
                <xsl:attribute name="onmouseout" select="'UnTip()'"/>
                <xsl:attribute name="onmouseover">
                    <xsl:text>TagToTip('</xsl:text>
                    <xsl:value-of select="concat('subst_',$substInlineID)"/>
                    <xsl:text>')</xsl:text>
                </xsl:attribute>
                <xsl:text>*</xsl:text>
            </xsl:element>
            <xsl:element name="span">
                <xsl:attribute name="class" select="'teiLetter_noteInline'"/>
                <xsl:attribute name="id">
                    <xsl:value-of select="concat('subst_',$substInlineID)"/>
                </xsl:attribute>
                <xsl:choose>
                    <xsl:when test="./tei:add[@place='inline']">
                        <xsl:value-of select="wega:getLanguageString('substInline', $lang)"/>
                    </xsl:when>
                    <xsl:when test="./tei:add[@place='above']">
                        <xsl:value-of select="wega:getLanguageString('substAbove', $lang)"/>
                    </xsl:when>
                    <xsl:when test="./tei:add[@place='below']">
                        <xsl:value-of select="wega:getLanguageString('substBelow', $lang)"/>
                    </xsl:when>
                    <xsl:when test="./tei:add[@place='margin']">
                        <xsl:value-of select="wega:getLanguageString('substMargin', $lang)"/>
                    </xsl:when>
                    <xsl:when test="./tei:add[@place='mixed']">
                        <xsl:value-of select="wega:getLanguageString('substMixed', $lang)"/>
                    </xsl:when>
                </xsl:choose>
                <xsl:choose>
                    <xsl:when test="./tei:del/tei:gap">
                        <xsl:value-of select="wega:getLanguageString('delGap', $lang)"/>
                    </xsl:when>
                    <xsl:when test="./tei:del[@rend='strikethrough']">
                        <xsl:value-of select="concat('&#34;', normalize-space(./tei:del[1]), '&#34;')"/>
                        <xsl:value-of select="wega:getLanguageString('delStrikethrough', $lang)"/>
                    </xsl:when>
                    <xsl:when test="./tei:del[@rend='overwritten']">
                        <xsl:value-of select="concat('&#34;', normalize-space(./tei:del[1]), '&#34;')"/>
                        <xsl:value-of select="wega:getLanguageString('delOverwritten', $lang)"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:element>
        </xsl:element>
    </xsl:template>
    <xsl:template match="tei:supplied">
        <xsl:element name="span">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class" select="'tei_supplied'"/>
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

    <xsl:template match="tei:choice">
        <xsl:choose>
            <xsl:when test="./tei:unclear">
                <xsl:apply-templates select="./tei:unclear[1]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tei:corr">
        <xsl:element name="span">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class" select="'tei_supplied'"/>
            <xsl:text> [recte: </xsl:text>
            <xsl:apply-templates/>
            <xsl:text>]</xsl:text>
        </xsl:element>
    </xsl:template>

    <xsl:template match="tei:expan">
        <xsl:element name="span">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class" select="'tei_supplied'"/>
            <xsl:text> [</xsl:text>
            <xsl:apply-templates/>
            <xsl:text>]</xsl:text>
        </xsl:element>
    </xsl:template>

    <xsl:template match="tei:unclear">
        <xsl:element name="span">
            <xsl:attribute name="class" select="'tei_unclear'"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="tei:figure" priority="0.5">
        <xsl:variable name="digilibDir" select="wega:getOption('digilibDir')"/>
        <xsl:variable name="figureHeight" select="wega:getOption('figureHeight')"/>
        <xsl:variable name="href" select="concat($digilibDir, functx:replace-multi($dbPath, ('/db/', '\.xml'), ('','/')), tei:graphic/@url, '&amp;mo=file')"/>
        <xsl:variable name="title" select="tei:figDesc"/>
        <xsl:variable name="content">
            <xsl:element name="img">
                <xsl:apply-templates select="@xml:id"/>
                <xsl:attribute name="alt" select="tei:figDesc"/>
                <xsl:attribute name="height" select="$figureHeight"/>
                <xsl:attribute name="src" select="concat($digilibDir, functx:replace-multi($dbPath, ('/db/', '\.xml'), ('','/')), tei:graphic/@url, '&amp;dh=', $figureHeight, '&amp;mo=q2')"/>
                <xsl:attribute name="class" select="'figure'"/>
            </xsl:element>
        </xsl:variable>
        <xsl:sequence select="wega:createLightboxAnchor($href,$title,'doc',$content)"/>
    </xsl:template>

    <xsl:template match="tei:note" priority="0.5">
        <xsl:choose>
            <xsl:when test="@type='definition' or @type='commentary' or @type='textConst'">
                <xsl:variable name="noteInlineID">
                    <xsl:number level="any"/>
                </xsl:variable>
                <xsl:call-template name="createSimpleToolTip">
                    <xsl:with-param name="no" select="$noteInlineID"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="@type='thematicCom'"/>
            <xsl:otherwise>
                <xsl:apply-templates/>
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
            <xsl:otherwise>
                <xsl:element name="ul">
                    <xsl:apply-templates select="@xml:id"/>
                    <xsl:apply-templates/>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tei:item[parent::tei:list]">
        <xsl:element name="li">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="tei:label">
        <xsl:element name="span">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class" select="'tei_hiBold'"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="tei:label[@n='listLabel']">
        <xsl:element name="span">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class" select="'listLabel'"/>
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

    <xsl:template match="tei:footNote"/>

    <xsl:template match="tei:g">
        <!--<xsl:element name="span">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:choose>
                <xsl:when test="@type='music'">
                    <xsl:attribute name="class" select="'musical-symbols'"/>
                </xsl:when>
            </xsl:choose>
            <xsl:apply-templates/>
        </xsl:element>-->
        <xsl:apply-templates/>
    </xsl:template>

    <!--<xsl:template match="tei:quote">
        <xsl:text>"</xsl:text>
        <xsl:apply-templates/>
        <xsl:text>"</xsl:text>
    </xsl:template>-->
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
    
    <xsl:template match="tei:sic">
        <xsl:element name="span">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class" select="'tei_sic'"/>
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
    
    <!-- Default template fürs Datum damit kein Leerzeichen danach entsteht -->
    <xsl:template match="tei:date" priority="0.5">
        <xsl:element name="span">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class" select="'tei_date'"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

</xsl:stylesheet>