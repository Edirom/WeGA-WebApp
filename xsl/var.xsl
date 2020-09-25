<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:wega="http://xquery.weber-gesamtausgabe.de/webapp/functions/utilities"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:rng="http://relaxng.org/ns/structure/1.0"
    xmlns:teix="http://www.tei-c.org/ns/Examples"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" version="2.0">
    <xsl:output encoding="UTF-8" method="html" omit-xml-declaration="yes" indent="no"/>
    <xsl:param name="createSecNos" select="false()"/>
    <xsl:param name="secNoOffset" select="0"/>
    <xsl:param name="uri"/>
    <xsl:strip-space elements="*"/>
    <xsl:preserve-space elements="tei:q tei:quote tei:cell tei:p tei:hi tei:persName tei:rs tei:workName tei:characterName tei:placeName tei:code tei:eg tei:item tei:head tei:date tei:orgName tei:note tei:lem tei:rdg tei:add"/>
    <xsl:include href="common_link.xsl"/>
    <xsl:include href="common_main.xsl"/>
	<xsl:include href="tagdocs.xsl"/>
    <xsl:include href="apparatus.xsl"/>
    
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>

    <!-- wird nie benutzt, oder?! -->
    <!--<xsl:template match="tei:text">
        <xsl:element name="div">
            <xsl:attribute name="class" select="'docText'"/>
            <xsl:apply-templates select="./tei:body/tei:div[@xml:lang=$lang] | ./tei:body/tei:divGen"/>
        </xsl:element>
    </xsl:template>-->
    
    <xsl:template match="tei:body">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="tei:back">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="tei:divGen[@type='toc']">
        <xsl:call-template name="createToc">
            <xsl:with-param name="lang" select="$lang"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="tei:divGen[@type='endNotes']">
        <xsl:call-template name="createEndnotesFromNotes"/>
    </xsl:template>

    <xsl:template match="tei:div">
        <xsl:variable name="uniqueID">
            <xsl:choose>
                <xsl:when test="@xml:id">
                    <xsl:value-of select="@xml:id"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="generate-id()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:element name="div">
            <xsl:attribute name="id" select="$uniqueID"/>
            <xsl:if test="@type">
                <xsl:attribute name="class" select="@type"/>
            </xsl:if>
            <xsl:if test="matches(@xml:id, '^para\d+$')">
                <xsl:call-template name="create-para-label">
                    <xsl:with-param name="no" select="substring-after(@xml:id, 'para')"/>
                </xsl:call-template>
            </xsl:if>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="tei:head[not(@type='sub')][parent::tei:div]">
<!--        <xsl:choose>-->
<!--            <xsl:when test="//tei:divGen">-->
                <!-- Überschrift h2 für Editionsrichtlinien und Weber-Biographie -->
                <xsl:element name="{concat('h', count(ancestor::tei:div) +1)}">
                    <xsl:attribute name="id">
                        <xsl:choose>
                            <xsl:when test="@xml:id">
                                <xsl:value-of select="@xml:id"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="generate-id()"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:attribute>
                    <xsl:if test="$createSecNos and not(./following::tei:divGen)">
                        <xsl:call-template name="createSecNo">
                            <xsl:with-param name="div" select="parent::tei:div"/>
                            <xsl:with-param name="lang" select="$lang"/>
                        </xsl:call-template>
                        <xsl:text> </xsl:text>
                    </xsl:if>
                    <xsl:apply-templates/>
                </xsl:element>
