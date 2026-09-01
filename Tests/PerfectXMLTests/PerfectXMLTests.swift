import Foundation
import Testing
@testable import PerfectXML

@Test func docParse1() {
    let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a><b><c a=\"attr1\">HI</c><d/></b></a>\n"
    let doc = XDocument(fromSource: docSrc)
    let str = doc?.string(pretty: false)
    #expect(str == docSrc)
}

@Test func htmlParse1() {
    let docSrc = "<html>\n<head>\n<title>title</title></head>\n<body>\n<div>hi</div>\n</body>\n</html>\n"
    let doc = HTMLDocument(fromSource: docSrc)
    let nodeName = doc?.documentElement?.nodeName
    #expect(nodeName == "html")
}

@Test func nodeName1() {
    let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a><b/><c/><d/></a>\n"
    let doc = XDocument(fromSource: docSrc)

    #expect(doc?.nodeName == "#document")

    guard let children = doc?.documentElement else {
        Issue.record("No children")
        return
    }
    #expect(children.nodeName == "a")
    let names = ["b", "c", "d"]
    for (n, v) in zip(children.childNodes, names) {
        guard n is XElement else {
            Issue.record("Not an XElement")
            return
        }
        #expect(n.nodeName == v)
    }
}

@Test func text1() {
    let value = "ABCD"
    let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a>\(value)</a>\n"
    let doc = XDocument(fromSource: docSrc)
    #expect(doc?.nodeName == "#document")
    guard let children = doc?.documentElement else {
        Issue.record("No children")
        return
    }
    #expect(children.nodeName == "a")
    let childNodes = children.childNodes
    #expect(childNodes.count == 1)
    guard let textChild = childNodes.first as? XText else {
        Issue.record("Not an XText")
        return
    }
    #expect(textChild.nodeValue == value)
}

@Test func nodeValue1() {
    let value = "ABCD"
    let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a>\(value)</a>\n"
    let doc = XDocument(fromSource: docSrc)
    #expect(doc?.nodeName == "#document")
    guard let children = doc?.documentElement else {
        Issue.record("No children")
        return
    }
    #expect(children.nodeName == "a")
    let childNodes = children.childNodes
    #expect(childNodes.count == 1)
    guard let text = childNodes.first?.nodeValue else {
        Issue.record("No node value")
        return
    }
    #expect(text == value)
}

@Test func nodeType1() {
    let value = "ABCD"
    let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a>\(value)</a>\n"
    let doc = XDocument(fromSource: docSrc)
    #expect(doc?.nodeName == "#document")
    guard let children = doc?.documentElement else {
        Issue.record("No children")
        return
    }
    #expect(children.nodeName == "a")
    guard case .elementNode = children.nodeType else {
        Issue.record("Expected .elementNode, got \(children.nodeType)")
        return
    }
}

@Test func firstLastChild1() {
    let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a><b/><c/><d/></a>\n"
    let doc = XDocument(fromSource: docSrc)
    #expect(doc?.nodeName == "#document")
    guard let children = doc?.documentElement else {
        Issue.record("No children")
        return
    }
    #expect(children.nodeName == "a")

    guard let firstChild = children.firstChild else {
        Issue.record("No first child")
        return
    }
    guard let lastChild = children.lastChild else {
        Issue.record("No last child")
        return
    }
    #expect(firstChild.nodeName == "b")
    #expect(lastChild.nodeName == "d")
}

@Test func prevNextSibling1() {
    let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a><b/><c/><d/></a>\n"
    let doc = XDocument(fromSource: docSrc)
    #expect(doc?.nodeName == "#document")
    guard let children = doc?.documentElement else {
        Issue.record("No children")
        return
    }
    #expect(children.nodeName == "a")

    guard let firstChild = children.firstChild else {
        Issue.record("No first child")
        return
    }
    #expect(firstChild.nodeName == "b")

    guard let nextSib = firstChild.nextSibling else {
        Issue.record("No next sibling")
        return
    }
    guard let prevSib = nextSib.previousSibling else {
        Issue.record("No previous sibling")
        return
    }
    #expect(nextSib.nodeName == "c")
    #expect(prevSib.nodeName == "b")
}

@Test func attributes1() {
    let names = ["atr1", "atr2"]
    let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a><b atr1=\"the value\" atr2=\"the other value\"></b></a>\n"
    let doc = XDocument(fromSource: docSrc)
    #expect(doc?.nodeName == "#document")
    guard let children = doc?.documentElement else {
        Issue.record("No children")
        return
    }
    #expect(children.nodeName == "a")

    guard let firstChild = children.firstChild else {
        Issue.record("No first child")
        return
    }
    #expect(firstChild.nodeName == "b")
    guard let attrs = firstChild.attributes else {
        Issue.record("nil attributes")
        return
    }
    #expect(attrs.length == 2)
    for index in 0..<attrs.length {
        guard let item = attrs[index] else {
            Issue.record("No item at index \(index)")
            return
        }
        #expect(item.nodeName == names[index])
    }
    for name in names {
        guard let item = attrs[name] else {
            Issue.record("No item named \(name)")
            return
        }
        #expect(item.nodeName == name)
    }
}

