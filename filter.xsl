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
				<xsl:apply-templates mode="public"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- identity template copies anything which isn't explicitly excluded by a more specific rule -->
	<xsl:template mode="public" match="*">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	
	<!-- redaction rules -->
	
	<!-- exclude object record whose status isn’t either “Public” or “Public Restricted" or "Removed" -->
	<xsl:template mode="public" match="
		record
			[TitObjectType]
			[
				not(
					AcsAPI_tab/AcsAPI  = ('Public', 'Public Restricted', 'Removed')
				)
			]
	"/>
	<!-- exclude a narrative's reference to an object, if that object's status isn’t either “Public” or “Public Restricted -->
	<xsl:template mode="public" match="
		record/ObjObjectsRef_tab/ObjObjectsRef
			[
				not(
					AcsAPI_tab/AcsAPI  = ('Public', 'Public Restricted')
				)
			]
	"/>
	
	<!-- exclude original_2 Piction images from Public API  -->
	<xsl:template mode="public" match="doc/dataSource[@name='original_2']"/>
	
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
	<xsl:template mode="public" match="record/MulMultiMediaRef_tab"/>
	
	<!-- remove all precise locations from Public API -->
	<xsl:template mode="public" match="LocCurrentLocationRef"/>
	
	<!-- exclude object inwards loan flag -->
	<xsl:template mode="public" match="InwardLoan"/>
	
	<xsl:variable name="open-rights" select="
		(
			'Public Domain', 
			'Creative Commons Commercial Use', 
			'Creative Commons Non-Commercial Use'
		)
	"/>
	<!-- remove all images if licence is not open -->
	<xsl:template mode="public" match="record[not(AcsCCStatus = $open-rights)]/WebMultiMediaRef_tab"/>
	
	<!-- remove rights data altogether if restricted; this will cause all images (including Piction images) to be redacted -->
	<xsl:template mode="public" match="record/AcsCCStatus[not(. = $open-rights)]"/>
	
	<!-- Exclude any narrative whose intended audience does not include "Collection Explorer publish" -->
	<xsl:template mode="public" match="
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
