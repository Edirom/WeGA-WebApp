<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:wega="http://xquery.weber-gesamtausgabe.de/webapp/functions/utilities" 
    xmlns:tei="http://www.tei-c.org/ns/1.0" 
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:rng="http://relaxng.org/ns/structure/1.0" 
    xmlns:functx="http://www.functx.com" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:teix="http://www.tei-c.org/ns/Examples" 
    xmlns:mei="http://www.music-encoding.org/ns/mei"
    xmlns:exist="http://exist.sourceforge.net/NS/exist" 
    version="2.0">
    
    <xsl:output encoding="UTF-8" method="html" omit-xml-declaration="yes" indent="no"/>

    <!--  *********************************************  -->
    <!--  *             Global Variables              *  -->
    <!--  *********************************************  -->
<!--    <xsl:variable name="optionsFile" select="'/db/webapp/xml/wegaOptions.xml'"/>-->
    <xsl:variable name="blockLevelElements" as="xs:string+" select="('p', 'list', 'table')"/>
    <xsl:variable name="musical-symbols" as="xs:string" select="'[&#x1d100;-&#x1d1ff;♭-♯]+'"/>
    <xsl:variable name="fa-exclamation-circle" as="xs:string" select="'&#xf06a;'"/>
    <xsl:param name="optionsFile"/>
    <xsl:param name="baseHref"/>
    <xsl:param name="lang"/>
    <xsl:param name="dbPath"/>
    <xsl:param name="docID"/>
    <xsl:param name="transcript"/>
    <xsl:param name="smufl-decl"/>
    <xsl:param name="data-collection-path"/>
    <xsl:param name="catalogues-collection-path"/>
    <xsl:param name="environment"/>
    
    <xsl:include href="common_funcs.xsl"/>
    
    <xsl:key name="charDecl" match="tei:char" use="@xml:id"/>


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
        <xsl:param name="marker" as="xs:string?"/>
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
        <xsl:element name="a">
            <xsl:attribute name="class" select="string-join(('noteMarker', $marker), ' ')"/>
            <xsl:attribute name="id" select="concat('ref-', $id)"/>
            <xsl:attribute name="data-toggle">popover</xsl:attribute>
            <xsl:attribute name="data-trigger">focus</xsl:attribute>
            <xsl:attribute name="tabindex">0</xsl:attribute>
            <xsl:attribute name="data-ref" select="concat('#', $id)"/>
            <xsl:choose>
                <xsl:when test="$marker eq 'arabic'">
                    <xsl:value-of select="count(preceding::tei:note[@type=('commentary','definition','textConst')]) + 1"/>
                </xsl:when>
                <xsl:when test="not($marker) and self::tei:note[not(@type='textConst')]">
                    <xsl:text>*</xsl:text>
                </xsl:when>
                <xsl:when test="not($marker) and self::tei:app">
                    <xsl:text>Δ</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>‡</xsl:text> <!-- to be changed in apparatus.xsl too if necessary -->
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>

    <xsl:template name="createEndnotes">
        <xsl:element name="div">
            <xsl:attribute name="id" select="'endNotes'"/>
            <xsl:element name="h3"><xsl:value-of select="wega:getLanguageString('originalFootnotes', $lang)"/></xsl:element>
            <xsl:element name="ul">
                <xsl:for-each select="//tei:footNote">
                    <xsl:element name="li">
                        <xsl:attribute name="id" select="@xml:id"/>
                        <xsl:element name="a">
                            <xsl:attribute name="href" select="concat('#backref-', @xml:id)"/>
                            <xsl:attribute name="class">fn-backref</xsl:attribute>
                            <xsl:element name="i">
                                <xsl:attribute name="class">fa fa-arrow-up</xsl:attribute>
                                <xsl:attribute name="aria-hidden">true</xsl:attribute>
                            </xsl:element>
                        </xsl:element>
                        <xsl:apply-templates/>
                    </xsl:element>
                </xsl:for-each>
            </xsl:element>
        </xsl:element>
    </xsl:template>
    
    <xsl:template name="remove-by-class">
        <xsl:param name="nodes" as="node()*"/>
        <xsl:for-each select="$nodes">
            <xsl:choose>
                <xsl:when test="self::document-node()">
                    <xsl:call-template name="remove-by-class">
                        <xsl:with-param name="nodes" select="current()/node()"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:when test="self::comment()">
                    <xsl:copy-of select="."/>
                </xsl:when>
                <xsl:when test="self::processing-instruction()">
                    <xsl:copy-of select="."/>
                </xsl:when>
                <xsl:when test="self::text()">
                    <xsl:copy-of select="."/>
                </xsl:when>
                <xsl:when test="self::xhtml:a[@class='noteMarker']"/>
                <xsl:otherwise>
                    <xsl:copy>
                        <xsl:copy-of select="@*"/>
                        <xsl:call-template name="remove-by-class">
                            <xsl:with-param name="nodes" select="current()/node()"/>
                        </xsl:call-template>
                    </xsl:copy>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="enquote">
        <xsl:param name="double" select="true()"/>
        <xsl:param name="ellipsis" select="false()"/>
        <xsl:param name="lang" select="$lang"/>
        <xsl:choose>
            <!-- German double quotation marks -->
            <xsl:when test="$lang eq 'de' and $double">
                <xsl:text>„</xsl:text>
                <xsl:apply-templates mode="#current"/>
                <xsl:if test="$ellipsis">
                    <xsl:text>…</xsl:text>
                </xsl:if>
                <xsl:text>“</xsl:text>
            </xsl:when>
            <xsl:when test="$lang eq 'en' and $double">
                <xsl:text>“</xsl:text>
                <xsl:apply-templates mode="#current"/>
                <xsl:if test="$ellipsis">
                    <xsl:text>…</xsl:text>
                </xsl:if>
                <xsl:text>”</xsl:text>
            </xsl:when>
            <!-- German single quotation marks -->
            <xsl:when test="$lang eq 'de' and not($double)">
                <xsl:text>‚</xsl:text>
                <xsl:apply-templates mode="#current"/>
                <xsl:text>‘</xsl:text>
            </xsl:when>
            <xsl:when test="$lang eq 'en' and not($double)">
                <xsl:text>‘</xsl:text>
                <xsl:apply-templates mode="#current"/>
                <xsl:text>’</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>"</xsl:text>
                <xsl:apply-templates mode="#current"/>
                <xsl:text>"</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!--  *********************************************  -->
    <!--  *                  Templates                *  -->
    <!--  *********************************************  -->
    <xsl:template match="tei:reg"/>

    <xsl:template match="tei:lb" priority="0.5">
        <xsl:if test="@type='inWord' or @break='no'">
            <xsl:element name="span">
                <xsl:attribute name="class" select="'break_inWord'"/>
                <xsl:text>-</xsl:text>
            </xsl:element>
        </xsl:if>
        <xsl:element name="br"/>
    </xsl:template>
    
    <xsl:template match="tei:ptr[starts-with(@target, 'http')]">
        <xsl:element name="a">
            <xsl:attribute name="href" select="@target"/>
            <xsl:value-of select="@target"/>
        </xsl:element>
    </xsl:template>

    <!-- 
        tei:seg und tei:signed mit @rend werden schon als block-level-Elemente gesetzt, 
        brauchen daher keinen Zeilenumbruch mehr 
    -->
    <xsl:template match="tei:lb[(following-sibling::text()[not(functx:all-whitespace(.))] | following-sibling::*)[1] = following-sibling::tei:seg[@rend]]" priority="0.6"/>
    <xsl:template match="tei:lb[(following-sibling::text()[not(functx:all-whitespace(.))] | following-sibling::*)[1] = following-sibling::tei:signed[@rend]]" priority="0.6"/>

    <xsl:template match="text()" mode="#all">
        <xsl:variable name="regex" select="string-join((&#34;'&#34;, $musical-symbols, $fa-exclamation-circle), '|')"/>
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
                <xsl:if test="matches(.,  $fa-exclamation-circle)">
                    <xsl:element name="i">
                        <xsl:attribute name="class" select="'fa fa-exclamation-circle'"/>
                        <xsl:attribute name="aria-hidden" select="'true'"/>
                    </xsl:element>
                </xsl:if>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:value-of select="."/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:template>

    <xsl:template match="tei:hi[@rend='underline']" mode="#all">
        <xsl:element name="span">
            <xsl:apply-templates select="@xml:id" mode="#current"/>
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
            <xsl:apply-templates mode="#current"/>
        </xsl:element>
    </xsl:template>
    
    <!--  Hier mit priority 0.5, da in Briefen und Tagebüchern unterschiedlich behandelt  -->
    <xsl:template match="tei:pb | tei:cb" priority="0.5">
        <xsl:variable name="division-sign" as="xs:string">
            <xsl:choose>
                <xsl:when test="self::tei:pb">
                    <xsl:value-of select="' | '"/> <!-- senkrechter Strich („|“) aka pipe -->
                </xsl:when>
                <xsl:when test="self::tei:cb">
                    <xsl:value-of select="' ¦ '"/> <!-- in der Mitte unterbrochener („¦“) senkrechter Strich -->
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <!-- breaks are not allowed within lists as they are in TEI. We need to workaround this … -->
        <xsl:element name="{if(parent::tei:list) then 'li' else 'span'}">
            <xsl:attribute name="class">
                <xsl:text>tei_</xsl:text>
                <xsl:value-of select="local-name()"/>
                <!-- breaks between block level elements -->
                <xsl:if test="parent::tei:div or parent::tei:body">
                    <xsl:text>_block</xsl:text>
                </xsl:if>
            </xsl:attribute>
            <xsl:attribute name="title">
                <xsl:choose>
                    <xsl:when test="@n">
                        <xsl:choose>
                            <xsl:when test="self::tei:pb">
                                <xsl:choose>
                                    <xsl:when test="$docID eq 'A100000'">
                                        <!-- Special treatment for the Notizenbuch where we decided to label the pages as numbers, sigh … -->
                                        <xsl:value-of select="concat(wega:getLanguageString('pageBreakTo', $lang), ' Nr.&#160;', @n)"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="concat(wega:getLanguageString('pageBreakTo', $lang), ' ', wega:getLanguageString('pp', $lang), '&#160;', @n)"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:when>
                            <xsl:when test="self::tei:cb">
                                <xsl:value-of select="concat(wega:getLanguageString('columnBreakTo', $lang), ' ', wega:getLanguageString('col', $lang), '&#160;', @n)"/>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:choose>
                            <xsl:when test="self::tei:pb">
                                <xsl:value-of select="wega:getLanguageString('pageBreak', $lang)"/>
                            </xsl:when>
                            <xsl:when test="self::tei:cb">
                                <xsl:value-of select="wega:getLanguageString('columnBreak', $lang)"/>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <xsl:if test="@facs">
                <xsl:attribute name="data-facs" select="substring(@facs, 2)"/>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="@type='inWord' or @break='no'">
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
        <xsl:element name="div">
            <xsl:attribute name="class">table-wrapper</xsl:attribute>
            <xsl:if test="@rend='collapsible'">
                <xsl:apply-templates select="tei:head"/>
            </xsl:if>
            <xsl:element name="table">
                <xsl:choose>
                    <xsl:when test="@xml:id">
                        <xsl:apply-templates select="@xml:id"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:attribute name="id" select="generate-id()"/>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:attribute name="class">
                    <xsl:text>table</xsl:text>
                    <xsl:if test="@rend='collapsible'">
                        <xsl:text> collapse</xsl:text>
                    </xsl:if>
                </xsl:attribute>
                <xsl:if test="not(@rend='collapsible')">
                    <xsl:apply-templates select="tei:head"/>
                </xsl:if>
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
                                <xsl:choose>
                                    <xsl:when test="count($currNode/tei:row[1]/tei:cell) = 3">
                                        <xsl:sequence select="(1,8,1)"/>
                                    </xsl:when>
                                    <xsl:when test="count($currNode/tei:row[1]/tei:cell) = 4">
                                        <xsl:sequence select="(1,7.5,1,.5)"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:message>XSLT Warning: unsupported ammount of table cells <xsl:value-of select="$docID"/></xsl:message>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:when>
                            <!-- Noch ein hack für die Spielpläne -->
                            <xsl:when test="$docID = ('A090102', 'A090134', 'A090206', 'A090068') and descendant::tei:table">
                                <xsl:copy-of select="(.6, .6, 8.8)"/>
                            </xsl:when>
                            <xsl:when test="$docID = ('A090102', 'A090134', 'A090206', 'A090068') and ancestor::tei:table">
                                <xsl:copy-of select="(2, 8)"/>
                            </xsl:when>
                            <xsl:otherwise/>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:variable name="widths" as="xs:double*">
                        <xsl:for-each select="$define-width-of-cells">
                            <xsl:value-of select="round-half-to-even(100 div (sum($define-width-of-cells) div .), 2)"/>
                        </xsl:for-each>
                    </xsl:variable>
                    <xsl:apply-templates select="tei:row">
                        <xsl:with-param name="widths" select="$widths" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:element>
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
        <xsl:variable name="counter" as="xs:integer" select="count(preceding-sibling::tei:cell) + 1"/>
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
        <xsl:element name="span">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class" select="'lg'"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="tei:l">
        <xsl:element name="span">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class" select="'verseLine'"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="tei:notatedMusic | tei:figure">
        <xsl:element name="span">
            <xsl:attribute name="class" select="string-join((concat('tei_', local-name()), @rend), ' ')"/>
            <xsl:choose>
                <xsl:when test="tei:graphic">
                    <xsl:apply-templates select="tei:graphic"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>[</xsl:text>
                    <xsl:value-of select="wega:getLanguageString(local-name(), $lang)"/>
                    <xsl:text>: </xsl:text>
                    <xsl:apply-templates select="tei:desc | tei:figDesc"/>
                    <xsl:text>]</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:graphic">
        <xsl:variable name="figureSize">
            <!-- There's more to do here: different images for different screen sizes and resolutions, etc. -->
            <xsl:choose>
                <xsl:when test="parent::tei:*/@rend='maxSize'">
                    <xsl:value-of select="'600,'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat(',',wega:getOption('figureHeight'))"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="localURL">
            <xsl:value-of select="concat(wega:getOption('iiifImageApi'), encode-for-uri(wega:join-path-elements((replace(concat(wega:getCollectionPath($docID), '/'), $data-collection-path, ''), $docID, @url))))"/>
        </xsl:variable>
        <xsl:variable name="title">
            <!-- desc within notatedMusic and figDesc within figures -->
            <xsl:apply-templates select="parent::*/tei:desc | parent::*/tei:figDesc"/>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="starts-with(@url, 'http')">
                <xsl:element name="img">
                    <xsl:attribute name="title" select="$title"/>
                    <xsl:attribute name="alt" select="$title"/>
                    <xsl:attribute name="src" select="@url"/>
                </xsl:element>
            </xsl:when>
            <xsl:when test="starts-with(@url, 'wega:')">
                <xsl:element name="img">
                    <xsl:attribute name="title" select="$title"/>
                    <xsl:attribute name="alt" select="$title"/>
                    <xsl:attribute name="src" select="replace(@url, 'wega:', wega:getOption('iiifImageApi'))"/>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <xsl:element name="a">
                    <xsl:attribute name="href" select="concat($localURL, '/full/full/0/native.jpg')"/>
                    <xsl:element name="img">
                        <!--<xsl:attribute name="title" select="$title"/>-->
                        <xsl:attribute name="alt" select="$title"/>
                        <xsl:attribute name="src" select="concat($localURL, '/full/', $figureSize, '/0/native.jpg')"/>
                    </xsl:element>
                </xsl:element>
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
                    <xsl:attribute name="class" select="'tei_list'"/>
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
    <xsl:template match="tei:head[parent::tei:body][ancestor::tei:floatingText]" priority="0.6">
        <xsl:variable name="minHeadLevel" as="xs:integer" select="2"/>
        <xsl:variable name="increments" as="xs:integer">
            <!-- Wenn es ein Untertitel ist bzw. der Titel einer Linegroup wird der Level hochgezählt -->
            <xsl:value-of select="count(.[@type='sub'])"/>
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
        <xsl:choose>
            <xsl:when test="parent::tei:table[@rend='collapsible']">
                <xsl:element name="h4">
                    <xsl:attribute name="data-target" select="concat('#', generate-id(parent::tei:table))"/>
                    <xsl:attribute name="data-toggle">collapse</xsl:attribute>
                    <xsl:attribute name="class">collapseMarker collapsed</xsl:attribute>
                    <xsl:apply-templates/>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <xsl:element name="caption">
                    <xsl:apply-templates/>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
    <!-- Überschriften innerhalb einer lg-Umgebung -->
    <xsl:template match="tei:head[parent::tei:lg]">
        <xsl:variable name="minHeadLevel" as="xs:integer" select="2"/>
        <xsl:variable name="increments" as="xs:integer">
            <!-- Verschachtelungstiefe hochgezählt -->
            <xsl:value-of select="count(ancestor::tei:lg)"/>
        </xsl:variable>
        <xsl:element name="span">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class" select="concat('heading', $minHeadLevel + $increments)"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="tei:footNote"/>

    <xsl:template match="tei:g">
        <xsl:variable name="smuflCodepoint" as="xs:string">
            <xsl:variable name="charName" select="concat('_', functx:substring-before-if-contains(functx:substring-after-last(@ref, '/'), '.'))"/>
            <xsl:value-of select="key('charDecl', $charName, wega:doc($smufl-decl))/tei:mapping[@type='smufl']"/>
        </xsl:variable>
        <xsl:element name="span">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:choose>
                <xsl:when test="$smuflCodepoint">
                    <xsl:attribute name="class" select="'musical-symbols'"/>
                    <xsl:value-of select="codepoints-to-string(wega:hex2dec(substring-after($smuflCodepoint, 'U+')))"/>
                </xsl:when>
                <xsl:when test="@type='mufi'">
                    <xsl:attribute name="class" select="'mufi-symbols'"/>
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>XSLT Warning: template for `tei:g` failed to recognize glyph in document <xsl:value-of select="$docID"/></xsl:message>
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
    
    <xsl:template match="tei:dateline" priority="0.5">
        <xsl:variable name="default-textAlignment">
            <!-- datelines werden im closer standardmäßig linksbündig gesetzt, ansonsten rechtsbündig. Immer in eine eigene Zeile (display:block)-->
            <xsl:choose>
                <xsl:when test="ancestor::tei:closer[not(@rend)]">left</xsl:when>
                <xsl:when test="ancestor::tei:closer[@rend]">
                    <xsl:value-of select="wega:getTextAlignment(ancestor::tei:closer/@rend, 'left')"/>
                </xsl:when>
                <xsl:otherwise>right</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:element name="span">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class" select="string-join(('tei_dateline', wega:getTextAlignment(@rend, $default-textAlignment)), ' ')"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="tei:closer" priority="0.5">
        <xsl:element name="{if (parent::tei:lg) then 'span' else 'p'}">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class" select="string-join(('tei_closer', wega:getTextAlignment(@rend, 'left'), if(@rend='inline') then 'inlineStart' else ()), ' ')"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:q|tei:quote|mei:q" priority="0.5" mode="#all">
        <xsl:choose>
            <!-- Surround with quotation marks if current node is `<q>`, or `@rend` is set on `<quote>` -->
            <xsl:when test="@rend or self::tei:q or self::mei:q">
                <xsl:variable name="doubleQuotes" select="
                    (
                    (count(ancestor::tei:q | ancestor::mei:q | ancestor::tei:quote[@rend]) mod 2) = 0
                        or @rend='double-quotes'
                    )
                    and not(@rend='single-quotes')
                    "/>
                <xsl:call-template name="enquote">
                    <xsl:with-param name="double" select="$doubleQuotes"/>
                    <xsl:with-param name="lang">
                        <!-- for quotes occuring in the text body try to use the 
                            proper quotation marks corresponding to the language of the text 
                        -->
                        <xsl:variable name="docLang" select="wega:get-doc-languages($docID)[1]"/>
                        <xsl:choose>
                            <xsl:when test="ancestor::tei:body and $docLang = ('de', 'en')">
                                <xsl:value-of select="$docLang"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$lang"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:with-param>
                </xsl:call-template>
            </xsl:when>
            <!-- no quotation marks as default for `<quote>` -->
            <xsl:otherwise>
                <xsl:apply-templates mode="#current"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="tei:soCalled" mode="#all">
        <xsl:call-template name="enquote">
            <xsl:with-param name="double" select="false()"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="tei:postscript">
        <xsl:element name="div">
            <xsl:attribute name="class">tei_postscript</xsl:attribute>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:note[@type='thematicCom']">
        <xsl:variable name="targets" select="tokenize(@target, '\s+')" as="xs:string*"/>
        <xsl:element name="{if(count($targets) eq 1) then 'a' else 'span'}">
            <xsl:attribute name="class" select="'noteMarker'"/>
            <xsl:choose>
                <xsl:when test="count($targets) eq 1">
                    <xsl:attribute name="href" select="wega:createLinkToDoc(substring-after(tokenize(@target, '\s+'), 'wega:'), $lang)"/>
                </xsl:when>
                <xsl:when test="count($targets) gt 1">
                    <xsl:attribute name="data-ref">
                        <xsl:value-of select="for $t in $targets return wega:createLinkToDoc(substring-after($t, 'wega:'), $lang)"/>
                    </xsl:attribute>
                </xsl:when>
            </xsl:choose>
            <xsl:text>T</xsl:text>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:p">
        <xsl:variable name="inlineEnd" as="xs:string?">
            <xsl:if test="following-sibling::node()[1][self::tei:closer[@rend='inline']]">
                <xsl:text>inlineEnd</xsl:text>
            </xsl:if>
        </xsl:variable>
        <xsl:for-each-group select="node()" group-ending-with="tei:list|tei:specList|teix:egXML|tei:eg">
            <xsl:if test="current-group()[not(self::tei:list or self::tei:specList or self::teix:egXML or self::tei:table or self::tei:floatingText or self::tei:eg)][matches(., '\S')] or current-group()[not(self::tei:list or self::tei:specList or self::teix:egXML or self::tei:table or self::tei:floatingText or self::tei:eg)][self::element()]">
                <xsl:element name="p">
                    <xsl:if test="position() eq 1">
                        <xsl:apply-templates select="parent::tei:p/@xml:id"/>
                    </xsl:if>
                    <xsl:if test="$inlineEnd">
                        <xsl:attribute name="class" select="$inlineEnd"/>
                    </xsl:if>
                    <xsl:apply-templates select="current-group()[not(self::tei:list or self::tei:specList or self::teix:egXML or self::tei:table or self::tei:floatingText or self::tei:eg)]"/>
                </xsl:element>
            </xsl:if>
            <xsl:apply-templates select="current-group()[self::tei:list or self::tei:specList or self::teix:egXML or self::tei:table or self::tei:floatingText or self::tei:eg]"/>
        </xsl:for-each-group>
    </xsl:template>

    <!-- Default template for TEI elements -->
    <!-- will be turned into html:span with class tei_elementName_attributeRendValue -->
    <xsl:template match="tei:*" mode="#all">
        <xsl:element name="span">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class" select="string-join(('tei', local-name(), @rend), '_')"/>
            <xsl:apply-templates mode="#current"/>
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
    
    <!--  *********************************************  -->
    <!--  * Templates for highlighting search resutls *  -->
    <!--  *********************************************  -->
    
    <xsl:template match="exist:match">
        <xsl:element name="span">
            <xsl:attribute name="class">hi</xsl:attribute>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
</xsl:stylesheet>
