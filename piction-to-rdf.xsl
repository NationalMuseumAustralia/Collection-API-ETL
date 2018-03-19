<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" 
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:crm="http://www.cidoc-crm.org/cidoc-crm/"
	xmlns="tag:conaltuohy.com,2018:nma/piction/"
	xmlns:dcterms="http://purl.org/dc/terms/">
	
	<xsl:param name="base-uri"/><!-- e.g. "http://api.nma.gov.au/" -->
	<xsl:variable name="nma-term-ns" select="concat($base-uri, 'term#')" />
	
	<!-- root element is <doc> containing only <field> and <dataSource> children -->
	<!-- field elements have @name attributes:
		"EMu IRN for Media Asset" - ignore?
		"EMu IRN for Related Objects" - done
		"Multimedia ID" - visual item identifier - done
		"Other Numbers Kind" 
		"Other Numbers Value" 
		"Page Number" 
		"Photographer" - done
		"Title" - done
	-->
	<!-- dataSource elements have attributes @type (="URLDataSource"), @baseUrl (= a UNC path to the image file), and @name:
		"original_2" 
		"original_3" 
		"original_4" 
		"original_5"
		"original_5" 
		"thumbnail" 
		"web"
	-->
	
	<xsl:template match="/*">
		<xsl:variable name="media-id" select="normalize-space((field[@name='Multimedia ID'])[1])"/>
		<xsl:variable name="visual-item-graph" select="concat('image/', $media-id)"/>
		<rdf:RDF>
			<xsl:attribute name="xml:base" select="$base-uri"/>
			<!-- we have both P138_represents and P138i_has_representation, for bidirectional traversal between objects and images -->
			<xsl:for-each select="field[@name='EMu IRN for Related Objects']">
				<crm:E19_Physical_Object rdf:about="object/{.}#">
					<crm:P138i_has_representation rdf:resource="{$visual-item-graph}#"/>
				</crm:E19_Physical_Object>
			</xsl:for-each>
			<!-- See http://linked.art/model/object/digital/#image -->
			<crm:E36_Visual_Item rdf:about="{$visual-item-graph}#">
				<xsl:for-each select="field[@name='title']"><rdf:label><xsl:value-of select="."/></rdf:label></xsl:for-each>
				<xsl:for-each select="field[@name='EMu IRN for Related Objects']">
					<crm:P138_represents rdf:resource="object/{.}#"/>
				</xsl:for-each>
				<xsl:for-each select="dataSource">
					<crm:P138i_has_representation>
						<crm:E36_Visual_Item rdf:about="{
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
						}">
							<!-- NB dimensions of these images are not known, but we can give them all types -->
							<crm:P2_has_type rdf:resource="{concat($nma-term-ns, @name)}"/>
						</crm:E36_Visual_Item>
					</crm:P138i_has_representation>
				</xsl:for-each>
				<xsl:if test="field[@name='Photographer'][normalize-space()]">
					<crm:P94i_was_created_by>
						<crm:E65_Creation rdf:about="{$visual-item-graph}#creation">
							<xsl:for-each select="field[@name='Photographer'][normalize-space()]">
								<crm:P14_carried_out_by>
									<crm:E21_Person>
										<rdf:label><xsl:value-of select="."/></rdf:label>
									</crm:E21_Person>
								</crm:P14_carried_out_by>
							</xsl:for-each>
						</crm:E65_Creation>
					</crm:P94i_was_created_by>
				</xsl:if>
				<!-- TODO other metadata fields -->
				<!--
				"Other Numbers Kind" 
				"Other Numbers Value" 
				"Page Number" 
				-->
			</crm:E36_Visual_Item>
		</rdf:RDF>
	</xsl:template>
	
</xsl:stylesheet>
