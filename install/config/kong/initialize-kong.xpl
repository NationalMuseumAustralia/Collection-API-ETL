<p:declare-step 
	name="initialize-kong"
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
	"service" is the API endpoint itself
	"route" is a kong endpoint which is proxied to the service.
	"consumer" is "associated with" individuals via an API key
	-->
	<!--
	create the service
	-->
	<kong:send name="create-service" method="post" uri="http://localhost:8001/services/">
		<p:input port="source">
			<p:inline>
				<map xmlns="http://www.w3.org/2005/xpath-functions">
					<string key="url">http://localhost:8080/xproc-z/</string>
					<string key="name">nma-api</string>
				</map>
			</p:inline>
		</p:input>
	</kong:send>
	<p:sink/>
	<kong:get name="get-service" uri="http://localhost:8001/services/nma-api"/>
	<!--
	create a route to the service
	-->
	<kong:send name="create-route" method="post" uri="http://localhost:8001/services/nma-api/routes">
		<p:input port="source">
			<p:inline>
				<map xmlns="http://www.w3.org/2005/xpath-functions">
					<array key="methods">
						<string>GET</string>
					</array>
				</map>
			</p:inline>
		</p:input>
	</kong:send>
	<p:sink/>
<!--

#need to add an anonymous consumer which the key-auth plugin can use when the api key is absent
post to  http://localhost:8001/consumers/
data 
	"username=anonymous"
	"custom_id=anonymous"

# returns {"custom_id":"anonymous","created_at":1524720140000,"username":"anonymous","id":"61c105a1-eae0-4b36-ad70-d24dd09ab566"}
-->
	<kong:send name="create-anonymous-user" method="post" uri="http://localhost:8001/consumers/">
		<p:input port="source">
			<p:inline>
				<map xmlns="http://www.w3.org/2005/xpath-functions">
					<string key="username">anonymous</string>
					<string key="custom_id">anonymous</string>
				</map>
			</p:inline>
		</p:input>
	</kong:send>
	<p:sink/>
	<!-- above may fail if 'anonymous' user already existed, but we can retrieve it now -->
	<kong:get name="get-anonymous-user" uri="http://localhost:8001/consumers/anonymous"/>	
<!--
#add the "key-auth" plugin to the service and configure it to use the "anonymous" consumer when api key absent
post to http://localhost:8001/services/nma-api/plugins/ 
data 'name=key-auth'
"config.anonymous=61c105a1-eae0-4b36-ad70-d24dd09ab566"

-->
	<p:template name="key-auth-plugin-with-anonymous-user-config">
		<p:with-param name="anonymous-user-id" select="/c:response/c:body/fn:map/fn:string[@key='id']"/>
		<p:with-param name="api-id" select="/c:response/c:body/fn:map/fn:string[@key='id']">
			<p:pipe step="get-service" port="result"/>
		</p:with-param>
		<p:input port="template">
			<p:inline>
				<map xmlns="http://www.w3.org/2005/xpath-functions">
					<string key="name">key-auth</string>
					<string key="service_id">{$api-id}</string>
					<map key="config">
						<string key="anonymous">{$anonymous-user-id}</string>
					</map>
				</map>
			</p:inline>
		</p:input>
	</p:template>
	<kong:send name="add-key-auth-plugin-with-anonymous-user" method="put" uri="http://localhost:8001/plugins/key-auth"/>
	<p:sink/>
	
	<kong:get name="get-nma-api-plugins" uri="http://localhost:8001/services/nma-api/plugins/"/>
	
	<kong:send name="configure-key-auth-plugin" method="patch">
		<p:with-option name="uri" select="
			concat(
				'http://localhost:8001/plugins/', 
				/c:response/c:body/fn:map/fn:array[@key='data']/fn:map[fn:string[@key='name']='key-auth']/fn:string[@key='id']
			)
		"/>
		<p:input port="source">
			<p:pipe step="key-auth-plugin-with-anonymous-user-config" port="result"/>
		</p:input>
	</kong:send>
	<p:sink/>
	
	<p:wrap-sequence name="collate-log-of-operations" wrapper="responses">
		<p:input port="source">
			<p:pipe step="create-service" port="log"/>
			<p:pipe step="get-service" port="log"/>
			<p:pipe step="create-route" port="log"/>
			<p:pipe step="create-anonymous-user" port="log"/>
			<p:pipe step="get-anonymous-user" port="log"/>
			<p:pipe step="add-key-auth-plugin-with-anonymous-user" port="log"/>
			<p:pipe step="get-nma-api-plugins" port="log"/>
			<p:pipe step="configure-key-auth-plugin" port="log"/>
		</p:input>
	</p:wrap-sequence>
	<p:store name="store-long" indent="true" href="/var/log/NMA-API-ETL/kong-config.xml"/>

	<p:declare-step name="send" type="kong:send">
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
		<p:xslt name="convert-to-xml">
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="stylesheet">
				<p:inline>
					<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" 
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
		<p:wrap-sequence name="log" wrapper="operation">
			<p:input port="source">
				<p:pipe step="create-request" port="result"/>
				<p:pipe step="convert-to-xml" port="result"/>
			</p:input>
		</p:wrap-sequence>
	</p:declare-step>
	
	<p:declare-step name="get" type="kong:get">
		<p:option name="uri" required="true"/><!-- e.g. "http://localhost:8001/consumers/" -->
		<p:output port="result" primary="true">
			<p:pipe step="convert-to-xml" port="result"/>
		</p:output>
		<p:output port="log">
			<p:pipe step="log" port="result"/>
		</p:output>
		<p:xslt name="create-request">
			<p:with-param name="uri" select="$uri"/>
			<p:input port="source"><p:inline><dummy/></p:inline></p:input>
			<p:input port="stylesheet">
				<p:inline>
					<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" 
						xmlns:f="http://www.w3.org/2005/xpath-functions"
						xmlns:map="http://www.w3.org/2005/xpath-functions/map">
						<xsl:param name="uri"/>
						<xsl:template match="/">
							<c:request
								method="get"
								detailed="true"
								override-content-type="text/plain"
								href="{$uri}"/>
						</xsl:template>
					</xsl:stylesheet>
				</p:inline>
			</p:input>
		</p:xslt>
		<!-- make http request -->
		<p:http-request/>
		<!-- convert result from json to xml -->
		<p:xslt name="convert-to-xml">
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="stylesheet">
				<p:inline>
					<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" 
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
		<p:wrap-sequence name="log" wrapper="operation">
			<p:input port="source">
				<p:pipe step="create-request" port="result"/>
				<p:pipe step="convert-to-xml" port="result"/>
			</p:input>
		</p:wrap-sequence>
	</p:declare-step>
	
</p:declare-step>