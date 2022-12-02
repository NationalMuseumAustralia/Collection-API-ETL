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
	type="nma:etl-to-solr"
>
	<p:option name="dataset" required="true"/>
	<p:option name="mode" required="true"/><!-- "incremental" or "full" -->
	
	<!-- import calabash extension library to enable use of file and message steps -->
	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
	<!-- import the library of pipelines for ETL from SPARQL graph store to Solr -->
	<p:import href="etl-to-solr-library.xpl"/>

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
	
</p:declare-step>
