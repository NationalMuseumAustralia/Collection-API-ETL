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
	<p:import href="kong-library.xpl"/>

	<!-- enable the ACL plugin for the service, defining two user groups "public" and "internal" -->
	<!-- 
		"This plugin requires an authentication plugin to have been already enabled on the Service or the Route" 
		from: https://docs.konghq.com/plugins/acl/ 
	-->
	<kong:send name="add-acl-plugin" method="post" uri="http://localhost:8001/services/nma-api/plugins">
		<p:input port="source">
			<p:inline>
				<map xmlns="http://www.w3.org/2005/xpath-functions">
					<string key="name">acl</string>
					<map key="config">
						<array key="allow">
							<string>public</string>
							<string>internal</string>
						</array>
					</map>
				</map>
			</p:inline>
		</p:input>		
	</kong:send>
	<p:sink/>
	
	<!-- add the "anonymous" user to the "public" user group -->
	<kong:send name="add-anonymous-user-to-internal-group" method="post" uri="http://localhost:8001/consumers/anonymous/acls">
		<p:input port="source">
			<p:inline>
				<map xmlns="http://www.w3.org/2005/xpath-functions">
					<string key="group">public</string>
				</map>
			</p:inline>
		</p:input>
	</kong:send>
	<p:sink/>
	
	<!-- enable API key-based authentication -->
	<!-- list the API's plugin configurations so we can update the "key-auth" one -->
	<!--
	<kong:get name="get-nma-api-plugins" uri="http://localhost:8001/services/nma-api/plugins/"/>
	-->
	<!-- get the identifier of the key-auth plugin configuration, and patch it with the predefined configuration -->
	<!--
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
	-->
	
	<!-- collate the logged operations into a log file and save it -->
	<p:wrap-sequence name="collate-log-of-operations" wrapper="responses">
		<p:input port="source">
			<p:pipe step="create-service" port="log"/>
			<p:pipe step="get-service" port="log"/>
			<p:pipe step="create-route" port="log"/>
			<p:pipe step="create-anonymous-user" port="log"/>
			<p:pipe step="get-anonymous-user" port="log"/>
			<p:pipe step="add-key-auth-plugin-with-anonymous-user" port="log"/>
			<p:pipe step="add-acl-plugin" port="log"/>
			<p:pipe step="add-anonymous-user-to-internal-group" port="log"/>
			<p:pipe step="throttle-anonymous-user" port="log"/>
			<!--
			<p:pipe step="get-nma-api-plugins" port="log"/>
			<p:pipe step="configure-key-auth-plugin" port="log"/>
			-->
		</p:input>
	</p:wrap-sequence>
	<p:store name="store-long" indent="true" href="/var/log/NMA-API-ETL/kong-config.xml"/>
	
</p:declare-step>