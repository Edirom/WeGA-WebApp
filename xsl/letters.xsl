<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:functx="http://www.functx.com" xmlns:rng="http://relaxng.org/ns/structure/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:wega="http://xquery.weber-gesamtausgabe.de/webapp/functions/utilities" version="2.0">
    <xsl:output encoding="UTF-8" method="html" omit-xml-declaration="yes" indent="no"/>
    <xsl:strip-space elements="*"/>
    <xsl:preserve-space elements="tei:q tei:quote tei:item tei:cell tei:p tei:dateline tei:closer tei:opener tei:hi tei:addrLine tei:persName tei:rs tei:workName tei:characterName tei:placeName tei:seg tei:l tei:head tei:salute tei:date tei:subst tei:add tei:note tei:orgName tei:lem tei:rdg tei:provenance tei:acquisition"/>
    <xsl:include href="common_link.xsl"/>
    <xsl:include href="common_main.xsl"/>
    <xsl:include href="apparatus.xsl"/>

    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
   
    <xsl:template match="tei:body">
        <xsl:element name="div">
            <xsl:attribute name="class" select="'teiLetter_body'"/>
            <xsl:apply-templates/>
            <xsl:if test="//tei:footNote">
                <xsl:call-template name="createEndnotes"/>
            </xsl:if>
        </xsl:element>
        <xsl:call-template name="createApparatus"/>
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
   
    <!--<xsl:template match="tei:rdg"/>
    <xsl:template match="tei:lem">
        <xsl:apply-templates/>
    </xsl:template>-->
   
    <!--<xsl:template match="tei:app">
        <xsl:variable name="appInlineID">
            <xsl:number level="any"/>
        </xsl:variable>
        <xsl:choose>
            <!-\-    tei:rdg[@cause='kein_Absatz'] nicht existent in den Daten. Dieser Zweig kann entfallen.       -\->
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
                    <xsl:text>Lesart(en): </xsl:text>
                    <xsl:for-each select="./tei:rdg">
                        <xsl:value-of select="normalize-space(.)"/>
                        <xsl:if test="position()!=last()">
                            <xsl:text>; </xsl:text>
                        </xsl:if>
                    </xsl:for-each>
                </span>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>-->

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