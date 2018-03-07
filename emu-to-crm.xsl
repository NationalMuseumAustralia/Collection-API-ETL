<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	version="3.0" xmlns:crm="http://www.cidoc-crm.org/cidoc-crm/" xmlns:aat="http://vocab.getty.edu/aat/"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">

	<xsl:param name="base-uri" select="'https://api.nma.gov.au'" />
	<xsl:variable name="crm-ns" select="'http://www.cidoc-crm.org/cidoc-crm/'" />
	<xsl:variable name="aat-ns" select="'http://vocab.getty.edu/aat/'" />

	<xsl:template match="/response">
		<rdf:RDF>
			<xsl:attribute name="xml:base" select="$base-uri" />
			<xsl:apply-templates select="record" />
		</rdf:RDF>
	</xsl:template>

	<xsl:template match="record">
		<xsl:param name="record-type" select="lower-case(TitObjectType//text())" />

		<rdf:Description rdf:about="{$base-uri}/{$record-type}/{irn}#">

			<!-- type -->
			<xsl:choose>
				<xsl:when test="$record-type='Object'">
					<rdf:type rdf:resource="{$crm-ns}E19_Physical_Object" />
				</xsl:when>
				<xsl:when test="$record-type='Narrative'">
					<rdf:type rdf:resource="http://www.openarchives.org/ore/terms/Aggregation" />
				</xsl:when>
				<xsl:when test="$record-type='Site'">
					<rdf:type rdf:resource="http://www.cidoc-crm.org/cidoc-crm/E53_Place" />
				</xsl:when>
				<xsl:otherwise><!-- parties -->
					<xsl:choose>
						<xsl:when test="NamPartyType = 'Person'">
							<rdf:type rdf:resource="http://www.cidoc-crm.org/cidoc-crm/E21_Person" />
						</xsl:when>
						<xsl:otherwise>
							<rdf:type rdf:resource="http://www.cidoc-crm.org/cidoc-crm/E74_Group" />
						</xsl:otherwise>
					</xsl:choose>
				</xsl:otherwise>
			</xsl:choose>

			<!-- title -->
			<rdfs:label>
				<xsl:value-of select="TitObjectTitle" />
			</rdfs:label>

			<!-- registration number -->
			<crm:P1_is_identified_by>
				<crm:E42_Identifier rdf:about="{$base-uri}/{$record-type}/{irn}/identifier#referencenumber">
					<rdf:value>
						<xsl:value-of select="TitObjectNumber" />
					</rdf:value>
					<crm:P2_has_type rdf:resource="{$aat-ns}300312355" />
				</crm:E42_Identifier>
			</crm:P1_is_identified_by>

		</rdf:Description>
	</xsl:template>

</xsl:stylesheet>
