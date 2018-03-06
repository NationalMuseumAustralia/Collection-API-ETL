<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" 
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:crm="http://www.cidoc-crm.org/cidoc-crm/"
	xmlns="tag:conaltuohy.com,2018:nma/piction/"
	xmlns:dcterms="http://purl.org/dc/terms/">
	
	<xsl:param name="base-uri"/><!-- e.g. "http://api.nma.gov.au/" -->
	
	<!-- root element is <doc> containing only <field> and <dataSource> children -->
	
	<xsl:template match="/*">
		<xsl:variable name="visual-item" select="concat('image/', normalize-space((field[@name='Multimedia ID'])[1]), '#')"/>
		<rdf:RDF>
			<xsl:attribute name="xml:base" select="$base-uri"/>
			<xsl:for-each select="field[@name='EMu IRN for Related Objects']">
				<crm:E19_Physical_Object rdf:about="object/{.}#">
					<crm:P138i_has_representation rdf:resource="{$visual-item}"/>
				</crm:E19_Physical_Object>
			</xsl:for-each>
			<crm:E36_Visual_Item rdf:about="{$visual-item}">
				<xsl:for-each select="field[normalize-space()]">
					<xsl:element name="{replace(@name, '\s', '-')}">
						<xsl:choose>
							<xsl:when test=" @name='EMu IRN for Related Objects' ">
								<xsl:attribute name="rdf:resource" select="concat('object/', ., '#')"/>
							</xsl:when>
							<xsl:otherwise><!-- a literal property -->
								<xsl:value-of select="."/>
							</xsl:otherwise>
						</xsl:choose>
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
			</crm:E36_Visual_Item>
		</rdf:RDF>
	</xsl:template>
	
</xsl:stylesheet>
