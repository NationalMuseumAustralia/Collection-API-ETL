#!/bin/bash
echo Generating documentation from Piction and EMu XML data files into ~/schema-doc/ ...
echo Generating XSD files ...
mkdir -p ~/schema-doc/
cd ~/schema-doc/
trang -I xml -O xsd /mnt/dams_data/solr_prod1.xml piction.xsd
trang -I xml -O xsd /mnt/emu_data/full/*_objects_*.xml objects.xsd
trang -I xml -O xsd /mnt/emu_data/full/*_accessionlots_*.xml accession-lots.xsd
trang -I xml -O xsd /mnt/emu_data/full/*_narratives_*.xml narratives.xsd
trang -I xml -O xsd /mnt/emu_data/full/*_parties_*.xml parties.xsd
trang -I xml -O xsd /mnt/emu_data/full/*_sites_*.xml sites.xsd
echo Generating SVG files ...
for SCHEMA in *.xsd 
do
	echo $SCHEMA
	java -jar /usr/local/xsdvi/dist/lib/xsdvi.jar $SCHEMA
done
echo Archiving as ~/schema-doc.zip ...
zip -r ../schema-doc.zip .

