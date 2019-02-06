#!/bin/bash
# Generate a zip file containing documentation of the XML sousrce data; sample records, XML schemas, and interactive SVG diagrams
SCHEMA_DOC=$(dirname "$0")/schema-doc
#ZIP=${SCHEMA_DOC}.zip
echo Generating documentation from Piction and EMu XML data files into $SCHEMA_DOC ...
mkdir -p $SCHEMA_DOC
rm -f $SCHEMA_DOC/*
#rm -f $ZIP
# XSLT is in the same folder as this script
XSLT=$(dirname "$0")/make-sample.xsl

for XML in /mnt/dams_data/solr_prod1.xml /mnt/emu_data/full/*.xml
do
	FILE_WITH_EXT=${XML##*/}
	FILE=${FILE_WITH_EXT%.*}
	XSD=${SCHEMA_DOC}/${FILE}.xsd
	SAMPLE=${SCHEMA_DOC}/${FILE}-SAMPLE.xml
	echo Processing $FILE ...
	trang -I xml -O xsd $XML $XSD
	# run xsvdi in the schema-doc folder because xsvdi always writes output files in the current directory
	pushd $SCHEMA_DOC && java -jar /usr/local/xsdvi/dist/lib/xsdvi.jar $XSD && popd
	java -cp /usr/local/xmlcalabash/lib/Saxon-HE-9.8.0-8.jar net.sf.saxon.Transform -s:$XML -xsl:$XSLT -o:$SAMPLE
done
rm ${SCHEMA_DOC}/xsdvi.log

#echo Archiving as $ZIP ...
#zip -r $ZIP $SCHEMA_DOC

