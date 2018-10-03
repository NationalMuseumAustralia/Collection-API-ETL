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
	
	<xsl:import href="util/trix-traversal-functions.xsl" />
	<xsl:import href="util/compact-json-ld.xsl"/>
	
	<xsl:param name="root-resource"/><!-- e.g. "http://nma-dev.conaltuohy.com/xproc-z/narrative/1758#" -->
	<xsl:param name="debug">false</xsl:param>
	<xsl:variable name="graph" select="/trix:trix/trix:graph"/>
	
	<xsl:template match="/">
		<xsl:variable name="json-ld-in-xml">
			<xsl:call-template name="resource-as-json-ld-xml">
				<xsl:with-param name="resource" select="$root-resource"/>
				<xsl:with-param name="context" select=" '/context.json' "/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="compact-json-ld-in-xml">
			<xsl:apply-templates select="$json-ld-in-xml" mode="compact"/>
		</xsl:variable>
		<xsl:copy-of select="$compact-json-ld-in-xml"/>
		<!-- see https://www.w3.org/TR/xpath-functions-31/#json-to-xml-mapping for definition of the elements used here -->
	</xsl:template>
	
	<xsl:template name="resource-as-json-ld-xml">
		<xsl:param name="resource" required="true"/>
		<xsl:param name="depth" select="0"/>
		<xsl:param name="already-rendered-resources" select="()"/>
		<xsl:param name="key" select="()"/>
		<xsl:param name="context"/><!-- include the specified reference to a JSON-LD context -->
		<xsl:if test="$depth = 17">
			<xsl:message terminate="yes">Too many relationships traversed: 
				<xsl:value-of select="string-join(
					($already-rendered-resources, $resource), ', '
				)"/>
			</xsl:message>
		</xsl:if>
		<xsl:choose>
			<xsl:when test="not($graph/trix:triple/*[1][.=$resource])">
				<!-- resource has no properties -->
				<f:string>
					<xsl:if test="$key">
						<xsl:attribute name="key" select="$key"/>
					</xsl:if>
					<xsl:value-of select="$resource"/>
				</f:string>
			</xsl:when>
			<xsl:otherwise>
				<!-- resource has properties -->
				<f:map>
					<xsl:if test="$key">
						<xsl:attribute name="key" select="$key"/>
					</xsl:if>
					<xsl:if test="$context">
						<f:string key="@context"><xsl:value-of select="$context"/></f:string>
					</xsl:if>
					<!-- if the resource identifier appears inside a trix:uri then it is a URI rather than a blank node, and should be displayed -->
					<xsl:if test="$graph/trix:triple/*[1][self::trix:uri][.=$resource]">
						<f:string key="@id"><xsl:value-of select="$resource"/></f:string>
					</xsl:if>
					<xsl:if test="not($resource = $already-rendered-resources)">
						<xsl:variable name="types" select="
							$graph/trix:triple
								[*[1]=$resource]
								[*[2]='http://www.w3.org/1999/02/22-rdf-syntax-ns#type']
									/*[3]"/>
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
						<!--represent the resource's other properties (apart from rdf:type) as JSON-LD XML -->
						<xsl:for-each-group select="$graph/trix:triple[*[1]=$resource][not(*[2]='http://www.w3.org/1999/02/22-rdf-syntax-ns#type')]" group-by="string(*[2])">
							<xsl:sort select="*[2]"/>
							<xsl:choose>
								<xsl:when test="count(current-group()) = 1">
									<xsl:call-template name="debug">
										<xsl:with-param name="message" select="concat('property ', *[2], ' has a single value: ', *[3])"/>
									</xsl:call-template>
									<!--
									<xsl:comment>only one property with predicate <xsl:value-of select="*[2]"/></xsl:comment>
									<xsl:comment>property value is <xsl:value-of select="*[3]"/></xsl:comment>
									<xsl:comment>property type is <xsl:value-of select="local-name(*[3])"/></xsl:comment>
									-->
									<!-- property is either a resource or a literal -->
									<xsl:choose>
										<!-- property value is a resource -->
										<xsl:when test="*[3]/self::trix:uri | *[3]/self::trix:id"><!-- object identifier is URI or blank node -->
											<xsl:call-template name="debug">
												<xsl:with-param name="message" select="concat('from ', $resource, ' to ', *[3])"/>
											</xsl:call-template>
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
									<xsl:call-template name="debug">
										<xsl:with-param name="message" select="concat('property ', *[2], ' has ', count(current-group()), ' values')"/>
									</xsl:call-template>
									<f:array key="{*[2]}">
										<xsl:for-each select="current-group()">
											<xsl:sort select="*[3]"/>
											<!-- property is either a resource or a literal -->
											<xsl:choose>
												<!-- property value is a resource -->
												<xsl:when test="*[3]/self::trix:uri | *[3]/self::trix:id"><!-- object identifier is URI or blank node -->
													<xsl:call-template name="debug">
														<xsl:with-param name="message" select="concat('from ', $resource, ' to ', *[3])"/>
													</xsl:call-template>
													<xsl:call-template name="resource-as-json-ld-xml">
														<xsl:with-param name="resource" select="*[3]"/>
														<xsl:with-param name="already-rendered-resources" select="$already-rendered-resources, $resource"/>
														<xsl:with-param name="depth" select="$depth + 1"/>
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
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="debug">
		<xsl:param name="message"/>
		<xsl:if test="$debug = 'true'">
			<xsl:message><xsl:value-of select="$message"/></xsl:message>
		</xsl:if>
	</xsl:template>
</xsl:stylesheet>
