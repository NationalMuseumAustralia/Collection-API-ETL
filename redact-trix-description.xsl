<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" 
	xmlns:path="tag:conaltuohy.com,2018:nma/trix-path-traversal"
	xmlns:trix="http://www.w3.org/2004/03/trix/trix-1/">
	
	<xsl:param name="root-resource"/><!-- e.g. "http://nma-dev.conaltuohy.com/xproc-z/narrative/1758#" -->
	<xsl:param name="debug" select=" 'false' "/><!-- 'true' will log the various of the redacted triples --> 
	<xsl:import href="util/trix-traversal-functions.xsl"/>
	
	<xsl:variable name="graph" select="/trix:trix/trix:graph" />
	
	<xsl:variable name="aat-ns" select=" 'http://vocab.getty.edu/aat/' "/> 
	<xsl:variable name="rdf-ns" select=" 'http://www.w3.org/1999/02/22-rdf-syntax-ns#' "/> 
	<xsl:variable name="ore-ns" select=" 'http://www.openarchives.org/ore/terms/' "/> 
	<xsl:variable name="dc-ns" select=" 'http://purl.org/dc/terms/' "/> 
	<xsl:variable name="rdfs-ns" select=" 'http://www.w3.org/2000/01/rdf-schema#' "/> 
	<xsl:variable name="crm-ns" select=" 'http://www.cidoc-crm.org/cidoc-crm/' "/>
	<xsl:variable name="nma-term-ns" select="replace($root-resource, '([^/]+//[^/]+).*', '$1/term/')"/>

	<!-- Objects within narratives have certain properties which we always want to retain: -->
	<xsl:variable name="desired-narrative-object-predicates" select="
		(
			concat($rdf-ns, 'type'),
			concat($rdfs-ns, 'label'),
			concat($crm-ns, 'P70i_is_documented_in')						
		)
	"/>
	
	<xsl:template match="/">
		<xsl:call-template name="do-redaction" />
	</xsl:template>
	
	<xsl:template name="do-redaction">
		<trix xmlns="http://www.w3.org/2004/03/trix/trix-1/">
			<graph>
				<!-- Find the identifiers of all the physical objects in the graph -->
				<xsl:variable name="objects" select="path:backward(concat($crm-ns, 'E19_Physical_Object'), 'rdf:type')"/>

				<!-- Find the identifiers of all the media in the graph -->
				<xsl:variable name="media" select="path:backward(concat($crm-ns, 'E36_Visual_Item'), 'rdf:type')"/>

				<!-- ############################################################################## -->
				<!-- Related objects -->
				<xsl:variable name="related-objects" select="path:forward('dc:relation')"/>

				<!-- identify related objects that aren't in the API (don't have a title) -->
				<xsl:variable name="related-objects-that-are-empty" select="
					$related-objects
						[
							not(
								path:forward(., ('rdfs:label'))
							)
						]
				"/>
				<!-- Exclude any links to those empty objects -->
				<xsl:variable name="empty-related-objects-triples" select="
					$graph/
						trix:triple
							[*[2]='http://purl.org/dc/terms/relation']
							[*[3]=$related-objects-that-are-empty] 
				"/>	
				<!-- Various properties of the 'related' objects are superfluous, and dc:relation especially
				should be pruned to avoid combinatorial explosion in JSON-LD rendering, since often a group of
				objects are related together in a dense cluster -->
				<xsl:variable name="desired-related-objects-properties" select="
					(
						'http://www.w3.org/1999/02/22-rdf-syntax-ns#type',
						'http://www.w3.org/2000/01/rdf-schema#label',
						'http://www.cidoc-crm.org/cidoc-crm/P138i_has_representation'
					)
				"/>
				<xsl:variable name="superfluous-related-objects-triples" select="
					$graph/
						trix:triple
							[*[1]=$related-objects]
							[not(*[2]=$desired-related-objects-properties)]
				"/>	
				
				<!-- ############################################################################## -->
				<!-- Slim down the description of any objects which are contained within narratives -->
				
				<!-- Find the identifiers of all the resources which are web pages. 
				Objects contained within narratives should retain 'is_subject_of' links to these resources, but not to other types of resources
				-->
				<xsl:variable name="web-pages" select="path:backward(concat($aat-ns, '300264578'), 'crm:P2_has_type')"/>
				<!-- Find all the objects which are contained within a narrative -->
				<xsl:variable name="narrative-objects" select="$objects[not(.=$root-resource)][path:backward(., 'ore:aggregates')]"/>
				<!-- find all the detailed visual items representing the top-level visual items depicting these narratives -->
				<xsl:call-template name="debug-list-values">
					<xsl:with-param name="title">narrative objects</xsl:with-param>
					<xsl:with-param name="values" select="$narrative-objects"/>
				</xsl:call-template>
				<xsl:variable name="detailed-visual-items" select="
					path:forward(
						$narrative-objects, 
						('crm:P138i_has_representation', 'crm:P138i_has_representation')
					)
				"/>
				<xsl:call-template name="debug-list-values">
					<xsl:with-param name="title">detailed visual items</xsl:with-param>
					<xsl:with-param name="values" select="$detailed-visual-items"/>
				</xsl:call-template>
				<!-- find the detailed visual items which are not either 'thumbnail' or 'preview' images; these can be redacted -->
				<xsl:variable name="irrelevant-visual-items" select="
					$detailed-visual-items[
						not(
							path:forward(., 'crm:P2_has_type') =
							(
								concat($nma-term-ns, 'thumbnail'),
								concat($nma-term-ns, 'preview')
							)
						)
					]
				"/>
				<xsl:call-template name="debug-list-values">
					<xsl:with-param name="title">irrelevant visual items</xsl:with-param>
					<xsl:with-param name="values" select="$irrelevant-visual-items"/>
				</xsl:call-template>
				<!-- find the triples which relate those irrelvant visual items to their parent visual item -->
				<xsl:variable name="irrelevant-visual-item-triples" select="$graph/trix:triple[*[3]=$irrelevant-visual-items]"/>
				<!-- Find all the triples which define properties of those "narrative objects" -->
				<xsl:variable name="narrative-object-triples" select="$graph/trix:triple[*[1]=$narrative-objects]"/>
				<!-- 
				The triples to retain are:
				• those whose predicates are always desired
				• all properties of the object if it's the root object of this graph (despite also being part of an aggregation)
				• those where the predicate is 'is_subject_of' and the value is a web page (i.e. links to Collection Explorer pages
				• those where the predicate is 'has_representation', and the value is a visual item which is represented by a detailed visual item
				  which is not one of the previously-identified irrelevant visual items
				-->
				<xsl:variable name="desired-narrative-object-triples" select="
					$narrative-object-triples
						[
							*[2]=$desired-narrative-object-predicates or
							*[2]=concat($crm-ns, 'P129i_is_subject_of') and *[3] = $web-pages  or
							*[2]=concat($crm-ns, 'P138i_has_representation') and 
								path:forward(*[3], 'crm:P138i_has_representation')[
									not(. = $irrelevant-visual-items)
								]
						]
				"/>
				<!-- All the OTHER narrative objects' triples must be unwanted -->
				<xsl:variable name="unwanted-narrative-object-triples" select="$narrative-object-triples except $desired-narrative-object-triples"/>

				<!-- ############################################################################## -->
				<!-- Finally copy the triples of the graph, excluding any of the triples we've identified as unwanted -->
				<xsl:variable name="published-triples" select="
					$graph/trix:triple except (
						$empty-related-objects-triples, 
						$superfluous-related-objects-triples, 
						$unwanted-narrative-object-triples,
						$irrelevant-visual-item-triples
					)
				"/>
				
				<xsl:call-template name="debug-list-redacted-triples">
					<xsl:with-param name="reason">irrelevant narrative object visual items</xsl:with-param>
					<xsl:with-param name="redaction" select="$irrelevant-visual-items"/>
				</xsl:call-template>
				<xsl:call-template name="debug-list-redacted-triples">
					<xsl:with-param name="reason">empty related objects triples</xsl:with-param>
					<xsl:with-param name="redaction" select="$empty-related-objects-triples"/>
				</xsl:call-template>
				<xsl:call-template name="debug-list-redacted-triples">
					<xsl:with-param name="reason">superfluous related objects triples</xsl:with-param>
					<xsl:with-param name="redaction" select="$superfluous-related-objects-triples"/>
				</xsl:call-template>
				<xsl:call-template name="debug-list-redacted-triples">
					<xsl:with-param name="reason">unwanted narrative object triples</xsl:with-param>
					<xsl:with-param name="redaction" select="$unwanted-narrative-object-triples"/>
				</xsl:call-template>

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
