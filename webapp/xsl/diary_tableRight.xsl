<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:tei="http://www.tei-c.org/ns/1.0" 
    xmlns:rng="http://relaxng.org/ns/structure/1.0" version="2.0">
    <xsl:output encoding="UTF-8" method="html" omit-xml-declaration="yes" indent="no"/>
    <xsl:include href="common_link.xsl"/>
    <xsl:include href="common_main.xsl"/>
    <xsl:template match="tei:ab">
        <xsl:element name="div">
            <xsl:attribute name="class" select="'tableRight'"/>
            <xsl:element name="span">
                <!--    Alles auf gleichen Abstand            -->
                <xsl:attribute name="class" select="'hiddenText'"/>
                <xsl:text>|</xsl:text>
            </xsl:element>
            <xsl:apply-templates select="element()"/>
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
        <xsl:apply-templates select=".//tei:measure[@type='expense'][not(@rend='inline')] | ./tei:lb | ./tei:pb">
            <xsl:with-param name="counter">
                <xsl:number level="any"/>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:template>
    <xsl:template match="tei:date"/>
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
            <xsl:call-template name="addCurrencySymbolIfNecessary">
                <xsl:with-param name="node" select="."/>
            </xsl:call-template>
        </xsl:element>
    </xsl:template>
</xsl:stylesheet>