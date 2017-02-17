<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" 
	xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:functx="http://www.functx.com"
	xmlns="http://www.w3.org/1999/xhtml"
	exclude-result-prefixes="xs" version="2.0">
	
	<xsl:output encoding="UTF-8" method="html" omit-xml-declaration="yes" indent="no"/>
	<xsl:strip-space elements="*"/>
	<xsl:preserve-space elements="tei:q tei:quote tei:item tei:cell tei:p tei:dateline tei:closer tei:opener tei:hi tei:addrLine tei:persName tei:rs tei:workName tei:characterName tei:placeName tei:seg tei:l tei:head tei:salute tei:date tei:subst tei:add tei:note tei:orgName"/>
	
	<xsl:include href="common_main.xsl"/>
	
	<xsl:template match="tei:elementSpec">
		<xsl:element name="div">
			<xsl:apply-templates/>
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="tei:remarks[@xml:lang=$lang]">
		<xsl:element name="div">
			<xsl:attribute name="class" select="local-name()"/>
			<xsl:apply-templates/>
		</xsl:element>
	</xsl:template>
	
</xsl:stylesheet>