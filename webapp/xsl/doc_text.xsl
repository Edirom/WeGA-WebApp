<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:wega="http://xquery.weber-gesamtausgabe.de/webapp/functions/utilities"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:functx="http://www.functx.com"
    xmlns:rng="http://relaxng.org/ns/structure/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    version="2.0">
    <xsl:output encoding="UTF-8" method="html" omit-xml-declaration="yes" indent="no"/>

    <xsl:strip-space elements="*"/>
    <xsl:preserve-space
        elements="tei:p tei:dateline tei:closer tei:opener tei:hi tei:persName tei:rs tei:workName tei:characterName tei:placeName tei:seg tei:footnote tei:head"/>

    <xsl:param name="headerMode" select="false()"/>

    <xsl:include href="common_main.xsl"/>
    <xsl:include href="common_link.xsl"/>
    <xsl:template match="/">
        <xsl:choose>
            <xsl:when test="$headerMode">
                <xsl:apply-templates mode="header"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tei:title[@level='a']" mode="header" priority="0.5">
        <xsl:element name="h1">
            <xsl:apply-templates mode="#default"/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="tei:title[@level='a'][@type='sub']" mode="header" priority="0.7">
        <xsl:element name="h2">
            <xsl:apply-templates mode="#default"/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="tei:body">
        <xsl:element name="div">
            <xsl:attribute name="id" select="'teiDoc_body'"/>
            <xsl:apply-templates select="./tei:div"/>
            <xsl:if test=".//tei:footNote">
                <xsl:call-template name="createEndnotes"/>
            </xsl:if>
        </xsl:element>
    </xsl:template>
    <xsl:template match="tei:div">
        <xsl:element name="div">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class" select="'docPart'"/>
            <xsl:apply-templates/>
            <!--<xsl:if test="not(following-sibling::tei:div)">
                <xsl:element name="p">
                    <xsl:attribute name="class" select="'clearer'"/>
                </xsl:element>
            </xsl:if>-->
        </xsl:element>
    </xsl:template>
    <xsl:template match="tei:p">
        <xsl:element name="p">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="tei:head[not(ancestor::tei:floatingText)]" priority="1">
        <xsl:variable name="minHeadLevel" as="xs:integer" select="2"/>
        <xsl:variable name="increments" as="xs:integer">
            <!-- Wenn es ein Untertitel ist wird der Level hochgezählt -->
            <xsl:value-of select="count(.[@type='sub'])"/>
        </xsl:variable>
        <xsl:element name="{concat('h', $minHeadLevel + $increments)}">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class" select="'docHeader'"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="tei:signed">
        <xsl:element name="span">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class" select="'teiSigned'"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

</xsl:stylesheet>
