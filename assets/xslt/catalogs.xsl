<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
 xmlns="urn:oasis:names:tc:entity:xmlns:xml:catalog"
 xmlns:c="urn:oasis:names:tc:entity:xmlns:xml:catalog"
 exclude-result-prefixes="xd c"
 version="1.0">
 <xd:doc scope="stylesheet">
  <xd:desc>
   <xd:p><xd:b>Created on:</xd:b> Mar 31, 2026</xd:p>
   <xd:p><xd:b>Author:</xd:b> Boris</xd:p>
   <xd:p></xd:p>
  </xd:desc>
 </xd:doc>
 
 <xsl:strip-space elements="*"/>
 <xsl:output method="xml" indent="yes"/>
 <xsl:param name="schema-version" />
 <xsl:variable name="schema-version-path" select="concat('schemas/', $schema-version, '/catalog.xml')"/>
 
 <xd:doc>
  <xd:desc>
   <xd:p>Adds link to the directory with specified version if it doesn't exist</xd:p>
  </xd:desc>
 </xd:doc>
 <xsl:template match="c:catalog[c:nextCatalog]">
  <xsl:copy>
   <xsl:copy-of select="@*" />
   <xsl:if test="not(c:nextCatalog[@catalog = $schema-version-path])">
    <nextCatalog catalog="{$schema-version-path}"/>
   </xsl:if>
   <xsl:apply-templates/>
  </xsl:copy>
 </xsl:template>
 
 <xsl:template match="node() | @*">
  <xsl:copy>
   <xsl:apply-templates select="node() | @*"/>
  </xsl:copy>
 </xsl:template>
 
 
</xsl:stylesheet>