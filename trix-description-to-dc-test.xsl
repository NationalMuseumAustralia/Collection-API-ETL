<!-- 
Converts trix RDF into simple DC ready for conversion to JSON.
Spec: https://www.w3.org/TR/xpath-functions-31/#json-to-xml-mapping
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	version="3.0" xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:path="tag:conaltuohy.com,2018:nma/trix-path-traversal"
	xmlns:xpath="http://www.w3.org/2005/xpath-functions"
	xmlns:xmljson="tag:conaltuohy.com,2018:nma/xml-to-json"
	xmlns:f="http://www.w3.org/2005/xpath-functions" 
	xmlns:map="http://www.w3.org/2005/xpath-functions/map"
	xmlns:trix="http://www.w3.org/2004/03/trix/trix-1/">

	<xsl:import href="util/trix-traversal-functions.xsl" />
	<xsl:import href="util/xmljson-functions.xsl" />
	<xsl:import href="util/date-util-functions.xsl" />

	<xsl:param name="root-resource" /><!-- e.g. "http://nma-dev.conaltuohy.com/xproc-z/narrative/1758#" -->
	<xsl:variable name="api-base-uri" select="replace($root-resource, '(.*)/.*/[^#]*#.*', '$1')"/>

	<xsl:template match="/">
		<default><xsl:value-of select="." /></default>
	</xsl:template>

	<!-- title -->
	<xsl:template name="title">
		<xsl:for-each select="path:forward('rdfs:label')">
			<xpath:string key="title">
				<xsl:value-of select="normalize-space(.)" />
			</xpath:string>
		</xsl:for-each>
	</xsl:template>	

	<!-- accession number -->
	<xsl:template name="accession-number">
		<xsl:copy-of select="xmljson:render-as-string('identifier', 
			path:forward('crm:P1_is_identified_by')[
				path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300312355'
			]
			/path:forward(., 'rdf:value'))" />
	</xsl:template>

</xsl:stylesheet>
