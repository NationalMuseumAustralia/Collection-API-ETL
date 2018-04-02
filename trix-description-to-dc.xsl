<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	version="3.0" xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:path="tag:conaltuohy.com,2018:nma/trix-path-traversal"
	xmlns:f="http://www.w3.org/2005/xpath-functions" xmlns:map="http://www.w3.org/2005/xpath-functions/map"
	xmlns:trix="http://www.w3.org/2004/03/trix/trix-1/">

	<xsl:import href="trix-traversal-functions.xsl" />

	<xsl:param name="root-resource" /><!-- e.g. "http://nma-dev.conaltuohy.com/xproc-z/narrative/1758#" -->
	<xsl:variable name="graph" select="/trix:trix/trix:graph" />
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

			<string key='id'>
				<xsl:value-of select="replace($root-resource, '(.*/)([^/]*)(#)$', '$2')" />
			</string>
			<string key='type'>
				<xsl:value-of select="$type" />
			</string>
			<xsl:for-each select="path:forward( ('crm:P2_has_type','rdfs:label') )">
				<string key="additionalType"><xsl:value-of select="."/></string>
			</xsl:for-each>
			<xsl:for-each select="path:forward('rdfs:label')">
				<string key="title"><xsl:value-of select="."/></string>
				<!-- duplicate organisation name into name field -->
				<xsl:if test="$type='party'">
					<string key="name"><xsl:value-of select="."/></string>
				</xsl:if>
			</xsl:for-each>
			<xsl:for-each select="path:forward( ('crm:P106i_forms_part_of', 'rdf:value') )">
				<string key="collection"><xsl:value-of select="."/></string>
			</xsl:for-each>

			<!-- accession number -->
			<xsl:for-each select="
				path:forward('crm:P1_is_identified_by')[
					path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300312355'
				]
			">
				<string key='identifier'>
					<xsl:value-of select="path:forward(., 'rdf:value')" />
				</string>
			</xsl:for-each>

			<!-- materials -->
			<xsl:variable name="materials"
				select="path:forward( ('crm:P45_consists_of','rdfs:label') )" />
			<xsl:if test="$materials">
				<array key="medium">
					<xsl:for-each select="$materials">
						<string>
							<xsl:value-of select="." />
						</string>
					</xsl:for-each>
				</array>
			</xsl:if>

			<!-- dimensions -->
			<xsl:if test="path:forward('crm:P43_has_dimension')">
				<map key="extent">
						<string key='type'><xsl:text>Measurement</xsl:text></string>
				
						<!-- length -->
						<xsl:for-each select="
							path:forward('crm:P43_has_dimension')[
								path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300055645'
							]
						">
							<string key='length'>
								<xsl:value-of select="path:forward(., 'rdf:value')" />
							</string>
						</xsl:for-each>

						<!-- height -->
						<xsl:for-each select="
							path:forward('crm:P43_has_dimension')[
								path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300055644'
							]
						">
							<string key='height'>
								<xsl:value-of select="path:forward(., 'rdf:value')" />
							</string>
						</xsl:for-each>

						<!-- width -->
						<xsl:for-each select="
							path:forward('crm:P43_has_dimension')[
								path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300055647'
							]
						">
							<string key='width'>
								<xsl:value-of select="path:forward(., 'rdf:value')" />
							</string>
						</xsl:for-each>

						<!-- depth -->
						<xsl:for-each select="
							path:forward('crm:P43_has_dimension')[
								path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300072633'
							]
						">
							<string key='depth'>
								<xsl:value-of select="path:forward(., 'rdf:value')" />
							</string>
						</xsl:for-each>

						<!-- diameter -->
						<xsl:for-each select="
							path:forward('crm:P43_has_dimension')[
								path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300055624'
							]
						">
							<string key='diameter'>
								<xsl:value-of select="path:forward(., 'rdf:value')" />
							</string>
						</xsl:for-each>

						<!-- weight -->
						<xsl:for-each select="
							path:forward('crm:P43_has_dimension')[
								path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300056240'
							]
						">
							<string key='weight'>
								<xsl:value-of select="path:forward(., 'rdf:value')" />
							</string>
						</xsl:for-each>

						<!-- linear units -->
						<xsl:variable name="linearDimensions" select="
							path:forward('crm:P43_has_dimension')[
								path:forward(., 'crm:P2_has_type') != 'http://vocab.getty.edu/aat/300056240'
							]
						" />
						<xsl:if test="$linearDimensions">
							<string key='unitText'>
								<xsl:value-of select="path:forward($linearDimensions[1], ('crm:P91_has_unit', 'rdfs:label'))" />
							</string>
						</xsl:if>
						

						<!-- weight units -->
						<xsl:for-each select="
							path:forward('crm:P43_has_dimension')[
								path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300056240'
							]
						">
							<string key='unitTextWeight'>
								<xsl:value-of select="path:forward(., ('crm:P91_has_unit', 'rdfs:label'))" />
							</string>
						</xsl:for-each>
					</map>
			</xsl:if>
			
			<!-- descriptions -->
			<!-- NB: using contains - there may be multiple crm:P2_has_type, and the term namespace varies depending on the server -->
			<xsl:for-each select="
				path:forward('crm:P129i_is_subject_of')[
					path:forward(., 'crm:P2_has_type') = concat($api-base-uri, '/term/contentDescription')
				]
			">
				<string key='description'>
					<xsl:value-of select="path:forward(., 'rdf:value')" />
				</string>
			</xsl:for-each>
			<xsl:for-each select="
				path:forward('crm:P129i_is_subject_of')[
					path:forward(., 'crm:P2_has_type') = concat($api-base-uri, '/term/physicalDescription')
				]
			">
				<string key='physicalDescription'>
					<xsl:value-of select="path:forward(., 'rdf:value')" />
				</string>
			</xsl:for-each>
			<xsl:for-each select="
				path:forward('crm:P129i_is_subject_of')[
					path:forward(., 'crm:P2_has_type') = concat($api-base-uri, '/term/significanceStatement')
				]
			">
				<string key='significanceStatement'>
					<xsl:value-of select="path:forward(., 'rdf:value')" />
				</string>
			</xsl:for-each>
			<xsl:for-each select="
				path:forward('crm:P129i_is_subject_of')[
					path:forward(., 'crm:P2_has_type') = concat($api-base-uri, '/term/educationalSignificance')
				]
			">
				<string key='educationalSignificance'>
					<xsl:value-of select="path:forward(., 'rdf:value')" />
				</string>
			</xsl:for-each>

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
							<xsl:for-each select="
								path:forward(., ('crm:P14_carried_out_by', 'crm:P1_is_identified_by'))[
									path:forward(., 'rdf:type') = 'https://linked.art/ns/terms/Name'
								]
							">
								<string key='title'>
									<xsl:value-of select="path:forward(., 'rdf:value')" />
								</string>
							</xsl:for-each>
							<!-- organisation label -->
							<xsl:for-each select="path:forward(., ('crm:P14_carried_out_by', 'rdfs:label') )">
								<string key='title'>
									<xsl:value-of select="." />
								</string>
							</xsl:for-each>
							<!-- role -->
							<xsl:for-each select="path:forward(., 'rdfs:label')">
								<string key='roleName'>
									<xsl:value-of select="." />
								</string>
							</xsl:for-each>
							<!-- production flag -->
							<string key='interactionType'><xsl:text>Production</xsl:text></string>
							<!-- description/notes -->
							<xsl:for-each select="path:forward(., ('crm:P129i_is_subject_of', 'rdf:value') )">
								<string key='description'>
									<xsl:value-of select="." />
								</string>
							</xsl:for-each>
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
							<xsl:for-each select="path:forward(., ('crm:P7_took_place_at', 'rdfs:label') )">
								<string key='title'>
									<xsl:value-of select="." />
								</string>
							</xsl:for-each>
							<!-- role -->
							<xsl:for-each select="path:forward(., 'rdfs:label')">
								<string key='roleName'>
									<xsl:value-of select="." />
								</string>
							</xsl:for-each>
							<!-- production flag -->
							<string key='interactionType'><xsl:text>Production</xsl:text></string>
							<!-- description/notes -->
							<xsl:for-each select="path:forward(., ('crm:P129i_is_subject_of', 'rdf:value') )">
								<string key='description'>
									<xsl:value-of select="." />
								</string>
							</xsl:for-each>
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
							<xsl:for-each select="path:forward(., ('crm:P4_has_time-span', 'rdfs:label') )">
								<string key='title'>
									<xsl:value-of select="." />
								</string>
							</xsl:for-each>
							<!-- role -->
							<xsl:for-each select="path:forward(., 'rdfs:label')">
								<string key='roleName'>
									<xsl:value-of select="." />
								</string>
							</xsl:for-each>
							<!-- production flag -->
							<string key='interactionType'><xsl:text>Production</xsl:text></string>
							<!-- description/notes -->
							<xsl:for-each select="path:forward(., ('crm:P129i_is_subject_of', 'rdf:value') )">
								<string key='description'>
									<xsl:value-of select="." />
								</string>
							</xsl:for-each>
						</map>
				</xsl:for-each>
				</array>
			</xsl:if>

			<!-- TODO: all assoc are 'in presence' so dates and places are coming thru, need to add AAT or something into CRM -->

			<!-- associated: party -->
			<xsl:variable name="associated-parties" select="
				path:forward( ('crm:P12i_was_present_at') )[
					path:forward(., 'crm:P12_occurred_in_the_presence_of')
				]
			" />
			<xsl:if test="$associated-parties">
				<array key="contributor">
					<xsl:for-each select="$associated-parties">
						<xsl:variable name="party-iri" select="path:forward(., 'crm:P12_occurred_in_the_presence_of')" />
						<map>
							<string key='id'>
								<xsl:value-of select="replace($party-iri, '(.*/)([^/]*)(#)$', '$2')" />
							</string>
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
							<!-- person name -->
							<xsl:for-each select="
								path:forward(., ('crm:P12_occurred_in_the_presence_of', 'crm:P1_is_identified_by'))[
									path:forward(., 'rdf:type') = 'https://linked.art/ns/terms/Name'
								]
							">
								<string key='title'>
									<xsl:value-of select="path:forward(., 'rdf:value')" />
								</string>
							</xsl:for-each>
							<!-- organisation label -->
							<xsl:for-each select="path:forward(., ('crm:P12_occurred_in_the_presence_of', 'rdfs:label') )">
								<string key='title'>
									<xsl:value-of select="." />
								</string>
							</xsl:for-each>
							<!-- role -->
							<xsl:for-each select="path:forward(., 'rdfs:label')">
								<string key='roleName'>
									<xsl:value-of select="." />
								</string>
							</xsl:for-each>
							<!-- NB: no interactionType as not production -->
							<!-- description/notes -->
							<xsl:for-each select="path:forward(., ('crm:P129i_is_subject_of', 'rdf:value') )">
								<string key='description'>
									<xsl:value-of select="." />
								</string>
							</xsl:for-each>
						</map>
				</xsl:for-each>
				</array>
			</xsl:if>

			<!-- acknowledgement -->
			<xsl:for-each select="
				path:forward('crm:P67i_is_referred_to_by')[
					path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300026687'
				]
			">
				<string key='acknowledgement'>
					<xsl:value-of select="path:forward(., 'rdf:value')" />
				</string>
			</xsl:for-each>

			<!-- rights -->
			<xsl:for-each select="path:forward( ('crm:P104_is_subject_to', 'rdf:value') )">
				<string key="rights"><xsl:value-of select="."/></string>
			</xsl:for-each>

			<!-- TODO: add representation mimetype format, once added to CRM -->

			<!-- representations and their digital media files -->
			<xsl:variable name="representations"
				select="path:forward('crm:P138i_has_representation')" />
			<xsl:if test="$representations">
				<array key="hasVersion">
					<xsl:for-each select="$representations">
						<map>
							<string key='id'>
								<xsl:value-of select="replace(., '(.*/)([^/]*)(#)$', '$2')" />
							</string>
							<string key='type'>
								<xsl:text>StillImage</xsl:text>
							</string>
							<string key='identifier'>
								<xsl:value-of select="." />
							</string>
							<!-- digital media files for this representation -->
							<array key="hasVersion">
								<xsl:for-each select="path:forward(., 'crm:P138i_has_representation')">
								<map>
									<string key='type'>
										<xsl:text>StillImage</xsl:text>
									</string>
									<xsl:for-each select="path:forward(., ('crm:P2_has_type', 'rdfs:label'))">
										<string key='version'><xsl:value-of select="."/></string>
									</xsl:for-each>
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
			<xsl:for-each select="
				path:forward('crm:P1_is_identified_by')[
					path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300404688'
				]
			">
				<string key="name"><xsl:value-of select="path:forward(., 'rdf:value')"/></string>
			</xsl:for-each>

			<!-- first name -->
			<xsl:for-each select="
				path:forward( ('crm:P1_is_identified_by', 'crm:P106_is_composed_of') )[
					path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300404651'
				]
			">
				<string key="givenName"><xsl:value-of select="path:forward(., 'rdf:value')"/></string>
			</xsl:for-each>

			<!-- TODO: add middle name -->

			<!-- last name -->
			<xsl:for-each select="
				path:forward( ('crm:P1_is_identified_by', 'crm:P106_is_composed_of') )[
					path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300404652'
				]
			">
				<string key="familyName"><xsl:value-of select="path:forward(., 'rdf:value')"/></string>
			</xsl:for-each>

			<!-- TODO: add other names -->

			<!-- gender -->
			<xsl:for-each select="
				path:forward('crm:P107i_is_current_or_former_member_of')[
					path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300055147'
				]
			">
				<string key="gender"><xsl:value-of select="path:forward(., 'rdfs:label')"/></string>
			</xsl:for-each>
			
			<!-- PLACE FIELDS -->

			<!-- location -->
			<xsl:for-each select="path:forward( ('crm:P168_place_is_defined_by', 'rdf:value') )">
				<string name="location"><xsl:value-of select="."/></string>
			</xsl:for-each>

		</map>
	</xsl:template>

	<xsl:template name="dc-xml-old">
		<xsl:param name="resource" required="true" />
		<map xmlns="http://www.w3.org/2005/xpath-functions">

			<!-- production: party -->
			<xsl:variable name="production-events"
				select="path:forward( ('crm:P108i_was_produced_by', 'crm:P9_consists_of') )" />
			<xsl:for-each select="path:forward($production-events, 'crm:PC14_carried_out_by')">
				<xsl:variable name="party-id" select="path:forward(., 'crm:P02_has_range')" />
				<contributor>
					<id>
						<xsl:value-of select="replace($party-id, '(.*/)([^/]*)(#)$', '$2')" />
					</id>
					<interactionType>
						<xsl:value-of
							select="path:forward(., ('crm:P14.1_in_the_role_of', 'rdfs:label') )" />
					</interactionType>
				</contributor>
			</xsl:for-each>

			<!-- production: place -->
			<xsl:for-each select="path:forward($production-events, 'crm:P7_took_place_at')">
				<xsl:variable name="place-id" select="." />
				<spatial>
					<id>
						<xsl:value-of select="replace($place-id, '(.*/)([^/]*)(#)$', '$2')" />
					</id>
					<title>
						<xsl:value-of select="path:forward(., 'rdfs:label' )" />
					</title>
					<!-- TODO: fix CRM mapping - should have title in rdfs:label -->
					<interactionType>
						<xsl:value-of select="path:forward(., 'dc:title' )" />
					</interactionType>
				</spatial>
			</xsl:for-each>

			<!-- production: date -->
			<xsl:for-each select="path:forward($production-events, 'crm:P4_has_time-span')">
				<temporal>
					<title>
						<xsl:value-of select="path:forward(., 'rdfs:label' )" />
					</title>
					<!-- TODO: fix CRM mapping - should have title in rdfs:label -->
					<interactionType>
						<xsl:value-of select="path:forward(., 'dc:title' )" />
					</interactionType>
				</temporal>
			</xsl:for-each>

			<!-- production events and activities -->
			<!-- <xsl:variable name="production-events" select="path:forward('crm:P108i_was_produced_by')" 
				/> <xsl:for-each select="path:forward($production-events, 'crm:P9_consists_of')"> 
				<activity-role> <xsl:value-of select="path:forward(., ('crm:PC14_carried_out_by', 
				'crm:P14.1_in_the_role_of', 'rdfs:label'))" /> </activity-role> <activity-party> 
				<xsl:value-of select="path:forward(., ('crm:PC14_carried_out_by', 'crm:P02_has_range'))" 
				/> </activity-party> </xsl:for-each> -->

			<activity-party>
				<xsl:value-of select="path:forward(('crm:P43_has_dimension', 'rdf:value'))" />
			</activity-party>
		</map>

	</xsl:template>

</xsl:stylesheet>
