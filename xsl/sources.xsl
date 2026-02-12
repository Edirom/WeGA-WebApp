<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:functx="http://www.functx.com" xmlns:rng="http://relaxng.org/ns/structure/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:wega="http://xquery.weber-gesamtausgabe.de/webapp/functions/utilities" version="2.0">
    
    <xsl:output encoding="UTF-8" method="html" omit-xml-declaration="yes" indent="no"/>
    <xsl:strip-space elements="*"/>
    <xsl:preserve-space elements="tei:q tei:quote tei:item tei:cell tei:p tei:dateline          tei:closer tei:opener tei:hi tei:persName tei:rs tei:workName          tei:characterName tei:placeName tei:seg tei:footNote tei:head tei:date          tei:orgName tei:note tei:lem tei:rdg tei:add tei:provenance          tei:acquisition tei:damage"/>
    
    <xsl:param name="headerMode" select="false()"/>
    
    <xsl:include href="common_main.xsl"/>
    <xsl:include href="common_link.xsl"/>
    <xsl:include href="apparatus.xsl"/>
    
    <xsl:template match="/">
        <xsl:choose>
            <xsl:when test="$headerMode">
                <xsl:element name="div">
                    <xsl:apply-templates mode="header" select=".//tei:title[@level='a']"/>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="tei:title[@level='a']" mode="header" priority="0.5">
        <xsl:element name="h1">
            <xsl:apply-templates mode="#default"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:title[@level='a'][@type='sub']" mode="header" priority="0.7">
        <xsl:element name="h2">
            <xsl:apply-templates mode="#default"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:text">
        <xsl:element name="div">
            <xsl:attribute name="class" select="'teiSrc_text'"/>
            <xsl:apply-templates select="./tei:front"/>
            <xsl:apply-templates select="./tei:body"/>
        </xsl:element>
        <xsl:call-template name="createApparatus"/>
    </xsl:template>
    
    <xsl:template match="tei:front">
        <xsl:element name="div">
            <xsl:attribute name="class" select="'teiSrc_front'"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:body">
        <xsl:element name="div">
            <xsl:attribute name="class" select="'teiSrc_body'"/>
            <xsl:apply-templates select="./tei:div"/>
            <xsl:if test=".//tei:footNote">
                <xsl:call-template name="createEndnotes"/>
            </xsl:if>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:div">
        <xsl:element name="div">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="class" select="'srcPart'"/>
            <xsl:apply-templates/>
            <!--<xsl:if test="not(following-sibling::tei:div)">
                <xsl:element name="p">
                    <xsl:attribute name="class" select="'clearer'"/>
                </xsl:element>
            </xsl:if>-->
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:head[parent::tei:div]" priority="1">
        <xsl:variable name="minHeadLevel" as="xs:integer" select="2"/>
        <xsl:variable name="increments" as="xs:integer">
            <!-- Wenn es ein Untertitel ist wird der Level hochgezählt -->
            <xsl:value-of select="count(.[@type='sub'])"/>
        </xsl:variable>
        <xsl:variable name="parentDiv" select="parent::tei:div"/>
        <xsl:variable name="parentDivType" select="string($parentDiv/@type)"/>
        <xsl:variable name="act" select="string($parentDiv/ancestor-or-self::tei:div[@type='act'][1]/@n)"/>
        <xsl:variable name="scene" select="string($parentDiv/ancestor-or-self::tei:div[@type='scene'][1]/@n)"/>
        <xsl:variable name="anchorId" select="if ($parentDivType = 'act') then concat('act-', $act) else if ($parentDivType = 'scene') then concat('act-', $act, '-scene-', $scene) else () "/>
        <xsl:element name="{concat('h', $minHeadLevel + $increments)}">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:attribute name="id" select="$anchorId"/>
            <xsl:attribute name="class" select="string-join(('srcHeader', concat('header-level-', if($parentDivType) then $parentDivType else 'generic')), ' ')"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <!-- overwrite common_main behaviour -->
    <xsl:template match="tei:pb" priority="1">
        <xsl:variable name="label" as="xs:string">
            <xsl:choose>
                <xsl:when test="@n">
                    <xsl:value-of select="concat(wega:getLanguageString('pageBreakTo', $lang), ' ', wega:getLanguageString('pp', $lang), ' ', @n)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="wega:getLanguageString('pageBreak', $lang)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <hr class="tei_pb-text" title="{$label}" data-content="{$label}">
            <xsl:if test="@facs">
                <xsl:attribute name="data-facs" select="substring(@facs, 2)"/>
            </xsl:if>
        </hr>
    </xsl:template>
    
</xsl:stylesheet>
