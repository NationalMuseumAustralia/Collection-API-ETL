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
/*
import javax.xml.bind.JAXBException;
import javax.xml.bind.JAXBContext;
import javax.xml.bind.JAXBElement;
import javax.xml.bind.Unmarshaller;
*/

import org.w3c.dom.Node;



import java.lang.reflect.Proxy;
import java.lang.reflect.Method;
import java.lang.reflect.InvocationHandler;
import java.lang.reflect.InvocationTargetException;

public class FileSplitter {
	
	public static void main(String[] args) {
		new FileSplitter(args);
	}
	
	FileSplitter(String[] args) {
		// read the command line arguments
		if (args.length < 4) {
			System.out.println("Splits an XML file, writing each acceptable top-level element into a separate file, named according to an XPath 1.0 expression.");
			System.out.println("The fragment-acceptable-xpath expression should return true if the fragment is to be saved, and false if it is to be ignored.");
			System.out.println("The fragment-name-xpath expression should return an output file name.");
			System.out.println("If any fragment is acceptable but is missing a name, then processing halts.");
			System.out.println();
			System.out.println("Required parameters:");
			System.out.println(" • input-file-name");
			System.out.println(" • output-folder-name");
			System.out.println(" • fragment-acceptable-xpath");
			System.out.println(" • fragment-name-xpath");
			System.out.println();
			System.out.println("e.g. /mnt/dams_data/solr_prod1.xml /data/cache/piction \"/doc/field[@name='Multimedia ID']\" \"(/doc/field[@name='Multimedia ID'])[1]\"");
			System.exit(-1);
		}
		String inputFileName = args[0];
		String outputFolderName = args[1];
		String fragmentAcceptableXPath = args[2];
		String fragmentNameXPath = args[3];
		try {
			// Set up infrastructure
			// First a transformer
			Transformer transformer = TransformerFactory.newInstance().newTransformer();
			transformer.setOutputProperty(OutputKeys.ENCODING, "UTF-8");
			transformer.setOutputProperty(OutputKeys.INDENT, "yes");
			transformer.setOutputProperty(OutputKeys.STANDALONE, "yes");
			transformer.setOutputProperty(OutputKeys.OMIT_XML_DECLARATION, "yes");
			
			// Set up XPath
			XPath xPath = XPathFactory.newInstance().newXPath();
			
			// StAX stream reader for the input file
			// This XMLStreamReader will return null from getVersion() if the source document doesn't include an XML version in its XML declaration
			XMLStreamReader unversionedXmlStreamReader = XMLInputFactory.newInstance().createXMLStreamReader(new FileReader(inputFileName));
			// This XMLStreamReader wraps the above, and returns "1.0" intead of null if the source document doesn't include have an XML version
			XMLStreamReader xmlStreamReader = (XMLStreamReader) Proxy.newProxyInstance(
				XMLStreamReader.class.getClassLoader(),
				new Class<?>[] { XMLStreamReader.class },
				new XMLStreamReaderVersion1Proxy(unversionedXmlStreamReader)
			);
			
			// Create the output directory if necessary
			new File(outputFolderName).mkdirs();
			
			// Read the first tag, the opening tag of the root element
			xmlStreamReader.nextTag();
			// Now read each child element of the root element and all its descendants into a DOM
			int count = 0;
			int state = xmlStreamReader.next(); // The next parsed token, which may be the opening tag of the child element
			while (xmlStreamReader.hasNext()) {
				if (xmlStreamReader.getEventType() != XMLStreamConstants.START_ELEMENT) {
					xmlStreamReader.next();
				} else {
					// Marshal the stream into a Document
					StAXSource fragmentSource = new StAXSource(xmlStreamReader);
					DOMResult domResult = new DOMResult();
					transformer.transform(fragmentSource, domResult);
					Node fragmentRoot = domResult.getNode(); 
					// Fheck if the Document is acceptable and should be saved
					Boolean acceptable = (Boolean) xPath.evaluate(fragmentAcceptableXPath, fragmentRoot, XPathConstants.BOOLEAN);
					if (acceptable) {
						// Fnd the file name
						String fileName = ((String) xPath.evaluate(fragmentNameXPath, fragmentRoot, XPathConstants.STRING)).trim();
						if (fileName.isEmpty()) {
							// The document is supposedly acceptable, but we have no filename to save it under
							// Dump the document to standard error
							transformer.transform(
								new DOMSource(fragmentRoot),
								new StreamResult(System.err)
							);
							throw new RuntimeException("No filename computed for record");
						} else {
							// the document can be saved under the filename
							transformer.transform(
								new DOMSource(fragmentRoot),
								new StreamResult(new File(outputFolderName, fileName+ ".xml"))
							);
						}
					}
				}
			}
		} catch (FileNotFoundException | XMLStreamException | TransformerException | XPathExpressionException e1) {
			e1.printStackTrace();
			System.exit(-1);
		}
	}
	/**
	* A dynamic proxy which wraps an XMLStreamReader and ensures that its getVersion() method always returns an explicit version, never null.
	* If the underlying XMLStreamReader.getVersion() returns null, this proxy returns "1.0" instead.
	* This is to work around a bug in certain versions of com.sun.org.apache.xalan.internal.xsltc.trax.SAX2DOM.setDocumentInfo()
	* which rashly attempts to assign such a null version string to an output document, causing a NullPointerException.
	*/
	public class XMLStreamReaderVersion1Proxy implements InvocationHandler {
		private XMLStreamReader xmlStreamReader;
		XMLStreamReaderVersion1Proxy(XMLStreamReader xmlStreamReader) {
			this.xmlStreamReader = xmlStreamReader;
		}
		public Object invoke(Object proxy, Method m, Object[] args) throws Throwable {
			Object result;
			try {
				result = m.invoke(xmlStreamReader, args);
				if (result == null && m.getName().equals("getVersion")) {
					result = "1.0";
				}
			} catch (InvocationTargetException e) {
				throw e.getTargetException();
			} catch (Exception e) {
				throw new RuntimeException("unexpected invocation exception: " + e.getMessage());
			}
			return result;
		}

	}
}

