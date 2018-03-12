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
			<xsl:apply-templates
				select="PhyDescription | PhyContentDescription | StaNmaSOSPublic | CreProvenance">
				<xsl:with-param name="object-iri" select="$object-iri" />
			</xsl:apply-templates>

			<!-- production -->
			<xsl:if test="ProductionParties | ProductionPlaces | ProductionDates">
				<crm:P108i_was_produced_by>
					<crm:E12_Production>
						<crm:P9_consists_of>
							<xsl:apply-templates
								select="ProductionParties | ProductionPlaces | ProductionDates">
								<xsl:with-param name="object-iri" select="$object-iri" />
							</xsl:apply-templates>
						</crm:P9_consists_of>
					</crm:E12_Production>
				</crm:P108i_was_produced_by>
			</xsl:if>

			<!-- materials -->
			<xsl:apply-templates select="PhyMaterials_tab" />

			<!-- dimensions: linear -->
			<xsl:apply-templates
				select="PhyRegistrationLength | PhyRegistrationWidth | PhyRegistrationWidth | PhyRegistrationDepth | PhyRegistrationDiameter">
				<xsl:with-param name="object-iri" select="$object-iri" />
				<xsl:with-param name="unit" select="PhyRegistrationUnitLength" />
			</xsl:apply-templates>

			<!-- dimensions: weight -->
			<xsl:apply-templates select="PhyRegistrationWeight">
				<xsl:with-param name="object-iri" select="$object-iri" />
				<xsl:with-param name="unit" select="PhyRegistrationUnitWeight" />
			</xsl:apply-templates>

			<!-- media -->
			<xsl:apply-templates select="WebMultiMediaRef_tab/image" />

		</rdf:Description>
	</xsl:template>

	<!-- sink to ignore stray partial update records -->
	<xsl:template match="record[./partial_update]">
	</xsl:template>

	<!-- ############### FIELD PROCESSING TEMPLATES ############ -->

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
	<!-- TODO: add support for notes -->

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

	<!-- materials -->
	<xsl:template match="PhyMaterials_tab">
		<xsl:for-each select="PhyMaterial">
			<crm:P45_consists_of>
				<crm:E57_Material>
					<rdfs:label>
						<xsl:value-of select="." />
					</rdfs:label>
				</crm:E57_Material>
			</crm:P45_consists_of>
		</xsl:for-each>
	</xsl:template>

	<!-- dimensions: length -->
	<xsl:template match="PhyRegistrationLength">
		<xsl:param name="object-iri" />
		<xsl:param name="unit" />
		<xsl:call-template name="output-dimension">
			<xsl:with-param name="object-iri" select="$object-iri" />
			<xsl:with-param name="type" select="'length'" />
			<!-- AAT: length -->
			<xsl:with-param name="aat-type" select="'300055645'" />
			<xsl:with-param name="value" select="." />
			<xsl:with-param name="unit-value" select="$unit" />
		</xsl:call-template>
	</xsl:template>

	<!-- dimensions: height -->
	<xsl:template match="PhyRegistrationHeight">
		<xsl:param name="object-iri" />
		<xsl:param name="unit" />
		<xsl:call-template name="output-dimension">
			<xsl:with-param name="object-iri" select="$object-iri" />
			<xsl:with-param name="type" select="'height'" />
			<!-- AAT: height -->
			<xsl:with-param name="aat-type" select="'300055644'" />
			<xsl:with-param name="value" select="." />
			<xsl:with-param name="unit-value" select="$unit" />
		</xsl:call-template>
	</xsl:template>

	<!-- dimensions: width -->
	<xsl:template match="PhyRegistrationWidth">
		<xsl:param name="object-iri" />
		<xsl:param name="unit" />
		<xsl:call-template name="output-dimension">
			<xsl:with-param name="object-iri" select="$object-iri" />
			<xsl:with-param name="type" select="'width'" />
			<!-- AAT: width -->
			<xsl:with-param name="aat-type" select="'300055647'" />
			<xsl:with-param name="value" select="." />
			<xsl:with-param name="unit-value" select="$unit" />
		</xsl:call-template>
	</xsl:template>

	<!-- dimensions: depth -->
	<xsl:template match="PhyRegistrationDepth">
		<xsl:param name="object-iri" />
		<xsl:param name="unit" />
		<xsl:call-template name="output-dimension">
			<xsl:with-param name="object-iri" select="$object-iri" />
			<xsl:with-param name="type" select="'depth'" />
			<!-- AAT: depth (size/dimension) -->
			<xsl:with-param name="aat-type" select="'300072633'" />
			<xsl:with-param name="value" select="." />
			<xsl:with-param name="unit-value" select="$unit" />
		</xsl:call-template>
	</xsl:template>

	<!-- dimensions: diameter -->
	<xsl:template match="PhyRegistrationDiameter">
		<xsl:param name="object-iri" />
		<xsl:param name="unit" />
		<xsl:call-template name="output-dimension">
			<xsl:with-param name="object-iri" select="$object-iri" />
			<xsl:with-param name="type" select="'diameter'" />
			<!-- AAT: diameter -->
			<xsl:with-param name="aat-type" select="'300055624'" />
			<xsl:with-param name="value" select="." />
			<xsl:with-param name="unit-value" select="$unit" />
		</xsl:call-template>
	</xsl:template>

	<!-- dimensions: weight -->
	<xsl:template match="PhyRegistrationWeight">
		<xsl:param name="object-iri" />
		<xsl:param name="unit" />
		<xsl:call-template name="output-dimension">
			<xsl:with-param name="object-iri" select="$object-iri" />
			<xsl:with-param name="type" select="'weight'" />
			<!-- AAT: weight (heaviness attribute) -->
			<xsl:with-param name="aat-type" select="'300056240'" />
			<xsl:with-param name="value" select="." />
			<xsl:with-param name="unit-value" select="$unit" />
		</xsl:call-template>
	</xsl:template>

	<!-- media -->
	<xsl:template match="image">
		<xsl:variable name="media-iri" select="concat('media/', media_irn)" />
		<crm:P138i_has_representation>
			<crm:E36_Visual_Item rdf:about="{$media-iri}">

				<!-- preview -->
				<xsl:for-each select="res640px">
					<crm:P138i_has_representation>
						<crm:E36_Visual_Item rdf:about="{$media-iri}#preview">
							<rdf:value>
								<xsl:value-of select="image_path" />
							</rdf:value>
							<xsl:if test="image_width != ''">
								<crm:P43_has_dimension>
									<crm:E54_Dimension rdf:about="{$media-iri}#previewWidth">
										<rdf:value>
											<xsl:value-of select="image_width" />
										</rdf:value>
										<!-- AAT: width -->
										<crm:P2_has_type rdf:resource="{$aat-ns}300055647" />
										<crm:P91_has_unit>
											<!-- AAT: pixels -->
											<crm:E58_Measurement_Unit rdf:resource="{$aat-ns}300379612" />
										</crm:P91_has_unit>
									</crm:E54_Dimension>
								</crm:P43_has_dimension>
							</xsl:if>
							<xsl:if test="image_height != ''">
								<crm:P43_has_dimension>
									<crm:E54_Dimension rdf:about="{$media-iri}#previewHeight">
										<rdf:value>
											<xsl:value-of select="image_height" />
										</rdf:value>
										<!-- AAT: height -->
										<crm:P2_has_type rdf:resource="{$aat-ns}300055644" />
										<crm:P91_has_unit>
											<!-- AAT: pixels -->
											<crm:E58_Measurement_Unit rdf:resource="{$aat-ns}300379612" />
										</crm:P91_has_unit>
									</crm:E54_Dimension>
								</crm:P43_has_dimension>
							</xsl:if>
						</crm:E36_Visual_Item>
					</crm:P138i_has_representation>
				</xsl:for-each>

				<!-- thumbnail -->
				<xsl:for-each select="res200px">
					<crm:P138i_has_representation>
						<crm:E36_Visual_Item rdf:about="{$media-iri}#thumb">
							<rdf:value>
								<xsl:value-of select="image_path" />
							</rdf:value>
							<xsl:if test="image_width != ''">
								<crm:P43_has_dimension>
									<crm:E54_Dimension rdf:about="{$media-iri}#thumbWidth">
										<rdf:value>
											<xsl:value-of select="image_width" />
										</rdf:value>
										<!-- AAT: width -->
										<crm:P2_has_type rdf:resource="{$aat-ns}300055647" />
										<crm:P91_has_unit>
											<!-- AAT: pixels -->
											<crm:E58_Measurement_Unit rdf:resource="{$aat-ns}300379612" />
										</crm:P91_has_unit>
									</crm:E54_Dimension>
								</crm:P43_has_dimension>
							</xsl:if>
							<xsl:if test="image_height != ''">
								<crm:P43_has_dimension>
									<crm:E54_Dimension rdf:about="{$media-iri}#thumbHeight">
										<rdf:value>
											<xsl:value-of select="image_height" />
										</rdf:value>
										<!-- AAT: height -->
										<crm:P2_has_type rdf:resource="{$aat-ns}300055644" />
										<crm:P91_has_unit>
											<!-- AAT: pixels -->
											<crm:E58_Measurement_Unit rdf:resource="{$aat-ns}300379612" />
										</crm:P91_has_unit>
									</crm:E54_Dimension>
								</crm:P43_has_dimension>
							</xsl:if>
						</crm:E36_Visual_Item>
					</crm:P138i_has_representation>
				</xsl:for-each>

			</crm:E36_Visual_Item>
		</crm:P138i_has_representation>
	</xsl:template>

	<!-- ############### NAMED TEMPLATES ############ -->

	<!-- output a dimension -->
	<xsl:template name="output-dimension">
		<xsl:param name="object-iri" />
		<xsl:param name="type" />
		<xsl:param name="aat-type" />
		<xsl:param name="value" />
		<xsl:param name="unit-value" />
		<crm:P43_has_dimension>
			<crm:E54_Dimension rdf:about="{$object-iri}#{$type}">
				<rdf:value>
					<xsl:value-of select="$value" />
				</rdf:value>
				<crm:P2_has_type rdf:resource="{$aat-ns}{$aat-type}" />
				<!-- TODO: add AAT for relevant unit type -->
				<xsl:if test="$unit-value != ''">
					<crm:P91_has_unit>
						<crm:E58_Measurement_Unit>
							<rdfs:label>
								<xsl:value-of select="$unit-value" />
							</rdfs:label>
						</crm:E58_Measurement_Unit>
					</crm:P91_has_unit>
				</xsl:if>
			</crm:E54_Dimension>
		</crm:P43_has_dimension>
	</xsl:template>

</xsl:stylesheet>
