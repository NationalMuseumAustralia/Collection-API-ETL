<?xml version="1.0"?>
<!--
   Copyright 2018 Conal Tuohy

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
-->
<p:declare-step 
	version="1.0" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:tomcat="http://tomcat.apache.org/xml"
>
	<p:output port="result"/>
	<p:option name="command" required="true"/>
	<p:load href="/var/lib/tomcat8/conf/tomcat-users.xml"/>
	<p:template name="tomcat-manager-request">
		<p:with-param name="command" select="$command"/>
		<p:input port="template">
			<p:inline>
				<c:request 
					href="http://localhost:8080/manager/text/{$command}" 
					auth-method="basic"
					username="admin"
					password="{/tomcat:tomcat-users/tomcat:user[@username='admin']/@password}"
					method="get"
				/>
			</p:inline>
		</p:input>
	</p:template>
	<p:http-request/>
	
</p:declare-step>
