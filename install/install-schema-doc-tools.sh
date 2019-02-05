#!/bin/bash
# Install the Schema generation (Trang) and visualization (XSDVI) tools
XSDVI_DIR=/usr/local/xsdvi/

# Trang
apt install -y trang

#XSDVI
mkdir $XSDVI_DIR
cd $XSDVI_DIR
wget https://downloads.sourceforge.net/project/xsdvi/xsdvi/xsdvi-1.0/xsdvi.zip -O xsdvi.zip
unzip xsdvi.zip
