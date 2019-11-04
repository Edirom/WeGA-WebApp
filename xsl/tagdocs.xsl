<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:wega="http://xquery.weber-gesamtausgabe.de/webapp/functions/utilities" 
	xmlns:tei="http://www.tei-c.org/ns/1.0" 
	xmlns:functx="http://www.functx.com" 
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:teix="http://www.tei-c.org/ns/Examples"
	version="2.0">
	
	<!-- XSL module for the TEI tagdocs element set --> 
	
	<xsl:param name="main-source-path" as="xs:string?"/>
		
	<xsl:template match="tei:elementSpec">
		<xsl:element name="div">
			<xsl:apply-templates select="@xml:id"/>
			<xsl:apply-templates/>
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="tei:remarks[@xml:lang=$lang]">
		<xsl:element name="div">
			<xsl:apply-templates select="@xml:id"/>
			<xsl:attribute name="class" select="local-name()"/>
			<xsl:apply-templates/>
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="tei:gi">
		<xsl:element name="a">
			<xsl:apply-templates select="@xml:id"/>
			<xsl:attribute name="class">tei_gi</xsl:attribute>
			<xsl:attribute name="href" select="wega:spec-link(.)"/>
			<xsl:text>&lt;</xsl:text>
			<xsl:apply-templates/>
			<xsl:text>&gt;</xsl:text>
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="tei:specList">
		<xsl:element name="ul">
			<xsl:apply-templates select="@xml:id"/>
			<xsl:attribute name="class">tei_specList</xsl:attribute>
			<xsl:apply-templates/>
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="tei:specDesc">
		<xsl:variable name="spec" select="wega:doc($main-source-path)//tei:*[@ident=current()/@key]"/>
		<xsl:element name="li">
			<xsl:variable name="gi">
				<gi xmlns="http://www.tei-c.org/ns/1.0"><xsl:value-of select="@key"/></gi>
			</xsl:variable>
			<xsl:apply-templates select="$gi"/>
			<xsl:apply-templates select="$spec/tei:desc[@xml:lang=$lang]"/>
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="tei:tag">
		<xsl:element name="span">
			<xsl:attribute name="class">tei_tag</xsl:attribute>
			<xsl:text>&lt;</xsl:text>
			<xsl:apply-templates/>
			<xsl:text>&gt;</xsl:text>
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="tei:att">
		<xsl:element name="span">
			<xsl:attribute name="class">tei_att</xsl:attribute>
			<xsl:text>@</xsl:text>
			<xsl:apply-templates/>
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="tei:eg">
		<xsl:element name="div">
			<xsl:apply-templates select="@xml:id"/>
			<xsl:attribute name="class" select="'card panel-info'"/>
			<xsl:apply-templates select="tei:gloss"/>
			<xsl:element name="div">
				<xsl:attribute name="class" select="'card-body'"/>
				<xsl:apply-templates select="node()[not(self::tei:gloss)]"/>
			</xsl:element>
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="teix:egXML">
		<xsl:element name="div">
			<xsl:attribute name="class" select="'tei_egXML'"/>
			<xsl:if test="matches(@source, 'A[A-F0-9]{6}') and wega:getOption('environment') eq 'development'">
				<!-- output warnings for broken examples (in development mode only) -->
				<xsl:variable name="mySource" select="wega:doc(@source)"/>
				<xsl:variable name="myEgXML" select="functx:change-element-ns-deep(./*, 'http://www.tei-c.org/ns/1.0', '')" as="node()*"/>
				<xsl:if test="not(@valid or functx:is-node-among-descendants-deep-equal(wega:normalize-whitespace-deep($myEgXML), wega:normalize-whitespace-deep($mySource)))">
					<xsl:attribute name="style">border:1px solid red</xsl:attribute>
				</xsl:if>
			</xsl:if>
			<xsl:element name="pre">
				<xsl:attribute name="class">prettyprint</xsl:attribute>
				<xsl:element name="code">
					<xsl:attribute name="class">language-xml</xsl:attribute>
					<xsl:apply-templates select="*|comment()|processing-instruction()" mode="verbatim"/>
				</xsl:element>
			</xsl:element>
			<!-- WeGA only: create back links to documents for examples -->
			<xsl:if test="matches(@source, 'A[A-F0-9]{6}')">
				<xsl:variable name="rs">
					<rs xmlns="http://www.tei-c.org/ns/1.0">
						<xsl:attribute name="key" select="@source"/>
						<xsl:value-of select="@source"/>
					</rs>
				</xsl:variable>
				<xsl:element name="span">
					<xsl:attribute name="class">tei_egXML_source</xsl:attribute>
					<xsl:value-of select="wega:getLanguageString('source', $lang)"/>
					<xsl:text>: </xsl:text>
					<xsl:apply-templates select="$rs"/>
				</xsl:element>
			</xsl:if>
		</xsl:element>
	</xsl:template>
	
	<xsl:function name="wega:spec-link">
		<xsl:param name="specID" as="xs:string"/>
		<xsl:variable name="specType">
			<xsl:choose>
				<xsl:when test="starts-with($specID, 'att.')"><xsl:value-of select="wega:getLanguageString('attributes', $lang)"/></xsl:when>
				<xsl:when test="starts-with($specID, 'model.')"><xsl:value-of select="wega:getLanguageString('classes', $lang)"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="wega:getLanguageString('elements', $lang)"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:value-of select="wega:join-path-elements((
			$baseHref,
			$lang,
			wega:getLanguageString('project', $lang),
			replace(wega:getLanguageString('editorialGuidelines-text', $lang), '\s+', '_'),
			$specType,
			concat('ref-', $specID, '.html')
			))"/>
	</xsl:function>
	
</xsl:stylesheet>