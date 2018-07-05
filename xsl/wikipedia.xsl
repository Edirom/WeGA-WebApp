<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:wega="http://xquery.weber-gesamtausgabe.de/webapp/functions/utilities"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" version="2.0"
    xpath-default-namespace="http://www.w3.org/1999/xhtml">
    <xsl:output encoding="UTF-8" method="html" omit-xml-declaration="yes" indent="no"/>
    <xsl:strip-space elements="*"/>
    <xsl:preserve-space elements="p b"/>
    <xsl:param name="mode"/>
    <xsl:include href="common_main.xsl"/>

    <xsl:function name="wega:createWikipediaLink" as="xs:string?">
        <xsl:param name="href" as="xs:string"/>
        <xsl:param name="myLang" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="matches($href, '^/w(iki)?/')">
                <xsl:value-of select="concat('http://', $myLang, '.wikipedia.org', $href)"/>
            </xsl:when>
            <!--<xsl:when test="matches($href, '^#')">
                <xsl:value-of select="substring($href, 2)"/>
            </xsl:when>-->
            <xsl:when test="matches($href, '^//')">
                <xsl:value-of select="concat('http:', $href)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$href"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:template match="/">
        <xsl:choose>
            <xsl:when test="$mode='appendix'">
                <xsl:apply-templates mode="appendix"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="div[@id='siteSub']" priority="1">
        <xsl:element name="div">
            <xsl:attribute name="class" select="'wikipediaOrigin'"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <!--<xsl:template match="p[1]">
        <xsl:element name="p">
            <xsl:attribute name="class" select="'shortInfo'"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>-->
    <xsl:template match="div[@id='bodyContent']" priority="0.5">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="span[@class='PageNumber']">
        <xsl:element name="span">
            <xsl:attribute name="class" select="'tei_pb'"/>
            <xsl:text>|</xsl:text>
        </xsl:element>
        <xsl:element name="span">
            <xsl:attribute name="style" select="'display:none'"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="div[@id='adbcite']" mode="appendix">
        <xsl:element name="p">
            <xsl:attribute name="class" select="'linkAppendix'"/>
            <xsl:text>Der Text unter der Überschrift „ADB“ entstammt dem </xsl:text>
            <xsl:apply-templates mode="appendix"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="li[ancestor::div[@id='toc']]">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <span class="toggle-toc-item"><i class="fa fa-plus-square" aria-hidden="true" style="display:none;"/><i class="fa fa-minus-square" aria-hidden="true"/></span>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="@src | @href">
        <xsl:attribute name="{name(.)}" select="wega:createWikipediaLink(., $lang)"/>
    </xsl:template>
    
    <xsl:template match="*|@*" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="p" mode="appendix"/>
    <xsl:template match="span[matches(@class, 'editsection')]"/>
    <xsl:template match="span[matches(@class, 'ProofRead')]"/>
    <xsl:template match="div[matches(@class, 'thumb')]" priority="0.5"/>
    <xsl:template match="table[@id='toc']" priority="1"/>
    <xsl:template match="script"/>
    <xsl:template match="div[@id='jump-to-nav']"/>
    <xsl:template match="div[matches(@class, 'noprint')]" priority="0.4"/>
    <xsl:template match="table[matches(@class, 'metadata')]" priority="1"/>
    <xsl:template match="table[@id='Vorlage_Dieser_Artikel']" priority="1"/>
    <xsl:template match="table[matches(@class, 'navbox')]" priority="1"/>
    <xsl:template match="table[contains(@class, 'vcard')]" priority="1"/>
    <xsl:template match="table[@id='persondata']" priority="1"/>
    <xsl:template match="table[@id='Vorlage_Weiterleitungshinweis']" priority="1"/>
    <xsl:template match="span[matches(@class,'metadata')]" priority="1"/>
    <xsl:template match="span[@id='interwiki-hu-fa']"/>
    <xsl:template match="div[matches(@class, 'printfooter')]" priority="1"/>
    <xsl:template match="div[matches(@class, 'dablink')]" priority="1"/>
    <xsl:template match="div[matches(@class, 'boilerplate')]" priority="1"/>
    <xsl:template match="span[matches(@class, 'printonly')]" priority="1"/>
    <xsl:template match="div[@id='catlinks']"/>
    <xsl:template match="div[@id='normdaten']"/>
    <xsl:template match="div[@id='contentSub']"/>
    <xsl:template match="div[@id='NavContent']"/>
    <xsl:template match="div[matches(@class, 'haudio')]" priority="1"/>
    <xsl:template match="a[following-sibling::div/@id='mw-content-text']"/>
    <xsl:template match="table[@id='Vorlage_Begriffsklärungshinweis']"/>
    <xsl:template match="div[@class='hatnote navigation-not-searchable']"/>
</xsl:stylesheet>