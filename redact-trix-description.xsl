<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" 
	xmlns:path="tag:conaltuohy.com,2018:nma/trix-path-traversal"
	xmlns:trix="http://www.w3.org/2004/03/trix/trix-1/">
	
	<xsl:param name="root-resource"/><!-- e.g. "http://nma-dev.conaltuohy.com/xproc-z/narrative/1758#" -->
	<xsl:import href="util/trix-traversal-functions.xsl"/>
	
	<xsl:variable name="graph" select="/trix:trix/trix:graph" />
	
	<xsl:variable name="aat-ns" select=" 'http://vocab.getty.edu/aat/' "/> 
	<xsl:variable name="rdf-ns" select=" 'http://www.w3.org/1999/02/22-rdf-syntax-ns#' "/> 
	<xsl:variable name="ore-ns" select=" 'http://www.openarchives.org/ore/terms/' "/> 
	<xsl:variable name="dc-ns" select=" 'http://purl.org/dc/terms/' "/> 
	<xsl:variable name="rdfs-ns" select=" 'http://www.w3.org/2000/01/rdf-schema#' "/> 
	<xsl:variable name="crm-ns" select=" 'http://www.cidoc-crm.org/cidoc-crm/' "/>
	<xsl:variable name="nma-term-ns" select=" 'https://api.nma.gov.au/term/' " />

	<!-- Objects within narratives have certain properties which we always want to retain: -->
	<xsl:variable name="desired-narrative-object-predicates" select="
		(
			concat($rdf-ns, 'type'),
			concat($rdfs-ns, 'label'),
			concat($crm-ns, 'P138i_has_representation'),
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
				<!-- Having good quality images from Piction means we don't need any images from EMu -->
				
				<!-- identify any objects which have Piction images -->
				<xsl:variable name="objects-with-piction-images" select="
					$objects
						[
							path:forward(., ('crm:P138i_has_representation', 'crm:P2_has_type'))
								[
									contains(., 'piction-image')
								]
						]
				"/>
				<!-- identify any EMu images which can therefore be discarded -->
				<xsl:variable name="unwanted-emu-images" select="
					$graph/
						trix:triple
							[*[1]=$objects-with-piction-images]
							[*[2]='http://www.cidoc-crm.org/cidoc-crm/P138i_has_representation']
							[
								path:forward(*[3], 'crm:P2_has_type')
									[contains(., 'emu-image')]
							]
				"/>
				
				<!-- ############################################################################## -->
				<!-- We can't include media unless they are bundled into an aggregation which is subject to a rights statement -->

				<!-- 1. Remove links to those media from within objects -->
				
				<!-- identify any objects with media which are not aggregated into a collection which is subject to some legal rights -->
				<xsl:variable name="objects-with-media-but-no-rights" select="
					$objects[
						path:forward(., 'crm:P138i_has_representation')[
							not( 
								path:forward(., ('ore:isAggregatedBy', 'crm:P104_is_subject_to'))
							)
						]
					]
				"/>
				<!-- identify any media statements which can be discarded -->
				<xsl:variable name="unwanted-object-media-statements" select="
					$graph/
						trix:triple
							[*[1]=$objects-with-media-but-no-rights]
							[*[2]='http://www.cidoc-crm.org/cidoc-crm/P138i_has_representation']
				"/>


				<!-- ############################################################################## -->
				<!-- Exclude related objects that aren't available via the API -->

				<!-- identify related objects that aren't in the API (don't have a title) -->
				<xsl:variable name="related-objects-that-are-empty" select="
					path:forward(('dc:relation'))
						[
							not(
								path:forward(., ('rdfs:label'))
							)
						]
				"/>
				<!-- identify any related object statements which can be discarded -->
				<xsl:variable name="empty-related-objects-triples" select="
					$graph/
						trix:triple
							[*[2]='http://purl.org/dc/terms/relation']
							[*[3]=$related-objects-that-are-empty] 
				"/>	
				<!-- dc:relation properties of resources other than the root resource are superfluous, and 
				are deleted to avoid combinatorial explosion in JSON-LD rendering, since often a group of
				objects are related together in a dense cluster -->
				<xsl:variable name="superfluous-related-objects-triples" select="
					$graph/
						trix:triple
							[*[1]!=$root-resource]
							[*[2]='http://purl.org/dc/terms/relation']
				"/>	
				
				<!-- ############################################################################## -->
				<!-- Slim down the description of any objects which are contained within narratives -->
				
				<!-- Find the identifiers of all the resources which are web pages. 
				Objects contained within narratives should retain 'is_subject_of' links to these resources, but not to other types of resources
				-->
				<xsl:variable name="web-pages" select="path:backward(concat($aat-ns, '300264578'), 'crm:P2_has_type')"/>
				<!-- Find all the objects which are contained within a narrative -->
				<xsl:variable name="narrative-objects" select="$objects[path:backward(., 'ore:aggregates')]"/>
				<!-- Find all the triples which define properties of those "narrative objects" -->
				<xsl:variable name="narrative-object-triples" select="$graph/trix:triple[*[1]=$narrative-objects]"/>
				<!-- The properties to retain are those whose predicates are always desired, OR
				where the predicate is 'is_subject_of' and the value is a web page (i.e. links to Collection Explorer pages) -->
				<xsl:variable name="desired-narrative-object-triples" select="
					$narrative-object-triples
						[
							*[2]=$desired-narrative-object-predicates or
							*[2]=concat($crm-ns, 'P129i_is_subject_of') and *[3] = $web-pages
						]
				"/>
				<!-- All the OTHER narrative objects' triples must be unwanted -->
				<xsl:variable name="unwanted-narrative-object-triples" select="$narrative-object-triples except $desired-narrative-object-triples"/>

				<!-- ############################################################################## -->
				<!-- Finally copy the triples of the graph, excluding any of the triples we've identified as unwanted -->
				<xsl:variable name="published-triples" select="
					$graph/trix:triple except (
						$unwanted-emu-images, 
						$unwanted-object-media-statements, 
						$empty-related-objects-triples, 
						$superfluous-related-objects-triples, 
						$unwanted-narrative-object-triples
					)
				"/>
				
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
	
</xsl:stylesheet>
