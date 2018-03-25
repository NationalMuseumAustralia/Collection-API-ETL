<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:path="tag:conaltuohy.com,2018:nma/trix-path-traversal"
	xmlns:f="http://www.w3.org/2005/xpath-functions"
	xmlns:map="http://www.w3.org/2005/xpath-functions/map"
	xmlns:trix="http://www.w3.org/2004/03/trix/trix-1/">
	
	<xsl:import href="trix-description-to-json-ld.xsl"/>
	<xsl:import href="trix-description-to-dc.xsl"/>
	<xsl:import href="compact-json-ld.xsl"/>
	<xsl:import href="trix-traversal-functions.xsl"/>
	
	<xsl:param name="root-resource"/><!-- e.g. "http://nma-dev.conaltuohy.com/xproc-z/narrative/1758#" -->
	<xsl:param name="dataset"/>
	
	<xsl:template match="/">
		<c:request method="post" href="http://localhost:8983/solr/core_nma_{$dataset}/update">
			<c:body content-type="application/xml">
				<add commitWithin="10000">
					<doc>
						<!-- id = the last two components of the URI's path, e.g. "object/1234" or "party/5678" -->
						<field name="id"><xsl:value-of select="replace($root-resource, '(.*/)([^/]*/[^/]*)(#)$', '$2')"/></field>
						<xsl:for-each select="path:forward( ('crm:P1_is_identified_by', 'rdf:value') )">
							<field name="identifier"><xsl:value-of select="."/></field>
						</xsl:for-each>

						<!-- type = the second-to-last component of the URI's path, e.g. "object" or "party" -->
						<xsl:variable name="type" select="replace($root-resource, '(.*/)([^/]*)(/.*)$', '$2')"/>
						<field name="type"><xsl:value-of select="$type"/></field>
						<xsl:for-each select="path:forward('rdf:type')">
							<field name="type"><xsl:value-of select="."/></field>
						</xsl:for-each>
						<xsl:for-each select="path:forward( ('crm:P2_has_type', 'rdfs:label') )">
							<field name="type"><xsl:value-of select="."/></field>
						</xsl:for-each>
						<xsl:for-each select="path:forward( ('crm:P106i_forms_part_of', 'rdf:value') )">
							<field name="collection"><xsl:value-of select="."/></field>
						</xsl:for-each>

						<!-- title -->						
						<xsl:for-each select="path:forward('rdfs:label')">
							<field name="title"><xsl:value-of select="."/></field>
						</xsl:for-each>

						<!-- description -->						
						<xsl:for-each select="path:forward( ('crm:P129i_is_subject_of', 'rdf:value') )">
							<field name="description"><xsl:value-of select="."/></field>
						</xsl:for-each>

						<!-- TODO: group activities in the same event by P9_consists_of -->

						<!-- production events and activities -->						
						<xsl:variable name="production-events" select="path:forward('crm:P108i_was_produced_by')"/>
						<xsl:for-each select="path:forward($production-events, 'crm:P9_consists_of')">
							<!-- role -->
							<xsl:for-each select="path:forward(., 'rdfs:label')">
								<field name="activity">
									<xsl:value-of select="."/>
								</field>
							</xsl:for-each>
							<!-- party -->
							<xsl:for-each select="path:forward(., ('crm:P14_carried_out_by', 'rdf:value'))">
								<field name="activity">
									<xsl:value-of select="."/>
								</field>
							</xsl:for-each>
							<!-- date -->
							<xsl:for-each select="path:forward(., ('crm:P4_has_time-span', 'rdfs:label'))">
								<field name="activity">
									<xsl:value-of select="."/>
								</field>
							</xsl:for-each>
						</xsl:for-each>

						<!-- dimension -->
						<xsl:for-each select="path:forward( ('crm:P43_has_dimension', 'rdf:value') )">
							<field name="dimension">
								<xsl:value-of select="."/>
							</field>
						</xsl:for-each>

						<!-- materials -->						
						<xsl:for-each select="path:forward( ('crm:P45_consists_of', 'rdfs:label') )">
							<field name="medium">
								<xsl:value-of select="."/>
							</field>
						</xsl:for-each>

						<!-- rights -->						
						<xsl:for-each select="path:forward( ('crm:P104_is_subject_to', 'rdf:value') )">
							<field name="rights">
								<xsl:value-of select="."/>
							</field>
						</xsl:for-each>

						<!-- TODO: some associations/labels are missing, might be SPARQL query -->
						
						<!-- associations -->						
						<xsl:for-each select="path:forward( ('crm:P12i_was_present_at', 'rdfs:label') )">
							<field name="relation"><xsl:value-of select="."/></field>
						</xsl:for-each>
						<!-- party - person -->
						<xsl:for-each select="path:forward( ('crm:P12i_was_present_at', 'crm:P12_occurred_in_the_presence_of', 'rdf:value') )">
							<field name="relation"><xsl:value-of select="."/></field>
						</xsl:for-each>
						<!-- party - organisation -->
						<xsl:for-each select="path:forward( ('crm:P12i_was_present_at', 'crm:P12_occurred_in_the_presence_of', 'rdfs:label') )">
							<field name="relation"><xsl:value-of select="."/></field>
						</xsl:for-each>

						<!-- representations identifiers only -->
						<xsl:for-each select="path:forward('crm:P138i_has_representation')">
							<field name="media"><xsl:value-of select="."/></field>
						</xsl:for-each>

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
						<!--
						temporarily disabling "simple" serialization for any but "object" records:
						ERROR: xml-to-json: Invalid number: 
						ERROR:     cause: file:/usr/local/NMA-API-ETL/trix-description-to-solr.xsl:79:12:err:FOJS0006:xml-to-json: Invalid number: 
						-->
						<xsl:if test="$type = 'object'">
							<xsl:variable name="dc-in-xml">
								<xsl:call-template name="dc-xml">
									<xsl:with-param name="resource" select="$root-resource"/>
								</xsl:call-template>
							</xsl:variable>
							<field name="simple"><xsl:value-of select="xml-to-json($dc-in-xml, map{'indent':true()})"/></field>
						</xsl:if>
					</doc>
				</add>
			</c:body>
		</c:request>
	</xsl:template>
	
</xsl:stylesheet>
