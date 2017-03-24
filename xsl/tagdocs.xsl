<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/1999/xhtml" xmlns:wega="http://xquery.weber-gesamtausgabe.de/webapp/functions/utilities" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:functx="http://www.functx.com" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0">
	
	<!-- XSL module for the TEI tagdocs element set --> 
		
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
	
	<xsl:function name="wega:spec-link">
		<xsl:param name="specID" as="xs:string"/>
		<xsl:value-of select="wega:join-path-elements((
			$baseHref,
			$lang,
			wega:getLanguageString('project', $lang),
			replace(wega:getLanguageString('editorialGuidelines-text', $lang), '\s+', '_'),
			'wega_all',
			concat('ref-', $specID, '.html')
			))"/>
	</xsl:function>
	
</xsl:stylesheet>