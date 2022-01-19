<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:functx="http://www.functx.com"
   xmlns:wega="http://xquery.weber-gesamtausgabe.de/webapp/functions/utilities"
   exclude-result-prefixes="xs" version="2.0">

   <xsl:variable name="doc" select="wega:doc($docID)"/>
   <xsl:variable name="textConstitutionNodes" as="node()*" select=".//tei:subst | .//tei:add[not(parent::tei:subst)] | .//tei:gap[not(@reason='outOfScope' or parent::tei:del)] | .//tei:sic[not(parent::tei:choice)] | .//tei:del[not(parent::tei:subst)] | .//tei:unclear[not(parent::tei:choice)] | .//tei:note[@type='textConst']"/>
   <xsl:variable name="commentaryNodes" as="node()*" select=".//tei:note[@type=('commentary', 'definition')] | .//tei:choice"/>
   <xsl:variable name="rdgNodes" as="node()*" select=".//tei:app"/>

   <!--
      Mode: default (i.e. template rules without a @mode attribute)
      In this mode the default variant (e.g. sic, not corr) will be output and diacritic 
      signs will be added to the text. 
      
      Mode: lemma
      This mode is used for creating lemmata (for notes and apparatus entries, etc.) and will
      be plain text only, with the exception of html:span for musical symbols and the like.
      
      Mode: apparatus
      This mode is used for outputting the apparatus entries (with the variant forms).
   -->
   
   <xsl:template name="createApparatus">
      <xsl:element name="div">
         <xsl:attribute name="class">apparatus</xsl:attribute>
         <xsl:if test="wega:isNews($docID)">
            <xsl:attribute name="style">display:none</xsl:attribute>
         </xsl:if>
         <xsl:if test="$textConstitutionNodes or $doc//tei:notesStmt/tei:note[@type='textConst']">
            <xsl:element name="h3">
               <xsl:attribute name="class">media-heading</xsl:attribute>
               <xsl:value-of select="wega:getLanguageString('textConstitution', $lang)"/>
            </xsl:element>
         </xsl:if>
         <xsl:if test="$doc//tei:notesStmt/tei:note[@type='textConst']">
            <xsl:apply-templates select="$doc//tei:notesStmt/tei:note[@type='textConst']"/>
         </xsl:if>
         <xsl:element name="ul">
            <xsl:attribute name="class">apparatus textConstitution</xsl:attribute>
            <xsl:for-each select="$textConstitutionNodes">
               <xsl:element name="li">
                  <xsl:element name="div">
                     <xsl:attribute name="class">row</xsl:attribute>
                     <xsl:element name="div">
                        <xsl:attribute name="class">col-1 text-nowrap</xsl:attribute>
                        <xsl:element name="a">
                           <xsl:attribute name="href">#transcription</xsl:attribute>
                           <xsl:attribute name="data-href"><xsl:value-of select="concat('#ref-',wega:createID(.))"/></xsl:attribute>
                           <xsl:attribute name="class">apparatus-link</xsl:attribute>
                           <xsl:number count="$textConstitutionNodes" level="any"/>
                           <xsl:text>.</xsl:text>
                        </xsl:element>
                     </xsl:element>
                     <xsl:apply-templates select="." mode="apparatus"/>
                  </xsl:element>
               </xsl:element>
            </xsl:for-each>
         </xsl:element>
         <xsl:if test="$commentaryNodes">
            <xsl:element name="h3">
               <xsl:attribute name="class">media-heading</xsl:attribute>
               <xsl:value-of select="wega:getLanguageString('note_commentary', $lang)"/>
            </xsl:element>
         </xsl:if>
         <xsl:element name="ul">
            <xsl:attribute name="class">apparatus commentary</xsl:attribute>
            <xsl:for-each select="$commentaryNodes">
               <xsl:element name="li">
                  <xsl:element name="div">
                     <xsl:attribute name="class">row</xsl:attribute>
                     <xsl:element name="div">
                        <xsl:attribute name="class">col-1 text-nowrap</xsl:attribute>
                        <xsl:element name="a">
                           <xsl:attribute name="href">#transcription</xsl:attribute>
                           <xsl:attribute name="data-href"><xsl:value-of select="concat('#ref-',wega:createID(.))"/></xsl:attribute>
                           <xsl:attribute name="class">apparatus-link</xsl:attribute>
                           <xsl:number count="$commentaryNodes" level="any"/>
                           <xsl:text>.</xsl:text>
                        </xsl:element>
                     </xsl:element>
                     <xsl:apply-templates select="." mode="apparatus"/>
                  </xsl:element>
               </xsl:element>
            </xsl:for-each>
         </xsl:element>
         <xsl:if test="$rdgNodes">
            <xsl:element name="h3">
               <xsl:attribute name="class">media-heading</xsl:attribute>
               <xsl:value-of select="wega:getLanguageString('appRdgs', $lang)"/>
            </xsl:element>
         </xsl:if>
         <xsl:element name="ul">
            <xsl:attribute name="class">apparatus rdg</xsl:attribute>
            <xsl:for-each select="$rdgNodes">
               <xsl:element name="li">
                  <xsl:element name="div">
                     <xsl:attribute name="class">row</xsl:attribute>
                     <xsl:element name="div">
                        <xsl:attribute name="class">col-1 text-nowrap</xsl:attribute>
                        <xsl:element name="a">
                           <xsl:attribute name="href">#transcription</xsl:attribute>
                           <xsl:attribute name="data-href"><xsl:value-of select="concat('#ref-',wega:createID(.))"/></xsl:attribute>
                           <xsl:attribute name="class">apparatus-link</xsl:attribute>
                           <xsl:number count="$rdgNodes" level="any"/>
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

   <!-- dedicated template for textConst notes in the notesStmt -->
   <xsl:template match="tei:note[@type='textConst'][parent::tei:notesStmt]" priority="2">
      <xsl:choose>
         <xsl:when test="child::*/local-name() = $blockLevelElements">
            <xsl:apply-templates/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:element name="p">
               <xsl:apply-templates/>
            </xsl:element>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
   <xsl:template match="tei:note[@type=('definition', 'commentary', 'textConst')]">
      <xsl:call-template name="popover"/>
   </xsl:template>
   
   <xsl:template match="tei:note" mode="apparatus">
      <xsl:variable name="id" select="wega:createID(.)"/>
      <xsl:call-template name="apparatusEntry">
         <xsl:with-param name="title" select="wega:getLanguageString(string-join((local-name(),@type), '_'),$lang)"/>
         <xsl:with-param name="counter-param">
            <xsl:choose>
               <xsl:when test="@type='textConst'"/>
               <xsl:otherwise><xsl:value-of select="'note'"/></xsl:otherwise>
            </xsl:choose>
         </xsl:with-param>
         <xsl:with-param name="lemma">
            <xsl:choose>
               <xsl:when test="preceding::tei:ptr[@target=concat('#', $id)]">
                  <!-- When ein ptr existiert, dann wird dieser ausgewertet -->
                  <xsl:apply-templates select="preceding::tei:ptr[@target=concat('#', $id)]" mode="apparatus"/>
               </xsl:when>
               <xsl:otherwise>
                  <!-- Ansonsten werden die letzten fünf Wörter vor der note als Lemma gewählt -->
                  <xsl:variable name="textTokens" select="tokenize(normalize-space(string-join(preceding-sibling::text() | preceding-sibling::tei:*//text()[not(ancestor::tei:note or ancestor::tei:rdg or ancestor::tei:corr[parent::tei:choice] or ancestor::tei:del[parent::tei:subst])], ' ')), '\s+')"/>
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
      <xsl:variable name="vtextPostPtr" select="following::text()[not(ancestor::tei:note or ancestor::tei:rdg or ancestor::tei:corr[parent::tei:choice] or ancestor::tei:del[parent::tei:subst])]"/>
      <xsl:variable name="vtextPreNote" select="//tei:note[@xml:id=$noteID]/preceding::text()[not(ancestor::tei:note or ancestor::tei:rdg or ancestor::tei:corr[parent::tei:choice] or ancestor::tei:del[parent::tei:subst])]"/>
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
      <xsl:variable name="lemma">
         <xsl:choose>
            <xsl:when test="count(tei:add) gt 1">
               <xsl:apply-templates select="tei:add | text()" mode="lemma"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:apply-templates select="tei:add" mode="lemma"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:call-template name="apparatusEntry">
         <xsl:with-param name="title" select="wega:getLanguageString('popoverTitle.subst',$lang)"/>
         <xsl:with-param name="lemma" select="$lemma"/>
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
                  <xsl:text> </xsl:text>
                  <xsl:value-of select="wega:getLanguageString('substDelStrikethrough', $lang)"/>
                  <xsl:text> </xsl:text>
                  <xsl:sequence select="wega:enquote($lemma)"/>
               </xsl:when>
               <xsl:when test="tei:del[@rend='overwritten']">
                  <xsl:sequence select="wega:enquote($processedDel)"/>
                  <xsl:text> </xsl:text>
                  <xsl:value-of select="wega:getLanguageString('substDelOverwritten', $lang)"/>
                  <xsl:text> </xsl:text>
                  <xsl:sequence select="wega:enquote($lemma)"/>
               </xsl:when>
               <xsl:when test="tei:del[@rend='erased']">
                  <xsl:sequence select="wega:enquote($processedDel)"/>
                  <xsl:text> </xsl:text>
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


   <xsl:template match="tei:app" mode="apparatus">
      <xsl:variable name="id" select="wega:createID(.)"/>
      <xsl:variable name="counter">
         <xsl:number level="any"/>
      </xsl:variable>
      <xsl:variable name="lemElem" select="tei:lem/descendant::text()"/>
      <xsl:variable name="lemWit" select="tei:lem/@wit"/>
      <xsl:variable name="lemWitness" select="$doc//tei:witness[@xml:id=substring-after($lemWit,'#')]/@n"/>
      <xsl:variable name="lemtextSource">
         <xsl:choose>
            <xsl:when test="$lemWitness">
               <xsl:value-of select="$lemWitness"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:value-of select="($doc//tei:witness[not(@rend)])[1]/@n"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
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
         <xsl:attribute name="id" select="$id"/>
         <xsl:attribute name="class">apparatusEntry col-11</xsl:attribute>
         <xsl:attribute name="id" select="$id"/>
         <xsl:attribute name="data-title">
            <xsl:value-of select="wega:getLanguageString('appRdgs',$lang)"/>
         </xsl:attribute>
         <xsl:attribute name="data-counter"><xsl:value-of select="$counter"/></xsl:attribute>
         <xsl:attribute name="data-href"><xsl:value-of select="concat('#',$id)"/></xsl:attribute>
         <xsl:element name="div">
            <xsl:element name="strong">
               <!-- source containing the lemma the first available (not lost) text source by definition' -->
               <xsl:value-of select="concat(wega:getLanguageString('textSource', $lang),' ', $lemtextSource,': ')"/>
            </xsl:element> 
            <xsl:variable name="lemma">
               <xsl:apply-templates select="tei:lem" mode="lemma"/>
            </xsl:variable>
            <xsl:element name="span">
               <xsl:choose>
                  <xsl:when test="functx:all-whitespace($lemma)">
                     <xsl:attribute name="class">noRdg</xsl:attribute>
                     <xsl:value-of select="concat(wega:getLanguageString('noRdg', $lang), '.')"/>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:sequence select="wega:enquote($lemma)"/>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:element>
         </xsl:element>
         <xsl:for-each select="tei:rdg">
            <xsl:variable name="rdgWit" select="substring-after(@wit,'#')"/>
            <xsl:variable name="witN" select="$doc//tei:witness[@xml:id=$rdgWit]/data(@n)"/>
            <xsl:element name="div">
               <xsl:element name="strong">
                  <xsl:value-of select="concat(wega:getLanguageString('textSource', $lang),' ', $witN,': ')"/>
               </xsl:element>
               <xsl:variable name="rdg">
                  <xsl:apply-templates select="." mode="lemma"/>
               </xsl:variable>
               <xsl:element name="span">
                  <xsl:choose>
                     <xsl:when test="functx:all-whitespace($rdg)">
                        <xsl:attribute name="class">noRdg</xsl:attribute>
                        <xsl:value-of select="concat(wega:getLanguageString('noRdg', $lang), '.')"/>
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:sequence select="wega:enquote($rdg)"/>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:element>
            </xsl:element>
         </xsl:for-each>
      </xsl:element>
   </xsl:template>

   <!-- within readings or lemmas there must not be any paragraphs (in the result HTML) -->
   <xsl:template match="tei:p" mode="lemma">
      <xsl:element name="span">
         <xsl:attribute name="class" select="concat('tei_', local-name())"/>
         <xsl:apply-templates mode="#current"/>
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
         <xsl:apply-templates mode="lemma"/>
      </xsl:variable>
      <xsl:variable name="tokens" select="tokenize(normalize-space($addedText), '\s+')"/>
      <xsl:call-template name="apparatusEntry">
         <xsl:with-param name="title" select="wega:getLanguageString('popoverTitle.add',$lang)"/>
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
               <xsl:when test="@place=('margin', 'inline', 'above', 'below', 'mixed')">
                  <xsl:value-of select="wega:getLanguageString(concat('add', functx:capitalize-first(@place)), $lang)"/>
               </xsl:when>
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
      <xsl:variable name="tokens" select="tokenize(normalize-space($unclearText), '\s+')"/>
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
      <xsl:variable name="id" select="wega:createID(.)"/>
      <xsl:variable name="counter">
         <xsl:number count="tei:subst | tei:add[not(parent::tei:subst)] | tei:gap[not(@reason='outOfScope' or parent::tei:del)] | tei:sic[not(parent::tei:choice)] | tei:del[not(parent::tei:subst)] | tei:unclear[not(parent::tei:choice)] | tei:note[@type='textConst']" level="any"/>
      </xsl:variable>
      <xsl:element name="div">
         <xsl:attribute name="class">apparatusEntry col-11</xsl:attribute>
         <xsl:attribute name="id" select="$id"/>
         <xsl:attribute name="data-title">
            <xsl:value-of select="wega:getLanguageString('gapDefault',$lang)"/>
            <xsl:if test="@reason='outofScope'">
               <xsl:text>: </xsl:text>
               <xsl:value-of select="wega:getLanguageString('outofScope',$lang)"/>
            </xsl:if>
         </xsl:attribute>
         <xsl:attribute name="data-counter"><xsl:value-of select="$counter"/></xsl:attribute>
         <xsl:attribute name="data-href"><xsl:value-of select="concat('#',$id)"/></xsl:attribute>
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
         <xsl:with-param name="counter-param" select="'note'"/>
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
         <xsl:with-param name="counter-param" select="'note'"/>
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
         <xsl:with-param name="counter-param" select="'note'"/>
         <xsl:with-param name="title" select="wega:getLanguageString('popoverTitle.choiceAbbr',$lang)"/>
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
      </xsl:element>
      <xsl:call-template name="popover"/>
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
         <xsl:with-param name="title" select="wega:getLanguageString('popoverTitle.del',$lang)"/>
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
   <!-- suppress processing of footnotes in lemma mode to avoid duplicate IDs (https://github.com/Edirom/WeGA-WebApp/issues/313) -->
   <xsl:template match="tei:ref[@type='footnoteAnchor']|tei:footNote" mode="lemma" priority="1">
      <xsl:apply-templates mode="#current"/>
   </xsl:template>
   <!-- suppress processing of footnoteAnchors in lemma mode when the footnote itself is part of the tei:app -->
   <xsl:template match="tei:ref[@type='footnoteAnchor'][ancestor::tei:app//tei:footNote]" mode="lemma" priority="2"/>
   
   <!-- template for creating an apparatus entry -->
   <xsl:template name="apparatusEntry">
      <xsl:param name="title" as="xs:string"/>
      <xsl:param name="lemma" as="item()*"/>
      <xsl:param name="explanation" as="item()*"/>
      <xsl:param name="counter-param"/>
      <xsl:variable name="id" select="wega:createID(.)"/>
      <xsl:variable name="counter">
         <xsl:choose>
            <xsl:when test="$counter-param='note'">
               <xsl:number count="tei:note[@type=('commentary', 'definition')] | tei:choice" level="any"/>
            </xsl:when>
            <xsl:otherwise>
                  <xsl:number count="tei:subst | tei:add[not(parent::tei:subst)] | tei:gap[not(@reason='outOfScope' or parent::tei:del)] | tei:sic[not(parent::tei:choice)] | tei:del[not(parent::tei:subst)] | tei:unclear[not(parent::tei:choice)] | tei:note[@type='textConst']" level="any"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:element name="div">
         <xsl:attribute name="class">apparatusEntry col-11</xsl:attribute>
         <xsl:attribute name="id" select="$id"/>
         <xsl:attribute name="data-title">
            <xsl:value-of select="$title"/>
         </xsl:attribute>
         <xsl:attribute name="data-counter"><xsl:value-of select="$counter"/></xsl:attribute>
         <xsl:attribute name="data-href"><xsl:value-of select="concat('#',$id)"/></xsl:attribute>
         <xsl:if test="$lemma">
            <xsl:element name="span">
               <xsl:attribute name="class" select="'tei_lemma'"/>
               <xsl:sequence select="wega:enquote($lemma)"/>
            </xsl:element>
         </xsl:if>
         <xsl:if test="$explanation">
            <xsl:sequence select="$explanation"/>
            <xsl:variable name="quotation-marks" as="xs:string">\s*("|“|”|»|'|‘|’|›|«|‹)*</xsl:variable>
            <xsl:if test="matches(normalize-space($explanation), concat('(\w|\)|\])', $quotation-marks, '$')) and not(some $node in $textConstitutionNodes satisfies $node is .)">
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
