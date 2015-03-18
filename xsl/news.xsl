<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:wega="http://xquery.weber-gesamtausgabe.de/webapp/functions/utilities"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:rng="http://relaxng.org/ns/structure/1.0"
    version="2.0">
    <xsl:output encoding="UTF-8" method="html" omit-xml-declaration="yes" indent="no"/>
    <xsl:strip-space elements="*"/>
    <xsl:preserve-space
        elements="tei:item tei:cell tei:p tei:dateline tei:closer tei:opener tei:hi tei:persName tei:rs tei:workName tei:characterName tei:placeName tei:seg tei:head tei:date"/>
    <xsl:include href="common_main.xsl"/>
    <xsl:include href="common_link.xsl"/>
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="tei:body">
        <xsl:element name="div">
            <xsl:attribute name="class" select="'newsText'"/>
            <xsl:apply-templates/>
            <xsl:if test="//tei:footNote">
                <xsl:call-template name="createEndnotes"/>
            </xsl:if>
        </xsl:element>
    </xsl:template>
    <xsl:template match="tei:p">
        <xsl:element name="p">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
</xsl:stylesheet>
