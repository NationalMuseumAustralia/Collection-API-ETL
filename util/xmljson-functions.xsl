<!-- Function library for rendering literal values appropriately for xml-to-json 
	conversion -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	version="3.0" xmlns:xmljson="tag:conaltuohy.com,2018:nma/xml-to-json">

	<xsl:function name="xmljson:render-as-string">
		<xsl:param name="label" />
		<xsl:param name="values" />
		<xsl:copy-of select="xmljson:render-as-literal($label, $values, 'string', '; ')" />
	</xsl:function>

	<xsl:function name="xmljson:render-as-number">
		<xsl:param name="label" />
		<xsl:param name="values" />
		<!-- only use the first value -->
		<xsl:copy-of
			select="xmljson:render-as-literal($label, $values[position() = 1], 'number', '')" />
	</xsl:function>

	<xsl:function name="xmljson:render-as-boolean">
		<xsl:param name="label" />
		<xsl:param name="values" />
		<!-- only use the first value -->
		<xsl:copy-of
			select="xmljson:render-as-literal($label, $values[position() = 1], 'boolean', '')" />
	</xsl:function>

	<!-- display string/number/boolean, ensuring there is only one element (multi-values 
		are concatenated) -->
	<xsl:function name="xmljson:render-as-literal">
		<xsl:param name="label" />
		<xsl:param name="values" />
		<xsl:param name="datatype" />
		<xsl:param name="separator" />
		<xsl:if test="count($values) > 0">
			<xsl:element name="{$datatype}" xmlns="http://www.w3.org/2005/xpath-functions">
				<xsl:if test="$label">
					<xsl:attribute name="key"><xsl:value-of select="$label" /></xsl:attribute>
				</xsl:if>
				<xsl:value-of select="string-join($values, $separator)" />
			</xsl:element>
		</xsl:if>
	</xsl:function>


</xsl:stylesheet>