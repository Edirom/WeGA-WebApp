<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:functx="http://www.functx.com"
   xmlns:wega="http://xquery.weber-gesamtausgabe.de/webapp/functions/utilities"
   exclude-result-prefixes="xs" version="3.1">

   <xsl:variable name="doc" select="wega:doc($docID)"/>
   <xsl:variable name="textConstitutionNodes" as="node()*" select=".//tei:subst | .//tei:add[not(parent::tei:subst)] | .//tei:gap[not(@reason='outOfScope' or parent::tei:del)] | .//tei:sic[not(parent::tei:choice)] | .//tei:del[not(parent::tei:subst)] | .//tei:unclear[not(parent::tei:choice)] | .//tei:note[@type='textConst'] | .//tei:supplied[parent::tei:damage]"/>
   <xsl:variable name="commentaryNodes" as="node()*" select=".//tei:note[@type=('commentary', 'definition')] | .//tei:choice"/>
   <xsl:variable name="rdgNodes" as="node()*" select=".//tei:app"/>
   <xsl:variable name="author" as="xs:string?" select="string($doc//tei:titleStmt/tei:author[1]//text())"/>

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
         <xsl:variable name="major-hands" select="$doc//tei:handNotes/tei:handNote[@scope='major'] ! normalize-space(string-join(.//text(), ' '))[. ne '']" as="xs:string*"/>
         <xsl:variable name="main-hands" select="if(exists($major-hands)) then $major-hands else $author" as="xs:string*"/>
         <xsl:variable name="minor-hands" select="$doc//tei:handNotes/tei:handNote[@scope='minor'] ! normalize-space(string-join(.//text(), ' '))[. ne '']" as="xs:string*"/>
         <xsl:if test="exists($main-hands) or exists($minor-hands)">
            <xsl:element name="h3">
               <xsl:attribute name="class">media-heading</xsl:attribute>
               <xsl:value-of select="wega:getLanguageString('hands', $lang)"/>
            </xsl:element>
            <xsl:if test="exists($main-hands)">
               <xsl:element name="h4">
                  <xsl:value-of select="wega:getLanguageString('mainHand', $lang)"/>
               </xsl:element>
               <xsl:element name="ul">
                  <xsl:attribute name="class">hands tei_list</xsl:attribute>
                  <xsl:for-each select="$main-hands">
                     <xsl:element name="li">
                        <xsl:value-of select="."/>
                     </xsl:element>
                  </xsl:for-each>
               </xsl:element>
            </xsl:if>
            <xsl:if test="exists($minor-hands)">
               <xsl:element name="h4">
                  <xsl:value-of select="wega:getLanguageString('minorHands', $lang)"/>
               </xsl:element>
               <xsl:element name="ul">
                  <xsl:attribute name="class">hands tei_list</xsl:attribute>
                  <xsl:for-each select="$minor-hands">
                     <xsl:element name="li">
                        <xsl:value-of select="."/>
                     </xsl:element>
                  </xsl:for-each>
               </xsl:element>
            </xsl:if>
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
         <xsl:if test="$textConstitutionNodes">
            <xsl:variable name="major-hand-note" select="($doc//tei:handNote[@scope='major'])[1]" as="element(tei:handNote)?"/>
            <xsl:variable name="major-hand-id" select="if($major-hand-note/@xml:id) then string($major-hand-note/@xml:id) else ()" as="xs:string?"/>
            <xsl:variable name="major-hand-desc" select="if($major-hand-note) then wega:hand-entry-text($major-hand-note) else $author" as="xs:string?"/>
            <xsl:variable name="main-hand-heading" select="
               if(normalize-space($major-hand-desc))
               then concat(wega:getLanguageString('mainHand', $lang), ' – ', $major-hand-desc)
               else wega:getLanguageString('mainHand', $lang)
            " as="xs:string"/>
            <xsl:variable name="hand-ids-in-text-constitution" as="xs:string*">
               <xsl:for-each select="$textConstitutionNodes">
                  <xsl:sequence select="wega:resolved-text-constitution-hand-ids(.)"/>
               </xsl:for-each>
            </xsl:variable>
            <xsl:variable name="distinct-hand-ids" select="wega:distinct-strings-in-order($hand-ids-in-text-constitution)" as="xs:string*"/>
            <xsl:variable name="additional-hand-ids" as="xs:string*">
               <xsl:sequence select="
                  for $note in $doc//tei:handNote[@xml:id][@xml:id = $distinct-hand-ids and not(@xml:id = $major-hand-id)]
                  return string($note/@xml:id)
               "/>
            </xsl:variable>

            <xsl:element name="h4">
               <xsl:value-of select="$main-hand-heading"/>
            </xsl:element>
            <xsl:element name="ul">
               <xsl:attribute name="class">apparatus textConstitution</xsl:attribute>
               <xsl:for-each select="$textConstitutionNodes[wega:is-main-hand-text-constitution-entry(., $major-hand-id)]">
                  <xsl:element name="li">
                     <xsl:element name="div">
                        <xsl:attribute name="class">row</xsl:attribute>
                        <xsl:element name="div">
                           <xsl:attribute name="class">col-1 text-nowrap</xsl:attribute>
                           <xsl:element name="a">
                              <xsl:attribute name="href">#transcription</xsl:attribute>
                              <xsl:attribute name="data-href" select="wega:get-backref-link(wega:createID(.))"/>
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

            <xsl:for-each select="$additional-hand-ids">
               <xsl:variable name="hand-id" select="." as="xs:string"/>
               <xsl:variable name="hand-label" select="wega:hand-label-by-id($textConstitutionNodes[1], $hand-id)" as="xs:string?"/>
               <xsl:if test="normalize-space($hand-label)">
                  <xsl:element name="h4">
                     <xsl:value-of select="$hand-label"/>
                  </xsl:element>
                  <xsl:element name="ul">
                     <xsl:attribute name="class">apparatus textConstitution</xsl:attribute>
                     <xsl:for-each select="$textConstitutionNodes[wega:is-hand-text-constitution-entry(., $hand-id)]">
                        <xsl:element name="li">
                           <xsl:element name="div">
                              <xsl:attribute name="class">row</xsl:attribute>
                              <xsl:element name="div">
                                 <xsl:attribute name="class">col-1 text-nowrap</xsl:attribute>
                                 <xsl:element name="a">
                                    <xsl:attribute name="href">#transcription</xsl:attribute>
                                    <xsl:attribute name="data-href" select="wega:get-backref-link(wega:createID(.))"/>
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
               </xsl:if>
            </xsl:for-each>
         </xsl:if>
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
                           <xsl:attribute name="data-href" select="wega:get-backref-link(wega:createID(.))"/>
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
                           <xsl:attribute name="data-href" select="wega:get-backref-link(wega:createID(.))"/>
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
            <xsl:variable name="non-main-hand-annotation" select="wega:non-main-hand-annotation(.)" as="element()?"/>
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
               <xsl:when test="tei:del[@rend='converted']">
                  <xsl:sequence select="wega:enquote($processedDel)"/>
                  <xsl:text> </xsl:text>
                  <xsl:value-of select="wega:getLanguageString('substDelConverted', $lang)"/>
                  <xsl:text> </xsl:text>
                  <xsl:sequence select="wega:enquote($lemma)"/>
               </xsl:when>
               <xsl:when test="tei:del[@rend='erased']">
                  <xsl:sequence select="wega:enquote($processedDel)"/>
                  <xsl:text> </xsl:text>
                  <xsl:value-of select="wega:getLanguageString('delErased', $lang)"/>
               </xsl:when>
            </xsl:choose>
            <xsl:if test="$non-main-hand-annotation">
               <xsl:sequence select="$non-main-hand-annotation"/>
            </xsl:if>
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
         <xsl:attribute name="data-counter" select="$counter"/>
         <xsl:attribute name="data-href" select="concat('#',$id)"/>
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
            <xsl:variable name="non-main-hand-annotation" select="wega:non-main-hand-annotation(.)" as="element()?"/>
            <xsl:choose>
               <xsl:when test="@place=('margin', 'inline', 'above', 'below', 'mixed')">
                  <xsl:value-of select="wega:getLanguageString(concat('add', functx:capitalize-first(@place)), $lang)"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:value-of select="wega:getLanguageString('addDefault', $lang)"/>
               </xsl:otherwise>
            </xsl:choose>
            <xsl:if test="$non-main-hand-annotation">
               <xsl:sequence select="$non-main-hand-annotation"/>
            </xsl:if>
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

   <!--
      whitespace is preserved for tei:damage via xsl:preserve-space;
      we'll suppress it though when there's only one child element 
   -->
   <xsl:template match="tei:damage[count(*) eq 1]">
      <xsl:element name="span">
         <xsl:apply-templates select="@xml:id"/>
         <xsl:attribute name="class">tei_damage</xsl:attribute>
         <xsl:apply-templates select="*"/>
      </xsl:element>
   </xsl:template>

   <xsl:template match="tei:gap">
      <xsl:element name="span">
         <xsl:text>[…]</xsl:text>
         <xsl:if test="not(@reason='outOfScope' or parent::tei:del)">
            <xsl:call-template name="popover"/>
         </xsl:if>
      </xsl:element>
   </xsl:template>

   <xsl:template match="tei:gap" mode="apparatus">
      <xsl:variable name="data-title" select="(ancestor::tei:damage/@agent, ancestor::tei:damage ! 'damageDefault', 'gapDefault')[1]" as="xs:string"/>
      <xsl:variable name="text-desc" select="(@reason, 'gapDefault')[1]" as="xs:string"/>
      <xsl:call-template name="apparatusEntry">
         <xsl:with-param name="title" select="wega:getLanguageString($data-title, $lang)"/>
         <xsl:with-param name="explanation">
            <xsl:value-of select="wega:getLanguageString($text-desc, $lang)"/>
            <xsl:if test="@unit and @quantity">
               <xsl:text> (</xsl:text>
               <xsl:value-of select="wega:getLanguageString('approx', $lang)"/>
               <xsl:text> </xsl:text>
               <xsl:value-of select="@quantity"/>
               <xsl:text> </xsl:text>
               <xsl:value-of select="
                  if(@quantity = 1) then wega:getLanguageString(@unit || 'Sg', $lang)
                  else wega:getLanguageString(@unit, $lang)
                  "/>
               <xsl:text>)</xsl:text>
            </xsl:if>
         </xsl:with-param>
      </xsl:call-template>
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
<!--         <xsl:attribute name="id" select="wega:createID(.)"/>-->
         <xsl:element name="span">
            <xsl:attribute name="class">brackets_supplied</xsl:attribute>
            <xsl:text>[</xsl:text>
         </xsl:element>
         <xsl:apply-templates mode="#current"/>
         <xsl:element name="span">
            <xsl:attribute name="class">brackets_supplied</xsl:attribute>
            <xsl:text>]</xsl:text>
         </xsl:element>
         <xsl:if test="parent::tei:damage">
            <xsl:call-template name="popover"/>
         </xsl:if>
      </xsl:element>
   </xsl:template>
   
   <xsl:template match="tei:supplied[parent::tei:damage]" mode="apparatus">
      <xsl:variable name="data-title" select="(ancestor::tei:damage/@agent, 'damageDefault')[1]" as="xs:string"/>
      <xsl:call-template name="apparatusEntry">
         <xsl:with-param name="title" select="wega:getLanguageString($data-title,$lang)"/>
         <xsl:with-param name="lemma">
            <xsl:apply-templates mode="lemma"/>
         </xsl:with-param>
         <xsl:with-param name="explanation">
            <xsl:value-of select="wega:getLanguageString('supplied',$lang)"/>
         </xsl:with-param>
      </xsl:call-template>
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
            <xsl:variable name="non-main-hand-annotation" select="wega:non-main-hand-annotation(.)" as="element()?"/>
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
            <xsl:if test="$non-main-hand-annotation">
               <xsl:sequence select="$non-main-hand-annotation"/>
            </xsl:if>
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
               <xsl:number count="tei:subst | tei:add[not(parent::tei:subst)] | tei:gap[not(@reason='outOfScope' or parent::tei:del)] | tei:sic[not(parent::tei:choice)] | tei:del[not(parent::tei:subst)] | tei:unclear[not(parent::tei:choice)] | tei:note[@type='textConst'] | tei:supplied[parent::tei:damage]" level="any"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:element name="div">
         <xsl:attribute name="class">apparatusEntry col-11</xsl:attribute>
         <xsl:attribute name="id" select="$id"/>
         <xsl:attribute name="data-title">
            <xsl:value-of select="$title"/>
         </xsl:attribute>
         <xsl:attribute name="data-counter" select="$counter"/>
         <xsl:attribute name="data-href" select="concat('#',$id)"/>
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
   
   <xsl:function name="wega:hand-ids" as="xs:string*">
      <xsl:param name="hand-values" as="xs:string*"/>
      <xsl:sequence select="
         distinct-values(
            for $hand in $hand-values
            return
               for $token in tokenize(normalize-space($hand), '\s+')
               return normalize-space(
                  if(contains($token, '#')) then substring-after($token, '#')
                  else $token
               )
         )[. ne '']
      "/>
   </xsl:function>

   <xsl:function name="wega:distinct-strings-in-order" as="xs:string*">
      <xsl:param name="values" as="xs:string*"/>
      <xsl:sequence select="
         for $pos in 1 to count($values)
         return
            if($values[position() lt $pos] = $values[$pos])
            then ()
            else $values[$pos]
      "/>
   </xsl:function>

   <xsl:function name="wega:hand-note" as="element(tei:handNote)?">
      <xsl:param name="context" as="node()"/>
      <xsl:param name="id" as="xs:string"/>
      <xsl:sequence select="
         (($doc//tei:handNote[@xml:id = $id], $context/root()//tei:handNote[@xml:id = $id])[1])
      "/>
   </xsl:function>

   <xsl:function name="wega:hand-label-by-id" as="xs:string?">
      <xsl:param name="context" as="node()"/>
      <xsl:param name="id" as="xs:string"/>
      <xsl:variable name="note" select="wega:hand-note($context, $id)" as="element(tei:handNote)?"/>
      <xsl:sequence select="
         if(not($note))
         then ()
         else normalize-space(string-join($note//text(), ' '))
      "/>
   </xsl:function>

   <xsl:function name="wega:text-constitution-hand-ids" as="xs:string*">
      <xsl:param name="context" as="node()"/>
      <xsl:choose>
         <xsl:when test="$context/self::tei:subst and normalize-space($context/@hand)">
            <xsl:sequence select="wega:hand-ids(string($context/@hand))"/>
         </xsl:when>
         <xsl:when test="$context/self::tei:subst">
            <xsl:sequence select="
               wega:hand-ids(
                  (
                     for $h in $context/tei:del/@hand return string($h),
                     for $h in $context/tei:add/@hand return string($h)
                  )
               )
            "/>
         </xsl:when>
         <xsl:when test="$context/self::tei:add or $context/self::tei:del">
            <xsl:sequence select="wega:hand-ids(string($context/@hand))"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence select="()"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <xsl:function name="wega:resolved-text-constitution-hand-ids" as="xs:string*">
      <xsl:param name="context" as="node()"/>
      <xsl:variable name="resolved" as="xs:string*">
         <xsl:for-each select="wega:text-constitution-hand-ids($context)">
            <xsl:if test="normalize-space(wega:hand-label-by-id($context, .))">
               <xsl:sequence select="."/>
            </xsl:if>
         </xsl:for-each>
      </xsl:variable>
      <xsl:sequence select="wega:distinct-strings-in-order($resolved)"/>
   </xsl:function>

   <xsl:function name="wega:is-main-hand-text-constitution-entry" as="xs:boolean">
      <xsl:param name="node" as="node()"/>
      <xsl:param name="major-hand-id" as="xs:string?"/>
      <xsl:choose>
         <xsl:when test="$node/self::tei:add or $node/self::tei:del or $node/self::tei:subst">
            <xsl:variable name="resolved-hand-ids" select="wega:resolved-text-constitution-hand-ids($node)" as="xs:string*"/>
            <xsl:sequence select="
               if($major-hand-id)
               then empty($resolved-hand-ids) or $major-hand-id = $resolved-hand-ids
               else empty($resolved-hand-ids)
            "/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence select="true()"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <xsl:function name="wega:is-hand-text-constitution-entry" as="xs:boolean">
      <xsl:param name="node" as="node()"/>
      <xsl:param name="hand-id" as="xs:string"/>
      <xsl:sequence select="
         some $resolved-id in wega:resolved-text-constitution-hand-ids($node)
         satisfies $resolved-id = $hand-id
      "/>
   </xsl:function>

   <xsl:function name="wega:major-hand-id" as="xs:string?">
      <xsl:sequence select="string(($doc//tei:handNote[@scope='major'][1]/@xml:id, ())[1])"/>
   </xsl:function>

   <xsl:function name="wega:non-main-hand-labels" as="xs:string*">
      <xsl:param name="context" as="element()"/>
      <xsl:variable name="major-hand-id" select="wega:major-hand-id()" as="xs:string?"/>
      <xsl:variable name="resolved-ids" select="wega:resolved-text-constitution-hand-ids($context)" as="xs:string*"/>
      <xsl:variable name="non-main-ids" as="xs:string*"
         select="
            if(normalize-space($major-hand-id))
            then $resolved-ids[. ne $major-hand-id]
            else $resolved-ids
         "/>
      <xsl:sequence select="
         wega:distinct-strings-in-order(
            for $id in $non-main-ids
            return wega:hand-label-by-id($context, $id)
         )[normalize-space(.)]
      "/>
   </xsl:function>
   
   <xsl:function name="wega:resolve-hand-texts" as="xs:string*">
      <xsl:param name="context" as="element()"/>
      <xsl:param name="hand-values" as="xs:string*"/>
      <xsl:sequence select="
         distinct-values(
            for $id in wega:hand-ids($hand-values)
            return normalize-space(
               string-join((($doc//tei:handNote[@xml:id = $id], $context/root()//tei:handNote[@xml:id = $id])[1])//text(), ' ')
            )
         )[. ne '']
      "/>
   </xsl:function>
   
   <xsl:function name="wega:hand-texts" as="xs:string*">
      <xsl:param name="context" as="element()"/>
      <xsl:choose>
         <xsl:when test="$context/self::tei:subst and normalize-space($context/@hand)">
            <xsl:sequence select="wega:resolve-hand-texts($context, string($context/@hand))"/>
         </xsl:when>
         <xsl:when test="$context/self::tei:subst">
            <xsl:sequence select="
               wega:resolve-hand-texts(
                  $context,
                  (
                     for $h in $context/tei:del/@hand return string($h),
                     for $h in $context/tei:add/@hand return string($h)
                  )
               )
            "/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence select="wega:resolve-hand-texts($context, string($context/@hand))"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   <xsl:function name="wega:hand-explanation" as="xs:string?">
      <xsl:param name="context" as="element()"/>
      <xsl:variable name="hand-texts" select="wega:hand-texts($context)" as="xs:string*"/>
      <xsl:sequence select="
         if(exists($hand-texts))
         then concat(' (', wega:getLanguageString('handLabel', $lang), ': ', string-join($hand-texts, '; '), ')')
         else ()
      "/>
   </xsl:function>

   <xsl:function name="wega:non-main-hand-annotation" as="element()?">
      <xsl:param name="context" as="element()"/>
      <xsl:variable name="labels" select="wega:non-main-hand-labels($context)" as="xs:string*"/>
      <xsl:if test="exists($labels)">
         <xsl:element name="span">
            <xsl:attribute name="class">hand</xsl:attribute>
            <xsl:value-of select="string-join($labels, '; ')"/>
         </xsl:element>         
      </xsl:if>
   </xsl:function>
   
   <xsl:function name="wega:hand-display-text" as="xs:string?">
      <xsl:param name="node" as="element()?"/>
      <xsl:sequence select="
         if($node)
         then normalize-space(string-join($node//text(), ' '))
         else ()
      "/>
   </xsl:function>
   
   <xsl:function name="wega:hand-entry-text" as="xs:string?">
      <xsl:param name="node" as="element()?"/>
      <xsl:variable name="text" select="wega:hand-display-text($node)" as="xs:string?"/>
      <xsl:sequence select="if(not($text)) then () else $text"/>
   </xsl:function>

   <xsl:variable name="sort-order" as="element()+">
      <cert sort="1">high</cert>
      <cert sort="2">medium</cert>
      <cert sort="3">low</cert>
      <cert sort="4">unknown</cert>
      <cert sort="4"/>
   </xsl:variable>

</xsl:stylesheet>
