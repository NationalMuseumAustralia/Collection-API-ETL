<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" 
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:crm="http://www.cidoc-crm.org/cidoc-crm/"
	xmlns="tag:conaltuohy.com,2018:nma/piction/"
	xmlns:dcterms="http://purl.org/dc/terms/">
	
	<xsl:param name="base-uri"/><!-- e.g. "http://api.nma.gov.au/" -->
	<xsl:variable name="nma-term-ns" select="concat($base-uri, 'term/')" />
	
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
		"original_2" - 2000px, internal API only
		"original_3" - 1600px, public
		"original_4" - 640px, ignore
		"original_5" - 200px, ignore
		"thumbnail" - 200px, public
		"web" - 800px, public
	-->

	<xsl:template match="/*">
		<xsl:variable name="media-id"
			select="normalize-space((field[@name='Multimedia ID'])[1])" />
		<xsl:variable name="visual-item-graph" select="concat('media/', $media-id)" />
		<xsl:variable name="related-objects"
			select="field[@name='EMu IRN for Related Objects'][normalize-space()]" />
		<xsl:variable name="image-data-sources" select="dataSource[contains(@baseUrl, '\Collectionsearch\')]"/>
		<rdf:RDF>
			<xsl:attribute name="xml:base" select="$base-uri" />
			<xsl:if test="$related-objects and $image-data-sources">
				<!-- we have both P138_represents and P138i_has_representation, for bidirectional 
					traversal between objects and images -->
				<xsl:for-each select="$related-objects">
					<crm:E19_Physical_Object rdf:about="object/{translate(., ' ', '')}#">
						<crm:P138i_has_representation rdf:resource="{$visual-item-graph}#" />
					</crm:E19_Physical_Object>
				</xsl:for-each>
				<!-- See http://linked.art/model/object/digital/#image -->
				<crm:E36_Visual_Item rdf:about="{$visual-item-graph}#">
					<xsl:for-each select="field[@name='title']">
						<rdf:label>
							<xsl:value-of select="." />
						</rdf:label>
					</xsl:for-each>
					<xsl:for-each select="$related-objects">
						<crm:P138_represents rdf:resource="object/{translate(., ' ', '')}#" />
					</xsl:for-each>
					<xsl:for-each select="$image-data-sources">
						<crm:P138i_has_representation>
							<crm:E36_Visual_Item rdf:about="{concat
							(
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
								<xsl:choose>
									<xsl:when test="@name = 'thumbnail'">
										<crm:P2_has_type rdf:resource="{concat($nma-term-ns, 'thumbnail')}" />
									</xsl:when>
									<xsl:when test="@name = 'web'">
										<crm:P2_has_type rdf:resource="{concat($nma-term-ns, 'preview')}" />
									</xsl:when>
									<xsl:when test="@name = 'original_3'">
										<crm:P2_has_type rdf:resource="{concat($nma-term-ns, 'large')}" />
									</xsl:when>
									<!-- TODO: include other resolutions in internal API -->
									<!-- 
									<xsl:otherwise>
										<crm:P2_has_type rdf:resource="{concat($nma-term-ns, @name)}" />
									</xsl:otherwise>
									 -->
								</xsl:choose>
							</crm:E36_Visual_Item>
						</crm:P138i_has_representation>
					</xsl:for-each>
					<xsl:if test="field[@name='Photographer'][normalize-space()]">
						<crm:P94i_was_created_by>
							<crm:E65_Creation rdf:about="{$visual-item-graph}#creation">
								<xsl:for-each select="field[@name='Photographer'][normalize-space()]">
									<crm:P14_carried_out_by>
										<crm:E21_Person>
											<rdf:label>
												<xsl:value-of select="." />
											</rdf:label>
										</crm:E21_Person>
									</crm:P14_carried_out_by>
								</xsl:for-each>
							</crm:E65_Creation>
						</crm:P94i_was_created_by>
					</xsl:if>
					<!-- TODO other metadata fields -->
					<!-- "Other Numbers Kind" "Other Numbers Value" "Page Number" -->
				</crm:E36_Visual_Item>
			</xsl:if>
		</rdf:RDF>
	</xsl:template>
	
</xsl:stylesheet>
