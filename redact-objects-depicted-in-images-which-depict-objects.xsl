<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" 
	xmlns:path="tag:conaltuohy.com,2018:nma/trix-path-traversal"
	xmlns:trix="http://www.w3.org/2004/03/trix/trix-1/">
	
	<xsl:param name="root-resource"/><!-- e.g. "http://nma-dev.conaltuohy.com/xproc-z/narrative/1758#" -->
	<xsl:param name="debug" select=" 'false' "/><!-- 'true' will log the various redacted triples --> 
	<xsl:import href="util/trix-traversal-functions.xsl"/>
	
	<xsl:variable name="graph" select="/trix:trix/trix:graph" />
	
	<xsl:variable name="aat-ns" select=" 'http://vocab.getty.edu/aat/' "/> 
	<xsl:variable name="rdf-ns" select=" 'http://www.w3.org/1999/02/22-rdf-syntax-ns#' "/> 
	<xsl:variable name="ore-ns" select=" 'http://www.openarchives.org/ore/terms/' "/> 
	<xsl:variable name="dc-ns" select=" 'http://purl.org/dc/terms/' "/> 
	<xsl:variable name="rdfs-ns" select=" 'http://www.w3.org/2000/01/rdf-schema#' "/> 
	<xsl:variable name="crm-ns" select=" 'http://www.cidoc-crm.org/cidoc-crm/' "/>
	<xsl:variable name="nma-term-ns" select="replace($root-resource, '([^/]+//[^/]+).*', '$1/term/')"/>

	<!-- When an object is depicted by a visual item, and the visual item in turn depicts more objects, the depiction of those
	secondary objects should be redacted to avoid combinatorial explosion when a set of objects (e.g. chess pieces) and a set
	of visual items are multiply-linked in a dense cluster -->
	
	<xsl:template match="/">
		<xsl:if test="$debug='true'">
			<xsl:message>redacting secondary depictions...</xsl:message>
		</xsl:if>
		<xsl:call-template name="do-redaction" />
	</xsl:template>
	
	<xsl:key name="depictions-by-media-id"
		match="/trix:trix/trix:graph/trix:triple[*[2]='http://www.cidoc-crm.org/cidoc-crm/P138_represents']"
		use="*[1]"
	/>
	
	<xsl:template name="do-redaction">
		<trix xmlns="http://www.w3.org/2004/03/trix/trix-1/">
			<graph>
				<!-- Find the identifiers of all the physical objects in the graph -->
				<xsl:variable name="objects" select="path:backward(concat($crm-ns, 'E19_Physical_Object'), 'rdf:type')"/>
				<xsl:call-template name="debug-list-values">
					<xsl:with-param name="title">physical objects</xsl:with-param>
					<xsl:with-param name="values" select="$objects"/>
				</xsl:call-template>

				<!-- Find the identifiers of all the media depicting those objects -->
				<xsl:variable name="media" select="path:forward($objects, 'crm:P138i_has_representation')"/>
				<xsl:call-template name="debug-list-values">
					<xsl:with-param name="title">media depicting physical objects</xsl:with-param>
					<xsl:with-param name="values" select="$media"/>
				</xsl:call-template>
				
				<!-- Find the triples in which those media themselves depict further objects -->
				<xsl:variable name="extraneous-depictions" select="key('depictions-by-media-id', $media)"/>
				
				<xsl:call-template name="debug-list-redacted-triples">
					<xsl:with-param name="reason">depictions of secondary objects</xsl:with-param>
					<xsl:with-param name="redaction" select="$extraneous-depictions"/>
				</xsl:call-template>

				<!-- ############################################################################## -->
				<!-- Finally copy the triples of the graph, excluding the triples we've identified as unwanted -->
				<xsl:variable name="published-triples" select="$graph/trix:triple except $extraneous-depictions"/>

				<!-- sort the triples into a stable order, to facilitate checking for changes later in the pipeline -->
				<!-- NB trix:id elements (blank nodes) are not used for sorting since their values are not stable -->
				<xsl:for-each select="$published-triples">
					<xsl:sort select="*[1]/self::trix:uri"/>
					<xsl:sort select="*[2]"/>
					<xsl:sort select="*[3]/self::trix:plainLiteral"/>
					<xsl:sort select="*[3]/self::trix:plainLiteral/@xml:lang"/>
					<xsl:sort select="*[3]/self::trix:typedLiteral"/>
					<xsl:sort select="*[3]/self::trix:typedLiteral/@dataType"/>
					<xsl:copy-of select="."/>
				</xsl:for-each>
				
			</graph>
		</trix>
	</xsl:template>
	
	<xsl:template name="debug-list-redacted-triples">
		<xsl:param name="reason"/>
		<xsl:param name="redaction"/>
		<xsl:if test="($debug = 'true') and $redaction">
			<xsl:message>Redacting: <xsl:value-of select="$reason"/></xsl:message>
			<xsl:for-each select="$redaction">
				<xsl:message><xsl:value-of select="string-join(*, ' ')"/></xsl:message>
			</xsl:for-each>
		</xsl:if>
	</xsl:template>
	
	
	<xsl:template name="debug-list-values">
		<xsl:param name="title"/>
		<xsl:param name="values"/>
		<xsl:if test="($debug = 'true')">
			<xsl:message><xsl:value-of select="$title"/> (n=<xsl:value-of select="count($values)"/>)</xsl:message>
			<xsl:for-each select="$values">
				<xsl:message><xsl:value-of select="."/></xsl:message>
			</xsl:for-each>
		</xsl:if>
	</xsl:template>	
	
</xsl:stylesheet>
