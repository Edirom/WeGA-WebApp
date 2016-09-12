<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:html="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="xs"
    version="2.0">
    
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="*|@*">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="@href">
        <xsl:attribute name="href">
            <xsl:choose>
                <xsl:when test="contains(., 'digilib')">
                    <xsl:value-of select="replace(., '.*/digilib', '/digilib')"/>
                </xsl:when>
                <xsl:when test="matches(., '#[a-f0-9]+')">
                    <xsl:value-of select="'some_computed_id'"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="replace(., '/exist/apps/WeGA-WebApp', '')"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
    </xsl:template>
    
    <xsl:template match="@src">
        <xsl:attribute name="src">
            <xsl:choose>
                <xsl:when test="contains(., 'digilib')">
                    <xsl:value-of select="replace(., '.*/digilib', '/digilib')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="replace(., '/exist/apps/WeGA-WebApp', '')"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
    </xsl:template>
    
    <xsl:template match="@data-url">
        <xsl:attribute name="data-url">
            <xsl:value-of select="replace(., '/exist/apps/WeGA-WebApp', '')"/>
        </xsl:attribute>
    </xsl:template>
    
    <xsl:template match="@data-tab-url">
        <xsl:attribute name="data-tab-url">
            <xsl:value-of select="replace(., '/exist/apps/WeGA-WebApp', '')"/>
        </xsl:attribute>
    </xsl:template>
    
    <xsl:template match="html:span[matches(., '^Letzte Änderung dieses Dokuments am \d\d?\. \w+ \d{4}')]"/>
    <!--<xsl:template match="html:li[normalize-space(.)='Themenkommentare']"/>-->
    
    <xsl:template match="@id"/>
    <xsl:template match="@data-ref"/>
    <xsl:template match="processing-instruction() | comment()"/>
    
    <xsl:template match="html:meta[@name='DC.identifier'][not(normalize-space(@content) eq '')]"/>
    <xsl:template match="html:meta[@name='DC.date'][not(normalize-space(@content) eq '')]"/>
    <xsl:template match="html:meta[@name='DC.creator'][not(normalize-space(@content) eq '')]"/>
    <xsl:template match="html:script"/>
    <xsl:template match="html:noscript"/>
    
</xsl:stylesheet>