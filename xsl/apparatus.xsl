<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" 
   xmlns="http://www.w3.org/1999/xhtml"
   xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:wega="http://xquery.weber-gesamtausgabe.de/webapp/functions/utilities"
   exclude-result-prefixes="xs" version="2.0">
   
   <xsl:template name="createApparatus">
      <xsl:element name="div">
         <xsl:attribute name="class">apparatus</xsl:attribute>
         <xsl:apply-templates select=".//tei:app | .//tei:subst | .//tei:note | .//tei:add[not(parent::tei:subst)]" mode="apparatus"/>
      </xsl:element>
   </xsl:template>
   
   <xsl:template match="tei:note" mode="apparatus">
      <xsl:element name="div">
         <xsl:attribute name="class">apparatusEntry</xsl:attribute>
         <xsl:attribute name="id" select="wega:createID(.)"/>
         <xsl:attribute name="data-title">
            <xsl:value-of select="local-name()"/>
            <xsl:if test="self::tei:note">
               <xsl:text> </xsl:text>
               <xsl:value-of select="@type"/>
            </xsl:if>
         </xsl:attribute>
         <xsl:apply-templates/>
      </xsl:element>
   </xsl:template>
   
   <xsl:template match="tei:subst" mode="apparatus">
      <xsl:element name="div">
         <xsl:attribute name="class">apparatusEntry</xsl:attribute>
         <xsl:attribute name="id" select="wega:createID(.)"/>
         <xsl:attribute name="data-title">
            <xsl:value-of select="local-name()"/>
         </xsl:attribute>
         <xsl:text>"</xsl:text>
         <xsl:apply-templates select="tei:add | text()"/>
         <xsl:text>": </xsl:text>
         <xsl:choose>
            <xsl:when test="./tei:del/tei:gap">
               <xsl:value-of select="wega:getLanguageString('delGap', $lang)"/>
            </xsl:when>
            <xsl:when test="./tei:del[@rend='strikethrough']">
               <xsl:value-of select="concat('&#34;', normalize-space(./tei:del[1]), '&#34;')"/>
               <xsl:value-of select="wega:getLanguageString('delStrikethrough', $lang)"/>
            </xsl:when>
            <xsl:when test="./tei:del[@rend='overwritten']">
               <xsl:value-of select="concat('&#34;', normalize-space(./tei:del[1]), '&#34;')"/>
               <xsl:value-of select="wega:getLanguageString('delOverwritten', $lang)"/>
            </xsl:when>
         </xsl:choose>
         <!--<xsl:element name="span">
                <xsl:attribute name="class" select="'teiLetter_noteInline'"/>
                <xsl:attribute name="id">
                    <xsl:value-of select="concat('subst_',$substInlineID)"/>
                </xsl:attribute>
                <xsl:choose>
                    <xsl:when test="./tei:add[@place='inline']">
                        <xsl:value-of select="wega:getLanguageString('substInline', $lang)"/>
                    </xsl:when>
                    <xsl:when test="./tei:add[@place='above']">
                        <xsl:value-of select="wega:getLanguageString('substAbove', $lang)"/>
                    </xsl:when>
                    <xsl:when test="./tei:add[@place='below']">
                        <xsl:value-of select="wega:getLanguageString('substBelow', $lang)"/>
                    </xsl:when>
                    <xsl:when test="./tei:add[@place='margin']">
                        <xsl:value-of select="wega:getLanguageString('substMargin', $lang)"/>
                    </xsl:when>
                    <xsl:when test="./tei:add[@place='mixed']">
                        <xsl:value-of select="wega:getLanguageString('substMixed', $lang)"/>
                    </xsl:when>
                </xsl:choose>
                <xsl:choose>
                    <xsl:when test="./tei:del/tei:gap">
                        <xsl:value-of select="wega:getLanguageString('delGap', $lang)"/>
                    </xsl:when>
                    <xsl:when test="./tei:del[@rend='strikethrough']">
                        <xsl:value-of select="concat('&#34;', normalize-space(./tei:del[1]), '&#34;')"/>
                        <xsl:value-of select="wega:getLanguageString('delStrikethrough', $lang)"/>
                    </xsl:when>
                    <xsl:when test="./tei:del[@rend='overwritten']">
                        <xsl:value-of select="concat('&#34;', normalize-space(./tei:del[1]), '&#34;')"/>
                        <xsl:value-of select="wega:getLanguageString('delOverwritten', $lang)"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:element>-->
      </xsl:element>
   </xsl:template>
   
   <xsl:template match="tei:app" mode="apparatus">
      <xsl:element name="div">
         <xsl:attribute name="class">apparatusEntry</xsl:attribute>
         <xsl:attribute name="id" select="wega:createID(.)"/>
         <xsl:attribute name="data-title">
            <xsl:value-of select="local-name()"/>
         </xsl:attribute>
         <xsl:text> some apparatus entry </xsl:text>
      </xsl:element>
   </xsl:template>
   
   <xsl:template match="tei:add[not(parent::tei:subst)]" mode="apparatus">
      <xsl:variable name="addedText">
         <xsl:apply-templates/>
      </xsl:variable>
      <xsl:variable name="tokens" select="tokenize($addedText, '\s+')"/>
      <xsl:element name="div">
         <xsl:attribute name="class">apparatusEntry</xsl:attribute>
         <xsl:attribute name="id" select="wega:createID(.)"/>
         <xsl:attribute name="data-title">
            <xsl:value-of select="local-name()"/>
         </xsl:attribute>
         <xsl:text>"</xsl:text>
         <xsl:choose>
            <xsl:when test="count($tokens) gt 6">
               <xsl:value-of select="string-join(subsequence($tokens, 1, 3), ' ')"/>
               <xsl:text> … </xsl:text>
               <xsl:value-of select="string-join(subsequence($tokens, count($tokens) -3, 3), ' ')"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:value-of select="$addedText"/>
            </xsl:otherwise>
         </xsl:choose>
         <xsl:text>": </xsl:text>
         <xsl:choose>
            <xsl:when test="@place='margin'">
               <xsl:value-of select="wega:getLanguageString('addMargin', $lang)"/>
            </xsl:when>
            <xsl:when test="@place='inline'">
               <xsl:value-of select="wega:getLanguageString('addInline', $lang)"/>
            </xsl:when>
            <!-- TODO translate -->
            <xsl:otherwise>Hinzufügung</xsl:otherwise>
         </xsl:choose>
      </xsl:element>
   </xsl:template>
   
   <xsl:function name="wega:createID">
      <xsl:param name="elem" as="element()"/>
      <xsl:choose>
         <xsl:when test="$elem/@xml:id">
            <xsl:value-of select="$elem/@xml:id"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:value-of select="generate-id($elem)"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
</xsl:stylesheet>