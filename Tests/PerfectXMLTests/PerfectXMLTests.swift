import XCTest
@testable import PerfectXML

class PerfectXMLTests: XCTestCase {
	
    func testDocParse1() {
        let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a><b><c a=\"attr1\">HI</c><d/></b></a>\n"
		let doc = XDocument(fromSource: docSrc)
		let str = doc?.string(pretty: false)
		XCTAssert(str == docSrc, "\(String(describing: str))")
	}
	
	func testHTMLParse1() {
		let docSrc = "<html>\n<head>\n<title>title</title></head>\n<body>\n<div>hi</div>\n</body>\n</html>\n"
		let doc = HTMLDocument(fromSource: docSrc)
		let nodeName = doc?.documentElement?.nodeName
		XCTAssert(nodeName == "html")
	}
	
	func testNodeName1() {
		let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a><b/><c/><d/></a>\n"
		let doc = XDocument(fromSource: docSrc)
		
		XCTAssert(doc?.nodeName == "#document")
		
		guard let children = doc?.documentElement else {
			return XCTAssert(false, "No children")
		}
		XCTAssert(children.nodeName == "a")
		let names = ["b", "c", "d"]
		for (n, v) in zip(children.childNodes, names) {
			guard let _ = n as? XElement else {
				return XCTAssert(false)
			}
			XCTAssert(n.nodeName == v, "\(n.nodeName) != \(v)")
		}
	}
	
	func testText1() {
		let value = "ABCD"
		let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a>\(value)</a>\n"
		let doc = XDocument(fromSource: docSrc)
		XCTAssert(doc?.nodeName == "#document")
		guard let children = doc?.documentElement else {
			return XCTAssert(false, "No children")
		}
		XCTAssert(children.nodeName == "a")
		do {
			let children = children.childNodes
			XCTAssert(children.count == 1)
			guard let textChild = children.first as? XText else {
				return XCTAssert(false)
			}
			XCTAssert(textChild.nodeValue == value)
		}
	}
	
	func testNodeValue1() {
		let value = "ABCD"
		let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a>\(value)</a>\n"
		let doc = XDocument(fromSource: docSrc)
		XCTAssert(doc?.nodeName == "#document")
		guard let children = doc?.documentElement else {
			return XCTAssert(false, "No children")
		}
		XCTAssert(children.nodeName == "a")
		do {
			let children = children.childNodes
			XCTAssert(children.count == 1)
			guard let text = children.first?.nodeValue else {
				return XCTAssert(false)
			}
			XCTAssert(text == value)
		}
	}
	
	func testNodeType1() {
		let value = "ABCD"
		let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a>\(value)</a>\n"
		let doc = XDocument(fromSource: docSrc)
		XCTAssert(doc?.nodeName == "#document")
		guard let children = doc?.documentElement else {
			return XCTAssert(false, "No children")
		}
		XCTAssert(children.nodeName == "a")
		let nodeType = children.nodeType
		if case .elementNode = nodeType {
		
		} else {
			XCTAssert(false, "\(nodeType)")
		}
	}
	
	func testFirstLastChild1() {
		let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a><b/><c/><d/></a>\n"
		let doc = XDocument(fromSource: docSrc)
		XCTAssert(doc?.nodeName == "#document")
		guard let children = doc?.documentElement else {
			return XCTAssert(false, "No children")
		}
		XCTAssert(children.nodeName == "a")
		
		guard let firstChild = children.firstChild else {
			return XCTAssert(false)
		}
		guard let lastChild = children.lastChild else {
			return XCTAssert(false)
		}
		XCTAssert(firstChild.nodeName == "b")
		XCTAssert(lastChild.nodeName == "d")
	}
	
