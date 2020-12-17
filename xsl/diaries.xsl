<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/1999/xhtml" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:wega="http://xquery.weber-gesamtausgabe.de/webapp/functions/utilities" exclude-result-prefixes="xs" version="2.0">
    <xsl:output encoding="UTF-8" method="html" omit-xml-declaration="yes" indent="no"/>
    
    <!--<xsl:strip-space elements="*"/>-->
    <xsl:preserve-space elements="tei:q tei:quote tei:seg tei:hi tei:ab tei:persName tei:rs tei:workName tei:characterName tei:placeName tei:date tei:add tei:head tei:orgName tei:note"/>
    
    <xsl:include href="common_link.xsl"/>
    <xsl:include href="common_main.xsl"/>
    <xsl:include href="apparatus.xsl"/>
    
    <xsl:template match="tei:ab">
            <!-- left table column -->
            <xsl:element name="div">
                <xsl:apply-templates select="@xml:id"/>
                <xsl:attribute name="class" select="'tableLeft'"/>
                <xsl:element name="p">
                    <xsl:apply-templates/>
                </xsl:element>
            </xsl:element>
            
            <!-- right table column -->
            <xsl:element name="div">
                <xsl:attribute name="class" select="'tableRight'"/>
                <xsl:element name="p">
                    <xsl:element name="span">
                        <!--    Alles auf gleichen Abstand            -->
                        <xsl:attribute name="class" select="'hiddenText'"/>
                        <xsl:text>|</xsl:text>
                    </xsl:element>
                    <xsl:apply-templates select="element()" mode="rightTableColumn"/>
                </xsl:element>
            </xsl:element>
            
            <!-- Apparatus entries; this will be moved by the calling XQuery elsewhere -->
            <xsl:call-template name="createApparatus"/>
    </xsl:template>
    
    <!-- 
        #################################### 
            Left table column
        #################################### 
    --> 
    
    <xsl:template match="tei:pb" priority="1">
        <xsl:element name="br"/>
        <xsl:element name="span">
            <xsl:attribute name="class" select="'tei_pb'"/>
            <xsl:value-of select="wega:getLanguageString('pageBreak', $lang)"/>
            <!-- <xsl:text>Seitenumbruch</xsl:text> -->
        </xsl:element>
    </xsl:template>
    
    <!-- 
        overwrite generic template from common_main.xsl
        which drops line breaks following a tei:seg[@rend]
    -->
    <xsl:template match="tei:lb" priority="0.8">
        <xsl:if test="@type='inWord' or @break='no'">
            <xsl:element name="span">
                <xsl:attribute name="class" select="'break_inWord'"/>
                <xsl:text>-</xsl:text>
            </xsl:element>
        </xsl:if>
        <xsl:element name="br"/>
        <!-- 
            special treatment for linebreaks in segs that span more than one line;
            occurs rarely but see A062344, A062374, and A065590 
        -->
        <xsl:if test="ancestor::tei:seg[@rend]">
            <xsl:element name="span">
                <!--    Erzwingt vertikalen Abstand bei Zeilenumbrüchen -->
                <xsl:attribute name="class" select="'hiddenText'"/>
                <xsl:text>|</xsl:text>
            </xsl:element>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="tei:seg">
        <xsl:variable name="counter">
            <xsl:number level="any"/>
        </xsl:variable>
        <xsl:element name="span">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:if test="./tei:measure">
                <xsl:variable name="cssClass">
                    <xsl:value-of select="concat('payment_',$counter)"/>
                </xsl:variable>
                <xsl:variable name="divId">
                    <xsl:value-of select="parent::tei:ab/@xml:id"/>
                </xsl:variable>
                <xsl:attribute name="class" select="$cssClass"/>
            </xsl:if>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:measure[@type='expense' or ancestor::tei:seg/@type='accounting'][not(@rend='inline')]"/>
    
    <xsl:template match="tei:measure">
        <xsl:element name="span">
            <xsl:attribute name="class">tei_measure</xsl:attribute>
            <xsl:apply-templates/>
            <!-- Wenn kein Währungssymbol angegeben ist, setzen wir eins hinzu -->
            <xsl:copy-of select="wega:addCurrencySymbolIfNecessary(.)"/>
        </xsl:element>
    </xsl:template>
    
    <!-- 
        #################################### 
            Right table column
        #################################### 
    --> 
    
    <xsl:template match="tei:pb" priority="1" mode="rightTableColumn">
        <xsl:element name="span">
            <xsl:attribute name="class" select="'tei_pb'"/>
            <!--            <xsl:text>Seitenumbruch</xsl:text>-->
            <xsl:element name="br"/>
        </xsl:element>
        <xsl:element name="span">
            <!--    Erzwingt vertikalen Abstand bei Zeilenumbrüchen -->
            <xsl:attribute name="class" select="'hiddenText'"/>
            <xsl:text>|</xsl:text>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:lb" priority="1" mode="rightTableColumn">
        <xsl:element name="br"/>
        <xsl:element name="span">
            <!--    Erzwingt vertikalen Abstand bei Zeilenumbrüchen -->
            <xsl:attribute name="class" select="'hiddenText'"/>
            <xsl:text>|</xsl:text>
        </xsl:element>
    </xsl:template>
    
    <!-- 
        dedicated rule for tei:seg[@rend] because those elements
        get a styling as `display:block` which produces extra line breaks.
        Hence we need to add extra line breaks in the right column
        as well.
    -->
    <xsl:template match="tei:seg[@rend]" priority="1" mode="rightTableColumn">
        <xsl:apply-templates mode="#current">
            <xsl:with-param name="counter" tunnel="yes">
                <xsl:number level="any"/>
            </xsl:with-param>
        </xsl:apply-templates>
        <xsl:element name="br"/>
        <xsl:element name="span">
            <!--    Erzwingt vertikalen Abstand bei Zeilenumbrüchen -->
            <xsl:attribute name="class" select="'hiddenText'"/>
            <xsl:text>|</xsl:text>
        </xsl:element>
    </xsl:template>
    
    <!--
        this is the entry point for the right column.
        Need to catch everything to process nested line
        and page breaks.
        There are several caveats: 
        * measure@rend='inline' need to be excluded because they will be output in the left column
        * ancestor::tei:seg[@rend] need to be excluded, otherwise those measures will be duplicated by the rule above for `tei:seg[@rend]`
    -->
    <xsl:template match="*[parent::tei:ab]" priority="0.1" mode="rightTableColumn">
        <xsl:apply-templates mode="#current">
            <xsl:with-param name="counter" tunnel="yes">
                <xsl:number level="any"/>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="tei:measure[@type='expense' or ancestor::tei:seg/@type='accounting'][not(@rend='inline')]" priority="0.5" mode="rightTableColumn">
        <xsl:param name="counter" tunnel="yes"/>
        <xsl:element name="span">
            <xsl:attribute name="class">
                <xsl:value-of select="concat('payment_',$counter)"/>
                <xsl:value-of select="concat(' ', @unit)"/>
                <xsl:if test="ancestor::tei:del">
                    <xsl:value-of select="' tei_del'"/>
                </xsl:if>
                <!-- need to process ancestor tei:hi elements with rendition information here -->
                <xsl:for-each select="ancestor::tei:hi">
                    <xsl:text> </xsl:text>
                    <xsl:choose>
                        <xsl:when test="@n &gt; 1 or ancestor::tei:hi[@rend='underline']">
                            <xsl:value-of select="'tei_hi_underline2andMore'"/>
                        </xsl:when>
                        <xsl:when test="@rend='underline' and (not(@n) or @n='1')">
                            <xsl:value-of select="'tei_hi_underline1'"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="concat('tei_hi_', @rend)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:attribute>
            <xsl:apply-templates mode="#default"/>
            <!-- Wenn kein Währungssymbol angegeben ist, setzen wir eins hinzu -->
            <xsl:copy-of select="wega:addCurrencySymbolIfNecessary(.)"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:measure" priority="0.2" mode="rightTableColumn">
        <xsl:apply-templates select="*" mode="#current"/>
    </xsl:template>
    
    <!--
        Need to add priority to overwrite default 
        template (with mode #add) in the commons module
    -->
    <xsl:template match="*" mode="rightTableColumn" priority="0.01">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    
    <!-- 
        extra treatment since per default the content of those elements will be enquoted
        which results in empty quotations in the right column
        (see templates in common_main.xsl and commit 3777509a)
    -->
    <xsl:template match="tei:q|tei:quote|tei:soCalled" mode="rightTableColumn" priority="1">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    
    <!--
        extra treatment for elements processed in the linking module with the mode #all
    -->
    <xsl:template match="tei:persName | tei:orgName | tei:workName | tei:settlement" mode="rightTableColumn" priority="1">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    
    <!--
        extra treatment for elements processed in the commons module with the mode #all
    -->
    <xsl:template match="tei:hi" mode="rightTableColumn" priority="1">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>
    
    <xsl:template match="text()[not(parent::tei:measure)]" mode="rightTableColumn"/>
    
</xsl:stylesheet>