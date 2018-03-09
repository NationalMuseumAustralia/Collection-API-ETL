<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	version="3.0" xmlns:crm="http://www.cidoc-crm.org/cidoc-crm/" xmlns:aat="http://vocab.getty.edu/aat/"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">

	<!-- record type of the input file, e.g. "Object", "Site", "Party", or "Narrative" -->
	<xsl:param name="record-type" select="'Object'" />
	<xsl:param name="base-uri" select="'https://api.nma.gov.au/'" />

	<xsl:variable name="nma-term-ns" select="'http://nma.tepapa.gov.au/term/'" />
	<xsl:variable name="crm-ns" select="'http://www.cidoc-crm.org/cidoc-crm/'" />
	<xsl:variable name="aat-ns" select="'http://vocab.getty.edu/aat/'" />
	<xsl:variable name="ore-ns" select="'http://www.openarchives.org/ore/terms/'" />

	<xsl:template match="/">
		<rdf:RDF>
			<xsl:attribute name="xml:base" select="$base-uri" />
			<xsl:apply-templates select="record" />
			<!-- for debugging on full XML input file -->
			<xsl:apply-templates select="response/record" />
		</rdf:RDF>
	</xsl:template>

	<xsl:template match="record">
		<xsl:param name="object-record-type" select="lower-case(TitObjectType//text())" />

		<xsl:variable name="object-iri" select="concat(lower-case($record-type), '/', irn)" />

		<rdf:Description rdf:about="{$object-iri}#">

			<!-- type -->
			<xsl:choose>
				<xsl:when test="$record-type='Object'">
					<rdf:type rdf:resource="{$crm-ns}E19_Physical_Object" />
				</xsl:when>
				<xsl:when test="$record-type='Narrative'">
					<rdf:type rdf:resource="{$ore-ns}Aggregation" />
				</xsl:when>
				<xsl:when test="$record-type='Site'">
					<rdf:type rdf:resource="{$crm-ns}E53_Place" />
				</xsl:when>
				<!-- parties -->
				<xsl:otherwise>
					<xsl:choose>
						<xsl:when test="NamPartyType = 'Person'">
							<rdf:type rdf:resource="{$crm-ns}E21_Person" />
						</xsl:when>
						<xsl:otherwise>
							<rdf:type rdf:resource="{$crm-ns}E74_Group" />
						</xsl:otherwise>
					</xsl:choose>
				</xsl:otherwise>
			</xsl:choose>

			<!-- title -->
			<rdfs:label>
				<xsl:value-of select="TitObjectTitle" />
			</rdfs:label>

			<!-- IDs -->

			<!-- irn -->
			<crm:P1_is_identified_by>
				<crm:E42_Identifier rdf:about="{$object-iri}#repositorynumber">
					<rdf:value>
						<xsl:value-of select="irn" />
					</rdf:value>
					<!-- AAT: repository numbers -->
					<crm:P2_has_type rdf:resource="{$aat-ns}300404621" />
				</crm:E42_Identifier>
			</crm:P1_is_identified_by>

			<!-- registration number -->
			<crm:P1_is_identified_by>
				<crm:E42_Identifier rdf:about="{$object-iri}#referencenumber">
					<rdf:value>
						<xsl:value-of select="TitObjectNumber" />
					</rdf:value>
					<!-- AAT: accession numbers -->
					<crm:P2_has_type rdf:resource="{$aat-ns}300312355" />
				</crm:E42_Identifier>
			</crm:P1_is_identified_by>

			<!-- collection -->
			<xsl:apply-templates select="TitCollectionTitle" />

			<!-- descriptions -->
			<xsl:apply-templates select="PhyDescription">
				<xsl:with-param name="object-iri">
					<xsl:value-of select="$object-iri" />
				</xsl:with-param>
			</xsl:apply-templates>
			<xsl:apply-templates select="PhyContentDescription">
				<xsl:with-param name="object-iri">
					<xsl:value-of select="$object-iri" />
				</xsl:with-param>
			</xsl:apply-templates>
			<xsl:apply-templates select="StaNmaSOSPublic">
				<xsl:with-param name="object-iri">
					<xsl:value-of select="$object-iri" />
				</xsl:with-param>
			</xsl:apply-templates>
			<xsl:apply-templates select="CreProvenance">
				<xsl:with-param name="object-iri">
					<xsl:value-of select="$object-iri" />
				</xsl:with-param>
			</xsl:apply-templates>

			<!-- production -->
			<xsl:if test="ProductionParties | ProductionPlaces | ProductionDates">
				<crm:P108i_was_produced_by>
					<crm:E12_Production>
						<crm:P9_consists_of>
							<xsl:apply-templates
								select="ProductionParties | ProductionPlaces | ProductionDates">
								<xsl:with-param name="object-iri">
									<xsl:value-of select="$object-iri" />
								</xsl:with-param>
							</xsl:apply-templates>
						</crm:P9_consists_of>
					</crm:E12_Production>
				</crm:P108i_was_produced_by>
			</xsl:if>

		</rdf:Description>
	</xsl:template>

	<!-- sink to ignore stray partial update records -->
	<xsl:template match="record[./partial_update]">
	</xsl:template>

	<!-- collection -->
	<xsl:template match="TitCollectionTitle">
		<crm:P106i_forms_part_of>
			<crm:E19_Physical_Object>
				<rdf:value>
					<xsl:value-of select="." />
				</rdf:value>
				<!-- AAT: collections (object groupings) -->
				<crm:P2_has_type rdf:resource="{$aat-ns}300025976" />
			</crm:E19_Physical_Object>
		</crm:P106i_forms_part_of>
	</xsl:template>

	<!-- physical description -->
	<xsl:template match="PhyDescription">
		<xsl:param name="object-iri" />
		<crm:P129i_is_subject_of>
			<crm:E33_Linguistic_Object rdf:about="{$object-iri}#physicalDescription">
				<rdf:value>
					<xsl:value-of select="." />
				</rdf:value>
				<!-- AAT: descriptions (documents) -->
				<crm:P2_has_type rdf:resource="{$aat-ns}300411780" />
				<crm:P2_has_type rdf:resource="{$nma-term-ns}physicalDescription" />
			</crm:E33_Linguistic_Object>
		</crm:P129i_is_subject_of>
	</xsl:template>

	<!-- content description -->
	<xsl:template match="PhyContentDescription">
		<xsl:param name="object-iri" />
		<crm:P129i_is_subject_of>
			<crm:E33_Linguistic_Object rdf:about="{$object-iri}#contentDescription">
				<rdf:value>
					<xsl:value-of select="." />
				</rdf:value>
				<!-- AAT: descriptions (documents) -->
				<crm:P2_has_type rdf:resource="{$aat-ns}300411780" />
				<crm:P2_has_type rdf:resource="{$nma-term-ns}contentDescription" />
			</crm:E33_Linguistic_Object>
		</crm:P129i_is_subject_of>
	</xsl:template>

	<!-- statement of signficance -->
	<xsl:template match="StaNmaSOSPublic">
		<xsl:param name="object-iri" />
		<crm:P129i_is_subject_of>
			<crm:E33_Linguistic_Object rdf:about="{$object-iri}#significanceStatement">
				<rdf:value>
					<xsl:value-of select="." />
				</rdf:value>
				<!-- AAT: significance assessments (surveys) -->
				<crm:P2_has_type rdf:resource="{$aat-ns}300379612" />
				<crm:P2_has_type rdf:resource="{$nma-term-ns}significanceStatement" />
			</crm:E33_Linguistic_Object>
		</crm:P129i_is_subject_of>
	</xsl:template>

	<!-- educational signficance -->
	<xsl:template match="CreProvenance">
		<xsl:param name="object-iri" />
		<crm:P129i_is_subject_of>
			<crm:E33_Linguistic_Object rdf:about="{$object-iri}#educationalSignificance">
				<rdf:value>
					<xsl:value-of select="." />
				</rdf:value>
				<!-- AAT: significance assessments (surveys) -->
				<crm:P2_has_type rdf:resource="{$aat-ns}300379612" />
				<crm:P2_has_type rdf:resource="{$nma-term-ns}educationalSignificance" />
			</crm:E33_Linguistic_Object>
		</crm:P129i_is_subject_of>
	</xsl:template>

	<!-- production: places -->
	<xsl:template match="ProductionPlaces">
		<xsl:param name="object-iri" />
		<xsl:for-each select="ProductionPlace">
			<xsl:variable name="place-iri" select="concat('place/', ProPlaceRef_tab.irn)" />
			<crm:E7_Activity>
				<rdfs:label>
					<xsl:value-of select="ProPlaceType_tab" />
				</rdfs:label>
				<crm:P7_took_place_at>
					<rdf:Description rdf:about="{$place-iri}" />
				</crm:P7_took_place_at>
			</crm:E7_Activity>
		</xsl:for-each>

	</xsl:template>

	<!-- TODO: are there organisation producers? -->

	<!-- production: parties -->
	<xsl:template match="ProductionParties">
		<xsl:param name="object-iri" />
		<xsl:for-each select="ProductionParty">
			<xsl:variable name="party-iri" select="concat('party/', ProPersonRef_tab.irn)" />
			<crm:E7_Activity>
				<rdfs:label>
					<xsl:value-of select="ProPersonType_tab" />
				</rdfs:label>
				<crm:P14_carried_out_by>
					<rdf:Description rdf:about="{$party-iri}" />
				</crm:P14_carried_out_by>
			</crm:E7_Activity>
		</xsl:for-each>
	</xsl:template>

	<!-- production: dates -->
	<xsl:template match="ProductionDates">
		<xsl:param name="object-iri" />
		<xsl:for-each select="ProductionDate">
			<crm:E7_Activity>
				<rdfs:label>
					<xsl:value-of select="ProDateType_tab" />
				</rdfs:label>
				<crm:P4_has_time-span>
					<crm:E52_Time-Span>
						<rdfs:label>
							<xsl:value-of select="ProDate0" />
						</rdfs:label>
						<crm:P82a_begin_of_the_begin>
							<xsl:value-of select="ProEarliestDate0" />
						</crm:P82a_begin_of_the_begin>
						<crm:P82b_end_of_the_end>
							<xsl:value-of select="ProLatestDate0" />
						</crm:P82b_end_of_the_end>
					</crm:E52_Time-Span>
				</crm:P4_has_time-span>
			</crm:E7_Activity>
		</xsl:for-each>
	</xsl:template>

</xsl:stylesheet>
