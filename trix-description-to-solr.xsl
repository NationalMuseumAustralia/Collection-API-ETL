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
						<!-- type = the second-to-last component of the URI's path, e.g. "object" or "party" -->
						<xsl:variable name="type " select="replace($root-resource, '(.*/)([^/]*)(/.*)$', '$2')"/>
						<field name="type"><xsl:value-of select="$type"/></field>
						<field name="type2"><xsl:value-of select="path:forward('rdf:type')"/></field>
						<field name="collection"><xsl:value-of select="path:forward( ('crm:P106i_forms_part_of', 'rdf:value') )"/></field>
						
						<field name="title"><xsl:value-of select="path:forward('rdfs:label')"/></field>

						<!-- representations and their digital media files -->
						<xsl:variable name="representations" select="path:forward('crm:P138i_has_representation')"/>
						<field name="representations"><xsl:value-of select="$representations"/></field>
						<xsl:for-each select="path:forward($representations, 'crm:P138i_has_representation')">
							<field name="web-media">
								<xsl:value-of select="."/>
							</field>
							<field name="web-media-url">
								<xsl:value-of select="path:forward(., 'rdf:value')"/>
							</field>
							<field name="web-media-dimension">
								<xsl:for-each select="path:forward(., 'crm:P43_has_dimension')">
									<xsl:value-of select="path:forward(., 'rdf:value')"/>
									<xsl:text> </xsl:text>
								</xsl:for-each>
							</field>
						</xsl:for-each>

						<!-- production events and activities -->						
						<xsl:variable name="production-events" select="path:forward('crm:P108i_was_produced_by')"/>
						<xsl:for-each select="path:forward($production-events, 'crm:P9_consists_of')">
							<field name="activity-role">
								<xsl:value-of select="path:forward(., ('crm:PC14_carried_out_by', 'crm:P14.1_in_the_role_of', 'rdfs:label'))"/>
							</field>
							<field name="activity-party">
								<xsl:value-of select="path:forward(., ('crm:PC14_carried_out_by', 'crm:P02_has_range'))"/>
							</field>
						</xsl:for-each>
						
						<field name="dimension"><xsl:value-of select="path:forward(('crm:P43_has_dimension', 'rdf:value'))"/></field>

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
