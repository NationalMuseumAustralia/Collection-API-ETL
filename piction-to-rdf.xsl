<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" 
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns="tag:conaltuohy.com,2018:nma/piction/"
	xmlns:dcterms="http://purl.org/dc/terms/">
	
	<xsl:param name="base-uri"/><!-- e.g. "http://api.nma.gov.au/" -->
	
	<!-- root element is <doc> containing only <field> and <dataSource> children -->
	
	<xsl:template match="/*">
		<rdf:RDF>
			<xsl:attribute name="xml:base" select="$base-uri"/>
			<xsl:if test="count(field[@name='EMu IRN for Related Objects']) &gt; 1">
				<xsl:comment>Record should have exactly one IRN</xsl:comment>
			</xsl:if>
			<rdf:Description rdf:about="{concat('object/', normalize-space((field[@name='EMu IRN for Related Objects'])[1]), '#')}">
				<xsl:for-each select="field">
					<xsl:element name="{replace(@name, '\s', '-')}">
						<xsl:value-of select="."/>
					</xsl:element>
				</xsl:for-each>
				<xsl:for-each select="dataSource">
					<xsl:element name="{replace(@name, '\s', '-')}">
						<xsl:attribute name="rdf:resource" select="
							concat(
								'http://collectionsearch.nma.gov.au/nmacs-image-download/piction/dams_data/',
								string-join(
									for $component in tokenize(
										substring-after(@baseUrl, '\Collectionsearch\'),
										'\\'
									) return encode-for-uri($component),
									'/'
								)
							)
						"/>
					</xsl:element>
				</xsl:for-each>
			</rdf:Description>
		</rdf:RDF>
	</xsl:template>
	
</xsl:stylesheet>
