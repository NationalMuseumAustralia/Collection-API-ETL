<p:declare-step 
	name="backup-credentials"
	version="1.0" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:fn="http://www.w3.org/2005/xpath-functions" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:nma="tag:conaltuohy.com,2018:nma"
	xmlns:kong="tag:conaltuohy.com,2018:kong"
	xmlns:pxf="http://exproc.org/proposed/steps/file"
	xmlns:cx="http://xmlcalabash.com/ns/extensions"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
>
	<!-- import calabash extension library to enable use of file steps -->
	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
	<!--
	<p:import href="kong-library.xpl"/>
	-->
	<!-- report -->
	<!--
	<p:output port="result"/>
	-->
	
	<!-- URI of input file -->
	<p:option name="input" required="true"/>
	
	<!-- read the backed up credentials file -->
	<p:load name="credential-backup">
		<p:with-option name="href" select="$input"/>
	</p:load>
	
	<!-- transform the backed up credential data into a series of HTTP request specifications for restoring the credentials -->
	<p:xslt name="transform-credentials-into-restore-commands">
		<p:input port="parameters"><p:empty/></p:input>
		<p:input port="stylesheet">
			<p:inline>
				<xsl:stylesheet version="3.0"
					xmlns:xsl="http://www.w3.org/1999/XSL/Transform"  
					xmlns:fn="http://www.w3.org/2005/xpath-functions"
					xmlns:c="http://www.w3.org/ns/xproc-step">
					
					<xsl:variable name="consumers" select="/credential-backup/c:response[1]/c:body/fn:map/fn:array[@key='data']/fn:map"/>
					<xsl:variable name="acls" select="/credential-backup/c:response[2]/c:body/fn:map/fn:array[@key='data']/fn:map"/>
					<xsl:variable name="keys" select="/credential-backup/c:response[3]/c:body/fn:map/fn:array[@key='data']/fn:map"/>
					
					<xsl:template match="/credential-backup">
						<credential-restore>
							<!-- restore consumers -->
							<consumers>
								<xsl:for-each select="$consumers">
									<xsl:variable name="consumer-id" select="fn:string[@key='id']"/>
									<c:request href="http://localhost:8001/consumers/{$consumer-id}" method="put" override-content-type="text/plain">
										<xsl:variable name="consumer">
											<xsl:apply-templates select="." mode="consumer"/>
										</xsl:variable>
										<c:body content-type="application/json">
											<xsl:sequence select="xml-to-json($consumer)"/>
										</c:body>
									</c:request>
								</xsl:for-each>
							</consumers>
							<!-- restore acls -->
							<acls>
								<xsl:for-each select="$acls">
									<xsl:variable name="user-group" select="fn:string[@key='group']"/>
									<xsl:variable name="consumer-id" select="fn:string[@key='consumer_id']"/>
									<c:request href="http://localhost:8001/consumers/{$consumer-id}/acls" method="post" override-content-type="text/plain">
										<c:body content-type="application/json">
											<xsl:variable name="acl">
												<xsl:apply-templates select="." mode="acl"/>
											</xsl:variable>
											<xsl:sequence select="xml-to-json($acl)"/>
										</c:body>
									</c:request>
								</xsl:for-each>
							</acls>
							<!-- restore keys -->
							<keys>
								<xsl:for-each select="$keys">
									<xsl:variable name="consumer-id" select="fn:string[@key='consumer_id']"/>
									<c:request href="http://localhost:8001/consumers/{$consumer-id}/key-auth" method="post" override-content-type="text/plain">
										<c:body content-type="application/json">
											<xsl:variable name="key">
												<xsl:apply-templates select="." mode="key"/>
											</xsl:variable>
											<xsl:sequence select="xml-to-json($key)"/>
										</c:body>
									</c:request>
								</xsl:for-each>
							</keys>
						</credential-restore>
					</xsl:template>
					
					<xsl:mode name="consumer" on-no-match="shallow-copy"/>
					<!-- delete any backed-up 'created_at' field since we are creating this consumer anew -->
					<xsl:template mode="consumer" match="fn:number[@key='created_at']"/>
					
					<xsl:mode name="acl" on-no-match="shallow-copy"/>
					<xsl:template mode="acl" match="fn:map">
						<xsl:copy>
							<xsl:copy-of select="fn:string[@key='group']"/>
						</xsl:copy>
					</xsl:template>
	
					<xsl:mode name="key" on-no-match="shallow-copy"/>
					<xsl:template mode="key" match="fn:map">
						<xsl:copy>
							<xsl:copy-of select="fn:string[@key='key']"/>
						</xsl:copy>
					</xsl:template>
				</xsl:stylesheet>
			</p:inline>
		</p:input>
	</p:xslt>
	
	
	<!-- make the API calls to import the data -->
	<p:viewport name="api-call" match="/credential-restore//c:request">
		<p:viewport-source>
			<p:pipe step="transform-credentials-into-restore-commands" port="result"/>
		</p:viewport-source>
		<p:http-request/>
	</p:viewport>
	
	<!-- output details of the operation -->
	<p:store href="credential-restore-requests.xml" indent="true">
		<p:input port="source">
			<p:pipe step="transform-credentials-into-restore-commands" port="result"/>
		</p:input>
	</p:store>
	<p:store href="credential-restore-results.xml" indent="true">
		<p:input port="source">
			<p:pipe step="api-call" port="result"/>
		</p:input>
	</p:store>
	
</p:declare-step>