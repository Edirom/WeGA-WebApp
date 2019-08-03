<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:functx="http://www.functx.com"
   xmlns:wega="http://xquery.weber-gesamtausgabe.de/webapp/functions/utilities"
   exclude-result-prefixes="xs" version="2.0">

   <!--
      Mode: default (i.e. template rules without a @mode attribute)
      In this mode the default variant (e.g. sic, not corr) will be output and diacritic 
      signs will be added to the text. 
      
      Mode: lemma
      This mode is used for creating lemmata (for notes and apparatus entries, etc.) and will
      be almost plain text, with the exception of html:span for musical symbols and the like.
      
      Mode: apparatus
      This mode is used for outputting the apparatus entries (wiht the variant forms).
   -->
   
   <xsl:template name="createApparatus">
      <xsl:variable name="textConstitutionPath" select=".//tei:subst | .//tei:add[not(parent::tei:subst)] | .//tei:gap[not(@reason='outOfScope' or parent::tei:del)] | .//tei:sic[not(parent::tei:choice)] | .//tei:del[not(parent::tei:subst)] | .//tei:unclear[not(parent::tei:choice)] | .//tei:note[@type='textConst']"/>
      <xsl:variable name="commentaryPath" select=".//tei:note[@type=('commentary', 'definition')] | .//tei:choice"/>
      <xsl:variable name="rdgPath" select=".//tei:app"/>
      <xsl:element name="div">
         <xsl:attribute name="class">apparatus</xsl:attribute>
         <xsl:if test="wega:isNews($docID)">
            <xsl:attribute name="style">display:none</xsl:attribute>
         </xsl:if>
         <xsl:if test="$textConstitutionPath">
            <xsl:element name="h3">
               <xsl:attribute name="class">media-heading</xsl:attribute>
               <span><xsl:value-of select="wega:getLanguageString('textConstitution', $lang)"/></span>
            </xsl:element>
         </xsl:if>
         <xsl:element name="ul">
            <xsl:attribute name="class">apparatus textConstitution</xsl:attribute>
            <xsl:for-each select="$textConstitutionPath">
               <xsl:element name="li">
                  <xsl:element name="div">
                     <xsl:attribute name="class">row</xsl:attribute>
                     <xsl:element name="div">
                        <xsl:attribute name="class">col-xs-1</xsl:attribute>
                        <xsl:element name="a">
                           <xsl:attribute name="href">#transcription</xsl:attribute>
                           <xsl:attribute name="data-href"><xsl:value-of select="concat('#ref-',wega:createID(.))"/></xsl:attribute>
                           <xsl:attribute name="class">apparatus</xsl:attribute>
                           <xsl:number count="tei:subst | tei:add[not(parent::tei:subst)] | tei:gap[not(@reason='outOfScope' or parent::tei:del)] | tei:sic[not(parent::tei:choice)] | tei:del[not(parent::tei:subst)] | tei:unclear[not(parent::tei:choice)] | tei:note[@type='textConst']" level="any"/> <!-- should be in a variable -->
                           <xsl:text>.</xsl:text>
                        </xsl:element>
                     </xsl:element>
                     <xsl:apply-templates select="." mode="apparatus"/>
                  </xsl:element>
               </xsl:element>
            </xsl:for-each>
         </xsl:element>
         <xsl:if test="$commentaryPath">
            <xsl:element name="h3">
               <xsl:attribute name="class">media-heading</xsl:attribute>
               <xsl:value-of select="wega:getLanguageString('note_commentary', $lang)"/>
            </xsl:element>
         </xsl:if>
         <xsl:element name="ul">
            <xsl:attribute name="class">apparatus commentary</xsl:attribute>
            <xsl:for-each select="$commentaryPath">
               <xsl:element name="li">
                  <xsl:element name="div">
                     <xsl:attribute name="class">row</xsl:attribute>
                     <xsl:element name="div">
                        <xsl:attribute name="class">col-xs-1</xsl:attribute>
                        <xsl:element name="a">
                           <xsl:attribute name="href">#transcription</xsl:attribute>
                           <xsl:attribute name="data-href"><xsl:value-of select="concat('#ref-',wega:createID(.))"/></xsl:attribute>
                           <xsl:attribute name="class">apparatus</xsl:attribute>
                           <xsl:text>* </xsl:text>
                           <xsl:number count="tei:note[@type=('commentary', 'definition')] | tei:choice" level="any"/>
                           <xsl:text>.</xsl:text>
                        </xsl:element>
                     </xsl:element>
                     <xsl:apply-templates select="." mode="apparatus"/>
                  </xsl:element>
               </xsl:element>
            </xsl:for-each>
         </xsl:element>
         <xsl:if test="$rdgPath">
            <xsl:element name="h3">
               <xsl:attribute name="class">media-heading</xsl:attribute>
               <xsl:value-of select="wega:getLanguageString('appRdgs', $lang)"/>
            </xsl:element>
         </xsl:if>
         <xsl:element name="ul">
            <xsl:attribute name="class">apparatus rdg</xsl:attribute>
            <xsl:for-each select="$rdgPath">
               <xsl:element name="li">
                  <xsl:element name="div">
                     <xsl:attribute name="class">row</xsl:attribute>
                     <xsl:element name="div">
                        <xsl:attribute name="class">col-xs-1</xsl:attribute>
                        <xsl:element name="a">
                           <xsl:attribute name="href">#transcription</xsl:attribute>
                           <xsl:attribute name="data-href"><xsl:value-of select="concat('#ref-',wega:createID(.))"/></xsl:attribute>
                           <xsl:attribute name="class">apparatus</xsl:attribute>
                           <xsl:text>‡ </xsl:text>
                           <xsl:number level="any"/>
                           <xsl:text>.</xsl:text>
                        </xsl:element>
                     </xsl:element>
                     <xsl:apply-templates select="." mode="apparatus"/>
                  </xsl:element>
               </xsl:element>
            </xsl:for-each>
         </xsl:element>
      </xsl:element>
   </xsl:template>
   
   <xsl:template match="tei:listWit"/> <!-- prevent unintended witness output -->

   <xsl:template match="tei:note[@type=('definition', 'commentary', 'textConst')]">
      <xsl:call-template name="popover"/>
   </xsl:template>
   
   <xsl:template match="tei:note" mode="apparatus">
      <xsl:variable name="id" select="wega:createID(.)"/>
      <xsl:call-template name="apparatusEntry">
         <xsl:with-param name="title" select="wega:getLanguageString(string-join((local-name(),@type), '_'),$lang)"/>
         <xsl:with-param name="lemma">
            <xsl:choose>
               <xsl:when test="preceding::tei:ptr[@target=concat('#', $id)]">
                  <!-- When ein ptr existiert, dann wird dieser ausgewertet -->
                  <xsl:apply-templates select="preceding::tei:ptr[@target=concat('#', $id)]" mode="apparatus"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:variable name="textTokens" select="tokenize(string-join(preceding-sibling::text() | preceding-sibling::tei:*//text(), ' '), '\s+')"/>
                  <!-- Ansonsten werden die letzten fünf Wörter vor der note als Lemma gewählt -->
                  <xsl:sequence select="('… ', subsequence($textTokens, count($textTokens) - 4))"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:with-param>
         <xsl:with-param name="explanation">
            <xsl:apply-templates/>
         </xsl:with-param>
      </xsl:call-template>
   </xsl:template>

   <xsl:template match="tei:ptr" mode="apparatus">
      <!-- Thanks to Dimitre Novatchev! http://stackoverflow.com/questions/2694825/how-do-i-select-all-text-nodes-between-two-elements-using-xsl -->
      <xsl:variable name="noteID" select="substring(@target, 2)"/>
      <xsl:variable name="vtextPostPtr" select="following::text()"/>
      <xsl:variable name="vtextPreNote" select="//tei:note[@xml:id=$noteID]/preceding::text()"/>
      <xsl:variable name="textTokensBetween" select="tokenize(string-join($vtextPostPtr[count(.|$vtextPreNote) = count($vtextPreNote)], ' '), '\s+')"/>
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
   </xsl:template>

   <xsl:template match="tei:subst">
      <xsl:element name="span">
         <xsl:apply-templates select="@xml:id"/>
         <xsl:attribute name="class" select="concat('tei_', local-name())"/>
         <!-- Need to take care of whitespace when there are multiple <add> -->
             <xsl:choose>
                <xsl:when test="count(tei:add) gt 1">
                   <xsl:apply-templates select="tei:add | text()" mode="lemma"/>
                </xsl:when>
                <xsl:otherwise>
                   <xsl:apply-templates select="tei:add" mode="lemma"/>
                </xsl:otherwise>
             </xsl:choose>
         <xsl:call-template name="popover"/>
      </xsl:element>
   </xsl:template>

   <xsl:template match="tei:subst" mode="apparatus">
      <xsl:call-template name="apparatusEntry">
         <xsl:with-param name="title" select="wega:getLanguageString('subst',$lang)"/>
         <xsl:with-param name="lemma">
            <xsl:choose>
               <xsl:when test="count(tei:add) gt 1">
                  <xsl:apply-templates select="tei:add | text()" mode="lemma"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:apply-templates select="tei:add" mode="lemma"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:with-param>
         <xsl:with-param name="explanation">
            <xsl:variable name="processedDel">
               <xsl:apply-templates select="tei:del[1]/node()" mode="lemma"/>
            </xsl:variable>
            <xsl:choose>
               <xsl:when test="tei:del/tei:gap and functx:all-whitespace(string-join(tei:del/text(), ''))">
                  <xsl:value-of select="wega:getLanguageString('delGap', $lang)"/>
               </xsl:when>
               <xsl:when test="tei:del[@rend='strikethrough']">
                  <xsl:sequence select="wega:enquote($processedDel)"/>
                  <xsl:value-of select="wega:getLanguageString('delStrikethrough', $lang)"/>
               </xsl:when>
               <xsl:when test="tei:del[@rend='overwritten']">
                  <xsl:sequence select="wega:enquote($processedDel)"/>
                  <xsl:value-of select="wega:getLanguageString('delOverwritten', $lang)"/>
               </xsl:when>
               <xsl:when test="tei:del[@rend='erased']">
                  <xsl:sequence select="wega:enquote($processedDel)"/>
                  <xsl:value-of select="wega:getLanguageString('delErased', $lang)"/>
               </xsl:when>
            </xsl:choose>
         </xsl:with-param>
      </xsl:call-template>
   </xsl:template>

   <xsl:template match="tei:app">
      <xsl:element name="span">
         <xsl:apply-templates select="@xml:id"/>
         <xsl:attribute name="class" select="concat('tei_', local-name())"/>
         <xsl:apply-templates select="tei:lem" mode="#current"/>
         <xsl:call-template name="popover"/>
      </xsl:element>
   </xsl:template>

   <!-- will be changed in https://github.com/Edirom/WeGA-WebApp/issues/307 -->
   <xsl:template match="tei:app" mode="apparatus">
      <xsl:variable name="counter">
         <xsl:number level="any"/>
      </xsl:variable>
      <xsl:variable name="lemElem" select="tei:lem/descendant::text()"/>
      <xsl:variable name="lemWit" select="tei:rdg/substring-after(@wit,'#')"/>
      <xsl:variable name="witN" select="preceding::tei:witness[@xml:id=$lemWit]/data(@n)"/>
      <xsl:variable name="tokens" select="tokenize(string-join($lemElem, ' '), '\s+')"/>
      <xsl:variable name="qelem">
         <xsl:choose>
            <xsl:when test="count($tokens) gt 6">
               <xsl:value-of select="string-join(subsequence($tokens, 1, 3), ' ')"/>
               <xsl:text> … </xsl:text>
               <xsl:value-of select="string-join(subsequence($tokens, count($tokens) -2, 3), ' ')"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:value-of select="$lemElem"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:element name="div">
         <xsl:attribute name="class">apparatusEntry col-xs-11</xsl:attribute>
         <xsl:attribute name="id" select="wega:createID(.)"/>
         <xsl:attribute name="data-title">
            <xsl:value-of select="wega:getLanguageString('appRdgs',$lang)"/>
         </xsl:attribute>
         <xsl:attribute name="data-counter"><xsl:value-of select="$counter"/></xsl:attribute>
         <xsl:element name="div">
            <strong><xsl:value-of select="concat(wega:getLanguageString('textSource', $lang),' ', '1',': ')"/></strong> <!-- source containing the lemma the first text source by definition' -->
            <xsl:variable name="lemma">
               <xsl:apply-templates select="tei:lem" mode="lemma"/>
            </xsl:variable>
            <xsl:element name="span">
               <!--<xsl:attribute name="class" select="'tei_lemma'"/>-->
               <xsl:sequence select="wega:enquote($lemma)"/>
            </xsl:element>
         </xsl:element>
         <xsl:element name="div">
            <strong><xsl:value-of select="concat(wega:getLanguageString('textSource', $lang),' ', $witN,': ')"/></strong>
            <xsl:variable name="rdg">
               <xsl:apply-templates select="tei:rdg" mode="lemma"/>
            </xsl:variable>
            <xsl:sequence select="wega:enquote($rdg)"/>
         </xsl:element>
      </xsl:element>
   </xsl:template>

   <xsl:template match="tei:rdg">
      <xsl:element name="span">
         <xsl:attribute name="class" select="concat('tei_', local-name())"/>
         <xsl:apply-templates mode="rdg"/>
      </xsl:element>
   </xsl:template>

   <!-- within readings there must not be any paragraphs (in the result HTML) -->
   <xsl:template match="tei:p" mode="rdg">
      <xsl:element name="span">
         <xsl:attribute name="class" select="concat('tei_', local-name())"/>
         <xsl:apply-templates mode="#default"/>
      </xsl:element>
   </xsl:template>

   <!-- fallback (for everything but tei:p): forward all nodes to the default templates  -->
   <xsl:template match="node()|@*" mode="rdg">
      <xsl:apply-templates select="." mode="#default"/>
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
         <xsl:apply-templates mode="lemma"/>
      </xsl:variable>
      <xsl:variable name="tokens" select="tokenize($addedText, '\s+')"/>
      <xsl:call-template name="apparatusEntry">
         <xsl:with-param name="title" select="wega:getLanguageString('addDefault',$lang)"/>
         <xsl:with-param name="lemma">
            <xsl:choose>
               <xsl:when test="count($tokens) gt 6">
                  <xsl:value-of select="string-join(subsequence($tokens, 1, 3), ' ')"/>
                  <xsl:text> … </xsl:text>
                  <xsl:value-of select="string-join(subsequence($tokens, count($tokens) -2, 3), ' ')"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:sequence select="$addedText"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:with-param>
         <xsl:with-param name="explanation">
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
         </xsl:with-param>
      </xsl:call-template>
   </xsl:template>

   <xsl:template match="tei:unclear[not(parent::tei:choice)]">
      <xsl:element name="span">
         <xsl:apply-templates select="@xml:id"/>
         <xsl:attribute name="class" select="concat('tei_', local-name())"/>
         <xsl:apply-templates/>
         <xsl:call-template name="popover"/>
      </xsl:element>
   </xsl:template>

   <xsl:template match="tei:unclear[not(parent::tei:choice)]" mode="apparatus">
      <xsl:variable name="unclearText">
         <xsl:apply-templates mode="lemma"/>
      </xsl:variable>
      <xsl:variable name="tokens" select="tokenize($unclearText, '\s+')"/>
      <xsl:call-template name="apparatusEntry">
         <xsl:with-param name="title" select="wega:getLanguageString('unclearDefault',$lang)"/>
         <xsl:with-param name="lemma">
            <xsl:choose>
               <xsl:when test="count($tokens) gt 6">
                  <xsl:value-of select="string-join(subsequence($tokens, 1, 3), ' ')"/>
                  <xsl:text> … </xsl:text>
                  <xsl:value-of select="string-join(subsequence($tokens, count($tokens) -2, 3), ' ')"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:sequence select="$unclearText"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:with-param>
         <xsl:with-param name="explanation" select="wega:getLanguageString('unclearDefault', $lang)"/>
      </xsl:call-template>
   </xsl:template>

   <!-- TODO: gap in damage, del, add und unclear?!? -->
   <xsl:template match="tei:gap">
      <xsl:element name="span">
         <xsl:text>[…]</xsl:text>
         <xsl:if test="not(@reason='outOfScope' or parent::tei:del)">
            <xsl:call-template name="popover"/>
         </xsl:if>
      </xsl:element>
   </xsl:template>

   <!-- TODO: Beschreibung von gap noch etwas dürftig bzw. gedoppelt in Titel und Beschreibung -->
   <xsl:template match="tei:gap" mode="apparatus">
      <xsl:variable name="counter">
         <xsl:number level="any"/>
      </xsl:variable>
      <xsl:element name="div">
         <xsl:attribute name="class">apparatusEntry</xsl:attribute>
         <xsl:attribute name="id" select="wega:createID(.)"/>
         <xsl:attribute name="data-title">
            <xsl:value-of select="wega:getLanguageString('gapDefault',$lang)"/>
            <xsl:if test="@reason='outofScope'">
               <xsl:text>: </xsl:text>
               <xsl:value-of select="wega:getLanguageString('outofScope',$lang)"/>
            </xsl:if>
         </xsl:attribute>
         <xsl:attribute name="data-counter"><xsl:value-of select="$counter"/></xsl:attribute>
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
         <xsl:attribute name="class" select="concat('tei_', local-name())"/>
         <xsl:choose>
            <xsl:when test="tei:sic">
               <xsl:apply-templates select="tei:sic" mode="#current"/>
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

   <xsl:template match="tei:choice[tei:sic]" mode="apparatus">
      <xsl:variable name="sic">
         <xsl:apply-templates select="tei:sic" mode="lemma"/>
      </xsl:variable>
      <xsl:variable name="corr">
         <xsl:apply-templates select="tei:corr" mode="lemma"/>
      </xsl:variable>
      <xsl:call-template name="apparatusEntry">
         <xsl:with-param name="title">sic</xsl:with-param>
         <xsl:with-param name="lemma">
            <xsl:sequence select="$sic"/>
         </xsl:with-param>
         <xsl:with-param name="explanation">
            <xsl:sequence select="('recte ', wega:enquote($corr))"/>
         </xsl:with-param>
      </xsl:call-template>
   </xsl:template>
   
   <xsl:template match="tei:choice[tei:unclear]" mode="apparatus">
      <xsl:variable name="opts" as="element()*">
         <xsl:perform-sort select="tei:unclear">
            <xsl:sort select="$sort-order[. = current()/string(@cert)]/@sort"/>
         </xsl:perform-sort>
      </xsl:variable>
      <xsl:variable name="opt1">
         <xsl:apply-templates select="$opts[1]" mode="lemma"/>
      </xsl:variable>
      <xsl:variable name="opt2">
         <xsl:apply-templates select="subsequence($opts, 2)" mode="lemma"/>
      </xsl:variable>
      <xsl:call-template name="apparatusEntry">
         <xsl:with-param name="title" select="wega:getLanguageString('choiceUnclear',$lang)"/>
         <xsl:with-param name="lemma">
            <xsl:sequence select="$opt1"/>
         </xsl:with-param>
         <xsl:with-param name="explanation">
            <!-- Eventuell noch @cert mit ausgeben?!? -->
            <xsl:sequence select="(wega:getLanguageString('choiceUnclear', $lang),' ', $opt2)"/>
         </xsl:with-param>
      </xsl:call-template>
   </xsl:template>
   
   <xsl:template match="tei:choice[tei:abbr]" mode="apparatus">
      <xsl:variable name="abbr">
         <xsl:apply-templates select="tei:abbr" mode="lemma"/>
      </xsl:variable>
      <xsl:variable name="expan">
         <xsl:apply-templates select="tei:expan" mode="lemma"/>
      </xsl:variable>
      <xsl:call-template name="apparatusEntry">
         <xsl:with-param name="title" select="wega:getLanguageString('choiceUnclear',$lang)"/>
         <xsl:with-param name="lemma">
            <xsl:sequence select="$abbr"/>
         </xsl:with-param>
         <xsl:with-param name="explanation">
            <xsl:sequence select="(wega:getLanguageString('choiceAbbr', $lang),' ', wega:enquote($expan))"/>
         </xsl:with-param>
      </xsl:call-template>
   </xsl:template>

   <!-- special template rule for <sic> within bibliographic contexts -->
   <xsl:template match="tei:sic[parent::tei:title or parent::tei:author]" priority="2">
      <xsl:apply-templates/>
      <xsl:element name="span">
         <xsl:attribute name="class">brackets_supplied</xsl:attribute>
         <xsl:text>[sic!]</xsl:text>
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
         <xsl:element name="span">
            <xsl:attribute name="class">brackets_supplied</xsl:attribute>
            <xsl:text>[</xsl:text>
         </xsl:element>
         <xsl:apply-templates mode="#current"/>
         <xsl:element name="span">
            <xsl:attribute name="class">brackets_supplied</xsl:attribute>
            <xsl:text>]</xsl:text>
         </xsl:element>
      </xsl:element>
   </xsl:template>

   <xsl:template match="tei:sic[not(parent::tei:choice)]" mode="apparatus">
      <xsl:call-template name="apparatusEntry">
         <xsl:with-param name="title" select="local-name()"/>
         <xsl:with-param name="lemma">
            <xsl:apply-templates mode="lemma"/>
         </xsl:with-param>
         <xsl:with-param name="explanation">
            <xsl:text>sic!</xsl:text>
         </xsl:with-param>
      </xsl:call-template>
   </xsl:template>

   <xsl:template match="tei:del[not(parent::tei:subst)]" mode="apparatus">
      <xsl:call-template name="apparatusEntry">
         <xsl:with-param name="title" select="wega:getLanguageString('del',$lang)"/>
         <xsl:with-param name="lemma">
            <xsl:apply-templates mode="lemma"/>
         </xsl:with-param>
         <xsl:with-param name="explanation">
            <xsl:choose>
               <xsl:when test="tei:gap and functx:all-whitespace(string-join(text(), ''))">
                  <xsl:value-of select="wega:getLanguageString('delGap', $lang)"/>
               </xsl:when>
               <xsl:when test="@rend='strikethrough'">
                  <xsl:value-of select="wega:getLanguageString('delStrikethrough', $lang)"/>
               </xsl:when>
               <xsl:when test="@rend='overwritten'">
                  <xsl:value-of select="wega:getLanguageString('delOverwritten', $lang)"/>
               </xsl:when>
               <xsl:when test="@rend='erased'">
                  <xsl:value-of select="wega:getLanguageString('delErased', $lang)"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:value-of select="@rend"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:with-param>
      </xsl:call-template>
   </xsl:template>
    
   <xsl:template match="tei:del" mode="lemma"/>
   <xsl:template match="tei:note" mode="lemma"/>
   <xsl:template match="tei:lb" mode="lemma">
      <xsl:text> </xsl:text>
   </xsl:template>
   <xsl:template match="tei:gap" mode="lemma">
      <xsl:text>[…]</xsl:text>
   </xsl:template>
   <xsl:template match="tei:choice" mode="lemma">
      <xsl:choose>
         <xsl:when test="tei:sic">
            <xsl:apply-templates select="tei:sic" mode="#current"/>
         </xsl:when>
         <xsl:when test="tei:unclear">
            <xsl:variable name="opts" as="element()*">
               <xsl:perform-sort select="tei:unclear">
                  <xsl:sort select="$sort-order[. = current()/string(@cert)]/@sort"/>
               </xsl:perform-sort>
            </xsl:variable>
            <xsl:apply-templates select="$opts[1]" mode="#current"/>
         </xsl:when>
         <xsl:when test="tei:abbr">
            <xsl:apply-templates select="tei:abbr" mode="#current"/>
         </xsl:when>
      </xsl:choose>
   </xsl:template>
   <xsl:template match="tei:*" mode="lemma">
      <xsl:apply-templates mode="#current"/>
   </xsl:template>
   
   <!-- template for creating an apparatus entry -->
   <xsl:template name="apparatusEntry">
      <xsl:param name="title" as="xs:string"/>
      <xsl:param name="lemma" as="item()*"/>
      <xsl:param name="explanation" as="item()*"/>
      <xsl:variable name="counter">
         <xsl:number level="any"/>
      </xsl:variable>
      <xsl:element name="div">
         <xsl:attribute name="class">apparatusEntry</xsl:attribute>
         <xsl:attribute name="id" select="wega:createID(.)"/>
         <xsl:attribute name="data-title">
            <xsl:value-of select="$title"/>
         </xsl:attribute>
         <xsl:attribute name="data-counter"><xsl:value-of select="$counter"/></xsl:attribute>
         <xsl:if test="$lemma">
            <xsl:element name="span">
               <xsl:attribute name="class" select="'tei_lemma'"/>
               <xsl:sequence select="wega:enquote($lemma)"/>
            </xsl:element>
         </xsl:if>
         <xsl:if test="$explanation">
            <xsl:sequence select="$explanation"/>
            <xsl:if test="not(matches($explanation, '(\.|\?|!)\s*$'))">
               <xsl:text>.</xsl:text>
            </xsl:if>
         </xsl:if>
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

   <xsl:variable name="sort-order" as="element()+">
      <cert sort="1">high</cert>
      <cert sort="2">medium</cert>
      <cert sort="3">low</cert>
      <cert sort="4">unknown</cert>
      <cert sort="4"/>
   </xsl:variable>

</xsl:stylesheet>