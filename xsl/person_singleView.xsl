<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:wega="http://xquery.weber-gesamtausgabe.de/webapp/functions/utilities"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:rng="http://relaxng.org/ns/structure/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    version="2.0">
    <xsl:output encoding="UTF-8" method="html" omit-xml-declaration="yes"/>

    <xsl:preserve-space
        elements="tei:item tei:cell tei:hi tei:persName tei:rs tei:workName tei:characterName tei:placeName tei:head tei:date"/>
    
    <xsl:param name="eventID" as="xs:string"/>

    <xsl:include href="common_main.xsl"/>
    <xsl:include href="common_link.xsl"/>


    <xsl:template match="tei:p">
        <xsl:element name="p">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="tei:note[@type='bioSummary']" priority="1">
        <xsl:element name="div">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:event">
        <xsl:element name="div">
            <xsl:attribute name="id" select="$eventID"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:head[parent::tei:event]" priority="0.7">
        <xsl:element name="h2">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
</xsl:stylesheet>
