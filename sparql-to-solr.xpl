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

	<!-- generate a Solr index of media -->
	<nma:index-resources name="index-media" list-query="list-media.rq" describe-query="describe-media.rq"/>

	<!-- generate a Solr index of places -->
	<nma:index-resources name="index-places" list-query="list-places.rq" describe-query="describe-places.rq"/>

	<!-- generate a Solr index of parties -->
	<nma:index-resources name="index-parties" list-query="list-parties.rq" describe-query="describe-parties.rq"/>
	
	<!-- generate a Solr index for physical objects -->
	<nma:index-resources name="index-physical-objects" list-query="list-objects.rq" describe-query="describe-objects.rq"/>
	
	
	<!-- load a (non-XML) sparql query from disk -->
	<p:declare-step type="nma:load-sparql-query" name="load-sparql-query">
		<p:option name="query-file" required="true"/>
		<p:output port="result"/>
		<p:template name="sparql-list-query-load-request"><!-- a request to load the file from disk -->
			<p:with-param name="query-file" select="$query-file"/>
			<p:input port="source"><p:empty/></p:input>
			<p:input port="template">
				<p:inline>
					<c:request href="{encode-for-uri($query-file)}" method="get" override-content-type="text/plain"/>
				</p:inline>
			</p:input>
		</p:template>
		<p:http-request/>
	</p:declare-step>
	
	<!-- generates a Solr index for resources which match a particular SPARQL query, from a resource description given by another SPARQL query template -->
	<p:declare-step type="nma:index-resources" name="index-resources">
		<!-- names of files containing the sparql queries to list, and to describe, entities of a particular type -->
		<p:option name="list-query" required="true"/>
		<p:option name="describe-query" required="true"/>
		<!-- load the non-XML sparql queries from file system -->
		<nma:load-sparql-query name="resource-list-sparql-query">
			<p:with-option name="query-file" select="$list-query"/>
		</nma:load-sparql-query>
		<nma:load-sparql-query name="resource-description-sparql-query">
			<p:with-option name="query-file" select="$describe-query"/>
		</nma:load-sparql-query>
		<!-- execute the query to list all the resources to be indexed -->
		<nma:sparql-query name="resources-to-index" accept="application/sparql-results+xml" dataset="public">
			<p:input port="source">
				<p:pipe step="resource-list-sparql-query" port="result"/>
			</p:input>
		</nma:sparql-query>
		<!-- iterate through the resources, indexing each one individually -->
		<p:for-each name="resource">
			<p:iteration-source select="/results:sparql/results:results/results:result[1]">
				<p:pipe step="resources-to-index" port="result"/>
			</p:iteration-source>
			<!-- generate description for this resource -->
			<p:variable name="resource-uri" select="/results:result/results:binding/results:uri"/>
			<cx:message>
				<p:with-option name="message" select="concat('Querying SPARQL store for ', $resource-uri, ' ...')"/>
			</cx:message>
			<!-- substitute the URI of the resource to be indexed into the query template -->
			<p:xslt name="generate-sparql-query">
				<p:with-param name="resource-uri" select="$resource-uri"/>
				<p:input port="source">
					<p:pipe step="resource-description-sparql-query" port="result"/>
				</p:input>
				<p:input port="stylesheet">
					<p:document href="substitute-resource-uri-into-query.xsl"/>
				</p:input>
			</p:xslt>
			<!-- execute the query to generate a resource description -->
			<nma:sparql-query name="resource-description" dataset="public" accept="application/trix+xml"/>
			<!-- transform the RDF graph into a Solr index update -->
			<p:xslt name="trix-description-to-solr-doc">
				<p:input port="stylesheet">
					<p:document href="trix-description-to-solr.xsl"/>
				</p:input>
				<p:with-param name="root-resource" select="$resource-uri"/>
				<p:with-param name="dataset" select=" 'public' "/>
			</p:xslt>
			<!-- convert the JSON-XML blobs into JSON before deposit in Solr -->
			<p:try name="json-xml-to-json">
				<p:group>
					<p:output port="result"/>
					<p:xslt>
						<p:input port="parameters"><p:empty/></p:input>
						<p:input port="stylesheet">
							<p:document href="json-xml-to-json.xsl"/>
						</p:input>
					</p:xslt>
				</p:group>
				<p:catch name="json-xml-could-not-be-serialized-as-json-string">
					<p:output port="result"/>
					<cx:message message="json xml could not be serialized as a json string"/>
					<p:xslt name="serialize-json-xml-as-xml-string">
						<p:input port="parameters"><p:empty/></p:input>
						<p:input port="source">
							<p:pipe step="trix-description-to-solr-doc" port="result"/>
						</p:input>
						<p:input port="stylesheet">
							<p:inline>
								<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" >
									<xsl:template match="*">
										<xsl:copy>
											<xsl:copy-of select="@*"/>
											<xsl:apply-templates/>
										</xsl:copy>
									</xsl:template>
									<xsl:template match="field[@name='simple']/*">
										<xsl:value-of select="serialize(., map{'indent':true()})"/>
									</xsl:template>
									<xsl:template match="field[@name='type']/text()">
										<xsl:text>json-error</xsl:text>
									</xsl:template>
								</xsl:stylesheet>
							</p:inline>
						</p:input>
					</p:xslt>
				</p:catch>
			</p:try>
			<p:store href="/tmp/solr.xml" indent="true"/>
			<!-- execute the Solr index update -->
			<p:http-request name="solr-deposit">
				<p:input port="source">
					<p:pipe step="json-xml-to-json" port="result"/>
				</p:input>
			</p:http-request>
			<p:for-each name="error-response">
				<p:iteration-source select="/c:response[number(@status) &gt;= 400]"/>
				<p:store href="/tmp/last-solr-error.xml" indent="true"/>
			</p:for-each>
			<p:store href="/tmp/description.xml" indent="true">
				<p:input port="source">
					<p:pipe step="resource-description" port="result"/>
				</p:input>
			</p:store>
		</p:for-each>	
	</p:declare-step>
		
	<p:declare-step type="nma:sparql-query" name="sparql-query">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:option name="dataset" required="true"/>
		<p:option name="accept" required="true"/><!-- application/ld+json, application/trix+xml, application/rdf+xml, application/sparql-results+xml, text/csv -->
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
						<c:header name="Accept" value="{$accept}"/>
						<c:body content-type="application/x-www-form-urlencoded">{concat('query=', encode-for-uri(/))}</c:body>
					</c:request>
				</p:inline>
			</p:input>
		</p:template>
		<p:http-request/>
	</p:declare-step>	
</p:declare-step>
