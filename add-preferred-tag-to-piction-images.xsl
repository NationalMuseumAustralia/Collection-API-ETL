<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" 
	xmlns:f="http://www.w3.org/2005/xpath-functions"
	xmlns:map="http://www.w3.org/2005/xpath-functions/map">
	<!--
		This stylesheet exists to ensure that for every EMu object, if it is depicted by at least one Piction image, then at least one of those images is 
		marked as 'preferred', by having a <field name="Page Number">1</field>
		
		This is so that we can highlight those 'preferred' images, and use them as graphical labels for the objects, when they appear in lists, etc.
	-->
	<xsl:key name="image-by-depicted-object" match="/*/doc" use="for $field in field[@name='EMu IRN for Related Objects'] return tokenize($field)"/>
	<xsl:template match="/*">
		<xsl:copy>
			<xsl:for-each select="doc">
				<xsl:copy>
					<xsl:copy-of select="*"/>
					<xsl:variable name="current-image" select="."/>
					<!-- find the objects which this image depicts, and -->
					<!-- select only those objects which this image is the FIRST to depict -->
					<!-- (we only need to flag this image as 'preferred' if it's the FIRST to depict an object which otherwise has no preferred images) -->
					<xsl:variable name="depicted-objects" select="
						for $object-id in 
							for $field in field[@name='EMu IRN for Related Objects'] return tokenize($field)
						return
							if ($current-image is key('image-by-depicted-object', $object-id)[1]) then $object-id else ()
					"/>
					<xsl:variable name="depicted-objects-all-have-preferred-images" select="
						every $object in $depicted-objects satisfies
							some $depiction in key('image-by-depicted-object', $object) satisfies
								$depiction/field[@name='Page Number']='1'
					"/>
					<xsl:if test="not($depicted-objects-all-have-preferred-images)">
						<field name="Page Number">1</field>
					</xsl:if>
				</xsl:copy>
			</xsl:for-each>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>