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
	
	<!-- modify the piction data file slightly (for testing incremental sparql build -->
	<p:load name="source" href="/mnt/dams_data/solr_prod1.xml"/>
	<p:string-replace name="modified" match="/add/doc/field[@name='Title']/text()[contains(., ' - ')]" replace="translate(., '-', '–')"/>
	
	<p:store href="/mnt/dams_data/solr_prod1-modified.xml">
		<p:input port="source">
			<p:pipe step="modified" port="result"/>
		</p:input>
	</p:store>
	<p:store href="/mnt/dams_data/solr_prod1-unmodified.xml">
		<p:input port="source">
			<p:pipe step="source" port="result"/>
		</p:input>
	</p:store>

</p:declare-step>