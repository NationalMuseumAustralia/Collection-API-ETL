<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" xmlns:c="http://www.w3.org/ns/xproc-step">
    	
	<xsl:template match="/">
		<c:request method="post" href="http://localhost:8080/solr/update">
			<c:body content-type="application/xml">
				<add commitWithin="5000">	
					<xsl:for-each select="/response/record">
						<doc>
							<field name="id"><xsl:value-of select="obj_irn"/></field>
							<field name="collection_explorer">http://collectionsearch.nma.gov.au/?object=<xsl:value-of select="obj_irn"/></field>
							<xsl:apply-templates/>
						</doc>
					</xsl:for-each>
				</add>
			</c:body>
		</c:request>
	</xsl:template>

	<xsl:template match="record/*[normalize-space()]">
		<!-- all child elements of record become simple solr fields -->
		<field name="{local-name()}"><xsl:value-of select="."/></field>
	</xsl:template>
	
</xsl:stylesheet>

