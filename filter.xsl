<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">

	<!-- redacts records and parts of records, for public consumption -->
	<xsl:param name="dataset"/>

	<xsl:template match="/">
		<xsl:choose>
			<xsl:when test="($dataset='internal')">
				<!-- copy everything -->
				<xsl:copy-of select="*"/>
			</xsl:when>
			<xsl:otherwise>
				<!-- redact non-public data -->
				<xsl:apply-templates/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- identity template copies anything which isn't explicitly excluded by a more specific rule -->
	<xsl:template match="*">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	
	<!-- redaction rules -->
	
	<!-- exclude object record whose status isn’t either “Public” or “Public Restricted -->
	<xsl:template match="
		record
			[TitObjectType]
			[
				not(
					AcsAPI_tab/AcsAPI  = ('Public', 'Public Restricted')
				)
			]
	"/>
	<!-- exclude a narrative's reference to an object, if that object's status isn’t either “Public” or “Public Restricted -->
	<xsl:template match="
		record/ObjObjectsRef_tab/ObjObjectsRef
			[
				not(
					AcsAPI_tab/AcsAPI  = ('Public', 'Public Restricted')
				)
			]
	"/>
	
	<!-- exclude original_2 Piction images from Public API  -->
	<xsl:template match="doc/dataSource[@name='original_2']"/>
	
	<!-- TODO: what about AdmPublishWebNoPassword? -->
	<!-- 1265 say "Yes", 555 say "No" -->
	<!--
			ObjObjectsRef_tab (optional)
				sequence of ObjObjectsRef,
					irn (string), 
					AdmPublishWebNoPassword, 
					AcsAPI_tab 
						sequence of AcsAPI (string)
	-->
	
	<!-- exclude narrative banner images -->
	<xsl:template match="record/MulMultiMediaRef_tab"/>
	
	<!-- remove all non-Acton locations from Public API -->
	<xsl:template match="LocCurrentLocationRef[not(LocLevel1='Acton')]"/>
	
	<!-- remove all locations other than levels 1 and 2, where level 1 is "Acton" -->
	<xsl:template match="LocCurrentLocationRef[LocLevel1='Acton']/*[not(self::LocLevel1 | self::LocLevel2)]"/>
	
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
	
	<!-- Exclude any narrative whose intended audience does not include "Collection Explorer publish" -->
	<xsl:template match="
		record[
			DesIntendedAudience_tab
		]
		[
			not(
				DesIntendedAudience_tab/DesIntendedAudience='Collection Explorer publish'
			)
		]
	"/>
			
			
</xsl:stylesheet>
