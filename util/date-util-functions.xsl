<!-- Function library for date conversion -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	version="3.0" xmlns:dateutil="tag:conaltuohy.com,2018:nma/date-util">

	<!-- only handles input date format: dd/mm/yyyy -->
	<xsl:function name="dateutil:to-iso-date">
		<xsl:param name="input" />
		<xsl:variable name="isoDate">
			<xsl:analyze-string select="normalize-space($input)"
				regex="([0-9]{{0,2}})/?([0-9]{{0,2}})/?([0-9]{{4}})">
				<xsl:matching-substring>
					<xsl:number value="regex-group(3)" format="0001" />
					<xsl:if test="regex-group(2)">
						<xsl:text>-</xsl:text>
						<xsl:number value="regex-group(2)" format="01" />
						<xsl:if test="regex-group(1)">
							<xsl:text>-</xsl:text>
							<xsl:number value="regex-group(1)" format="01" />
						</xsl:if>
					</xsl:if>
				</xsl:matching-substring>
			</xsl:analyze-string>
		</xsl:variable>
		<!-- ensure is a string -->
		<xsl:if test="string($isoDate)">
			<xsl:value-of select="string($isoDate)" />
		</xsl:if>
	</xsl:function>

	<xsl:function name="dateutil:to-xml-schema-type">
		<xsl:param name="input" />
		<xsl:variable name="isoDate" select="dateutil:to-iso-date($input)" />
		<xsl:choose>
			<xsl:when test="string-length(string($isoDate)) = 4">
				<xsl:text>http://www.w3.org/2001/XMLSchema#gYear</xsl:text>
			</xsl:when>
			<xsl:when test="string-length(string($isoDate)) = 7">
				<xsl:text>http://www.w3.org/2001/XMLSchema#gYearMonth</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>http://www.w3.org/2001/XMLSchema#date</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

</xsl:stylesheet>