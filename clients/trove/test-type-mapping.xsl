<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<!-- 
	This stylesheet is for checking the mapping from the "additionalType" field in the NMA's data API to Trove's categories.
	The stylesheet can be applied to an EMu objects XML file to produce a listing of all object, showing their names and types, 
	along with the related Trove category for each one.
	The actual mapping is implemented in the imported stylesheet.
	-->
	<xsl:output indent="yes"/>
	<xsl:import href="nma-additional-type-mapping.xsl"/>
	<xsl:template match="/">
		<mapping-test>
			<xsl:for-each select="/response/record">
				<item>
					<name><xsl:value-of select="TitObjectTitle"/></name>
					<type><xsl:value-of select="TitObjectName"/></type>
					<category><xsl:call-template name="category-from-additionalType"><xsl:with-param name="additionalType" select="TitObjectName"/></xsl:call-template></category>
				</item>
			</xsl:for-each>
		</mapping-test>
	</xsl:template>
</xsl:stylesheet>