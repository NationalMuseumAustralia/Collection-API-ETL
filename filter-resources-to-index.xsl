<!-- Compares two lists of resources; a SPARQL results set, and a Solr doc list -->
<!-- Returns the SPARQL results, filtered to exclude any result whose resource, lastUpdated, and sourceCount columns
are matched by a Solr doc's id, last-updated, and source-count fields -->
<!-- Matching resources indicates that the resource in Solr is already up to date, and will not need updating, and can be removed from the result set -->
<!-- SPARQL resource is a full URI e.g. 'http://nma-dev.conaltuohy.com/media/100008#' whereas Solr's id is just 'media/100008' -->

<xsl:stylesheet  version="3.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:sparql="http://www.w3.org/2005/sparql-results#">
	<xsl:template match="/">
		<xsl:apply-templates select="comparison/sparql:sparql"/>
	</xsl:template>
	<xsl:template match="*">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="sparql:result">
		<!-- Check if the result has a matching Solr doc; if not, then copy it -->
		<xsl:variable name="id" select="
			replace(
				sparql:binding[@name='resource']/sparql:uri,
				'http://[^/]*/(.*)#',
				'$1'
			)
		"/>
		<xsl:variable name="datestamp" select="sparql:binding[@name='lastUpdated']/sparql:literal"/>
		<xsl:variable name="source-count" select="sparql:binding[@name='sourceCount']/sparql:literal"/>
		<xsl:variable name="solr-doc" select="
			key(
				'solr-doc-by-id-datestamp-and-source-count', 
				string-join(
					($id, $datestamp, $source-count),
					' '
				)
			)
		"/>
		<xsl:if test="not($solr-doc)">
			<!-- no matching doc in Solr already, so this record will need to be updated -->
			<xsl:copy-of select="."/>
		</xsl:if>
	</xsl:template>
	<xsl:key 
		name="solr-doc-by-id-datestamp-and-source-count"
		match="/comparison/response/result[@name='response']/doc"
		use="
			string-join(
				(str[@name='id'], str[@name='datestamp'], str[@name='source_count']),
				' '
			)
		"
	/>
</xsl:stylesheet>