@Test func attributes2() {
    let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a><b atr1=\"the value\" atr2=\"the other value\"></b></a>\n"
    let doc = XDocument(fromSource: docSrc)
    #expect(doc?.nodeName == "#document")
    guard let children = doc?.documentElement else {
        Issue.record("No children")
        return
    }
    #expect(children.nodeName == "a")

    guard let firstChild = children.firstChild as? XElement else {
        Issue.record("Not an XElement")
        return
    }
    #expect(firstChild.nodeName == "b")
    guard let atr1 = firstChild.getAttribute(name: "atr1") else {
        Issue.record("No atr1")
        return
    }
    #expect(atr1 == "the value")
    guard let atr2 = firstChild.getAttributeNode(name: "atr2") else {
        Issue.record("No atr2")
        return
    }
    #expect(atr2.value == "the other value")
}

@Test func attributes3() {
    let names = ["atr1", "atr2"]
    let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a xmlns:foo=\"foo:bar\"><b foo:atr1=\"the value\" foo:atr2=\"the other value\"></b></a>\n"
    let doc = XDocument(fromSource: docSrc)
    #expect(doc?.nodeName == "#document")
    guard let children = doc?.documentElement else {
        Issue.record("No children")
        return
    }
    #expect(children.nodeName == "a")

    guard let firstChild = children.firstChild else {
        Issue.record("No first child")
        return
    }
    #expect(firstChild.nodeName == "b")
    guard let attrs = firstChild.attributes else {
        Issue.record("nil attributes")
        return
    }
    #expect(attrs.length == 2)
    for name in names {
        guard let item = attrs.getNamedItemNS(namespaceURI: "foo:bar", localName: name) else {
            Issue.record("No item named \(name)")
            return
        }
        #expect(item.nodeName == name)
    }
}

@Test func attributes4() {
    let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a xmlns:foo=\"foo:bar\"><b atr1=\"the value\" foo:atr2=\"the other value\"></b></a>\n"
    let doc = XDocument(fromSource: docSrc)
    #expect(doc?.nodeName == "#document")
    guard let children = doc?.documentElement else {
        Issue.record("No children")
        return
    }
    #expect(children.nodeName == "a")
    guard let firstChild = children.firstChild as? XElement else {
        Issue.record("Not an XElement")
        return
    }
    #expect(firstChild.nodeName == "b")
    guard let atr2 = firstChild.getAttributeNodeNS(namespaceURI: "foo:bar", localName: "atr2") else {
        Issue.record("No atr2")
        return
    }
    #expect(atr2.value == "the other value")
    #expect(firstChild.hasAttributeNS(namespaceURI: "foo:bar", localName: "atr2"))
    #expect(firstChild.hasAttribute(name: "atr1"))
    #expect(!firstChild.hasAttributeNS(namespaceURI: "foo:bar", localName: "atr1"))
    #expect(!firstChild.hasAttribute(name: "atr3"))
}

@Test func docElementByName1() {
    let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a><b/><a><b><b/></b></a></a>\n"
    let doc = XDocument(fromSource: docSrc)
    #expect(doc?.nodeName == "#document")

    guard let elements = doc?.getElementsByTagName("b") else {
        Issue.record("No elements")
        return
    }
    #expect(elements.count == 3)
    for node in elements {
        #expect(node.nodeName == "b")
    }
}

@Test func docElementByName2() {
    let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a><b/><a><b><b/></b></a></a>\n"
    let doc = XDocument(fromSource: docSrc)
    #expect(doc?.nodeName == "#document")

    guard let elements = doc?.documentElement?.getElementsByTagName("b") else {
        Issue.record("No elements")
        return
    }
    #expect(elements.count == 3)
    for node in elements {
        #expect(node.nodeName == "b")
    }
}

@Test func docElementByName3() {
    let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a><b/><a><b>FOO<b/></b></a></a>\n"
    let doc = XDocument(fromSource: docSrc)
    #expect(doc?.nodeName == "#document")

    guard let elements = doc?.getElementsByTagName("a") else {
        Issue.record("No elements")
        return
    }
    #expect(elements.count == 2)
    for node in elements {
        #expect(node.nodeName == "a")
    }

    guard let nestedElements = doc?.documentElement?.getElementsByTagName("a") else {
        Issue.record("No elements")
        return
    }
    #expect(nestedElements.count == 1)
    for node in nestedElements {
        #expect(node.nodeName == "a")
    }
}

