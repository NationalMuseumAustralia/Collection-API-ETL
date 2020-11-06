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
	xmlns:fn="http://www.w3.org/2005/xpath-functions" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:nma="tag:conaltuohy.com,2018:nma"
	xmlns:pxf="http://exproc.org/proposed/steps/file"
	xmlns:cx="http://xmlcalabash.com/ns/extensions"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
>
	<!-- import calabash extension library to enable use of file steps -->
	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
	
	<p:option name="dataset" required="true"/>
	
	<p:exec name="read-hostname" command="hostname" result-is-xml="false">
		<p:input port="source">
			<!-- the linux "hostname" command will not be sent any input -->
			<p:empty/>
		</p:input>
	</p:exec>
	<p:group>
		<!-- capture the hostname so we can make URIs relative to this host -->
		<p:variable name="hostname" select="normalize-space(/)"/>
		<p:sink name="discard-hostname"/>

		<!-- Execute an HTTP POST to update the Fuseki dataset to include "preferred" Piction images -->
		<!-- This query ensures that all objects with images have at least one image with a type of "preferred" -->
		<!-- which allows client applications to pick an appropriate image to depict an object. -->
		<!-- Many images are already explicitly tagged in Piction as preferred, but the "preferred" flag is -->
		<!-- here assigned purely arbitrarily. -->
		<p:template name="generate-post-request">
			<p:with-param name="hostname" select="$hostname"/>
			<p:with-param name="dataset" select="$dataset"/>
			<p:input port="source"><p:empty/></p:input>
			<p:input port="template">
				<p:inline>
					<c:request method="POST" href="http://localhost:8080/fuseki/{$dataset}/update" detailed="true">
						<c:body content-type="application/sparql-update">
							# update the dataset to include the preferred image flag
							prefix nma: &lt;http://{$hostname}/term/&gt;
							prefix crm: &lt;http://www.cidoc-crm.org/cidoc-crm/&gt;
							insert {{
								graph ?graph {{
									?preferred_image crm:P2_has_type nma:preferred.
								}}
							}}
							where {{
								select (min(?image) as ?preferred_image) ?graph 
								where {{
									?image crm:P2_has_type nma:piction-image.
									?object a crm:E19_Physical_Object.
									?object crm:P2_has_type ?some_object_type.
									?image a crm:E36_Visual_Item.
									?object crm:P138i_has_representation ?image.
									?image crm:P70i_is_documented_in ?graph.
									not exists{{
										?image crm:P2_has_type nma:preferred
									}}
								}}
								group by ?object ?graph
							}}
						</c:body>
					</c:request>
				</p:inline>
			</p:input>
		</p:template>
		
		<cx:message message="Adding 'preferred' flags to Piction images, where needed..."/>
		<p:http-request name="http-post"/>
		<cx:message>
			<p:with-option name="message" select="
				concat(
					if (/c:response/@status='204') then 
						'SUCCESS: '
					else
						'ERROR: ',
					'Fuseki returned an HTTP ', /c:response/@status, ' response. '
				)
			"/>
		</cx:message>
		<p:store href="/tmp/last-sparql-update-response.xml" indent="true"/>
		<p:store href="/tmp/last-sparql-update-request.xml" indent="true">
			<p:input port="source">
				<p:pipe step="generate-post-request" port="result"/>
			</p:input>
		</p:store>
	</p:group>
	
</p:declare-step>
