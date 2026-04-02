<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
 xmlns:xt="http://www.oxygenxml.com/ns/extension"
 xmlns:xhtml="http://www.w3.org/1999/xhtml"
 exclude-result-prefixes="xd xhtml"
 version="1.0">
 <xd:doc scope="stylesheet">
  <xd:desc>
   <xd:p><xd:b>Created on:</xd:b> Apr 1, 2026</xd:p>
   <xd:p><xd:b>Author:</xd:b> Boris</xd:p>
   <xd:p></xd:p>
  </xd:desc>
 </xd:doc>
 
 <xsl:strip-space elements="*"/>
 <xsl:output method="xml" indent="yes"/>
 <xsl:param name="schema-version" />
 <xsl:param name="addon-version" />
 <xsl:param name="base-url" />
 <xsl:param name="tags-path" />
 <xsl:variable name="schema-tag-url" select="concat($base-url, '/', $tags-path, '/v', $schema-version)"/>
 
 <xsl:template  match="/xt:extensions/xt:extension[1]/xt:version">
  <xsl:copy>
   <xsl:copy-of select="@*"/>
   <xsl:value-of select="$addon-version"/>
  </xsl:copy>
 </xsl:template>
 
 <xsl:template  match="/xt:extensions/xt:extension[1]/xt:description//xhtml:span[@id='addon-version']">
  <xsl:copy>
   <xsl:copy-of select="@*"/>
   <xsl:value-of select="$addon-version"/>
  </xsl:copy>
 </xsl:template>
 
 <xsl:template match="/xt:extensions/xt:extension[1]/xt:description//xhtml:ul[@id = 'versions']">
  <xsl:copy>
   <xsl:copy-of select="@*"/>
   <xsl:if test="xhtml:li[1][. != $schema-version]">
    <xsl:call-template name="add-schema-link"/>
   </xsl:if>
   <xsl:copy-of select="*"/>
  </xsl:copy>
 </xsl:template>
 
 <xsl:template name="add-schema-link">
  <li xmlns="http://www.w3.org/1999/xhtml">
   <a href="{$schema-tag-url}">
    <xsl:value-of select="$schema-version" />
   </a>
  </li>
 </xsl:template>
 
 <xsl:template match="/xt:extensions/xt:extension[1]/xt:description//xhtml:h3[. = 'History']">
  <xsl:copy-of select="."/>
  <xsl:if test="following-sibling::xhtml:h4[1][. != $addon-version]">
   <h4 xmlns="http://www.w3.org/1999/xhtml"><xsl:copy-of select="$addon-version"/></h4>
   <p xmlns="http://www.w3.org/1999/xhtml"><p>Support for following schemas was added:</p>
    <ul xmlns="http://www.w3.org/1999/xhtml">
     <xsl:call-template name="add-schema-link" />
    </ul>
   </p>
  </xsl:if>
 </xsl:template>
 
 <xsl:template match="xt:license">
  <xsl:copy>
   <xsl:text disable-output-escaping="yes">&lt;![CDATA[</xsl:text>
   <xsl:apply-templates/>
   <xsl:text disable-output-escaping="yes">&#x5D;&#x5D;&gt;</xsl:text>
  </xsl:copy>
 </xsl:template>
 
 <xsl:template match="node() | @*">
  <xsl:copy>
   <xsl:apply-templates select="node() | @*"/>
  </xsl:copy>
 </xsl:template>
 
 
</xsl:stylesheet>