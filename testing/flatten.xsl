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
                <xsl:when test="contains(., '/Scaler/')">
                    <xsl:value-of select="replace(., '.*/Scaler/', '/Scaler/')"/>
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
    
    <xsl:template match="@src[ancestor::html:div[contains(@class, 'iconographie') or contains(@class, 'portrait')]]">
        <xsl:attribute name="src">filtered_out_by_flatten.xsl</xsl:attribute>
    </xsl:template>
    
    <xsl:template match="@src">
        <xsl:attribute name="src">
            <xsl:choose>
                <xsl:when test="contains(., '/Scaler/')">
                    <xsl:value-of select="replace(., '.*/Scaler/', '/Scaler/')"/>
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
    
    <xsl:template match="@data-target[matches(., '#[a-f0-9]+')]">
        <xsl:attribute name="data-target">some_computed_id</xsl:attribute>
    </xsl:template>
    
    <xsl:template match="html:span[matches(., '^Letzte Änderung dieses Dokuments am \d\d?\. \w+ \d{4}')]"/>
    <xsl:template match="html:span[matches(., '^Version \d+\.\d+(\.\d+)?dev vom \d\d?\. \w+ \d{4}')]"/>
    <xsl:template match="html:h2[matches(., '^\d+ Suchergebnisse$')]"/>
    <xsl:template match="html:small[matches(., '^ \(\d+\)$')]"/><!-- Anzahl der jeweiligen Dokumente (Backlinks, Briefe, etc.) in den Personentabs -->
    <xsl:template match="html:a[@class='page-link'][matches(@href, '\?page=\d+')]"/>
    <xsl:template match="html:div[@id='gnd-beacon'][count(html:ul/html:li) gt 1]"/><!-- Beacon Links verändern sich gerne in Kleinigkeiten, daher hier entfernt -->
    
    <xsl:template match="@id"/>
    <xsl:template match="@data-ref"/>
    <xsl:template match="processing-instruction() | comment()"/>
    
    <xsl:template match="html:meta[@property='dc:identifier'][not(normalize-space(@content) eq '')]"/>
    <xsl:template match="html:meta[@property='dc:date'][not(normalize-space(@content) eq '')]"/>
    <xsl:template match="html:meta[@property='dc:creator'][not(normalize-space(@content) eq '')]"/>
<!--    <xsl:template match="html:script"/>-->
<!--    <xsl:template match="html:noscript"/>-->
    
</xsl:stylesheet>