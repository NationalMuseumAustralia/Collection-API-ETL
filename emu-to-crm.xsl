<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" 
	xmlns:crm="http://www.cidoc-crm.org/cidoc-crm/" 
	xmlns:la="https://linked.art/ns/terms/"
	xmlns:aat="http://vocab.getty.edu/aat/" 
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" 
	xmlns:ore="http://www.openarchives.org/ore/terms/"
	xmlns:dc="http://purl.org/dc/terms/"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:dateutil="tag:conaltuohy.com,2018:nma/date-util"
	xmlns:uri="tag:conaltuohy.com,2018:nma/uri-utility">
	
	<xsl:import href="util/date-util-functions.xsl"/>

	<!-- record type of the input file, e.g. "object", "place", "party", or "narrative" -->
	<xsl:variable name="record-type" select="
		if (exists(//TitObjectNumber)) then 'object' else
		if (exists(//NarTitle)) then 'narrative' else
		if (exists(
			//NamOrganisation | //NamFirst | //NamFirst | //NamMiddle | //NamLast | //NamOtherNames_tab
		)) then 'party' else
		if (exists(
			//LocSpecialGeographicUnit_tab | //LocNearestNamedPlace_tab |
			//LocTownship_tab | //LocDistrictCountyShire_tab |
			//LocProvinceStateTerritory_tab | //LocCountry_tab |
			//LocContinent_tab | //LocOcean_tab |
			//LatCentroidLatitude0 | //LatCentroidLongitude0 | 
			//LatCentroidLatitudeDec_tab | //LatCentroidLongitudeDec_tab
		)) then 'place' else
		if (exists(//AcqNmaCollectionTitle)) then 'collection' else
		'unrecognised'
	"/>
	<xsl:param name="base-uri" select="'https://api.nma.gov.au/'" />
	<xsl:param name="ce-uri-base" select="'http://collectionsearch.nma.gov.au/'" />
	<xsl:param name="media-uri-base" select="'http://collectionsearch.nma.gov.au/nmacs-image-download/emu/'" />

	<xsl:variable name="nma-term-ns" select="concat($base-uri, 'term/')" />
	<xsl:variable name="crm-ns" select="'http://www.cidoc-crm.org/cidoc-crm/'" />
	<xsl:variable name="aat-ns" select="'http://vocab.getty.edu/aat/'" />
	<xsl:variable name="ore-ns" select="'http://www.openarchives.org/ore/terms/'" />
	
	<xsl:function name="uri:uri-from-filename">
		<!-- convert a filename to a URI, with a base URI -->
		<xsl:param name="base-uri"/>
		<xsl:param name="filename"/>
		<xsl:value-of select="concat($base-uri, uri:uri-from-filename($filename))"/>
	</xsl:function>
	<xsl:function name="uri:uri-from-filename">
		<!-- convert a filename to a relative URI -->
		<xsl:param name="filename"/>
		<xsl:value-of select="
			string-join(
				for $component in tokenize(
					$filename,
					'/'
				) return encode-for-uri($component),
				'/'
			)
		"/>
	</xsl:function>
	
	<!-- TODO add metadata for the RDF graph using PROV-O ontology -->
	<!-- the graph http://www.w3.org/ns/prov#wasGeneratedBy a http://www.w3.org/ns/prov#Generation
	which http://www.w3.org/ns/prov#atTime the value of <AdmDateModified> -->

	<xsl:template match="/">
		<rdf:RDF>
			<xsl:attribute name="xml:base" select="$base-uri" />
			<xsl:apply-templates select="record" />
			<!-- for debugging on full XML input file -->
			<xsl:apply-templates select="response/record" />
		</rdf:RDF>
	</xsl:template>

	<xsl:template match="record">
		<xsl:variable name="entity-iri" select="concat(lower-case($record-type), '/', irn)" />
		
		<!-- 
			Image re-use rights 
			(NB unlike most of the data modelled here, these rights are not a property of the PhysicalObject; 
			rather they are a property of the aggregation of the images which depict this PhysicalObject.
		-->
		<xsl:apply-templates select="AcsCCStatus">
			<xsl:with-param name="entity-iri" select="$entity-iri" />
			<xsl:with-param name="reason" select="AcsCCRestrictionReason" />
		</xsl:apply-templates>

		<rdf:Description rdf:about="{$entity-iri}#">

			<!-- COMMON FIELDS -->

			<xsl:call-template name="entity-type">
				<xsl:with-param name="record-type" select="$record-type" />
			</xsl:call-template>
			
			<!-- date modified -->
			<xsl:call-template name="record-metadata">
				<xsl:with-param name="entity-iri" select="$entity-iri" />
			</xsl:call-template>

			<!-- irn -->
			<xsl:apply-templates select="irn">
				<xsl:with-param name="entity-iri" select="$entity-iri" />
			</xsl:apply-templates>

			<!-- Collection Explorer link -->			
			<xsl:call-template name="web-link">
				<xsl:with-param name="record-type" select="$record-type" />
				<xsl:with-param name="entity-iri" select="$entity-iri" />
			</xsl:call-template>
			
			<!-- OBJECT FIELDS -->

			<!-- accession number -->
			<xsl:apply-templates select="TitObjectNumber">
				<xsl:with-param name="entity-iri" select="$entity-iri" />
			</xsl:apply-templates>

			<!-- title -->
			<xsl:apply-templates select="TitObjectTitle" />

			<!-- collection -->
			<xsl:apply-templates select="AccAccessionLotRef" />

			<!-- object type -->
			<xsl:apply-templates select="TitObjectName" />
			
			<!-- secondary object type -->
			<xsl:apply-templates select="TitSecondaryObjectType" />
			
			<!-- descriptions -->
			<xsl:apply-templates select="PhyDescription | PhyContentDescription | StaNmaSOSPublic | CreProvenance">
				<xsl:with-param name="entity-iri" select="$entity-iri" />
			</xsl:apply-templates>

			<!-- production -->
			<xsl:call-template name="production">
				<xsl:with-param name="entity-iri" select="$entity-iri" />
			</xsl:call-template>

			<!-- materials -->
			<xsl:apply-templates select="PhyMaterials_tab" />

			<!-- dimensions: linear -->
			<xsl:apply-templates select="PhyRegistrationLength | PhyRegistrationHeight | PhyRegistrationWidth | PhyRegistrationDepth | PhyRegistrationDiameter">
				<xsl:with-param name="entity-iri" select="$entity-iri" />
				<xsl:with-param name="unit" select="PhyRegistrationUnitLength" />
			</xsl:apply-templates>

			<!-- dimensions: weight -->
			<xsl:apply-templates select="PhyRegistrationWeight">
				<xsl:with-param name="entity-iri" select="$entity-iri" />
				<xsl:with-param name="unit" select="PhyRegistrationUnitWeight" />
			</xsl:apply-templates>

			<!-- associations -->
			<xsl:apply-templates select="AssociatedParties | AssociatedPlaces | AssociatedDates" />

			<!-- related objects -->
			<xsl:apply-templates select="RelRelatedObjects_tab/RelatedObject" />

			<!-- acknowledgement -->
			<xsl:apply-templates select="RigCreditLine2">
				<xsl:with-param name="entity-iri" select="$entity-iri" />
				<xsl:with-param name="acknowledgement-flag" select="RigAcknowledgement" />
			</xsl:apply-templates>

			<!-- exhibition location -->
			<xsl:apply-templates select="LocCurrentLocationRef">
				<xsl:with-param name="entity-iri" select="$entity-iri" />
			</xsl:apply-templates>

			<!-- inward loan -->
			<xsl:apply-templates select="InwardLoan" />

			<!-- object parent -->
			<!-- NB: we don't use TitObjectType as AssParentObjectRef adds parent AND child links -->
			<xsl:apply-templates select="AssParentObjectRef">
				<xsl:with-param name="entity-iri" select="$entity-iri" />
			</xsl:apply-templates>
			
			<!-- notes -->
			<xsl:apply-templates select="NotText0">
				<xsl:with-param name="entity-iri" select="$entity-iri" />
			</xsl:apply-templates>
			
			<!-- media -->
			<xsl:apply-templates select="WebMultiMediaRef_tab/image">
				<xsl:with-param name="record-type" select="$record-type" />
				<xsl:with-param name="entity-iri" select="$entity-iri" />
			</xsl:apply-templates>

			<!-- NARRATIVE FIELDS -->

			<!-- DesVersionDate (optional) TODO ??? barely used -->
			<!-- AdmDateModified TODO use prov:atTime -->
			<!-- AssMasterNarrativeRef (optional) = IGNORE as inverse of SubNarrative.irn -->
			<!-- TODO: add blanket rights statement for all narrative images? -->

			<!-- Narrative title -->
			<xsl:apply-templates select="NarTitle" />

			<!-- Narrative type -->
			<xsl:apply-templates select="DesType_tab/DesType" />

			<!-- Narrative audience -->
			<xsl:apply-templates select="DesIntendedAudience_tab/DesIntendedAudience" />

			<!-- Narrative text -->
			<xsl:apply-templates select="NarNarrative">
				<xsl:with-param name="entity-iri" select="$entity-iri" />
			</xsl:apply-templates>

			<!-- Narrative image -->
			<xsl:apply-templates select="MulMultiMediaRef_tab/image" />

			<!-- Narrative related objects -->
			<xsl:apply-templates select="ObjObjectsRef_tab/ObjObjectsRef">
				<xsl:with-param name="entity-iri" select="$entity-iri" />
			</xsl:apply-templates>

			<!-- Sub-narrative -->
			<!-- NB: this adds parent AND child links -->
			<xsl:apply-templates select="SubNarratives/SubNarrative">
				<xsl:with-param name="entity-iri" select="$entity-iri" />
			</xsl:apply-templates>

			<!-- PARTY FIELDS -->

			<!-- organisation name -->
			<xsl:apply-templates select="NamOrganisation" />

			<!-- person names -->
			<xsl:call-template name="person-names" />

			<!-- gender -->
			<xsl:apply-templates select="NamSex" />

			<!-- PLACE FIELDS -->

			<!-- formatted label -->
			<xsl:call-template name="place-label">
				<xsl:with-param name="record-type" select="$record-type" />
			</xsl:call-template>

			<!-- geo coordinates -->
			<xsl:call-template name="geo-coordinates">
				<xsl:with-param name="entity-iri" select="$entity-iri" />
			</xsl:call-template>

			<!-- COLLECTION FIELDS -->

			<!-- collection name -->
			<xsl:apply-templates select="AcqNmaCollectionTitle">
				<xsl:with-param name="entity-iri" select="$entity-iri" />
			</xsl:apply-templates>
			
		</rdf:Description>
	</xsl:template>

	<!-- sink to ignore stray partial update records -->
	<xsl:template match="record[./partial_update]">
	</xsl:template>

	<!-- ############### FIELD PROCESSING TEMPLATES ############ -->

	<!-- COMMON FIELDS -->

	<!-- irn -->
	<!-- http://linked.art/model/object/identity/#identifier -->
	<xsl:template match="irn">
		<xsl:param name="entity-iri" />
		<crm:P1_is_identified_by>
			<crm:E42_Identifier rdf:about="{$entity-iri}#repositorynumber">
				<rdf:value><xsl:value-of select="." /></rdf:value>
				<!-- AAT 300404621: repository numbers -->
				<crm:P2_has_type rdf:resource="{$aat-ns}300404621" />
			</crm:E42_Identifier>
		</crm:P1_is_identified_by>
	</xsl:template>

	<!-- OBJECT FIELDS -->

	<!-- accession number -->
	<!-- http://linked.art/model/object/identity/#identifier -->
	<xsl:template match="TitObjectNumber">
		<xsl:param name="entity-iri" />
		<crm:P1_is_identified_by>
			<crm:E42_Identifier rdf:about="{$entity-iri}#referencenumber">
				<rdf:value><xsl:value-of select="." /></rdf:value>
				<!-- AAT 300312355: accession numbers -->
				<crm:P2_has_type rdf:resource="{$aat-ns}300312355" />
			</crm:E42_Identifier>
		</crm:P1_is_identified_by>
	</xsl:template>

	<!-- title -->
	<!-- http://linked.art/model/object/identity/#titles -->
	<xsl:template match="TitObjectTitle">
		<rdfs:label><xsl:value-of select="." /></rdfs:label>
	</xsl:template>

	<!-- collection -->
	<!-- https://linked.art/cookbook/getty/photoarchive/ -->
	<xsl:template match="AccAccessionLotRef">
		<xsl:variable name="collection-iri" select="concat('collection/', ., '#')" />
		<crm:P106i_forms_part_of rdf:resource="{$collection-iri}" />
	</xsl:template>

	<!-- object type -->
	<!-- secondary object type -->
	<xsl:template match="TitObjectName | TitSecondaryObjectType">
		<crm:P2_has_type>
			<rdf:Description>
				<rdfs:label><xsl:value-of select="." /></rdfs:label>
			</rdf:Description>
		</crm:P2_has_type>
	</xsl:template>

	<!-- object parent -->
	<!-- NB: ignoring TitObjectType as this provides part/hasPart -->
	<xsl:template match="AssParentObjectRef">
		<xsl:param name="entity-iri" />
		<xsl:variable name="parent-iri" select="concat('object/', ., '#')" />
		<!-- this child object is contained by the specified parent object... 
		     which (in reverse) contains this child object -->
		<crm:P46i_forms_part_of>
			<rdf:Description rdf:about="{$parent-iri}">
				<crm:P46_is_composed_of rdf:resource="{$entity-iri}#" />
			</rdf:Description>
		</crm:P46i_forms_part_of>
	</xsl:template>

	<!-- physical description -->
	<!-- http://linked.art/model/object/aboutness/#description -->
	<xsl:template match="PhyDescription">
		<xsl:param name="entity-iri" />
		<crm:P129i_is_subject_of>
			<crm:E33_Linguistic_Object rdf:about="{$entity-iri}#physicalDescription">
				<rdf:value><xsl:value-of select="." /></rdf:value>
				<!-- AAT 300411780: descriptions (documents) -->
				<crm:P2_has_type rdf:resource="{$aat-ns}300411780" />
				<crm:P2_has_type rdf:resource="{$nma-term-ns}physicalDescription" />
			</crm:E33_Linguistic_Object>
		</crm:P129i_is_subject_of>
	</xsl:template>

	<!-- content description -->
	<!-- http://linked.art/model/object/aboutness/#description -->
	<xsl:template match="PhyContentDescription">
		<xsl:param name="entity-iri" />
		<crm:P129i_is_subject_of>
			<crm:E33_Linguistic_Object rdf:about="{$entity-iri}#contentDescription">
				<rdf:value><xsl:value-of select="." /></rdf:value>
				<!-- AAT 300411780: descriptions (documents) -->
				<crm:P2_has_type rdf:resource="{$aat-ns}300411780" />
				<crm:P2_has_type rdf:resource="{$nma-term-ns}contentDescription" />
			</crm:E33_Linguistic_Object>
		</crm:P129i_is_subject_of>
	</xsl:template>

	<!-- statement of significance (usually stated at collection level) -->
	<!-- http://linked.art/model/object/aboutness/#description -->
	<xsl:template match="StaNmaSOSPublic">
		<xsl:param name="entity-iri" />
		<crm:P129i_is_subject_of>
			<crm:E33_Linguistic_Object rdf:about="{$entity-iri}#significanceStatement">
				<rdf:value><xsl:value-of select="." /></rdf:value>
				<!-- AAT 300379612: significance assessments (surveys) -->
				<crm:P2_has_type rdf:resource="{$aat-ns}300379612" />
				<crm:P2_has_type rdf:resource="{$nma-term-ns}significanceStatement" />
			</crm:E33_Linguistic_Object>
		</crm:P129i_is_subject_of>
	</xsl:template>

	<!-- educational significance (usually stated at collection level) -->
	<!-- http://linked.art/model/object/aboutness/#description -->
	<xsl:template match="CreProvenance">
		<xsl:param name="entity-iri" />
		<crm:P129i_is_subject_of>
			<crm:E33_Linguistic_Object rdf:about="{$entity-iri}#educationalSignificance">
				<rdf:value><xsl:value-of select="." /></rdf:value>
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
		<xsl:param name="entity-iri" />
		<xsl:for-each select="ProductionParty">
			<xsl:variable name="party-iri" select="concat('party/', ProPersonRef_tab.irn, '#')" />
			<crm:P9_consists_of>
				<crm:E7_Activity>
					<rdfs:label>
						<xsl:value-of select="ProPersonType_tab" />
					</rdfs:label>
					<xsl:if test="ProPersonNotes_tab">
						<crm:P129i_is_subject_of>
							<crm:E33_Linguistic_Object>
								<rdf:value>
									<xsl:value-of select="ProPersonNotes_tab" />
								</rdf:value>
								<!-- AAT 300411780: descriptions (documents) -->
								<crm:P2_has_type rdf:resource="{$aat-ns}300411780" />
							</crm:E33_Linguistic_Object>
						</crm:P129i_is_subject_of>
					</xsl:if>
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
		<xsl:param name="entity-iri" />
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
		<xsl:param name="entity-iri" />
		<xsl:for-each select="ProductionPlace">
			<xsl:variable name="place-iri" select="concat('place/', ProPlaceRef_tab.irn, '#')" />
			<crm:P9_consists_of>
				<crm:E7_Activity>
					<rdfs:label>
						<xsl:value-of select="ProPlaceType_tab" />
					</rdfs:label>
					<xsl:if test="ProPlaceNotes_tab">
						<crm:P129i_is_subject_of>
							<crm:E33_Linguistic_Object>
								<rdf:value>
									<xsl:value-of select="ProPlaceNotes_tab" />
								</rdf:value>
								<!-- AAT 300411780: descriptions (documents) -->
								<crm:P2_has_type rdf:resource="{$aat-ns}300411780" />
							</crm:E33_Linguistic_Object>
						</crm:P129i_is_subject_of>
					</xsl:if>
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
		<xsl:param name="entity-iri" />
		<xsl:for-each select="ProductionDate">
			<crm:P9_consists_of>
				<crm:E7_Activity>
					<rdfs:label>
						<xsl:value-of select="ProDateType_tab" />
					</rdfs:label>
					<xsl:if test="ProDateNotes_tab">
						<crm:P129i_is_subject_of>
							<crm:E33_Linguistic_Object>
								<rdf:value>
									<xsl:value-of select="ProDateNotes_tab" />
								</rdf:value>
								<!-- AAT 300411780: descriptions (documents) -->
								<crm:P2_has_type rdf:resource="{$aat-ns}300411780" />
							</crm:E33_Linguistic_Object>
						</crm:P129i_is_subject_of>
					</xsl:if>
					<xsl:if test="ProDate0 or ProEarliestDate0 or ProLatestDate0">
						<crm:P4_has_time-span>
							<xsl:call-template name="time-span">
								<xsl:with-param name="defaultDate" select="ProDate0" />
								<xsl:with-param name="earliestDate" select="ProEarliestDate0" />
								<xsl:with-param name="latestDate" select="ProLatestDate0" />
							</xsl:call-template>
						</crm:P4_has_time-span>
					</xsl:if>
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
					<xsl:if test="AssDate0 or AssEarliestDate0 or AssLatestDate0">
						<crm:P4_has_time-span>
							<xsl:call-template name="time-span">
								<xsl:with-param name="defaultDate" select="AssDate0" />
								<xsl:with-param name="earliestDate" select="AssEarliestDate0" />
								<xsl:with-param name="latestDate" select="AssLatestDate0" />
							</xsl:call-template>
						</crm:P4_has_time-span>
					</xsl:if>
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
					<rdfs:label><xsl:value-of select="." /></rdfs:label>
					<rdfs:seeAlso rdf:resource="object?medium=%22{encode-for-uri(.)}%22"/>
				</crm:E57_Material>
			</crm:P45_consists_of>
		</xsl:for-each>
	</xsl:template>

	<!-- dimensions: length -->
	<!-- http://linked.art/model/object/physical/#dimensions -->
	<xsl:template match="PhyRegistrationLength">
		<xsl:param name="entity-iri" />
		<xsl:param name="unit" />
		<xsl:call-template name="output-dimension">
			<xsl:with-param name="dimension-iri" select="concat($entity-iri,'#length')" />
			<!-- AAT 300055645: length -->
			<xsl:with-param name="aat-type" select="'300055645'" />
			<xsl:with-param name="value" select="." />
			<xsl:with-param name="unit-value" select="$unit" />
		</xsl:call-template>
	</xsl:template>

	<!-- dimensions: height -->
	<!-- http://linked.art/model/object/physical/#dimensions -->
	<xsl:template match="PhyRegistrationHeight">
		<xsl:param name="entity-iri" />
		<xsl:param name="unit" />
		<xsl:call-template name="output-dimension">
			<xsl:with-param name="dimension-iri" select="concat($entity-iri,'#height')" />
			<!-- AAT 300055644: height -->
			<xsl:with-param name="aat-type" select="'300055644'" />
			<xsl:with-param name="value" select="." />
			<xsl:with-param name="unit-value" select="$unit" />
		</xsl:call-template>
	</xsl:template>

	<!-- dimensions: width -->
	<!-- http://linked.art/model/object/physical/#dimensions -->
	<xsl:template match="PhyRegistrationWidth">
		<xsl:param name="entity-iri" />
		<xsl:param name="unit" />
		<xsl:call-template name="output-dimension">
			<xsl:with-param name="dimension-iri" select="concat($entity-iri,'#width')" />
			<!-- AAT 300055647: width -->
			<xsl:with-param name="aat-type" select="'300055647'" />
			<xsl:with-param name="value" select="." />
			<xsl:with-param name="unit-value" select="$unit" />
		</xsl:call-template>
	</xsl:template>

	<!-- dimensions: depth -->
	<!-- http://linked.art/model/object/physical/#dimensions -->
	<xsl:template match="PhyRegistrationDepth">
		<xsl:param name="entity-iri" />
		<xsl:param name="unit" />
		<xsl:call-template name="output-dimension">
			<xsl:with-param name="dimension-iri" select="concat($entity-iri,'#depth')" />
			<!-- AAT 300072633: depth (size/dimension) -->
			<xsl:with-param name="aat-type" select="'300072633'" />
			<xsl:with-param name="value" select="." />
			<xsl:with-param name="unit-value" select="$unit" />
		</xsl:call-template>
	</xsl:template>

	<!-- dimensions: diameter -->
	<!-- http://linked.art/model/object/physical/#dimensions -->
	<xsl:template match="PhyRegistrationDiameter">
		<xsl:param name="entity-iri" />
		<xsl:param name="unit" />
		<xsl:call-template name="output-dimension">
			<xsl:with-param name="dimension-iri" select="concat($entity-iri,'#diameter')" />
			<!-- AAT 300055624: diameter -->
			<xsl:with-param name="aat-type" select="'300055624'" />
			<xsl:with-param name="value" select="." />
			<xsl:with-param name="unit-value" select="$unit" />
		</xsl:call-template>
	</xsl:template>

	<!-- dimensions: weight -->
	<!-- http://linked.art/model/object/physical/#dimensions -->
	<xsl:template match="PhyRegistrationWeight">
		<xsl:param name="entity-iri" />
		<xsl:param name="unit" />
		<xsl:call-template name="output-dimension">
			<xsl:with-param name="dimension-iri" select="concat($entity-iri,'#weight')" />
			<!-- AAT 300056240: weight (heaviness attribute) -->
			<xsl:with-param name="aat-type" select="'300056240'" />
			<xsl:with-param name="value" select="." />
			<xsl:with-param name="unit-value" select="$unit" />
		</xsl:call-template>
	</xsl:template>

	<!-- TODO: should related objects only be included if RelPublishedonCE=Yes? -->

	<!-- related objects -->
	<!-- https://linked.art/model/object/aboutness/index.html#related-objects -->
	<xsl:template match="RelatedObject">
		<xsl:variable name="related-entity-iri" select="concat('object/', ./relirn)" />
		<!-- NB: We don't put in the reverse relationship in case curators only intended one-way -->
		<dc:relation rdf:resource="{$related-entity-iri}#" />
	</xsl:template>

	<!-- TODO: RigAcknowledgement - appears to be empty, unsure if flag will be 'no' or something else -->

	<!-- acknowledgement -->
	<!-- https://linked.art/model/object/rights/#credit-attribution-statement -->
	<xsl:template match="RigCreditLine2">
		<xsl:param name="entity-iri" />
		<xsl:param name="acknowledgement-flag" />
		<!-- include by default, unless RigAcknowledgement = 'no' -->
		<xsl:if test="not($acknowledgement-flag = 'no')">
			<crm:P67i_is_referred_to_by>
				<crm:E33_Linguistic_Object rdf:about="{$entity-iri}#acknowledgement">
					<rdf:value><xsl:value-of select="." /></rdf:value>
					<!-- AAT 300026687: acknowledgements -->
					<crm:P2_has_type rdf:resource="{$aat-ns}300026687" />
					</crm:E33_Linguistic_Object>
			</crm:P67i_is_referred_to_by>
		</xsl:if>
	</xsl:template>

	<!-- rights -->
	<!-- restriction reason -->
	<!-- https://linked.art/model/object/rights/#rights-assertions -->
	<!-- NB: rights are NOT attached to the object IRI, but an images fragment: /object/nnn#media -->
	<!-- this fragment is later connected to each media in the object - as a parallel aggregation of the media -->
	<xsl:template match="AcsCCStatus">
		<xsl:param name="entity-iri" />
		<xsl:param name="reason" />
		<ore:Aggregation rdf:about="{$entity-iri}#media">
			<crm:P104_is_subject_to>
				<crm:E30_Right rdf:about="{$entity-iri}#rights">
					<!-- right/licence -->
					<crm:P148_has_component>
						<xsl:choose>
							<xsl:when test=". = 'Public Domain'">
								<crm:E30_Right rdf:about="https://creativecommons.org/publicdomain/mark/1.0/">
									<rdfs:label><xsl:text>Public Domain</xsl:text></rdfs:label>
								</crm:E30_Right>
							</xsl:when>
							<xsl:when test=". = 'Creative Commons Commercial Use'">
								<crm:E30_Right rdf:about="https://creativecommons.org/licenses/by-sa/4.0/">
									<rdfs:label><xsl:text>CC BY-SA 4.0</xsl:text></rdfs:label>
								</crm:E30_Right>
							</xsl:when>
							<xsl:when test=". = 'Creative Commons Non-Commercial Use'">
								<crm:E30_Right rdf:about="https://creativecommons.org/licenses/by-nc-sa/4.0/">
									<rdfs:label><xsl:text>CC BY-NC-SA 4.0</xsl:text></rdfs:label>
								</crm:E30_Right>
							</xsl:when>
							<!-- fall back to most conservative -->
							<xsl:otherwise>
								<crm:E30_Right rdf:about="http://rightsstatements.org/vocab/InC/1.0/">
									<rdfs:label><xsl:text>All Rights Reserved</xsl:text></rdfs:label>
								</crm:E30_Right>
							</xsl:otherwise>
						</xsl:choose>
					</crm:P148_has_component>
					<!-- restriction reason, if provided -->
					<xsl:if test="$reason">
						<crm:P129i_is_subject_of>
							<crm:E33_Linguistic_Object rdf:about="{$entity-iri}#restrictionReason">
								<rdf:value><xsl:value-of select="$reason" /></rdf:value>
								<!-- AAT 300404457: purpose (information indicator) -->
								<crm:P2_has_type rdf:resource="{$aat-ns}300404457" />
							</crm:E33_Linguistic_Object>
						</crm:P129i_is_subject_of>
					</xsl:if>
				</crm:E30_Right>
			</crm:P104_is_subject_to>
		</ore:Aggregation>
	</xsl:template>

	<!-- TODO: add detailed exhibition location ancestor structure -->

	<!-- exhibition location -->
	<!-- https://linked.art/model/exhibition/ -->
	<!-- NB: externally filtered, so levels 3+ won't make it here for public API -->
	<xsl:template match="LocCurrentLocationRef">
		<crm:P16i_was_used_for>
			<crm:E7_Activity>
				<rdfs:label>
					<!-- NB: filtering out empty locations using [. != ''] -->
					<xsl:value-of select="string-join( (LocLevel8, LocLevel7, LocLevel6, LocLevel5, LocLevel4, LocLevel3, LocLevel2, LocLevel1)[. != ''], ', ')" />
				</rdfs:label>
				<!-- AAT 300054766: exhibitions (events) -->
				<crm:P2_has_type rdf:resource="{$aat-ns}300054766" />
			</crm:E7_Activity>
		</crm:P16i_was_used_for>
	</xsl:template>

	<!-- inward loan -->
	<!-- https://linked.art/model/exhibition/#exhibition-provenance-transfer-of-custody -->
	<xsl:template match="InwardLoan">
		<xsl:if test=". = 'yes'">
			<crm:P30i_custody_transferred_through>
				<crm:E10_Transfer_of_Custody>
					<rdfs:label>Inward loan to NMA</rdfs:label>
					<crm:P29_custody_received_by
						rdf:resource="http://dbpedia.org/resource/National_Museum_of_Australia" />
				</crm:E10_Transfer_of_Custody>
			</crm:P30i_custody_transferred_through>
		</xsl:if>
	</xsl:template>

	<!-- web links -->
	<!-- https://linked.art/model/object/digital/#other-pages -->
	<xsl:template match="NotText0">
		<xsl:param name="entity-iri" />
		<!-- parse out URL and label (ignoring note_type) -->
		<!-- example: &lt;a href=&quot;http://...&quot;&gt;Label&lt;/a&gt; -->
		<!-- ie: <a href="http://...">Label</a> -->
		<xsl:variable name="label">
			<xsl:analyze-string select="normalize-space(note_text)"
				regex=".*href=&quot;(.*)&quot;&gt;(.*)&lt;/a&gt;.*">
				<xsl:matching-substring>
					<xsl:value-of select="regex-group(2)" />
				</xsl:matching-substring>
				<xsl:non-matching-substring>
					<xsl:value-of select="." />
				</xsl:non-matching-substring>
			</xsl:analyze-string>
		</xsl:variable>
		<xsl:variable name="href">
			<xsl:analyze-string select="normalize-space(note_text)"
				regex=".*href=&quot;(.*)&quot;&gt;(.*)&lt;/a&gt;.*">
				<xsl:matching-substring>
					<xsl:value-of select="regex-group(1)" />
				</xsl:matching-substring>
				<!-- NB: no xsl:non-matching-substring here - if href not found, 
					 return the whole string in label (ie. empty href variable) -->
			</xsl:analyze-string>
		</xsl:variable>
		<rdfs:seeAlso>
			<rdf:Description>
				<!-- NB: defensive, in case href didn't parse -->
				<xsl:if test="$href and not($href='')">
					<!-- mint RDF ID for link from *this* entity -->
					<xsl:attribute name="rdf:about"><xsl:value-of select="concat($entity-iri, '#link-', $href)" /></xsl:attribute>
					<!-- and here's the actual link -->
					<crm:P1_is_identified_by>
					    <crm:E42_Identifier rdf:resource="{$href}" />
					</crm:P1_is_identified_by>
				</xsl:if>
				<xsl:if test="$label">
					<rdfs:label><xsl:value-of select="$label" /></rdfs:label>
				</xsl:if>
				<!-- AAT 300264578: web pages (documents) -->
				<crm:P2_has_type rdf:resource="{$aat-ns}300264578" />
			</rdf:Description>
		</rdfs:seeAlso>
	</xsl:template>

	<!-- media -->
	<!-- https://linked.art/model/object/digital/ -->
	<xsl:template match="image">
		<xsl:param name="record-type" />
		<xsl:param name="entity-iri" />
		<xsl:variable name="media-iri" select="concat('media/', media_irn)" />
		<crm:P138i_has_representation>
			<crm:E36_Visual_Item rdf:about="{$media-iri}#">
				<!-- bundle this media up along with all the other media of this object, into a parallel aggregation which is subject to the re-use rights -->
				<!-- NB: see AcsCCStatus template -->
				<ore:isAggregatedBy rdf:resource="{$entity-iri}#media"/>
				<!-- flag first image as 'preferred' -->
				<xsl:if test="position()=1">
					<crm:P2_has_type rdf:resource="{$nma-term-ns}preferred" />
				</xsl:if>
				<crm:P2_has_type rdf:resource="{$nma-term-ns}emu-image" />
				<!-- add reverse link back to parent object entity -->
				<xsl:if test="$record-type = 'object' and not($entity-iri= '')">
					<crm:P138_represents rdf:resource="{$entity-iri}#" />
				</xsl:if>

				<!-- TODO: add identified_by for media IRN -->
				<!-- TODO: add mime type/format -->

				<!-- preview -->
				<xsl:for-each select="res640px">
					<crm:P138i_has_representation>		
						<crm:E36_Visual_Item rdf:about="{uri:uri-from-filename($media-uri-base, image_path)}">
							<crm:P2_has_type rdf:resource="{$nma-term-ns}preview" />
							<xsl:if test="image_width != ''">
								<xsl:call-template name="output-dimension">
									<xsl:with-param name="dimension-iri" select="concat($media-iri,'#previewWidth')" />
									<!-- AAT 300055647: width -->
									<xsl:with-param name="aat-type" select="'300055647'" />
									<xsl:with-param name="value" select="image_width" />
									<!-- TODO: add AAT 300379612: pixels -->
									<xsl:with-param name="unit-value" select="'pixels'" />
								</xsl:call-template>
							</xsl:if>
							<xsl:if test="image_height != ''">
								<xsl:call-template name="output-dimension">
									<xsl:with-param name="dimension-iri" select="concat($media-iri,'#previewHeight')" />
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
						<crm:E36_Visual_Item rdf:about="{uri:uri-from-filename($media-uri-base, image_path)}">
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

	<!-- NARRATIVE FIELDS -->

	<xsl:template match="NarTitle">
		<rdfs:label><xsl:value-of select="." /></rdfs:label>
	</xsl:template>

	<!-- TODO: DesType is barely used; get clarity on meaning -->

	<!-- DesType_tab (optional), containing sequence of DesType (string) -->
	<xsl:template match="DesType">
		<crm:P2_has_type>
			<crm:E55_Type>
				<rdfs:label><xsl:value-of select="." />	</rdfs:label>
			</crm:E55_Type>
		</crm:P2_has_type>
	</xsl:template>

	<!-- DesIntendedAudience_tab (optional) - sequence of DesIntendedAudience (string) -->
	<xsl:template match="DesIntendedAudience">
		<crm:P2_has_type>
			<crm:E55_Type>
				<rdfs:label><xsl:value-of select="." /></rdfs:label>
				<crm:P2_has_type rdf:resource="{$aat-ns}300192793" /><!-- audiences -->
			</crm:E55_Type>
		</crm:P2_has_type>
	</xsl:template>

	<!-- NarNarrative (optional) (string) -->
	<xsl:template match="NarNarrative">
		<xsl:param name="entity-iri" />
		<ore:aggregates>
			<crm:E33_Linguistic_Object rdf:about="{$entity-iri}#text">
				<crm:P2_has_type rdf:resource="{$aat-ns}300263751" /><!-- "texts (documents)" -->
				<rdf:value><xsl:value-of select="." /></rdf:value>
				<dc:format>text/html</dc:format>
			</crm:E33_Linguistic_Object>
		</ore:aggregates>
	</xsl:template>

	<!-- MulMultiMediaRef_tab (optional) - sequence of image banner_small banner_large -->
	<xsl:template match="MulMultiMediaRef_tab/image">
		<ore:aggregates>
			<crm:E36_Visual_Item>
				<crm:P2_has_type rdf:resource="{$nma-term-ns}emu-image" />
				<crm:P2_has_type rdf:resource="{$nma-term-ns}banner-image" />
				<crm:P138i_has_representation>
					<crm:E36_Visual_Item
						rdf:about="{uri:uri-from-filename($media-uri-base, banner_small)}">
						<crm:P2_has_type rdf:resource="{$nma-term-ns}small-banner-image" />
					</crm:E36_Visual_Item>
				</crm:P138i_has_representation>
				<crm:P138i_has_representation>
					<crm:E36_Visual_Item
						rdf:about="{uri:uri-from-filename($media-uri-base, banner_large)}">
						<crm:P2_has_type rdf:resource="{$nma-term-ns}large-banner-image" />
					</crm:E36_Visual_Item>
				</crm:P138i_has_representation>
			</crm:E36_Visual_Item>
		</ore:aggregates>
	</xsl:template>

	<!-- NMA narratives contain optionally, either of ObjObjectsRef_tab OR SubNarratives -->
	
	<!-- TODO: we don't include isAggregatedBy from objects to containing narratives, though this could be a seeAlso canned search -->

	<!-- ObjObjectsRef_tab (optional) - sequence of ObjObjectsRef, irn (string), AdmPublishWebNoPassword, 
		AcsAPI_tab sequence of AcsAPI (string) -->
	<xsl:template match="ObjObjectsRef">
		<xsl:param name="entity-iri" />
		<!-- this narrative contains the specified object... which (in reverse) is contained by this narrative -->
		<ore:aggregates>
			<rdf:Description rdf:about="{concat('object/', irn, '#')}">
				<ore:isAggregatedBy rdf:resource="{$entity-iri}#" />
			</rdf:Description>
		</ore:aggregates>
	</xsl:template>

	<!-- SubNarratives - sequence of SubNarrative SubNarrative.irn -->
	<xsl:template match="SubNarrative">
		<xsl:param name="entity-iri" />
		<!-- this narrative contains the specified sub-narrative... which (in reverse) is contained by this narrative -->
		<ore:aggregates>
			<rdf:Description rdf:about="{concat('narrative/', SubNarrative.irn, '#')}">
				<ore:isAggregatedBy rdf:resource="{$entity-iri}#" />
			</rdf:Description>
		</ore:aggregates>
	</xsl:template>

	<!-- PARTY FIELDS -->

	<!-- organisation name -->
	<!-- http://linked.art/model/actor/#names -->
	<xsl:template match="NamOrganisation">
		<rdfs:label><xsl:value-of select="." /></rdfs:label>
	</xsl:template>

	<!-- first names (component of full name) -->
	<!-- http://linked.art/model/actor/#names -->
	<xsl:template match="NamFirst">
		<crm:P106_is_composed_of>
			<la:Name>
				<rdf:value><xsl:value-of select="." /></rdf:value>
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
				<rdf:value><xsl:value-of select="." /></rdf:value>
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
				<rdf:value><xsl:value-of select="." /></rdf:value>
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
					<rdf:value><xsl:value-of select="." /></rdf:value>
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
						<rdfs:label><xsl:text>female</xsl:text></rdfs:label>
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
						<rdfs:label><xsl:text>male</xsl:text></rdfs:label>
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
						<rdfs:label><xsl:value-of select="." /></rdfs:label>
						<!-- AAT 300055147: sex role -->
						<crm:P2_has_type rdf:resource="{$aat-ns}300055147" />
					</crm:E74_Group>
				</crm:P107i_is_current_or_former_member_of>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- PLACE FIELDS -->

	<!-- TODO: add ancestor locations as separate fields -->

	<!-- place label (used as components in 'place-label' template) -->
	<!-- http://linked.art/model/base/#locations -->
	<xsl:template match="LocSpecialGeographicUnit_tab | LocNearestNamedPlace_tab | LocTownship_tab | LocDistrictCountyShire_tab | LocProvinceStateTerritory_tab | LocCountry_tab | LocContinent_tab | LocOcean_tab" mode="label">
		<xsl:value-of select="." />
		<xsl:text>, </xsl:text>
	</xsl:template>

	<!-- COLLECTION FIELDS -->

	<!-- collection name -->
	<!-- https://linked.art/cookbook/getty/photoarchive/ -->
	<xsl:template match="AcqNmaCollectionTitle">
		<xsl:param name="entity-iri" />
		<rdfs:label>
			<xsl:value-of select="." />
		</rdfs:label>
		<!-- see also the objects which make up this collection -->
		<!--
		need to search objects by collection's IRN
		-->
		<rdfs:seeAlso rdf:resource="object?collection=%22{encode-for-uri(.)}%22"/>
	</xsl:template>

	<!-- ############### NAMED TEMPLATES ############ -->

	<!-- TODO: could PhysicalObject be split into ManMadeObject and BiologicalObject -->

	<!-- entity type -->
	<!-- http://linked.art/model/object/identity/#types -->
	<!-- http://linked.art/model/actor/#types -->
	<!-- NMA decision: E78 Collection better for physical collections, ore:Aggregation for narratives/sets -->
	<xsl:template name="entity-type">
		<xsl:param name="record-type" />
			<xsl:choose>
				<xsl:when test="$record-type='object'">
					<rdf:type rdf:resource="{$crm-ns}E19_Physical_Object" />
				</xsl:when>
				<xsl:when test="$record-type='narrative'">
					<rdf:type rdf:resource="{$ore-ns}Aggregation" />
					<!-- AAT 300025976: collections (object groupings) -->
					<crm:P2_has_type rdf:resource="{$aat-ns}300025976" />
				</xsl:when>
				<xsl:when test="$record-type='collection'">
					<rdf:type rdf:resource="{$crm-ns}E78_Collection" />
				</xsl:when>
				<xsl:when test="$record-type='place'">
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
	</xsl:template>

	<xsl:template name="record-metadata">
		<xsl:param name="entity-iri" />
		<crm:P70i_is_documented_in>
			<crm:E31_Document rdf:about="{$entity-iri}"><!-- identifies the RDF graph itself -->
				<xsl:if test="AdmDateModified">
					<dc:modified>
						<xsl:attribute name="rdf:datatype"><xsl:value-of select="dateutil:to-xml-schema-type(AdmDateModified)" /></xsl:attribute>
						<xsl:value-of select="dateutil:to-iso-date(AdmDateModified)" />
					</dc:modified>
				</xsl:if>
				<xsl:if test="WebReleaseDate">
					<!-- dc:issued is more precise than dc:available - http://dublincore.org/documents/date-element/ -->
					<dc:issued>
						<xsl:attribute name="rdf:datatype"><xsl:value-of select="dateutil:to-xml-schema-type(WebReleaseDate)" /></xsl:attribute>
						<xsl:value-of select="dateutil:to-iso-date(WebReleaseDate)" />
					</dc:issued>
				</xsl:if>
			</crm:E31_Document>
		</crm:P70i_is_documented_in>
	</xsl:template>

	<!-- Collection Explorer web link -->
	<!-- https://linked.art/model/object/digital/#other-pages -->
	<xsl:template name="web-link">
		<xsl:param name="record-type" />
		<xsl:param name="entity-iri" />
		<xsl:variable name="id" select="replace($entity-iri, '(.*/)([^/]*)$', '$2')" />
		<xsl:variable name="href" select="concat($ce-uri-base, $record-type, '/', $id)" />
		<xsl:if test="$record-type='object' or $record-type='narrative'">
			<crm:P129i_is_subject_of>
				<crm:E33_Linguistic_Object rdf:about="{$href}">
					<rdfs:label><xsl:text>View on Collection Explorer</xsl:text></rdfs:label>
					<!-- AAT 300264578: web pages (documents) -->
					<crm:P2_has_type rdf:resource="{$aat-ns}300264578" />
				</crm:E33_Linguistic_Object>
			</crm:P129i_is_subject_of>
		</xsl:if>
	</xsl:template>

	<!-- production -->
	<!-- http://linked.art/model/provenance/production.html -->
	<!-- NB: modeled as a single production event consisting of multiple activities -->
	<xsl:template name="production">
		<xsl:param name="entity-iri" />
		<xsl:if test="ProductionParties | ProductionPlaces | ProductionDates">
			<crm:P108i_was_produced_by>
				<crm:E12_Production>
					<xsl:apply-templates select="ProductionParties | ProductionPlaces | ProductionDates">
						<xsl:with-param name="entity-iri" select="$entity-iri" />
					</xsl:apply-templates>
				</crm:E12_Production>
			</crm:P108i_was_produced_by>
		</xsl:if>
	</xsl:template>

	<!-- display time span -->
	<!-- assumes AT LEAST ONE date will be supplied -->
	<xsl:template name="time-span">
		<xsl:param name="defaultDate" />
		<xsl:param name="earliestDate" />
		<xsl:param name="latestDate" />
		
		<!-- if only have default date, copy into earliest and latest -->
		<xsl:variable name="earliestDatePopulated">
			<xsl:choose>
				<xsl:when test="not($earliestDate) and not($latestDate)">
					<xsl:value-of select="$defaultDate" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$earliestDate" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="latestDatePopulated">
			<xsl:choose>
				<xsl:when test="not($earliestDate) and not($latestDate)">
					<xsl:value-of select="$defaultDate" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$latestDate" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:variable name="earliestDisplayDate" select="dateutil:to-display-date($earliestDatePopulated)" />
		<xsl:variable name="latestDisplayDate" select="dateutil:to-display-date($latestDatePopulated)" />

		<crm:E52_Time-Span>
			<rdfs:label>
				<xsl:choose>
					<!-- 1) "earliest - latest" -->
					<xsl:when test="$earliestDisplayDate != $latestDisplayDate">
						<xsl:value-of select="$earliestDisplayDate" />
						<xsl:text> - </xsl:text>
						<xsl:value-of select="$latestDisplayDate" />
					</xsl:when>
					<!-- 2) "earliest" (as earliest is same as latest) -->
					<xsl:when test="$earliestDisplayDate = $latestDisplayDate">
						<xsl:value-of select="$earliestDisplayDate" />
					</xsl:when>
					<!-- 3) "earliest -" -->
					<xsl:when test="$earliestDisplayDate">
						<xsl:value-of select="$earliestDisplayDate" />
						<xsl:text> -</xsl:text>
					</xsl:when>
					<!-- 4) "- latest" -->
					<xsl:when test="$latestDisplayDate">
						<xsl:text>- </xsl:text>
						<xsl:value-of select="$latestDisplayDate" />
					</xsl:when>
				</xsl:choose>
			</rdfs:label>
			<xsl:if test="$earliestDisplayDate">
				<crm:P82a_begin_of_the_begin>
					<xsl:attribute name="rdf:datatype">
						<xsl:value-of select="dateutil:to-xml-schema-type($earliestDatePopulated)" />
					</xsl:attribute>
					<xsl:value-of select="dateutil:to-iso-date($earliestDatePopulated)" />
				</crm:P82a_begin_of_the_begin>
			</xsl:if>
			<xsl:if test="$latestDisplayDate">
				<crm:P82b_end_of_the_end>
					<xsl:attribute name="rdf:datatype">
						<xsl:value-of select="dateutil:to-xml-schema-type($latestDatePopulated)" />
					</xsl:attribute>
					<xsl:value-of select="dateutil:to-iso-date($latestDatePopulated)" />
				</crm:P82b_end_of_the_end>
			</xsl:if>
		</crm:E52_Time-Span>
	</xsl:template>

	<!-- person names -->
	<!-- http://linked.art/model/actor/#names -->
	<!-- NB: modeled as full name composed of multiple parts -->
	<xsl:template name="person-names">
		<xsl:if test="NamFullName">
			<xsl:variable name="party-iri" select="concat('party/', irn)" />
			<crm:P1_is_identified_by>
				<la:Name rdf:about="{$party-iri}#name">
					<rdf:value><xsl:value-of select="NamFullName" /></rdf:value>
					<!-- AAT 300404670: preferred terms -->
					<crm:P2_has_type rdf:resource="{$aat-ns}300404670" />
					<!-- AAT 300404688: full names (personal names) -->
					<crm:P2_has_type rdf:resource="{$aat-ns}300404688" />
					<!-- add in name components -->
					<xsl:apply-templates select="NamFirst | NamMiddle | NamLast | NamOtherNames_tab" />
				</la:Name>
			</crm:P1_is_identified_by>
		</xsl:if>
	</xsl:template>
	
	<!-- concat place hierarchy labels into single comma-delimited label -->
	<xsl:template name="place-label">
		<xsl:param name="record-type" />
		<xsl:if test="$record-type='place'">
			<xsl:variable name="concatenatedLabel">
				<xsl:apply-templates select="LocSpecialGeographicUnit_tab" mode="label" />
				<xsl:apply-templates select="LocNearestNamedPlace_tab" mode="label" />
				<xsl:apply-templates select="LocTownship_tab" mode="label" />
				<xsl:apply-templates select="LocDistrictCountyShire_tab" mode="label" />
				<xsl:apply-templates select="LocProvinceStateTerritory_tab" mode="label" />
				<xsl:apply-templates select="LocCountry_tab" mode="label" />
				<xsl:apply-templates select="LocContinent_tab" mode="label" />
				<xsl:apply-templates select="LocOcean_tab" mode="label" />
			</xsl:variable>
			<rdfs:label>
				<!-- remove trailing ', ' -->
				<xsl:value-of select="substring($concatenatedLabel, 1, string-length($concatenatedLabel)-2)" />
			</rdfs:label>
		</xsl:if>
	</xsl:template>

	<!-- TODO: change to an RDF geo namespace? -->

	<!-- geo location -->
	<xsl:template name="geo-coordinates">
		<xsl:param name="entity-iri" />
		<xsl:if test="LatCentroidLatitudeDec_tab | LatCentroidLongitudeDec_tab">
			<crm:P168_place_is_defined_by>
				<crm:E94_Space_Primitive rdf:about="{$entity-iri}#location">
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
	</xsl:template>
		
	<!-- output a dimension -->
	<xsl:template name="output-dimension">
		<xsl:param name="dimension-iri" />
		<xsl:param name="aat-type" />
		<xsl:param name="value" />
		<xsl:param name="unit-value" />
		<crm:P43_has_dimension>
			<crm:E54_Dimension rdf:about="{$dimension-iri}">
				<rdf:value><xsl:value-of select="$value" /></rdf:value>
				<crm:P2_has_type rdf:resource="{$aat-ns}{$aat-type}" />
				<!-- TODO: add AAT for relevant unit type -->
				<xsl:if test="$unit-value != ''">
					<crm:P91_has_unit>
						<crm:E58_Measurement_Unit>
							<rdfs:label><xsl:value-of select="$unit-value" /></rdfs:label>
						</crm:E58_Measurement_Unit>
					</crm:P91_has_unit>
				</xsl:if>
			</crm:E54_Dimension>
		</crm:P43_has_dimension>
	</xsl:template>

</xsl:stylesheet>
