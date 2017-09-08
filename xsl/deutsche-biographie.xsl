<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xpath-default-namespace="http://www.w3.org/1999/xhtml" 
    xmlns="http://www.w3.org/1999/xhtml" 
    exclude-result-prefixes="xs" version="2.0">
    
    <xsl:output encoding="UTF-8" method="html" omit-xml-declaration="yes" indent="no"/>
    <xsl:strip-space elements="*"/>
    <xsl:preserve-space elements="p span"/>
    
    <xsl:template match="node()|@*">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="h4">
        <xsl:element name="h3">
            <xsl:apply-templates select="@*|node()"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="li[@class='artikel' or preceding-sibling::li[@class='artikel']]">
        <xsl:element name="div">
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="ul[@class='bioartikel' or li[@class='artikel']]">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="span[tokenize(@class, '\s+') = 'abbr']">
        <xsl:element name="abbr">
            <xsl:choose>
                <xsl:when test="@class='abbr'"/>
                <xsl:otherwise>
                    <xsl:attribute name="class" select="replace(@class, 'abbr', '')"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates select="@*[not(name()='class')]|node()"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="@href">
        <xsl:attribute name="href">
            <xsl:choose>
                <xsl:when test="starts-with(., 'http')">
                    <xsl:value-of select="."/>
                </xsl:when>
                <xsl:when test="starts-with(., '#')">
                    <xsl:value-of select="."/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('https://www.deutsche-biographie.de/', .)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
    </xsl:template>
    
    <xsl:template match="@class">
        <xsl:variable name="classes" as="xs:string*">
            <xsl:for-each select="tokenize(., '\s+')">
                <xsl:choose>
                    <xsl:when test=".='bold'">
                        <xsl:value-of select="'tei_hi_bold'"/>
                    </xsl:when>
                    <xsl:when test=".='spaced'">
                        <xsl:value-of select="'tei_hi_spaced_out'"/>
                    </xsl:when>
                    <xsl:when test=".='antiqua'">
                        <xsl:value-of select="'tei_hi_antiqua'"/>
                    </xsl:when>
                    <xsl:when test=".='italics'">
                        <xsl:value-of select="'tei_hi_italic'"/>
                    </xsl:when>
                    <xsl:when test=".='sup'">
                        <xsl:value-of select="'tei_hi_superscript'"/>
                    </xsl:when>
                    <!-- remove original grid information -->
                    <xsl:when test="starts-with(.,'col-sm')"/>
                    <xsl:when test="starts-with(.,'col-md')"/>    
                    <xsl:otherwise>
                        <xsl:value-of select="."/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <xsl:if test="count($classes) gt 0">
            <xsl:attribute name="class">
                <xsl:value-of select="string-join($classes, ' ')"/>
            </xsl:attribute>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="a[@href='#top']"/>
    <xsl:template match="div[div/a/@type='button']"/>
    <xsl:template match="div[contains(@class, 'navigationSidebar')]"/>
    <xsl:template match="li[h4[@id=('ndbcontent_zitierweise', 'adbcontent_zitierweise')]]" priority="1"/>
    
</xsl:stylesheet>