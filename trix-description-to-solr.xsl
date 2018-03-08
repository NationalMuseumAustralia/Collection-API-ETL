<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:path="tag:conaltuohy.com,2018:nma/trix-path-traversal"
	xmlns:f="http://www.w3.org/2005/xpath-functions"
	xmlns:map="http://www.w3.org/2005/xpath-functions/map"
	xmlns:trix="http://www.w3.org/2004/03/trix/trix-1/">
	
	<xsl:param name="root-resource"/><!-- e.g. "http://nma-dev.conaltuohy.com/xproc-z/narrative/1758#" -->
	<xsl:param name="dataset"/>
	<xsl:variable name="graph" select="/trix:trix/trix:graph"/>
	<!-- load the mapping between URIs and JSON key names from Linked Art context file, expanding compact URIs to full URIs -->
	<!-- and adding a mapping for rdf:type -->
	<xsl:variable name="linked-art-context" select="
		map:merge(
			(
				json-doc('linked-art.json')('@context'),
				map{'type': 'rdf:type'}
			),
			map{'duplicates': 'use-last'}
		)
	"/>
	<xsl:variable name="uri-term-map">
		<!-- 
			e.g.
			<mapping uri="http://www.cidoc-crm.org/cidoc-crm/P138i_has_representation" term="representation"/>
			...
		-->
		<xsl:for-each select="map:keys($linked-art-context)">
			<xsl:variable name="value" select="$linked-art-context(.)"/>
			<xsl:variable name="value-is-map" select="$value instance of map(*)"/>
			<xsl:message>value=<xsl:value-of select="if ($value-is-map) then serialize($value, map{'method': 'json'}) else $value"/></xsl:message>
			<xsl:message>value-is-map=<xsl:value-of select="$value-is-map"/></xsl:message>
			<!-- the value of the term in the JSON-LD context may be the URI or compact URI, or it may be another map, containing an entry with key="@id" and whose value=the URI or compact URI -->
			<xsl:variable name="uri-or-compact-uri" select="
				if ($value-is-map) then 
					$value('@id')
				else
					$value
			"/>
			<xsl:variable name="prefix" select="substring-before($uri-or-compact-uri, ':')"/>
			<xsl:message>prefix=<xsl:value-of select="$prefix"/></xsl:message>
			<xsl:variable name="expanded-prefix" select="$linked-art-context($prefix)"/>
			<xsl:message>expanded-prefix=<xsl:value-of select="$expanded-prefix"/></xsl:message>
			<xsl:variable name="expanded-uri" select="
				if ($expanded-prefix) then 
					concat($expanded-prefix, substring-after($uri-or-compact-uri, ':')) 
				else 
					$uri-or-compact-uri
			"/>
			<xsl:message>expanded-uri=<xsl:value-of select="$expanded-uri"/></xsl:message>
			<xsl:element name="mapping">
				<xsl:attribute name="uri" select="$expanded-uri"/>
				<xsl:attribute name="term" select="."/>
			</xsl:element>
		</xsl:for-each>
	</xsl:variable>
	
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
							<xsl:call-template name="json-ld-in-xml"/>
						</xsl:variable>
						<field name="json-ld"><xsl:value-of select="xml-to-json($json-ld-in-xml, map{'indent':true()})"/></field>
					</doc>
				</add>
			</c:body>
		</c:request>
	</xsl:template>
	
	<xsl:template name="json-ld-in-xml">
		<!-- see https://www.w3.org/TR/xpath-functions-31/#json-to-xml-mapping for definition of the elements used here -->
		<f:map>
			<f:string key="@context">https://linked.art/ns/v1/linked-art.json</f:string>
			<f:string key="id"><xsl:value-of select="$root-resource"/></f:string>
			<!-- TODO apply templates to traverse the graph; templates would match triples by predicate, and represent them as JSON XML -->
			<xsl:apply-templates select="$graph/trix:triple[string(trix:uri[1])=$root-resource]" mode="json-ld-in-xml"/>
		</f:map>
	</xsl:template>
	
	<xsl:template mode="json-ld-in-xml" match="trix:triple">
		<!-- render the triple as JSON-LD in XML -->
		<!-- look up the term defined for this predicate URI by the Linked Art context -->
		<xsl:variable name="predicate" select="trix:uri[2]"/>
		<xsl:variable name="key" select="
			$uri-term-map/mapping[@uri=$predicate]/@term
		"/>
		<xsl:message><xsl:value-of select="
			concat(
				'looking up [',
				$predicate,
				'] to find [',
				$key,
				']'
			)
		"/></xsl:message>
		<xsl:if test="$key">
			<f:string key="{$key}">
				<xsl:variable name="property-value" select="*[3]"/>
				<xsl:choose>
					<xsl:when test="$property-value/self::trix:uri"><!-- object property with URI --><!-- TODO handle blank nodes -->
						<f:map>
							<f:string key="id"><xsl:value-of select="$property-value"/></f:string>
							<xsl:apply-templates select="$graph/trix:triple[trix:uri[1]=$property-value]" mode="json-ld-in-xml"/>
						</f:map>
					</xsl:when>
					<xsl:when test="$property-value/self::trix:plainLiteral | $property-value/self::trix:literal"><!-- string -->
						<f:string key="{$key}"><xsl:value-of select="$property-value"/></f:string>
					</xsl:when>
				</xsl:choose>
			</f:string>
		</xsl:if>
	</xsl:template>
	
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
