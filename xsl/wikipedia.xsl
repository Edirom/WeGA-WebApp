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
            <!--<xsl:otherwise>
                <xsl:value-of select="'foobar'"/>
            </xsl:otherwise>-->
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
    <xsl:template match="div[@id='siteSub']">
        <xsl:element name="span">
            <xsl:attribute name="class" select="'wikipediaOrigin'"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="p[1]">
        <xsl:element name="p">
            <xsl:attribute name="class" select="'shortInfo'"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="p[position()!=1]">
        <xsl:element name="p">
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="h2">
        <xsl:element name="h2">
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="h3">
        <xsl:element name="h3">
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="h4">
        <xsl:element name="h4">
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="ul">
        <xsl:element name="ul">
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="ol">
        <xsl:element name="ol">
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="li">
        <xsl:element name="li">
            <xsl:if test="@id">
                <xsl:attribute name="id" select="@id"/>
            </xsl:if>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="b">
        <xsl:element name="span">
            <xsl:attribute name="class" select="'tei_hi_bold'"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="i" mode="#all">
        <xsl:element name="span">
            <xsl:attribute name="class" select="'tei_hi_italic'"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="tt">
        <xsl:element name="span">
            <xsl:attribute name="class" select="'tei_hi_typewriter'"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="a" mode="#all">
        <xsl:element name="a">
            <xsl:choose>
                <xsl:when test="matches(@href, '^/wiki/')">
                    <xsl:attribute name="href" select="wega:createWikipediaLink(@href, $lang)"/>
                    <xsl:attribute name="class" select="'wikilink'"/>
                    <xsl:attribute name="title" select="@title"/>
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:when test="matches(@href, '^/w/')">
                    <xsl:attribute name="href" select="wega:createWikipediaLink(@href, $lang)"/>
                    <xsl:attribute name="class" select="'wikiredlink'"/>
                    <xsl:attribute name="title" select="@title"/>
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:when test="matches(@href, '^#')">
                    <!--                    <xsl:variable name="href" select="wega:createWikipediaLink(@href, $lang)"/>-->
                    <xsl:attribute name="href" select="@href"/>
                    <xsl:attribute name="class" select="'internalLink'"/>
                    <xsl:choose>
                        <xsl:when test="not(ancestor::ol[@class='references'])">
                            <xsl:attribute name="title" select="substring(//*[@id eq @href], 2)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:attribute name="title" select="wega:getLanguageString('wiki_referenceBack', $lang)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="href" select="@href"/>
                    <xsl:attribute name="class" select="'externalLink'"/>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>
    <xsl:template match="sup[@class='reference']" priority="1">
        <xsl:element name="span">
            <xsl:attribute name="class" select="'reference'"/>
            <xsl:attribute name="id" select="@id"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="sup">
        <xsl:element name="span">
            <xsl:attribute name="class" select="'tei_hi_superscript'"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="div" priority="0.2">
        <xsl:element name="div">
            <xsl:copy-of select="@style"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
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
    <xsl:template match="span[@class='mw-headline']">
        <xsl:copy>
            <xsl:copy-of select="@id"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="dl">
        <xsl:element name="dl">
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="dd">
        <xsl:element name="dd">
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
    <xsl:template match="table" priority="0.5">
        <!--<xsl:copy-of select="."/>-->
        <xsl:element name="table">
            <xsl:copy-of select="@style"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="tbody">
        <xsl:element name="tbody">
            <xsl:copy-of select="@style"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="tr">
        <xsl:element name="tr">
            <xsl:copy-of select="@style"/>
            <xsl:copy-of select="@align"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="td | th">
        <xsl:copy>
            <xsl:copy-of select="@style"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="img">
        <xsl:element name="img">
            <xsl:copy-of select="@style"/>
            <xsl:copy-of select="@alt"/>
            <xsl:copy-of select="@title"/>
            <xsl:copy-of select="@width"/>
            <xsl:copy-of select="@height"/>
            <xsl:attribute name="src" select="wega:createWikipediaLink(@src, $lang)"/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="br">
        <xsl:element name="br"/>
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
    <xsl:template match="table[@class='infobox vcard']" priority="1"/>
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
</xsl:stylesheet>
