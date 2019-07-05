<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:wega="http://xquery.weber-gesamtausgabe.de/webapp/functions/utilities"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:rng="http://relaxng.org/ns/structure/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    version="2.0">
    <xsl:output encoding="UTF-8" method="html" omit-xml-declaration="yes"/>

    <xsl:preserve-space
        elements="tei:item tei:cell tei:hi tei:persName tei:rs tei:workName tei:characterName tei:placeName tei:head tei:date tei:orgName tei:note"/>
    
    <xsl:include href="common_main.xsl"/>
    <xsl:include href="common_link.xsl"/>
    <xsl:include href="apparatus.xsl"/>

    <xsl:template match="tei:note[parent::document-node()]" priority="1">
        <xsl:element name="div">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:choose>
                <xsl:when test="tei:p">
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:when test="tei:list">
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:element name="p">
                        <xsl:apply-templates/>
                    </xsl:element>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:event">
        <xsl:element name="div">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:head[parent::tei:event]" priority="0.7">
        <xsl:element name="h3">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class">media-heading</xsl:attribute>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
</xsl:stylesheet>