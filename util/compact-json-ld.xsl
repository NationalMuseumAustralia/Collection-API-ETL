<!-- 

TODO

compact a JSON-LD document according to a context

-->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" 
	xmlns:json-ld="tag:conaltuohy.com,2018:nma/json-ld"
	xmlns:f="http://www.w3.org/2005/xpath-functions"
	xmlns:map="http://www.w3.org/2005/xpath-functions/map">
	
	<!--
	<xsl:variable name="context" select="json-doc('linked-art.json')('@context')"/>
		TO make tweaks to context:
		map:merge(
			(
				json-doc('linked-art.json')('@context'),
				map{'type': 'rdf:type'}
			),
			map{'duplicates': 'use-last'}
		)
	-->
	
	<!-- NB our input JSON-LD has no local context, so our active context is simply equal to the Linked Art context -->
	<xsl:variable name="active-context" select="json-to-xml(unparsed-text('linked-art.json'))/f:map/f:map[@key='@context']"/>
	
	<!-- inverse context -->
	<!--
	To create an inverse context for a given active context, each term in the active context is visited, ordered by length, shortest first (ties are broken by choosing the lexicographically least term). For each term, an entry is added to the inverse context for each possible combination of container mapping and type mapping or language mapping that would legally match the term. Illegal matches include differences between a value's type mapping or language mapping and that of the term. If a term has no container mapping, type mapping, or language mapping (or some combination of these), then it will have an entry in the inverse context using the special key @none. This allows the Term Selection algorithm to fall back to choosing more generic terms when a more specifically-matching term is not available for a particular IRI and value combination.
	-->
	<xsl:variable name="inverse-context">
		<!-- Initialize result to an empty dictionary. -->
		<f:map>
			<!-- TODO: Initialize default language to @none. If the active context has a default language, set default language to it. -->
			<xsl:for-each select="$active-context/*">
				<!-- each term in the active context is visited, ordered by length, shortest first -->
				<xsl:sort select="string-length(@key)" order="ascending"/>
				<!-- (ties are broken by choosing the lexicographically least term) -->
				<xsl:sort select="@key" order="ascending"/>
				<xsl:variable name="term" select="@key"/>
				<!-- If the term definition is null, term cannot be selected during compaction, so continue to the next term. -->
				<!-- Q: why would you have a null term anyway? -->
				<xsl:if test="normalize-space($term)">
					<!-- (term is not null) -->
					<!-- Initialize container to @none. If the container mapping is not empty, set container to the concatenation of all values of the container mapping in lexicographically [sic] order. -->
					<xsl:variable name="container-mapping" select="f:string[@key='@container']"/>
					<xsl:variable name="container">
						<xsl:choose>
							<xsl:when test="normalize-space($container-mapping)">
								<f:string key="@container">
									<xsl:for-each select="tokenize($container-mapping)">
										<xsl:sort select="." order="ascending"/>
										<xsl:if test="position() &gt; 1"><xsl:text> </xsl:text></xsl:if>
										<xsl:value-of select="."/>
									</xsl:for-each>
								</f:string>
							</xsl:when>
							<xsl:otherwise>
								<f:string key="@container">@none</f:string>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<!-- 3.3 Initialize iri to the value of the IRI mapping for the term definition -->
					<xsl:variable name="iri" select="json-ld:iri-for-term($term)"/>
					<f:map key="{$iri}">
						<f:map>
							<f:map key="@language"></f:map>
							<f:map key="@type"></f:map>
							<f:map key="@any">
								<f:string key="@none"><xsl:value-of select="$term"/></f:string>
							</f:map>
						</f:map>
						<!-- up to here -->
					</f:map>
				</xsl:if>
			</xsl:for-each>
		</f:map>
	</xsl:variable>
	
	<xsl:function name="json-ld:iri-for-term">
		<xsl:param name="term"/>
		<!-- look up the term in the active context and return the corresponding IRI -->
		<xsl:variable name="term-value" select="$active-context/*[@key=$term]"/>
		<!-- If the term's value is a string, then it contains the IRI (or possibly compact IRI); if it's a dictionary, then the string whose key is "@id" contains the IRI (or compact URI) -->
		<xsl:variable name="iri-or-compact-iri" select="if ($term-value/self::f:string) then $term-value else $term-value/f:string[@key='@id']"/>
		<!-- check to see whether the prefix is a URI scheme like "htttp:", or an alias such as "dc:" or "rdf:" -->
		<xsl:variable name="prefix" select="substring-before($iri-or-compact-iri, ':')"/>
		<xsl:variable name="prefix-expansion" select="$active-context/f:string[@key=$prefix]"/>
		<xsl:variable name="iri" select="
			if ($prefix-expansion) then
				concat($prefix-expansion, substring-after($iri-or-compact-iri, ':'))
			else
				$iri-or-compact-iri
		"/>
		<xsl:value-of select="$iri"/>
	</xsl:function>
	
	<xsl:template match="/">
		<!-- https://json-ld.org/spec/latest/json-ld-api/#overview-4 -->
		<xsl:variable name="compact-json-ld-in-xml">
			<xsl:apply-templates mode="compact"/>
		</xsl:variable>
		<xsl:comment>compact json-ld as xml</xsl:comment>
		<xsl:copy-of select="$compact-json-ld-in-xml"/>
		<xsl:comment>compact json-ld</xsl:comment>
		<xsl:comment>
			<xsl:value-of select="xml-to-json($compact-json-ld-in-xml, map{'indent':true()})"/>
		</xsl:comment>
		<!--
		<xsl:comment>active context</xsl:comment>
		<xsl:copy-of select="$active-context"/>
		<xsl:comment>inverse context members:
			<xsl:value-of select="string-join($inverse-context/f:map/f:map, ', ')"/>
		</xsl:comment>
		<xsl:comment>inverse context</xsl:comment>
		<xsl:copy-of select="$inverse-context"/>
		-->
	</xsl:template>
	
	<xsl:template match="f:map" mode="compact">
		<!-- compact a map ("dictionary") -->
		<!-- 
		Otherwise element is a dictionary. The value of each key in element is compacted recursively. Some of the keys will be compacted, using the IRI Compaction algorithm, to terms or compact IRIs and others will be compacted from keywords to keyword aliases or simply left unchanged because they do not have definitions in the context. Values will be converted to compacted form via the Value Compaction algorithm. Some data will be reshaped based on container mapping specified in the context such as @index or @language maps.
		-->
		<!-- TODO follow the complete set of compaction rules -->
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:variable name="key" select="@key"/>
			<xsl:variable name="compact-key" select="$inverse-context/f:map/f:map[@key=$key]/f:map/f:map[@key='@any']/f:string[@key='@none']"/>
			<xsl:if test="$compact-key">
				<xsl:attribute name="key" select="$compact-key"/>
			</xsl:if>
			<xsl:apply-templates mode="compact"/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="f:array" mode="compact">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:variable name="key" select="@key"/>
			<xsl:variable name="compact-key" select="$inverse-context/f:map/f:map[@key=$key]/f:map/f:map[@key='@any']/f:string[@key='@none']"/>
			<xsl:if test="$compact-key">
				<xsl:attribute name="key" select="$compact-key"/>
			</xsl:if>
			<xsl:apply-templates mode="compact"/>
		</xsl:copy>
	</xsl:template>
	
	<!-- hack job on f:string - TODO follow compaction rules properly -->
	<xsl:template match="f:string" mode="compact">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:variable name="key" select="@key"/>
			<xsl:variable name="compact-key" select="$inverse-context/f:map/f:map[@key=$key]/f:map/f:map[@key='@any']/f:string[@key='@none']"/>
			<xsl:if test="$compact-key">
				<xsl:attribute name="key" select="$compact-key"/>
			</xsl:if>
			<xsl:variable name="value" select="."/>
			<xsl:variable name="compact-value"  select="$inverse-context/f:map/f:map[@key=$value]/f:map/f:map[@key='@any']/f:string[@key='@none']"/>
			<xsl:value-of select="($compact-value, $value)[1]"/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="*" mode="compact">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates mode="compact"/>
		</xsl:copy>
	</xsl:template>
	
</xsl:stylesheet>

