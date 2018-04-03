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

	<p:variable name="object-id" select=" '45929' "/>
	<p:variable name="physical-object-uri" select=" concat('http://nma-dev.conaltuohy.com/xproc-z/object/', $object-id, '#') "/>
	<p:xslt name="generate-sparql-query">
		<p:with-param name="resource-uri" select="$physical-object-uri"/>
		<p:input port="source">
			<p:inline>
				<query>
<![CDATA[
CONSTRUCT {
	«resource-uri» ?resourceProperty ?resourcePropertyValue.
	?image ?imageProperty ?imagePropertyValue.
	?person ?personProperty ?personPropertyValue.
	?place ?placeProperty ?placePropertyValue.
}
WHERE {
	«resource-uri» ?resourceProperty ?resourcePropertyValue.
	OPTIONAL {
		?image <tag:conaltuohy.com,2018:nma/piction/EMu-IRN-for-Related-Objects> «resource-uri».
		?image ?imageProperty ?imagePropertyValue.	
	}
	OPTIONAL {
		«resource-uri» <tag:conaltuohy.com,2018:nma/emu/ProPersonRef_tab.irn> ?person.
		?person ?personProperty ?personPropertyValue
	}
	OPTIONAL {
		«resource-uri» <tag:conaltuohy.com,2018:nma/emu/AssPlaceRef_tab.irn> ?place.
		?place ?placeProperty ?placePropertyValue
	}
}
]]>
				</query>
			</p:inline>			
		</p:input>
		<p:input port="stylesheet">
			<p:document href="util/substitute-resource-uri-into-query.xsl"/>
		</p:input>
	</p:xslt>
	<!-- execute the query to generate a resource description -->
	<cx:message>
		<p:with-option name="message" select="concat('Querying SPARQL store for ', $physical-object-uri, ' ...')"/>
	</cx:message>
	<nma:sparql-query name="resource-description" dataset="public" accept="application/trix+xml"/>
	<p:xslt name="trix-description-to-json-ld">
		<p:input port="stylesheet">
			<p:document href="trix-description-to-json-ld.xsl"/>
		</p:input>
		<p:with-param name="root-resource" select="$physical-object-uri"/>
	</p:xslt>
	<p:store method="xml" indent="true">
		<p:with-option name="href" select="concat('/tmp/', $object-id, '.xml')"/>
	</p:store>	
	<p:xslt name="compact-json-ld">
		<p:input port="parameters"><p:empty/></p:input>
		<p:input port="source">
			<p:pipe step="trix-description-to-json-ld" port="result"/>
		</p:input>
		<p:input port="stylesheet">
			<p:document href="util/compact-json-ld.xsl"/>
		</p:input>
	</p:xslt>
	<p:store method="xml" indent="true">
		<p:with-option name="href" select="concat('/tmp/', $object-id, '-compact.xml')"/>
	</p:store>
	<!--
	<p:store method="text">
		<p:with-option name="href" select="concat('/tmp/', $object-id, '.jsonld')"/>
	</p:store>
	-->
	
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