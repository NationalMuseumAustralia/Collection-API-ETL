import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;

import javax.xml.stream.XMLInputFactory;
import javax.xml.stream.XMLStreamConstants;
import javax.xml.stream.XMLStreamException;
import javax.xml.stream.XMLStreamReader;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMResult;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stax.StAXSource;
import javax.xml.transform.stream.StreamResult;
import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathExpressionException;
import javax.xml.xpath.XPathFactory;

import javax.xml.bind.JAXBException;
import javax.xml.bind.JAXBContext;
import javax.xml.bind.JAXBElement;
import javax.xml.bind.Unmarshaller;


import org.w3c.dom.Node;

public class FileSplitter {

	public static void main(String[] args) {
		// read the command line arguments
		if (args.length < 3) {
			System.out.println("Splits an XML file, writing each top-level element into a separate file, named according to an XPath 1.0 expression.");
			System.out.println();
			System.out.println("Required parameters:");
			System.out.println(" • input-file-name");
			System.out.println(" • output-folder-name");
			System.out.println(" • fragment-name-xpath");
			System.out.println();
			System.out.println("e.g. /mnt/dams_data/solr_prod1.xml /data/cache/piction \"(/doc/field[@name='Multimedia ID'])[1]\"");
			System.exit(-1);
		}
		String inputFileName = args[0];
		String outputFolderName = args[1];
		String fragmentNameXPath = args[2];
		try {
			// set up infrastructure
			// first a transformer
			Transformer transformer = TransformerFactory.newInstance().newTransformer();
			transformer.setOutputProperty(OutputKeys.ENCODING, "UTF-8");
			transformer.setOutputProperty(OutputKeys.INDENT, "yes");
			// set up XPath
			XPath xPath = XPathFactory.newInstance().newXPath();
			// StAX stream reader for the input file
			XMLStreamReader xmlStreamReader = XMLInputFactory.newInstance()
					.createXMLStreamReader(new FileReader(inputFileName));
			// JAXB unmarshaller
			final JAXBContext jaxbContext = JAXBContext.newInstance();
			final Unmarshaller unmarshaller = jaxbContext.createUnmarshaller();

			// read the next (i.e. first) tag, the root element
			xmlStreamReader.nextTag();
			// now read each child element of the root element and all its descendants into
			// a DOM
			int state = xmlStreamReader.nextTag();
			while (xmlStreamReader.hasNext()) {
				if (state == XMLStreamConstants.START_ELEMENT) {
					JAXBElement<Object> element = unmarshaller.unmarshal(xmlStreamReader, Object.class);
					Node fragmentRoot = (Node) element.getValue();
					/*
					// create a DOM result to accept the transformed output
					DOMResult domResult = new DOMResult();
					// the StAXSource reads the current node and all its descendants into the DOM
					// advancing the XMLStreamReader to the next tag if any
					transformer.transform(new StAXSource(xmlStreamReader), domResult);
					// get the root node of the fragment DOM from the DOMResult
					Node fragmentRoot = domResult.getNode();
					*/
					// find the file name
					Node fragmentNameNode = (Node) xPath.evaluate(fragmentNameXPath, fragmentRoot, XPathConstants.NODE);
					if (fragmentNameNode == null)
						continue;
					String fileName = fragmentNameNode.getTextContent();
					if (fileName == null)
						continue;
					fileName = fileName.trim();
					if (fileName.isEmpty())
						continue;
					// can save to file
					transformer.transform(new DOMSource(fragmentRoot),
							new StreamResult(new File(outputFolderName, fileName+ ".xml")));
				}
				// advance to the next start element only if the state is not already START_ELEMENT
				if (! xmlStreamReader.isStartElement()) {
					state = xmlStreamReader.next();
				}
			}
		} catch (FileNotFoundException | XMLStreamException | TransformerException | XPathExpressionException | JAXBException e1) {
			e1.printStackTrace();
			System.exit(-1);
		}
	}

}