	func testPrevNextSibling1() {
		let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a><b/><c/><d/></a>\n"
		let doc = XDocument(fromSource: docSrc)
		XCTAssert(doc?.nodeName == "#document")
		guard let children = doc?.documentElement else {
			return XCTAssert(false, "No children")
		}
		XCTAssert(children.nodeName == "a")
		
		guard let firstChild = children.firstChild else {
			return XCTAssert(false)
		}
		XCTAssert(firstChild.nodeName == "b")
		
		guard let nextSib = firstChild.nextSibling else {
			return XCTAssert(false)
		}
		guard let prevSib = nextSib.previousSibling else {
			return XCTAssert(false)
		}
		XCTAssert(nextSib.nodeName == "c")
		XCTAssert(prevSib.nodeName == "b")
	}
	
	func testAttributes1() {
		let names = ["atr1", "atr2"]
		let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a><b atr1=\"the value\" atr2=\"the other value\"></b></a>\n"
		let doc = XDocument(fromSource: docSrc)
		XCTAssert(doc?.nodeName == "#document")
		guard let children = doc?.documentElement else {
			return XCTAssert(false, "No children")
		}
		XCTAssert(children.nodeName == "a")
		
		guard let firstChild = children.firstChild else {
			return XCTAssert(false)
		}
		XCTAssert(firstChild.nodeName == "b")
		guard let attrs = firstChild.attributes else {
			return XCTAssert(false, "nil attributes")
		}
		XCTAssert(attrs.length == 2)
		for index in 0..<attrs.length {
			guard let item = attrs[index] else {
				return XCTAssert(false)
			}
			XCTAssert(item.nodeName == names[index])
		}
		for name in names {
			guard let item = attrs[name] else {
				return XCTAssert(false)
			}
			XCTAssert(item.nodeName == name)
		}
	}
	
	func testAttributes2() {
		let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a><b atr1=\"the value\" atr2=\"the other value\"></b></a>\n"
		let doc = XDocument(fromSource: docSrc)
		XCTAssert(doc?.nodeName == "#document")
		guard let children = doc?.documentElement else {
			return XCTAssert(false, "No children")
		}
		XCTAssert(children.nodeName == "a")
		
		guard let firstChild = children.firstChild as? XElement else {
			return XCTAssert(false)
		}
		XCTAssert(firstChild.nodeName == "b")
		guard let atr1 = firstChild.getAttribute(name: "atr1") else {
			return XCTAssert(false)
		}
		XCTAssert(atr1 == "the value")
		guard let atr2 = firstChild.getAttributeNode(name: "atr2") else {
			return XCTAssert(false)
		}
		XCTAssert(atr2.value == "the other value")
	}
	
	func testAttributes3() {
		let names = ["atr1", "atr2"]
		let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a xmlns:foo=\"foo:bar\"><b foo:atr1=\"the value\" foo:atr2=\"the other value\"></b></a>\n"
		let doc = XDocument(fromSource: docSrc)
		XCTAssert(doc?.nodeName == "#document")
		guard let children = doc?.documentElement else {
			return XCTAssert(false, "No children")
		}
		XCTAssert(children.nodeName == "a")
		
		guard let firstChild = children.firstChild else {
			return XCTAssert(false)
		}
		XCTAssert(firstChild.nodeName == "b")
		guard let attrs = firstChild.attributes else {
			return XCTAssert(false, "nil attributes")
		}
		XCTAssert(attrs.length == 2)
		for name in names {
			guard let item = attrs.getNamedItemNS(namespaceURI: "foo:bar", localName: name) else {
				return XCTAssert(false)
			}
			XCTAssert(item.nodeName == name)
		}
	}
	
