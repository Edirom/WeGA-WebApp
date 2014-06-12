<xsl:stylesheet xmlns="http://www.tei-c.org/ns/1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:functx="http://www.functx.com"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" version="2.0">
    
<!--  ****************  -->
<!--  AHTUNG: Die Kommentarknoten wurde nicht übernommen!  -->
<!--  ****************  -->

    <xsl:output name="xml" indent="yes" encoding="UTF-8" method="xml" omit-xml-declaration="no"
        exclude-result-prefixes="xsl"/>
    <xsl:output indent="yes" encoding="UTF-8" method="xml" omit-xml-declaration="no"
        exclude-result-prefixes="xsl tei"/>

    <xsl:param name="id"/>

    <xsl:function name="functx:repeat-string" as="xs:string">
        <xsl:param name="stringToRepeat" as="xs:string?"/>
        <xsl:param name="count" as="xs:integer"/>

        <xsl:sequence
            select="              string-join((for $i in 1 to $count return $stringToRepeat),             '')             "
        />
    </xsl:function>
    <xsl:function name="functx:pad-integer-to-length" as="xs:string">
        <xsl:param name="integerToPad" as="xs:anyAtomicType?"/>
        <xsl:param name="length" as="xs:integer"/>

        <xsl:sequence
            select="              if ($length &lt; string-length(string($integerToPad)))             then error(xs:QName('functx:Integer_Longer_Than_Length'))             else concat             (functx:repeat-string(             '0',$length - string-length(string($integerToPad))),             string($integerToPad))             "
        />
    </xsl:function>

    <!--<xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>-->

    <!--<xsl:template match="tei:div">
        <xsl:apply-templates/>
    </xsl:template>-->

    <xsl:template match="tei:ab">
        <!--<xsl:variable name="counter">
            <xsl:number level="any"/>
        </xsl:variable>-->
        <!--        <xsl:variable name="id" select="concat('A06',functx:pad-integer-to-length($counter, 4))"/>-->
        <!--        <xsl:variable name="filename" select="concat('/Users/peter/temp/diaries/', $id,'.xml')"/>-->
        <!--        <xsl:result-document href="{$filename}" format="xml">-->
        <xsl:element name="ab">
            <xsl:attribute name="n" select="substring-after(substring-after(@xml:id, '_'), '_')"/>
            <xsl:attribute name="xml:id" select="$id"/>
            <xsl:apply-templates/>
            <!--<xsl:for-each select="*">
                    <xsl:copy-of select="."/>
                </xsl:for-each>-->
        </xsl:element>
        <!--        </xsl:result-document>-->
    </xsl:template>

    <xsl:template match="*[ancestor::tei:ab]">
        <xsl:copy-of select="."/>
    </xsl:template>
</xsl:stylesheet>
