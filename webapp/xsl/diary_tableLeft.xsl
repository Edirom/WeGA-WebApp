<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:wega="http://xquery.weber-gesamtausgabe.de/webapp/functions/utilities"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:rng="http://relaxng.org/ns/structure/1.0"
    version="2.0">
    <xsl:output encoding="UTF-8" method="html" omit-xml-declaration="yes" indent="no"/>
    <xsl:strip-space elements="*"/>
    <xsl:preserve-space
        elements="tei:seg tei:hi tei:ab tei:persName tei:rs tei:workName tei:characterName tei:placeName tei:date tei:add tei:head"/>
    <xsl:include href="common_link.xsl"/>
    <xsl:include href="common_main.xsl"/>
    <!-- <xsl:param name="pageBreak"/> -->
    <xsl:template match="tei:ab">
        <xsl:element name="div">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class" select="'tableLeft'"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="tei:pb" priority="1">
        <xsl:element name="span">
            <xsl:attribute name="class" select="'tei_pb'"/>
            <xsl:value-of select="wega:getLanguageString('pageBreak', $lang)"/>
            <!-- <xsl:text>Seitenumbruch</xsl:text> -->
        </xsl:element>
    </xsl:template>
    <xsl:template match="tei:date">
        <xsl:element name="span">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class" select="'date'"/>
            <xsl:apply-templates/>
        </xsl:element>
        <xsl:text> </xsl:text>
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
                <!--<xsl:attribute name="onmouseover">
<!-\-                    <xsl:text>this.style.cursor='pointer'</xsl:text>-\->
                    <xsl:value-of select='concat("highlightRow('", $divId, "', '", $cssClass, "')")'/>
                </xsl:attribute>-->
                <!--<xsl:attribute name="onclick">
                    <xsl:text>highlightSpanClassInText('</xsl:text>
                    <xsl:value-of select="concat('payment_',$counter)"/>
                    <xsl:text>')</xsl:text>
                </xsl:attribute>-->
            </xsl:if>
            <xsl:apply-templates/>
        </xsl:element>
        <xsl:text> </xsl:text>
    </xsl:template>
    <xsl:template match="tei:measure[@type='expense']" priority="0.5"/>
    <xsl:template match="tei:measure[@rend='inline' or @type='income' or @type='rebooking']"
        priority="1">
        <xsl:variable name="counter">
            <xsl:number level="any"/>
        </xsl:variable>
        <xsl:element name="span">
            <xsl:attribute name="class" select="concat(@type,$counter)"/>
            <xsl:apply-templates/>
            <!-- Wenn kein Währungssymbol angegeben ist, setzen wir eins hinzu -->
            <xsl:call-template name="addCurrencySymbolIfNecessary">
                <xsl:with-param name="node" select="."/>
            </xsl:call-template>
        </xsl:element>
    </xsl:template>
</xsl:stylesheet>
