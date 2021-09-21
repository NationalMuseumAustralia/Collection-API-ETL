<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" 
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:crm="http://www.cidoc-crm.org/cidoc-crm/"
	xmlns="tag:conaltuohy.com,2018:nma/piction/"
	xmlns:ore="http://www.openarchives.org/ore/terms/"
	xmlns:dcterms="http://purl.org/dc/terms/">
	
	<xsl:param name="base-uri"/><!-- e.g. "http://api.nma.gov.au/" -->
	<xsl:variable name="nma-term-ns" select="concat($base-uri, 'term/')" />
	
	<!-- root element is <doc> containing only <field> and <dataSource> children -->
	<!-- field elements have @name attributes:
		"EMU IRN" - done
		"Multimedia ID" - visual item identifier - done
		"Page Number" 
		"Photographer" - done
		"Title" - done
	-->


	<xsl:template match="/*">
		<xsl:variable name="media-id"
			select="normalize-space((field[@name='Multimedia ID'])[1])" />
		<xsl:variable name="visual-item-graph" select="concat('media/', $media-id)" />
		<xsl:variable name="related-objects"
			select="field[@name='EMU IRN'][normalize-space()]" />
		<!-- dataSource elements have attributes @type (="URLDataSource"), @baseUrl (= a UNC path to the image file), and @name:
			"original_2" - 2000px, internal API only
			"original_3" - 1600px, public
			"original_4" - 640px, ignore
			"original_5" - 200px, ignore
			"thumbnail" - 200px, public
			"web" - 800px, public
		-->
		<xsl:variable name="image-data-sources" select="
			dataSource
				[@name=('original_2', 'original_3', 'thumbnail', 'web')]
		"/>
		<rdf:RDF>
			<xsl:attribute name="xml:base" select="$base-uri" />
			<xsl:if test="$related-objects and $image-data-sources">
				<!-- we have both P138_represents and P138i_has_representation, for bidirectional 
					traversal between objects and images -->
				<xsl:variable name="related-object-identifiers" select="$related-objects!tokenize(., '[,\s?]+')"/>
				<xsl:for-each select="$related-object-identifiers">
					<crm:E19_Physical_Object rdf:about="object/{translate(., ' ', '')}#">
						<crm:P138i_has_representation rdf:resource="{$visual-item-graph}#" />
					</crm:E19_Physical_Object>
				</xsl:for-each>
				<!-- See http://linked.art/model/object/digital/#image -->
				<crm:E36_Visual_Item rdf:about="{$visual-item-graph}#">
					<crm:P2_has_type rdf:resource="{$nma-term-ns}piction-image" />
					<!-- a record with <field name="Page Number">1</field> is marked as "preferred" -->
					<xsl:if test="field[@name='Page Number']='1'">
						<crm:P2_has_type rdf:resource="{$nma-term-ns}preferred" />	
					</xsl:if>
					<xsl:for-each select="field[@name='Title']">
						<rdfs:label>
							<xsl:value-of select="." />
						</rdfs:label>
					</xsl:for-each>
					<xsl:for-each select="$related-object-identifiers">
						<crm:P138_represents rdf:resource="object/{translate(., ' ', '')}#" />
						<!-- bundle this media up along with all the other media of this object, into a parallel aggregation which is subject to the re-use rights -->
						<ore:isAggregatedBy rdf:resource="object/{translate(., ' ', '')}#media"/>
					</xsl:for-each>
					<xsl:for-each select="$image-data-sources">
						<crm:P138i_has_representation>
							<crm:E36_Visual_Item rdf:about="{@baseUrl}">
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
									<!-- full resolution in internal API -->
									<xsl:when test="@name = 'original_2'">
										<crm:P2_has_type rdf:resource="{concat($nma-term-ns, 'full')}" />
									</xsl:when>
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
											<rdfs:label>
												<xsl:value-of select="." />
											</rdfs:label>
										</crm:E21_Person>
									</crm:P14_carried_out_by>
								</xsl:for-each>
							</crm:E65_Creation>
						</crm:P94i_was_created_by>
					</xsl:if>
					<crm:P70i_is_documented_in>
						<crm:E31_Document rdf:about="{$visual-item-graph}"><!-- identifies the RDF graph itself -->
							<dc:modified 
								rdf:datatype="http://www.w3.org/2001/XMLSchema#date"
								xmlns:dc="http://purl.org/dc/terms/"><xsl:value-of select="@date-modified" /></dc:modified>
							<crm:P104_is_subject_to rdf:resource="{$nma-term-ns}metadata-rights"/>
						</crm:E31_Document>
					</crm:P70i_is_documented_in>
				</crm:E36_Visual_Item>
			</xsl:if>
		</rdf:RDF>
	</xsl:template>
	
</xsl:stylesheet>
