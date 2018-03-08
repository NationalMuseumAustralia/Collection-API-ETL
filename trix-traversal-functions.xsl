<!-- 
Function library for traversing an RDF graph expressed in TriX, in a manner similar to simply SPARQL property paths
-->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:path="tag:conaltuohy.com,2018:nma/trix-path-traversal"
	xmlns:f="http://www.w3.org/2005/xpath-functions"
	xmlns:map="http://www.w3.org/2005/xpath-functions/map"
	xmlns:trix="http://www.w3.org/2004/03/trix/trix-1/">
	
	<xsl:function name="path:forward">
		<xsl:param name="path"/><!-- a sequence of URIs of the predicates to follow -->
		<xsl:copy-of select="path:forward($root-resource, $path)"/>
	</xsl:function>
	
	<xsl:function name="path:forward">
		<xsl:param name="from"/><!-- a URI identifying the start of the path to traverse -->
		<xsl:param name="path"/><!-- a sequence of URIs of the predicates to follow -->
		<xsl:variable name="step" select="$path[1]"/><!-- the next predicate to follow -->
		<xsl:variable name="step-result" select="$graph/trix:triple[trix:uri[1]/text()=$from and trix:uri[2]/text()=$path]/*[3]/text()"/><!-- result of following that predicate -->
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
		<xsl:variable name="step-result" select="$graph/trix:triple[uri[3]/text()=$from and trix:uri[2]/text()=$path]/trix:uri[1]/text()"/><!-- result of following that predicate -->
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