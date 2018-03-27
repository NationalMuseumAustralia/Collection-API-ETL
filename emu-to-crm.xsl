<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	version="3.0" xmlns:crm="http://www.cidoc-crm.org/cidoc-crm/" xmlns:la="https://linked.art/ns/terms/"
	xmlns:aat="http://vocab.getty.edu/aat/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#">

	<!-- record type of the input file, e.g. "object", "site", "party", or "narrative" -->
	<xsl:param name="record-type" select="'object'" />
	<xsl:param name="base-uri" select="'https://api.nma.gov.au/'" />
	<xsl:param name="media-uri-base"
		select="'http://collectionsearch.nma.gov.au/nmacs-image-download/emu/'" />

	<xsl:variable name="nma-term-ns" select="concat($base-uri, 'term/')" />
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

			<!-- TODO: could PhysicalObject be split into ManMadeObject and BiologicalObject -->

			<!-- entity type -->
			<!-- http://linked.art/model/object/identity/#types -->
			<!-- http://linked.art/model/actor/#types -->
			<xsl:choose>
				<xsl:when test="$record-type='object'">
					<rdf:type rdf:resource="{$crm-ns}E19_Physical_Object" />
				</xsl:when>
				<xsl:when test="$record-type='narrative'">
					<rdf:type rdf:resource="{$ore-ns}Aggregation" />
				</xsl:when>
				<xsl:when test="$record-type='site'">
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

			<!-- COMMON FIELDS -->

			<!-- irn -->
			<xsl:apply-templates select="irn">
				<xsl:with-param name="object-iri" select="$object-iri" />
			</xsl:apply-templates>

			<!-- OBJECT FIELDS -->

			<!-- registration number -->
			<xsl:apply-templates select="TitObjectNumber">
				<xsl:with-param name="object-iri" select="$object-iri" />
			</xsl:apply-templates>

			<!-- title -->
			<xsl:apply-templates select="TitObjectTitle" />

			<!-- collection -->
			<xsl:apply-templates select="TitCollectionTitle" />

			<!-- object type -->
			<xsl:apply-templates select="TitObjectName" />
			
			<!-- TODO: add secondary object type -->

			<!-- descriptions -->
			<xsl:apply-templates
				select="PhyDescription | PhyContentDescription | StaNmaSOSPublic | CreProvenance">
				<xsl:with-param name="object-iri" select="$object-iri" />
			</xsl:apply-templates>

			<!-- production -->
			<!-- http://linked.art/model/provenance/production.html -->
			<!-- NB: modeled as a single production event consisting of multiple activities -->
			<xsl:if test="ProductionParties | ProductionPlaces | ProductionDates">
				<crm:P108i_was_produced_by>
					<crm:E12_Production>
						<xsl:apply-templates
							select="ProductionParties | ProductionPlaces | ProductionDates">
							<xsl:with-param name="object-iri" select="$object-iri" />
						</xsl:apply-templates>
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

			<!-- associations -->
			<xsl:apply-templates select="AssociatedParties | AssociatedPlaces | AssociatedDates" />

			<!-- TODO: exclude credit line if RigAcknowledgement=false -->

			<!-- acknowledgement -->
			<xsl:apply-templates select="RigCreditLine2">
				<xsl:with-param name="object-iri" select="$object-iri" />
			</xsl:apply-templates>
			
			<!-- rights -->
			<xsl:apply-templates select="AcsCCStatus">
				<xsl:with-param name="object-iri" select="$object-iri" />
			</xsl:apply-templates>

			<!-- exhibition location -->
			<xsl:apply-templates select="LocCurrentLocationRef">
				<xsl:with-param name="object-iri" select="$object-iri" />
			</xsl:apply-templates>

			<!-- media -->
			<xsl:apply-templates select="WebMultiMediaRef_tab/image" />

			<!-- PARTY FIELDS -->

			<!-- organisation name -->
			<!-- http://linked.art/model/actor/#names -->
			<xsl:apply-templates select="NamOrganisation">
				<xsl:with-param name="party-iri" select="concat('party/', irn)" />
			</xsl:apply-templates>

			<!-- person names -->
			<!-- http://linked.art/model/actor/#names -->
			<!-- NB: modeled as full name composed of multiple parts -->
			<xsl:if test="NamFullName">
				<xsl:variable name="party-iri" select="concat('party/', irn)" />
				<crm:P1_is_identified_by>
					<la:Name rdf:about="{$party-iri}#name">
						<rdf:value>
							<xsl:value-of select="NamFullName" />
						</rdf:value>
						<!-- AAT 300404670: preferred terms -->
						<crm:P2_has_type rdf:resource="{$aat-ns}300404670" />
						<!-- AAT 300404688: full names (personal names) -->
						<crm:P2_has_type rdf:resource="{$aat-ns}300404688" />
						<xsl:apply-templates select="NamFirst | NamMiddle | NamLast | NamOtherNames_tab" />
					</la:Name>
				</crm:P1_is_identified_by>
			</xsl:if>

			<!-- gender -->
			<xsl:apply-templates select="NamSex" />

			<!-- PLACE FIELDS -->

			<!-- formatted label -->
			<xsl:if test="$record-type='site'">
				<xsl:variable name="concatenatedLabel">
					<xsl:apply-templates select="LocSpecialGeographicUnit_tab"
						mode="label" />
					<xsl:apply-templates select="LocNearestNamedPlace_tab"
						mode="label" />
					<xsl:apply-templates select="LocTownship_tab" mode="label" />
					<xsl:apply-templates select="LocDistrictCountyShire_tab"
						mode="label" />
					<xsl:apply-templates select="LocProvinceStateTerritory_tab"
						mode="label" />
					<xsl:apply-templates select="LocCountry_tab" mode="label" />
					<xsl:apply-templates select="LocContinent_tab" mode="label" />
					<xsl:apply-templates select="LocOcean_tab" mode="label" />
				</xsl:variable>
				<rdfs:label>
					<!-- remove trailing ', ' -->
					<xsl:value-of
						select="substring($concatenatedLabel, 1, string-length($concatenatedLabel)-2)" />
				</rdfs:label>
			</xsl:if>

			<!-- geo coordinates -->
			<xsl:if test="LatCentroidLatitudeDec_tab | LatCentroidLongitudeDec_tab">
				<crm:P168_place_is_defined_by rdf:resource="{$object-iri}#location">
					<crm:E94_Space_Primitive>
						<rdf:value>
							<xsl:value-of select="LatCentroidLatitudeDec_tab" />
							<xsl:text>,</xsl:text>
							<xsl:value-of select="LatCentroidLongitudeDec_tab" />
						</rdf:value>
						<!-- AAT 300380194: geospatial data -->
						<crm:P2_has_type rdf:resource="{$aat-ns}300380194" />
					</crm:E94_Space_Primitive>
				</crm:P168_place_is_defined_by>
			</xsl:if>

		</rdf:Description>
	</xsl:template>

	<!-- sink to ignore stray partial update records -->
	<xsl:template match="record[./partial_update]">
	</xsl:template>

	<!-- ############### FIELD PROCESSING TEMPLATES ############ -->

	<!-- COMMON -->

	<!-- irn -->
	<!-- http://linked.art/model/object/identity/#identifier -->
	<xsl:template match="irn">
		<xsl:param name="object-iri" />
		<crm:P1_is_identified_by>
			<crm:E42_Identifier rdf:about="{$object-iri}#repositorynumber">
				<rdf:value>
					<xsl:value-of select="." />
				</rdf:value>
				<!-- AAT 300404621: repository numbers -->
				<crm:P2_has_type rdf:resource="{$aat-ns}300404621" />
			</crm:E42_Identifier>
		</crm:P1_is_identified_by>
	</xsl:template>

	<!-- OBJECT -->

	<!-- registration number -->
	<!-- http://linked.art/model/object/identity/#identifier -->
	<xsl:template match="TitObjectNumber">
		<xsl:param name="object-iri" />
		<crm:P1_is_identified_by>
			<crm:E42_Identifier rdf:about="{$object-iri}#referencenumber">
				<rdf:value>
					<xsl:value-of select="." />
				</rdf:value>
				<!-- AAT 300312355: accession numbers -->
				<crm:P2_has_type rdf:resource="{$aat-ns}300312355" />
			</crm:E42_Identifier>
		</crm:P1_is_identified_by>
	</xsl:template>

	<!-- title -->
	<!-- http://linked.art/model/object/identity/#titles -->
	<xsl:template match="TitObjectTitle">
		<rdfs:label>
			<xsl:value-of select="." />
		</rdfs:label>
	</xsl:template>

	<!-- collection -->
	<!-- https://linked.art/cookbook/getty/photoarchive/ -->
	<xsl:template match="TitCollectionTitle">
		<crm:P106i_forms_part_of>
			<crm:E19_Physical_Object>
				<rdf:value>
					<xsl:value-of select="." />
				</rdf:value>
				<!-- AAT 300025976: collections (object groupings) -->
				<crm:P2_has_type rdf:resource="{$aat-ns}300025976" />
			</crm:E19_Physical_Object>
		</crm:P106i_forms_part_of>
	</xsl:template>

	<!-- object type -->
	<xsl:template match="TitObjectName">
		<crm:P2_has_type>
			<rdf:Description>
				<rdfs:label>
					<xsl:value-of select="." />
				</rdfs:label>
			</rdf:Description>
		</crm:P2_has_type>
	</xsl:template>

	<!-- physical description -->
	<!-- http://linked.art/model/object/aboutness/#description -->
	<xsl:template match="PhyDescription">
		<xsl:param name="object-iri" />
		<crm:P129i_is_subject_of>
			<crm:E33_Linguistic_Object rdf:about="{$object-iri}#physicalDescription">
				<rdf:value>
					<xsl:value-of select="." />
				</rdf:value>
				<!-- AAT 300411780: descriptions (documents) -->
				<crm:P2_has_type rdf:resource="{$aat-ns}300411780" />
				<crm:P2_has_type rdf:resource="{$nma-term-ns}physicalDescription" />
			</crm:E33_Linguistic_Object>
		</crm:P129i_is_subject_of>
	</xsl:template>

	<!-- content description -->
	<!-- http://linked.art/model/object/aboutness/#description -->
	<xsl:template match="PhyContentDescription">
		<xsl:param name="object-iri" />
		<crm:P129i_is_subject_of>
			<crm:E33_Linguistic_Object rdf:about="{$object-iri}#contentDescription">
				<rdf:value>
					<xsl:value-of select="." />
				</rdf:value>
				<!-- AAT 300411780: descriptions (documents) -->
				<crm:P2_has_type rdf:resource="{$aat-ns}300411780" />
				<crm:P2_has_type rdf:resource="{$nma-term-ns}contentDescription" />
			</crm:E33_Linguistic_Object>
		</crm:P129i_is_subject_of>
	</xsl:template>

	<!-- statement of significance (usually stated at collection level) -->
	<!-- http://linked.art/model/object/aboutness/#description -->
	<xsl:template match="StaNmaSOSPublic">
		<xsl:param name="object-iri" />
		<crm:P129i_is_subject_of>
			<crm:E33_Linguistic_Object rdf:about="{$object-iri}#significanceStatement">
				<rdf:value>
					<xsl:value-of select="." />
				</rdf:value>
				<!-- AAT 300379612: significance assessments (surveys) -->
				<crm:P2_has_type rdf:resource="{$aat-ns}300379612" />
				<crm:P2_has_type rdf:resource="{$nma-term-ns}significanceStatement" />
			</crm:E33_Linguistic_Object>
		</crm:P129i_is_subject_of>
	</xsl:template>

	<!-- educational significance (usually stated at collection level) -->
	<!-- http://linked.art/model/object/aboutness/#description -->
	<xsl:template match="CreProvenance">
		<xsl:param name="object-iri" />
		<crm:P129i_is_subject_of>
			<crm:E33_Linguistic_Object rdf:about="{$object-iri}#educationalSignificance">
				<rdf:value>
					<xsl:value-of select="." />
				</rdf:value>
				<!-- AAT 300379612: significance assessments (surveys) -->
				<crm:P2_has_type rdf:resource="{$aat-ns}300379612" />
				<crm:P2_has_type rdf:resource="{$nma-term-ns}educationalSignificance" />
			</crm:E33_Linguistic_Object>
		</crm:P129i_is_subject_of>
	</xsl:template>

	<!-- TODO: add support for notes -->

	<!-- production: parties -->
	<!-- http://linked.art/model/provenance/production.html -->
	<!-- TODO: change to CRM's proposed party in-the-role-of version once Linked Art ratify -->
	<!-- SEE: http://lists.ics.forth.gr/pipermail/crm-sig/2018-March/003300.html -->
	<xsl:template match="ProductionParties">
		<xsl:param name="object-iri" />
		<xsl:for-each select="ProductionParty">
			<xsl:variable name="party-iri" select="concat('party/', ProPersonRef_tab.irn, '#')" />
			<crm:P9_consists_of>
				<crm:E7_Activity>
					<rdfs:label>
						<xsl:value-of select="ProPersonType_tab" />
					</rdfs:label>
					<crm:P14_carried_out_by>
						<rdf:Description rdf:about="{$party-iri}" />
					</crm:P14_carried_out_by>
				</crm:E7_Activity>
			</crm:P9_consists_of>
		</xsl:for-each>
	</xsl:template>
	
	<!-- TODO: CRM's proposed party in-the-role-of version - to use once Linked Art ratify -->
	<!-- 
	<xsl:template match="ProductionParties">
		<xsl:param name="object-iri" />
		<xsl:for-each select="ProductionParty">
			<xsl:variable name="party-iri" select="concat('party/', ProPersonRef_tab.irn, '#')" />
			<crm:P9_consists_of>
				<crm:E7_Activity>
					<crm:PC14_carried_out_by>
						<rdf:Description>
							<crm:P02_has_range rdf:resource="{$party-iri}" />
							<crm:P14.1_in_the_role_of>
								<crm:E55_Type>
									<rdfs:label>
										<xsl:value-of select="ProPersonType_tab" />
									</rdfs:label>
								</crm:E55_Type>
							</crm:P14.1_in_the_role_of>
						</rdf:Description>
					</crm:PC14_carried_out_by>
				</crm:E7_Activity>
			</crm:P9_consists_of>
		</xsl:for-each>
	</xsl:template>
	 -->	

	<!-- production: places -->
	<!-- http://linked.art/model/provenance/production.html -->
	<!-- TODO: remove role label once joined with main event using EMu keys -->
	<xsl:template match="ProductionPlaces">
		<xsl:param name="object-iri" />
		<xsl:for-each select="ProductionPlace">
			<xsl:variable name="place-iri" select="concat('place/', ProPlaceRef_tab.irn, '#')" />
			<crm:P9_consists_of>
				<crm:E7_Activity>
					<rdfs:label>
						<xsl:value-of select="ProPlaceType_tab" />
					</rdfs:label>
					<crm:P7_took_place_at>
						<rdf:Description rdf:about="{$place-iri}" />
					</crm:P7_took_place_at>
				</crm:E7_Activity>
			</crm:P9_consists_of>
		</xsl:for-each>
	</xsl:template>

	<!-- production: dates -->
	<!-- http://linked.art/model/provenance/production.html -->
	<!-- TODO: remove role label once joined with main event using EMu keys -->
	<xsl:template match="ProductionDates">
		<xsl:param name="object-iri" />
		<xsl:for-each select="ProductionDate">
			<crm:P9_consists_of>
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
			</crm:P9_consists_of>
		</xsl:for-each>
	</xsl:template>

	<!-- association: parties -->
	<!-- NB: modeled as an 'association event' that the party was present at -->
	<xsl:template match="AssociatedParties">
		<xsl:for-each select="AssociatedParty">
			<xsl:variable name="party-iri" select="concat('party/', AssPersonRef_tab.irn, '#')" />
			<crm:P12i_was_present_at>
				<crm:E5_Event>
					<rdfs:label>
						<xsl:value-of select="AssPersonType_tab" />
					</rdfs:label>
					<xsl:if test="AssPersonNotes_tab">
						<crm:P129i_is_subject_of>
							<crm:E33_Linguistic_Object>
								<rdf:value>
									<xsl:value-of select="AssPersonNotes_tab" />
								</rdf:value>
								<!-- AAT 300411780: descriptions (documents) -->
								<crm:P2_has_type rdf:resource="{$aat-ns}300411780" />
							</crm:E33_Linguistic_Object>
						</crm:P129i_is_subject_of>
					</xsl:if>
					<crm:P12_occurred_in_the_presence_of
						rdf:resource="{$party-iri}" />
				</crm:E5_Event>
			</crm:P12i_was_present_at>
		</xsl:for-each>
	</xsl:template>

	<!-- TODO: probably change from crm:P12i_was_present_at to crm:P4_has_time-span and crm:P7_took_place_at-->

	<!-- association: places -->
	<!-- NB: modeled as an 'association event' that the place was present at -->
	<xsl:template match="AssociatedPlaces">
		<xsl:for-each select="AssociatedPlace">
			<xsl:variable name="place-iri" select="concat('place/', AssPlaceRef_tab.irn, '#')" />
			<crm:P12i_was_present_at>
				<crm:E5_Event>
					<rdfs:label>
						<xsl:value-of select="AssPlaceType_tab" />
					</rdfs:label>
					<xsl:if test="AssPlaceNotes_tab">
						<crm:P129i_is_subject_of>
							<crm:E33_Linguistic_Object>
								<rdf:value>
									<xsl:value-of select="AssPlaceNotes_tab" />
								</rdf:value>
								<!-- AAT 300411780: descriptions (documents) -->
								<crm:P2_has_type rdf:resource="{$aat-ns}300411780" />
							</crm:E33_Linguistic_Object>
						</crm:P129i_is_subject_of>
					</xsl:if>
					<crm:P12_occurred_in_the_presence_of
						rdf:resource="{$place-iri}" />
				</crm:E5_Event>
			</crm:P12i_was_present_at>
		</xsl:for-each>
	</xsl:template>

	<!-- association: dates -->
	<!-- NB: modeled as an 'association event' that the date was present at -->
	<xsl:template match="AssociatedDates">
		<xsl:for-each select="AssociatedDates">
			<crm:P12i_was_present_at>
				<crm:E5_Event>
					<rdfs:label>
						<xsl:value-of select="AssDateType_tab" />
					</rdfs:label>
					<xsl:if test="AssDateNotes_tab">
						<crm:P129i_is_subject_of>
							<crm:E33_Linguistic_Object>
								<rdf:value>
									<xsl:value-of select="AssDateNotes_tab" />
								</rdf:value>
								<!-- AAT 300411780: descriptions (documents) -->
								<crm:P2_has_type rdf:resource="{$aat-ns}300411780" />
							</crm:E33_Linguistic_Object>
						</crm:P129i_is_subject_of>
					</xsl:if>
					<crm:P4_has_time-span>
						<crm:E52_Time-Span>
							<rdfs:label>
								<xsl:value-of select="AssDate0" />
							</rdfs:label>
							<crm:P82a_begin_of_the_begin>
								<xsl:value-of select="AssEarliestDate0" />
							</crm:P82a_begin_of_the_begin>
							<crm:P82b_end_of_the_end>
								<xsl:value-of select="AssLatestDate0" />
							</crm:P82b_end_of_the_end>
						</crm:E52_Time-Span>
					</crm:P4_has_time-span>
				</crm:E5_Event>
			</crm:P12i_was_present_at>
		</xsl:for-each>
	</xsl:template>

	<!-- materials -->
	<!-- http://linked.art/model/object/physical/#materials -->
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
	<!-- http://linked.art/model/object/physical/#dimensions -->
	<xsl:template match="PhyRegistrationLength">
		<xsl:param name="object-iri" />
		<xsl:param name="unit" />
		<xsl:call-template name="output-dimension">
			<xsl:with-param name="dimension-iri" select="concat($object-iri,'#length')" />
			<!-- AAT 300055645: length -->
			<xsl:with-param name="aat-type" select="'300055645'" />
			<xsl:with-param name="value" select="." />
			<xsl:with-param name="unit-value" select="$unit" />
		</xsl:call-template>
	</xsl:template>

	<!-- dimensions: height -->
	<!-- http://linked.art/model/object/physical/#dimensions -->
	<xsl:template match="PhyRegistrationHeight">
		<xsl:param name="object-iri" />
		<xsl:param name="unit" />
		<xsl:call-template name="output-dimension">
			<xsl:with-param name="dimension-iri" select="concat($object-iri,'#height')" />
			<!-- AAT 300055644: height -->
			<xsl:with-param name="aat-type" select="'300055644'" />
			<xsl:with-param name="value" select="." />
			<xsl:with-param name="unit-value" select="$unit" />
		</xsl:call-template>
	</xsl:template>

	<!-- dimensions: width -->
	<!-- http://linked.art/model/object/physical/#dimensions -->
	<xsl:template match="PhyRegistrationWidth">
		<xsl:param name="object-iri" />
		<xsl:param name="unit" />
		<xsl:call-template name="output-dimension">
			<xsl:with-param name="dimension-iri" select="concat($object-iri,'#width')" />
			<!-- AAT 300055647: width -->
			<xsl:with-param name="aat-type" select="'300055647'" />
			<xsl:with-param name="value" select="." />
			<xsl:with-param name="unit-value" select="$unit" />
		</xsl:call-template>
	</xsl:template>

	<!-- dimensions: depth -->
	<!-- http://linked.art/model/object/physical/#dimensions -->
	<xsl:template match="PhyRegistrationDepth">
		<xsl:param name="object-iri" />
		<xsl:param name="unit" />
		<xsl:call-template name="output-dimension">
			<xsl:with-param name="dimension-iri" select="concat($object-iri,'#depth')" />
			<!-- AAT 300072633: depth (size/dimension) -->
			<xsl:with-param name="aat-type" select="'300072633'" />
			<xsl:with-param name="value" select="." />
			<xsl:with-param name="unit-value" select="$unit" />
		</xsl:call-template>
	</xsl:template>

	<!-- dimensions: diameter -->
	<!-- http://linked.art/model/object/physical/#dimensions -->
	<xsl:template match="PhyRegistrationDiameter">
		<xsl:param name="object-iri" />
		<xsl:param name="unit" />
		<xsl:call-template name="output-dimension">
			<xsl:with-param name="dimension-iri" select="concat($object-iri,'#diameter')" />
			<!-- AAT 300055624: diameter -->
			<xsl:with-param name="aat-type" select="'300055624'" />
			<xsl:with-param name="value" select="." />
			<xsl:with-param name="unit-value" select="$unit" />
		</xsl:call-template>
	</xsl:template>

	<!-- dimensions: weight -->
	<!-- http://linked.art/model/object/physical/#dimensions -->
	<xsl:template match="PhyRegistrationWeight">
		<xsl:param name="object-iri" />
		<xsl:param name="unit" />
		<xsl:call-template name="output-dimension">
			<xsl:with-param name="dimension-iri" select="concat($object-iri,'#weight')" />
			<!-- AAT 300056240: weight (heaviness attribute) -->
			<xsl:with-param name="aat-type" select="'300056240'" />
			<xsl:with-param name="value" select="." />
			<xsl:with-param name="unit-value" select="$unit" />
		</xsl:call-template>
	</xsl:template>

	<!-- acknowledgement -->
	<!-- https://linked.art/model/object/rights/#credit-attribution-statement -->
	<xsl:template match="RigCreditLine2">
		<xsl:param name="object-iri" />
		<crm:P67i_is_referred_to_by>
			<crm:E33_Linguistic_Object rdf:about="{$object-iri}#acknowledgement">
				<rdf:value>
					<xsl:value-of select="." />
				</rdf:value>
				<!-- AAT 300026687: acknowledgements -->
				<crm:P2_has_type rdf:resource="{$aat-ns}300026687" />
			</crm:E33_Linguistic_Object>
		</crm:P67i_is_referred_to_by>
	</xsl:template>

	<!-- TODO: should CC licences be no-derivatives? -->
	<!-- TODO: look at rightsstatements.org as suggested by Linked Art -->
	
	<!-- rights -->
	<!-- https://linked.art/model/object/rights/#rights-assertions -->
	<xsl:template match="AcsCCStatus">
		<xsl:param name="object-iri" />
		<crm:P104_is_subject_to>
			<xsl:choose>
				<xsl:when test=". = 'Public Domain'">
					<crm:E30_Right rdf:about="https://creativecommons.org/publicdomain/zero/1.0/">
						<rdf:value>
							<xsl:text>CC PD 1.0</xsl:text>
						</rdf:value>
					</crm:E30_Right>
				</xsl:when>
				<xsl:when test=". = 'Creative Commons Commercial Use'">
					<crm:E30_Right rdf:about="https://creativecommons.org/licenses/by/4.0/">
						<rdf:value>
							<xsl:text>CC BY 4.0</xsl:text>
						</rdf:value>
					</crm:E30_Right>
				</xsl:when>
				<xsl:when test=". = 'Creative Commons Non-commercial Use'">
					<crm:E30_Right rdf:about="https://creativecommons.org/licenses/by-nc/4.0/">
						<rdf:value>
							<xsl:text>CC BY-NC 4.0</xsl:text>
						</rdf:value>
					</crm:E30_Right>
				</xsl:when>
				<!-- fall back to most conservative -->
				<xsl:otherwise>
					<crm:E30_Right rdf:about="http://rightsstatements.org/vocab/InC/1.0/">
						<rdf:value>
							<xsl:text>All Rights Reserved</xsl:text>
						</rdf:value>
					</crm:E30_Right>
				</xsl:otherwise>
			</xsl:choose>
		</crm:P104_is_subject_to>
	</xsl:template>

	<!-- TODO: add additional location levels and ancestor structure -->

	<!-- exhibition location -->
	<!-- https://linked.art/model/exhibition/ -->
	<xsl:template match="LocCurrentLocationRef">
		<crm:P16i_was_used_for>
			<crm:E7_Activity>
				<rdfs:label>
					<xsl:if test="LocLevel4">
						<xsl:value-of select="LocLevel4" />
					</xsl:if>
					<xsl:if test="LocLevel3">
						<xsl:text>, </xsl:text>
						<xsl:value-of select="LocLevel3" />
					</xsl:if>
					<xsl:if test="LocLevel2">
						<xsl:text>, </xsl:text>
						<xsl:value-of select="LocLevel2" />
					</xsl:if>
					<xsl:if test="LocLevel1">
						<xsl:text>, </xsl:text>
						<xsl:value-of select="LocLevel1" />
					</xsl:if>
				</rdfs:label>
				<!-- AAT 300054766: exhibitions (events) -->
				<crm:P2_has_type rdf:resource="{$aat-ns}300054766" />
			</crm:E7_Activity>
		</crm:P16i_was_used_for>
	</xsl:template>

	<!-- media -->
	<!-- https://linked.art/model/object/digital/ -->
	<xsl:template match="image">
		<xsl:variable name="media-iri" select="concat('media/', media_irn)" />
		<crm:P138i_has_representation>
			<crm:E36_Visual_Item rdf:about="{$media-iri}#">

				<!-- TODO: add identified_by for media IRN -->
				<!-- TODO: add mime type/format -->

				<!-- preview -->
				<xsl:for-each select="res640px">
					<crm:P138i_has_representation>
						<crm:E36_Visual_Item rdf:about="{concat($media-uri-base, image_path)}">
							<crm:P2_has_type rdf:resource="{$nma-term-ns}preview" />
							<xsl:if test="image_width != ''">
								<xsl:call-template name="output-dimension">
									<xsl:with-param name="dimension-iri"
										select="concat($media-iri,'#previewWidth')" />
									<!-- AAT 300055647: width -->
									<xsl:with-param name="aat-type" select="'300055647'" />
									<xsl:with-param name="value" select="image_width" />
									<!-- TODO: add AAT 300379612: pixels -->
									<xsl:with-param name="unit-value" select="'pixels'" />
								</xsl:call-template>
							</xsl:if>
							<xsl:if test="image_height != ''">
								<xsl:call-template name="output-dimension">
									<xsl:with-param name="dimension-iri"
										select="concat($media-iri,'#previewHeight')" />
									<!-- AAT 300055644: height -->
									<xsl:with-param name="aat-type" select="'300055644'" />
									<xsl:with-param name="value" select="image_height" />
									<!-- TODO: add AAT 300379612: pixels -->
									<xsl:with-param name="unit-value" select="'pixels'" />
								</xsl:call-template>
							</xsl:if>
						</crm:E36_Visual_Item>
					</crm:P138i_has_representation>
				</xsl:for-each>

				<!-- thumbnail -->
				<xsl:for-each select="res200px">
					<crm:P138i_has_representation>
						<crm:E36_Visual_Item rdf:about="{concat($media-uri-base, image_path)}">
							<crm:P2_has_type rdf:resource="{$nma-term-ns}thumbnail" />
							<xsl:if test="image_width != ''">
								<xsl:call-template name="output-dimension">
									<xsl:with-param name="dimension-iri" select="concat($media-iri,'#thumbWidth')" />
									<!-- AAT 300055647: width -->
									<xsl:with-param name="aat-type" select="'300055647'" />
									<xsl:with-param name="value" select="image_width" />
									<!-- TODO: add AAT 300379612: pixels -->
									<xsl:with-param name="unit-value" select="'pixels'" />
								</xsl:call-template>
							</xsl:if>
							<xsl:if test="image_height != ''">
								<xsl:call-template name="output-dimension">
									<xsl:with-param name="dimension-iri" select="concat($media-iri,'#thumbHeight')" />
									<!-- AAT 300055644: height -->
									<xsl:with-param name="aat-type" select="'300055644'" />
									<xsl:with-param name="value" select="image_height" />
									<!-- TODO: add AAT 300379612: pixels -->
									<xsl:with-param name="unit-value" select="'pixels'" />
								</xsl:call-template>
							</xsl:if>
						</crm:E36_Visual_Item>
					</crm:P138i_has_representation>
				</xsl:for-each>

			</crm:E36_Visual_Item>
		</crm:P138i_has_representation>
	</xsl:template>

	<!-- PARTY -->

	<!-- organisation name -->
	<xsl:template match="NamOrganisation">
		<xsl:param name="party-iri" />
		<rdfs:label>
			<xsl:value-of select="." />
		</rdfs:label>
	</xsl:template>

	<!-- first names (component of full name) -->
	<!-- http://linked.art/model/actor/#names -->
	<xsl:template match="NamFirst">
		<crm:P106_is_composed_of>
			<la:Name>
				<rdf:value>
					<xsl:value-of select="." />
				</rdf:value>
				<!-- AAT 300404651: first names -->
				<crm:P2_has_type rdf:resource="{$aat-ns}300404651" />
			</la:Name>
		</crm:P106_is_composed_of>
	</xsl:template>

	<!-- middle names (component of full name) -->
	<!-- http://linked.art/model/actor/#names -->
	<xsl:template match="NamMiddle">
		<crm:P106_is_composed_of>
			<la:Name>
				<rdf:value>
					<xsl:value-of select="." />
				</rdf:value>
				<!-- AAT 300404654: middle names -->
				<crm:P2_has_type rdf:resource="{$aat-ns}300404654" />
			</la:Name>
		</crm:P106_is_composed_of>
	</xsl:template>

	<!-- last names (component of full name) -->
	<!-- http://linked.art/model/actor/#names -->
	<xsl:template match="NamLast">
		<crm:P106_is_composed_of>
			<la:Name>
				<rdf:value>
					<xsl:value-of select="." />
				</rdf:value>
				<!-- AAT 300404652: last names -->
				<crm:P2_has_type rdf:resource="{$aat-ns}300404652" />
			</la:Name>
		</crm:P106_is_composed_of>
	</xsl:template>

	<!-- TODO: are other names part of full name or a separate entity? -->

	<!-- other names (component of full name) -->
	<!-- http://linked.art/model/actor/#names -->
	<xsl:template match="NamOtherNames_tab">
		<xsl:for-each select="NamOtherName">
			<crm:P106_is_composed_of>
				<la:Name>
					<rdf:value>
						<xsl:value-of select="." />
					</rdf:value>
					<!-- AAT 300264273: nonpreferred terms -->
					<crm:P2_has_type rdf:resource="{$aat-ns}300264273" />
				</la:Name>
			</crm:P106_is_composed_of>
		</xsl:for-each>
	</xsl:template>

	<!-- gender -->
	<!-- http://linked.art/model/actor/#gender -->
	<xsl:template match="NamSex">
		<xsl:choose>
			<xsl:when test=".='Female'">
				<crm:P107i_is_current_or_former_member_of>
					<crm:E74_Group>
						<rdfs:label>
							<xsl:text>female</xsl:text>
						</rdfs:label>
						<!-- AAT 300055147: sex role -->
						<crm:P2_has_type rdf:resource="{$aat-ns}300055147" />
						<!-- AAT 300189557"]: female -->
						<crm:P2_has_type rdf:resource="{$aat-ns}300189557" />
					</crm:E74_Group>
				</crm:P107i_is_current_or_former_member_of>
			</xsl:when>
			<xsl:when test=".='Male'">
				<crm:P107i_is_current_or_former_member_of>
					<crm:E74_Group>
						<rdfs:label>
							<xsl:text>male</xsl:text>
						</rdfs:label>
						<!-- AAT 300055147: sex role -->
						<crm:P2_has_type rdf:resource="{$aat-ns}300055147" />
						<!-- AAT 300189559"]: male -->
						<crm:P2_has_type rdf:resource="{$aat-ns}300189559" />
					</crm:E74_Group>
				</crm:P107i_is_current_or_former_member_of>
			</xsl:when>
			<xsl:otherwise>
				<crm:P107i_is_current_or_former_member_of>
					<crm:E74_Group>
						<rdfs:label>
							<xsl:value-of select="." />
						</rdfs:label>
						<!-- AAT 300055147: sex role -->
						<crm:P2_has_type rdf:resource="{$aat-ns}300055147" />
					</crm:E74_Group>
				</crm:P107i_is_current_or_former_member_of>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- PLACE -->

	<!-- TODO: add ancestor locations -->

	<!-- place label -->
	<!-- http://linked.art/model/base/#locations -->
	<xsl:template
		match="LocSpecialGeographicUnit_tab | LocNearestNamedPlace_tab | LocTownship_tab | LocDistrictCountyShire_tab | LocProvinceStateTerritory_tab | LocCountry_tab | LocContinent_tab | LocOcean_tab"
		mode="label">
		<xsl:value-of select="." />
		<xsl:text>, </xsl:text>
	</xsl:template>

	<!-- ############### NAMED TEMPLATES ############ -->

	<!-- output a dimension -->
	<xsl:template name="output-dimension">
		<xsl:param name="dimension-iri" />
		<xsl:param name="aat-type" />
		<xsl:param name="value" />
		<xsl:param name="unit-value" />
		<crm:P43_has_dimension>
			<crm:E54_Dimension rdf:about="{$dimension-iri}">
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
