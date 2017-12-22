<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:mei="http://www.music-encoding.org/ns/mei"
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
    
</xsl:stylesheet>