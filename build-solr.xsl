<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:path="tag:conaltuohy.com,2018:nma/trix-path-traversal"
	xmlns:f="http://www.w3.org/2005/xpath-functions"
	xmlns:map="http://www.w3.org/2005/xpath-functions/map"
	xmlns:trix="http://www.w3.org/2004/03/trix/trix-1/">
	
	<xsl:import href="trix-description-to-json-ld.xsl"/>
	<xsl:import href="trix-description-to-dc.xsl"/>
	<xsl:import href="trix-description-to-dc-v0.xsl"/>
	<xsl:import href="trix-description-to-solr.xsl"/>
	<xsl:import href="util/compact-json-ld.xsl"/>
	
	<xsl:param name="root-resource"/><!-- e.g. "http://nma-dev.conaltuohy.com/xproc-z/narrative/1758#" -->
	<xsl:param name="dataset"/>
	<xsl:param name="hash"/>
	<xsl:param name="datestamp"/>
	<xsl:param name="source-count"/>

	<!-- type = the second-to-last component of the URI's path, e.g. "object" or "party" -->
	<xsl:variable name="type" select="replace($root-resource, '(.*/)([^/]*)(/.*)$', '$2')"/>
	<xsl:variable name="api-base-uri" select="replace($root-resource, '(.*)/.*/[^#]*#.*', '$1')"/>
	
	<xsl:template match="/">
		<xsl:variable name="solr-build-record">
			<xsl:call-template name="solr-record" />
		</xsl:variable>
		<xsl:copy-of select="$solr-build-record" />
	</xsl:template>

	<xsl:template name="solr-record">
		<c:request method="post" href="http://localhost:8983/solr/core_nma_{$dataset}/update" detailed="true">
			<c:body content-type="application/xml">
				<add commitWithin="10000">
					<doc>
						<!-- The hash is used as an identifier for this current version of this record -->
						<field name="hash"><xsl:value-of select="$hash"/></field>
						<field name="datestamp"><xsl:value-of select="$datestamp"/></field>
						<field name="source_count"><xsl:value-of select="$source-count"/></field>
						
						<!-- Solr index fields -->
						<xsl:variable name="solr-in-xml">
							<xsl:call-template name="solr-xml">
								<xsl:with-param name="resource" select="$root-resource"/>
							</xsl:call-template>
						</xsl:variable>
						<xsl:copy-of select="$solr-in-xml"/>

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

						<!-- Simplified DC blob - current -->
						<xsl:variable name="dc-in-xml">
							<xsl:call-template name="dc-xml">
								<xsl:with-param name="resource" select="$root-resource"/>
							</xsl:call-template>
						</xsl:variable>
						<field name="simple">
							<xsl:copy-of select="$dc-in-xml"/>
						</field>

						<!-- Simplified DC blob - v0 -->
						<xsl:variable name="dc-in-xml-v0">
							<xsl:call-template name="dc-xml-v0">
								<xsl:with-param name="resource" select="$root-resource"/>
							</xsl:call-template>
						</xsl:variable>
						<field name="simple-v0">
							<xsl:copy-of select="$dc-in-xml-v0"/>
						</field>
					</doc>
				</add>
			</c:body>
		</c:request>
	</xsl:template>

</xsl:stylesheet>
