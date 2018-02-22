<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" 
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns="tag:conaltuohy.com,2018:nma/emu/"
	xmlns:dcterms="http://purl.org/dc/terms/">
	
	<xsl:param name="base-uri"/><!-- e.g. "http://api.nma.gov.au/" -->
	<xsl:param name="record-type"/><!-- e.g. "object", "site", "party", or "narrative" -->
	
	<xsl:template match="/*">
		<rdf:RDF>
			<xsl:attribute name="xml:base" select="$base-uri"/>
			<rdf:Description rdf:about="object/{irn}#">
				<xsl:variable name="leaf-node-elements" select=".//*[not(*)][normalize-space()]"/>
				<xsl:if test="$record-type='object'">
					<dcterms:hasFormat rdf:resource="http://collectionsearch.nma.gov.au/object/{irn}"/>
				</xsl:if>
				<xsl:for-each select="$leaf-node-elements">
					<xsl:element name="{local-name()}">
						<xsl:apply-templates select="." mode="type"/>
						<xsl:apply-templates select="." mode="value"/>
					</xsl:element>
				</xsl:for-each>
			</rdf:Description>
		</rdf:RDF>
	</xsl:template>
	
	<!-- value of some field is just a string literal -->
	<xsl:template mode="value" match="*">
		<xsl:value-of select="."/>
	</xsl:template>
	
	<!-- value is a URI derived from the irn identifying the current record -->
	<xsl:template mode="value" match="irn">
		<xsl:attribute name="rdf:resource" select="concat($record-type, '/', .)"/>
	</xsl:template>
	
	<!-- values of IRNs that refer to foreign records -->
	<xsl:template mode="value" match="AssParentObjectRef | RelRelatedObjectsRef_tab.irn">
		<xsl:attribute name="rdf:resource" select="concat('object/', .)"/>
	</xsl:template>
	
	<xsl:template mode="value" match="ProPersonRef_tab.irn | AssPersonRef_tab.irn">
		<xsl:attribute name="rdf:resource" select="concat('party/', .)"/>
	</xsl:template>
	
	<xsl:template mode="value" match="ProPlaceRef_tab.irn | AssPlaceRef_tab.irn">
		<xsl:attribute name="rdf:resource" select="concat('site/', .)"/>
	</xsl:template>		
	
	<xsl:template mode="type" match="*[@type='integer']">
		<xsl:attribute name="rdf:datatype">http://www.w3.org/2001/XMLSchema#int</xsl:attribute>
	</xsl:template>
	<xsl:template mode="type" match="*[ends-with(local-name(), '_date')]">
		<xsl:attribute name="rdf:datatype">http://www.w3.org/2001/XMLSchema#dateTime</xsl:attribute>
	</xsl:template>
	<!-- type not specified -->
	<xsl:template mode="type" match="*"/>
	
</xsl:stylesheet>
