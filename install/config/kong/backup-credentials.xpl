<p:declare-step 
	name="backup-credentials"
	version="1.0" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:fn="http://www.w3.org/2005/xpath-functions" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:nma="tag:conaltuohy.com,2018:nma"
	xmlns:kong="tag:conaltuohy.com,2018:kong"
	xmlns:pxf="http://exproc.org/proposed/steps/file"
	xmlns:cx="http://xmlcalabash.com/ns/extensions"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
>
	<!-- import calabash extension library to enable use of file steps -->
	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
	<p:import href="kong-library.xpl"/>
	
	<!-- URI of output file -->
	<p:option name="output" required="true"/>

	<!-- TODO export the data about the members of the internal and public groups -->
	<kong:read name="get-consumers" uri="http://localhost:8001/consumers/?size=1000"/>
	<!--<p:wrap wrapper="consumers" match="/*"/>-->
	<kong:read name="get-keys" uri="http://localhost:8001/key-auths/?size=1000"/>
	<!--<p:wrap wrapper="keys" match="/*"/>-->
	<p:wrap-sequence wrapper="credential-backup">
		<p:input port="source">
			<p:pipe step="get-consumers" port="result"/>
			<p:pipe step="get-keys" port="result"/>
		</p:input>
	</p:wrap-sequence>
	<p:store name="save-file" indent="true">
		<p:with-option name="href" select="$output"/>
	</p:store>
</p:declare-step>