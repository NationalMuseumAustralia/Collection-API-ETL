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
				<!-- ############################################################################## -->
				<!-- Remove narrative banner images (not rights-cleared) -->
				
				<!-- identify narrative banner images to be discarded -->
				<xsl:variable name="unwanted-narrative-banner-images" select="
					path:forward('ore:aggregates')[
						path:forward(., 'crm:P2_has_type') = concat($nma-term-ns, 'banner-image')
					]
				"/>
				
				<!-- ############################################################################## -->
				<!-- Slim down the description of any objects which are contained within narratives -->
				
				<!-- Find the identifiers of all the resources which are web pages. 
				Objects contained within narratives should retain 'is_subject_of' links to these resources, but not to other types of resources
				-->
				<xsl:variable name="web-pages" select="path:backward(concat($aat-ns, '300264578'), 'crm:P2_has_type')"/>
				<!-- Find the identifiers of all the physical objects in the graph -->
				<xsl:variable name="objects" select="path:backward(concat($crm-ns, 'E19_Physical_Object'), 'rdf:type')"/>
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
				<!-- identify any EMu images which can be discarded -->
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
				<!-- We don't want a rights statement if there isn't actually any media attached -->
				
				<!-- identify any objects without media -->
				<xsl:variable name="objects-with-no-media" select="
					$objects
						[
							not( 
								path:forward(., ('crm:P138i_has_representation'))
							)
						]
				"/>
				<!-- identify any rights statements which can be discarded -->
				<xsl:variable name="unwanted-rights-statements" select="
					$graph/
						trix:triple
							[*[1]=$objects-with-no-media]
							[*[2]='http://www.cidoc-crm.org/cidoc-crm/P104_is_subject_to']
				"/>
				
				<!-- ############################################################################## -->
				<!-- Finally copy the triples of the graph, excluding any of the triples we've identified as unwanted -->
				<xsl:copy-of select="$graph/trix:triple except ($unwanted-narrative-banner-images, $unwanted-narrative-object-triples, $unwanted-emu-images, $unwanted-rights-statements)"/>
				
			</graph>
		</trix>
	</xsl:template>
	
	
</xsl:stylesheet>
