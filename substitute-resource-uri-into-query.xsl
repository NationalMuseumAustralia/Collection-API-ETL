<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" 
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:crm="http://www.cidoc-crm.org/cidoc-crm/"
	xmlns="tag:conaltuohy.com,2018:nma/piction/"
	xmlns:dcterms="http://purl.org/dc/terms/">
	
	<xsl:param name="resource-uri"/><!-- e.g. "http://nma-dev.conaltuohy.com/xproc-z/narrative/1758#" -->
	
	<xsl:template match="/*">
		<xsl:copy>
			<xsl:analyze-string select="text()" regex="«resource-uri»">
				<xsl:matching-substring>
					<xsl:value-of select="concat('&lt;', $resource-uri, '&gt;')"/>
				</xsl:matching-substring>
				<xsl:non-matching-substring>
					<xsl:value-of select="."/>
				</xsl:non-matching-substring>
			</xsl:analyze-string>
		</xsl:copy>
	</xsl:template>
	
</xsl:stylesheet>
