<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:path="tag:conaltuohy.com,2018:nma/trix-path-traversal"
	xmlns:f="http://www.w3.org/2005/xpath-functions"
	xmlns:map="http://www.w3.org/2005/xpath-functions/map"
	xmlns:trix="http://www.w3.org/2004/03/trix/trix-1/">

	<xsl:import href="util/trix-traversal-functions.xsl" />
	
	<xsl:param name="root-resource"/><!-- e.g. "http://nma-dev.conaltuohy.com/xproc-z/narrative/1758#" -->
	<xsl:param name="dataset"/>
	<xsl:param name="hash"/>
	<xsl:param name="datestamp"/>
	<xsl:param name="source-count"/>

	<!-- type = the second-to-last component of the URI's path, e.g. "object" or "party" -->
	<xsl:variable name="type" select="replace($root-resource, '(.*/)([^/]*)(/.*)$', '$2')"/>
	<xsl:variable name="api-base-uri" select="replace($root-resource, '(.*)/.*/[^#]*#.*', '$1')"/>
	
	<xsl:template match="/">
					<doc>
						
						<!-- COMMON FIELDS -->
						<xsl:call-template name="id-solr" />
						<xsl:call-template name="type-solr" />
						<xsl:call-template name="additional-type-solr" />
						<xsl:call-template name="title-solr" />
						<xsl:call-template name="record-metadata-solr" />

						<!-- OBJECT FIELDS -->
						<xsl:call-template name="collection-solr" />
						<xsl:call-template name="accession-number-solr" />
						<xsl:call-template name="materials-solr" />
						<xsl:call-template name="dimensions-solr" />
						<xsl:call-template name="content-description-solr" />
						<xsl:call-template name="physical-description-solr" />
						<xsl:call-template name="significance-statement-solr" />
						<xsl:call-template name="educational-significance-solr" />
						<xsl:call-template name="production-parties-solr" />
						<xsl:call-template name="production-places-solr" />
						<xsl:call-template name="production-dates-solr" />
						<xsl:call-template name="associated-parties-solr" />
						<xsl:call-template name="associated-places-solr" />
						<xsl:call-template name="associated-dates-solr" />
						<xsl:call-template name="acknowledgement-solr" />
						<xsl:call-template name="inwardloan-solr" />
						<xsl:call-template name="rights-solr" />
						<xsl:call-template name="exhibition-location-solr" />
						<xsl:call-template name="object-parent-solr" />
						<xsl:call-template name="object-children-solr" />
						<xsl:call-template name="related-solr" />
						<xsl:call-template name="web-links-solr" />
						<xsl:call-template name="media-parent-solr" />
						<xsl:call-template name="representations-solr" />

						<!-- NARRATIVE FIELDS -->
						<xsl:call-template name="narrative-text-solr" />
						<xsl:call-template name="narrative-parent-solr" />
						<xsl:call-template name="narrative-children-solr" />
						<xsl:call-template name="narrative-objects-solr" />

						<!-- PARTY FIELDS -->
						<xsl:call-template name="names-solr" />
						<xsl:call-template name="gender-solr" />

						<!-- PLACE FIELDS -->
						<xsl:call-template name="location-solr" />
					</doc>
	</xsl:template>

	<!-- ############### FIELD PROCESSING TEMPLATES ############ -->

	<!-- COMMON FIELDS -->

	<!-- id -->
	<xsl:template name="id-solr">
		<!-- id = the last two components of the URI's path, e.g. "object/1234" or "party/5678" -->
		<field name="id"><xsl:value-of select="replace($root-resource, '(.*/)([^/]*/[^/]*)(#)$', '$2')"/></field>
	</xsl:template>

	<!-- type -->
	<xsl:template name="type-solr">
		<field name="type"><xsl:value-of select="$type"/></field>
		<xsl:for-each select="path:forward('rdf:type')">
			<field name="type"><xsl:value-of select="."/></field>
		</xsl:for-each>
	</xsl:template>

	<!-- additional type -->
	<xsl:template name="additional-type-solr">
		<xsl:for-each select="path:forward( ('crm:P2_has_type', 'rdfs:label') )">
			<field name="additionalType"><xsl:value-of select="."/></field>
		</xsl:for-each>
	</xsl:template>

	<!-- title -->
	<xsl:template name="title-solr">
		<xsl:for-each select="path:forward('rdfs:label')">
			<field name="title">
				<xsl:value-of select="." />
			</field>
			<!-- duplicate organisation name into name field -->
			<xsl:if test="$type='party'">
				<field name="name">
					<xsl:value-of select="." />
				</field>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>

	<!-- record metadata: modified, issued -->
	<xsl:template name="record-metadata-solr">
		<!-- modified -->
		<xsl:for-each select="path:forward( ('crm:P70i_is_documented_in', 'dc:modified') )">
			<field name="modified"><xsl:value-of select="." /></field>
			<field name="modified_date"><xsl:value-of select="." /></field>
		</xsl:for-each>
		<!-- web release -->
		<xsl:for-each select="path:forward( ('crm:P70i_is_documented_in', 'dc:issued') )">
			<field name="issued"><xsl:value-of select="." /></field>
			<field name="issued_date"><xsl:value-of select="." /></field>
		</xsl:for-each>
		
		<xsl:for-each select="path:forward( ('crm:P70i_is_documented_in', 'http://www.w3.org/2011/http#resp', 'http://www.w3.org/2011/http#statusCodeValue') )[1]">
			<field name="status_code"><xsl:value-of select="." /></field>
		</xsl:for-each>
		<xsl:for-each select="path:forward( ('crm:P70i_is_documented_in', 'http://www.w3.org/2011/http#resp', 'http://www.w3.org/2011/http#reasonPhrase') )[1]">
			<field name="reason"><xsl:value-of select="." /></field>
		</xsl:for-each>
	</xsl:template>
	
	<!-- OBJECT FIELDS -->

	<!-- collection -->
	<xsl:template name="collection-solr">
		<xsl:for-each select="path:forward('crm:P106i_forms_part_of')">
			<field name="collection_id"><xsl:value-of select="replace(., '(.*/)([^/]*)(#)$', '$2')"/></field>
			<field name="collection"><xsl:value-of select="path:forward(., 'rdfs:label')"/></field>
		</xsl:for-each>
	</xsl:template>
	
	<!-- accession number -->
	<xsl:template name="accession-number-solr">
		<xsl:for-each select="
			path:forward('crm:P1_is_identified_by')[
				path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300312355'
			]
		">
			<field name="identifier"><xsl:value-of select="path:forward(., 'rdf:value')"/></field>
		</xsl:for-each>
	</xsl:template>	

	<!-- materials -->
	<xsl:template name="materials-solr">
		<xsl:for-each select="path:forward( ('crm:P45_consists_of', 'rdfs:label') )">
			<field name="medium"><xsl:value-of select="."/></field>
		</xsl:for-each>
	</xsl:template>

	<!-- dimensions -->
	<xsl:template name="dimensions-solr">
		<!-- length -->
		<xsl:for-each select="
			path:forward('crm:P43_has_dimension')[
				path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300055645'
			]
			/path:forward(., 'rdf:value')
		">
			<field name="length"><xsl:value-of select="."/></field>
		</xsl:for-each>

		<!-- height -->
		<xsl:for-each select="
			path:forward('crm:P43_has_dimension')[
				path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300055644'
			]
			/path:forward(., 'rdf:value')
		">
			<field name="height"><xsl:value-of select="."/></field>
		</xsl:for-each>

		<!-- width -->
		<xsl:for-each select="
			path:forward('crm:P43_has_dimension')[
				path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300055647'
			]
			/path:forward(., 'rdf:value')
		">
			<field name="width"><xsl:value-of select="."/></field>
		</xsl:for-each>

		<!-- depth -->
		<xsl:for-each select="
			path:forward('crm:P43_has_dimension')[
				path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300072633'
			]
			/path:forward(., 'rdf:value')
		">
			<field name="depth"><xsl:value-of select="."/></field>
		</xsl:for-each>

		<!-- diameter -->
		<xsl:for-each select="
			path:forward('crm:P43_has_dimension')[
				path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300055624'
			]
			/path:forward(., 'rdf:value')
		">
			<field name="diameter"><xsl:value-of select="."/></field>
		</xsl:for-each>

		<!-- weight -->
		<xsl:for-each select="
			path:forward('crm:P43_has_dimension')[
				path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300056240'
			]
			/path:forward(., 'rdf:value')
		">
			<field name="weight"><xsl:value-of select="."/></field>
		</xsl:for-each>

		<!-- linear units (taken from first non-weight dimension) -->
		<xsl:variable name="linearDimensions" select="
			path:forward('crm:P43_has_dimension')[
				path:forward(., 'crm:P2_has_type') != 'http://vocab.getty.edu/aat/300056240'
			]
		" />
		<xsl:if test="$linearDimensions">
			<field name="unitText">
				<xsl:value-of select="path:forward($linearDimensions[1], ('crm:P91_has_unit', 'rdfs:label'))"/>
			</field>
		</xsl:if>

		<!-- weight units (taken from first weight dimension) -->
		<xsl:variable name="weightDimensions" select="
			path:forward('crm:P43_has_dimension')[
				path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300056240'
			]
		" />
		<xsl:if test="$weightDimensions">
			<field name="unitTextWeight">
				<xsl:value-of select="path:forward($weightDimensions[1], ('crm:P91_has_unit', 'rdfs:label'))"/>
			</field>
		</xsl:if>
	</xsl:template>
	
	<!-- content description -->
	<xsl:template name="content-description-solr">
		<xsl:for-each select="
			path:forward('crm:P129i_is_subject_of')[
				path:forward(., 'crm:P2_has_type') = concat($api-base-uri, '/term/contentDescription')
			]
			/path:forward(., 'rdf:value')
		">
			<field name="contentDescription"><xsl:value-of select="."/></field>
		</xsl:for-each>
	</xsl:template>

	<!-- physical description -->
	<xsl:template name="physical-description-solr">
		<xsl:for-each select="
			path:forward('crm:P129i_is_subject_of')[
				path:forward(., 'crm:P2_has_type') = concat($api-base-uri, '/term/physicalDescription')
			]
			/path:forward(., 'rdf:value')
		">
			<field name="physicalDescription"><xsl:value-of select="."/></field>
		</xsl:for-each>
	</xsl:template>

	<!-- significance statement -->
	<xsl:template name="significance-statement-solr">
		<xsl:for-each select="
			path:forward('crm:P129i_is_subject_of')[
				path:forward(., 'crm:P2_has_type') = concat($api-base-uri, '/term/significanceStatement')
			]
			/path:forward(., 'rdf:value')
		">
			<field name="significanceStatement"><xsl:value-of select="."/></field>
		</xsl:for-each>
	</xsl:template>

	<!-- educational significance -->
	<xsl:template name="educational-significance-solr">
		<xsl:for-each select="
			path:forward('crm:P129i_is_subject_of')[
				path:forward(., 'crm:P2_has_type') = concat($api-base-uri, '/term/educationalSignificance')
			]
			/path:forward(., 'rdf:value')
		">
			<field name="educationalSignificance"><xsl:value-of select="."/></field>
		</xsl:for-each>
	</xsl:template>

	<!-- production parties -->
	<xsl:template name="production-parties-solr">
		<xsl:for-each select="
			path:forward( ('crm:P108i_was_produced_by', 'crm:P9_consists_of') )[
				path:forward(., 'crm:P14_carried_out_by')
			]
		">
			<!-- party id -->
			<xsl:variable name="party-id" select="path:forward(., 'crm:P14_carried_out_by')" />
			<field name="creator_id"><xsl:value-of select="replace($party-id, '(.*/)([^/]*)(#)$', '$2')"/></field>
			<!-- person name -->
			<xsl:for-each select="
				path:forward(., ('crm:P14_carried_out_by', 'crm:P1_is_identified_by'))[
					path:forward(., 'rdf:type') = 'https://linked.art/ns/terms/Name'
				]
				/path:forward(., 'rdf:value')
			">
				<field name="creator"><xsl:value-of select="."/></field>
			</xsl:for-each>
			<!-- organisation label -->
			<xsl:for-each select="path:forward(., ('crm:P14_carried_out_by', 'rdfs:label') )">
				<field name="creator"><xsl:value-of select="."/></field>
			</xsl:for-each>
			<!-- role -->
			<xsl:for-each select="path:forward(., 'rdfs:label')">
				<field name="creator"><xsl:value-of select="."/></field>
			</xsl:for-each>
			<!-- description/notes -->
			<xsl:for-each select="path:forward(., ('crm:P129i_is_subject_of', 'rdf:value') )">
				<field name="creator"><xsl:value-of select="."/></field>
			</xsl:for-each>
		</xsl:for-each>
	</xsl:template>

	<!-- production places -->
	<xsl:template name="production-places-solr">
		<xsl:for-each select="
			path:forward( ('crm:P108i_was_produced_by', 'crm:P9_consists_of') )[
				path:forward(., 'crm:P7_took_place_at')
			]
		">
			<!-- place id -->
			<xsl:variable name="place-id" select="path:forward(., 'crm:P7_took_place_at')" />
			<field name="spatial_id"><xsl:value-of select="replace($place-id, '(.*/)([^/]*)(#)$', '$2')"/></field>
			<!-- label -->
			<xsl:for-each select="path:forward(., ('crm:P7_took_place_at', 'rdfs:label') )">
				<field name="spatial"><xsl:value-of select="."/></field>
			</xsl:for-each>
			<!-- geo location -->
			<xsl:for-each select="path:forward(., ('crm:P7_took_place_at', 'crm:P168_place_is_defined_by', 'rdf:value') )">
				<field name="spatial_geo"><xsl:value-of select="."/></field>
			</xsl:for-each>
			<!-- role -->
			<xsl:for-each select="path:forward(., 'rdfs:label')">
				<field name="spatial"><xsl:value-of select="."/></field>
			</xsl:for-each>
			<!-- description/notes -->
			<xsl:for-each select="path:forward(., ('crm:P129i_is_subject_of', 'rdf:value') )">
				<field name="spatial"><xsl:value-of select="."/></field>
			</xsl:for-each>
		</xsl:for-each>
	</xsl:template>

	<!-- production dates -->
	<xsl:template name="production-dates-solr">
		<xsl:for-each select="
			path:forward( ('crm:P108i_was_produced_by', 'crm:P9_consists_of') )[
				path:forward(., 'crm:P4_has_time-span')
			]
		">
			<!-- display date -->
			<xsl:for-each select="path:forward(., ('crm:P4_has_time-span', 'rdfs:label') )">
				<field name="temporal"><xsl:value-of select="."/></field>
			</xsl:for-each>
			<!-- encoded date -->
			<field name="temporal_date">
				<xsl:call-template name="format-solr-date-range">
					<xsl:with-param name="startDate" select="path:forward(., ('crm:P4_has_time-span', 'crm:P82a_begin_of_the_begin') )"/>
					<xsl:with-param name="endDate" select="path:forward(., ('crm:P4_has_time-span', 'crm:P82b_end_of_the_end') )"/>
				</xsl:call-template>
			</field>
			<!-- role -->
			<xsl:for-each select="path:forward(., 'rdfs:label')">
				<field name="temporal"><xsl:value-of select="."/></field>
			</xsl:for-each>
			<!-- description/notes -->
			<xsl:for-each select="path:forward(., ('crm:P129i_is_subject_of', 'rdf:value') )">
				<field name="temporal"><xsl:value-of select="."/></field>
			</xsl:for-each>
		</xsl:for-each>
	</xsl:template>

	<!-- associated parties -->
	<xsl:template name="associated-parties-solr">
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
		<xsl:for-each select="$associated_organisation_value | $associated_person_value">
			<!-- id -->
			<xsl:variable name="party-iri" select="path:forward(., 'crm:P12_occurred_in_the_presence_of')" />
			<xsl:if test="$party-iri">
				<field name="contributor_id"><xsl:value-of select="replace($party-iri, '(.*/)([^/]*)(#)$', '$2')" /></field>
			</xsl:if>
			<!-- person name -->
			<field name="contributor"><xsl:value-of select="
				path:forward(., ('crm:P12_occurred_in_the_presence_of', 'crm:P1_is_identified_by'))[
					path:forward(., 'rdf:type') = 'https://linked.art/ns/terms/Name'
				]
				/path:forward(., 'rdf:value')
			"/></field>
			<!-- organisation label -->
			<xsl:for-each select="path:forward(., ('crm:P12_occurred_in_the_presence_of', 'rdfs:label') )">
				<field name="contributor"><xsl:value-of select="."/></field>
			</xsl:for-each>
			<!-- date -->
			<xsl:for-each select="path:forward(., ('crm:P4_has_time-span', 'rdfs:label') )">
				<field name="contributor"><xsl:value-of select="."/></field>
			</xsl:for-each>
			<!-- role -->
			<xsl:for-each select="path:forward(., 'rdfs:label')">
				<field name="contributor"><xsl:value-of select="."/></field>
			</xsl:for-each>
			<!-- description/notes -->
			<xsl:for-each select="path:forward(., ('crm:P129i_is_subject_of', 'rdf:value') )">
				<field name="contributor"><xsl:value-of select="."/></field>
			</xsl:for-each>
		</xsl:for-each>
	</xsl:template>

	<!-- associated places -->
	<xsl:template name="associated-places-solr">
		<xsl:for-each select="
			path:forward('crm:P12i_was_present_at')[
				path:forward(., ('crm:P12_occurred_in_the_presence_of', 'rdf:type')) = 'http://www.cidoc-crm.org/cidoc-crm/E53_Place'
			]
		">
			<!-- place id -->
			<xsl:variable name="place-id" select="path:forward(., 'crm:P12_occurred_in_the_presence_of')" />
			<field name="spatial_id"><xsl:value-of select="replace($place-id, '(.*/)([^/]*)(#)$', '$2')"/></field>
			<!-- label -->
			<xsl:for-each select="path:forward(., ('crm:P12_occurred_in_the_presence_of', 'rdfs:label') )">
				<field name="spatial"><xsl:value-of select="."/></field>
			</xsl:for-each>
			<!-- geo location -->
			<xsl:for-each select="path:forward(., ('crm:P12_occurred_in_the_presence_of', 'crm:P168_place_is_defined_by', 'rdf:value') )">
				<field name="spatial_geo"><xsl:value-of select="."/></field>
			</xsl:for-each>
			<!-- role -->
			<xsl:for-each select="path:forward(., 'rdfs:label')">
				<field name="spatial"><xsl:value-of select="."/></field>
			</xsl:for-each>
			<!-- description/notes -->
			<xsl:for-each select="path:forward(., ('crm:P129i_is_subject_of', 'rdf:value') )">
				<field name="spatial"><xsl:value-of select="."/></field>
			</xsl:for-each>
		</xsl:for-each>
	</xsl:template>

	<!-- associated dates -->
	<xsl:template name="associated-dates-solr">
		<xsl:for-each select="
			path:forward('crm:P12i_was_present_at')[
				path:forward(., 'crm:P4_has_time-span')
			]
		">
			<!-- display date -->
			<xsl:for-each select="path:forward(., ('crm:P4_has_time-span', 'rdfs:label') )">
				<field name="temporal"><xsl:value-of select="."/></field>
			</xsl:for-each>
			<!-- encoded date -->
			<field name="temporal_date">
				<xsl:call-template name="format-solr-date-range">
					<xsl:with-param name="startDate" select="path:forward(., ('crm:P4_has_time-span', 'crm:P82a_begin_of_the_begin') )"/>
					<xsl:with-param name="endDate" select="path:forward(., ('crm:P4_has_time-span', 'crm:P82b_end_of_the_end') )"/>
				</xsl:call-template>
			</field>
			<!-- role -->
			<xsl:for-each select="path:forward(., 'rdfs:label')">
				<field name="temporal"><xsl:value-of select="."/></field>
			</xsl:for-each>
			<!-- description/notes -->
			<xsl:for-each select="path:forward(., ('crm:P129i_is_subject_of', 'rdf:value') )">
				<field name="temporal"><xsl:value-of select="."/></field>
			</xsl:for-each>
		</xsl:for-each>
	</xsl:template>

	<!-- acknowledgement -->
	<xsl:template name="acknowledgement-solr">
		<xsl:for-each select="
			path:forward('crm:P67i_is_referred_to_by')[
				path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300026687'
			]
			/path:forward(., 'rdf:value')
		">
			<field name="acknowledgement"><xsl:value-of select="."/></field>
		</xsl:for-each>
	</xsl:template>

	<!-- inward loan -->
	<xsl:template name="inwardloan-solr">
		<xsl:if test="
			path:forward(('crm:P30i_custody_transferred_through', 'crm:P29_custody_received_by')) = 'http://dbpedia.org/resource/National_Museum_of_Australia'
		">
			<field name="source"><xsl:text>Inward loan</xsl:text></field>
		</xsl:if>
	</xsl:template>

	<!-- rights -->
	<xsl:template name="rights-solr">
		<xsl:variable name="value" select="path:forward(('crm:P138i_has_representation', 'ore:isAggregatedBy', 'crm:P104_is_subject_to'))" />
		<xsl:if test="$value">
			<!-- all rights for representations of an object are the same, so just use the first one -->
			<xsl:for-each select="$value[1]">
				<!-- rights IRI -->
				<field name="rights"><xsl:value-of select="path:forward(., 'crm:P148_has_component')"/></field>
				<!-- rights label -->
				<field name="rights"><xsl:value-of select="path:forward(., ('crm:P148_has_component', 'rdfs:label') )"/></field>
				<!-- rights restriction reason -->
				<xsl:for-each select="path:forward(., ('crm:P129i_is_subject_of', 'rdf:value') )">
					<field name="rights"><xsl:value-of select="."/></field>
				</xsl:for-each>
			</xsl:for-each>
		</xsl:if>
	</xsl:template>

	<!-- exhibition location -->
	<xsl:template name="exhibition-location-solr">
		<xsl:for-each select="
			path:forward('crm:P16i_was_used_for')[
				path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300054766'
			]
			/path:forward(., 'rdfs:label')
		">
			<field name="location"><xsl:value-of select="."/></field>
		</xsl:for-each>
	</xsl:template>

	<!-- web links -->
	<xsl:template name="web-links-solr">
		<xsl:for-each select="
			path:forward('rdfs:seeAlso')[
				path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300264578'
			]
			/path:forward(., 'crm:P1_is_identified_by')
		">
			<field name="seeAlso"><xsl:value-of select="."/></field>
		</xsl:for-each>
	</xsl:template>
	
	<!-- parent object - identifiers only (titles would skew keyword searches) -->
	<xsl:template name="object-parent-solr">
		<xsl:variable name="value" select="
			path:forward('crm:P46i_forms_part_of')[
				path:forward(., 'rdf:type') = 'http://www.cidoc-crm.org/cidoc-crm/E19_Physical_Object'
			]
		" />
		<xsl:if test="$type='object' and $value">
			<xsl:for-each select="$value">
				<field name="isPartOf_object_id"><xsl:value-of select="replace(., '(.*/)([^/]*)(#)$', '$2')"/></field>
			</xsl:for-each>
		</xsl:if>
	</xsl:template>
	
	<!-- children objects - identifiers only (titles would skew keyword searches) -->
	<xsl:template name="object-children-solr">
		<xsl:variable name="value" select="
			path:forward('crm:P46_is_composed_of')[
				path:forward(., 'rdf:type') = 'http://www.cidoc-crm.org/cidoc-crm/E19_Physical_Object'
			]
		" />
		<xsl:if test="$type='object' and $value">
			<xsl:for-each select="$value">
				<field name="hasPart_object_id"><xsl:value-of select="replace(., '(.*/)([^/]*)(#)$', '$2')"/></field>
			</xsl:for-each>
		</xsl:if>
	</xsl:template>
	
	<!-- related - identifiers only (titles would skew keyword searches) -->
	<xsl:template name="related-solr">
		<xsl:for-each select="path:forward('dc:relation')">
			<field name="related_object_id"><xsl:value-of select="replace(., '(.*/)([^/]*)(#)$', '$2')"/></field>
		</xsl:for-each>
	</xsl:template>

	<!-- parent object for media -->
	<xsl:template name="media-parent-solr">
		<xsl:for-each select="path:forward('crm:P138_represents')">
			<field name="media_object_id"><xsl:value-of select="replace(., '(.*/)([^/]*)(#)$', '$2')"/></field>
		</xsl:for-each>
	</xsl:template>

	<!-- representations - identifiers only -->
	<xsl:template name="representations-solr">
		<xsl:for-each select="path:forward('crm:P138i_has_representation')">
			<field name="media"><xsl:value-of select="replace(., '(.*/)([^/]*)(#)$', '$2')"/></field>
			<field name="media_id"><xsl:value-of select="replace(., '(.*/)([^/]*)(#)$', '$2')"/></field>
			<xsl:for-each select="path:forward(., 'crm:P138i_has_representation')">
				<field name="media"><xsl:value-of select="replace(., '(.*/)([^/]*)(#)$', '$2')"/></field>
				<field name="media_id"><xsl:value-of select="replace(., '(.*/)([^/]*)(#)$', '$2')"/></field>
			</xsl:for-each>
		</xsl:for-each>
	</xsl:template>

	<!-- NARRATIVE FIELDS -->
	
	<!-- narrative text -->
	<xsl:template name="narrative-text-solr">
		<xsl:variable name="value" select="
			path:forward('ore:aggregates')[
				path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300263751'
			]
		" />
		<xsl:if test="$type='narrative' and $value">
			<field name="description"><xsl:value-of select="path:forward($value, 'rdf:value')"/></field>
		</xsl:if>
	</xsl:template>
	
	<!-- narrative banner images - not searchable -->
	
	<!-- parent narrative -->
	<xsl:template name="narrative-parent-solr">
		<xsl:variable name="value" select="
			path:forward('ore:isAggregatedBy')[
				path:forward(., 'rdf:type') = 'http://www.openarchives.org/ore/terms/Aggregation'
			]
		" />
		<!-- this is a narrative under another narrative -->
		<xsl:if test="$type='narrative' and $value">
			<xsl:for-each select="$value">
				<field name="isPartOf_narrative_id"><xsl:value-of select="replace(., '(.*/)([^/]*)(#)$', '$2')"/></field>
			</xsl:for-each>
		</xsl:if>
		<!-- this is an object under a narrative -->
		<xsl:if test="$type='object' and $value">
			<xsl:for-each select="$value">
				<field name="isAggregatedBy_narrative_id"><xsl:value-of select="replace(., '(.*/)([^/]*)(#)$', '$2')"/></field>
			</xsl:for-each>
		</xsl:if>
	</xsl:template>
	
	<!-- children narratives -->
	<xsl:template name="narrative-children-solr">
		<xsl:variable name="value" select="
			path:forward('ore:aggregates')[
				path:forward(., 'rdf:type') = 'http://www.openarchives.org/ore/terms/Aggregation'
			]
		" />
		<xsl:if test="$type='narrative' and $value">
			<xsl:for-each select="$value">
				<field name="hasPart_narrative_id"><xsl:value-of select="replace(., '(.*/)([^/]*)(#)$', '$2')"/></field>
			</xsl:for-each>
		</xsl:if>
	</xsl:template>
	
	<!-- narrative's related objects -->
	<xsl:template name="narrative-objects-solr">
		<xsl:variable name="value" select="
			path:forward('ore:aggregates')[
				path:forward(., 'rdf:type') = 'http://www.cidoc-crm.org/cidoc-crm/E19_Physical_Object'
			]
		" />
		<xsl:if test="$type='narrative' and $value">
			<xsl:for-each select="$value">
				<field name="aggregates_object_id"><xsl:value-of select="replace(., '(.*/)([^/]*)(#)$', '$2')"/></field>
			</xsl:for-each>
		</xsl:if>
	</xsl:template>

	<!-- PARTY FIELDS -->
	
	<!-- name and parts of name -->
	<xsl:template name="names-solr">
		<xsl:for-each select="
			path:forward('crm:P1_is_identified_by')[
				path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300404688'
			]
		">
			<field name="name"><xsl:value-of select="path:forward(., 'rdf:value')"/></field>
			<!-- name parts -->
			<xsl:for-each select="path:forward(., ('crm:P106_is_composed_of', 'rdf:value') )">
				<field name="name"><xsl:value-of select="."/></field>
			</xsl:for-each>
		</xsl:for-each>
	</xsl:template>
	
	<!-- gender -->
	<xsl:template name="gender-solr">
		<xsl:for-each select="path:forward( ('crm:P107i_is_current_or_former_member_of', 'rdfs:label') )">
			<field name="gender"><xsl:value-of select="."/></field>
		</xsl:for-each>
	</xsl:template>

	<!-- PLACE FIELDS -->
	
	<!-- location -->
	<xsl:template name="location-solr">
		<xsl:for-each select="path:forward( ('crm:P168_place_is_defined_by', 'rdf:value') )">
			<field name="geo"><xsl:value-of select="."/></field>
		</xsl:for-each>
	</xsl:template>
	
	<!-- FUNCTIONS -->

	<!-- format solr date range -->
	<!-- solr.DateRangeField: "[start|* TO end|*]", or single date if both the same -->
	<!-- https://lucene.apache.org/solr/guide/working-with-dates.html -->
	<xsl:template name="format-solr-date-range">
		<xsl:param name="startDate" />
		<xsl:param name="endDate" />
		<xsl:choose>
			<xsl:when test="$startDate = $endDate">
				<xsl:value-of select="$startDate" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>[</xsl:text>
				<xsl:choose>
					<xsl:when test="$startDate">
						<xsl:value-of select="$startDate" />
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>*</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:text> TO </xsl:text>
				<xsl:choose>
					<xsl:when test="$endDate">
						<xsl:value-of select="$endDate" />
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>*</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:text>]</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

</xsl:stylesheet>
