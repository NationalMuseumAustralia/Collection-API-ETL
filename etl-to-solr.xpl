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
	xmlns:trix="http://www.w3.org/2004/03/trix/trix-1/"
	xmlns:sparql="http://www.w3.org/2005/sparql-results#"
>
	<p:option name="dataset" required="true"/>
	<p:option name="mode" required="true"/><!-- "incremental" or "full" -->
	
	<!-- import calabash extension library to enable use of file steps -->
	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>


        <!-- create folder for logging failed uploads -->
        <pxf:mkdir fail-on-error="false" href="/data/failed-solr-deposits"/>
	
	<!-- update Solr store by querying the SPARQL store -->

	<!-- generate a Solr index of narratives, media, places, parties, collections, and physical objects -->
	<nma:index-resources name="index-narratives" 
		solr-type="narrative" 
		list-query="sparql-queries/list-narratives.rq" 
		describe-query="sparql-queries/describe-narratives.rq">
		<p:with-option name="dataset" select="$dataset"/>
		<p:with-option name="mode" select="$mode"/>
	</nma:index-resources>
	<nma:index-resources name="index-collections" 
		solr-type="collection"
		list-query="sparql-queries/list-collections.rq" 
		describe-query="sparql-queries/describe-collections.rq">
		<p:with-option name="dataset" select="$dataset"/>
		<p:with-option name="mode" select="$mode"/>
	</nma:index-resources>
	<nma:index-resources name="index-media" 
		solr-type="media"
		list-query="sparql-queries/list-media.rq" 
		describe-query="sparql-queries/describe-media.rq">
		<p:with-option name="dataset" select="$dataset"/>
		<p:with-option name="mode" select="$mode"/>
	</nma:index-resources>
	<nma:index-resources name="index-physical-objects" 
		solr-type="object"
		list-query="sparql-queries/list-objects.rq" 
		describe-query="sparql-queries/describe-objects.rq">
		<p:with-option name="dataset" select="$dataset"/>
		<p:with-option name="mode" select="$mode"/>
	</nma:index-resources>
	<nma:index-resources name="index-parties" 
		solr-type="party" 
		list-query="sparql-queries/list-parties.rq" 
		describe-query="sparql-queries/describe-parties.rq">
		<p:with-option name="dataset" select="$dataset"/>
		<p:with-option name="mode" select="$mode"/>
	</nma:index-resources>
	<nma:index-resources name="index-places" 
		solr-type="place"
		list-query="sparql-queries/list-places.rq" 
		describe-query="sparql-queries/describe-places.rq">
		<p:with-option name="dataset" select="$dataset"/>
		<p:with-option name="mode" select="$mode"/>
	</nma:index-resources>
	
	<!-- load a (non-XML) sparql query from disk -->
	<p:declare-step type="nma:load-sparql-query" name="load-sparql-query">
		<p:option name="query-file" required="true"/>
		<p:output port="result"/>
		<p:template name="sparql-list-query-load-request"><!-- a request to load the file from disk -->
			<p:with-param name="query-file" select="$query-file"/>
			<p:input port="source"><p:empty/></p:input>
			<p:input port="template">
				<p:inline>
					<c:request href="{encode-for-uri($query-file)}" method="get" override-content-type="text/plain; charset=UTF-8"/>
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
		<p:option name="dataset" required="true"/>
		<p:option name="solr-type" required="true"/>
		<p:option name="mode" required="true"/>
		<!-- load the non-XML sparql queries from file system -->
		<nma:load-sparql-query name="resource-list-sparql-query">
			<p:with-option name="query-file" select="$list-query"/>
		</nma:load-sparql-query>
		<nma:load-sparql-query name="resource-description-sparql-query">
			<p:with-option name="query-file" select="$describe-query"/>
		</nma:load-sparql-query>
		<!-- execute the query to list all the resources to be indexed -->
		<nma:sparql-query accept="application/sparql-results+xml">
			<p:with-option name="dataset" select="$dataset"/>
			<p:input port="source">
				<p:pipe step="resource-list-sparql-query" port="result"/>
			</p:input>
		</nma:sparql-query>
		<p:delete name="resources-to-index" match="
			/sparql:sparql/sparql:results/sparql:result[
				contains(
					sparql:binding[@name='resource']/sparql:uri,
					'unrecognised'
				)
			]
		"/>
		<nma:message>
			<p:with-option name="message" select="
				concat(
					'The &quot;', $dataset, '&quot; SPARQL dataset ',
					'has ', count(/sparql:sparql/sparql:results/sparql:result), ' resources ',
					'with type &quot;', $solr-type, '&quot;...'
				)
			"/>
		</nma:message>
		<p:choose>
			<p:when test="$mode = 'incremental' ">
				<!-- query solr for records of this type -->
				<p:load name="resources-in-solr-index">
					<p:with-option name="href" select="
						concat(
							'http://localhost:8983/solr/core_nma_',
							$dataset,
							'/select?fl=id,hash,datestamp,source_count&amp;q=type:',
							$solr-type,
							'&amp;rows=2147483647&amp;wt=xml'
						)
					"/>
				</p:load>
				<nma:message>
					<p:with-option name="message" select="
						concat(
							'The &quot;', $dataset, '&quot; Solr core ',
							'has ', count(/response/result[@name='response']/doc), ' records ',
							'with type &quot;', $solr-type, '&quot;.'
						)
					"/>
				</nma:message>
				<!-- compare "resources-to-index" with "resources-in-solr-index" and remove any which are unchanged -->
				<p:wrap-sequence name="comparison" wrapper="comparison">
					<p:input port="source">
						<p:pipe step="resources-to-index" port="result"/>
						<p:pipe step="resources-in-solr-index" port="result"/>
					</p:input>
				</p:wrap-sequence>
				<!-- remove resources from list of indexable resources if they are unchanged from the version in the solr index already -->
				<p:xslt name="filter-resources-to-index">
					<p:input port="parameters"><p:empty/></p:input>
					<p:input port="stylesheet">
						<p:document href="filter-resources-to-index.xsl"/>
					</p:input>
				</p:xslt>
			</p:when>
			<p:otherwise><!-- $mode = "full" -->
				<p:identity name="index-all-resources"/>
			</p:otherwise>
		</p:choose>
		<nma:message>
			<p:with-option name="message" select="concat(count(/sparql:sparql/sparql:results/sparql:result), ' resources need to be indexed.')"/>
		</nma:message>
		<!-- iterate through the resources, indexing each one individually -->
		<p:for-each name="resource">
			<p:iteration-source select="/results:sparql/results:results/results:result"/>
			<!-- generate description for this resource -->
			<p:variable name="resource-uri" select="/results:result/results:binding[@name='resource']/results:uri"/>
			<p:variable name="datestamp" select="/results:result/results:binding[@name='lastUpdated']/results:literal"/>
			<p:variable name="source-count" select="/results:result/results:binding[@name='sourceCount']/results:literal"/>
			<nma:message>
				<p:with-option name="message" select="concat(current-dateTime(), ' copying ', $resource-uri, ' from ', $dataset, ' dataset ...')"/>
			</nma:message>
			<!--
			<nma:message>
				<p:with-option name="message" select="concat(current-dateTime(), ' generating SPARQL query ...')"/>
			</nma:message>
			-->
			<!-- substitute the URI of the resource to be indexed into the query template -->
			<p:xslt name="generate-sparql-query">
				<p:with-param name="resource-uri" select="$resource-uri"/>
				<p:input port="source">
					<p:pipe step="resource-description-sparql-query" port="result"/>
				</p:input>
				<p:input port="stylesheet">
					<p:document href="util/substitute-resource-uri-into-query.xsl"/>
				</p:input>
			</p:xslt>
			<!-- execute the query to generate a resource description -->
			<!--
			<nma:message>
				<p:with-option name="message" select="concat(current-dateTime(), ' executing SPARQL query ...')"/>
			</nma:message>
			-->
			<nma:sparql-query name="resource-description" accept="application/trix+xml">
				<p:with-option name="dataset" select="$dataset"/>
			</nma:sparql-query>
			<!-- make any necessary redactions to the RDF graph -->
			<p:group name="redaction"><!-- cx:depends-on="store-raw-trix">-->
				<p:choose>
					<p:when test=" $dataset = 'public' ">
						<p:xslt name="description-with-unlicensed-images-redacted">
							<p:input port="stylesheet">
								<p:document href="redact-unlicensed-images-from-trix-description.xsl"/>
							</p:input>
							<p:with-param name="root-resource" select="$resource-uri"/>
							<p:with-param name="debug" select=" 'false' "/>
						</p:xslt>
					</p:when>
					<p:otherwise>
						<p:identity name="unlicensed-images-not-redacted-from-internal-api"/>
					</p:otherwise>
				</p:choose>
				<p:xslt name="description-with-secondary-depictions-redacted">
					<p:input port="stylesheet">
						<p:document href="redact-objects-depicted-in-images-which-depict-objects.xsl"/>
					</p:input>
					<p:with-param name="root-resource" select="$resource-uri"/>
					<p:with-param name="debug" select=" 'false' "/>
				</p:xslt>
				<p:xslt name="redacted-description">
					<p:input port="stylesheet">
						<p:document href="redact-trix-description.xsl"/>
					</p:input>
					<p:with-param name="root-resource" select="$resource-uri"/>
					<p:with-param name="debug" select=" 'false' "/>
				</p:xslt>
			</p:group>
			<nma:update-solr>
				<p:with-option name="resource-uri" select="$resource-uri"/>
				<p:with-option name="dataset" select="$dataset"/>
				<p:with-option name="hash" select=" p:system-property('p:episode') "/>
				<p:with-option name="datestamp" select="$datestamp"/>
				<p:with-option name="source-count" select="$source-count"/>
			</nma:update-solr>
			<!-- store raw trix -->
			<!--
			<p:store indent="true" name="store-raw-trix">
				<p:with-option name="href" select="concat('/data/', $dataset, '/trix/', encode-for-uri(encode-for-uri($resource-uri)), '.xml')"/>
				<p:input port="source">
					<p:pipe step="resource-description" port="result"/>
				</p:input>
			</p:store>
			-->
			<!-- store redacted trix -->
			<!--
			<p:store indent="true">
				<p:with-option name="href" select="concat('/data/public/redacted-trix/', encode-for-uri(encode-for-uri($resource-uri)), '.xml')"/>
				<p:input port="source">
					<p:pipe step="redacted-description" port="result"/>
				</p:input>
			</p:store>
			-->
		</p:for-each>	
		<!--
		<p:store>
			<p:with-option name="href" select="concat('/tmp/', $solr-type, '.xml')"/>
			<p:input port="source">
				<p:pipe step="resources-to-index" port="result"/>
			</p:input>
		</p:store>
		-->
		
		<!-- If doing a full update, we should now purge all the records except those which have been saved in this particular episode of the ETL pipeline -->
		<p:template name="create-solr-request">
			<p:with-param name="dataset" select="$dataset"/>
			<p:with-param name="type" select="$solr-type"/>
			<p:with-param name="hash" select="p:system-property('p:episode')"/>
			<p:input port="source">
				<p:empty/>
			</p:input>
			<p:input port="template">
				<p:inline>
					<c:request method="post" href="http://localhost:8983/solr/core_nma_{$dataset}/update" detailed="true">
						<c:body content-type="application/xml">
							<delete commitWithin="10000"><query>type:"{$type}" NOT hash:"{$hash}"</query></delete>
						</c:body>
					</c:request>
				</p:inline>
			</p:input>
		</p:template>
		<p:for-each>
			<!-- query needs executing only if $mode='full' -->
			<p:iteration-source select="/*[$mode='full']"/>
			<!-- execute the Solr index delete query -->
			<p:http-request name="solr-deposit"/>
			<p:sink/>
		</p:for-each>
	</p:declare-step>
	
	<!-- compute a hash of a document, replacing it with <hash value="xxx"/> -->
	<p:declare-step name="hash" type="nma:hash">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:wrap wrapper="hash" match="/*"/>
		<p:add-attribute attribute-name="value" match="/hash" attribute-value=" '' "/>
		<p:hash name="computed-hash" match="/hash/@value" algorithm="crc">
			<p:input port="parameters"><p:empty/></p:input>
			<p:with-option name="value" select="serialize(/)"/>
		</p:hash>
		<p:delete match="/hash/*"/>
	</p:declare-step>
	
	<p:declare-step type="nma:update-solr" name="update-solr">	
			<p:input port="source"/>
			<p:option name="resource-uri" required="true"/>
			<p:option name="dataset" required="true"/>
			<p:option name="hash" required="true"/>
			<p:option name="datestamp" required="true"/>
			<p:option name="source-count" required="true"/>
			<!-- generate the Solr metadata fields -->
			<p:template name="solr-metadata-fields">
				<p:with-param name="hash" select="$hash"/>
				<p:with-param name="datestamp" select="$datestamp"/>
				<p:with-param name="source-count" select="$source-count"/>
				<p:input port="template">
					<p:inline>
						<doc>
							<!-- The hash is used as an identifier for this current version of this record -->
							<field name="hash">{$hash}</field>
							<field name="datestamp">{$datestamp}</field>
							<field name="source_count">{$source-count}</field>
						</doc>
					</p:inline>
				</p:input>
			</p:template>
			<!-- transform the RDF graph into a Solr index update -->
			<!-- generate all the search and metadata fields -->
			<!--
			<nma:message message="generating solr search fields"/>
			-->
			<p:xslt name="trix-description-to-solr-search-fields">
				<p:input port="source">
					<p:pipe step="update-solr" port="source"/>
				</p:input>
				<p:input port="stylesheet">
					<p:document href="trix-description-to-solr.xsl"/>
				</p:input>
				<p:with-param name="root-resource" select="$resource-uri"/>
				<p:with-param name="dataset" select="$dataset"/>
				<p:with-param name="hash" select="$hash"/>
				<p:with-param name="datestamp" select="$datestamp"/>
				<p:with-param name="source-count" select="$source-count"/>
			</p:xslt>
			<!-- generate the "simple_{n}" response payload fields -->
			<nma:trix-description-to-solr-field name="trix-description-to-simple-json-v1"
				field-name="simple_1">
				<p:input port="source">
					<p:pipe step="update-solr" port="source"/>
				</p:input>
				<p:input port="stylesheet">
					<p:document href="trix-description-to-dc-v1.xsl"/>
				</p:input>
				<p:with-option name="root-resource" select="$resource-uri"/>
			</nma:trix-description-to-solr-field>
			<nma:trix-description-to-solr-field name="trix-description-to-simple-json-v2"
				field-name="simple_2">
				<p:input port="source">
					<p:pipe step="update-solr" port="source"/>
				</p:input>
				<p:input port="stylesheet">
					<p:document href="trix-description-to-dc-v2.xsl"/>
				</p:input>
				<p:with-option name="root-resource" select="$resource-uri"/>
			</nma:trix-description-to-solr-field>
			<!-- generate the "json-ld" response payload field -->
			<nma:trix-description-to-solr-field name="trix-description-to-json-ld"
				field-name="json-ld">
				<p:input port="source">
					<p:pipe step="update-solr" port="source"/>
				</p:input>
				<p:input port="stylesheet">
					<p:document href="trix-description-to-json-ld.xsl"/>
				</p:input>
				<p:with-option name="root-resource" select="$resource-uri"/>
			</nma:trix-description-to-solr-field>
				
			<!-- aggregate the fields contained in the 4 <doc> elements into a single <doc> and format it for HTTP POST to Solr -->
			<p:wrap-sequence wrapper="doc">
				<p:input port="source" select="/doc/field">
					<p:pipe step="solr-metadata-fields" port="result"/>
					<p:pipe step="trix-description-to-solr-search-fields" port="result"/>
					<p:pipe step="trix-description-to-simple-json-v1" port="result"/>
					<p:pipe step="trix-description-to-simple-json-v2" port="result"/>
					<p:pipe step="trix-description-to-json-ld" port="result"/>
				</p:input>
			</p:wrap-sequence>
			<p:template name="create-solr-request">
				<p:with-param name="dataset" select="$dataset"/>
				<p:input port="template">
					<p:inline>
						<c:request method="post" href="http://localhost:8983/solr/core_nma_{$dataset}/update" detailed="true">
							<c:body content-type="application/xml">
								<add commitWithin="10000">
									{/doc}
								</add>
							</c:body>
						</c:request>
					</p:inline>
				</p:input>
			</p:template>
			<!-- execute the Solr index update -->
			<p:http-request name="solr-deposit"/>
			<!-- store any errors -->
			<p:for-each name="error-response">
				<p:iteration-source select="/c:response[number(@status) &gt;= 400]"/>
				<nma:message>
					<p:with-option name="message" select="
						concat(
							'Error depositing resource &lt;',
							$resource-uri,
							'&gt; in Solr'
						)
					"/>
				</nma:message>
				<p:wrap-sequence wrapper="failed-solr-deposit">
					<p:input port="source">
						<p:pipe step="update-solr" port="source"/>
						<p:pipe step="create-solr-request" port="result"/>
						<p:pipe step="solr-deposit" port="result"/>
					</p:input>
				</p:wrap-sequence>
				<p:store indent="true">
					<p:with-option name="href" select="
						concat(
							'/data/failed-solr-deposits/',
							encode-for-uri(encode-for-uri($resource-uri)),
							'.xml'
						)
					"/>
				</p:store>
			</p:for-each>
			<!-- store solr update -->
			<!--
			<p:store href="/tmp/solr.xml" indent="true">
				<p:input port="source">
					<p:pipe step="json-xml-to-json" port="result"/>
				</p:input>
			</p:store>
			-->
	</p:declare-step>

	<!-- converts an RDF graph in TriX format into JSON XML using the specified stylesheet, 
	passing the $root-resource parameter to the stylesheet to identify the main resource in the graph,
	then converts the resulting JSON-XML into JSON,
	and wraps it in a Solr <field name="xxx"> element with the specified field-name --> 
	<p:declare-step type="nma:trix-description-to-solr-field" name="trix-description-to-solr-field">
		<p:input port="source" primary="true"/>
		<p:input port="stylesheet"/>
		<p:output port="result"/>
		<p:option name="field-name" required="true"/>
		<p:option name="root-resource" required="true"/>
		<!--
		<nma:message>
			<p:with-option name="message" select="concat('generating solr field ', codepoints-to-string(34), $field-name, codepoints-to-string(34))"/>
		</nma:message>
		-->
		<!-- apply the stylesheet to the trix source to produce JSON XML -->
		<p:xslt name="convert-trix-to-json-xml">
			<p:input port="stylesheet">
				<p:pipe step="trix-description-to-solr-field" port="stylesheet"/>
			</p:input>
			<p:with-param name="root-resource" select="$root-resource"/>
			<p:with-param name="debug" select=" 'false' "/>
		</p:xslt>
		<!--
		<p:store name="debug-save-json-xml">
			<p:with-option name="href" select="
				concat(
					'/data/json-xml/',
					encode-for-uri(encode-for-uri($root-resource)),
					'/',
					$field-name,
					'.xml'
				)
			"/>
		</p:store>
		-->
		<p:identity>
			<p:input port="source"><p:pipe step="convert-trix-to-json-xml" port="result"/></p:input>
		</p:identity>
		<!-- wrap as Solr doc/field -->
		<p:wrap name="solr-field" match="/*" wrapper="field"/>
		<p:add-attribute name="solr-field-name" match="/field" attribute-name="name">
			<p:with-option name="attribute-value" select="$field-name"/>
		</p:add-attribute>
		<p:wrap name="solr-doc" match="/field" wrapper="doc"/>
		<!-- convert to JSON  -->
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
				<p:identity/>
			</p:catch>
		</p:try>
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
	
	<p:declare-step type="nma:message" name="message">
		<p:option name="message" required="true"/>
		<p:input port="source"/>
		<p:output port="result"/>
		<cx:message>
			<p:with-option name="message" select="concat(current-dateTime(), ' ', $message)"/>
		</cx:message>
	</p:declare-step>
	
</p:declare-step>
