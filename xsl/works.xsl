<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:mei="http://www.music-encoding.org/ns/mei"
    xmlns:wega="http://xquery.weber-gesamtausgabe.de/webapp/functions/utilities"
    xmlns="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="xs" version="2.0">
    
    <xsl:output encoding="UTF-8" method="html" omit-xml-declaration="yes"/>
    
    <xsl:include href="common_main.xsl"/>
    <xsl:include href="common_link.xsl"/>
    
    <xsl:template match="mei:p">
        <xsl:element name="p">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="mei:lb">
        <xsl:element name="br"/>
    </xsl:template>
    
    <!-- suppress links within titles (for popovers etc.) -->
    <xsl:template match="mei:persName[parent::mei:title]" priority="4">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="mei:eventList">
        <xsl:element name="dl">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="mei:event[parent::mei:eventList]">
        <xsl:element name="dt">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates select="mei:head"/>
        </xsl:element>
        <xsl:element name="dd">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates select="node() except mei:head"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="mei:creation">
        <xsl:element name="p">
            <xsl:value-of select="wega:getLanguageString('dateOfOrigin', $lang)"/>
            <xsl:text>: </xsl:text>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="mei:annot">
        <xsl:element name="p">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
</xsl:stylesheet>