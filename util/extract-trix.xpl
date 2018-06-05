<p:declare-step version="1.0" xmlns:p="http://www.w3.org/ns/xproc"
	xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:c="http://www.w3.org/ns/xproc-step"
	xmlns:nma="tag:conaltuohy.com,2018:nma" xmlns:pxf="http://exproc.org/proposed/steps/file"
	xmlns:cx="http://xmlcalabash.com/ns/extensions" xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:results="http://www.w3.org/2005/sparql-results#">

	<!-- import calabash extension library to enable use of file steps -->
	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl" />

	<!-- generate description for the specified resource -->
	<p:option name="type" required="true" />
	<p:option name="id"   required="true" />
	<p:variable name="resource-uri" select="concat('http://nma-dev.conaltuohy.com/', $type, '/', $id, '#')" />

	<!-- uncomment the appropriate describe query for the resource type -->
	<nma:index-resources name="index-physical-objects" describe-query="../sparql-queries/describe-objects.rq">
		<p:with-option name="resource-uri" select="$resource-uri" />
	</nma:index-resources>
<!-- 
	<nma:index-resources name="index-narratives" describe-query="../sparql-queries/describe-narratives.rq">
		<p:with-option name="resource-uri" select="$resource-uri" />
	</nma:index-resources>
	<nma:index-resources name="index-collections" describe-query="../sparql-queries/describe-collections.rq">
		<p:with-option name="resource-uri" select="$resource-uri" />
	</nma:index-resources>
	<nma:index-resources name="index-media" describe-query="../sparql-queries/describe-media.rq">
		<p:with-option name="resource-uri" select="$resource-uri" />
	</nma:index-resources>
	<nma:index-resources name="index-parties" describe-query="../sparql-queries/describe-parties.rq">
		<p:with-option name="resource-uri" select="$resource-uri" />
	</nma:index-resources>
	<nma:index-resources name="index-places" describe-query="../sparql-queries/describe-places.rq">
		<p:with-option name="resource-uri" select="$resource-uri" />
	</nma:index-resources>
 -->

	<!-- load a (non-XML) sparql query from disk -->
	<p:declare-step type="nma:load-sparql-query" name="load-sparql-query">
		<p:option name="query-file" required="true" />
		<p:output port="result" />
		<p:template name="sparql-list-query-load-request"><!-- a request to load the file from disk -->
			<p:with-param name="query-file" select="$query-file" />
			<p:input port="source">
				<p:empty />
			</p:input>
			<p:input port="template">
				<p:inline>
					<c:request href="{encode-for-uri($query-file)}" method="get"
						override-content-type="text/plain" />
				</p:inline>
			</p:input>
		</p:template>
		<p:http-request />
	</p:declare-step>

	<!-- extract and store as trix the specified resource which matches a particular SPARQL query --> 
	<p:declare-step type="nma:index-resources" name="index-resources">
		<!-- names of files containing the sparql queries to describe, entities of a particular type -->
		<p:option name="describe-query" required="true" />
		<p:option name="resource-uri" required="true" />
		<!-- load the non-XML sparql queries from file system -->
		<nma:load-sparql-query name="resource-description-sparql-query">
			<p:with-option name="query-file" select="$describe-query" />
		</nma:load-sparql-query>

		<cx:message>
			<p:with-option name="message"
				select="concat('Querying SPARQL store for ', $resource-uri, ' ...')" />
		</cx:message>
		<!-- substitute the URI of the resource to be indexed into the query template -->
		<p:xslt name="generate-sparql-query">
			<p:with-param name="resource-uri" select="$resource-uri" />
			<p:input port="source">
				<p:pipe step="resource-description-sparql-query" port="result" />
			</p:input>
			<p:input port="stylesheet">
				<p:document href="substitute-resource-uri-into-query.xsl" />
			</p:input>
		</p:xslt>
		<!-- execute the query to generate a resource description -->
		<nma:sparql-query name="resource-description" dataset="public"
			accept="application/trix+xml" />
		<!-- make any necessary redactions to the RDF graph -->
		<p:xslt name="redacted-description">
			<p:input port="stylesheet">
				<p:document href="../redact-trix-description.xsl" />
			</p:input>
			<p:with-param name="root-resource" select="$resource-uri" />
		</p:xslt>
		<!-- store raw trix -->
		<p:store indent="true">
			<p:with-option name="href" select="'/tmp/trix.xml'" />
			<p:input port="source">
				<p:pipe step="resource-description" port="result" />
			</p:input>
		</p:store>
	</p:declare-step>

	<p:declare-step type="nma:sparql-query" name="sparql-query">
		<p:input port="source" />
		<p:output port="result" />
		<p:option name="dataset" required="true" />
		<p:option name="accept" required="true" /><!-- application/ld+json, application/trix+xml, 
			application/rdf+xml, application/sparql-results+xml, text/csv -->
		<p:in-scope-names name="parameters" />
		<p:template name="generate-http-request">
			<p:input port="source">
				<p:pipe step="sparql-query" port="source" />
			</p:input>
			<p:input port="parameters">
				<p:pipe step="parameters" port="result" />
			</p:input>
			<p:input port="template">
				<p:inline>
					<c:request method="POST" href="http://localhost:8080/fuseki/{$dataset}/query">
						<c:header name="Accept" value="{$accept}" />
						<c:body content-type="application/x-www-form-urlencoded">{concat('query=', encode-for-uri(/))}</c:body>
					</c:request>
				</p:inline>
			</p:input>
		</p:template>
		<p:http-request />
	</p:declare-step>
</p:declare-step>
