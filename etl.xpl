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
	<pxf:mkdir href="/data/split"/>
	<p:load name="emu-objects" href="/data/Emu_Objects_77659.xml"/>
	<!--
	<p:for-each>
		<p:iteration-source select="/response/record"/>
		<p:store>
			<p:with-option name="href" select="concat('/data/split/', /record/obj_irn, '.xml')"/>
		</p:store>
	</p:for-each>
	-->
	<p:xslt name="emu-objects-to-solr">
		<p:input port="stylesheet">
			<p:document href="emu-objects-to-solr.xsl"/>
		</p:input>
		<p:input port="parameters">
			<p:empty/>
		</p:input>
	</p:xslt>
	<!--<p:store href="/data/objects-solr.xml"/>-->
	<p:http-request name="solr-deposit"/>
	<p:sink/>
	
</p:declare-step>
