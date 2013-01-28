<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:wega="http://xquery.weber-gesamtausgabe.de/webapp/functions/utilities"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:rng="http://relaxng.org/ns/structure/1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fn="http://www.w3.org/2005/xpath-functions"
    version="2.0">
    <xsl:output encoding="UTF-8" method="html" omit-xml-declaration="yes" indent="no"/>
    <xsl:variable name="linkableElements" as="xs:string+"
        select="('persName', 'rs', 'workName', 'characterName')"/>


    <!--  *********************************************  -->
    <!--  *                  Templates                *  -->
    <!--  *********************************************  -->
    <xsl:template match="tei:persName | tei:author">
        <xsl:call-template name="createLink"/>
    </xsl:template>

    <xsl:template match="tei:rs">
        <xsl:choose>
            <xsl:when test="matches(@type, '.+s$|newsPl$')">
                <!-- Pluralformen werden aktuell noch ausgespart-->
                <xsl:element name="span">
                    <xsl:apply-templates select="@xml:id"/>
                    <xsl:attribute name="class">
                        <xsl:value-of select="@type"/>
                        <xsl:if test="@key">
                            <xsl:text> </xsl:text>
                            <xsl:value-of select="@key"/>
                        </xsl:if>
                    </xsl:attribute>
                    <xsl:apply-templates/>
                </xsl:element>
            </xsl:when>
            <xsl:when test="@type = 'work'">
                <xsl:call-template name="createHover">
                    <xsl:with-param name="key" select="@key"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="createLink"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tei:placeName">
        <xsl:element name="span">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class">
                <xsl:text>placeName </xsl:text>
                <xsl:for-each select="string-to-codepoints(normalize-space(.))">
                    <!--Umsetzen des Namens in ASCII-Zahlen, damit keine Umlaute o.ä. in der Klasse auftauchen-->
                    <xsl:value-of select="."/>
                </xsl:for-each>
            </xsl:attribute>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="tei:characterName">
        <xsl:element name="span">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class">
                <xsl:text>characterName </xsl:text>
                <xsl:for-each select="string-to-codepoints(normalize-space(.))">
                    <!--Umsetzen des Namens in ASCII-Zahlen, damit keine Umlaute o.ä. in der Klasse auftauchen-->
                    <xsl:value-of select="."/>
                </xsl:for-each>
            </xsl:attribute>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="tei:workName">
        <xsl:choose>
            <xsl:when test="@key">
                <xsl:call-template name="createHover">
                    <xsl:with-param name="key" select="@key"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:element name="span">
                    <xsl:apply-templates select="@xml:id"/>
                    <xsl:apply-templates/>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tei:ref">
        <xsl:element name="a">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="href" select="@target"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

    <xsl:template name="createLink">
        <xsl:choose>
            <xsl:when
                test="exists(@key) and not(./descendant::*[local-name(.) = $linkableElements])">
                <xsl:element name="a">
                    <xsl:if test="$transcript">
                        <xsl:attribute name="class" select="'transcript'"/>
                    </xsl:if>
                    <xsl:attribute name="href" select="wega:createLinkToDoc(@key, $lang)"/>
                    <xsl:call-template name="createHover">
                        <xsl:with-param name="key" select="@key"/>
                    </xsl:call-template>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="createHover">
                    <xsl:with-param name="key" select="@key"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="createHover">
        <xsl:param name="key" required="no"/>
        <xsl:variable name="docType">
            <xsl:choose>
                <xsl:when test="name(.)='persName'">
                    <xsl:text>person</xsl:text>
                </xsl:when>
                <xsl:when test="name(.)='author'">
                    <xsl:text>person</xsl:text>
                </xsl:when>
                <xsl:when test="name(.)='workName'">
                    <xsl:text>work</xsl:text>
                </xsl:when>
                <xsl:when test="name(.)='characterName'">
                    <xsl:text>character</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@type"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:element name="span">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class">
                <xsl:value-of select="$docType"/>
                <xsl:if test="$key != '' and not(matches($key, '\s'))">
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="$key"/>
                </xsl:if>
                <xsl:if test="$key = ''">
                    <xsl:text> </xsl:text>
                    <xsl:for-each select="string-to-codepoints(normalize-space(.))">
                        <!--Umsetzen des Namens in ASCII-Zahlen, damit keine Umlaute o.ä. in der Klasse auftauchen-->
                        <xsl:value-of select="."/>
                    </xsl:for-each>
                </xsl:if>
            </xsl:attribute>
            <xsl:if test="$key != '' and  not(matches($key, '\s'))">
                <xsl:attribute name="onmouseover">
                    <xsl:text>metaDataToTip('</xsl:text>
                    <xsl:value-of select="$key"/>
                    <xsl:text>', '</xsl:text>
                    <xsl:value-of select="$lang"/>
                    <xsl:text>')</xsl:text>
                </xsl:attribute>
                <xsl:attribute name="onmouseout">
                    <xsl:text>UnTip()</xsl:text>
                </xsl:attribute>
            </xsl:if>
            <xsl:apply-templates/>
            <!--<xsl:if test="not($key)">
                <xsl:attribute name="onmouseover">
                    <xsl:text>Tip('unbekannt')</xsl:text>
                </xsl:attribute>
            </xsl:if>-->
        </xsl:element>
    </xsl:template>

</xsl:stylesheet>
