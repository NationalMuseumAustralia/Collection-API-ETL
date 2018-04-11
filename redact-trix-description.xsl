<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" 
	xmlns:trix="http://www.w3.org/2004/03/trix/trix-1/">
	
	<xsl:param name="root-resource"/><!-- e.g. "http://nma-dev.conaltuohy.com/xproc-z/narrative/1758#" -->
	<xsl:variable name="graph" select="/trix:trix/trix:graph" />

	<xsl:template match="/">
		<trix xmlns="http://www.w3.org/2004/03/trix/trix-1/">
			<graph>
				<!-- identify any Piction images -->
				<xsl:variable name="piction-images" select="
					$graph/
						trix:triple
							[*[2]='http://www.cidoc-crm.org/cidoc-crm/P2_has_type']
							[contains(*[3], 'piction-image')]
							/*[1]
				"/>
				<xsl:choose>
					<xsl:when test="$piction-images">
						<!-- Having good quality images from Piction means we don't need any images from EMu -->
						<!-- Identify EMu images for redaction -->
						<xsl:variable name="emu-images" select="
							$graph/
								trix:triple
									[*[2]='http://www.cidoc-crm.org/cidoc-crm/P2_has_type']
									[contains(*[3], 'emu-image')]
									/*[1]
						"/>
						<!-- Copy the triples, redacting those whose objects are EMu images -->
						<xsl:copy-of select="$graph/trix:triple[not(*[3]=$emu-images)]"/>
					</xsl:when>
					<xsl:otherwise>
						<!-- No Piction images means there is nothing to redact -->
						<xsl:copy-of select="$graph/trix:triple"/>
					</xsl:otherwise>
				</xsl:choose>
			</graph>
		</trix>
	</xsl:template>
	
	
</xsl:stylesheet>
