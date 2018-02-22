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
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
>
	<!-- import calabash extension library to enable use of file steps -->
	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
	<!-- create folders for temporary storage of individual records -->
	<pxf:mkdir href="/data/object"/>
	<pxf:mkdir href="/data/site"/>
	<pxf:mkdir href="/data/party"/>
	<pxf:mkdir href="/data/narrative"/>
	<pxf:mkdir href="/data/media"/>
	
	<!-- process EMu objects, sites, parties, and narratives -->
	<!--	
	<nma:process-emu-data href="/data/emu_objects_21-02-2018_80454.xml" record-type="object"/>
	<nma:process-emu-data href="/data/emu_narratives_22-02-2018_1359.xml" record-type="narrative"/>
	<nma:process-emu-data href="/data/emu_sites19-02-2018_4200.xml" record-type="site"/>
	<nma:process-emu-data href="/data/emu_parties21-02-2018_25986.xml" record-type="party"/>	
	-->
	
	<!-- process Piction image metadata -->
	<nma:process-piction-data href="/data/solr_prod1.xml"/>
	
	<p:declare-step name="process-piction-data" type="nma:process-piction-data">
		<p:option name="href"/>
		<!-- process Piction media metadata -->
		<p:load name="piction-image-metadata">
			<p:with-option name="href" select="$href"/>
		</p:load>
		<p:for-each name="piction-record">
			<p:iteration-source select="/add/doc"/>
			<p:variable name="identifier" select="
				encode-for-uri(
					normalize-space(
						/doc/field
							[@name='EMu IRN for Related Objects']
							[not(string(.)=preceding-sibling::field[@name='EMu IRN for Related Objects'])]
					)
				)
			"/>
			<p:store indent="true">
				<p:with-option name="href" select="concat('/data/media/', $identifier, '.xml')"/>
			</p:store>
			<p:xslt name="piction-to-rdf">
				<p:with-param name="base-uri" select=" 'http://nma.conaltuohy.com/xproc-z/' "/>
				<p:input port="source">
					<p:pipe step="piction-record" port="current"/>
				</p:input>
				<p:input port="stylesheet">
					<p:document href="piction-to-rdf.xsl"/>
				</p:input>
			</p:xslt>
			<p:store indent="true">
				<p:with-option name="href" select="concat('/data/media/', $identifier, '.rdf')"/>
			</p:store>		
		</p:for-each>
	</p:declare-step>
	
	<p:declare-step name="process-emu-data" type="nma:process-emu-data">
		<p:option name="href"/>
		<p:option name="record-type"/>
		<p:load name="emu-objects">
			<p:with-option name="href" select="$href"/>
		</p:load>
		<p:for-each name="record">
			<p:iteration-source select="/response/record[1]"/>
			<p:variable name="identifier" select="/record/irn"/>
			<p:store indent="true">
				<p:with-option name="href" select="concat('/data/', $record-type, '/', $identifier, '.xml')"/>
			</p:store>
			<p:xslt name="emu-objects-to-rdf">
				<p:with-param name="base-uri" select=" 'http://nma.conaltuohy.com/xproc-z/' "/>
				<p:with-param name="record-type" select="$record-type"/>
				<p:input port="stylesheet">
					<p:document href="emu-to-rdf.xsl"/>
				</p:input>
				<p:input port="source">
					<p:pipe step="record" port="current"/>
				</p:input>
			</p:xslt>
			<p:store indent="true">
				<p:with-option name="href" select="concat('/data/', $record-type, '/', $identifier, '.rdf')"/>
			</p:store>
			<nma:store-graph>
				<p:with-option name="graph-uri" select="concat('http://nma.conaltuohy.com/fuseki/nma/data/', $record-type, '/', $identifier)"/>
				<p:input port="source">
					<p:pipe step="emu-objects-to-rdf" port="result"/>
				</p:input>
			</nma:store-graph>
		</p:for-each>			
	</p:declare-step>
	
	<!-- store graph in SPARQL store-->
	<p:declare-step type="nma:store-graph" name="store-graph">
		<p:input port="source"/>
		<p:option name="graph-uri" required="true"/>
		<!-- execute an HTTP PUT to store the graph in the graph store at the location specified -->
		<p:in-scope-names name="variables"/>
		<p:template name="generate-put-request">
			<p:input port="source">
				<p:pipe step="store-graph" port="source"/>
			  </p:input>
			<p:input port="template">
				<p:inline>
					<c:request method="PUT" href="http://localhost:8080/fuseki/nma/data?graph={$graph-uri}" detailed="true">
						<c:body content-type="application/rdf+xml">{ /* }</c:body>
					</c:request>
				</p:inline>
			</p:input>
			<p:input port="parameters">
				<p:pipe step="variables" port="result"/>
			</p:input>
		</p:template>
		<p:http-request/>
		<p:sink/>
	</p:declare-step>
	
</p:declare-step>
