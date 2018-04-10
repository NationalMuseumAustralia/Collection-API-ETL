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
	
	<xsl:template match="/">
		<c:request method="post" href="http://localhost:8983/solr/core_nma_{$dataset}/update" detailed="true">
			<c:body content-type="application/xml">
				<add commitWithin="10000">
					<doc>
						<!-- TODO: remove text fields and use copyField in the Solr schema -->

						<!-- COMMON FIELDS -->
						<xsl:call-template name="id-solr" />
						<xsl:call-template name="type-solr" />
						<xsl:call-template name="additional-type-solr" />
						<xsl:call-template name="title-solr" />

						<!-- OBJECT FIELDS -->
						<xsl:call-template name="collection-solr" />
						<xsl:call-template name="accession-number-solr" />
						<xsl:call-template name="materials-solr" />
						<xsl:call-template name="dimensions-solr" />
						<xsl:call-template name="content-description-solr" />
						<xsl:call-template name="physical-description-solr" />
						<xsl:call-template name="significance-statement-solr" />
						<xsl:call-template name="educational-significance-solr" />
						<xsl:call-template name="production-events-solr" />
						<xsl:call-template name="production-parties-solr" />
						<xsl:call-template name="production-places-solr" />
						<xsl:call-template name="production-dates-solr" />
						<xsl:call-template name="associated-roles-solr" />
						<xsl:call-template name="associated-parties-solr" />
						<xsl:call-template name="associated-places-solr" />
						<xsl:call-template name="associated-dates-solr" />
						<xsl:call-template name="acknowledgement-solr" />
						<xsl:call-template name="rights-solr" />
						<xsl:call-template name="representations-solr" />

						<!-- PARTY FIELDS -->
						<xsl:call-template name="full-name-solr" />
						<xsl:call-template name="first-name-solr" />
						<!-- TODO: add middle name -->
						<xsl:call-template name="last-name-solr" />
						<!-- TODO: add other names -->
						<xsl:call-template name="gender-solr" />

						<!-- PLACE FIELDS -->
						<xsl:call-template name="location-solr" />
					
						<!-- Linked Art JSON-LD blob -->
						<xsl:variable name="json-ld-in-xml">
							<xsl:call-template name="resource-as-json-ld-xml">
								<xsl:with-param name="resource" select="$root-resource"/>
								<xsl:with-param name="context" select=" 'https://linked.art/ns/v1/linked-art.json' "/>
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
		<xsl:for-each select="path:forward( ('crm:P2_has_type', 'rdfs:label') )">
			<field name="type"><xsl:value-of select="."/></field>
			<field name="text"><xsl:value-of select="."/></field>
		</xsl:for-each>
	</xsl:template>

	<!-- additional type -->
	<xsl:template name="additional-type-solr">
	</xsl:template>

	<!-- title -->
	<xsl:template name="title-solr">
		<xsl:for-each select="path:forward('rdfs:label')">
			<field name="title">
				<xsl:value-of select="." />
			</field>
			<field name="text">
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
	
	<!-- OBJECT FIELDS -->

	<!-- collection -->
	<xsl:template name="collection-solr">
		<xsl:for-each select="path:forward( ('crm:P106i_forms_part_of', 'rdf:value') )">
			<field name="collection"><xsl:value-of select="."/></field>
				<field name="text"><xsl:value-of select="."/></field>
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
			<field name="text"><xsl:value-of select="path:forward(., 'rdf:value')"/></field>
		</xsl:for-each>
	</xsl:template>	

	<!-- materials -->
	<xsl:template name="materials-solr">
		<xsl:for-each select="path:forward( ('crm:P45_consists_of', 'rdfs:label') )">
			<field name="medium"><xsl:value-of select="."/></field>
			<field name="text"><xsl:value-of select="."/></field>
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
		<xsl:for-each select="path:forward( ('crm:P129i_is_subject_of', 'rdf:value') )">
			<field name="description"><xsl:value-of select="."/></field>
			<field name="text"><xsl:value-of select="."/></field>
		</xsl:for-each>
	</xsl:template>

	<!-- physical description -->
	<xsl:template name="physical-description-solr">
	</xsl:template>

	<!-- significance statement -->
	<xsl:template name="significance-statement-solr">
	</xsl:template>

	<!-- educational significance -->
	<xsl:template name="educational-significance-solr">
	</xsl:template>

	<!-- production parties -->
	<xsl:template name="production-parties-solr">
	</xsl:template>

	<!-- production events -->
	<xsl:template name="production-events-solr">
		<xsl:variable name="value" select="path:forward('crm:P108i_was_produced_by')"/>
		<xsl:for-each select="path:forward($value, 'crm:P9_consists_of')">
			<!-- role: party person name -->
			<xsl:for-each select="
				path:forward(., ('crm:P14_carried_out_by', 'crm:P1_is_identified_by'))[
					path:forward(., 'rdf:type') = 'https://linked.art/ns/terms/Name'
				]
				/path:forward(., 'rdf:value')
			">
				<field name="creator"><xsl:value-of select="."/></field>
				<field name="text"><xsl:value-of select="."/></field>
			</xsl:for-each>
			<!-- role: party organisation label -->
			<xsl:for-each select="path:forward(., ('crm:P14_carried_out_by', 'rdfs:label') )">
				<field name="creator"><xsl:value-of select="."/></field>
				<field name="text"><xsl:value-of select="."/></field>
			</xsl:for-each>
			<!-- role: date -->
			<xsl:for-each select="path:forward(.[path:forward(., 'crm:P4_has_time-span')], 'rdfs:label')">
				<field name="temporal"><xsl:value-of select="."/></field>
				<field name="text"><xsl:value-of select="."/></field>
			</xsl:for-each>
			<!-- role: place -->
			<xsl:for-each select="path:forward(.[path:forward(., 'crm:P7_took_place_at')], 'rdfs:label')">
				<field name="spatial"><xsl:value-of select="."/></field>
				<field name="text"><xsl:value-of select="."/></field>
			</xsl:for-each>
			<!-- party -->
			<xsl:for-each select="path:forward(., ('crm:P14_carried_out_by', 'rdf:value'))">
				<field name="creator"><xsl:value-of select="."/></field>
				<field name="text"><xsl:value-of select="."/></field>
			</xsl:for-each>
			<!-- date -->
			<xsl:for-each select="path:forward(., ('crm:P4_has_time-span', 'rdfs:label'))">
				<field name="temporal"><xsl:value-of select="."/></field>
				<field name="text"><xsl:value-of select="."/></field>
			</xsl:for-each>
			<!-- place -->
			<xsl:for-each select="path:forward(., ('crm:P7_took_place_at', 'rdfs:label'))">
				<field name="spatial"><xsl:value-of select="."/></field>
				<field name="text"><xsl:value-of select="."/></field>
			</xsl:for-each>
		</xsl:for-each>
	</xsl:template>

	<!-- production places -->
	<xsl:template name="production-places-solr">
	</xsl:template>
	
	<!-- production dates -->
	<xsl:template name="production-dates-solr">
	</xsl:template>

	<!-- TODO: group activities in the same event by P9_consists_of -->
	<!-- TODO: date/place should go to spatial/temporal, not contributor -->
	
	<!-- associated roles -->
	<xsl:template name="associated-roles-solr">
						<xsl:for-each select="path:forward( ('crm:P12i_was_present_at', 'rdfs:label') )">
							<field name="contributor"><xsl:value-of select="."/></field>
							<field name="text"><xsl:value-of select="."/></field>
						</xsl:for-each>
	</xsl:template>
	
	<!-- associated parties -->
	<!-- NB: organisations have a title (not an la:Name), so are picked up by associated places -->
	<xsl:template name="associated-parties-solr">
		<xsl:for-each select="
			path:forward( ('crm:P12i_was_present_at', 'crm:P12_occurred_in_the_presence_of', 'crm:P1_is_identified_by'))[
				path:forward(., 'rdf:type') = 'https://linked.art/ns/terms/Name'
			]
			/path:forward(., 'rdf:value')
		">
			<field name="contributor"><xsl:value-of select="."/></field>
			<field name="text"><xsl:value-of select="."/></field>
		</xsl:for-each>
	</xsl:template>

	<!-- associated places (incl. associated organisations) -->
	<xsl:template name="associated-places-solr">
		<xsl:for-each select="path:forward( ('crm:P12i_was_present_at', 'crm:P12_occurred_in_the_presence_of', 'rdfs:label') )">
			<field name="contributor"><xsl:value-of select="."/></field>
			<field name="text"><xsl:value-of select="."/></field>
		</xsl:for-each>
	</xsl:template>
	
	<!-- associated dates -->
	<xsl:template name="associated-dates-solr">
		<xsl:for-each select="path:forward( ('crm:P12i_was_present_at', 'crm:P4_has_time-span', 'rdfs:label') )">
			<field name="contributor"><xsl:value-of select="."/></field>
			<field name="text"><xsl:value-of select="."/></field>
		</xsl:for-each>
	</xsl:template>
	
	<!-- acknowledgement -->
	<xsl:template name="acknowledgement-solr">
	</xsl:template>

	<!-- rights -->
	<xsl:template name="rights-solr">
		<xsl:for-each select="path:forward( ('crm:P104_is_subject_to', 'rdf:value') )">
			<field name="rights"><xsl:value-of select="."/></field>
		</xsl:for-each>
	</xsl:template>
	
	<!-- representations - identifiers only -->
	<xsl:template name="representations-solr">
		<xsl:for-each select="path:forward('crm:P138i_has_representation')">
			<field name="media"><xsl:value-of select="."/></field>
		</xsl:for-each>
	</xsl:template>

	<!-- PARTY FIELDS -->
	
	<!-- full name -->
	<xsl:template name="full-name-solr">
		<xsl:for-each select="
			path:forward('crm:P1_is_identified_by')[
			path:forward(., 'crm:P2_has_type') = 'http://vocab.getty.edu/aat/300404688'
		]
		">
		<field name="name"><xsl:value-of select="path:forward(., 'rdf:value')"/></field>
			<field name="text"><xsl:value-of select="path:forward(., 'rdf:value')"/></field>
		</xsl:for-each>
	</xsl:template>
	
	<!-- first name -->
	<xsl:template name="first-name-solr">
	</xsl:template>
	
	<!-- last name -->
	<xsl:template name="last-name-solr">
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
			<field name="location"><xsl:value-of select="."/></field>
		</xsl:for-each>
	</xsl:template>
	
</xsl:stylesheet>
