<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:wega="http://xquery.weber-gesamtausgabe.de/webapp/functions/utilities"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:functx="http://www.functx.com"
    xmlns:rng="http://relaxng.org/ns/structure/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    version="2.0">
    <xsl:output encoding="UTF-8" method="html" omit-xml-declaration="yes" indent="no"/>

    <xsl:strip-space elements="*"/>
    <xsl:preserve-space
        elements="tei:item tei:cell tei:p tei:dateline tei:closer tei:opener tei:hi tei:persName tei:rs tei:workName tei:characterName tei:placeName tei:seg tei:footnote tei:head tei:date"/>

    <xsl:param name="headerMode" select="false()"/>

    <xsl:include href="common_main.xsl"/>
    <xsl:include href="common_link.xsl"/>
    <xsl:template match="/">
        <xsl:choose>
            <xsl:when test="$headerMode">
                <xsl:element name="div">
                    <xsl:apply-templates mode="header" select=".//tei:title[@level='a']"/>
                </xsl:element>
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
    
    <!-- This is just a hack (duplicated from letter_text.xsl) -->
    <xsl:template match="tei:app">
        <xsl:variable name="appInlineID">
            <xsl:number level="any"/>
        </xsl:variable>
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
    </xsl:template>
    
    <xsl:template match="tei:lem">
        <xsl:apply-templates/>
    </xsl:template>

</xsl:stylesheet>
