<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">

	<!-- redacts records and parts of records, for public consumption -->

	<!-- identity template copies anything which isn't explicitly excluded by a more specific rule -->
	<xsl:template match="*">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	
	<!-- redaction rules -->
	
	<!-- exclude records whose status isn’t either “Public” or “Public Restricted -->
	<xsl:template match="
		record[
			not(AcsAPI_tab/AcsAPI  = ('Public', 'Public Restricted'))
		]
	"/>
	
	<!-- exclude original_2 Piction images from Public API  -->
	<xsl:template match="record/dataSource[@name='original_2']"/>
	
	<!-- remove all non-Acton locations from Public API -->
	<xsl:template match="LocCurrentLocationRef[not(LocLevel1='Acton')]"/>
	
	<!-- remove all locations other than levels 1 and 2, where level 1 is "Acton" -->
	<xsl:template match="LocCurrentLocationRef[LocLevel1='Acton']/*[not(self::LocLevel1 | self:LocLevel2)]"/>
	
	<!-- remove all images if licence is not open -->
	<xsl:template match="
		record[
			not(
				AcsStatus = (
					'Public Domain', 
					'Creative Commons Commercial Use', 
					'Creative Commons Non-Commercial Use'
				)
			)
		]/WebMultiMediaRef_tab
	"/>

</xsl:stylesheet>
