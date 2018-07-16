<!-- Function library for date conversion -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	version="3.0" xmlns:dateutil="tag:conaltuohy.com,2018:nma/date-util"
	xmlns:xs="http://www.w3.org/2001/XMLSchema">

	<!-- convert date from slashes format to iso format -->
	<!-- only handles input date format: dd/mm/yyyy -->
	<xsl:function name="dateutil:to-iso-date">
		<xsl:param name="input" />
		<xsl:variable name="isoDate">
			<xsl:analyze-string select="normalize-space($input)"
				regex="([0-9]{{0,2}})/?([0-9]{{0,2}})/?([0-9]{{4}})">
				<xsl:matching-substring>
					<!-- year -->
					<xsl:number value="regex-group(3)" format="0001" />
					<!-- month -->
					<xsl:if test="regex-group(2)">
						<xsl:text>-</xsl:text>
						<xsl:number value="regex-group(2)" format="01" />
						<!-- day -->
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

	<!-- convert date from slashes format to human-readable display format -->
	<!-- only handles input date format: dd/mm/yyyy -->
	<xsl:function name="dateutil:to-display-date">
		<xsl:param name="input" />
		<xsl:variable name="displayDate">
			<xsl:analyze-string select="normalize-space($input)"
				regex="([0-9]{{0,2}})/?([0-9]{{0,2}})/?([0-9]{{4}})">
				<xsl:matching-substring>
					<!-- day -->
					<xsl:if test="regex-group(1)">
						<xsl:number value="regex-group(1)" format="1" />
					</xsl:if>
					<!-- month -->
					<xsl:if test="regex-group(2)">
						<xsl:text> </xsl:text>
						<!-- get month as text by formatting a fake date containing the actual month value -->
						<xsl:value-of select="format-date( xs:date( concat('0001-',regex-group(2),'-01') ), '[MNn]')" />
					</xsl:if>
					<!-- year -->
					<xsl:if test="regex-group(3)">
						<xsl:text> </xsl:text>
						<xsl:number value="regex-group(3)" format="0001" />
					</xsl:if>
				</xsl:matching-substring>
			</xsl:analyze-string>
		</xsl:variable>
		<!-- ensure is a string -->
		<xsl:if test="string($displayDate)">
			<xsl:value-of select="normalize-space(string($displayDate))" />
		</xsl:if>
	</xsl:function>

	<!-- convert date from iso format to human-readable display format -->
	<!-- only handles input iso date format: yyyy-mm-dd -->
	<xsl:function name="dateutil:to-display-date-iso">
		<xsl:param name="input" />
		<xsl:variable name="displayDate">
			<!-- NB: can't just use format-date as requires xs:date to the day precision -->
			<xsl:analyze-string select="normalize-space($input)"
				regex="([0-9]{{4}})-?([0-9]{{0,2}})-?([0-9]{{0,2}})">
				<xsl:matching-substring>
					<!-- day, no leading zero -->
					<xsl:if test="regex-group(3)">
						<xsl:number value="regex-group(3)" format="1" />
					</xsl:if>
					<!-- month, as text -->
					<xsl:if test="regex-group(2)">
						<xsl:text> </xsl:text>
						<!-- get month as text by formatting a fake date containing the actual month value -->
						<xsl:value-of select="format-date( xs:date( concat('0001-',regex-group(2),'-01') ), '[MNn]')" />
					</xsl:if>
					<!-- year -->
					<xsl:if test="regex-group(1)">
						<xsl:text> </xsl:text>
						<xsl:number value="regex-group(1)" format="0001" />
					</xsl:if>
				</xsl:matching-substring>
			</xsl:analyze-string>
		</xsl:variable>
		<!-- ensure is a string -->
		<xsl:if test="string($displayDate)">
			<xsl:value-of select="normalize-space(string($displayDate))" />
		</xsl:if>
	</xsl:function>

	<!-- returns XML Schema datatype IRI if date converted from slashes format to iso format -->
	<!-- only handles input date format: dd/mm/yyyy -->
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