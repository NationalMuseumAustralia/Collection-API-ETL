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
	
	<!-- remove level 3 and 4 locations where level 1 is "Acton" -->
	<xsl:template match="LocCurrentLocationRef[LocLevel1='Acton']/LocLevel3"/>
	<xsl:template match="LocCurrentLocationRef[LocLevel1='Acton']/LocLevel4"/>

</xsl:stylesheet>