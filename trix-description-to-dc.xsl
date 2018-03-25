<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	version="3.0" xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:path="tag:conaltuohy.com,2018:nma/trix-path-traversal"
	xmlns:f="http://www.w3.org/2005/xpath-functions" xmlns:map="http://www.w3.org/2005/xpath-functions/map"
	xmlns:trix="http://www.w3.org/2004/03/trix/trix-1/">

	<xsl:import href="trix-traversal-functions.xsl" />

	<xsl:param name="root-resource" /><!-- e.g. "http://nma-dev.conaltuohy.com/xproc-z/narrative/1758#" -->
	<xsl:variable name="graph" select="/trix:trix/trix:graph" />

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
			<number key='id'>
				<xsl:value-of select="replace($root-resource, '(.*/)([^/]*)(#)$', '$2')" />
			</number>
			<string key='type'>
				<xsl:value-of select="replace($root-resource, '(.*/)([^/]*)(/.*)$', '$2')" />
			</string>
			<string key='additionalType'>
				<xsl:value-of select="path:forward( ('crm:P2_has_type','rdfs:label') )" />
			</string>
			<string key='title'>
				<xsl:value-of select="path:forward('rdfs:label')" />
			</string>
			<string key='isAggregatedBy'>
				<xsl:value-of select="path:forward( ('crm:P106i_forms_part_of', 'rdf:value') )" />
			</string>

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

			<!-- descriptions -->
			<xsl:for-each select="path:forward('crm:P129i_is_subject_of')">
				<xsl:variable name="subject-iri" select="." />
				<xsl:if test="contains($subject-iri, 'contentDescription')">
					<string key='description'>
						<xsl:value-of select="path:forward($subject-iri, 'rdf:value')" />
					</string>
				</xsl:if>
				<xsl:if test="contains($subject-iri, 'physicalDescription')">
					<string key='physicalDescription'>
						<xsl:value-of select="path:forward($subject-iri, 'rdf:value')" />
					</string>
				</xsl:if>
				<xsl:if test="contains($subject-iri, 'significanceStatement')">
					<string key='significanceStatement'>
						<xsl:value-of select="path:forward($subject-iri, 'rdf:value')" />
					</string>
				</xsl:if>
				<xsl:if test="contains($subject-iri, 'educationalSignificance')">
					<string key='educationalSignificance'>
						<xsl:value-of select="path:forward($subject-iri, 'rdf:value')" />
					</string>
				</xsl:if>
			</xsl:for-each>

			<!-- representations and their digital media files -->
			<xsl:variable name="representations"
				select="path:forward('crm:P138i_has_representation')" />
			<xsl:if test="$representations">
				<array key="hasVersion">
					<xsl:for-each select="$representations">
						<map>
							<string key='identifier'>
								<xsl:value-of select="." />
							</string>
							<array key="hasVersion">
								<xsl:for-each select="path:forward(., 'crm:P138i_has_representation')">
								<map>
									<string key='identifier'>
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
