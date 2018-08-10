<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

	<!-- discard doc elements whose content is not different to the cached version -->
	<xsl:param name="current-date"/>
	
	<xsl:template match="/">
		<!-- the first <add> element contained in the root <comparison> element contains the new Piction data -->
		<!-- the second <add> contains the previous version of the Piction data -->
		<add>
			<xsl:for-each select="/comparison/add[1]/doc">
				<xsl:variable name="cached-record" select="key('cached-record-by-multimedia-id', field[@name='Multimedia ID'])"/>
				<!-- NB assumption is that the order of the elements within this <doc> is stable; 
				so we can compare the children of the two <doc> elements as sequences rather than sets -->
				<!-- if the new and cached records are identical, discard the record -->
				<xsl:if test="not(deep-equal(*, $cached-record/*))">
					<doc date-modified="{$current-date}">
						<xsl:copy-of select="*"/>
					</doc>
				</xsl:if>
			</xsl:for-each>
		</add>
	</xsl:template>
	
	<xsl:key name="cached-record-by-multimedia-id" match="/comparison/add[2]/doc" use="field[@name='Multimedia ID']"/>
	
</xsl:stylesheet>
