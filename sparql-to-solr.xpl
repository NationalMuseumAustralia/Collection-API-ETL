<p:declare-step 
	version="1.0" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:fn="http://www.w3.org/2005/xpath-functions" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:nma="tag:conaltuohy.com,2018:nma"
	xmlns:pxf="http://exproc.org/proposed/steps/file"
	xmlns:cx="http://xmlcalabash.com/ns/extensions"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:results="http://www.w3.org/2005/sparql-results#"
>
	<!-- import calabash extension library to enable use of file steps -->
	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>

	
	<!-- update Solr store by querying the SPARQL store -->
	<nma:sparql-query name="physical-objects-for-solr" output="xml" dataset="public">
		<p:input port="source">
			<p:inline>
				<!-- TODO replace this query with one which returns only resources which have been updated since a particular time -->
				<query>
<![CDATA[
PREFIX crm: <http://www.cidoc-crm.org/cidoc-crm/>
select ?resource
where {?resource a crm:E19_Physical_Object}	
]]>
				</query>
			</p:inline>
		</p:input>
	</nma:sparql-query>
	<p:store href="/data/updated-resources.xml"/>

	<p:for-each name="physical-object">
		<p:iteration-source select="/results:sparql/results:results/results:result[2]">
			<p:pipe step="physical-objects-for-solr" port="result"/>
		</p:iteration-source>
		<!-- generate description for this physical object -->
		<p:variable name="physical-object-uri" select="/results:result/results:binding/results:uri"/>	
		<cx:message>
			<p:with-option name="message" select="concat('Querying SPARQL store for ', $physical-object-uri, ' ...')"/>
		</cx:message>
		<p:xslt name="generate-sparql-query">
			<p:with-param name="resource-uri" select="$physical-object-uri"/>
			<p:input port="source">
				<!-- TODO replace this DESCRIBE query with a more specific CONSTRUCT query that explicitly requests all the desired properties -->
				<p:inline>
					<query>
<![CDATA[
describe «resource-uri»
]]>
					</query>
				</p:inline>			
			</p:input>
			<p:input port="stylesheet">
				<p:document href="substitute-resource-uri-into-query.xsl"/>
			</p:input>
		</p:xslt>
		<!-- execute the query to generate a resource description -->
		<nma:sparql-query name="resource-description" dataset="public" output="json"/>
		<p:store href="/tmp/description.xml"/>
	</p:for-each>
	
	<p:declare-step type="nma:sparql-query" name="sparql-query">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:option name="dataset" required="true"/>
		<p:option name="output" select="'xml'"/>
		<p:in-scope-names name="parameters"/>
		<p:template name="generate-http-request">
			<p:input port="source">
				<p:pipe step="sparql-query" port="source"/>
			  </p:input>
			<p:input port="parameters">
				<p:pipe step="parameters" port="result"/>
			</p:input>
			<p:input port="template">
				<p:inline>
					<c:request method="POST" href="http://localhost:8080/fuseki/{$dataset}/query">
						<c:body content-type="application/x-www-form-urlencoded">{
							concat(
								'query=', encode-for-uri(/),
								'&amp;output=', $output
							)
						}</c:body>
					</c:request>
				</p:inline>
			</p:input>
		</p:template>
		<p:http-request/>
	</p:declare-step>	
</p:declare-step>