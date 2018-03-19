<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:path="tag:conaltuohy.com,2018:nma/trix-path-traversal"
	xmlns:f="http://www.w3.org/2005/xpath-functions"
	xmlns:map="http://www.w3.org/2005/xpath-functions/map"
	xmlns:trix="http://www.w3.org/2004/03/trix/trix-1/">
	
	<xsl:import href="trix-description-to-json-ld.xsl"/>
	<xsl:import href="compact-json-ld.xsl"/>
	<xsl:import href="trix-traversal-functions.xsl"/>
	
	<xsl:param name="root-resource"/><!-- e.g. "http://nma-dev.conaltuohy.com/xproc-z/narrative/1758#" -->
	<xsl:param name="dataset"/>
	
	<xsl:template match="/">
		<c:request method="post" href="http://localhost:8983/solr/core_nma_{$dataset}/update">
			<c:body content-type="application/xml">
				<add commitWithin="10000">
					<doc>
						<field name="id"><xsl:value-of select="replace($root-resource, '(.*/)([^/]*)(#)$', '$2')"/></field>
						<field name="type"><xsl:value-of select="replace($root-resource, '(.*/)([^/]*)(/.*)$', '$2')"/></field>
						<field name="collection-explorer"><xsl:value-of select="path:forward('http://purl.org/dc/terms/hasFormat')"/></field>
						<field name="title"><xsl:value-of select="path:forward('tag:conaltuohy.com,2018:nma/emu/TitObjectTitle')"/></field>
						<!-- Link goes from images to their EMu objects, so must travel backwards along this predicate from the object to the images -->
						<xsl:variable name="images" select="path:backward('tag:conaltuohy.com,2018:nma/piction/EMu-IRN-for-Related-Objects')"/>
						<xsl:for-each select="path:forward($images, 'tag:conaltuohy.com,2018:nma/piction/web')">
							<field name="web-image"><xsl:value-of select="."/></field>
						</xsl:for-each>
						<xsl:for-each select="
							path:forward(
								(
									'tag:conaltuohy.com,2018:nma/emu/AssPlaceRef_tab.irn',
									'tag:conaltuohy.com,2018:nma/emu/SummaryData'
								)
							)
						">
							<field name="place"><xsl:value-of select="."/></field>
						</xsl:for-each>
						<xsl:for-each select="
							path:forward(
								(
									'tag:conaltuohy.com,2018:nma/emu/ProPersonRef_tab.irn',
									'tag:conaltuohy.com,2018:nma/emu/SummaryData'
								)
							)
						">
							<field name="person"><xsl:value-of select="."/></field>
						</xsl:for-each>
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
					</doc>
				</add>
			</c:body>
		</c:request>
	</xsl:template>
	
</xsl:stylesheet>
