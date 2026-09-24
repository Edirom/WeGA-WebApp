<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
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

</xsl:stylesheet>
