<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:wega="http://xquery.weber-gesamtausgabe.de/webapp/functions/utilities"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:functx="http://www.functx.com"
    xmlns:rng="http://relaxng.org/ns/structure/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    version="2.0">
    <xsl:output encoding="UTF-8" method="html" omit-xml-declaration="yes" indent="no"/>
    <xsl:strip-space elements="*"/>
    <xsl:preserve-space
        elements="tei:item tei:cell tei:p tei:dateline tei:closer tei:opener tei:hi tei:addrLine tei:persName tei:rs tei:workName tei:characterName tei:placeName tei:seg tei:l tei:head tei:salute tei:date"/>
    <xsl:include href="common_link.xsl"/>
    <xsl:include href="common_main.xsl"/>

    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="tei:body">
        <xsl:element name="div">
            <xsl:attribute name="id" select="'teiLetter_body'"/>
            <xsl:apply-templates select="./tei:div"/>
            <xsl:if test="//tei:footNote">
                <xsl:call-template name="createEndnotes"/>
            </xsl:if>
        </xsl:element>
    </xsl:template>
    <xsl:template match="tei:div">
        <xsl:element name="div">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:choose>
                <xsl:when test="@type='address'">
                    <xsl:attribute name="class" select="'teiLetter_address'"/>
                    <xsl:for-each select=".//tei:addrLine">
                        <xsl:element name="p">
                            <xsl:apply-templates/>
                        </xsl:element>
                    </xsl:for-each>
                </xsl:when>
                <xsl:when test="@type='writingSession'">
                    <xsl:attribute name="class" select="'writingSession'"/>
                    <!--<xsl:if test="following-sibling::tei:div[1][@rend='inline'] or ./@rend='inline'">
                    <xsl:attribute name="style" select="'display:inline'"/>
                </xsl:if>-->
                    <xsl:apply-templates/>
                    <xsl:if test="not(following-sibling::tei:div)">
                        <xsl:element name="p">
                            <xsl:attribute name="class" select="'clearer'"/>
                        </xsl:element>
                    </xsl:if>
                </xsl:when>
                <!--     Debugging Option       -->
                <xsl:otherwise>
                    <xsl:if test="wega:getOption('environment') eq 'development'">
                        <xsl:attribute name="class">
                            <xsl:value-of select="'tei_cssUndefined'"/>
                        </xsl:attribute>
                    </xsl:if>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>
    <xsl:template match="tei:p">
        <xsl:element name="p">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class">
                <xsl:choose>
                    <xsl:when test="following-sibling::node()[1][name() = 'closer'][@rend='inline']">
                        <xsl:text>inlineParagraph</xsl:text>
                    </xsl:when>
                    <!--<xsl:when test="following-sibling::node()[name() = 'closer' or name() = 'p'][1][@rend='inline'] or ./@rend='inline' or (. = ../tei:p[position()=last() and ])">
                        <xsl:text>inlineParagraph</xsl:text>
                        <xsl:if test="not(./@rend='inline') and not(. = ../tei:p[position()=1])">
                            <xsl:text> indented</xsl:text>
                        </xsl:if>
                    </xsl:when>-->
                    <xsl:otherwise>
                        <xsl:text>blockParagraph</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:choose>
                    <xsl:when test="not(@n='1' or . = ../tei:p[position()=1])">
                        <xsl:text> indented</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text> noIndent</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="parent::node()/name() = 'postscript'">
                    <xsl:text> teiLetter_postscript</xsl:text>
                </xsl:if>
            </xsl:attribute>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

    <!--  Soll das docDate angezeigt werden??  -->
    <xsl:template match="tei:docDate">
        <!--<div class="teiLetter_docDate">
            <xsl:apply-templates />
        </div>-->
    </xsl:template>
    <xsl:template match="tei:opener">
        <xsl:element name="div">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class">
                <xsl:value-of select="'teiLetter_opener'"/>
            </xsl:attribute>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="tei:head[parent::tei:div[@type='writingSession']]" priority="1">
        <xsl:element name="h2">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="tei:note[@type='summary']" priority="1">
        <xsl:element name="div">
            <xsl:attribute name="id" select="'summary'"/>
            <xsl:if test="normalize-space(.) != ''">
                <xsl:element name="h3">
                    <xsl:value-of select="wega:getLanguageString('summary', $lang)"/>
                </xsl:element>
                <xsl:choose>
                    <xsl:when test="./tei:p">
                        <xsl:apply-templates/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:element name="p">
                            <xsl:apply-templates/>
                        </xsl:element>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
        </xsl:element>
    </xsl:template>

    <xsl:template match="//tei:opener//tei:dateline">
        <xsl:element name="p">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class">
                <xsl:choose>
                    <xsl:when test="@rend='left'">
                        <xsl:text>teiLetter_datelineOpenerBlockLeft</xsl:text>
                    </xsl:when>
                    <xsl:when test="@rend='inline'">
                        <xsl:text>teiLetter_datelineOpenerInline</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>teiLetter_datelineOpenerBlockRight</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="tei:closer" priority="1">
        <xsl:element name="p">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class">
                <xsl:text>teiLetter_closer</xsl:text>
                <xsl:choose>
                    <xsl:when test="@rend='inline'">
                        <xsl:text> inlineParagraph</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text> blockParagraph indented</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <xsl:if test="@rend='right'">
                <xsl:attribute name="style" select="'text-align: right;'"/>
            </xsl:if>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="tei:closer//tei:dateline">
        <xsl:element name="span">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class">teiLetter_datelineCloser</xsl:attribute>
            <xsl:if test="@rend='right'">
                <xsl:attribute name="style" select="'text-align: right;'"/>
            </xsl:if>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="tei:salute">
        <xsl:choose>
            <xsl:when test="parent::node()/name() = 'opener'">
                <xsl:element name="p">
                    <xsl:apply-templates select="@xml:id"/>
                    <xsl:attribute name="class">teiLetter_salute</xsl:attribute>
                    <xsl:choose>
                        <xsl:when test="@rend='inline'">
                            <xsl:attribute name="style">display:inline;</xsl:attribute>
                        </xsl:when>
                        <xsl:when test="@rend='right'">
                            <xsl:attribute name="style">text-align:right;</xsl:attribute>
                        </xsl:when>
                        <xsl:when test="@rend='left'">
                            <xsl:attribute name="style">text-align:left;</xsl:attribute>
                        </xsl:when>
                        <!--<xsl:otherwise>
                            <p class="teiLetter_undefined">
                            <xsl:apply-templates />
                            </p>
                            </xsl:otherwise>-->
                    </xsl:choose>
                    <xsl:apply-templates/>
                </xsl:element>
            </xsl:when>
            <xsl:when test="parent::node()/name() = 'closer'">
                <xsl:apply-templates/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tei:rdg"/>
    <xsl:template match="tei:lem">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="tei:app">
        <xsl:variable name="appInlineID">
            <xsl:number level="any"/>
        </xsl:variable>
        <xsl:choose>
            <!--    tei:rdg[@cause='kein_Absatz'] nicht existent in den Daten. Dieser Zweig kann entfallen.       -->
            <xsl:when test="./tei:rdg[@cause='kein_Absatz']">
                <span class="teiLetter_noteDefinitionMark" onmouseout="UnTip()">
                    <xsl:attribute name="onmouseover">
                        <xsl:text>TagToTip('</xsl:text>
                        <xsl:value-of select="concat('app_',$appInlineID)"/>
                        <xsl:text>')</xsl:text>
                    </xsl:attribute>
                    <xsl:text>*</xsl:text>
                </span>
                <span class="teiLetter_noteInline">
                    <xsl:attribute name="id">
                        <xsl:value-of select="concat('app_',$appInlineID)"/>
                    </xsl:attribute>
                    <xsl:text>Lesart ohne Absatz</xsl:text>
                </span>
            </xsl:when>
            <xsl:otherwise>
                <span class="teiLetter_lem" onmouseout="UnTip()">
                    <xsl:attribute name="onmouseover">
                        <xsl:text>TagToTip('</xsl:text>
                        <xsl:value-of select="concat('app_',$appInlineID)"/>
                        <xsl:text>')</xsl:text>
                    </xsl:attribute>
                    <xsl:apply-templates select="./tei:lem"/>
                </span>
                <span class="teiLetter_noteInline">
                    <xsl:attribute name="id">
                        <xsl:value-of select="concat('app_',$appInlineID)"/>
                    </xsl:attribute>
                    <xsl:text>Lesart(en):&#160;</xsl:text>
                    <xsl:for-each select="./tei:rdg">
                        <xsl:value-of select="normalize-space(.)"/>
                        <xsl:if test="position()!=last()">
                            <xsl:text>;&#160;</xsl:text>
                        </xsl:if>
                    </xsl:for-each>
                </span>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!--<xsl:template match="tei:subst">
        <xsl:apply-templates/>
        <!-\-<xsl:choose>
            <xsl:when test="@rend='overwritten'">
                <span class="teiLetter_delOverwritten">
                    <xsl:value-of select="normalize-space(tei:del)"/>
                </span>
                <xsl:value-of select="normalize-space(tei:add)"/>
            </xsl:when>
            <xsl:otherwise>
                <p class="teiLetter_undefined">
                    <xsl:apply-templates/>
                </p>
            </xsl:otherwise>
        </xsl:choose>-\->
    </xsl:template>-->
    <xsl:template match="tei:cit">
        <xsl:apply-templates select="./tei:quote"/>
        <xsl:variable name="citInlineID">
            <xsl:number level="any"/>
        </xsl:variable>
        <span class="teiLetter_noteDefinitionMark" onmouseout="UnTip()">
            <xsl:attribute name="onmouseover">
                <xsl:text>TagToTip('</xsl:text>
                <xsl:value-of select="concat('cit_',$citInlineID)"/>
                <xsl:text>')</xsl:text>
            </xsl:attribute>
            <xsl:text>*</xsl:text>
        </span>
        <span class="teiLetter_noteInline">
            <xsl:attribute name="id">
                <xsl:value-of select="concat('cit_',$citInlineID)"/>
            </xsl:attribute>
            <xsl:apply-templates select="./tei:bibl"/>
        </span>
    </xsl:template>
    <xsl:template match="tei:quote">
        <xsl:text>"</xsl:text>
        <xsl:apply-templates/>
        <xsl:text>"</xsl:text>
    </xsl:template>
    <xsl:template match="tei:bibl">
        <!--        <p class="teiLetter_bibl">-->
        <xsl:if test="./tei:author">
            <xsl:value-of select="normalize-space(./tei:author)"/>
            <xsl:text>,&#160;</xsl:text>
            <span class="teiLetter_hiItalics">
                <xsl:value-of select="normalize-space(./tei:name)"/>
            </span>
        </xsl:if>
        <xsl:if test="./tei:rs">
            <xsl:apply-templates/>
        </xsl:if>
        <!--        </p>-->
    </xsl:template>
    <xsl:template match="tei:incipit">
        <xsl:element name="div">
            <xsl:attribute name="id" select="'incipit'"/>
            <xsl:if test="normalize-space(.) != ''">
                <xsl:element name="h3">
                    <xsl:value-of select="wega:getLanguageString('incipit', $lang)"/>
                </xsl:element>
                <xsl:choose>
                    <xsl:when test="./tei:p">
                        <xsl:apply-templates/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:element name="p">
                            <xsl:text>"</xsl:text>
                            <xsl:apply-templates/>
                            <xsl:text> …"</xsl:text>
                        </xsl:element>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
        </xsl:element>
    </xsl:template>
    <!--<xsl:template match="tei:title[@level='a']">
        <xsl:apply-templates/>
    </xsl:template>-->
    <xsl:template match="text()[parent::tei:title]">
        <xsl:choose>
            <xsl:when test="$lang eq 'en'">
                <xsl:value-of
                    select="functx:replace-multi(., (' in ', ' an '), (lower-case(wega:getLanguageString('in', $lang)), lower-case(wega:getLanguageString('to', $lang))))"
                />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
