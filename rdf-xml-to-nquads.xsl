<?xml version="1.1"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
	
	<xsl:param name="graph"/>
	
	<xsl:template match="/">
		<nquads-graph>
			<xsl:apply-templates/>
		</nquads-graph>
	</xsl:template>
	
	<xsl:template match="rdf:RDF">
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:function name="rdf:node-identifier">
		<xsl:param name="node"/>
		<xsl:value-of select="
			if ($node/@rdf:about) then
				concat('&lt;', resolve-uri($node/@rdf:about, ($node/ancestor-or-self::*/@xml:base)[1]), '&gt;')
			else if ($node/@rdf:ID) then
				concat('&lt;', resolve-uri(concat('#', $node/@rdf:ID), ($node/ancestor-or-self::*/@xml:base)[1]), '&gt;')
			else if ($node/@rdf:nodeID) then
				concat('_:', $node/@rdf:nodeID)
			else
				concat('_:', generate-id($node))
		"/>		
	</xsl:function>
	
	<xsl:function name="rdf:literal">
		<xsl:param name="text"/>
		<xsl:param name="lang"/>
		<xsl:param name="datatype"/>
		<xsl:variable name="result">
			<xsl:text>"</xsl:text>
			<xsl:analyze-string select="$text" regex="(#x22)|(#x5C)|(#xA)|(#xD)">
				<xsl:matching-substring>
					<xsl:choose>
						<xsl:when test="regex-group(1)">\"</xsl:when>
						<xsl:when test="regex-group(2)">\\</xsl:when>
						<xsl:when test="regex-group(3)">\n</xsl:when>
						<xsl:when test="regex-group(4)">\r</xsl:when>
					</xsl:choose>
				</xsl:matching-substring>
				<xsl:non-matching-substring>
					<xsl:value-of select="."/>
				</xsl:non-matching-substring>
			</xsl:analyze-string>
			<xsl:text>"</xsl:text>
			<xsl:choose>
				<xsl:when test="$datatype">^^<xsl:value-of select="$datatype"/></xsl:when>
				<xsl:otherwise>
					<xsl:if test="$lang">@<xsl:value-of select="$lang"/></xsl:if>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:value-of select="string($result)"/>
	</xsl:function>
	
	<!-- match a node element -->
	<xsl:template match="*">
		<xsl:variable name="subject" select="rdf:node-identifier(.)"/>
		
		<!-- rdf:type property value specified by node element QName -->
		<xsl:if test="not(self::rdf:Description)">
			<!-- element name specifies a class -->
			<xsl:variable name="class" select="concat('&lt;', namespace-uri(.), local-name(.), '-XXX&gt;')"/>
			<xsl:call-template name="triple">
				<xsl:with-param name="subject" select="$subject"/>
				<xsl:with-param name="predicate" select="'&lt;http://www.w3.org/1999/02/22-rdf-syntax-ns#type&gt;'"/>
				<xsl:with-param name="object" select="$class"/>
			</xsl:call-template>
		</xsl:if>
		
		<!-- other properties specified by property elements -->
		<xsl:for-each select="*">
			<xsl:variable name="predicate" select="concat('&lt;', namespace-uri(.), local-name(.), '&gt;')"/>
			<!-- property value may be specified by an element or an rdf:resource attribute or by text with an optional datatype attribute -->
			<xsl:choose>
				<xsl:when test="*">
					<xsl:call-template name="triple">
						<xsl:with-param name="subject" select="$subject"/>
						<xsl:with-param name="predicate" select="$predicate"/>
						<xsl:with-param name="object" select="rdf:node-identifier(*)"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="@rdf:resource">
					<xsl:call-template name="triple">
						<xsl:with-param name="subject" select="$subject"/>
						<xsl:with-param name="predicate" select="$predicate"/>
						<xsl:with-param name="object" select="concat('&lt;', @rdf:resource, '&gt;')"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:call-template name="triple">
						<xsl:with-param name="subject" select="$subject"/>
						<xsl:with-param name="predicate" select="$predicate"/>
						<xsl:with-param name="object" select="rdf:literal(string(.), ancestor-or-self::*/@xml:lang, @rdf:datatype)"/>
					</xsl:call-template>				
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
		
		<!-- other string properties may be specified by property attributes -->
		<xsl:for-each select="@*">
			<xsl:if test="namespace-uri(.) != 'http://www.w3.org/1999/02/22-rdf-syntax-ns#' ">
				<xsl:variable name="predicate" select="concat('&lt;', namespace-uri(.), local-name(.), '&gt;')"/>
				<xsl:call-template name="triple">
					<xsl:with-param name="subject" select="$subject"/>
					<xsl:with-param name="predicate" select="$predicate"/>
					<xsl:with-param name="object" select="rdf:literal(., ancestor-or-self::*/@xml:lang, ())"/>
				</xsl:call-template>		
			</xsl:if>
		</xsl:for-each>
		
		<!-- recurse -->
		<xsl:apply-templates select="*/*"/>
				
	</xsl:template>
	
	<xsl:template name="triple">
		<xsl:param name="subject"/>
		<xsl:param name="predicate"/>
		<xsl:param name="object"/>
		<xsl:variable name="graph" select="concat('&lt;', $graph, '&gt;')"/>
		<xsl:value-of select="
			concat(
				$subject,
				' ',
				$predicate,
				' ',
				$object,
				' ',
				$graph,
				'.',
				codepoints-to-string(10)
			)
		"/>
	</xsl:template>
	
</xsl:stylesheet>