<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:path="tag:conaltuohy.com,2018:nma/trix-path-traversal"
	xmlns:f="http://www.w3.org/2005/xpath-functions"
	xmlns:map="http://www.w3.org/2005/xpath-functions/map"
	xmlns:trix="http://www.w3.org/2004/03/trix/trix-1/">
	
	<xsl:import href="trix-description-to-json-ld.xsl"/>
	<xsl:import href="trix-description-to-dc.xsl"/>
	<xsl:import href="util/compact-json-ld.xsl"/>
	
	<xsl:param name="root-resource"/><!-- e.g. "http://nma-dev.conaltuohy.com/xproc-z/narrative/1758#" -->
	<xsl:param name="dataset"/>

	<!-- type = the second-to-last component of the URI's path, e.g. "object" or "party" -->
	<xsl:variable name="type" select="replace($root-resource, '(.*/)([^/]*)(/.*)$', '$2')"/>
	<xsl:variable name="api-base-uri" select="replace($root-resource, '(.*)/.*/[^#]*#.*', '$1')"/>
	
	<xsl:template match="/">
		<!-- discover if this is a child object (has a parent object) -->
		<xsl:variable name="object_parents" select="
			path:forward('ore:isAggregatedBy')[
				path:forward(., 'rdf:type') = 'http://www.cidoc-crm.org/cidoc-crm/E19_Physical_Object'
			]
		" />
		<c:request method="post" href="http://localhost:8983/solr/core_nma_{$dataset}/update" detailed="true">
			<c:body content-type="application/xml">
				<add commitWithin="10000">
					<doc>
						<!-- for child objects, we load the data but don't index (can retrieve but can't search) -->
						<xsl:if test="not($type='object' and $object_parents)">

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
							<xsl:call-template name="rights-solr" />
							<xsl:call-template name="exhibition-location-solr" />
							<xsl:call-template name="object-parent-solr" />
							<xsl:call-template name="object-children-solr" />
							<xsl:call-template name="related-solr" />
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

						</xsl:if>
					
						<!-- Linked Art JSON-LD blob -->
						<xsl:variable name="json-ld-in-xml">
							<xsl:call-template name="resource-as-json-ld-xml">
								<xsl:with-param name="resource" select="$root-resource"/>
								<xsl:with-param name="context" select=" '/context.json' "/>
							</xsl:call-template>
						</xsl:variable>
						<xsl:variable name="compact-json-ld-in-xml">
							<xsl:apply-templates select="$json-ld-in-xml" mode="compact"/>
						</xsl:variable>
						<field name="json-ld"><xsl:value-of select="xml-to-json($compact-json-ld-in-xml, map{'indent':true()})"/></field>

						<!-- Simplified DC blob -->
						<xsl:variable name="dc-in-xml">
							<xsl:call-template name="dc-xml">
								<xsl:with-param name="resource" select="$root-resource"/>
							</xsl:call-template>
						</xsl:variable>
						<field name="simple">
							<xsl:copy-of select="$dc-in-xml"/>
						</field>
					</doc>
				</add>
			</c:body>
		</c:request>
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
		<xsl:for-each select="path:forward( ('crm:P43_has_dimension', 'rdf:value') )">
			<field name="dimension"><xsl:value-of select="."/></field>
		</xsl:for-each>
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
			<!-- value -->
			<xsl:for-each select="path:forward(., ('crm:P4_has_time-span', 'rdfs:label') )">
				<field name="temporal"><xsl:value-of select="."/></field>
				<field name="temporal_date"><xsl:value-of select="."/></field>
			</xsl:for-each>
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
			<field name="spatial"><xsl:value-of select="replace($place-id, '(.*/)([^/]*)(#)$', '$2')"/></field>
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
			<!-- value -->
			<xsl:for-each select="path:forward(., ('crm:P4_has_time-span', 'rdfs:label') )">
				<field name="temporal"><xsl:value-of select="."/></field>
				<field name="temporal_date"><xsl:value-of select="."/></field>
			</xsl:for-each>
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
	</xsl:template>

	<!-- rights -->
	<xsl:template name="rights-solr">
		<xsl:for-each select="path:forward('crm:P104_is_subject_to')">
			<field name="rights"><xsl:value-of select="."/></field>
			<field name="rights"><xsl:value-of select="path:forward(., 'rdf:value')"/></field>
		</xsl:for-each>
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

	<!-- parent object - identifiers only (titles would skew keyword searches) -->
	<xsl:template name="object-parent-solr">
		<xsl:variable name="value" select="
			path:forward('ore:isAggregatedBy')[
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
			path:forward('ore:aggregates')[
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
		<xsl:for-each select="path:forward('dc:related')">
			<field name="related_object_id"><xsl:value-of select="replace(., '(.*/)([^/]*)(#)$', '$2')"/></field>
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
		<xsl:if test="$type='narrative' and $value">
			<xsl:for-each select="$value">
				<field name="isPartOf_narrative_id"><xsl:value-of select="replace(., '(.*/)([^/]*)(#)$', '$2')"/></field>
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
				<field name="aggregates_id"><xsl:value-of select="replace(., '(.*/)([^/]*)(#)$', '$2')"/></field>
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
	
</xsl:stylesheet>
