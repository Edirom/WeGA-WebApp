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
        <xsl:if test="@type='inWord'">
            <xsl:element name="span">
                <xsl:attribute name="class" select="'break_inWord'"/>
                <xsl:text>-</xsl:text>
            </xsl:element>
        </xsl:if>
        <xsl:element name="br"/>
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
        <xsl:apply-templates select=".//tei:seg[@rend] | .//tei:measure[@type='expense' or ancestor::tei:seg/@type='accounting'][not(@rend='inline')] | .//tei:lb | .//tei:pb" mode="#current">
            <xsl:with-param name="counter">
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
        <xsl:apply-templates select=".//tei:seg[@rend] | .//tei:measure[@type='expense' or ancestor::tei:seg/@type='accounting'][not(@rend='inline')][not(ancestor::tei:seg[@rend])] | .//tei:lb | .//tei:pb" mode="#current">
            <xsl:with-param name="counter">
                <xsl:number level="any"/>
            </xsl:with-param>
        </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="tei:measure[@type='expense' or ancestor::tei:seg/@type='accounting'][not(@rend='inline')]" priority="0.5" mode="rightTableColumn">
        <xsl:param name="counter"/>
        <xsl:element name="span">
            <xsl:attribute name="class">
                <xsl:value-of select="concat('payment_',$counter)"/>
                <xsl:value-of select="concat(' ', @unit)"/>
                <xsl:if test="ancestor::tei:del">
                    <xsl:value-of select="' tei_del'"/>
                </xsl:if>
            </xsl:attribute>
            <xsl:apply-templates mode="#default"/>
            <!-- Wenn kein Währungssymbol angegeben ist, setzen wir eins hinzu -->
            <xsl:copy-of select="wega:addCurrencySymbolIfNecessary(.)"/>
        </xsl:element>
    </xsl:template>
    
    <!-- suppress all other content -->
    <xsl:template match="*" mode="rightTableColumn"/>
    
</xsl:stylesheet>