<!--            </xsl:when>-->
            <!--<xsl:otherwise>
                <!-\- Ebenfalls h2 für Indexseite und Impressum -\->
                <xsl:element name="{concat('h', count(ancestor::tei:div) +1)}">
                    <xsl:apply-templates/>
                </xsl:element>
            </xsl:otherwise>-->
        <!--</xsl:choose>-->
    </xsl:template>

    <xsl:template match="tei:head[@type='sub']">
        <xsl:element name="h3">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="tei:ab">
        <xsl:element name="div">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:code">
        <xsl:element name="code">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:gloss[parent::tei:eg]">
        <xsl:element name="div">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class" select="'card-header'"/>
            <xsl:element name="h4">
                <xsl:attribute name="class" select="'card-title'"/>
                <xsl:apply-templates/>
            </xsl:element>
        </xsl:element>
    </xsl:template>

    <xsl:template match="tei:address">
        <xsl:element name="ul">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class" select="'contactAddress'"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="tei:addrLine">
        <xsl:element name="li">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:choose>
                <xsl:when test="@n='telephone'">
                    <xsl:value-of select="concat(wega:getLanguageString('tel',$lang), ': ')"/>
                    <xsl:element name="a">
                        <xsl:attribute name="href" select="concat('tel:', replace(normalize-space(.), '-|–|(\(0\))|\s', ''))"/>
                        <xsl:apply-templates/>
                    </xsl:element>
                </xsl:when>
                <xsl:when test="@n='fax'">
                    <xsl:value-of select="concat(wega:getLanguageString('fax',$lang), ': ', .)"/>
                </xsl:when>
                <xsl:when test="@n='email'">
                    <xsl:element name="a">
                        <xsl:attribute name="class" select="'obfuscate-email'"/>
                        <xsl:apply-templates/>
                    </xsl:element>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:note[@type=('commentary','definition','textConst')]" priority="2">
        <xsl:call-template name="popover">
            <xsl:with-param name="marker" select="'arabic'"/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="tei:listBibl">
        <xsl:element name="ul">
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:bibl[parent::tei:listBibl]">
        <xsl:element name="li">
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <!-- Create section numbers for headings   -->
    <xsl:template name="createSecNo">
        <xsl:param name="div"/>
        <xsl:param name="lang"/>
        <xsl:param name="dot" select="false()"/>
        <xsl:variable name="offset" as="xs:integer">
            <xsl:choose>
                <xsl:when test="$div/ancestor::tei:div">
                    <xsl:value-of select="0"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$secNoOffset"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:if test="$div/parent::tei:div">
            <xsl:call-template name="createSecNo">
                <xsl:with-param name="div" select="$div/parent::tei:div"/>
                <xsl:with-param name="lang" select="$lang"/>
                <xsl:with-param name="dot" select="true()"/>
            </xsl:call-template>
        </xsl:if>
        <xsl:value-of select="count($div/preceding-sibling::tei:div[not(following::tei:divGen)][tei:head][ancestor-or-self::tei:div/@xml:lang=$lang]) + 1 +$offset"/>
        <xsl:if test="$dot">
            <xsl:text>.&#8201;</xsl:text>
        </xsl:if>
    </xsl:template>

    <!-- Create table of contents   -->
    <xsl:template name="createToc">
        <xsl:param name="lang" as="xs:string?"/>
        <xsl:element name="div">
            <xsl:attribute name="id" select="'toc'"/>
            <xsl:element name="h2">
                <xsl:value-of select="wega:getLanguageString('toc', $lang)"/>
            </xsl:element>
            <xsl:element name="ul">
                <xsl:for-each select="//tei:head[not(@type='sub')][ancestor::tei:div/string(@xml:lang) = ($lang, '')][preceding::tei:divGen[@type='toc']][parent::tei:div] | //tei:divGen[@type='endNotes']">
                    <xsl:element name="li">
                    	<xsl:attribute name="class" select="concat('secLevel', count(ancestor::tei:div))"/>
                        <xsl:element name="a">
                            <xsl:attribute name="href">
                                <xsl:choose>
                                    <xsl:when test="parent::tei:div[@xml:id]">
                                        <xsl:value-of select="concat('#', parent::tei:div/@xml:id)"/>
                                    </xsl:when>
                                    <xsl:when test="self::tei:divGen">
                                        <xsl:value-of select="concat('#', @type)"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="concat('#', generate-id())"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:attribute>
                            <xsl:if test="$createSecNos">
                                <xsl:call-template name="createSecNo">
                                    <xsl:with-param name="div" select="parent::tei:div"/>
                                    <xsl:with-param name="lang" select="$lang"/>
                                </xsl:call-template>
                                <xsl:text> </xsl:text>
                            </xsl:if>
                            <xsl:choose>
                                <xsl:when test="self::tei:divGen">
                                    <xsl:value-of select="wega:getLanguageString('endNotes', $lang)"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="."/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:element>
                    </xsl:element>
                </xsl:for-each>
            </xsl:element>
        </xsl:element>
    </xsl:template>

    <xsl:template name="create-para-label">
        <!--<xsl:param name="lang" tunnel="yes"/>-->
        <xsl:param name="no"/>
        <xsl:element name="span">
            <xsl:attribute name="class" select="'para-label'"/>
            <xsl:value-of select="concat('§ ', $no)"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template name="createEndnotesFromNotes">
        <xsl:element name="div">
            <xsl:attribute name="id" select="'endNotes'"/>
            <xsl:element name="{concat('h', count(ancestor::tei:div) + 2)}">
                <xsl:value-of select="wega:getLanguageString('endNotes', $lang)"/>
            </xsl:element>
            <xsl:element name="ol">
                <xsl:attribute name="class">endNotes</xsl:attribute>
                <xsl:for-each select="//tei:note[@type=('commentary','definition','textConst')]">
                    <xsl:element name="li">
                        <xsl:attribute name="id" select="./@xml:id"/>
                        <xsl:attribute name="data-title" select="concat(wega:getLanguageString('endNote', $lang), '&#160;', position())"/>
                        <xsl:element name="a">
                            <xsl:attribute name="class">endnote_backlink</xsl:attribute>
                            <xsl:attribute name="href" select="concat('#ref-', @xml:id)"/>
                            <xsl:value-of select="position()"/>
                        </xsl:element>
                        <xsl:apply-templates/>
                    </xsl:element>
                </xsl:for-each>
            </xsl:element>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="*" mode="verbatim">
        <xsl:param name="indent-increment" select="'   '"/>
        <xsl:param name="indent" select="'&#xA;'"/>
        
        <!-- indent the opening tag; unless it's the root element -->
        <xsl:if test="not(parent::teix:egXML)">
            <xsl:value-of select="$indent"/>
        </xsl:if>
        
        <!-- Begin opening tag -->
        <xsl:text>&lt;</xsl:text>
        <xsl:value-of select="name()"/>
        
        <!-- Namespaces -->
        <xsl:for-each select="namespace::*[not(starts-with(., 'http://www.tei-c.org') or . eq 'http://www.w3.org/XML/1998/namespace')]">
            <xsl:text> xmlns</xsl:text>
            <xsl:if test="name() != ''">
                <xsl:text>:</xsl:text>
                <xsl:value-of select="name()"/>
            </xsl:if>
            <xsl:text>='</xsl:text>
            <xsl:call-template name="verbatim-xml">
                <xsl:with-param name="text" select="."/>
            </xsl:call-template>
            <xsl:text>'</xsl:text>
        </xsl:for-each>
        
        <!-- Attributes -->
        <xsl:for-each select="@*">
            <xsl:text> </xsl:text>
            <xsl:value-of select="name()"/>
            <xsl:text>='</xsl:text>
            <xsl:call-template name="verbatim-xml">
                <xsl:with-param name="text" select="."/>
            </xsl:call-template>
            <xsl:text>'</xsl:text>
        </xsl:for-each>
        
        <!-- End opening tag -->
        <xsl:text>&gt;</xsl:text>
        
        <!-- Content (child elements, text nodes, and PIs) -->
        <xsl:apply-templates select="node()" mode="verbatim">
            <xsl:with-param name="indent" select="concat($indent, $indent-increment)"/>
        </xsl:apply-templates>
        
        <xsl:if test="*">
            <xsl:value-of select="$indent"/>
        </xsl:if>
        
        <!-- Closing tag -->
        <xsl:text>&lt;/</xsl:text>
        <xsl:value-of select="name()"/>
        <xsl:text>&gt;</xsl:text>
    </xsl:template>
    
    <!--
        Need to add priority to overwrite default 
        template (with mode #add) in the commons module
    -->
    <xsl:template match="text()" mode="verbatim" priority="0.1">
        <xsl:call-template name="verbatim-xml">
            <xsl:with-param name="text" select="."/>
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="processing-instruction()" mode="verbatim">
        <xsl:text>&lt;?</xsl:text>
        <xsl:value-of select="name()"/>
        <xsl:text> </xsl:text>
        <xsl:call-template name="verbatim-xml">
            <xsl:with-param name="text" select="."/>
        </xsl:call-template>
        <xsl:text>?&gt;</xsl:text>
    </xsl:template>
    
    <xsl:template name="verbatim-xml">
        <xsl:param name="text"/>
        <xsl:if test="$text != ''">
            <xsl:variable name="head" select="substring($text, 1, 1)"/>
            <xsl:variable name="tail" select="substring($text, 2)"/>
            <xsl:choose>
                <xsl:when test="$head = '&amp;'">&amp;amp;</xsl:when>
                <xsl:when test="$head = '&lt;'">&amp;lt;</xsl:when>
                <xsl:when test="$head = '&gt;'">&amp;gt;</xsl:when>
                <xsl:when test="$head = '&#34;'">&amp;quot;</xsl:when>
                <xsl:when test="$head = &#34;'&#34;">&amp;apos;</xsl:when>
                <xsl:otherwise><xsl:value-of select="$head"/></xsl:otherwise>
            </xsl:choose>
            <xsl:call-template name="verbatim-xml">
                <xsl:with-param name="text" select="$tail"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

</xsl:stylesheet>