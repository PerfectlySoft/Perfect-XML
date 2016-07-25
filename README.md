# Perfect-XML
XML support for Perfect

It currently contains most of the DOM Core level 2 *read-only* APIs and includes XPath support.

## Building

Add this project as a dependency in your Package.swift file.

```
.Package(url:"https://github.com/PerfectlySoft/Perfect-XML.git", versions: Version(0,0,0)..<Version(10,0,0))
```

## Examples

To utilize this package, ```import PerfectXML```.

### Parse XML Source

This snippet will parse an XML source string and then convert it back into a string.

```swift
let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a><b><c a=\"attr1\">HI</c><d/></b></a>\n"
let doc = XDocument(fromSource: docSrc)
let str = doc?.string(pretty: false)
XCTAssert(str == docSrc, "\(str)")
```

### Inspect Node Names

```swift
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
```

### Inspect Text Node

```swift
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
```

### Check Node Type

```swift
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
	XCTAssert(true)
} else {
	XCTAssert(false, "\(nodeType)")
}
```

### First &amp; Last Child

```swift
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
```

### Next &amp; Previous Sibling

```swift
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
```

### Element Attributes

```swift
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
```

With namespaces:

```swift
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
```

### Get Elements By Name

```swift
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
```

With namespaces:

```swift
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
```

### Get Element By ID

```swift
let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a><b id=\"foo\"/><a><b>FOO<b/></b></a></a>\n"
let doc = XDocument(fromSource: docSrc)
XCTAssert(doc?.nodeName == "#document")
guard let element = doc?.getElementById("foo") else {
	return XCTAssert(false)
}
XCTAssert(element.tagName == "b")
```

### XPath

Elements:

```swift
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
```

Attributes:

```swift
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
```

Text:

```swift
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
```

Namespaces:

```swift
let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a xmlns:foo=\"foo:bar\"><b/><foo:a><b>FOO<b/></b></foo:a></a>\n"
let doc = XDocument(fromSource: docSrc)!
	
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
```
