<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
 exclude-result-prefixes="xd"
 version="1.0">
 <xd:doc scope="stylesheet">
  <xd:desc>
   <xd:p><xd:b>Created on:</xd:b> Apr 1, 2026</xd:p>
   <xd:p><xd:b>Author:</xd:b> Boris</xd:p>
   <xd:p></xd:p>
  </xd:desc>
 </xd:doc>
 
 <xsl:output method="xml" indent="yes"/>
 <xsl:param name="schema-version" />
 <xsl:variable name="schema-version-path" select="concat('${framework}/schemas/', $schema-version, '/lex-0.rng')" />
 <xsl:variable name="schema-version-name" select="concat('TEI Lex-0 v', $schema-version)"/>
 
 <xsl:template match="/serialized/serializableOrderedMap/entry/documentTypeDescriptor-array/documentTypeDescriptor/field[@name='schemaDescriptor']">
  <field name="schemaDescriptor"><docTypeSchema><field name="type"><Integer>4</Integer></field><field name="uri"><String><xsl:value-of select="$schema-version-path"/></String></field></docTypeSchema></field>
 </xsl:template>
 
 <!-- for teilex0.framework and transformation.scenarios -->
 <xsl:template match="//documentTypeDescriptor/field[@name='validationScenarios']/validationScenario-array | /serialized/serializableOrderedMap/entry[String = 'validation.scenarios']/validationScenario-array">
  <xsl:copy>
   <xsl:copy-of select="@*"/>
   <xsl:if test="not(validationScenario[.//field[@name='uri']/String[contains(., $schema-version)]])">
    <xsl:call-template name="validation-scenario-skeleton" />
   </xsl:if>
   <xsl:copy-of select="*" />   
  </xsl:copy>
 </xsl:template>
 
 <xsl:template name="validation-scenario-skeleton">
  <validationScenario>
   <field name="pairs">
    <list>
     <validationUnit>
      <field name="validationType">
       <validationUnitType>
        <field name="validationInputType">
         <String>text/xml</String>
        </field>
       </validationUnitType>
      </field>
      <field name="url">
       <String>${currentFileURL}</String>
      </field>
      <field name="validationEngine">
       <validationEngine>
        <field name="engineType">
         <String>&lt;Default engine&gt;</String>
        </field>
        <field name="allowsAutomaticValidation">
         <Boolean>true</Boolean>
        </field>
       </validationEngine>
      </field>
      <field name="allowAutomaticValidation">
       <Boolean>true</Boolean>
      </field>
      <field name="extensions">
       <null/>
      </field>
      <field name="validationSchema">
       <validationUnitSchema>
        <field name="dtdSchemaPublicID">
         <null/>
        </field>
        <field name="schematronPhase">
         <null/>
        </field>
        <field name="type">
         <Integer>6</Integer>
        </field>
        <field name="uri">
         <String><xsl:value-of select="$schema-version-path"/></String>
        </field>
       </validationUnitSchema>
      </field>
      <field name="validationAdvancedSettings">
       <null/>
      </field>
     </validationUnit>
    </list>
   </field>
   <field name="type">
    <String>Validation_scenario</String>
   </field>
   <field name="name">
    <String><xsl:value-of select="$schema-version-name"/></String>
   </field>
  </validationScenario>
 </xsl:template>
 
 <xsl:template match="node() | @*">
  <xsl:copy>
   <xsl:apply-templates select="node() | @*"/>
  </xsl:copy>
 </xsl:template>
 
 
</xsl:stylesheet>