@Test func docElementByName4() {
    let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a xmlns:foo=\"foo:bar\"><b/><foo:a><b>FOO<b/></b></foo:a></a>\n"
    let doc = XDocument(fromSource: docSrc)
    #expect(doc?.nodeName == "#document")

    guard let elements = doc?.getElementsByTagNameNS(namespaceURI: "foo:bar", localName: "a") else {
        Issue.record("No elements")
        return
    }
    #expect(elements.count == 1)
    for node in elements {
        #expect(node.nodeName == "a")
        #expect(node.localName == "a")
        #expect(node.prefix == "foo")
        #expect(node.namespaceURI == "foo:bar")
    }

    guard let nestedElements = doc?.documentElement?.getElementsByTagNameNS(namespaceURI: "foo:bar", localName: "a") else {
        Issue.record("No elements")
        return
    }
    #expect(nestedElements.count == 1)
    for node in nestedElements {
        #expect(node.nodeName == "a")
        #expect(node.localName == "a")
        #expect(node.prefix == "foo")
        #expect(node.namespaceURI == "foo:bar")
    }

    guard let noElements = doc?.getElementsByTagNameNS(namespaceURI: "foo:barz", localName: "a") else {
        Issue.record("No elements")
        return
    }
    #expect(noElements.count == 0)

    guard let noNestedElements = doc?.documentElement?.getElementsByTagNameNS(namespaceURI: "foo:barz", localName: "a") else {
        Issue.record("No elements")
        return
    }
    #expect(noNestedElements.count == 0)
}

@Test func docElementById1() {
    let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a><b id=\"foo\"/><a><b>FOO<b/></b></a></a>\n"
    let doc = XDocument(fromSource: docSrc)
    #expect(doc?.nodeName == "#document")
    guard let element = doc?.getElementById("foo") else {
        Issue.record("No element")
        return
    }
    #expect(element.tagName == "b")
}

@Test func xPath1() {
    let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a><b id=\"foo\"/><a><b>FOO<b/></b></a></a>\n"
    guard let doc = XDocument(fromSource: docSrc) else {
        Issue.record("No document")
        return
    }
    #expect(doc.nodeName == "#document")

    let pathRes = doc.extract(path: "/a/b")
    guard case .nodeSet(let set) = pathRes else {
        Issue.record("Expected .nodeSet, got \(pathRes)")
        return
    }
    for node in set {
        guard let b = node as? XElement else {
            Issue.record("Not an XElement: \(node)")
            return
        }
        #expect(b.tagName == "b")
    }
}

@Test func xPath2() {
    let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a><b id=\"foo\"/><a><b>FOO<b/></b></a></a>\n"
    guard let doc = XDocument(fromSource: docSrc) else {
        Issue.record("No document")
        return
    }
    #expect(doc.nodeName == "#document")

    let pathRes = doc.extract(path: "/a/b/@id")
    guard case .nodeSet(let set) = pathRes else {
        Issue.record("Expected .nodeSet, got \(pathRes)")
        return
    }
    for node in set {
        guard let b = node as? XAttr else {
            Issue.record("Not an XAttr: \(node)")
            return
        }
        #expect(b.name == "id")
        #expect(b.value == "foo")
    }
}

@Test func xPath3() {
    let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a><b id=\"foo\"/><a><b>FOO<b/></b></a></a>\n"
    guard let doc = XDocument(fromSource: docSrc) else {
        Issue.record("No document")
        return
    }
    #expect(doc.nodeName == "#document")

    let pathRes = doc.extract(path: "/a/a/b/text()")
    guard case .nodeSet(let set) = pathRes else {
        Issue.record("Expected .nodeSet, got \(pathRes)")
        return
    }
    for node in set {
        guard let b = node as? XText else {
            Issue.record("Not an XText: \(node)")
            return
        }
        guard let nodeValue = b.nodeValue else {
            Issue.record("No node value")
            return
        }
        #expect(nodeValue == "FOO")
    }
}

@Test func xPath4() {
    let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a><b id=\"foo\"/><a><b>FOO<b/></b></a></a>\n"
    guard let doc = XDocument(fromSource: docSrc) else {
        Issue.record("No document")
        return
    }
    #expect(doc.nodeName == "#document")
    guard let node = doc.extractOne(path: "/a/a/b/text()") else {
        Issue.record("no result")
        return
    }
    guard let b = node as? XText else {
        Issue.record("Not an XText: \(node)")
        return
    }
    guard let nodeValue = b.nodeValue else {
        Issue.record("No node value")
        return
    }
    #expect(nodeValue == "FOO")
}

