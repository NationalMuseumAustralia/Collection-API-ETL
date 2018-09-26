<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" 
	xmlns:f="http://www.w3.org/2005/xpath-functions">

	<!-- This stylesheet accepts a Solr index document (root element is unnamespaced 'doc'),
	and returns a copy in which JSON content in "JSON-XML" syntax is serialized as a JSON string.
	The purpose of isolating the JSON serialization into one stylesheet is to facilitate the XProc
	pipeline's error handling of the mapping from RDF to JSON -->
	
	<xsl:template match="*">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="f:*">
		<xsl:value-of select="xml-to-json(., map{'indent':true()})"/>
	</xsl:template>
	
</xsl:stylesheet>