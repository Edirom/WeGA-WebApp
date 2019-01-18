<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:tei="http://www.tei-c.org/ns/1.0" 
    xmlns:rng="http://relaxng.org/ns/structure/1.0" 
    xmlns:wega="http://xquery.weber-gesamtausgabe.de/webapp/functions/utilities" 
    version="2.0">
    
    <xsl:output encoding="UTF-8" method="html" omit-xml-declaration="yes" indent="no"/>
    
    <xsl:strip-space elements="*"/>
    <xsl:preserve-space elements="tei:p tei:dateline tei:closer tei:opener tei:hi tei:persName tei:rs tei:workName tei:characterName tei:placeName tei:seg tei:footnote tei:head tei:orgName tei:note"/>
    
    <xsl:include href="common_main.xsl"/>
    <xsl:include href="common_link.xsl"/>
    <!--    <xsl:preserve-space elements="tei:persName"/>-->

    <!--<xsl:template match="/">
        <xsl:apply-templates/>
        </xsl:template>-->

    <xsl:template match="tei:listWit">
        <xsl:for-each select="tei:witness">
            <xsl:sort select="@n" order="ascending" data-type="number"/>
            <xsl:element name="div">
                <xsl:attribute name="id" select="concat('source_', position())"/>
                <xsl:attribute name="class" select="'witness'"/>
                <xsl:if test="position()!=1">
                    <xsl:attribute name="style" select="'display:none;'"/>
                </xsl:if>
                <xsl:apply-templates/>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="tei:msDesc">
        <xsl:choose>
            <xsl:when test="parent::tei:witness">
                <xsl:apply-templates/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:element name="div">
                    <xsl:apply-templates/>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tei:msIdentifier">
        <xsl:call-template name="createMsIdentifier">
            <xsl:with-param name="node" select="."/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="tei:msFrag">
        <xsl:element name="div">
            <xsl:attribute name="class">tei_msFrag</xsl:attribute>
            <xsl:element name="h4"><xsl:value-of select="concat(wega:getLanguageString('fragment', $lang), ' ', count(preceding-sibling::tei:msFrag) +1)"/></xsl:element>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

    <xsl:template name="createMsIdentifier">
        <xsl:param name="node"/>
        <!--<xsl:element name="h4">
            <xsl:attribute name="class">media-heading</xsl:attribute>
            <xsl:value-of select="wega:getLanguageString('repository', $lang)"/>
        </xsl:element>-->
        <xsl:element name="p">
            <xsl:if test="$node/ancestor-or-self::tei:msDesc/@rend">
                <xsl:value-of select="wega:getLanguageString($node/ancestor-or-self::tei:msDesc/@rend, $lang)"/>
                <xsl:text>: </xsl:text>
            </xsl:if>
            <xsl:if test="$node/tei:settlement != ''">
                <xsl:value-of select="tei:settlement"/>
                <xsl:text> </xsl:text>
            </xsl:if>
            <xsl:if test="$node/tei:country != ''">
                <xsl:text>(</xsl:text>
                <xsl:value-of select="tei:country"/>
                <xsl:text>), </xsl:text>
            </xsl:if>
            <xsl:if test="$node/tei:repository != ''">
                <xsl:value-of select="$node/tei:repository"/>
            </xsl:if>
            <xsl:if test="$node/tei:repository/@n">
                <xsl:text> (</xsl:text>
                <xsl:value-of select="$node/tei:repository/@n"/>
                <xsl:text>)</xsl:text>
            </xsl:if>
            <xsl:if test="$node/tei:collection != ''">
                <xsl:text>, </xsl:text>
                <xsl:value-of select="$node/tei:collection"/>
            </xsl:if>
            <xsl:if test="$node/tei:idno != ''">
                <xsl:element name="br"/>
                <xsl:element name="i">
                    <xsl:value-of select="wega:getLanguageString('shelfMark', $lang)"/>
                </xsl:element>
                <xsl:text>: </xsl:text>
                <xsl:value-of select="$node/tei:idno"/>
            </xsl:if>
            <xsl:if test="$node/tei:altIdentifier != ''">
                <xsl:variable name="altIdentifier" as="element()">
                    <xsl:call-template name="createMsIdentifier">
                        <xsl:with-param name="node" select="$node/tei:altIdentifier"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:element name="br"/>
                <xsl:element name="i">
                    <xsl:value-of select="wega:getLanguageString('formerly', $lang)"/>
                </xsl:element>
                <xsl:text>: </xsl:text>
                <xsl:element name="span">
                    <xsl:attribute name="class">tei_altIdentifier</xsl:attribute>
                    <xsl:copy-of select="$altIdentifier/node()"/>
                </xsl:element>
            </xsl:if>
        </xsl:element>
    </xsl:template>

    <xsl:template match="tei:physDesc">
        <xsl:element name="h4">
            <xsl:attribute name="class">media-heading</xsl:attribute>
            <xsl:value-of select="wega:getLanguageString('physicalDescription', $lang)"/>
        </xsl:element>
        <xsl:element name="ul">
            <xsl:for-each select="tei:p">
                <xsl:element name="li">
                    <xsl:apply-templates/>
                </xsl:element>
            </xsl:for-each>
        </xsl:element>
        <xsl:if test="tei:accMat">
            <xsl:element name="h4">
                <xsl:attribute name="class">media-heading</xsl:attribute>
                <xsl:value-of select="wega:getLanguageString('accMat', $lang)"/>
            </xsl:element>
            <xsl:element name="ul">
                <xsl:for-each select="tei:accMat">
                    <xsl:element name="li">
                        <xsl:apply-templates/>
                    </xsl:element>
                </xsl:for-each>
            </xsl:element>
        </xsl:if>
    </xsl:template>

    <xsl:template match="tei:history">
        <xsl:element name="h4">
            <xsl:attribute name="class">media-heading</xsl:attribute>
            <xsl:value-of select="wega:getLanguageString('provenance', $lang)"/>
        </xsl:element>
        <xsl:element name="ul">
            <xsl:for-each select="tei:provenance | tei:acquisition">
                <xsl:element name="li">
                    <xsl:apply-templates/>
                </xsl:element>
            </xsl:for-each>
        </xsl:element>
    </xsl:template>

    <xsl:template match="tei:additional">
        <!--<xsl:element name="h4">
            <xsl:attribute name="class">media-heading</xsl:attribute>
            <xsl:value-of select="wega:getLanguageString('prints', $lang)"/>
        </xsl:element>
        <xsl:apply-templates/>-->
    </xsl:template>

    <!--<xsl:template match="tei:listBibl">
        <xsl:element name="ul">
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>-->

    <!--<xsl:template match="tei:bibl[parent::tei:listBibl]">
        <xsl:element name="li">
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>-->
    
    <xsl:template match="tei:creation">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="tei:note[@type=('summary', 'editorial')]" priority="1">
        <xsl:element name="div">
            <xsl:choose>
                <xsl:when test="tei:p">
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:element name="p">
                        <xsl:apply-templates/>
                    </xsl:element>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:note[@type='incipit']">
        <xsl:element name="div">
            <!--<xsl:attribute name="id" select="'incipit'"/>-->
            <xsl:if test="normalize-space(.) != ''">
                <!--<xsl:element name="h3">
                    <xsl:value-of select="wega:getLanguageString('incipit', $lang)"/>
                </xsl:element>-->
                <xsl:choose>
                    <xsl:when test="tei:p">
                        <xsl:apply-templates/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:element name="p">
                            <xsl:text>"</xsl:text>
                            <xsl:apply-templates/>
                            <xsl:text> …"</xsl:text>
                        </xsl:element>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
        </xsl:element>
    </xsl:template>
    
    <!--<xsl:template match="tei:biblStruct[parent::tei:listBibl]">
        <xsl:sequence select="wega:printCitation(., 'li', $lang)"/>
    </xsl:template>-->


    <!--<xsl:template match="tei:quote">
        <xsl:text>"</xsl:text>
        <xsl:apply-templates/>
        <xsl:text>"</xsl:text>
    </xsl:template>-->
</xsl:stylesheet>