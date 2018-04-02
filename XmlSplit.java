import java.io.File;
import java.io.FileReader;
import java.io.BufferedReader;
import javax.xml.stream.XMLInputFactory;
import javax.xml.stream.XMLStreamConstants;
import javax.xml.stream.XMLStreamReader;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.stax.StAXSource;
import javax.xml.transform.stream.StreamResult;

// source: https://stackoverflow.com/a/20144537
// fix: https://stackoverflow.com/a/14529983

/**
 * Splits an XML file into a separate XML file for each 2nd level tag.
 */
public class XmlSplit {

	public static void main(String[] args) throws Exception {
		if (args == null || args.length < 2) {
			System.out.println("Usage: " + XmlSplit.class.getName() + " FILE OUTPUT-DIRECTORY");
			System.exit(1);
		}

		String xmlFile = args[0];
		File dir = new File(args[1]);
		dir.mkdirs();

		TransformerFactory transformerFactory = TransformerFactory.newInstance();
		Transformer transformer = transformerFactory.newTransformer();
		XMLInputFactory inputFactory = XMLInputFactory.newInstance();

		XMLStreamReader reader = inputFactory.createXMLStreamReader(new BufferedReader(new FileReader(xmlFile)));
		reader.nextTag(); // advance to first tag

		int count = 0;
		int eventType = reader.nextTag(); // advance to second tag

		while (eventType == XMLStreamConstants.START_ELEMENT) {
			// File file = new File(dir, reader.getAttributeValue(null, "id") + ".xml");
			File file = new File(dir, String.valueOf(++count) + ".xml");
			transformer.transform(new StAXSource(reader), new StreamResult(file));

			// after transform, only advance if not already at start/end element
			eventType = reader.getEventType();
			if (eventType != XMLStreamConstants.START_ELEMENT && eventType != XMLStreamConstants.END_ELEMENT) {
				eventType = reader.nextTag();
			}
		}
		System.out.println("Split into " + count + " files");
	}
}
