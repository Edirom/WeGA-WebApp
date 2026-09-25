<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:wega="http://xquery.weber-gesamtausgabe.de/webapp/functions/utilities"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="tei wega xs"
    version="2.0">

    <xsl:output encoding="UTF-8" method="html" omit-xml-declaration="yes" indent="no"/>
    <xsl:strip-space elements="*"/>
    <xsl:preserve-space elements="tei:q tei:quote tei:item tei:cell tei:p tei:dateline
        tei:closer tei:opener tei:hi tei:persName tei:rs tei:workName
        tei:characterName tei:placeName tei:seg tei:footNote tei:head tei:date
        tei:orgName tei:note tei:lem tei:rdg tei:add tei:provenance
        tei:acquisition tei:damage tei:l tei:speaker tei:stage tei:caption
        tei:role tei:roleDesc tei:subst tei:del"/>

    <xsl:include href="common_main.xsl"/>
    <xsl:include href="common_link.xsl"/>
    <xsl:include href="apparatus.xsl"/>

    <xsl:function name="wega:source-toc-label" as="xs:string">
        <xsl:param name="head" as="element(tei:head)"/>
        <xsl:variable name="label">
            <xsl:apply-templates select="$head/node()" mode="source-toc-label"/>
        </xsl:variable>
        <xsl:sequence select="normalize-space(string($label))"/>
    </xsl:function>

    <xsl:function name="wega:source-toc-head" as="element(tei:head)?">
        <xsl:param name="container" as="element()"/>
        <xsl:sequence select="$container/tei:head[not(@type = 'sub')][wega:source-toc-label(.) != ''][1]"/>
    </xsl:function>

    <xsl:function name="wega:is-source-toc-container" as="xs:boolean">
        <xsl:param name="container" as="element()"/>
        <xsl:sequence select="
            $container/self::tei:div
            and not($container/ancestor::*
                [self::tei:castList or self::tei:note or self::tei:footNote or self::tei:app])
            and exists(wega:source-toc-head($container))
            and exists($container/*[not(self::tei:head)] | $container/text()[normalize-space()])"/>
    </xsl:function>

    <xsl:function name="wega:has-source-toc" as="xs:boolean">
        <xsl:param name="context" as="node()"/>
        <xsl:sequence select="count(
            $context/ancestor-or-self::tei:text[1]
                //tei:div[wega:is-source-toc-container(.)]
            ) gt 1"/>
    </xsl:function>

    <xsl:function name="wega:source-toc-id" as="xs:string">
        <xsl:param name="container" as="element()"/>
        <xsl:variable name="head" select="wega:source-toc-head($container)"/>
        <xsl:variable name="existingId" select="($head/@xml:id, $container/@xml:id)[1]"/>
        <xsl:sequence select="
            if($existingId) then string($existingId)
            else generate-id($head)"/>
    </xsl:function>

    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="tei:text">
        <div class="teiSrc_text">
            <xsl:apply-templates/>
        </div>
        <xsl:if test="wega:has-source-toc(.)">
            <nav class="source-toc" aria-label="{wega:getLanguageString('toc', $lang)}">
                <ul>
                    <xsl:apply-templates select="node()" mode="source-toc"/>
                </ul>
            </nav>
        </xsl:if>
        <xsl:call-template name="createApparatus"/>
    </xsl:template>

    <xsl:template match="tei:front">
        <div class="teiSrc_front">
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="tei:body">
        <div class="teiSrc_body">
            <xsl:apply-templates/>
            <xsl:if test=".//tei:footNote">
                <xsl:call-template name="createEndnotes"/>
            </xsl:if>
        </div>
    </xsl:template>

    <xsl:template match="tei:div">
        <div class="srcPart">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="tei:head[parent::tei:div]" priority="1">
        <xsl:variable name="container" select="parent::tei:div"/>
        <xsl:element name="{if (@type = 'sub') then 'h3' else 'h2'}">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:if test="wega:has-source-toc($container)
                    and wega:is-source-toc-container($container)
                    and . is wega:source-toc-head($container)
                    and not(@xml:id or $container/@xml:id)">
                <xsl:attribute name="id" select="wega:source-toc-id($container)"/>
            </xsl:if>
            <xsl:attribute name="class" select="'srcHeader'"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="text()" mode="source-toc-label" priority="2">
        <xsl:value-of select="."/>
    </xsl:template>

    <xsl:template match="tei:lb" mode="source-toc-label" priority="3">
        <xsl:text> </xsl:text>
    </xsl:template>

    <xsl:template match="tei:note | tei:footNote | tei:app | tei:del" mode="source-toc-label" priority="3"/>

    <xsl:template match="tei:subst" mode="source-toc-label" priority="3">
        <xsl:apply-templates select="(tei:add, tei:del)[1]/node()" mode="source-toc-label"/>
    </xsl:template>

    <xsl:template match="tei:choice" mode="source-toc-label" priority="3">
        <xsl:apply-templates select="(tei:corr, tei:reg, tei:expan, tei:orig, tei:sic, tei:abbr)[1]/node()" mode="source-toc-label"/>
    </xsl:template>

    <xsl:template match="*" mode="source-toc-label" priority="2">
        <xsl:apply-templates mode="source-toc-label"/>
    </xsl:template>

    <xsl:template match="tei:div" mode="source-toc" priority="3">
        <xsl:choose>
            <xsl:when test="wega:is-source-toc-container(.)">
                <li>
                    <a href="#{wega:source-toc-id(.)}">
                        <xsl:value-of select="wega:source-toc-label(wega:source-toc-head(.))"/>
                    </a>
                    <xsl:if test="descendant::tei:div[wega:is-source-toc-container(.)]">
                        <ul>
                            <xsl:apply-templates mode="source-toc"/>
                        </ul>
                    </xsl:if>
                </li>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates mode="source-toc"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tei:note | tei:footNote | tei:app" mode="source-toc" priority="3"/>

    <xsl:template match="*" mode="source-toc" priority="2">
        <xsl:apply-templates mode="source-toc"/>
    </xsl:template>

    <xsl:template match="text()" mode="source-toc" priority="2"/>

    <xsl:template match="tei:pb" priority="1">
        <xsl:variable name="label" as="xs:string">
            <xsl:choose>
                <xsl:when test="@n">
                    <xsl:choose>
                        <xsl:when test="matches(@n, '[vr]')">
                            <xsl:value-of select="concat(wega:getLanguageString('pageBreakTo', $lang), ' ', wega:getLanguageString('leaf', $lang), '&#160;', @n)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="concat(wega:getLanguageString('pageBreakTo', $lang), ' ', wega:getLanguageString('pp', $lang), '&#160;', @n)"/>
                        </xsl:otherwise>
                    </xsl:choose>
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

    <xsl:template match="tei:lg" priority="1">
        <xsl:variable name="indent-class" as="xs:string?"
            select="if (tokenize(normalize-space(@rend), '\s+') = 'indent' and @n = ('1', '2', '3')) then concat('indent-', @n) else ()"/>
        <span class="{string-join(('lg', $indent-class), ' ')}">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <xsl:template match="tei:l" priority="1">
        <xsl:variable name="indent-class" as="xs:string?"
            select="if (tokenize(normalize-space(@rend), '\s+') = 'indent' and @n = ('1', '2', '3')) then concat('indent-', @n) else ()"/>
        <xsl:variable name="part-class" as="xs:string?"
            select="if (@part) then concat('part-', @part) else ()"/>
        <span class="{string-join(('verseLine', $part-class, $indent-class), ' ')}">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <xsl:template match="tei:sp | tei:spGrp | tei:speaker | tei:stage | tei:caption | tei:castGroup" priority="1">
        <span class="{string-join((
                concat('tei_', local-name()),
                @type,
                @rend), ' ')}">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates/>
        </span>
    </xsl:template>

    <xsl:template match="tei:l/text()[not(normalize-space())]
            | tei:speaker/text()[not(normalize-space())]
            | tei:stage/text()[not(normalize-space())]
            | tei:caption/text()[not(normalize-space())]
            | tei:role/text()[not(normalize-space())]
            | tei:roleDesc/text()[not(normalize-space())]
            | tei:del/text()[not(normalize-space())]" mode="#all" priority="1">
        <xsl:if test="preceding-sibling::* and following-sibling::*">
            <xsl:text> </xsl:text>
        </xsl:if>
    </xsl:template>

    <xsl:template match="tei:subst/text()[not(normalize-space())]" mode="lemma" priority="1">
        <xsl:if test="preceding-sibling::tei:add and following-sibling::tei:add">
            <xsl:text> </xsl:text>
        </xsl:if>
    </xsl:template>

    <xsl:template match="tei:actor[parent::tei:castItem]" priority="1">
        <xsl:variable name="rend-tokens" as="xs:string*"
            select="tokenize(normalize-space(@rend), '\s+')[.]"/>
        <xsl:if test="$rend-tokens = 'leader_dots'">
            <span class="tei_leader_dots"/>
        </xsl:if>
        <span class="{string-join(('tei_actor', $rend-tokens), ' ')}">
            <xsl:apply-templates select="@xml:id"/>
            <xsl:apply-templates/>
        </span>
    </xsl:template>

</xsl:stylesheet>
