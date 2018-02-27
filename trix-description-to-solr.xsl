<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" 
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:crm="http://www.cidoc-crm.org/cidoc-crm/"
	xmlns="tag:conaltuohy.com,2018:nma/piction/"
	xmlns:dcterms="http://purl.org/dc/terms/"
	xmlns:path="tag:conaltuohy.com,2018:nma/trix-path-traversal"
	xpath-default-namespace="http://www.w3.org/2004/03/trix/trix-1/">
	
	<xsl:param name="root-resource"/><!-- e.g. "http://nma-dev.conaltuohy.com/xproc-z/narrative/1758#" -->
	<xsl:variable name="graph" select="/trix/graph"/>
	
	<xsl:template match="/">
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
				<!--<field name="json-ld"><xsl:apply-templates mode="json-ld"/></field>-->
			</doc>
		</add>
	</xsl:template>
	
	<xsl:function name="path:forward">
		<xsl:param name="path"/><!-- a sequence of URIs of the predicates to follow -->
		<xsl:copy-of select="path:forward($root-resource, $path)"/>
	</xsl:function>
	
	<xsl:function name="path:forward">
		<xsl:param name="from"/><!-- a URI identifying the start of the path to traverse -->
		<xsl:param name="path"/><!-- a sequence of URIs of the predicates to follow -->
		<xsl:variable name="step" select="$path[1]"/><!-- the next predicate to follow -->
		<xsl:variable name="step-result" select="$graph/triple[uri[1]/text()=$from and uri[2]/text()=$path]/*[3]/text()"/><!-- result of following that predicate -->
		<xsl:choose>
			<xsl:when test="count($path) = 1">
				<xsl:copy-of select="$step-result"/>
			</xsl:when>
			<xsl:otherwise>
				<!-- keep going down that path -->
				<xsl:copy-of select="path:forward($step-result, $path[position() &gt; 1])"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<xsl:function name="path:backward">
		<xsl:param name="path"/><!-- a sequence of URIs of the predicates to follow -->
		<xsl:copy-of select="path:backward($root-resource, $path)"/>
	</xsl:function>
	
	<xsl:function name="path:backward">
		<xsl:param name="from"/><!-- a URI identifying the start of the path to traverse -->
		<xsl:param name="path"/><!-- a sequence of URIs of the predicates to follow -->
		<xsl:variable name="step" select="$path[1]"/><!-- the next predicate to follow -->
		<xsl:variable name="step-result" select="$graph/triple[uri[3]/text()=$from and uri[2]/text()=$path]/uri[1]/text()"/><!-- result of following that predicate -->
		<xsl:choose>
			<xsl:when test="count($path) = 1">
				<xsl:copy-of select="$step-result"/>
			</xsl:when>
			<xsl:otherwise>
				<!-- keep going down that path -->
				<xsl:copy-of select="path:backward($step-result, $path[position() &gt; 1])"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>	
</xsl:stylesheet>
