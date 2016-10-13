<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/1999/xhtml" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:wega="http://xquery.weber-gesamtausgabe.de/webapp/functions/utilities" exclude-result-prefixes="xs" version="2.0">
   
   <xsl:template name="createApparatus">
      <xsl:element name="div">
         <xsl:attribute name="class">apparatus</xsl:attribute>
         <xsl:if test="wega:isNews($docID)">
            <xsl:attribute name="style">display:none</xsl:attribute>
         </xsl:if>
         <xsl:element name="h3">
            <xsl:attribute name="class">media-heading</xsl:attribute>
            <xsl:value-of select="wega:getLanguageString('textConstitution', $lang)"/>
         </xsl:element>
         <xsl:element name="ul">
            <xsl:attribute name="class">textConstitution</xsl:attribute>
            <xsl:for-each select=".//tei:subst | .//tei:add[not(parent::tei:subst)] | .//tei:gap[not(@reason='outOfScope')] | .//tei:sic[not(parent::tei:choice)] | .//tei:del[not(parent::tei:subst)] | .//tei:unclear[not(parent::tei:choice)]">
               <xsl:element name="li">
                  <xsl:apply-templates select="." mode="apparatus"/>
               </xsl:element>
            </xsl:for-each>
         </xsl:element>
         <xsl:element name="h3">
            <xsl:attribute name="class">media-heading</xsl:attribute>
            <xsl:value-of select="wega:getLanguageString('commentary', $lang)"/>
         </xsl:element>
         <xsl:element name="ul">
            <xsl:attribute name="class">commentary</xsl:attribute>
            <xsl:for-each select=".//tei:app | .//tei:note | .//tei:choice">
               <xsl:element name="li">
                  <xsl:apply-templates select="." mode="apparatus"/>
               </xsl:element>
            </xsl:for-each>
         </xsl:element>
      </xsl:element>
   </xsl:template>
   
   <xsl:template match="tei:note[@type=('definition', 'commentary', 'textConst')]">
      <xsl:call-template name="popover"/>
   </xsl:template>
   
   <xsl:template match="tei:note" mode="apparatus">
      <xsl:variable name="id" select="wega:createID(.)"/>
      <xsl:element name="div">
         <xsl:attribute name="class">apparatusEntry</xsl:attribute>
         <xsl:attribute name="id" select="$id"/>
         <xsl:attribute name="data-title">
            <xsl:value-of select="local-name()"/>
            <xsl:if test="self::tei:note">
               <xsl:text> </xsl:text>
               <xsl:value-of select="@type"/>
            </xsl:if>
         </xsl:attribute>
         <xsl:choose>
            <xsl:when test="preceding::tei:ptr[@target=concat('#', $id)]">
               <!-- When ein ptr existiert, dann wird dieser ausgewertet -->
               <xsl:apply-templates select="preceding::tei:ptr[@target=concat('#', $id)]" mode="apparatus"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:variable name="textTokens" select="tokenize(string-join(preceding-sibling::text() | preceding-sibling::tei:*//text(), ' '), '\s+')"/>
               <!-- Ansonsten werden die letzten fünf Wörter vor der note als Lemma gewählt -->
               <xsl:element name="span">
                  <xsl:attribute name="class" select="'tei_lemma'"/>
                  <xsl:text>"… </xsl:text>
                  <xsl:value-of select="subsequence($textTokens, count($textTokens) - 4)"/>
                  <xsl:text>": </xsl:text>
               </xsl:element>
            </xsl:otherwise>
         </xsl:choose>
         <xsl:apply-templates/>
      </xsl:element>
   </xsl:template>
   
   <xsl:template match="tei:ptr" mode="apparatus">
      <!-- Thanks to Dimitre Novatchev! http://stackoverflow.com/questions/2694825/how-do-i-select-all-text-nodes-between-two-elements-using-xsl -->
      <xsl:variable name="noteID" select="substring(@target, 2)"/>
      <xsl:variable name="vtextPostPtr" select="following::text()"/>
      <xsl:variable name="vtextPreNote" select="//tei:note[@xml:id=$noteID]/preceding::text()"/>
      <xsl:variable name="textTokensBetween" select="tokenize(string-join($vtextPostPtr[count(.|$vtextPreNote) = count($vtextPreNote)], ' '), '\s+')"/>
      <xsl:text>"</xsl:text>
      <xsl:element name="span">
         <xsl:attribute name="class" select="'tei_lemma'"/>
         <xsl:choose>
            <xsl:when test="count($textTokensBetween) gt 6">
               <xsl:value-of select="string-join(subsequence($textTokensBetween, 1, 3), ' ')"/>
               <xsl:text> … </xsl:text>
               <xsl:value-of select="string-join(subsequence($textTokensBetween, count($textTokensBetween) -2, 3), ' ')"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:value-of select="string-join($textTokensBetween, ' ')"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:element>
      <xsl:text>": </xsl:text>
   </xsl:template>
   
   <xsl:template match="tei:subst">
      <xsl:element name="span">
         <xsl:apply-templates select="@xml:id"/>
         <xsl:attribute name="class" select="'tei_subst'"/>
         <!-- Need to take care of whitespace when there are multiple <add> -->
         <xsl:choose>
            <xsl:when test="count(tei:add) gt 1">
               <xsl:apply-templates select="tei:add | text()" mode="#current"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:apply-templates select="tei:add" mode="#current"/>
            </xsl:otherwise>
         </xsl:choose>
         <xsl:call-template name="popover"/>
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
         <!-- Need to take care of whitespace when there are multiple <add> -->
         <xsl:choose>
            <xsl:when test="count(tei:add) gt 1">
               <xsl:apply-templates select="tei:add | text()" mode="plain-text-output"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:apply-templates select="tei:add" mode="plain-text-output"/>
            </xsl:otherwise>
         </xsl:choose>
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
            </xsl:element>-->
      </xsl:element>
   </xsl:template>
   
   <xsl:template match="tei:app">
      <xsl:element name="span">
         <xsl:apply-templates select="@xml:id"/>
         <xsl:attribute name="class">
            <xsl:text>tei_app</xsl:text>
         </xsl:attribute>
         <xsl:apply-templates select="tei:lem" mode="#current"/>
         <xsl:call-template name="popover"/>
      </xsl:element>
   </xsl:template>
   
   <xsl:template match="tei:app" mode="apparatus">
      <xsl:element name="div">
         <xsl:attribute name="class">apparatusEntry</xsl:attribute>
         <xsl:attribute name="id" select="wega:createID(.)"/>
         <xsl:attribute name="data-title">
            <xsl:value-of select="local-name()"/>
         </xsl:attribute>
         <xsl:text>"</xsl:text>
         <xsl:value-of select="tei:lem"/>
         <xsl:text>": </xsl:text>
         <xsl:value-of select="wega:getLanguageString('appRdg', $lang)"/>
         <xsl:text>: </xsl:text>
         <xsl:variable name="rdg">
            <xsl:apply-templates select="tei:rdg"/>
         </xsl:variable>
         <xsl:call-template name="remove-by-class">
            <xsl:with-param name="nodes" select="$rdg"/>
         </xsl:call-template>
      </xsl:element>
   </xsl:template>
   
   <xsl:template match="tei:add[not(parent::tei:subst)]">
      <xsl:element name="span">
         <xsl:apply-templates select="@xml:id"/>
         <xsl:attribute name="class">
            <xsl:text>tei_add</xsl:text>
            <xsl:choose>
               <xsl:when test="@place='above'">
                  <xsl:text> tei_hi_superscript</xsl:text>
               </xsl:when>
               <xsl:when test="@place='below'">
                  <xsl:text> tei_hi_subscript</xsl:text>
               </xsl:when>
               <!--<xsl:when test="./tei:add[@place='margin']">
                        <xsl:text>Ersetzung am Rand. </xsl:text>
                    </xsl:when>-->
               <!--<xsl:when test="./tei:add[@place='mixed']">
                        <xsl:text>Ersetzung an mehreren Stellen. </xsl:text>
                        </xsl:when>-->
            </xsl:choose>
         </xsl:attribute>
         <xsl:apply-templates/>
         <xsl:call-template name="popover"/>
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
               <xsl:value-of select="string-join(subsequence($tokens, count($tokens) -2, 3), ' ')"/>
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
            <xsl:otherwise>
               <xsl:value-of select="wega:getLanguageString('addDefault', $lang)"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:element>
   </xsl:template>
   
   <xsl:template match="tei:unclear[not(parent::tei:choice)]">
      <xsl:element name="span">
         <xsl:apply-templates select="@xml:id"/>
         <xsl:attribute name="class">
            <xsl:text>tei_add</xsl:text>
         </xsl:attribute>
         <xsl:apply-templates/>
         <xsl:call-template name="popover"/>
      </xsl:element>
   </xsl:template>
   
   <xsl:template match="tei:unclear[not(parent::tei:choice)]" mode="apparatus">
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
               <xsl:value-of select="string-join(subsequence($tokens, count($tokens) -2, 3), ' ')"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:value-of select="$addedText"/>
            </xsl:otherwise>
         </xsl:choose>
         <xsl:text>": </xsl:text>
         <xsl:value-of select="wega:getLanguageString('unclearDefault', $lang)"/>
      </xsl:element>
   </xsl:template>
   
   <!--<xsl:template match="tei:gap[@reason='outOfScope']">
      <xsl:element name="span">
         <xsl:attribute name="class" select="'tei_supplied'"/>
         <xsl:text> […] </xsl:text>
      </xsl:element>
   </xsl:template>-->
   
   <!-- gap in damage, del, add und unclear?!? -->
   <xsl:template match="tei:gap">
      <xsl:element name="span">
         <xsl:text> […]</xsl:text>
         <xsl:if test="not(@reason='outOfScope' or parent::tei:del)">
            <xsl:call-template name="popover"/>
         </xsl:if>
      </xsl:element>
   </xsl:template>
   
   <xsl:template match="tei:gap" mode="apparatus">
      <xsl:element name="div">
         <xsl:attribute name="class">apparatusEntry</xsl:attribute>
         <xsl:attribute name="id" select="wega:createID(.)"/>
         <xsl:attribute name="data-title">
            <xsl:value-of select="local-name()"/>
            <xsl:text> </xsl:text>
            <xsl:value-of select="@reason"/>
         </xsl:attribute>
         <xsl:text> </xsl:text>
         <xsl:value-of select="wega:getLanguageString('gapDefault', $lang)"/>
         <xsl:text> </xsl:text>
         <xsl:if test="@unit and @quantity">
            <xsl:text>(ca. </xsl:text>
            <xsl:value-of select="@quantity"/>
            <xsl:text> </xsl:text>
            <xsl:value-of select="@unit"/>
            <xsl:text>)</xsl:text>
         </xsl:if>
      </xsl:element>
   </xsl:template>
   
   <xsl:template match="tei:choice">
      <xsl:element name="span">
         <xsl:apply-templates select="@xml:id"/>
         <xsl:attribute name="class" select="'tei_choice'"/>
         <xsl:choose>
            <xsl:when test="tei:sic">
               <xsl:apply-templates select="tei:corr" mode="#current"/>
            </xsl:when>
            <xsl:when test="tei:unclear">
               <xsl:variable name="opts" as="element()*">
                  <xsl:perform-sort select="tei:unclear">
                     <xsl:sort select="$sort-order[. = current()/string(@cert)]/@sort"/>
                  </xsl:perform-sort>
               </xsl:variable>
               <xsl:apply-templates select="$opts[1]"/>
            </xsl:when>
            <xsl:when test="tei:abbr">
               <xsl:apply-templates select="tei:abbr"/>
            </xsl:when>
         </xsl:choose>
         <xsl:call-template name="popover"/>
      </xsl:element>
   </xsl:template>
   
   <xsl:template match="tei:choice" mode="apparatus">
      <xsl:element name="div">
         <xsl:attribute name="class">apparatusEntry</xsl:attribute>
         <xsl:attribute name="id" select="wega:createID(.)"/>
         <xsl:attribute name="data-title">
            <xsl:value-of select="local-name()"/>
         </xsl:attribute>
         <xsl:choose>
            <xsl:when test="tei:sic">
               <xsl:text>recte "</xsl:text>
               <xsl:value-of select="tei:corr"/>
               <xsl:text>": eigentlich "</xsl:text>
               <xsl:value-of select="tei:sic"/>
               <xsl:text>"</xsl:text>
            </xsl:when>
            <xsl:when test="tei:unclear">
               <xsl:variable name="opts" as="element()*">
                  <xsl:perform-sort select="tei:unclear">
                     <xsl:sort select="$sort-order[. = current()/string(@cert)]/@sort"/>
                  </xsl:perform-sort>
               </xsl:variable>
               <xsl:text>"</xsl:text>
               <xsl:value-of select="$opts[1]"/>
               <xsl:text>": </xsl:text>
               <xsl:value-of select="wega:getLanguageString('choiceUnclear', $lang)"/>
               <xsl:text>: "</xsl:text>
               <!-- Eventuell noch @cert mit ausgeben?!? -->
               <xsl:value-of select="string-join(subsequence($opts, 2), '&#34;, &#34;')"/>
               <xsl:text>"</xsl:text>
            </xsl:when>
            <xsl:when test="tei:abbr">
               <xsl:text>"</xsl:text>
               <xsl:value-of select="tei:abbr"/>
               <xsl:text>": </xsl:text>
               <xsl:value-of select="wega:getLanguageString('choiceAbbr', $lang)"/>
               <xsl:text> "</xsl:text>
               <xsl:value-of select="tei:expan"/>
               <xsl:text>"</xsl:text>
            </xsl:when>
         </xsl:choose>
      </xsl:element>
   </xsl:template>
   
   <xsl:template match="tei:sic[not(parent::tei:choice)] | tei:del[not(parent::tei:subst)]">
      <xsl:element name="span">
         <xsl:apply-templates select="@xml:id"/>
         <xsl:attribute name="class" select="concat('tei_', local-name())"/>
         <xsl:apply-templates mode="#current"/>
         <xsl:call-template name="popover"/>
      </xsl:element>
   </xsl:template>
   
   <xsl:template match="tei:supplied">
      <xsl:element name="span">
         <xsl:attribute name="class" select="concat('tei_', local-name())"/>
         <xsl:attribute name="id" select="wega:createID(.)"/>
         <xsl:text>[</xsl:text>
         <xsl:apply-templates mode="#current"/>
         <xsl:text>]</xsl:text>
      </xsl:element>
   </xsl:template>
   
   <xsl:template match="tei:sic[not(parent::tei:choice)]" mode="apparatus">
      <xsl:element name="div">
         <xsl:attribute name="class">apparatusEntry</xsl:attribute>
         <xsl:attribute name="id" select="wega:createID(.)"/>
         <xsl:attribute name="data-title">
            <xsl:value-of select="local-name()"/>
         </xsl:attribute>
         <xsl:text>"</xsl:text>
         <xsl:apply-templates mode="plain-text-output"/>
         <xsl:text>": sic!</xsl:text>
      </xsl:element>
   </xsl:template>
   
   <!--<xsl:template match="tei:supplied" mode="apparatus">
      <xsl:element name="div">
         <xsl:attribute name="class">apparatusEntry</xsl:attribute>
         <xsl:attribute name="id" select="wega:createID(.)"/>
         <xsl:attribute name="data-title">
            <xsl:value-of select="local-name()"/>
         </xsl:attribute>
         <xsl:text>"</xsl:text>
         <xsl:apply-templates/>
         <xsl:text>": Hinzufügung des Herausgebers</xsl:text>
      </xsl:element>
   </xsl:template>-->
   
   <xsl:template match="tei:del[not(parent::tei:subst)]" mode="apparatus">
      <xsl:element name="div">
         <xsl:attribute name="class">apparatusEntry</xsl:attribute>
         <xsl:attribute name="id" select="wega:createID(.)"/>
         <xsl:attribute name="data-title">
            <xsl:value-of select="local-name()"/>
         </xsl:attribute>
         <xsl:text>"</xsl:text>
         <xsl:apply-templates mode="plain-text-output"/>
         <xsl:text>": </xsl:text>
         <xsl:choose>
            <xsl:when test="tei:gap">
               <xsl:value-of select="wega:getLanguageString('delGap', $lang)"/>
            </xsl:when>
            <xsl:when test="@rend='strikethrough'">
               <xsl:value-of select="wega:getLanguageString('delStrikethrough', $lang)"/>
            </xsl:when>
            <xsl:when test="@rend='overwritten'">
               <xsl:value-of select="wega:getLanguageString('delOverwritten', $lang)"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:value-of select="@rend"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:element>
   </xsl:template>
    
   <xsl:template match="tei:del" mode="plain-text-output"/>
   <xsl:template match="tei:note" mode="plain-text-output"/>
   <xsl:template match="tei:lb" mode="plain-text-output">
      <xsl:text> </xsl:text>
   </xsl:template>
   <xsl:template match="tei:q" mode="plain-text-output">
      <xsl:text>"</xsl:text>
      <xsl:apply-templates mode="#current"/>
      <xsl:text>"</xsl:text>
   </xsl:template>
   <xsl:template match="tei:*" mode="plain-text-output">
      <xsl:apply-templates mode="#current"/>
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
   
   <xsl:variable name="sort-order" as="element()+">
      <cert sort="1">high</cert>
      <cert sort="2">medium</cert>
      <cert sort="3">low</cert>
      <cert sort="4">unknown</cert>
      <cert sort="4"/>
   </xsl:variable>
   
</xsl:stylesheet>