<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:wega="http://xquery.weber-gesamtausgabe.de/webapp/functions/utilities" 
    xmlns:tei="http://www.tei-c.org/ns/1.0" 
    xmlns:rng="http://relaxng.org/ns/structure/1.0" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:fn="http://www.w3.org/2005/xpath-functions" 
    xmlns:mei="http://www.music-encoding.org/ns/mei"
    xmlns="http://www.w3.org/1999/xhtml" 
    version="2.0">
    
    <xsl:output encoding="UTF-8" method="html" omit-xml-declaration="yes" indent="no"/>
    <!-- 
        because HTML does not support nested links (aka html:a elements) we need to attach the link to the deepest element; 
        thus exclude all elements with the following child elements 
    -->
    <xsl:variable name="linkableElements" as="xs:string+" select="('persName', 'rs', 
        'workName', 'characterName', 'orgName', 'sic', 'del', 'add', 'subst', 
        'damage', 'choice', 'unclear', 'app', 'note', 'settlement')"/>
    
    <!--  *********************************************  -->
    <!--  *                  Templates                *  -->
    <!--  *********************************************  -->
    <xsl:template match="tei:persName | tei:author | tei:orgName | 
        mei:persName | tei:workName | tei:settlement | mei:settlement | 
        mei:geogName | mei:corpName | mei:title[@codedval]" mode="#all">
        <xsl:choose>
            <xsl:when test="@key or @codedval">
                <xsl:call-template name="createLink"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="createSpan"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tei:rs" mode="#all">
        <!--
            Need to distinguish between docTypes with support for single views and those with tooltips only 
        -->
        <xsl:variable name="rs-types-with-link" as="xs:string+" select="('person', 'news', 'writing', 'letter', 'diaryDay', 'org', 'document', 'work')"/>
        <xsl:choose>
            <xsl:when test="@key and (@type=$rs-types-with-link)">
                <xsl:call-template name="createLink"/>
            </xsl:when>
            <!-- All plural forms, e.g. "persons" -->
            <xsl:when test="@key and not(@type=$rs-types-with-link)">
                <xsl:call-template name="createSpan"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates mode="#current"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="tei:rs[@type='addenda'][@key]">
        <!-- 
            Addenda don't need popovers and have special virtual resource locations
            Hence this special treatmetn here
        -->
        <xsl:element name="a">
            <xsl:attribute name="href" select="concat(wega:join-path-elements(($baseHref, $lang, @key)), '.html')"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="tei:characterName" mode="#all">
        <xsl:call-template name="createSpan"/>
    </xsl:template>

    <xsl:template match="tei:ref | mei:ref" mode="#all">
        <xsl:element name="a">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates select="@target"/>
            <xsl:if test="@type='footnoteAnchor'">
                <xsl:attribute name="id" select="concat('backref-', substring(@target, 2))"/>
                <xsl:attribute name="class">fn-ref</xsl:attribute>
            </xsl:if>
            <xsl:apply-templates mode="#current"/>
            <xsl:if test="@type = 'hyperLink'">
                <xsl:text> </xsl:text>
                <xsl:element name="i">
                    <xsl:attribute name="class">fa fa-external-link</xsl:attribute>
                    <xsl:attribute name="aria-hidden">true</xsl:attribute>
                </xsl:element>
            </xsl:if>
        </xsl:element>
    </xsl:template>
    
    <!--
        dedicated rule for internal links (e.g. `<ref target='wega:A090092'>`)
        which will be treated like other references with previews.
        NB: fragment identifiers are excluded since this is not implemented yet
        for previews. Hence, links with fragment identifiers (e.g. `<ref target='wega:A090092#chapter-links'>`)
        will be transformed to simple links without preview popover
    -->
    <xsl:template match="tei:ref[contains(@target, 'wega:')][not(contains(@target, '#'))] |
        mei:ref[contains(@target, 'wega:')][not(contains(@target, '#'))]" mode="#all">
        <xsl:choose>
            <xsl:when test="count(tokenize(@target, '\s+')) gt 1">
                <xsl:call-template name="createSpan"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="createLink"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="@target[not(matches(., '\s'))]">
        <xsl:attribute name="href">
            <xsl:choose>
                <xsl:when test="starts-with(.,'wega:')">
                    <!-- part 1: standard link to doc; part 2: fragment identifier -->
                    <xsl:value-of select="concat(wega:createLinkToDoc(substring(., 6, 7), $lang), substring(., 13))"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
    </xsl:template>
    
    <xsl:template match="@key[not(matches(., '\s'))] | @codedval[not(matches(., '\s'))]">
        <xsl:attribute name="href" select="wega:createLinkToDoc(., $lang)"/>
    </xsl:template>

    <xsl:template name="createLink">
        <xsl:choose>
            <xsl:when test="exists((@key, @codedval, @target)) and not(descendant::*[local-name(.) = $linkableElements])">
                <xsl:element name="a">
                    <xsl:attribute name="class">
                        <xsl:value-of select="wega:preview-class(.)"/>
                    </xsl:attribute>
                    <!--<xsl:attribute name="href" select="wega:createLinkToDoc((@key, @codedval), $lang)"/>-->
                    <xsl:apply-templates select="@key | @codedval | @target"/>
                    <xsl:apply-templates mode="#current"/>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <!--<xsl:apply-templates/>-->
                <xsl:call-template name="createSpan"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="createSpan">
        <xsl:element name="span">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class">
                <xsl:choose>
                    <xsl:when test="exists((@key, @codedval, @target))">
                        <xsl:value-of select="wega:preview-class(.)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:for-each select="string-to-codepoints(normalize-space(.))">
                            <!--Umsetzen des Namens in ASCII-Zahlen, damit keine Umlaute o.ä. in der Klasse auftauchen-->
                            <xsl:value-of select="."/>
                        </xsl:for-each>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <xsl:if test="exists((@key, @codedval, @target))">
                <xsl:variable name="urls" as="xs:string+">
                    <xsl:for-each select="descendant-or-self::*/@key | descendant-or-self::*/@codedval | descendant-or-self::*/@target[starts-with(., 'wega:')]">
                        <xsl:for-each select="tokenize(normalize-space(.), '\s+')">
                            <xsl:choose>
                                <xsl:when test="starts-with(.,'wega:')">
                                    <xsl:value-of select="wega:createLinkToDoc(substring(., 6, 7), $lang)"/>
                                </xsl:when>
                                <xsl:when test="matches(., '^A[A-F0-9]{6}$')">
                                    <xsl:value-of select="wega:createLinkToDoc(., $lang)"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="."/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:attribute name="data-ref" select="string-join($urls, ' ')"/>
            </xsl:if>
            <xsl:apply-templates mode="#current"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:function name="wega:preview-class" as="xs:string">
        <xsl:param name="myNode" as="element()"/>
        <xsl:variable name="keys" select="
            for $key in tokenize(($myNode/@key, $myNode/@codedval, $myNode/@target/replace(., 'wega:', '')), '\s+')
            return substring($key, 1, 7)
            " as="xs:string+"/>
        <xsl:variable name="class" as="xs:string">
            <xsl:choose>
                <xsl:when test="count(distinct-values(for $key in $keys return substring($key, 1,3))) = 1">
                    <xsl:value-of select="wega:get-doctype-by-id($keys[1])"/>
                </xsl:when>
                <xsl:otherwise>mixed</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="string-join(('preview', $class, $keys), ' ')"/>
    </xsl:function>

</xsl:stylesheet>