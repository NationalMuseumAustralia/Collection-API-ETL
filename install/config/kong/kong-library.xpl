<p:library version="1.0" 
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
	
<p:declare-step name="get-api-key" type="nma:get-api-key">
		<p:output port="result"/>
		<p:option name="name" required="true"/>
		<p:option name="email" required="true"/>
		<p:option name="user-group" required="true"/>
		<!-- first create a consumer (user) -->
		<!-- 
		Kong username is a unique id, which needs to be unique even if the name/email/user-group combo is not,
		because a single user may wish to mint different API keys with the same security level for different apps.
		The username needs to include some identifying characteristic to support logging and admin. TODO: check if that's true.
		For uniqueness, the name also includes a random code.
		-->
		<p:variable name="random-id" select="current-dateTime()"/>
		<p:variable name="username" select="
			concat(
				$name,
				' &lt;', 
				$email, 
				'(', 
				$user-group,
				' [',
				$random-id,
				'])&gt;'
			)
		"/>
		<p:template name="create-user-request">
			<p:with-param name="username" select="$username"/>
			<p:input port="source"><p:empty/></p:input>
			<p:input port="template">
				<p:inline>
					<fn:map>
						<fn:string key="username">{$username}</fn:string>
						<fn:string key="custom_id">{$username}</fn:string>
					</fn:map>
				</p:inline>
			</p:input>
		</p:template>
		<kong:write name="create-user" method="post" uri="http://localhost:8001/consumers/"/>
		<p:sink/>
		<!-- above may fail if  user already existed, but we can retrieve it now -->
		<kong:read name="get-consumer" cx:depends-on="create-user-request">
			<p:with-option name="uri" select="
				concat(
					'http://localhost:8001/consumers/?custom_id=',
					encode-for-uri($username)
				)
			"/>
		</kong:read>
		<!-- specify the appropriate user group for the new user -->
		<p:template name="specify-user-group">
			<p:with-param name="user-group" select="$user-group"/>
			<p:input port="source"><p:empty/></p:input>
			<p:input port="template">
				<p:inline>
					<map xmlns="http://www.w3.org/2005/xpath-functions">
						<string key="group">{$user-group}</string>
					</map>
				</p:inline>
			</p:input>
		</p:template>
		<cx:message>
			<p:with-option name="message" select="
				concat(
					'Adding ',
					$email,
					' to user group ',
					/fn:map/fn:string[@key='group']
				)
			"/>
		</cx:message>
		<kong:write name="add-new-user-to-specified-group" method="post">
			<p:with-option name="uri" select="
				concat(
					'http://localhost:8001/consumers/', 
					/c:response/c:body/fn:map/fn:array[@key='data']/fn:map[1]/fn:string[@key='id'],
					'/acls'
				)
			">
				<p:pipe step="get-consumer" port="result"/>
			</p:with-option>
		</kong:write>
		<p:sink/>
		<!-- for debugging, log the requests -->
		<!--
		<p:store href="/tmp/create-user.xml" indent="true">
			<p:input port="source">
				<p:pipe step="create-user" port="log"/>
			</p:input>
		</p:store>
		<p:store href="/tmp/get-consumer.xml" indent="true">
			<p:input port="source">
				<p:pipe step="get-consumer" port="log"/>
			</p:input>
		</p:store>
		<p:store href="/tmp/add-new-user-to-specified-group.xml" indent="true">
			<p:input port="source">
				<p:pipe step="add-new-user-to-specified-group" port="log"/>
			</p:input>
		</p:store>
		-->
		<!-- mint an API key for the user (NB kong:read is used instead of kong:write because there's no data to send) -->
		<kong:write name="add-key-to-consumer" method="post">
			<p:with-option name="uri" select="
				concat(
					'http://localhost:8001/consumers/', 
					/c:response/c:body/fn:map/fn:array[@key='data']/fn:map[1]/fn:string[@key='id'],
					'/key-auth'
				)
			">
				<p:pipe step="get-consumer" port="result"/>
			</p:with-option>
			<p:input port="source">
				<p:inline>
					<fn:map>
						<!-- an empty map is required here since HTTP POST implies a request payload -->
					</fn:map>
				</p:inline>
			</p:input>
		</kong:write>
		<!-- expect: 
		{
			 "consumer_id": "876bf719-8f18-4ce5-cc9f-5b5af6c36007",
			 "created_at": 1443371053000,
			 "id": "62a7d3b7-b995-49f9-c9c8-bac4d781fb59",
			 "key": "62eb165c070a41d5c1b58d9d3d725ca1"
		}
		-->	
	</p:declare-step>
	
	<p:declare-step name="process-signup" type="nma:process-signup">
		<p:option name="maximum-key-security" select=" 'public' "/><!-- do not mint 'internal' keys if $maximum-key-security is 'public' -->
		<p:input port="fields"/>
		<p:output port="result"/>
		<!-- get data from posted form fields -->
		<p:variable name="email" select="/c:param-set/c:param[@name='email']/@value"/>
		<p:variable name="name" select="
			string-join(
				(
					/c:param-set/c:param[@name='first-name']/@value,
					/c:param-set/c:param[@name='last-name']/@value
				),
				' '
			)
		"/>
		<p:variable name="user-group"  select="
			if ($maximum-key-security='internal') then 
				/c:param-set/c:param[@name='user-group']/@value
			else 
				'public' 
		"/>
		
		<!--		<cx:message message="getting API key ..."/>-->
		<nma:get-api-key name="api-key">
			<p:with-option name="name" select="$name"/>
			<p:with-option name="email" select="$email"/>
			<p:with-option name="user-group" select="$user-group"/>
		</nma:get-api-key>
		<p:sink/>
		<!--
		<cx:message message="retrieved API key"/>
		<p:store href="/tmp/api-key.xml" indent="true"/>
		-->
		<!--
		<kong:read uri="http://localhost:8001/consumers/"/>
		<p:store href="/tmp/kong-consumers.xml" indent="true"/>
		-->
		<p:template name="email-response">
			<p:input port="parameters">
				<p:pipe step="process-signup" port="fields"/>
			</p:input>
			<p:input port="source">
				<p:pipe step="api-key" port="result"/>
			</p:input>
			<p:input port="template">
				<p:inline>
					<html xmlns="http://www.w3.org/1999/xhtml" xmlns:fn="http://www.w3.org/2005/xpath-functions">
						<head>
							<title>API Key Registration Complete</title>
							<style type="text/css">
								body {{
									font-family: Calibri, Helvetica, Arial, sans-serif;
									font-size: 11pt;
								}}
								h1 {{
									font-size: 12pt;
								}}
								img {{
									border: none;
								}}
								.label {{
									font-weight: bold;
								}}
							</style>
						</head>
						<body>
							<img src="http://collectionsearch.nma.gov.au/sites/all/themes/cs/logo.png" alt="National Museum of Australia"/>
							<p>Thank you for registering for an API key. Your key is:</p>
							<p><code>{/c:response/c:body/fn:map/fn:string[@key='key']}</code></p>
							<p>To get started, <a href="https://github.com/NationalMuseumAustralia/Collection-API/wiki/Getting-started">view the documentation on GitHub</a>.</p>
							<h1>Registration details</h1>
							<p><span class="label">First name:</span> {$first-name}</p>
							<p><span class="label">Last name:</span> {$last-name}</p>
							<p><span class="label">Organisation:</span> {$organisation}</p>
							<p><span class="label">Email:</span> {$email}</p>
							<p><span class="label">User group:</span> {$user-group}</p>
							<p><span class="label">Use of the API:</span> {$use}</p>
							<p><span class="label">Website:</span> {$website}</p>
							<p>We hope you enjoy using the API. Please let us know how you are using it, or email feedback or questions to <a href="mailto:api@nma.gov.au">api@nma.gov.au</a>.</p>
							<p>National Museum of Australia<br/>Collection API</p>
						</body>
					</html>		
				</p:inline>
			</p:input>
		</p:template>
		<!--
		<nma:send-email 
			from="National Museum of Australia &lt;api@nma.gov.au&gt;" 
			bcc="National Museum of Australia &lt;api@nma.gov.au&gt;" 
			subject="Collection API key">
			<p:with-option name="to" select="concat($name, ' &lt;', $email, '&gt;') "/>
			<p:input port="source">
				<p:pipe step="email-response" port="result"/>
			</p:input>
		</nma:send-email>
		-->
		<!-- Create response web page -->
		<p:identity name="http-response">
			<p:input port="source">
				<p:inline>
					<c:response status="303">
						<c:header name="location" value="http://www.nma.gov.au/collections/api/thankyou"/>
					</c:response>
				</p:inline>
			</p:input>
		</p:identity>
	</p:declare-step>
	
<p:declare-step name="read" type="kong:read">
		<p:option name="uri" required="true"/><!-- e.g. "http://localhost:8001/consumers/" -->
		<p:option name="method" select=" 'get' "/><!-- default HTTP method for reading is 'get' -->
		<p:output port="result" primary="true">
			<p:pipe step="convert-to-xml" port="result"/>
		</p:output>
		<p:output port="log">
			<p:pipe step="log" port="result"/>
		</p:output>
		<p:xslt name="create-request">
			<p:with-param name="uri" select="$uri"/>
			<p:with-param name="method" select="$method"/>
			<p:input port="source"><p:inline><dummy/></p:inline></p:input>
			<p:input port="stylesheet">
				<p:inline>
					<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" 
						xmlns:c="http://www.w3.org/ns/xproc-step" 
						xmlns:f="http://www.w3.org/2005/xpath-functions"
						xmlns:map="http://www.w3.org/2005/xpath-functions/map">
						<xsl:param name="uri"/>
						<xsl:param name="method"/>
						<xsl:template match="/">
							<c:request
								method="{$method}"
								detailed="true"
								override-content-type="text/plain"
								href="{$uri}"/>
						</xsl:template>
					</xsl:stylesheet>
				</p:inline>
			</p:input>
		</p:xslt>
		<!--
		<p:store href="/tmp/kong-read-request.xml"/>
		<p:identity>
			<p:input port="source">
				<p:pipe step="create-request" port="result"/>
			</p:input>
		</p:identity>
		-->
		<!-- make http request -->
		<p:http-request/>
		<!-- convert result from json to xml -->
		<kong:json-to-xml name="convert-to-xml"/>
		<p:wrap-sequence name="log" wrapper="operation">
			<p:input port="source">
				<p:pipe step="create-request" port="result"/>
				<p:pipe step="convert-to-xml" port="result"/>
			</p:input>
		</p:wrap-sequence>
	</p:declare-step>
	
	<p:declare-step name="write" type="kong:write">
		<p:option name="uri" required="true"/><!-- e.g. "http://localhost:8001/consumers/" -->
		<p:option name="method" required="true"/>
		<p:input port="source"/>
		<p:output port="result" primary="true">
			<p:pipe step="convert-to-xml" port="result"/>
		</p:output>
		<p:output port="log">
			<p:pipe step="log" port="result"/>
		</p:output>
		<p:xslt name="create-request">
			<p:with-param name="uri" select="$uri"/>
			<p:with-param name="method" select="$method"/>
			<p:input port="stylesheet">
				<p:inline>
					<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" 
						xmlns:c="http://www.w3.org/ns/xproc-step" 
						xmlns:f="http://www.w3.org/2005/xpath-functions"
						xmlns:map="http://www.w3.org/2005/xpath-functions/map">
						<xsl:param name="uri"/>
						<xsl:param name="method"/>
						<xsl:template match="/">
							<c:request
								method="{$method}"
								detailed="true"
								override-content-type="text/plain"
								href="{$uri}">
								<c:body content-type="application/json">
									<xsl:copy-of select="xml-to-json(*)"/>
								</c:body>
							</c:request>
						</xsl:template>
					</xsl:stylesheet>
				</p:inline>
			</p:input>
		</p:xslt>
		<!-- make http request -->
		<p:http-request/>
		<!-- convert result from json to xml -->
		<kong:json-to-xml name="convert-to-xml"/>
		<p:wrap-sequence name="log" wrapper="operation">
			<p:input port="source">
				<p:pipe step="create-request" port="result"/>
				<p:pipe step="convert-to-xml" port="result"/>
			</p:input>
		</p:wrap-sequence>
	</p:declare-step>

	<p:declare-step name="json-to-xml" type="kong:json-to-xml">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:xslt name="convert-to-xml">
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="stylesheet">
				<p:inline>
					<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" 
						xmlns:c="http://www.w3.org/ns/xproc-step" 
						xmlns:f="http://www.w3.org/2005/xpath-functions"
						xmlns:map="http://www.w3.org/2005/xpath-functions/map">
						<xsl:template match="*">
							<xsl:copy>
								<xsl:copy-of select="@*"/>
								<xsl:apply-templates/>
							</xsl:copy>
						</xsl:template>
						<xsl:template match="c:body">
							<xsl:copy>
								<xsl:copy-of select="json-to-xml(.)"/>
							</xsl:copy>
						</xsl:template>
					</xsl:stylesheet>
				</p:inline>
			</p:input>
		</p:xslt>
	</p:declare-step>	
</p:library>