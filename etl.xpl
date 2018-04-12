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
	
	<p:option name="incremental" required="true"/>
	
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
			<p:with-option name="incremental" select="$incremental"/>
			<p:with-option name="hostname" select="$hostname"/>
		</nma:load-vocabulary>
		
		<!-- process Piction image metadata -->
		<nma:process-data record-type="piction" dataset="public">
			<p:with-option name="incremental" select="$incremental"/>
			<p:with-option name="hostname" select="$hostname"/>
		</nma:process-data>
		
		<!-- process EMu objects, places, parties, collections, and narratives -->
		<nma:process-data record-type="object" dataset="public">
			<p:with-option name="incremental" select="$incremental"/>
			<p:with-option name="hostname" select="$hostname"/>
		</nma:process-data>

		<nma:process-data record-type="narrative" dataset="public">
			<p:with-option name="incremental" select="$incremental"/>
			<p:with-option name="hostname" select="$hostname"/>
		</nma:process-data>

		<nma:process-data record-type="place" dataset="public">
			<p:with-option name="incremental" select="$incremental"/>
			<p:with-option name="hostname" select="$hostname"/>
		</nma:process-data>

		<nma:process-data record-type="party" dataset="public">
			<p:with-option name="incremental" select="$incremental"/>
			<p:with-option name="hostname" select="$hostname"/>
		</nma:process-data>

		<nma:process-data record-type="collection" dataset="public">
			<p:with-option name="incremental" select="$incremental"/>
			<p:with-option name="hostname" select="$hostname"/>
		</nma:process-data>
	</p:group>
	
	<p:declare-step name="load-vocabulary" type="nma:load-vocabulary">
		<p:option name="hostname" required="true"/>
		<p:option name="incremental" required="true"/>
		<p:load href="vocabulary.rdf" name="raw-vocabulary"/>
		<cx:message message="Loading local RDF vocabularies into SPARQL store..."/>
		<p:add-attribute attribute-name="xml:base" match="/*" name="localised-vocabulary">
			<p:with-option name="attribute-value" select="concat('http://', $hostname, '/xproc-z/term/')"/>
		</p:add-attribute>
		<nma:store-graph dataset="public">
			<p:with-option name="incremental" select="$incremental"/>
			<p:with-option name="graph-uri" select="concat('http://', $hostname, '/fuseki/', $dataset, '/data/vocabulary')"/>
		</nma:store-graph>
	</p:declare-step>
	
	<p:declare-step type="nma:list-input-data-files" name="list-input-data-files">
		<p:option name="record-type" required="true"/>
		<p:option name="incremental" required="true"/>
		<p:output port="result"/>
		<p:variable name="input-folder" select="if ($incremental = 'true') then '/data/incremental' else '/data/full' "/>
		<!-- search the input folder for files whose names contain the record type -->
		<p:directory-list>
			<p:with-option name="path" select="$input-folder"/>
			<p:with-option name="include-filter" select="
				concat(
					'.*',
					$record-type,
					'.*\.xml'
				)
			"/>
		</p:directory-list>
		<p:xslt name="sort-input-files-sequentially">
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="stylesheet">
				<p:inline>
					<xsl:stylesheet version="2.0"
						xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
						xmlns:c="http://www.w3.org/ns/xproc-step">
						<xsl:template match="/c:directory">
							<xsl:copy>
								<xsl:copy-of select="@*"/>
								<xsl:for-each select="c:file">
									<xsl:sort select="@name" order="ascending"/>
									<xsl:copy>
										<xsl:attribute name="name" select="concat(/c:directory/@xml:base, @name)"/>
									</xsl:copy>
								</xsl:for-each>
							</xsl:copy>
						</xsl:template>
					</xsl:stylesheet>
				</p:inline>
			</p:input>
		</p:xslt>		
	</p:declare-step>
	
	<p:declare-step name="process-data" type="nma:process-data">
		<p:option name="record-type" required="true"/>
		<p:option name="hostname" required="true"/>
		<p:option name="dataset" required="true"/>
		<p:option name="incremental" required="true"/>
		<!-- search the input folder 'data' for data files containing records of this type -->
		<nma:list-input-data-files>
			<p:with-option name="record-type" select="$record-type"/>
			<p:with-option name="incremental" select="$incremental"/>
		</nma:list-input-data-files>
		<p:for-each name="file">
			<p:iteration-source select="//c:file"/>
			<cx:message>
				<p:with-option name="message" select="
					concat(
						'Reading ', 
						$record-type, 
						' input file ', 
						/c:file/@name, 
						' ...'
					)
				"/>
			</cx:message>
			<p:load>
				<p:with-option name="href" select="/c:file/@name"/>
			</p:load>
			<p:for-each name="record">
				<p:iteration-source select="/response/record | /add/doc"/>
				<!-- EMu records are /response/record, Piction records are /add/doc -->
				<!-- EMu "partial-update" records are excluded from this processing, and handled separately below -->
				<!-- because a partial-update can't be handled by transforming the record to an RDF graph and storing it using the SPARQL Graph Store protocol; -->
				<!-- instead it has to delete a triple from a graph and insert a new one, using the SPARQL Update protocol -->
				<p:choose>
					<p:when test="/record[partial-update]">
						<nma:partial-update>
							<p:with-option name="dataset" select="$dataset"/>        
							<p:with-option name="hostname" select="$hostname"/>
						</nma:partial-update>
					</p:when>
					<p:otherwise>
						<nma:ingest-record>
							<p:with-option name="record-type" select="$record-type"/>
							<p:with-option name="dataset" select="$dataset"/>        
							<p:with-option name="hostname" select="$hostname"/>
							<p:with-option name="incremental" select="$incremental"/>
						</nma:ingest-record>
					</p:otherwise>
				</p:choose>
			</p:for-each>
		</p:for-each>
	</p:declare-step>
	
	<p:declare-step type="nma:partial-update" name="partial-update">
		<!-- Process "partial-update" records which apply to objects only (not the other entity types) -->
		<!-- EMu "partial-update" records can't be handled by transforming the record to an RDF graph and storing it using the SPARQL Graph Store protocol; -->
		<!-- instead, each partial update must delete a triple from an existing graph and insert a new triple in its place, using the SPARQL Update protocol -->
		<!-- EMu records are uniquely identified by /response/record/irn -->
		<p:option name="dataset" required="true"/><!-- "public" or "internal" -->
		<p:option name="hostname" required="true"/><!-- e.g. "nma.conaltuohy.com" or "data.nma.gov.au" -->
		<p:input port="source"/>
		<p:variable name="identifier" select="/record/irn"/>
		<cx:message>
			<p:with-option name="message" select="concat('Partially updating object ', $identifier, ' in ', $dataset, ' dataset...')"/>
		</cx:message>
		<!-- TODO generate and execute the appropriate SPARQL update -->
		<p:sink name="simply-ignore-the-partial-update-record-for-now"/>
	</p:declare-step>
	
	<p:declare-step type="nma:ingest-record" name="ingest-record">
		<!-- accepts a single XML record, transforms it to RDF and deposits it in the SPARQL graph store -->
		<p:option name="record-type" required="true"/><!-- "object", "image", "place", "party", or "narrative" -->
		<p:option name="dataset" required="true"/><!-- "public" or "internal" -->
		<p:option name="hostname" required="true"/><!-- e.g. "nma.conaltuohy.com" or "data.nma.gov.au" -->
		<p:option name="incremental" required="true"/><!-- 'true' if graph store is to be updated incrementally; 'false' for a full rebuild -->
		<p:input port="source"/>
		<!-- EMu records are uniquely identified by /response/record/irn, Piction records by /doc/field[@name='Multimedia ID'] -->
		<p:variable name="identifier" select="/record/irn | doc/field[@name='Multimedia ID']"/>
		<cx:message>
			<p:with-option name="message" select="concat('Transforming ', $record-type, ' record ', $identifier, ' for ', $dataset, ' dataset...')"/>
		</cx:message>
		<p:choose name="transformation-to-rdf">
			<p:when test="$record-type='image'">
				<p:output port="result"/>
				<p:xslt name="piction-to-rdf">
					<p:with-param name="base-uri" select="concat('http://', $hostname, '/xproc-z/')"/>
					<p:with-param name="record-type" select="$record-type"/>
					<p:input port="stylesheet">
						<p:document href="piction-to-rdf.xsl"/>
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
				</p:xslt>
			</p:otherwise>
		</p:choose>
		<nma:store-graph>
			<p:with-option name="graph-uri" select="concat('http://', $hostname, '/fuseki/', $dataset, '/data/', $record-type, '/', $identifier)"/>
			<p:with-option name="dataset" select="$dataset"/>
			<p:with-option name="incremental" select="$incremental"/>
		</nma:store-graph>
		<p:sink/>
	</p:declare-step>
	
	<!-- store graph in SPARQL store or as n-quads file if @incremental=false -->
	<p:declare-step type="nma:store-graph" name="store-graph">
		<p:input port="source"/>
		<p:option name="graph-uri" required="true"/>
		<p:option name="dataset" required="true"/>
		<p:option name="incremental" required="true"/><!-- 'true' or 'false' -->
		<p:choose>
			<p:when test=" $incremental = 'true' ">
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
				<p:store href="/tmp/last-sparql-store-response.xml" indent="true"/>
				<p:store href="/tmp/last-sparql-store-request.xml" indent="true">
					<p:input port="source">
						<p:pipe step="generate-put-request" port="result"/>
					</p:input>
				</p:store>
			</p:when>
			<p:otherwise>
				<!-- not an incremental update: instead we will generate a full dataset, saving each graph as an nquads file, -->
				<!-- and use them to build a new dataset for Fuseki with the tdb2.tdbloader command line tool. -->
				<p:xslt name="convert-to-nquads">
					<p:with-param name="graph" select="$graph-uri"/>
					<p:input port="stylesheet">
						<p:document href="rdf-xml-to-nquads.xsl"/>
					</p:input>
				</p:xslt>
				<p:store method="text">
					<p:with-option name="href" select="concat('/data/', $dataset, '/n-quads/', encode-for-uri(encode-for-uri($graph-uri)), '.nq')"/>
					<p:input port="source">
						<p:pipe step="convert-to-nquads" port="result"/>
					</p:input>
				</p:store>
			</p:otherwise>
		</p:choose>
		<!-- store the RDF/XML as a file -->
		<p:store indent="true">
			<p:with-option name="href" select="concat('/data/', $dataset, '/rdf-xml/', encode-for-uri(encode-for-uri($graph-uri)), '.rdf')"/>
			<p:input port="source">
				<p:pipe step="store-graph" port="source"/>
			</p:input>
		</p:store>		
	</p:declare-step>
	
</p:declare-step>