	func testAttributes4() {
		let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a xmlns:foo=\"foo:bar\"><b atr1=\"the value\" foo:atr2=\"the other value\"></b></a>\n"
		let doc = XDocument(fromSource: docSrc)
		XCTAssert(doc?.nodeName == "#document")
		guard let children = doc?.documentElement else {
			return XCTAssert(false, "No children")
		}
		XCTAssert(children.nodeName == "a")
		guard let firstChild = children.firstChild as? XElement else {
			return XCTAssert(false)
		}
		XCTAssert(firstChild.nodeName == "b")
		guard let atr2 = firstChild.getAttributeNodeNS(namespaceURI: "foo:bar", localName: "atr2") else {
			return XCTAssert(false)
		}
		XCTAssert(atr2.value == "the other value")
		XCTAssert(firstChild.hasAttributeNS(namespaceURI: "foo:bar", localName: "atr2"))
		XCTAssert(firstChild.hasAttribute(name: "atr1"))
		XCTAssert(!firstChild.hasAttributeNS(namespaceURI: "foo:bar", localName: "atr1"))
		XCTAssert(!firstChild.hasAttribute(name: "atr3"))
	}
	
	func testDocElementByName1() {
		let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a><b/><a><b><b/></b></a></a>\n"
		let doc = XDocument(fromSource: docSrc)
		XCTAssert(doc?.nodeName == "#document")
		
		guard let elements = doc?.getElementsByTagName("b") else {
			return XCTAssert(false)
		}
		XCTAssert(elements.count == 3)
		for node in elements {
			XCTAssert(node.nodeName == "b")
		}
	}
	
	func testDocElementByName2() {
		let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a><b/><a><b><b/></b></a></a>\n"
		let doc = XDocument(fromSource: docSrc)
		XCTAssert(doc?.nodeName == "#document")
		
		guard let elements = doc?.documentElement?.getElementsByTagName("b") else {
			return XCTAssert(false)
		}
		XCTAssert(elements.count == 3)
		for node in elements {
			XCTAssert(node.nodeName == "b")
		}
	}
	
	func testDocElementByName3() {
		let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a><b/><a><b>FOO<b/></b></a></a>\n"
		let doc = XDocument(fromSource: docSrc)
		XCTAssert(doc?.nodeName == "#document")
		
		do {
			guard let elements = doc?.getElementsByTagName("a") else {
				return XCTAssert(false)
			}
			XCTAssert(elements.count == 2)
			for node in elements {
				XCTAssert(node.nodeName == "a")
			}
		}
		
		do {
			guard let elements = doc?.documentElement?.getElementsByTagName("a") else {
				return XCTAssert(false)
			}
			XCTAssert(elements.count == 1)
			for node in elements {
				XCTAssert(node.nodeName == "a")
			}
		}
	}
	
	func testDocElementByName4() {
		let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a xmlns:foo=\"foo:bar\"><b/><foo:a><b>FOO<b/></b></foo:a></a>\n"
		let doc = XDocument(fromSource: docSrc)
		XCTAssert(doc?.nodeName == "#document")
		
		do {
			guard let elements = doc?.getElementsByTagNameNS(namespaceURI: "foo:bar", localName: "a") else {
				return XCTAssert(false)
			}
			XCTAssert(elements.count == 1)
			for node in elements {
				XCTAssert(node.nodeName == "a")
				XCTAssert(node.localName == "a")
				XCTAssert(node.prefix == "foo")
				XCTAssert(node.namespaceURI == "foo:bar")
			}
		}
		
		do {
			guard let elements = doc?.documentElement?.getElementsByTagNameNS(namespaceURI: "foo:bar", localName: "a") else {
				return XCTAssert(false)
			}
			XCTAssert(elements.count == 1)
			for node in elements {
				XCTAssert(node.nodeName == "a")
				XCTAssert(node.localName == "a")
				XCTAssert(node.prefix == "foo")
				XCTAssert(node.namespaceURI == "foo:bar")
			}
		}
		
		do {
			guard let elements = doc?.getElementsByTagNameNS(namespaceURI: "foo:barz", localName: "a") else {
				return XCTAssert(false)
			}
			XCTAssert(elements.count == 0)
		}
		
		do {
			guard let elements = doc?.documentElement?.getElementsByTagNameNS(namespaceURI: "foo:barz", localName: "a") else {
				return XCTAssert(false)
			}
			XCTAssert(elements.count == 0)
		}
	}
	