@Test func xPath5() {
    let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a xmlns:foo=\"foo:bar\"><b/><foo:a><b>FOO<b/></b></foo:a></a>\n"
    guard let doc = XDocument(fromSource: docSrc) else {
        Issue.record("No document")
        return
    }
    let namespaces = [("f", "foo:bar")]
    let pathRes = doc.extract(path: "/a/f:a", namespaces: namespaces)
    guard case .nodeSet(let set) = pathRes else {
        Issue.record("Expected .nodeSet, got \(pathRes)")
        return
    }
    for node in set {
        guard let e = node as? XElement else {
            Issue.record("Not an XElement: \(node)")
            return
        }
        #expect(e.tagName == "a")
        #expect(e.namespaceURI == "foo:bar")
        #expect(e.prefix == "foo")
    }
}

// `XMLEncoder` only supports a flat keyed container of primitive values
// (see Codable.swift's doc comment) — no test for the array/nested case
// here, matching that deliberate, documented scope limit.

@Test func xmlStream() throws {
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
            return Data(a)
        }
        func close() {}
    }
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
            Issue.record("No item")
            return
        }
        #expect(item.type == check.0)
        #expect(item.localName == check.1)
        #expect(item.value == check.2)
        #expect(item.isEmpty == check.3)
        #expect(item.attributeCount == check.4)
        #expect(item.getAttribute("a") == check.5)
    }
}

@Test func sax() throws {
    final class TestDelegate: SAXDelegate {
        var opens = ["A", "B", "C", "D", "E"]
        var closes = ["B", "C", "E", "D", "A"]

        func startElementNs(localName: String, prefix: String?, uri: String?, namespaces: [SAXDelegateNamespace], attributes: [SAXDelegateAttribute]) {
            #expect(opens.removeFirst() == localName)
            if localName == "B" {
                #expect(attributes.first?.localName == "a")
            }
        }
        func endElementNs(localName: String, prefix: String?, uri: String?) {
            #expect(closes.removeFirst() == localName)
        }
    }
    let d = TestDelegate()
    let sax = SAXParser(delegate: d)
    let bytes = Array("<A><foo:B xmlns:foo=\"123\" foo:a=\"value\">CONTENT</foo:B><C/><D><E/></D></A>".utf8)
    for n in stride(from: 0, to: bytes.count, by: 4) {
        let upper = min(n + 4, bytes.count)
        let range = bytes[n..<upper]
        try sax.pushData(Array(range))
    }
    try sax.finish()
    #expect(d.opens.isEmpty)
    #expect(d.closes.isEmpty)
}

// Regression for the `String(_:count:default:)` UTF-8 decode fix in
// XMLStream.swift: character data containing multi-byte UTF-8 sequences
// (continuation bytes >= 0x80) must decode correctly instead of falling
// back to `default`.
@Test func saxNonASCIICharacters() throws {
    final class TestDelegate: SAXDelegate {
        var collected = ""
        func characters(_ c: String) { collected += c }
    }
    let d = TestDelegate()
    let sax = SAXParser(delegate: d)
    let value = "caf\u{e9} \u{4f60}\u{597d} \u{1f600}"
    let bytes = Array("<A>\(value)</A>".utf8)
    for n in stride(from: 0, to: bytes.count, by: 3) {
        let upper = min(n + 3, bytes.count)
        try sax.pushData(Array(bytes[n..<upper]))
    }
    try sax.finish()
    #expect(d.collected == value)
}

// MARK: - XXE hardening regression (see XMLDOM.swift's doc comments on
// XDocument.init?(fromSource:)/HTMLDocument.init?(fromSource:encoding:))
//
// Points an external SYSTEM entity/DTD reference at a local fixture file
// containing a unique marker string, parses through the hardened DOM
// path, and asserts the marker string is absent from the resulting tree.
// This is portable across libxml2 versions/builds (some already disable
// external-entity fetching by default independent of the options
// bitmask) — asserting "no substitution occurred" is correct either way,
// unlike asserting on network-fetch behavior, which would pass for the
// wrong reason in a network-isolated CI container.

@Test func xxeExternalEntityIsNotSubstituted() throws {
    let marker = "XXE-MARKER-\(UUID().uuidString)"
    let entityFile = FileManager.default.temporaryDirectory
        .appendingPathComponent("perfectxml-xxe-\(UUID().uuidString).txt")
    try marker.write(to: entityFile, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(at: entityFile) }

    let docSrc = """
    <?xml version="1.0"?>
    <!DOCTYPE root [
      <!ENTITY xxe SYSTEM "file://\(entityFile.path)">
    ]>
    <root>&xxe;</root>
    """
    let doc = XDocument(fromSource: docSrc)
    let output = doc?.string(pretty: false) ?? ""
    #expect(!output.contains(marker))
}
