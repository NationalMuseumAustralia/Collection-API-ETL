<!-- 
Function library for traversing an RDF graph expressed in TriX, in a manner similar to simply SPARQL property paths
-->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:path="tag:conaltuohy.com,2018:nma/trix-path-traversal"
	xmlns:f="http://www.w3.org/2005/xpath-functions"
	xmlns:map="http://www.w3.org/2005/xpath-functions/map"
	xmlns:trix="http://www.w3.org/2004/03/trix/trix-1/">

	<xsl:variable name="graph" select="/trix:trix/trix:graph" />
	
	<xsl:function name="path:forward">
		<xsl:param name="path"/><!-- a sequence of URIs of the predicates to follow -->
		<xsl:copy-of select="path:forward($root-resource, $path)"/>
	</xsl:function>

	<!-- Traverses trix triples, starting from the specified 'from' IRI, and following 
		the specified 'path' sequence of IRI predicates forwards. Returns the value at the 
		end of traversing the specified path. -->
	<!-- Single layer blank nodes and wildcard nodes are automatically traversed over 
		so do not include them in the path, e.g. path 'A,Z' will traverse over both A-B-Z 
		and A-C-Z, but not A-M-N-Z. -->
	<xsl:function name="path:forward">
		<xsl:param name="from"/><!-- a URI identifying the start of the path to traverse -->
		<xsl:param name="path"/><!-- a sequence of URIs of the predicates to follow -->
		<xsl:variable name="step" select="path:expandNamespace($path[1])"/><!-- the next predicate to follow -->
		<!-- result of following that predicate: -->
		<xsl:variable name="step-result" select="
			key('object-by-subject-and-predicate', for $subject in $from return concat($subject, ' ', $step), $graph)
		"/>
		<!--
		<xsl:variable name="step-result" select="$graph/trix:triple[trix:*[1]/text()=$from and trix:*[2]/text()=$step]/*[3]/text()"/>
		-->
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
	
	<!-- index subjects by object and predicate (only where the object is an identifier of some sort) -->
	<xsl:key name="subject-by-object-and-predicate" match="trix:triple[*[3]/self::trix:uri | *[3]/self::trix:id]/*[1]" use="concat(../*[3], ' ', ../*[2])"/>
	<!-- index objects by subject and predicate -->
	<xsl:key name="object-by-subject-and-predicate" match="trix:triple/*[3]" use="concat(../*[1], ' ', ../*[2])"/>
	
	<xsl:function name="path:backward">
		<xsl:param name="path"/><!-- a sequence of URIs of the predicates to follow -->
		<xsl:copy-of select="path:backward($root-resource, $path)"/>
	</xsl:function>
	
	<xsl:function name="path:backward">
		<xsl:param name="from"/><!-- a URI identifying the start of the path to traverse -->
		<xsl:param name="path"/><!-- a sequence of URIs of the predicates to follow -->
		<xsl:variable name="step" select="path:expandNamespace($path[1])"/><!-- the next predicate to follow -->
		<!-- result of following that predicate: -->
		<xsl:variable name="step-result" select="
			key('subject-by-object-and-predicate', for $object in $from return concat($object, ' ', $step), $graph)
		"/>
		<!--
		<xsl:variable name="step-result" select="$graph/trix:triple[*[3]/text()=$from and trix:*[2]/text()=$step]/trix:*[1]/text()"/>
		-->
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

	<xsl:function name="path:expandNamespace">
		<xsl:param name="iri"/>
		<xsl:variable name="iri-1" select="replace($iri, 'rdf:', 'http://www.w3.org/1999/02/22-rdf-syntax-ns#')" />
		<xsl:variable name="iri-2" select="replace($iri-1, 'rdfs:', 'http://www.w3.org/2000/01/rdf-schema#')" />
		<xsl:variable name="iri-3" select="replace($iri-2, 'crm:', 'http://www.cidoc-crm.org/cidoc-crm/')" />
		<xsl:variable name="iri-4" select="replace($iri-3, 'ore:', 'http://www.openarchives.org/ore/terms/')" />
		<xsl:variable name="iri-5" select="replace($iri-4, 'dc:', 'http://purl.org/dc/terms/')" />
		<xsl:value-of select="$iri-5" />
	</xsl:function>

</xsl:stylesheet>