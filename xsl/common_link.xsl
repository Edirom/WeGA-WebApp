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
    <xsl:variable name="linkableElements" as="xs:string+" select="('persName', 'rs', 'workName', 'characterName', 'orgName', 'sic', 'del', 'add', 'subst', 'damage', 'choice', 'unclear', 'app', 'note')"/>
    
    <!--  *********************************************  -->
    <!--  *                  Templates                *  -->
    <!--  *********************************************  -->
    <xsl:template match="tei:persName | tei:author | tei:orgName | mei:persName | tei:workName | tei:settlement">
        <xsl:choose>
            <xsl:when test="@key or @dbkey">
                <xsl:call-template name="createLink"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="createSpan"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tei:rs">
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
                <xsl:apply-templates/>
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

    <xsl:template match="tei:characterName">
        <xsl:call-template name="createSpan"/>
    </xsl:template>

    <xsl:template match="tei:ref">
        <xsl:element name="a">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates select="@target"/>
            <xsl:if test="@type='footnoteAnchor'">
                <xsl:attribute name="id" select="concat('backref-', substring(@target, 2))"/>
                <xsl:attribute name="class">fn-ref</xsl:attribute>
            </xsl:if>
            <xsl:apply-templates/>
            <xsl:if test="@type = 'hyperLink'">
                <xsl:text> </xsl:text>
                <xsl:element name="i">
                    <xsl:attribute name="class">fa fa-external-link</xsl:attribute>
                    <xsl:attribute name="aria-hidden">true</xsl:attribute>
                </xsl:element>
            </xsl:if>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="@target">
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

    <xsl:template name="createLink">
        <xsl:choose>
            <xsl:when test="exists((@key, @dbkey)) and not(descendant::*[local-name(.) = $linkableElements] or $suppressLinks)">
                <xsl:element name="a">
                    <xsl:attribute name="class">
                        <xsl:value-of select="string-join(('preview', wega:get-doctype-by-id(substring((@key, @dbkey), 1, 7)), (@key, @dbkey)), ' ')"/>
                    </xsl:attribute>
                    <xsl:attribute name="href" select="wega:createLinkToDoc((@key, @dbkey), $lang)"/>
                    <xsl:apply-templates/>
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
                    <xsl:when test="@key or @dbkey">
                        <xsl:value-of select="string-join(
                            (
                            if($suppressLinks) then () else 'preview', 
                            wega:get-doctype-by-id(substring((@key, @dbkey), 1, 7)), 
                            (@key, @dbkey)
                            )
                            , ' ')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:for-each select="string-to-codepoints(normalize-space(.))">
                            <!--Umsetzen des Namens in ASCII-Zahlen, damit keine Umlaute o.ä. in der Klasse auftauchen-->
                            <xsl:value-of select="."/>
                        </xsl:for-each>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <xsl:if test="(@key or @dbkey) and not($suppressLinks)">
                <xsl:variable name="urls" as="xs:string+">
                    <xsl:for-each select="descendant-or-self::*/@key | descendant-or-self::*/@dbkey">
                        <xsl:for-each select="tokenize(normalize-space(.), '\s+')">
                            <xsl:value-of select="wega:createLinkToDoc(., $lang)"/>
                        </xsl:for-each>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:attribute name="data-ref" select="string-join($urls, ' ')"/>
            </xsl:if>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

</xsl:stylesheet>