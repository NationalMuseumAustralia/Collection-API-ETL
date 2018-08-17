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
		<nma:sparql-query name="resources-to-index" accept="application/sparql-results+xml">
			<p:with-option name="dataset" select="$dataset"/>
			<p:input port="source">
				<p:pipe step="resource-list-sparql-query" port="result"/>
			</p:input>
		</nma:sparql-query>
		<cx:message>
			<p:with-option name="message" select="
				concat(
					'The &quot;', $dataset, '&quot; SPARQL dataset ',
					'has ', count(/sparql:sparql/sparql:results/sparql:result), ' resources ',
					'with type &quot;', $solr-type, '&quot;...'
				)
			"/>
		</cx:message>
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
				<cx:message>
					<p:with-option name="message" select="
						concat(
							'The &quot;', $dataset, '&quot; Solr core ',
							'has ', count(/response/result[@name='response']/doc), ' records ',
							'with type &quot;', $solr-type, '&quot;.'
						)
					"/>
				</cx:message>
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
		<cx:message>
			<p:with-option name="message" select="concat(count(/sparql:sparql/sparql:results/sparql:result), ' resources need to be indexed.')"/>
		</cx:message>
		<!-- iterate through the resources, indexing each one individually -->
		<p:for-each name="resource">
			<p:iteration-source select="/results:sparql/results:results/results:result"/>
			<!-- generate description for this resource -->
			<p:variable name="resource-uri" select="/results:result/results:binding[@name='resource']/results:uri"/>
			<p:variable name="datestamp" select="/results:result/results:binding[@name='lastUpdated']/results:literal"/>
			<p:variable name="source-count" select="/results:result/results:binding[@name='sourceCount']/results:literal"/>
			<cx:message>
				<p:with-option name="message" select="concat(current-dateTime(), ' copying ', $resource-uri, ' from ', $dataset, ' dataset ...')"/>
			</cx:message>
			<!--
			<cx:message>
				<p:with-option name="message" select="concat(current-dateTime(), ' generating SPARQL query ...')"/>
			</cx:message>
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
			<cx:message>
				<p:with-option name="message" select="concat(current-dateTime(), ' executing SPARQL query ...')"/>
			</cx:message>
			-->
			<nma:sparql-query name="resource-description" accept="application/trix+xml">
				<p:with-option name="dataset" select="$dataset"/>
			</nma:sparql-query>
			<!-- make any necessary redactions to the RDF graph -->
			<!--
			<cx:message>
				<p:with-option name="message" select="concat(current-dateTime(), ' redacting query results ...')"/>
			</cx:message>
			-->
			<p:xslt name="redacted-description">
				<p:input port="stylesheet">
					<p:document href="redact-trix-description.xsl"/>
				</p:input>
				<p:with-param name="root-resource" select="$resource-uri"/>
			</p:xslt>
			<!-- Check if the Solr store already contains a record with the same identifier, based on identical RDF -->
			<!--
			<cx:message>
				<p:with-option name="message" select="concat(current-dateTime(), ' generating hash of results ...')"/>
			</cx:message>
			-->
			<p:delete name="remove-unstable-blank-node-identifiers" match="//trix:id"/>
			<nma:hash name="trix-hash"/>
			<p:group>
				<p:variable name="hash" select="/hash/@value"/>
				<!-- check if Solr has this record with the same hash as the just-computed hash -->
				<!--
				<cx:message>
					<p:with-option name="message" select="concat(current-dateTime(), ' querying Solr for hash equality ...')"/>
				</cx:message>
				-->
				<p:load name="still-current-solr-record">
					<p:with-option name="href" select="
						concat(
							'http://localhost:8983/solr/core_nma_',
							$dataset,
							'/select?wt=xml&amp;q=id:',
							replace($resource-uri, '(.*/)([^/]*/[^/]*)(#)$', '$2'),
							'%20AND%20hash:',
							$hash
						)
					"/>
				</p:load>
				<p:choose>
					<p:when test="/response/result/@numFound='1'">
						<!-- there is a record in Solr which was derived from the same source data -->
						<cx:message>
							<p:with-option name="message" select="concat(current-dateTime(), ' the source data for the record in Solr was still valid')"/>
						</cx:message>
					</p:when>
					<p:otherwise>
						<!-- solr didn't contain a record based on the same source data -->
						<cx:message>
							<p:with-option name="message" select="concat(current-dateTime(), ' the source data for the record in Solr was stale')"/>
						</cx:message>
					</p:otherwise>
				</p:choose>
				<p:choose>
					<p:when test="/response/result/@numFound='0' or $mode='full' ">
						<!-- Solr does not contain an up-to-date version of this record -->
						<!-- or we are performing a "full" population of Solr anyway -->
						<!-- so derive new publication formats from the RDF and store in Solr -->
						<cx:message message="updating Solr ..."/>
						<nma:update-solr>
							<p:with-option name="resource-uri" select="$resource-uri"/>
							<p:with-option name="dataset" select="$dataset"/>
							<p:with-option name="hash" select="$hash"/>
							<p:with-option name="datestamp" select="$datestamp"/>
							<p:with-option name="source-count" select="$source-count"/>
							<p:input port="source">
								<p:pipe step="redacted-description" port="result"/>
							</p:input>
						</nma:update-solr>
					</p:when>
					<p:otherwise>
						<p:sink/>
					</p:otherwise>
				</p:choose>
			</p:group>
			<!-- store raw trix -->
			<!--
			<p:store indent="true">
				<p:with-option name="href" select="concat('/data/public/trix/', encode-for-uri(encode-for-uri($resource-uri)), '.xml')"/>
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
		<p:store>
			<p:with-option name="href" select="concat('/tmp/', $solr-type, '.xml')"/>
			<p:input port="source">
				<p:pipe step="resources-to-index" port="result"/>
			</p:input>
		</p:store>
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
			<!-- transform the RDF graph into a Solr index update -->
			<p:xslt name="trix-description-to-solr-doc">
				<p:input port="stylesheet">
					<p:document href="trix-description-to-solr.xsl"/>
				</p:input>
				<p:with-param name="root-resource" select="$resource-uri"/>
				<p:with-param name="dataset" select="$dataset"/>
				<p:with-param name="hash" select="$hash"/>
				<p:with-param name="datestamp" select="$datestamp"/>
				<p:with-param name="source-count" select="$source-count"/>
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
			<!-- execute the Solr index update -->
			<p:http-request name="solr-deposit"/>
			<!-- store any errors -->
			<p:for-each name="error-response">
				<p:iteration-source select="/c:response[number(@status) &gt;= 400]"/>
				<cx:message>
					<p:with-option name="message" select="
						concat(
							'Error depositing resource &lt;',
							$resource-uri,
							'&gt; in Solr'
						)
					"/>
				</cx:message>
				<p:wrap-sequence wrapper="failed-solr-deposit">
					<p:input port="source">
						<p:pipe step="update-solr" port="source"/>
						<p:pipe step="json-xml-to-json" port="result"/>
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
