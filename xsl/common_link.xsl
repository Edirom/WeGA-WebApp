<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:wega="http://xquery.weber-gesamtausgabe.de/webapp/functions/utilities" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:rng="http://relaxng.org/ns/structure/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fn="http://www.w3.org/2005/xpath-functions" version="2.0">
    <xsl:output encoding="UTF-8" method="html" omit-xml-declaration="yes" indent="no"/>
    <xsl:variable name="linkableElements" as="xs:string+" select="('persName', 'rs', 'workName', 'characterName')"/>


    <!--  *********************************************  -->
    <!--  *                  Templates                *  -->
    <!--  *********************************************  -->
    <xsl:template match="tei:persName | tei:author">
        <xsl:choose>
            <xsl:when test="@key and not($suppressLinks)">
                <xsl:call-template name="createLink"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="createSpan"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tei:rs">
        <xsl:choose>
            <xsl:when test="$suppressLinks">
                <xsl:call-template name="createSpan"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="matches(@type, '.+[yrnkg]s$|newsPl$')">
                        <!-- Pluralformen werden aktuell noch ausgespart-->
                        <xsl:call-template name="createSpan"/>
                    </xsl:when>
                    <xsl:when test="matches(@type, 'work|biblio')">
                        <!-- Für Werke und Bibliographische Objekte gibt es aktuell noch keine Einzelansicht, lediglich einen Tooltip -->
                        <xsl:call-template name="createSpan"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="createLink"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tei:placeName">
        <xsl:call-template name="createSpan"/>
    </xsl:template>

    <xsl:template match="tei:characterName">
        <xsl:call-template name="createSpan"/>
    </xsl:template>

    <xsl:template match="tei:workName">
        <xsl:call-template name="createSpan"/>
    </xsl:template>

    <xsl:template match="tei:ref">
        <xsl:element name="a">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="href" select="@target"/>
            <xsl:apply-templates/>
            <xsl:if test="@type = 'hyperLink'">
                <xsl:text> </xsl:text>
                <xsl:element name="i">
                    <xsl:attribute name="class">fa fa-external-link</xsl:attribute>
                </xsl:element>
            </xsl:if>
        </xsl:element>
    </xsl:template>

    <xsl:template name="createLink">
        <xsl:choose>
            <xsl:when test="exists(@key) and not(./descendant::*[local-name(.) = $linkableElements])">
                <xsl:element name="a">
                    <xsl:attribute name="class">
                        <xsl:value-of select="wega:get-doctype-by-id(substring(@key, 1, 7))"/>
                        <xsl:text> </xsl:text>
                        <xsl:value-of select="@key"/>
                        <!--<xsl:if test="$transcript">
                            <xsl:text> transcript</xsl:text>
                        </xsl:if>-->
                    </xsl:attribute>
                    <xsl:attribute name="href" select="wega:createLinkToDoc(@key, $lang)"/>
                    <xsl:apply-templates/>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="createSpan">
        <xsl:element name="span">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class">
                <xsl:value-of select="wega:get-doctype-by-id(substring(@key, 1, 7))"/>
                <xsl:text> </xsl:text>
                <xsl:choose>
                    <xsl:when test="@key">
                        <xsl:value-of select="@key"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:for-each select="string-to-codepoints(normalize-space(.))">
                            <!--Umsetzen des Namens in ASCII-Zahlen, damit keine Umlaute o.ä. in der Klasse auftauchen-->
                            <xsl:value-of select="."/>
                        </xsl:for-each>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <!-- Pluralformen wieder aussparen s.o. -->
            <xsl:if test="@key and not($suppressLinks or string-length(@key) ne 7)">
                <xsl:attribute name="data-ref" select="wega:createLinkToDoc(@key, $lang)"/>
            </xsl:if>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

</xsl:stylesheet>