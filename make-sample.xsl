<!-- 
Extract a sample record from an XML source data file.
These files all consist of a root element containing a list of child elements each of which defines a single record.
This stylesheet extracts the most diverse such record; the (first) one which has the largest number of distinctly-named descendant elements of its own.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

	<xsl:output indent="true"/>

	<xsl:template match="/">
		<xsl:variable name="max-distinct-element-count" select="
			max(
				for $record in /*/* 
				return count(
					distinct-values(
						for $field in $record//*
						return local-name($field)
					)
				)
			)
		"/>
		<xsl:copy-of select="
			/*/*[
				$max-distinct-element-count = count(
					distinct-values(
						for $field in .//*
						return local-name($field)
					)
				)
			]
			[1]
		"/>
	</xsl:template>

</xsl:stylesheet>
