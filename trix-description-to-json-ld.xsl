<!-- 
Generate a JSON-LD document (starting from a specified root resource) with no context.
The JSON-LD is an expanded form, with URIs for identifiers, and will be compacted using a specific context in a subsequent step.
-->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:path="tag:conaltuohy.com,2018:nma/trix-path-traversal"
	xmlns:f="http://www.w3.org/2005/xpath-functions"
	xmlns:map="http://www.w3.org/2005/xpath-functions/map"
	xmlns:trix="http://www.w3.org/2004/03/trix/trix-1/">
	
	<xsl:param name="root-resource"/><!-- e.g. "http://nma-dev.conaltuohy.com/xproc-z/narrative/1758#" -->
	<xsl:variable name="graph" select="/trix:trix/trix:graph"/>
	
	<xsl:template match="/">
		<xsl:variable name="json-ld-in-xml">
			<xsl:call-template name="resource-as-json-ld-xml">
				<xsl:with-param name="resource" select="$root-resource"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:copy-of select="$json-ld-in-xml"/>
		<xsl:comment>
			<!-- see https://www.w3.org/TR/xpath-functions-31/#json-to-xml-mapping for definition of the elements used here -->
			<xsl:value-of select="xml-to-json($json-ld-in-xml, map{'indent':true()})"/>
		</xsl:comment>
	</xsl:template>
	
	<xsl:template name="resource-as-json-ld-xml">
		<xsl:param name="resource" required="true"/>
		<xsl:param name="already-rendered-resources" select="()"/>
		<xsl:param name="key" select="()"/>
		<f:map>
			<xsl:if test="$key">
				<xsl:attribute name="key" select="$key"/>
			</xsl:if>
			<f:string key="@id"><xsl:value-of select="$resource"/></f:string>
			<xsl:if test="not($resource = $already-rendered-resources)">
				<xsl:variable name="types" select="
					$graph/trix:triple
						[trix:uri[1]=$resource]
						[trix:uri[2]='http://www.w3.org/1999/02/22-rdf-syntax-ns#type']
							/trix:*[3]"/>
				<xsl:choose>
					<xsl:when test="count($types) = 0"/>
					<xsl:when test="count($types) = 1">
						<f:string key="@type"><xsl:value-of select="$types"/></f:string>
					</xsl:when>
					<xsl:otherwise>
						<f:array key="@type">
							<xsl:for-each select="$types">
								<f:string><xsl:value-of select="."/></f:string>
							</xsl:for-each>
						</f:array>
					</xsl:otherwise>
				</xsl:choose>
				<!--represent the resource's properties as JSON-LD XML -->
				<xsl:for-each-group select="$graph/trix:triple[*[1]=$resource]" group-by="*[2]">
					<xsl:choose>
						<xsl:when test="count(current-group()) = 1">
							<!--
							<xsl:comment>only one property with predicate <xsl:value-of select="*[2]"/></xsl:comment>
							<xsl:comment>property value is <xsl:value-of select="*[3]"/></xsl:comment>
							<xsl:comment>property type is <xsl:value-of select="local-name(*[3])"/></xsl:comment>
							-->
							<!-- property is either a resource or a literal -->
							<xsl:choose>
								<!-- property value is a resource -->
								<xsl:when test="*[3]/self::trix:uri | *[3]/self::trix:id"><!-- object identifier is URI or blank node -->
									<xsl:message><xsl:value-of select="concat('from ', $resource, ' to ', *[3])"/></xsl:message>
									<xsl:call-template name="resource-as-json-ld-xml">
										<xsl:with-param name="resource" select="*[3]"/>
										<xsl:with-param name="already-rendered-resources" select="$already-rendered-resources, $resource"/>
										<xsl:with-param name="key" select="*[2]"/>
									</xsl:call-template>
								</xsl:when>
								<!-- property value is a literal; treat all literals as strings for now -->
								<xsl:when test="*[3]/self::trix:plainLiteral | *[3]/self::trix:typedLiteral">
									<f:string key="{*[2]}"><xsl:value-of select="*[3]"/></f:string>
								</xsl:when>
							</xsl:choose>
						</xsl:when>
						<xsl:otherwise>
							<xsl:comment><xsl:value-of select="count(current-group())"/> properties with predicate <xsl:value-of select="*[2]"/></xsl:comment>
							<f:array key="{*[2]}">
								<xsl:for-each select="current-group()">
									<!-- property is either a resource or a literal -->
									<xsl:choose>
										<!-- property value is a resource -->
										<xsl:when test="*[3]/self::trix:uri | *[3]/self::trix:id"><!-- object identifier is URI or blank node -->
											<!-- <xsl:message><xsl:value-of select="concat('from ', $resource, ' to ', *[3])"/></xsl:message> -->
											<xsl:call-template name="resource-as-json-ld-xml">
												<xsl:with-param name="resource" select="*[3]"/>
												<xsl:with-param name="already-rendered-resources" select="$already-rendered-resources, $resource"/>
											</xsl:call-template>
										</xsl:when>
										<!-- property value is a literal; treat all literals as strings for now -->
										<xsl:when test="*[3]/self::trix:plainLiteral | *[3]/self::trix:typedLiteral">
											<f:string><xsl:value-of select="*[3]"/></f:string>
										</xsl:when>
									</xsl:choose>
								</xsl:for-each>
							</f:array>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:for-each-group>
			</xsl:if>
		</f:map>
	</xsl:template>

</xsl:stylesheet>
