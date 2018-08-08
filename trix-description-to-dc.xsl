<!-- 
Converts trix RDF into simple DC ready for conversion to JSON.
Spec: https://www.w3.org/TR/xpath-functions-31/#json-to-xml-mapping
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	version="3.0" xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:path="tag:conaltuohy.com,2018:nma/trix-path-traversal"
	xmlns:xmljson="tag:conaltuohy.com,2018:nma/xml-to-json"
	xmlns:f="http://www.w3.org/2005/xpath-functions" 
	xmlns:map="http://www.w3.org/2005/xpath-functions/map"
	xmlns:trix="http://www.w3.org/2004/03/trix/trix-1/"
	xmlns="http://www.w3.org/2005/xpath-functions">

	<xsl:import href="util/trix-traversal-functions.xsl" />
	<xsl:import href="util/xmljson-functions.xsl" />
	<xsl:import href="util/date-util-functions.xsl" />

	<xsl:param name="root-resource" /><!-- e.g. "http://nma-dev.conaltuohy.com/xproc-z/narrative/1758#" -->
	<xsl:variable name="api-base-uri" select="replace($root-resource, '(.*)/.*/[^#]*#.*', '$1')"/>
	<xsl:variable name="collection-explorer-uri" select=" 'http://collectionsearch.nma.gov.au/' "/>

	<!-- type = the second-to-last component of the URI's path, e.g. "object" or "party" -->
	<xsl:variable name="type" select="replace($root-resource, '(.*/)([^/]*)(/.*)$', '$2')"/>

	<xsl:template match="/">
		<xsl:variable name="dc-json-in-xml">
			<xsl:call-template name="dc-xml">
				<xsl:with-param name="resource" select="$root-resource" />
			</xsl:call-template>
		</xsl:variable>
		<xsl:copy-of select="$dc-json-in-xml" />
	</xsl:template>

	<xsl:template name="dc-xml">
		<xsl:param name="resource" required="true" />
		<map>

			<!-- COMMON FIELDS -->

			<xsl:call-template name="id-dc" />
			<xsl:call-template name="type-dc" />
			<xsl:call-template name="additional-type-dc" />
			<xsl:call-template name="title-dc" />

			<!-- OBJECT FIELDS -->

			<xsl:call-template name="collection-dc" />
			<xsl:call-template name="accession-number-dc" />
			<xsl:call-template name="materials-dc" />
			<xsl:call-template name="dimensions-dc" />
			<xsl:call-template name="content-description-dc" />
			<xsl:call-template name="physical-description-dc" />
			<xsl:call-template name="significance-statement-dc" />
			<xsl:call-template name="educational-significance-dc" />
			<xsl:call-template name="creator-dc" />
			<xsl:call-template name="contributor-dc" />
			<xsl:call-template name="spatial-dc" />
			<xsl:call-template name="temporal-dc" />
			<!-- TODO: all assoc are 'in presence of' so dates and places are coming thru, need to add AAT or something into CRM -->
			<xsl:call-template name="acknowledgement-dc" />
			<xsl:call-template name="inwardloan-dc" />
			<xsl:call-template name="exhibition-location-dc" />
			<xsl:call-template name="object-parent-dc" />
			<xsl:call-template name="object-children-dc" />
			<xsl:call-template name="related-dc" />
			<xsl:call-template name="media-parent-dc" />
			<xsl:call-template name="web-links-dc" />
			<!-- TODO: add representation mimetype format, once added to CRM -->
			<!-- NB: rights are placed inside each media rather than at the object record level -->
			<xsl:call-template name="representations-dc" />
			
			<!-- PARTY FIELDS -->
			<xsl:call-template name="full-name-dc" />
			<xsl:call-template name="first-name-dc" />
			<xsl:call-template name="middle-name-dc" />
			<xsl:call-template name="last-name-dc" />
			<xsl:call-template name="other-name-dc" />
			<xsl:call-template name="gender-dc" />

			<!-- PLACE FIELDS -->
			<xsl:call-template name="location-dc" />

			<!-- NARRATIVE FIELDS -->
			<!-- TODO: narrative author, audience, media, des-type -->
			<xsl:call-template name="narrative-text-dc" />
			<xsl:call-template name="narrative-image-dc" />
			<xsl:call-template name="narrative-parent-dc" />
			<xsl:call-template name="narrative-children-dc" />
			<xsl:call-template name="narrative-objects-dc" />

			<!-- COMMON FIELDS (footer) -->

			<xsl:call-template name="record-metadata-dc" />

		</map>
	</xsl:template>
	
	<!-- ############### FIELD PROCESSING TEMPLATES ############ -->

	<!-- COMMON FIELDS -->

	<!-- id -->
	<xsl:template name="id-dc">
		<xsl:copy-of select="xmljson:render-as-string('id', replace($root-resource, '(.*/)([^/]*)(#)$', '$2'))" />
	</xsl:template>

	<!-- type -->
	<xsl:template name="type-dc">
		<xsl:copy-of select="xmljson:render-as-string('type', $type)" />
	</xsl:template>

	<!-- additional type -->
	<xsl:template name="additional-type-dc">
		<xsl:variable name="value" select="path:forward( ('crm:P2_has_type','rdfs:label') )" />
		<xsl:if test="$value">
			<array key="additionalType">
				<xsl:for-each select="$value">
					<!-- NB: no JSON string labels -->
					<xsl:copy-of select="xmljson:render-as-string('', .)" />
				</xsl:for-each>
			</array>
		</xsl:if>
	</xsl:template>

	<!-- title -->
	<xsl:template name="title-dc">
		<xsl:copy-of select="xmljson:render-as-string('title', path:forward('rdfs:label'))" />
		<!-- duplicate organisation title into name field -->
		<xsl:if test="$type='party'">
			<xsl:copy-of select="xmljson:render-as-string('name', path:forward('rdfs:label'))" />
		</xsl:if>
	</xsl:template>

	<!-- record metadata: modified, issued, collection explorer link -->
	<xsl:template name="record-metadata-dc">
		<xsl:if test="$type='object' or $type='narrative'">
			<map key="_meta">
				<xsl:variable name="primary-source-graph" select="path:forward('crm:P70i_is_documented_in')[1]"/>
				<xsl:for-each select="path:forward($primary-source-graph, 'dc:modified')[1]">
					<string key='modified'><xsl:value-of select="." /></string>
				</xsl:for-each>
				<!-- web release -->
				<xsl:for-each select="path:forward($primary-source-graph, 'dc:issued'[1] )">
					<string key='issued'><xsl:value-of select="." /></string>
				</xsl:for-each>
				<!-- collection explorer link -->
				<xsl:variable name="ceLink">
					<xsl:value-of select="$collection-explorer-uri" />
					<xsl:choose>
						<xsl:when test="$type='object'"><xsl:text>object/</xsl:text></xsl:when>
						<xsl:when test="$type='narrative'"><xsl:text>set/</xsl:text></xsl:when>
					</xsl:choose>
					<xsl:value-of select="replace($root-resource, '(.*/)([^/]*)(#)$', '$2')" />
				</xsl:variable>
				<string key='hasFormat'><xsl:value-of select="$ceLink" /></string>
			</map>
		</xsl:if>
	</xsl:template>
	
	<!-- OBJECT FIELDS -->

	<!-- collection -->
	<xsl:template name="collection-dc">
		<xsl:variable name="value" select="path:forward('crm:P106i_forms_part_of')" />
		<xsl:if test="$value">
			<map key="collection">
				<string key='id'><xsl:value-of select="replace($value, '(.*/)([^/]*)(#)$', '$2')" /></string>
				<string key='type'><xsl:text>Collection</xsl:text></string>
				<xsl:copy-of select="xmljson:render-as-string('title', path:forward($value, 'rdfs:label'))" />
			</map>
		</xsl:if>
	</xsl:template>
	
	<!-- accession number -->
	<xsl:template name="accession-number-dc">
		<!-- accession number -->
		<xsl:copy-of select="xmljson:render-as-string('identifier', 
			path:forward('crm:P1_is_identified_by')[
				path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300312355'
			]
			/path:forward(., 'rdf:value'))" />
	</xsl:template>	

	<!-- materials (array of strings) -->
	<xsl:template name="materials-dc">
		<xsl:variable name="value" select="path:forward( ('crm:P45_consists_of','rdfs:label') )" />
		<xsl:if test="$value">
			<array key="medium">
				<xsl:for-each select="$value">
					<map>
						<string key='type'><xsl:text>Material</xsl:text></string>
						<xsl:copy-of select="xmljson:render-as-string('title', .)" />
					</map>
				</xsl:for-each>
			</array>
		</xsl:if>
	</xsl:template>

	<!-- dimensions -->
	<xsl:template name="dimensions-dc">
		<xsl:if test="path:forward('crm:P43_has_dimension')">
			<map key="extent">
					<string key='type'><xsl:text>Measurement</xsl:text></string>
			
					<!-- length -->
					<xsl:copy-of select="xmljson:render-as-number('length', 
						path:forward('crm:P43_has_dimension')[
							path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300055645'
						]
						/path:forward(., 'rdf:value')
					)" />

					<!-- height -->
					<xsl:copy-of select="xmljson:render-as-number('height', 
						path:forward('crm:P43_has_dimension')[
							path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300055644'
						]
						/path:forward(., 'rdf:value')
					)" />

					<!-- width -->
					<xsl:copy-of select="xmljson:render-as-number('width', 
						path:forward('crm:P43_has_dimension')[
							path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300055647'
						]
						/path:forward(., 'rdf:value')
					)" />

					<!-- depth -->
					<xsl:copy-of select="xmljson:render-as-number('depth', 
						path:forward('crm:P43_has_dimension')[
							path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300072633'
						]
						/path:forward(., 'rdf:value')
					)" />

					<!-- diameter -->
					<xsl:copy-of select="xmljson:render-as-number('diameter', 
						path:forward('crm:P43_has_dimension')[
							path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300055624'
						]
						/path:forward(., 'rdf:value')
					)" />

					<!-- weight -->
					<xsl:copy-of select="xmljson:render-as-number('weight', 
						path:forward('crm:P43_has_dimension')[
							path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300056240'
						]
						/path:forward(., 'rdf:value')
					)" />

					<!-- linear units (taken from first non-weight dimension) -->
					<xsl:variable name="linearDimensions" select="
						path:forward('crm:P43_has_dimension')[
							path:forward(., 'crm:P2_has_type') != 'http://vocab.getty.edu/aat/300056240'
						]
					" />
					<xsl:copy-of select="xmljson:render-as-string('unitText',path:forward($linearDimensions[1], ('crm:P91_has_unit', 'rdfs:label')))" />

					<!-- weight units (taken from first weight dimension) -->
					<xsl:variable name="weightDimensions" select="
						path:forward('crm:P43_has_dimension')[
							path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300056240'
						]
					" />
					<xsl:copy-of select="xmljson:render-as-string('unitTextWeight',path:forward($weightDimensions[1], ('crm:P91_has_unit', 'rdfs:label')))" />
				</map>
		</xsl:if>
	</xsl:template>
	
	<!-- descriptions -->
	<!-- NB: term namespace varies depending on the server -->
	
	<!-- content description -->
	<xsl:template name="content-description-dc">
		<xsl:copy-of select="xmljson:render-as-string('description', 
			path:forward('crm:P129i_is_subject_of')[
				path:forward(., 'crm:P2_has_type') = concat($api-base-uri, '/term/contentDescription')
			]
			/path:forward(., 'rdf:value')
		)" />
	</xsl:template>

	<!-- physical description -->
	<xsl:template name="physical-description-dc">
		<xsl:copy-of select="xmljson:render-as-string('physicalDescription', 
			path:forward('crm:P129i_is_subject_of')[
				path:forward(., 'crm:P2_has_type') = concat($api-base-uri, '/term/physicalDescription')
			]
			/path:forward(., 'rdf:value')
		)" />
	</xsl:template>

	<!-- significance statement -->
	<xsl:template name="significance-statement-dc">
		<xsl:copy-of select="xmljson:render-as-string('significanceStatement', 
			path:forward('crm:P129i_is_subject_of')[
				path:forward(., 'crm:P2_has_type') = concat($api-base-uri, '/term/significanceStatement')
			]
			/path:forward(., 'rdf:value')
		)" />
	</xsl:template>

	<!-- educational significance -->
	<xsl:template name="educational-significance-dc">
		<xsl:copy-of select="xmljson:render-as-string('educationalSignificance', 
			path:forward('crm:P129i_is_subject_of')[
				path:forward(., 'crm:P2_has_type') = concat($api-base-uri, '/term/educationalSignificance')
			]
			/path:forward(., 'rdf:value')
		)" />
	</xsl:template>

	<!-- production parties -->
	<xsl:template name="creator-dc">
		<xsl:variable name="value" select="
			path:forward( ('crm:P108i_was_produced_by', 'crm:P9_consists_of') )[
				path:forward(., 'crm:P14_carried_out_by')
			]
		" />
		<xsl:if test="$value">
			<array key="creator">
				<xsl:for-each select="$value">
					<xsl:variable name="party-id" select="path:forward(., 'crm:P14_carried_out_by')" />
					<xsl:variable name="party-iri" select="$party-id/self::trix:uri"/>
					<map>
						<xsl:if test="$party-id">
							<string key='id'><xsl:value-of select="replace($party-id, '(.*/)([^/]*)(#)$', '$2')" /></string>
						</xsl:if>
						<!-- type -->
						<xsl:variable name="party-type" select="path:forward(., ('crm:P14_carried_out_by', 'rdf:type') )" />
						<xsl:if test="$party-type='http://www.cidoc-crm.org/cidoc-crm/E21_Person'">
							<string key='type'><xsl:text>Person</xsl:text></string>
						</xsl:if>
						<xsl:if test="$party-type='http://www.cidoc-crm.org/cidoc-crm/E74_Group'">
							<string key='type'><xsl:text>Organisation</xsl:text></string>
						</xsl:if>
						<!-- person name -->
						<xsl:copy-of select="xmljson:render-as-string('title', 
							path:forward(., ('crm:P14_carried_out_by', 'crm:P1_is_identified_by'))[
								path:forward(., 'rdf:type') = 'https://linked.art/ns/terms/Name'
							]
							/path:forward(., 'rdf:value')
						)" />
						<!-- organisation label -->
						<xsl:copy-of select="xmljson:render-as-string('title', path:forward(., ('crm:P14_carried_out_by', 'rdfs:label') ) )" />
						<!-- role -->
						<xsl:copy-of select="xmljson:render-as-string('roleName', path:forward(., 'rdfs:label') )" />
						<!-- production flag -->
						<string key='interactionType'><xsl:text>Production</xsl:text></string>
						<!-- description/notes -->
						<xsl:copy-of select="xmljson:render-as-string('description', path:forward(., ('crm:P129i_is_subject_of', 'rdf:value') ))" />
					</map>
			</xsl:for-each>
			</array>
		</xsl:if>
	</xsl:template>

	<!-- associated parties -->
	<xsl:template name="contributor-dc">
		<xsl:variable name="associated_person_value" select="
			path:forward('crm:P12i_was_present_at')[
				path:forward(., ('crm:P12_occurred_in_the_presence_of', 'rdf:type')) = 'http://www.cidoc-crm.org/cidoc-crm/E21_Person'
			]
		" />
		<xsl:variable name="associated_organisation_value" select="
			path:forward('crm:P12i_was_present_at')[
				path:forward(., ('crm:P12_occurred_in_the_presence_of', 'rdf:type')) = 'http://www.cidoc-crm.org/cidoc-crm/E74_Group'
			]
		" />
		<xsl:if test="$associated_person_value or $associated_organisation_value">
			<array key="contributor">
				<xsl:for-each select="$associated_person_value">
					<xsl:variable name="party-iri" select="path:forward(., 'crm:P12_occurred_in_the_presence_of')" />
					<map>
						<xsl:if test="$party-iri">
							<string key='id'><xsl:value-of select="replace($party-iri, '(.*/)([^/]*)(#)$', '$2')" /></string>
						</xsl:if>
						<!-- type -->
						<string key='type'><xsl:text>Person</xsl:text></string>
						<!-- person name -->
						<xsl:copy-of select="xmljson:render-as-string('title', 
							path:forward(., ('crm:P12_occurred_in_the_presence_of', 'crm:P1_is_identified_by'))[
								path:forward(., 'rdf:type') = 'https://linked.art/ns/terms/Name'
							]
							/path:forward(., 'rdf:value')
						)" />
						<!-- date -->
						<xsl:copy-of select="xmljson:render-as-string('title', path:forward(., ('crm:P4_has_time-span', 'rdfs:label') ) )" />
						<!-- role -->
						<xsl:copy-of select="xmljson:render-as-string('roleName', path:forward(., 'rdfs:label') )" />
						<!-- NB: no interactionType as not production -->
						<!-- description/notes -->
						<xsl:copy-of select="xmljson:render-as-string('description', path:forward(., ('crm:P129i_is_subject_of', 'rdf:value') ))" />
					</map>
				</xsl:for-each>
				<xsl:for-each select="$associated_organisation_value">
					<xsl:variable name="party-iri" select="path:forward(., 'crm:P12_occurred_in_the_presence_of')" />
					<map>
						<xsl:if test="$party-iri">
							<string key='id'><xsl:value-of select="replace($party-iri, '(.*/)([^/]*)(#)$', '$2')" /></string>
						</xsl:if>
						<!-- type -->
						<string key='type'><xsl:text>Organisation</xsl:text></string>
						<!-- organisation label -->
						<xsl:copy-of select="xmljson:render-as-string('title', path:forward(., ('crm:P12_occurred_in_the_presence_of', 'rdfs:label') ) )" />
						<!-- date -->
						<xsl:copy-of select="xmljson:render-as-string('title', path:forward(., ('crm:P4_has_time-span', 'rdfs:label') ) )" />
						<!-- role -->
						<xsl:copy-of select="xmljson:render-as-string('roleName', path:forward(., 'rdfs:label') )" />
						<!-- NB: no interactionType as not production -->
						<!-- description/notes -->
						<xsl:copy-of select="xmljson:render-as-string('description', path:forward(., ('crm:P129i_is_subject_of', 'rdf:value') ))" />
					</map>
				</xsl:for-each>
			</array>
		</xsl:if>
	</xsl:template>
	
	<!-- production places & associated places -->
	<xsl:template name="spatial-dc">
		<xsl:variable name="production_place_value" select="
			path:forward( ('crm:P108i_was_produced_by', 'crm:P9_consists_of') )[
				path:forward(., 'crm:P7_took_place_at')
			]
		" />
		<xsl:variable name="associated_place_value" select="
			path:forward('crm:P12i_was_present_at')[
				path:forward(., ('crm:P12_occurred_in_the_presence_of', 'rdf:type')) = 'http://www.cidoc-crm.org/cidoc-crm/E53_Place'
			]
		" />
		<xsl:if test="$production_place_value or $associated_place_value">
			<array key="spatial">
				<xsl:for-each select="$production_place_value">
					<xsl:variable name="place-iri" select="path:forward(., 'crm:P7_took_place_at')" />
					<map>
						<xsl:if test="$place-iri">
							<string key='id'><xsl:value-of select="replace($place-iri, '(.*/)([^/]*)(#)$', '$2')" /></string>
						</xsl:if>
						<!-- type -->
						<string key='type'><xsl:text>Place</xsl:text></string>
						<!-- place name -->
						<xsl:copy-of select="xmljson:render-as-string('title', path:forward(., ('crm:P7_took_place_at', 'rdfs:label') ) )" />
						<!-- role -->
						<xsl:copy-of select="xmljson:render-as-string('roleName', path:forward(., 'rdfs:label') )" />
						<!-- production flag -->
						<string key='interactionType'><xsl:text>Production</xsl:text></string>
						<!-- description/notes -->
						<xsl:copy-of select="xmljson:render-as-string('description', path:forward(., ('crm:P129i_is_subject_of', 'rdf:value') ))" />
						<!-- geo location -->
						<xsl:copy-of select="xmljson:render-as-string('geo', path:forward(., ('crm:P7_took_place_at', 'crm:P168_place_is_defined_by', 'rdf:value') ))" />
					</map>
				</xsl:for-each>
				<xsl:for-each select="$associated_place_value">
					<xsl:variable name="place-iri" select="path:forward(., 'crm:P12_occurred_in_the_presence_of')" />
					<map>
						<xsl:if test="$place-iri">
							<string key='id'><xsl:value-of select="replace($place-iri, '(.*/)([^/]*)(#)$', '$2')" /></string>
						</xsl:if>
						<!-- type -->
						<string key='type'><xsl:text>Place</xsl:text></string>
						<!-- place name -->
						<xsl:copy-of select="xmljson:render-as-string('title', path:forward(., ('crm:P12_occurred_in_the_presence_of', 'rdfs:label') ) )" />
						<!-- role -->
						<xsl:copy-of select="xmljson:render-as-string('roleName', path:forward(., 'rdfs:label') )" />
						<!-- NB: no interactionType as not production -->
						<!-- description/notes -->
						<xsl:copy-of select="xmljson:render-as-string('description', path:forward(., ('crm:P129i_is_subject_of', 'rdf:value') ))" />
						<!-- geo location -->
						<xsl:copy-of select="xmljson:render-as-string('geo', path:forward(., ('crm:P7_took_place_at', 'crm:P168_place_is_defined_by', 'rdf:value') ))" />
					</map>
				</xsl:for-each>
			</array>
		</xsl:if>
	</xsl:template>
	
	<!-- TODO: Add earliest/latest dates -->

	<!-- production dates and associated dates -->
	<!-- NB: if there is a note but no actual date the title will be empty (rather than including text when consumers are expecting an ISO date in the title) -->
	<xsl:template name="temporal-dc">
		<xsl:variable name="production_date_value" select="
			path:forward( ('crm:P108i_was_produced_by', 'crm:P9_consists_of') )[
				path:forward(., 'crm:P4_has_time-span')
			]
		" />
		<xsl:variable name="associated_date_value" select="
			path:forward('crm:P12i_was_present_at')[
				path:forward(., ('crm:P4_has_time-span', 'rdf:type')) = 'http://www.cidoc-crm.org/cidoc-crm/E52_Time-Span'
			]
		" />
		<xsl:if test="$production_date_value or $associated_date_value">
			<array key="temporal">
				<xsl:for-each select="$production_date_value">
					<map>
						<!-- type -->
						<string key='type'><xsl:text>Event</xsl:text></string>
						<!-- display date -->
						<xsl:copy-of select="xmljson:render-as-string('title', path:forward(., ('crm:P4_has_time-span', 'rdfs:label') ) )" />
						<!-- earliest/latest date -->
						<xsl:copy-of select="xmljson:render-as-string('startDate', path:forward(., ('crm:P4_has_time-span', 'crm:P82a_begin_of_the_begin') ) )" />
						<xsl:copy-of select="xmljson:render-as-string('endDate', path:forward(., ('crm:P4_has_time-span', 'crm:P82b_end_of_the_end') ) )" />
						<!-- role -->
						<xsl:copy-of select="xmljson:render-as-string('roleName', path:forward(., 'rdfs:label') )" />
						<!-- production flag -->
						<string key='interactionType'><xsl:text>Production</xsl:text></string>
						<!-- description/notes -->
						<xsl:copy-of select="xmljson:render-as-string('description', path:forward(., ('crm:P129i_is_subject_of', 'rdf:value') ))" />
					</map>
				</xsl:for-each>
				<xsl:for-each select="$associated_date_value">
					<map>
						<!-- type -->
						<string key='type'><xsl:text>Event</xsl:text></string>
						<!-- display date -->
						<xsl:copy-of select="xmljson:render-as-string('title', path:forward(., ('crm:P4_has_time-span', 'rdfs:label') ) )" />
						<!-- earliest/latest date -->
						<xsl:copy-of select="xmljson:render-as-string('startDate', path:forward(., ('crm:P4_has_time-span', 'crm:P82a_begin_of_the_begin') ) )" />
						<xsl:copy-of select="xmljson:render-as-string('endDate', path:forward(., ('crm:P4_has_time-span', 'crm:P82b_end_of_the_end') ) )" />
						<!-- role -->
						<xsl:copy-of select="xmljson:render-as-string('roleName', path:forward(., 'rdfs:label') )" />
						<!-- NB: no interactionType as not production -->
						<!-- description/notes -->
						<xsl:copy-of select="xmljson:render-as-string('description', path:forward(., ('crm:P129i_is_subject_of', 'rdf:value') ))" />
					</map>
				</xsl:for-each>
			</array>
		</xsl:if>
	</xsl:template>

	<!-- acknowledgement -->
	<xsl:template name="acknowledgement-dc">
		<xsl:copy-of select="xmljson:render-as-string('acknowledgement', 
			path:forward('crm:P67i_is_referred_to_by')[
				path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300026687'
			]
			/path:forward(., 'rdf:value')
		)" />
	</xsl:template>
	
	<!-- inward loan -->
	<xsl:template name="inwardloan-dc">
		<xsl:if test="
			path:forward('crm:P30i_custody_transferred_through')[
				path:forward(., 'crm:P29_custody_received_by') = 'http://dbpedia.org/resource/National_Museum_of_Australia'
			]
		">
			<string key='source'><xsl:text>Inward loan</xsl:text></string>
		</xsl:if>
	</xsl:template>
	
	<!-- TODO: could mint 'workFeaturedIn' instead of location (as inverse to schema:workFeatured) -->

	<!-- exhibition location -->
	<xsl:template name="exhibition-location-dc">
		<xsl:copy-of select="xmljson:render-as-string('location', 
			path:forward('crm:P16i_was_used_for')[
				path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300054766'
			]
			/path:forward(., 'rdfs:label')
		)" />
	</xsl:template>

	<!-- parent object -->
	<xsl:template name="object-parent-dc">
		<xsl:variable name="value" select="
			path:forward('crm:P46i_forms_part_of')[
				path:forward(., 'rdf:type') = 'http://www.cidoc-crm.org/cidoc-crm/E19_Physical_Object'
			]
		" />
		<xsl:if test="$type='object' and $value">
			<array key="isPartOf">
				<xsl:for-each select="$value">
					<map>
						<!-- id -->
						<xsl:copy-of select="xmljson:render-as-string('id', replace(., '(.*/)([^/]*)(#)$', '$2'))" />
						<!-- type -->
						<xsl:copy-of select="xmljson:render-as-string('type', $type)" />
						<!-- title -->
						<xsl:copy-of select="xmljson:render-as-string('title', path:forward(., 'rdfs:label') )" />
					</map>
			</xsl:for-each>
			</array>
		</xsl:if>
	</xsl:template>
	
	<!-- children objects -->
	<xsl:template name="object-children-dc">
		<xsl:variable name="value" select="
			path:forward('crm:P46_is_composed_of')[
				path:forward(., 'rdf:type') = 'http://www.cidoc-crm.org/cidoc-crm/E19_Physical_Object'
			]
		" />
		<xsl:if test="$type='object' and $value">
			<array key="hasPart">
				<xsl:for-each select="$value">
					<map>
						<!-- id -->
						<xsl:copy-of select="xmljson:render-as-string('id', replace(., '(.*/)([^/]*)(#)$', '$2'))" />
						<!-- type -->
						<xsl:copy-of select="xmljson:render-as-string('type', $type)" />
						<!-- title -->
						<xsl:copy-of select="xmljson:render-as-string('title', path:forward(., 'rdfs:label') )" />
					</map>
			</xsl:for-each>
			</array>
		</xsl:if>
	</xsl:template>
	
	<!-- related -->
	<xsl:template name="related-dc">
		<xsl:variable name="value" select="path:forward('dc:relation')" />
		<xsl:if test="$value">
			<array key="relation">
				<xsl:for-each select="$value">
					<map>
						<string key='id'><xsl:value-of select="replace(., '(.*/)([^/]*)(#)$', '$2')" /></string>
						<!-- type (assuming same type) -->
						<xsl:copy-of select="xmljson:render-as-string('type', $type)" />
						<!-- title -->
						<xsl:copy-of select="xmljson:render-as-string('title', path:forward(., 'rdfs:label') )" />
					</map>
				</xsl:for-each>
			</array>
		</xsl:if>
	</xsl:template>
	
	<!-- parent object for media -->
	<xsl:template name="media-parent-dc">
		<xsl:variable name="objects-represented-by-media" select="path:forward('crm:P138_represents')"/>
		<xsl:if test="$objects-represented-by-media">
			<array key="isVersionOf">
				<xsl:for-each select="$objects-represented-by-media">
					<map>
						<string key='type'><xsl:text>object</xsl:text></string>
						<xsl:copy-of select="xmljson:render-as-string('id', replace(., '(.*/)([^/]*)(#)$', '$2'))" />
					</map>
				</xsl:for-each>
			</array>
		</xsl:if>
	</xsl:template>

	<!-- web links -->
	<xsl:template name="web-links-dc">
		<xsl:variable name="value" select="
			path:forward('rdfs:seeAlso')[
				path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300264578'
			]
		" />
		<xsl:if test="$value">
			<array key="seeAlso">
				<xsl:for-each select="$value">
					<map>
						<string key='type'><xsl:text>Link</xsl:text></string>
						<xsl:copy-of select="xmljson:render-as-string('title', path:forward(., 'rdfs:label') )" />
						<xsl:copy-of select="xmljson:render-as-string('identifier', path:forward(., 'crm:P1_is_identified_by') )" />
					</map>
				</xsl:for-each>
			</array>
		</xsl:if>
	</xsl:template>
	
	<!-- TODO: separate into named templates the rendering of representation-level and digital-file-level, 
	     then call appropriately if root-resource is an 'object' entity (repn) or 'media' entity (files) -->

	<!-- representations and their digital media files -->
	<xsl:template name="representations-dc">
		<!-- embed record-level rights next to each media (as that's what it refers to) -->
		<xsl:call-template name="rights-dc-display">
			<xsl:with-param name="value" select="$root-resource" />
		</xsl:call-template>
		<!-- display preferred first (NB: only representations inside objects have preferred tagging) -->
		<xsl:variable name="value-preferred" select="
			path:forward('crm:P138i_has_representation')[
				path:forward(., 'crm:P2_has_type') = concat($api-base-uri, '/term/preferred')
			]
		" />
		<!-- then unpreferred (this also picks up representations inside narratives/media) -->
		<xsl:variable name="value-unpreferred" select="
			path:forward('crm:P138i_has_representation')[
				not( path:forward(., 'crm:P2_has_type') = concat($api-base-uri, '/term/preferred') )
			]
		" />
		<!-- for object: this is an array of media (which contain digital files) -->
		<!-- for media: this is an array of the digital files inside this one media -->
		<xsl:if test="$value-preferred or $value-unpreferred">
			<array key="hasVersion">
				<xsl:for-each select="($value-preferred, $value-unpreferred)">
					<xsl:call-template name="representations-dc-display">
						<xsl:with-param name="value" select="." />
					</xsl:call-template>
				</xsl:for-each>
			</array>
		</xsl:if>
	</xsl:template>

	<!-- display a representation -->
	<!-- (called from within: representations-dc, narrative-image-dc, narrative-objects-dc) -->
	<!-- NB: this displays the 'meat' of one representation (inside an array), which will be different depending on entity type -->
	<!-- object: shows one media plus its multiple child digital files (2nd level P138 has representation) -->
	<!-- media: shows one digital file (has no lower level P138 has representation) -->
	<xsl:template name="representations-dc-display">
		<xsl:param name="value" />
		<map>
			<!-- if media entity, a representation is a digital file, which doesn't have an id -->
			<xsl:if test="not($type='media')">
				<xsl:copy-of
					select="xmljson:render-as-string('id', replace(., '(.*/)([^/]*)(#)$', '$2'))" />
			</xsl:if>
			<string key='type'>
				<xsl:text>StillImage</xsl:text>
			</string>
			<xsl:copy-of select="xmljson:render-as-string('identifier', .)" />
			<!-- NB: for media P2/version is preferred flag, for file is thumb/preview/etc -->
			<xsl:copy-of
				select="xmljson:render-as-string('version', path:forward(., ('crm:P2_has_type', 'rdfs:label')))" />
			<!-- embed record-level rights next to each media (as that's what it refers to) -->
			<xsl:call-template name="rights-dc-display">
				<xsl:with-param name="value" select="$value" />
			</xsl:call-template>
			<!-- digital media files for this representation - only objects have a 2nd level -->
			<xsl:variable name="value2"
				select="path:forward(., 'crm:P138i_has_representation')" />
			<xsl:if test="$value2">
				<array key="hasVersion">
					<xsl:for-each select="$value2">
						<map>
							<string key='type'>
								<xsl:text>StillImage</xsl:text>
							</string>
							<xsl:copy-of
								select="xmljson:render-as-string('version', path:forward(., ('crm:P2_has_type', 'rdfs:label')))" />
							<string key='identifier'>
								<xsl:value-of select="." />
								<xsl:value-of select="path:forward(., 'rdf:value')" />
							</string>
							<!-- <xsl:for-each select="path:forward(., 'crm:P43_has_dimension')"> <string 
								key='dimension'> <xsl:value-of select="path:forward(., 'rdf:value')" /> </string> 
								</xsl:for-each> -->
						</map>
					</xsl:for-each>
				</array>
			</xsl:if>
		</map>
	</xsl:template>

	<!-- display rights within a representation -->
	<!-- (called from within representations-dc-display) -->
	<!-- NB: will only display if the supplied representation is at the level that has ore:isAggregatedBy -->
	<xsl:template name="rights-dc-display">
		<xsl:param name="value" />
		<!-- the object is represented by images which are aggregated into a bundle which is subject to certain legal rights -->
		<xsl:variable name="rights" select="path:forward($value, ('ore:isAggregatedBy', 'crm:P104_is_subject_to'))"/>
		<!-- one component part of the rights is a formal licence (Creative Commons or similar) -->
		<xsl:variable name="licence" select="path:forward($rights, 'crm:P148_has_component')"/>
		<xsl:copy-of select="xmljson:render-as-string('rights', $licence)" />
		<xsl:copy-of select="xmljson:render-as-string('rightsTitle', path:forward( $licence, 'rdfs:label' ))" />
		<!-- the rights may also be described by a document whose textual value gives a reason for the restriction -->
		<xsl:copy-of select="xmljson:render-as-string('rightsReason', path:forward( $rights, ('crm:P129i_is_subject_of', 'rdf:value') ))" />
	</xsl:template>

	<!-- PARTY FIELDS -->
	
	<!-- full name -->
	<xsl:template name="full-name-dc">
		<xsl:copy-of select="xmljson:render-as-string('name', 
			path:forward('crm:P1_is_identified_by')[
				path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300404688'
			]
			/path:forward(., 'rdf:value')
		)" />
	</xsl:template>
	
	<!-- first name -->
	<xsl:template name="first-name-dc">
		<xsl:copy-of select="xmljson:render-as-string('givenName', 
			path:forward( ('crm:P1_is_identified_by', 'crm:P106_is_composed_of') )[
				path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300404651'
			]
			/path:forward(., 'rdf:value')
		)" />
	</xsl:template>
	
	<!-- middle name -->
	<xsl:template name="middle-name-dc">
		<xsl:copy-of
			select="xmljson:render-as-string('middleName', 
			path:forward( ('crm:P1_is_identified_by', 'crm:P106_is_composed_of') )[
				path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300404654'
			]
			/path:forward(., 'rdf:value')
		)" />
	</xsl:template>

	<!-- last name -->
	<xsl:template name="last-name-dc">
		<xsl:copy-of select="xmljson:render-as-string('familyName', 
			path:forward( ('crm:P1_is_identified_by', 'crm:P106_is_composed_of') )[
				path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300404652'
			]
			/path:forward(., 'rdf:value')
		)" />
	</xsl:template>

	<!-- other names -->
	<xsl:template name="other-name-dc">
		<xsl:variable name="value"
			select="
			path:forward( ('crm:P1_is_identified_by', 'crm:P106_is_composed_of') )[
				path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300264273'
			]
			/path:forward(., 'rdf:value')
		" />
		<xsl:if test="$value">
			<array key="alternativeNames">
				<xsl:for-each select="$value">
					<!-- NB: no JSON string labels -->
					<xsl:copy-of select="xmljson:render-as-string('', .)" />
				</xsl:for-each>
			</array>
		</xsl:if>
	</xsl:template>
	
	<!-- gender -->
	<xsl:template name="gender-dc">
		<xsl:copy-of select="xmljson:render-as-string('gender', 
			path:forward('crm:P107i_is_current_or_former_member_of')[
				path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300055147'
			]
			/path:forward(., 'rdfs:label')
		)" />
	</xsl:template>

	<!-- PLACE FIELDS -->
	
	<!-- location -->
	<xsl:template name="location-dc">
		<xsl:copy-of select="xmljson:render-as-string('geo', path:forward( ('crm:P168_place_is_defined_by', 'rdf:value') ))" />
	</xsl:template>
	
	<!-- NARRATIVE FIELDS -->
	
	<!-- TODO: can a narrative have multiple parent narratives? -->
	
	<!-- narrative text -->
	<xsl:template name="narrative-text-dc">
		<!-- AAT 300263751 is text (i.e. description) -->
		<xsl:variable name="value" select="
			path:forward('ore:aggregates')[
				path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300263751'
			]
		" />
		<xsl:if test="$type='narrative' and $value">
			<xsl:copy-of select="xmljson:render-as-string('description', path:forward($value, 'rdf:value') )" />
		</xsl:if>
	</xsl:template>
	
	<!-- narrative banner images -->
	<xsl:template name="narrative-image-dc">
		<xsl:variable name="value" select="
			path:forward('ore:aggregates')[
				path:forward(., 'crm:P2_has_type') = concat($api-base-uri, '/term/banner-image')
			]
		" />
		<xsl:if test="$type='narrative' and $value">
			<array key="hasVersion">
				<xsl:for-each select="$value">
					<xsl:call-template name="representations-dc-display">
						<xsl:with-param name="value" select="$value" />
					</xsl:call-template>
				</xsl:for-each>
			</array>
		</xsl:if>
	</xsl:template>
	
	<!-- parent narrative -->
	<xsl:template name="narrative-parent-dc">
		<xsl:variable name="value" select="
			path:forward('ore:isAggregatedBy')[
				path:forward(., 'rdf:type') = 'http://www.openarchives.org/ore/terms/Aggregation'
			]
		" />
		<!-- this is a narrative under another narrative -->
		<xsl:if test="$type='narrative' and $value">
			<array key="isPartOf">
				<xsl:for-each select="$value">
					<map>
						<!-- id -->
						<xsl:copy-of select="xmljson:render-as-string('id', replace(., '(.*/)([^/]*)(#)$', '$2'))" />
						<!-- type -->
						<string key='type'><xsl:text>narrative</xsl:text></string>
						<!-- title -->
						<xsl:copy-of select="xmljson:render-as-string('title', path:forward(., 'rdfs:label') )" />
					</map>
			</xsl:for-each>
			</array>
		</xsl:if>
		<!-- this is an object under a narrative -->
		<xsl:if test="$type='object' and $value">
			<array key="isAggregatedBy">
				<xsl:for-each select="$value">
					<map>
						<!-- id -->
						<xsl:copy-of select="xmljson:render-as-string('id', replace(., '(.*/)([^/]*)(#)$', '$2'))" />
						<!-- type -->
						<string key='type'><xsl:text>narrative</xsl:text></string>
						<!-- title -->
						<xsl:copy-of select="xmljson:render-as-string('title', path:forward(., 'rdfs:label') )" />
					</map>
			</xsl:for-each>
			</array>
		</xsl:if>
	</xsl:template>
	
	<!-- children narratives -->
	<xsl:template name="narrative-children-dc">
		<xsl:variable name="value" select="
			path:forward('ore:aggregates')[
				path:forward(., 'rdf:type') = 'http://www.openarchives.org/ore/terms/Aggregation'
			]
		" />
		<xsl:if test="$type='narrative' and $value">
			<array key="hasPart">
				<xsl:for-each select="$value">
					<map>
						<!-- id -->
						<xsl:copy-of select="xmljson:render-as-string('id', replace(., '(.*/)([^/]*)(#)$', '$2'))" />
						<!-- type -->
						<string key='type'><xsl:text>narrative</xsl:text></string>
						<!-- title -->
						<xsl:copy-of select="xmljson:render-as-string('title', path:forward(., 'rdfs:label') )" />
					</map>
			</xsl:for-each>
			</array>
		</xsl:if>
	</xsl:template>
	
	<!-- narrative's related objects -->
	<xsl:template name="narrative-objects-dc">
		<xsl:variable name="value" select="
			path:forward('ore:aggregates')[
				path:forward(., 'rdf:type') = 'http://www.cidoc-crm.org/cidoc-crm/E19_Physical_Object'
			]
		" />
		<xsl:if test="$type='narrative' and $value">
			<array key="aggregates">
				<xsl:for-each select="$value">
					<map>
						<!-- id -->
						<xsl:variable name="object-id" select="replace(., '(.*/)([^/]*)(#)$', '$2')" />
						<xsl:copy-of select="xmljson:render-as-string('id', $object-id)" />
						<!-- type -->
						<string key='type'><xsl:text>object</xsl:text></string>
						<!-- title -->
						<xsl:copy-of select="xmljson:render-as-string('title', path:forward(., 'rdfs:label') )" />
						<!-- media - only preferred, but include all files -->
						<xsl:variable name="value-preferred" select="
							path:forward(., 'crm:P138i_has_representation')[
								path:forward(., 'crm:P2_has_type') = concat($api-base-uri, '/term/preferred')
							]
						" />
						<!-- NB: assuming only one preferred -->
						<xsl:for-each select="$value-preferred[1]">
							<array key="hasVersion">
								<xsl:call-template name="representations-dc-display">
									<xsl:with-param name="value" select="$value-preferred" />
								</xsl:call-template>
							</array>
						</xsl:for-each>
						<!-- meta: collection explorer link -->
						<map key="_meta">
							<string key='hasFormat'><xsl:value-of select="concat($collection-explorer-uri, 'object/', $object-id)" /></string>
						</map>
					</map>
				</xsl:for-each>
			</array>
		</xsl:if>
	</xsl:template>

</xsl:stylesheet>
