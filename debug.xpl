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
	xmlns:sparql="http://www.w3.org/2005/sparql-results#">
	<p:import href="etl-to-solr-library.xpl"/>
	<!-- import calabash extension library to enable use of file and message steps -->
	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
	
	<p:output port="result" sequence="true"/>
	<p:variable name="resource-uri" select=" 'http://data.nma.gov.au/object/16448#' "/>
	<p:variable name="dataset" select=" 'public' "/>

	<nma:load-sparql-query name="resource-description-sparql-query" query-file="sparql-queries/describe-media.rq"/>
	<p:xslt name="generate-sparql-query">
		<p:with-param name="resource-uri" select="$resource-uri"/>
		<p:input port="source">
			<p:pipe step="resource-description-sparql-query" port="result"/>
		</p:input>
		<p:input port="stylesheet">
			<p:document href="util/substitute-resource-uri-into-query.xsl"/>
		</p:input>
	</p:xslt>
	<nma:sparql-query name="resource-description" accept="application/trix+xml">
		<p:with-option name="dataset" select="$dataset"/>
	</nma:sparql-query>	
</p:declare-step>