	func testDocElementById1() {
		let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a><b id=\"foo\"/><a><b>FOO<b/></b></a></a>\n"
		let doc = XDocument(fromSource: docSrc)
		XCTAssert(doc?.nodeName == "#document")
		guard let element = doc?.getElementById("foo") else {
			return XCTAssert(false)
		}
		XCTAssert(element.tagName == "b")
	}
	
	func testXPath1() {
		let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a><b id=\"foo\"/><a><b>FOO<b/></b></a></a>\n"
		guard let doc = XDocument(fromSource: docSrc) else {
			return XCTAssert(false)
		}
		XCTAssert(doc.nodeName == "#document")
		
		let pathRes = doc.extract(path: "/a/b")
		guard case .nodeSet(let set) = pathRes else {
			return XCTAssert(false, "\(pathRes)")
		}
		for node in set {
			guard let b = node as? XElement else {
				return XCTAssert(false, "\(node)")
			}
			XCTAssert(b.tagName == "b")
		}
	}
	
	func testXPath2() {
		let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a><b id=\"foo\"/><a><b>FOO<b/></b></a></a>\n"
		guard let doc = XDocument(fromSource: docSrc) else {
			return XCTAssert(false)
		}
		XCTAssert(doc.nodeName == "#document")
		
		let pathRes = doc.extract(path: "/a/b/@id")
		guard case .nodeSet(let set) = pathRes else {
			return XCTAssert(false, "\(pathRes)")
		}
		for node in set {
			guard let b = node as? XAttr else {
				return XCTAssert(false, "\(node)")
			}
			XCTAssert(b.name == "id")
			XCTAssert(b.value == "foo")
		}
	}
	
	func testXPath3() {
		let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a><b id=\"foo\"/><a><b>FOO<b/></b></a></a>\n"
		guard let doc = XDocument(fromSource: docSrc) else {
			return XCTAssert(false)
		}
		XCTAssert(doc.nodeName == "#document")
		
		let pathRes = doc.extract(path: "/a/a/b/text()")
		guard case .nodeSet(let set) = pathRes else {
			return XCTAssert(false, "\(pathRes)")
		}
		for node in set {
			guard let b = node as? XText else {
				return XCTAssert(false, "\(node)")
			}
			guard let nodeValue = b.nodeValue else {
				return XCTAssert(false, "\(b)")
			}
			XCTAssert(nodeValue == "FOO")
		}
	}
	
	func testXPath4() {
		let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a><b id=\"foo\"/><a><b>FOO<b/></b></a></a>\n"
		guard let doc = XDocument(fromSource: docSrc) else {
			return XCTAssert(false)
		}
		XCTAssert(doc.nodeName == "#document")
		guard let node = doc.extractOne(path: "/a/a/b/text()") else {
			return XCTAssert(false, "no result")
		}
		guard let b = node as? XText else {
			return XCTAssert(false, "\(node)")
		}
		guard let nodeValue = b.nodeValue else {
			return XCTAssert(false, "\(b)")
		}
		XCTAssert(nodeValue == "FOO")
	}
	
