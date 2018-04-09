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
	xmlns:trix="http://www.w3.org/2004/03/trix/trix-1/">

	<xsl:import href="util/trix-traversal-functions.xsl" />
	<xsl:import href="util/xmljson-functions.xsl" />
	<xsl:import href="util/date-util-functions.xsl" />

	<xsl:param name="root-resource" /><!-- e.g. "http://nma-dev.conaltuohy.com/xproc-z/narrative/1758#" -->
	<xsl:variable name="api-base-uri" select="replace($root-resource, '(.*)/.*/[^#]*#.*', '$1')"/>

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
		<map xmlns="http://www.w3.org/2005/xpath-functions">
			<!-- type = the second-to-last component of the URI's path, e.g. "object" or "party" -->
			<xsl:variable name="type" select="replace($root-resource, '(.*/)([^/]*)(/.*)$', '$2')"/>

			<xsl:copy-of select="xmljson:render-as-string('id', replace($root-resource, '(.*/)([^/]*)(#)$', '$2'))" />
			<xsl:copy-of select="xmljson:render-as-string('type', $type)" />
			<xsl:copy-of select="xmljson:render-as-string('additionalType', path:forward( ('crm:P2_has_type','rdfs:label') ))" />
			<xsl:call-template name="title" />
			<!-- duplicate organisation name into name field -->
			<xsl:if test="$type='party'">
				<xsl:copy-of select="xmljson:render-as-string('name', path:forward('rdfs:label'))" />
			</xsl:if>
			<xsl:copy-of select="xmljson:render-as-string('collection', path:forward( ('crm:P106i_forms_part_of', 'rdf:value') ))" />

			<xsl:call-template name="accession-number" />

			<!-- materials (array of strings) -->
			<xsl:variable name="materials"
				select="path:forward( ('crm:P45_consists_of','rdfs:label') )" />
			<xsl:if test="$materials">
				<array key="medium">
					<xsl:for-each select="$materials">
						<!-- NB: no JSON string labels -->
						<xsl:copy-of select="xmljson:render-as-string('', .)" />
					</xsl:for-each>
				</array>
			</xsl:if>

			<!-- dimensions -->
			<xsl:if test="path:forward('crm:P43_has_dimension')">
				<map key="extent">
						<string key='type'><xsl:text>Measurement</xsl:text></string>
				
						<!-- length -->
						<xsl:copy-of select="xmljson:render-as-string('length', 
							path:forward('crm:P43_has_dimension')[
								path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300055645'
							]
							/path:forward(., 'rdf:value')
						)" />

						<!-- height -->
						<xsl:copy-of select="xmljson:render-as-string('height', 
							path:forward('crm:P43_has_dimension')[
								path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300055644'
							]
							/path:forward(., 'rdf:value')
						)" />

						<!-- width -->
						<xsl:copy-of select="xmljson:render-as-string('width', 
							path:forward('crm:P43_has_dimension')[
								path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300055647'
							]
							/path:forward(., 'rdf:value')
						)" />

						<!-- depth -->
						<xsl:copy-of select="xmljson:render-as-string('depth', 
							path:forward('crm:P43_has_dimension')[
								path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300072633'
							]
							/path:forward(., 'rdf:value')
						)" />

						<!-- diameter -->
						<xsl:copy-of select="xmljson:render-as-string('diameter', 
							path:forward('crm:P43_has_dimension')[
								path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300055624'
							]
							/path:forward(., 'rdf:value')
						)" />

						<!-- weight -->
						<xsl:copy-of select="xmljson:render-as-string('weight', 
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
			
			<!-- descriptions -->
			<!-- NB: term namespace varies depending on the server -->
			<xsl:copy-of select="xmljson:render-as-string('description', 
				path:forward('crm:P129i_is_subject_of')[
					path:forward(., 'crm:P2_has_type') = concat($api-base-uri, '/term/contentDescription')
				]
				/path:forward(., 'rdf:value')
			)" />
			<xsl:copy-of select="xmljson:render-as-string('physicalDescription', 
				path:forward('crm:P129i_is_subject_of')[
					path:forward(., 'crm:P2_has_type') = concat($api-base-uri, '/term/physicalDescription')
				]
				/path:forward(., 'rdf:value')
			)" />
			<xsl:copy-of select="xmljson:render-as-string('significanceStatement', 
				path:forward('crm:P129i_is_subject_of')[
					path:forward(., 'crm:P2_has_type') = concat($api-base-uri, '/term/significanceStatement')
				]
				/path:forward(., 'rdf:value')
			)" />
			<xsl:copy-of select="xmljson:render-as-string('educationalSignificance', 
				path:forward('crm:P129i_is_subject_of')[
					path:forward(., 'crm:P2_has_type') = concat($api-base-uri, '/term/educationalSignificance')
				]
				/path:forward(., 'rdf:value')
			)" />

			<!-- production: party -->
			<xsl:variable name="production-parties" select="
				path:forward( ('crm:P108i_was_produced_by', 'crm:P9_consists_of') )[
					path:forward(., 'crm:P14_carried_out_by')
				]
			" />
			<xsl:if test="$production-parties">
				<array key="creator">
					<xsl:for-each select="$production-parties">
						<xsl:variable name="party-id" select="path:forward(., 'crm:P14_carried_out_by')" />
						<xsl:variable name="party-iri" select="$party-id/self::trix:uri"/>
						<map>
							<xsl:if test="$party-id">
								<string key='id'>
									<xsl:value-of select="replace($party-id, '(.*/)([^/]*)(#)$', '$2')" />
								</string>
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

			<!-- production: place -->
			<xsl:variable name="production-places" select="
				path:forward( ('crm:P108i_was_produced_by', 'crm:P9_consists_of') )[
					path:forward(., 'crm:P7_took_place_at')
				]
			" />
			<xsl:if test="$production-places">
				<array key="spatial">
					<xsl:for-each select="$production-places">
						<xsl:variable name="place-iri" select="path:forward(., 'crm:P7_took_place_at')" />
						<map>
							<string key='id'>
								<xsl:value-of select="replace($place-iri, '(.*/)([^/]*)(#)$', '$2')" />
							</string>
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
						</map>
				</xsl:for-each>
				</array>
			</xsl:if>

			<!-- production: date -->
			<xsl:variable name="production-dates" select="
				path:forward( ('crm:P108i_was_produced_by', 'crm:P9_consists_of') )[
					path:forward(., 'crm:P4_has_time-span')
				]
			" />
			<xsl:if test="$production-dates">
				<array key="temporal">
					<xsl:for-each select="$production-dates">
						<map>
							<!-- type -->
							<string key='type'><xsl:text>Event</xsl:text></string>
							<!-- date value -->
							<xsl:copy-of select="xmljson:render-as-string('title', path:forward(., ('crm:P4_has_time-span', 'rdfs:label') ) )" />
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

			<!-- TODO: all assoc are 'in presence' so dates and places are coming thru, need to add AAT or something into CRM -->

			<!-- associated: party -->
			<xsl:variable name="associated-parties" select="
				path:forward( ('crm:P12i_was_present_at') )
			" />
			<xsl:if test="$associated-parties">
				<array key="contributor">
					<xsl:for-each select="$associated-parties">
						<xsl:variable name="party-iri" select="path:forward(., 'crm:P12_occurred_in_the_presence_of')" />
						<map>
							<xsl:if test="$party-iri">
								<string key='id'>
									<xsl:value-of select="replace($party-iri, '(.*/)([^/]*)(#)$', '$2')" />
								</string>
							</xsl:if>
							<!-- type -->
							<xsl:variable name="party-type" select="path:forward(., ('crm:P12_occurred_in_the_presence_of', 'rdf:type') )" />
							<xsl:if test="$party-type='http://www.cidoc-crm.org/cidoc-crm/E21_Person'">
								<string key='type'><xsl:text>Person</xsl:text></string>
							</xsl:if>
							<xsl:if test="$party-type='http://www.cidoc-crm.org/cidoc-crm/E74_Group'">
								<string key='type'><xsl:text>Organisation</xsl:text></string>
							</xsl:if>
							<xsl:if test="$party-type='http://www.cidoc-crm.org/cidoc-crm/E53_Place'">
								<string key='type'><xsl:text>Place</xsl:text></string>
							</xsl:if>
							<xsl:if test="$party-type='http://www.cidoc-crm.org/cidoc-crm/E5_Event'">
								<string key='type'><xsl:text>Event</xsl:text></string>
							</xsl:if>
							<xsl:variable name="date-type" select="path:forward(., ('crm:P4_has_time-span', 'rdf:type') )" />
							<xsl:if test="$date-type='http://www.cidoc-crm.org/cidoc-crm/E52_Time-Span'">
								<string key='type'><xsl:text>Event</xsl:text></string>
							</xsl:if>
							<!-- person name -->
							<xsl:copy-of select="xmljson:render-as-string('title', 
								path:forward(., ('crm:P12_occurred_in_the_presence_of', 'crm:P1_is_identified_by'))[
									path:forward(., 'rdf:type') = 'https://linked.art/ns/terms/Name'
								]
								/path:forward(., 'rdf:value')
							)" />
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

			<!-- acknowledgement -->
			<xsl:copy-of select="xmljson:render-as-string('acknowledgement', 
				path:forward('crm:P67i_is_referred_to_by')[
					path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300026687'
				]
				/path:forward(., 'rdf:value')
			)" />

			<!-- rights -->
			<xsl:copy-of select="xmljson:render-as-string('rights', path:forward( ('crm:P104_is_subject_to', 'rdf:value') ))" />

			<!-- TODO: add representation mimetype format, once added to CRM -->

			<!-- representations and their digital media files -->
			<xsl:variable name="representations"
				select="path:forward('crm:P138i_has_representation')" />
			<xsl:if test="$representations">
				<array key="hasVersion">
					<xsl:for-each select="$representations">
						<map>
							<xsl:copy-of select="xmljson:render-as-string('id', replace(., '(.*/)([^/]*)(#)$', '$2'))" />
							<string key='type'>
								<xsl:text>StillImage</xsl:text>
							</string>
							<xsl:copy-of select="xmljson:render-as-string('identifier', .)" />
							<!-- digital media files for this representation -->
							<array key="hasVersion">
								<xsl:for-each select="path:forward(., 'crm:P138i_has_representation')">
								<map>
									<string key='type'>
										<xsl:text>StillImage</xsl:text>
									</string>
									<xsl:copy-of select="xmljson:render-as-string('version', path:forward(., ('crm:P2_has_type', 'rdfs:label')))" />
									<string key='identifier'>
										<xsl:value-of select="." />
										<xsl:value-of select="path:forward(., 'rdf:value')" />
									</string>
									<!-- 
									<xsl:for-each select="path:forward(., 'crm:P43_has_dimension')">
										<string key='dimension'>
											<xsl:value-of select="path:forward(., 'rdf:value')" />
										</string>
									</xsl:for-each>
									 -->
								</map>
								</xsl:for-each>
							</array>
						</map>
					</xsl:for-each>
				</array>
			</xsl:if>
			
			<!-- PARTY FIELDS -->

			<!-- full name -->
			<xsl:copy-of select="xmljson:render-as-string('name', 
				path:forward('crm:P1_is_identified_by')[
					path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300404688'
				]
				/path:forward(., 'rdf:value')
			)" />

			<!-- first name -->
			<xsl:copy-of select="xmljson:render-as-string('givenName', 
				path:forward( ('crm:P1_is_identified_by', 'crm:P106_is_composed_of') )[
					path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300404651'
				]
				/path:forward(., 'rdf:value')
			)" />

			<!-- TODO: add middle name -->

			<!-- last name -->
			<xsl:copy-of select="xmljson:render-as-string('familyName', 
				path:forward( ('crm:P1_is_identified_by', 'crm:P106_is_composed_of') )[
					path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300404652'
				]
				/path:forward(., 'rdf:value')
			)" />

			<!-- TODO: add other names -->

			<!-- gender -->
			<xsl:copy-of select="xmljson:render-as-string('gender', 
				path:forward('crm:P107i_is_current_or_former_member_of')[
					path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300055147'
				]
				/path:forward(., 'rdfs:label')
			)" />
			
			<!-- PLACE FIELDS -->

			<!-- location -->
			<xsl:copy-of select="xmljson:render-as-string('location', path:forward( ('crm:P168_place_is_defined_by', 'rdf:value') ))" />

		</map>
	</xsl:template>
	
	<!-- ############### FIELD PROCESSING TEMPLATES ############ -->

	<!-- COMMON -->

	<!-- OBJECT -->

	<!-- title -->
	<xsl:template name="title">
		<xsl:copy-of select="xmljson:render-as-string('title', path:forward('rdfs:label'))" />
	</xsl:template>
	
	<!-- accession number -->
	<xsl:template name="accession-number">
		<!-- accession number -->
		<xsl:copy-of select="xmljson:render-as-string('identifier', 
			path:forward('crm:P1_is_identified_by')[
				path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300312355'
			]
			/path:forward(., 'rdf:value'))" />
	</xsl:template>	

</xsl:stylesheet>
