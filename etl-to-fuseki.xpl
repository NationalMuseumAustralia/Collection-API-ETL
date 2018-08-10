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
	<p:option name="dataset" required="true"/>
	
	<p:exec name="read-hostname" command="hostname" result-is-xml="false">
		<p:input port="source">
			<!-- the linux "hostname" command will not be sent any input -->
			<p:empty/>
		</p:input>
	</p:exec>
	<p:group>
		<!-- capture the hostname so we can make URIs relative to this host -->
		<p:variable name="hostname" select="normalize-space(/)"/>
		<p:sink name="discard-hostname"/>
		
		<!-- load our local vocabulary data -->
		<nma:load-vocabulary>
			<p:with-option name="dataset" select="$dataset"/>
			<p:with-option name="incremental" select="$incremental"/>
			<p:with-option name="hostname" select="$hostname"/>
		</nma:load-vocabulary>

		<!-- process Piction image metadata -->
		<nma:process-piction-data name="import-images">
			<p:with-option name="dataset" select="$dataset"/>
			<p:with-option name="incremental" select="$incremental"/>
			<p:with-option name="hostname" select="$hostname"/>
		</nma:process-piction-data>
		
		<!-- process EMu objects, places, parties, collections, and narratives -->
		<nma:process-data name="narratives" file-name-component="narratives">
			<p:with-option name="dataset" select="$dataset"/>
			<p:with-option name="incremental" select="$incremental"/>
			<p:with-option name="hostname" select="$hostname"/>
		</nma:process-data>

		<nma:process-data name="objects" file-name-component="objects">
			<p:with-option name="dataset" select="$dataset"/>
			<p:with-option name="incremental" select="$incremental"/>
			<p:with-option name="hostname" select="$hostname"/>
		</nma:process-data>

		<nma:process-data name="sites" file-name-component="sites">
			<p:with-option name="dataset" select="$dataset"/>
			<p:with-option name="incremental" select="$incremental"/>
			<p:with-option name="hostname" select="$hostname"/>
		</nma:process-data>

		<nma:process-data name="parties" file-name-component="parties">
			<p:with-option name="dataset" select="$dataset"/>
			<p:with-option name="incremental" select="$incremental"/>
			<p:with-option name="hostname" select="$hostname"/>
		</nma:process-data>

		<nma:process-data name="collections" file-name-component="accessionlots">
			<p:with-option name="dataset" select="$dataset"/>
			<p:with-option name="incremental" select="$incremental"/>
			<p:with-option name="hostname" select="$hostname"/>
		</nma:process-data>
		
	</p:group>
	
	<p:declare-step name="load-vocabulary" type="nma:load-vocabulary">
		<p:option name="dataset" required="true"/>
		<p:option name="hostname" required="true"/>
		<p:option name="incremental" required="true"/>
		<p:load href="vocabulary.rdf" name="raw-vocabulary"/>
		<cx:message message="Loading local RDF vocabularies into SPARQL store..."/>
		<p:add-attribute attribute-name="xml:base" match="/*" name="localised-vocabulary">
			<p:with-option name="attribute-value" select="concat('http://', $hostname, '/term/')"/>
		</p:add-attribute>
		<nma:store-graph>
			<p:with-option name="dataset" select="$dataset"/>
			<p:with-option name="incremental" select="$incremental"/>
			<p:with-option name="graph-uri" select="concat('http://', $hostname, '/fuseki/', $dataset, '/data/vocabulary')"/>
		</nma:store-graph>
	</p:declare-step>
	
	<p:declare-step type="nma:list-input-data-files" name="list-input-data-files">
		<p:option name="file-name-component" required="true"/>
		<p:option name="incremental" required="true"/>
		<p:output port="result"/>
		<p:variable name="input-folder" select="if ($incremental = 'true') then '/mnt/emu_data/incremental' else '/mnt/emu_data/full' "/>
		<!-- search the input folder for files whose names contain the record type -->
		<p:directory-list>
			<p:with-option name="path" select="$input-folder"/>
			<p:with-option name="include-filter" select="
				concat(
					'.*',
					$file-name-component,
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
	
	<p:declare-step name="process-piction-data" type="nma:process-piction-data">
		<p:option name="hostname" required="true"/>
		<p:option name="dataset" required="true"/>
		<p:option name="incremental" required="true"/>
		<!-- current date, used to tag new records and exclude old records, where necessary -->
		<p:variable name="current-date" select="current-date()"/>
		<!-- the file which contains previously processed version of the piction data -->
		<p:variable name="piction-cache" select="
			concat(
				'/data/cache/piction-',
				$dataset,
				'.xml'
			)
		"/>
		<p:documentation>the file containing the current, as yet unprocessed, piction data</p:documentation>
		<p:load name="new-piction-data" href="/mnt/dams_data/solr_prod1.xml"/>
		<p:documentation>track the "last-updated" date of the individual records</p:documentation>
		<p:try name="cached-piction-data">
			<p:group name="load-cached-piction-data">
				<p:output port="result"/>
				<cx:message message="Loading cached Piction data..."/>
				<p:load>
					<p:with-option name="href" select="$piction-cache"/>
				</p:load>
			</p:group>
			<p:catch name="no-cached-data">
				<p:output port="result"/>
				<cx:message message="No cached Piction data found, using current data..."/>
				<p:add-attribute match="/add/doc" attribute-name="date-modified">
					<p:with-option name="attribute-value" select="$current-date"/>
				</p:add-attribute>
			</p:catch>
		</p:try>
		<p:documentation>aggregate the new and cached piction, for comparison</p:documentation>
		<p:wrap-sequence name="new-and-cached-piction-data" wrapper="comparison">
			<p:input port="source">
				<p:pipe step="new-piction-data" port="result"/>
				<p:pipe step="cached-piction-data" port="result"/>
			</p:input>
		</p:wrap-sequence>
		<p:documentation>generate a version of the new piction data, with date-modified attribute on each record</p:documentation>
		<p:xslt name="compute-date-modified">
			<p:with-param name="current-date" select="$current-date"/>
			<p:input port="source">
				<p:pipe step="new-and-cached-piction-data" port="result"/>
			</p:input>
			<p:input port="stylesheet">
				<p:document href="compute-piction-date-modified.xsl"/>
			</p:input>
		</p:xslt>
		<p:documentation>for incremental updates, exclude records which have not changed since the previously cached versions</p:documentation>
		<p:choose name="ingestible-piction-records">
			<p:when test=" $incremental = 'true' ">
				<p:output port="result"/>
				<p:xslt name="exclude-unchanged-records">
					<p:with-param name="current-date" select="$current-date"/>
					<p:input port="source">
						<p:pipe step="new-and-cached-piction-data" port="result"/>
					</p:input>
					<p:input port="stylesheet">
						<p:document href="exclude-unchanged-piction-records.xsl"/>
					</p:input>		
				</p:xslt>
			</p:when>
			<p:otherwise>
				<p:output port="result"/>
				<p:identity name="include-all-piction-records"/>
			</p:otherwise>
		</p:choose>
		<cx:message>
			<p:with-option name="message" select="
				concat(
					'Processing ',
					count(/add/doc),
					' updated Piction records ...'
				)
			"/>
		</cx:message>
		<p:documentation>First make any necessary redactions before publishing to the specified dataset.
		NB 'public' dataset omits certains data, which are present only in the 'internal' dataset</p:documentation>
		<p:xslt name="redact">
			<p:with-param name="dataset" select="$dataset"/>
			<p:input port="stylesheet">
				<p:document href="filter.xsl"/>
			</p:input>
		</p:xslt>
		<p:for-each name="record">
			<p:iteration-source select="/add/doc"/>
			<nma:ingest-record name="save-the-piction-rdf">
				<p:with-option name="file-name-component" select=" 'piction' "/>
				<p:with-option name="dataset" select="$dataset"/>        
				<p:with-option name="hostname" select="$hostname"/>
				<p:with-option name="incremental" select="$incremental"/>
			</nma:ingest-record>
		</p:for-each>
		<cx:message message="Caching Piction data..." cx:depends-on="record">
			<p:input port="source">
				<p:pipe step="ingestible-piction-records" port="result"/>
			</p:input>
		</cx:message>
		<p:store indent="true">
			<p:with-option name="href" select="$piction-cache"/>
		</p:store>
	</p:declare-step>	
	
	<p:declare-step name="process-data" type="nma:process-data">
		<p:option name="file-name-component" required="true"/>
		<p:option name="hostname" required="true"/>
		<p:option name="dataset" required="true"/>
		<p:option name="incremental" required="true"/>
		<!-- search the input folder 'data' for data files containing records of this type -->
		<nma:list-input-data-files>
			<p:with-option name="file-name-component" select="$file-name-component"/>
			<p:with-option name="incremental" select="$incremental"/>
		</nma:list-input-data-files>
		<p:for-each name="file">
			<p:iteration-source select="//c:file"/>
			<p:variable name="filename" select="/c:file/@name"/>
			<cx:message>
				<p:with-option name="message" select="
					concat(
						'Reading ', 
						$file-name-component, 
						' input file ', 
						$filename, 
						' ...'
					)
				"/>
			</cx:message>
			<p:load>
				<p:with-option name="href" select="$filename"/>
			</p:load>
			<!-- make any necessary redactions before publishing to the specified dataset  -->
			<!-- NB 'public' dataset omits certains data, which are present only in the 'internal' dataset -->
			<p:xslt name="redact">
				<p:with-param name="dataset" select="$dataset"/>
				<p:input port="stylesheet">
					<p:document href="filter.xsl"/>
				</p:input>
			</p:xslt>
			<p:for-each name="record">
				<p:iteration-source select="/response/record"/>
				<!-- If AdmDateModified missing, insert an arbitrary date in the past -->
				<p:insert match="/record[not(AdmDateModified)]" position="last-child">
					<p:input port="insertion">
						<p:inline>
							<AdmDateModified>01/01/2018</AdmDateModified>
						</p:inline>
					</p:input>
				</p:insert>
				<nma:ingest-record>
					<p:with-option name="file-name-component" select="$file-name-component"/>
					<p:with-option name="dataset" select="$dataset"/>        
					<p:with-option name="hostname" select="$hostname"/>
					<p:with-option name="incremental" select="$incremental"/>
				</nma:ingest-record>
			</p:for-each>
		</p:for-each>
		<p:sink/>
	</p:declare-step>
	
	<p:declare-step type="nma:ingest-record" name="ingest-record">
		<!-- accepts a single XML record, transforms it to RDF and deposits it in the SPARQL graph store -->
		<p:option name="file-name-component" required="true"/><!-- base name of the source file containing this record -->
		<p:option name="dataset" required="true"/><!-- "public" or "internal" -->
		<p:option name="hostname" required="true"/><!-- e.g. "nma.conaltuohy.com" or "data.nma.gov.au" -->
		<p:option name="incremental" required="true"/><!-- 'true' if graph store is to be updated incrementally; 'false' for a full rebuild -->
		<p:input port="source"/>
		<!-- EMu records are uniquely identified by /response/record/irn, Piction records by /doc/field[@name='Multimedia ID'] -->
		<p:variable name="identifier" select="/record/irn | doc/field[@name='Multimedia ID']"/>
		<cx:message>
			<p:with-option name="message" select="concat('Transforming ', $file-name-component, ' record ', $identifier, ' for ', $dataset, ' dataset...')"/>
		</cx:message>
		<p:choose name="transformation-to-rdf">
			<p:when test="$file-name-component = 'piction'">
				<p:output port="result"/>
				<p:xslt name="piction-to-rdf">
					<p:with-param name="base-uri" select="concat('http://', $hostname, '/')"/>
					<p:input port="stylesheet">
						<p:document href="piction-to-rdf.xsl"/>
					</p:input>
				</p:xslt>
			</p:when>
			<p:otherwise>
				<p:output port="result"/>
				<p:xslt name="emu-objects-to-rdf">
					<p:with-param name="base-uri" select="concat('http://', $hostname, '/')"/>
					<p:input port="stylesheet">
						<p:document href="emu-to-crm.xsl"/>
					</p:input>
				</p:xslt>
			</p:otherwise>
		</p:choose>
		<nma:store-graph>
			<p:with-option name="graph-uri" select="concat('http://', $hostname, '/fuseki/', $dataset, '/data/', $file-name-component, '/', $identifier)"/>
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
<!--
		<p:store indent="true">
			<p:with-option name="href" select="concat('/data/', $dataset, '/rdf-xml/', encode-for-uri(encode-for-uri($graph-uri)), '.rdf')"/>
			<p:input port="source">
				<p:pipe step="store-graph" port="source"/>
			</p:input>
		</p:store>
-->
	</p:declare-step>
	
</p:declare-step>