	func testXPath5() {
		let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a xmlns:foo=\"foo:bar\"><b/><foo:a><b>FOO<b/></b></foo:a></a>\n"
		guard let doc = XDocument(fromSource: docSrc) else {
			return XCTAssert(false)
		}
		let namespaces = [("f", "foo:bar")]
		let pathRes = doc.extract(path: "/a/f:a", namespaces: namespaces)
		guard case .nodeSet(let set) = pathRes else {
			return XCTAssert(false, "\(pathRes)")
		}
		for node in set {
			guard let e = node as? XElement else {
				return XCTAssert(false, "\(node)")
			}
			XCTAssert(e.tagName == "a")
			XCTAssert(e.namespaceURI == "foo:bar")
			XCTAssert(e.prefix == "foo")
		}
	}
	
//	func testXMLEncode() {
//		struct ChildType: Codable {
//
//		}
//		struct DocumentType: Codable {
//			let id: Int
//			let str: String
//			let double: Double
//		}
//		do {
//			let doc = DocumentType(id: 42, str: "This is the string & stuff.", double: 42.3)
//			let data = try XMLEncoder().encode(doc, rootName: "document")
//			guard let str = String(data: data, encoding: .utf8) else {
//				return XCTFail("Bad data from encoding.")
//			}
//			let testAgainst = "<document><id>42</id><str>This is the string &amp; stuff.</str></document>"
//			XCTAssertEqual(str, testAgainst)
//		} catch {
//			XCTFail("\(error)")
//		}
//	}
	
	func testXMLStream() {
		struct ChunkyProvider: XMLStreamDataProvider {
			let source: [UInt8]
			let maxReturn = 4
			var offset: Int = 0
			init(_ s: String) {
				source = Array(s.utf8)
			}
			mutating func getData(maxCount: Int) throws -> Data? {
				let remaining = source.count - offset
				guard remaining > 0 else {
					return nil
				}
				let a = source[offset..<(offset + min(maxReturn, min(remaining, maxCount)))]
				offset += a.count
				return Data(bytes: a)
			}
			func close() {
				print("ChunkyProvider.close()")
			}
		}
		do {
			let provider = ChunkyProvider("<A><B a=\"value\">CONTENT</B><C/><D><E/></D></A>")
			let stream = XMLStream(provider: provider)
			
			let checks: [(XMLStream.NodeType, String, String?, Bool, Int, String?)] = [
				(.element, "A", nil, false, 0, nil),
				(.element, "B", nil, false, 1, "value"),
				(.text, "#text", "CONTENT", false, 0, nil),
				(.endElement, "B", nil, false, 0, "value"),
				(.element, "C", nil, true, 0, nil),
				(.element, "D", nil, false, 0, nil),
				(.element, "E", nil, true, 0, nil),
				(.endElement, "D", nil, false, 0, nil),
				(.endElement, "A", nil, false, 0, nil),
			]
			
			for check in checks {
				guard let item = try stream.next() else {
					return XCTFail("No item")
				}
				XCTAssertEqual(item.type!, check.0)
				XCTAssertEqual(item.localName, check.1)
				XCTAssertEqual(item.value, check.2)
				XCTAssertEqual(item.isEmpty, check.3)
				XCTAssertEqual(item.attributeCount, check.4)
				XCTAssertEqual(item.getAttribute("a"), check.5)
			}
		} catch {
			XCTFail("\(error)")
		}
	}
	
    static var allTests : [(String, (PerfectXMLTests) -> () throws -> Void)] {
		return [
			("testDocParse1", testDocParse1),
			("testNodeName1", testNodeName1),
			("testText1", testText1),
			("testNodeValue1", testNodeValue1),
			("testNodeType1", testNodeType1),
			("testFirstLastChild1", testFirstLastChild1),
			("testPrevNextSibling1", testPrevNextSibling1),
			("testAttributes1", testAttributes1),
			("testAttributes2", testAttributes2),
			("testAttributes3", testAttributes3),
			("testAttributes4", testAttributes4),
			("testDocElementByName1", testDocElementByName1),
			("testDocElementByName2", testDocElementByName2),
			("testDocElementByName3", testDocElementByName3),
			("testDocElementByName4", testDocElementByName4),
			("testDocElementById1", testDocElementById1),
			("testXPath1", testXPath1),
			("testXPath2", testXPath2),
			("testXPath3", testXPath3),
			("testXPath4", testXPath4),
			("testXPath5", testXPath5),
			("testXMLStream", testXMLStream)
			
        ]
    }
}
