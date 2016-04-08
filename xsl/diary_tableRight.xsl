<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:wega="http://xquery.weber-gesamtausgabe.de/webapp/functions/utilities"
    xmlns:tei="http://www.tei-c.org/ns/1.0" 
    xmlns:rng="http://relaxng.org/ns/structure/1.0" version="2.0">

    <xsl:output encoding="UTF-8" method="html" omit-xml-declaration="yes" indent="no"/>
    
    <xsl:param name="optionsFile"/>
    <xsl:param name="baseHref"/>
    <xsl:param name="lang"/>
    <xsl:param name="dbPath"/>
    <xsl:param name="docID"/>
    <xsl:param name="transcript"/>
    <xsl:param name="data-collection-path"/>
    
    <xsl:include href="common_funcs.xsl"/>
    
    <xsl:template match="tei:ab">
        <xsl:element name="div">
            <xsl:attribute name="class" select="'tableRight'"/>
            <xsl:element name="p">
                <xsl:element name="span">
                    <!--    Alles auf gleichen Abstand            -->
                    <xsl:attribute name="class" select="'hiddenText'"/>
                    <xsl:text>|</xsl:text>
                </xsl:element>
                <xsl:apply-templates select="element()"/>
            </xsl:element>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:pb" priority="1">
        <xsl:element name="span">
            <xsl:attribute name="class" select="'tei_pb'"/>
<!--            <xsl:text>Seitenumbruch</xsl:text>-->
            <xsl:element name="br"/>
        </xsl:element>
        <xsl:element name="span">
            <!--    Erzwingt vertikalen Abstand bei Zeilenumbrüchen -->
            <xsl:attribute name="class" select="'hiddenText'"/>
            <xsl:text>|</xsl:text>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:lb" priority="1">
        <xsl:element name="br"/>
        <xsl:element name="span">
            <!--    Erzwingt vertikalen Abstand bei Zeilenumbrüchen -->
            <xsl:attribute name="class" select="'hiddenText'"/>
            <xsl:text>|</xsl:text>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:seg">
        <xsl:apply-templates select=".//tei:measure[@type='expense'][not(@rend='inline')] | .//tei:lb | .//tei:pb">
            <xsl:with-param name="counter">
                <xsl:number level="any"/>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="tei:measure[@type='expense'][not(@rend='inline')]">
        <xsl:param name="counter"/>
        <xsl:element name="span">
            <xsl:attribute name="class">
                <xsl:value-of select="concat('payment_',$counter)"/>
                <xsl:value-of select="concat(' ', @unit)"/>
                <xsl:if test="ancestor::tei:del">
                    <xsl:value-of select="' tei_del'"/>
                </xsl:if>
            </xsl:attribute>
            <xsl:apply-templates/>
            <!-- Wenn kein Währungssymbol angegeben ist, setzen wir eins hinzu -->
            <xsl:copy-of select="wega:addCurrencySymbolIfNecessary(.)"/>
        </xsl:element>
    </xsl:template>
    
    <!-- suppress all other content -->
    <xsl:template match="*"/>
    
</xsl:stylesheet>