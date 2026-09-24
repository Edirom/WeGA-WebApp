<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:wega="http://xquery.weber-gesamtausgabe.de/webapp/functions/utilities"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="tei wega xs"
    version="2.0">

    <xsl:output encoding="UTF-8" method="html" omit-xml-declaration="yes" indent="no"/>
    <xsl:strip-space elements="*"/>
    <xsl:preserve-space elements="tei:q tei:quote tei:item tei:cell tei:p tei:dateline
        tei:closer tei:opener tei:hi tei:persName tei:rs tei:workName
        tei:characterName tei:placeName tei:seg tei:footNote tei:head tei:date
        tei:orgName tei:note tei:lem tei:rdg tei:add tei:provenance
        tei:acquisition tei:damage"/>

    <xsl:include href="common_main.xsl"/>
    <xsl:include href="common_link.xsl"/>
    <xsl:include href="apparatus.xsl"/>

    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="tei:text">
        <div class="teiSrc_text">
            <xsl:apply-templates/>
        </div>
        <xsl:call-template name="createApparatus"/>
    </xsl:template>

    <xsl:template match="tei:front">
        <div class="teiSrc_front">
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="tei:body">
        <div class="teiSrc_body">
            <xsl:apply-templates/>
            <xsl:if test=".//tei:footNote">
                <xsl:call-template name="createEndnotes"/>
            </xsl:if>
        </div>
    </xsl:template>

    <xsl:template match="tei:div">
        <div class="srcPart">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="tei:head[parent::tei:div]" priority="1">
        <xsl:element name="{if (@type = 'sub') then 'h3' else 'h2'}">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class" select="'srcHeader'"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="tei:pb" priority="1">
        <xsl:variable name="label" as="xs:string">
            <xsl:choose>
                <xsl:when test="@n">
                    <xsl:choose>
                        <xsl:when test="matches(@n, '[vr]')">
                            <xsl:value-of select="concat(wega:getLanguageString('pageBreakTo', $lang), ' ', wega:getLanguageString('leaf', $lang), '&#160;', @n)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="concat(wega:getLanguageString('pageBreakTo', $lang), ' ', wega:getLanguageString('pp', $lang), '&#160;', @n)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="wega:getLanguageString('pageBreak', $lang)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <hr class="tei_pb-text" title="{$label}" data-content="{$label}">
            <xsl:if test="@facs">
                <xsl:attribute name="data-facs" select="substring(@facs, 2)"/>
            </xsl:if>
        </hr>
    </xsl:template>

    <xsl:template match="tei:lg" priority="1">
        <xsl:variable name="indent-class" as="xs:string?"
            select="if (tokenize(normalize-space(@rend), '\s+') = 'indent' and @n = ('1', '2', '3')) then concat('indent-', @n) else ()"/>
        <span class="{string-join(('lg', $indent-class), ' ')}">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <xsl:template match="tei:l" priority="1">
        <xsl:variable name="indent-class" as="xs:string?"
            select="if (tokenize(normalize-space(@rend), '\s+') = 'indent' and @n = ('1', '2', '3')) then concat('indent-', @n) else ()"/>
        <span class="{string-join(('verseLine', $indent-class), ' ')}">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:if test="@part">
                <xsl:attribute name="data-part" select="@part"/>
            </xsl:if>
            <xsl:apply-templates/>
        </span>
    </xsl:template>

</xsl:stylesheet>
