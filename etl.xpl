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
	xmlns:cx="http://xmlcalabash.com/ns/extensions"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
>
	<!-- import calabash extension library to enable use of file steps -->
	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
	<!-- create folders for temporary storage of individual records -->
	<pxf:mkdir href="/data/object"/>
	<pxf:mkdir href="/data/place"/>
	<pxf:mkdir href="/data/party"/>
	<pxf:mkdir href="/data/narrative"/>
	<pxf:mkdir href="/data/collection"/>
	<pxf:mkdir href="/data/image"/>
	
	<p:exec name="read-hostname" command="hostname" result-is-xml="false">
		<p:input port="source">
			<!-- the linux "hostname" command will not be sent any input -->
			<p:empty/>
		</p:input>
	</p:exec>
	<p:group>
		<!-- capture the hostname so we can make URIs relative to this host -->
		<p:variable name="hostname" select="normalize-space(/)"/>
		
		<!-- load our local vocabulary data -->
		<nma:load-vocabulary>
			<p:with-option name="hostname" select="$hostname"/>
		</nma:load-vocabulary>
		
		<!-- process Piction image metadata -->
		<p:load href="/data/piction_solr_prod1.xml"/>
		<nma:process-data record-type="image" dataset="public">
			<p:with-option name="hostname" select="$hostname"/>
		</nma:process-data>
	
		<!-- process EMu objects, places, parties, collections, and narratives -->
		<p:load href="/data/emu_objects_09-04-2018_81985.xml"/>
		<nma:process-data record-type="object" dataset="public">
			<p:with-option name="hostname" select="$hostname"/>
		</nma:process-data>
		<p:load href="/data/emu_narratives_09-04-2018_1364.xml"/>
		<nma:process-data record-type="narrative" dataset="public">
			<p:with-option name="hostname" select="$hostname"/>
		</nma:process-data>
		<p:load href="/data/emu_sites09-04-2018_4216.xml"/>
		<nma:process-data record-type="place" dataset="public">
			<p:with-option name="hostname" select="$hostname"/>
		</nma:process-data>
		<p:load href="/data/emu_parties09-04-2018_26223.xml"/>	
		<nma:process-data record-type="party" dataset="public">
			<p:with-option name="hostname" select="$hostname"/>
		</nma:process-data>
		<p:load href="/data/emu_acclots_09-04-2018_3960.xml"/>	
		<nma:process-data record-type="collection" dataset="public">
			<p:with-option name="hostname" select="$hostname"/>
		</nma:process-data>
	</p:group>
	
	<p:declare-step name="load-vocabulary" type="nma:load-vocabulary">
		<p:option name="hostname" required="true"/>
		<p:load href="vocabulary.rdf" name="raw-vocabulary"/>
		<cx:message message="Loading local RDF vocabularies into SPARQL store..."/>
		<p:add-attribute attribute-name="xml:base" match="/*" name="localised-vocabulary">
			<p:with-option name="attribute-value" select="concat('http://', $hostname, '/xproc-z/term/')"/>
		</p:add-attribute>

		<nma:store-graph dataset="public">
			<p:with-option name="graph-uri" select="concat('http://', $hostname, '/fuseki/', $dataset, '/data/vocabulary')"/>
		</nma:store-graph>
	</p:declare-step>
	
	<p:declare-step name="process-data" type="nma:process-data">
		<p:input port="source"/>
		<p:option name="record-type" required="true"/>
		<p:option name="hostname" required="true"/>
		<p:option name="dataset" required="true"/>
		<cx:message message="Converting XML data into RDF in SPARQL store..."/>
		<p:for-each name="record">
			<!-- EMu records are /response/record, Piction records are /add/doc -->
			<!-- EMu "partial-update" records are excluded from this processing, and handled separately below -->
			<!-- because a partial-update can't be handled by transforming the record to an RDF graph and storing it using the SPARQL Graph Store protocol; -->
			<!-- instead it has to delete a triple from a graph and insert a new one, using the SPARQL Update protocol -->
			<p:iteration-source select="/response/record[not(partial-update)] | /add/doc"/>
			<!-- EMu records are uniquely identified by /response/record/irn, Piction records by /doc/field[@name='Multimedia ID'] -->
			<p:variable name="identifier" select="/record/irn | doc/field[@name='Multimedia ID']"/>
			<cx:message>
				<p:with-option name="message" select="concat('Ingesting ', $record-type, ' ', $identifier, ' into ', $dataset, ' dataset...')"/>
			</cx:message>
			<p:store indent="true">
				<p:with-option name="href" select="concat('/data/', $record-type, '/', $identifier, '.xml')"/>
			</p:store>
			<p:choose name="transformation-to-rdf">
				<p:when test="$record-type='image'">
					<p:output port="result"/>
					<p:xslt name="piction-to-rdf">
						<p:with-param name="base-uri" select="concat('http://', $hostname, '/xproc-z/')"/>
						<p:with-param name="record-type" select="$record-type"/>
						<p:input port="stylesheet">
							<p:document href="piction-to-rdf.xsl"/>
						</p:input>
						<p:input port="source">
							<p:pipe step="record" port="current"/>
						</p:input>
					</p:xslt>
				</p:when>
				<p:otherwise>
					<p:output port="result"/>
					<p:xslt name="emu-objects-to-rdf">
						<p:with-param name="base-uri" select="concat('http://', $hostname, '/xproc-z/')"/>
						<p:with-param name="record-type" select="$record-type"/>
						<p:input port="stylesheet">
							<p:document href="emu-to-crm.xsl"/>
						</p:input>
						<p:input port="source">
							<p:pipe step="record" port="current"/>
						</p:input>
					</p:xslt>
				</p:otherwise>
			</p:choose>
			<p:store indent="true">
				<p:with-option name="href" select="concat('/data/', $record-type, '/', $identifier, '.rdf')"/>
			</p:store>
			<nma:store-graph>
				<p:with-option name="graph-uri" select="concat('http://', $hostname, '/fuseki/', $dataset, '/data/', $record-type, '/', $identifier)"/>
				<p:with-option name="dataset" select="$dataset"/>
				<p:input port="source">
					<p:pipe step="transformation-to-rdf" port="result"/>
				</p:input>
			</nma:store-graph>
		</p:for-each>
		<p:sink/>
		<!-- Finally, process "partial-update" records -->
		<!-- EMu "partial-update" records can't be handled by transforming the record to an RDF graph and storing it using the SPARQL Graph Store protocol; -->
		<!-- instead, each partial update must delete a triple from an existing graph and insert a new triple in its place, using the SPARQL Update protocol -->
		<p:for-each name="partial-update">
			<p:iteration-source select="/response/record[partial-update]">
				<p:pipe step="process-data" port="source"/>
			</p:iteration-source>
			<!-- EMu records are uniquely identified by /response/record/irn -->
			<p:variable name="identifier" select="/record/irn"/>
			<cx:message>
				<p:with-option name="message" select="concat('Partially updating object', $identifier, ' in ', $dataset, ' dataset...')"/>
			</cx:message>
			<!-- TODO generate and execute the appropriate SPARQL update -->
			<p:sink name="simpy-ignore-the-partial-update-record-for-now"/>
		</p:for-each>
	</p:declare-step>
	
	<!-- store graph in SPARQL store-->
	<p:declare-step type="nma:store-graph" name="store-graph">
		<p:input port="source"/>
		<p:option name="graph-uri" required="true"/>
		<p:option name="dataset" required="true"/>
		<!-- execute an HTTP PUT to store the graph in the graph store at the location specified -->
		<p:in-scope-names name="variables"/>
		<p:template name="generate-put-request">
			<p:input port="source">
				<p:pipe step="store-graph" port="source"/>
			  </p:input>
			<p:input port="template">
				<p:inline>
					<c:request method="PUT" href="http://localhost:8080/fuseki/{$dataset}/data?graph={encode-for-uri($graph-uri)}" detailed="true">
						<c:body content-type="application/rdf+xml">{ /* }</c:body>
					</c:request>
				</p:inline>
			</p:input>
			<p:input port="parameters">
				<p:pipe step="variables" port="result"/>
			</p:input>
		</p:template>
		<p:http-request name="http-put"/>
		<!--
		<p:sink/>
		-->
		<p:store href="/tmp/last-sparql-store-response.xml" indent="true"/>
		<p:store href="/tmp/last-sparql-store-request.xml" indent="true">
			<p:input port="source">
				<p:pipe step="generate-put-request" port="result"/>
			</p:input>
		</p:store>
	</p:declare-step>
	
</p:declare-step>
