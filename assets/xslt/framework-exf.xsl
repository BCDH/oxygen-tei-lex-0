<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
 xmlns:fwe="http://www.oxygenxml.com/ns/framework/extend"
 exclude-result-prefixes="xd"
 version="1.0">
 <xd:doc scope="stylesheet">
  <xd:desc>
   <xd:p><xd:b>Created on:</xd:b> Apr 1, 2026</xd:p>
   <xd:p><xd:b>Author:</xd:b> Boris</xd:p>
   <xd:p></xd:p>
  </xd:desc>
 </xd:doc>
 
 <xsl:param name="schema-version" />
 <xsl:variable name="schema-version-path" select="concat('schemas/', $schema-version, '/lex-0.rng')"/>
 
 
 <!--
  <defaultSchema schemaType="rng" href="schemas/0.9.5/lex-0.rng"/>
 -->
 <xsl:template match="/fwe:script/fwe:defaultSchema[@schemaType='rng']">
  <xsl:copy>
   <xsl:copy-of select="@*"/>
   <xsl:if test="not(@href = $schema-version-path)">
    <xsl:attribute name="href"><xsl:value-of select="$schema-version-path"/></xsl:attribute>
   </xsl:if>
  </xsl:copy>
 </xsl:template>

 <xsl:template match="node() | @*">
  <xsl:copy>
   <xsl:apply-templates select="node() | @*"/>
  </xsl:copy>
 </xsl:template>
 
 
</xsl:stylesheet>