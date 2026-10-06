# Perfect-XML

<p align="center">
    <a href="https://developer.apple.com/swift/" target="_blank">
        <img src="https://img.shields.io/badge/Swift-6.2-orange.svg?style=flat" alt="Swift 6.2">
    </a>
    <a href="https://developer.apple.com/swift/" target="_blank">
        <img src="https://img.shields.io/badge/Platforms-macOS%2012%2B%20%7C%20iOS%2015%2B%20%7C%20Linux-lightgray.svg?style=flat" alt="Platforms macOS 12+ | iOS 15+ | Linux">
    </a>
    <a href="./LICENSE" target="_blank">
        <img src="https://img.shields.io/badge/License-Apache%202.0-lightgrey.svg?style=flat" alt="License Apache 2.0">
    </a>
</p>

XML &amp; HTML parsing support, modernized for Swift 6. This is real, load-bearing infrastructure:
`Perfect-FileMaker` imports `PerfectXML` to parse FileMaker Server's XML Custom Web Publishing responses.

It implements most of the DOM Core level 2 *read-only* APIs plus XPath support, and also includes a SAX push-parser, a streaming reader (`XMLStream`), and a minimal `XMLEncoder` that encodes flat `Encodable` structs as XML (see [Additional APIs](#additional-apis) below).

**Requirements:** Swift 6.2 or newer (`swift-tools-version: 6.2`); macOS 12+, iOS 15+, or Linux. On macOS and iOS, libxml2 comes from the SDK. On Linux, install `libxml2-dev` and `pkg-config` (see [Linux Build Notes](#linux-build-notes)). CI builds and tests on Linux (Swift 6.2 and 6.4), macOS (Xcode 26.0.1 and 26.6) and the iOS Simulator, with warnings treated as errors.

**Concurrency:** this is a synchronous, non-async/await library. The document, node and parser classes (`XDocument`, `HTMLDocument`, the `XNode` subclasses, `SAXParser` and `XMLStream`) are `@unchecked Sendable` over an underlying libxml2 pointer, each with an explicit rationale comment. They have no internal locking, so use each instance from one task at a time. `XMLEncoder` is not `Sendable`; use one per task.

**Security:** external entities (`<!ENTITY x SYSTEM "file:///etc/passwd">`, the classic XXE attack) are never loaded or substituted, and external DTDs aren't loaded. libxml2 takes its entity-substitution default from a process-wide global (`xmlSubstituteEntitiesDefault`), so `XDocument` and `XMLStream` force substitution off on their own parser contexts; another library turning the global on doesn't change that. Parsing also passes `XML_PARSE_NONET` as defence in depth against network fetches. Entity references stay references in the parsed tree rather than being substituted during parsing. Tests cover the `file://` case with the global both off and on.

The pre-Swift-6 version of this package is preserved on the [`legacy`](../../tree/legacy) branch.

## Building

`Perfect-XML` has no external Swift package dependencies. libxml2 is wrapped by a local `.systemLibrary` target inlined into this repo's `Package.swift`, which replaces the separate `Perfect-libxml2` package that 3.x depended on. The system libxml2 is still required at build time; see the platform notes below.

```swift
.package(url: "https://github.com/PerfectlySoft/Perfect-XML.git", from: "4.0.0")
```

and add `.product(name: "PerfectXML", package: "Perfect-XML")` to your target's dependencies.

## macOS and iOS Build Notes

Nothing to install: the macOS and iOS SDKs include libxml2, and the package uses that copy without pkg-config. A Homebrew libxml2 isn't needed. Don't `brew link --force libxml2` for this package: mixing Homebrew's libxml2 headers with the SDK's can fail the build with "conflicting types" errors.

## Linux Build Notes

Ensure that you have installed libxml2-dev and pkg-config.

```
sudo apt-get install libxml2-dev pkg-config
```

## Usage

Instantiate an XDocument object with your XML string

```swift
import PerfectXML
let document = XDocument(fromSource: xmlString)
```

Instantiate an HTMLDocument object with your HTML string

```swift
import PerfectXML
let document = HTMLDocument(fromSource: htmlString)
```

Now you can get the root node of the document structure by using the documentElement property

```swift
print(document.documentElement?.string(pretty: true))
```

Each node has several important properties

- nodeValue
- nodeName
- parentNode
- childNodes

Each node also has a getElementsByTagName: method that recursively searches through it and its children to return an array of all nodes that have that name. This method makes it easy to find a single value in the XML file.

```swift
import PerfectXML

let serverResponseXML = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n" +
"<Autodiscover xmlns=\"http://schemas.microsoft.com/exchange/autodiscover/responseschema/2006\">" + 
"  <Response>" + 
"    <Error Time=\"14:52:25.4524532\" Id=\"3280124998\">" + 
"      <ErrorCode>600</ErrorCode>" + 
"      <Message>Invalid Request</Message>" +
"      <DebugData />" +
"    </Error>" + 
"  </Response>" +
"</Autodiscover>"

let serverResponseDocument = XDocument(fromSource: serverResponseXML)
let serverMessage = serverResponseDocument?.documentElement?.getElementsByTagName("Message").first?.nodeValue
print(serverMessage) // prints Optional("Invalid Request")
```

Constructing model types from XML feeds is easy with getElementsByTagName

```swift
import PerfectXML

let rssXML = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>" +
"<rss version=\"2.0\">" +
"  <channel>" +
"    <title>W3Schools Home Page</title>" +
"    <link>http://www.w3schools.com</link>" +
"    <description>Free web building tutorials</description>" +
"    <item>" +
"      <title>RSS Tutorial</title>" +
"      <link>http://www.w3schools.com/xml/xml_rss.asp</link>" +
"      <description>New RSS tutorial on W3Schools</description>" +
"    </item>" +
"    <item>" +
"      <title>XML Tutorial</title>" +
"      <link>http://www.w3schools.com/xml</link>" +
"      <description>New XML tutorial on W3Schools</description>" +
"    </item>" +
"  </channel>" +
"</rss>"

let rssDocument = XDocument(fromSource: rssXML)
let feedItems = rssDocument?.documentElement?.getElementsByTagName("item")
print(feedItems?.count) // prints 2
let items = feedItems?.map({ MyCustomStruct(xmlNode: $0) })
```

Sometimes tag names are a bit too generic in order to meaningfully search for them, such as "title" in the example above. If we wanted to get the Channel title, link, and description, we could visit each of its children in a more deliberate way.

```swift
import PerfectXML

let rssXML = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>" +
"<rss version=\"2.0\">" +
"  <channel>" +
"    <title>W3Schools Home Page</title>" +
"    <link>http://www.w3schools.com</link>" +
"    <description>Free web building tutorials</description>" +
"    <item>" +
"      <title>RSS Tutorial</title>" +
"      <link>http://www.w3schools.com/xml/xml_rss.asp</link>" +
"      <description>New RSS tutorial on W3Schools</description>" +
"    </item>" +
"    <item>" +
"      <title>XML Tutorial</title>" +
"      <link>http://www.w3schools.com/xml</link>" +
"      <description>New XML tutorial on W3Schools</description>" +
"    </item>" +
"  </channel>" +
"</rss>"

let rssDocument = XDocument(fromSource: rssXML)
let channelNode = rssDocument?.documentElement?.getElementsByTagName("channel").first
let channelTitle = channelNode?.childNodes.filter({ $0.nodeName == "title" }).first?.nodeValue
let channelLink = channelNode?.childNodes.filter({ $0.nodeName == "link" }).first?.nodeValue
let channelDescription = channelNode?.childNodes.filter({ $0.nodeName == "description" }).first?.nodeValue

print(channelTitle) // Optional("W3Schools Home Page")
print(channelLink) // Optional("http://www.w3schools.com")
print(channelDescription) // Optional("Free web building tutorials")
```

### Parse XML Source

This snippet will parse an XML source string and then convert it back into a string.

```swift
let docSrc = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<a><b><c a=\"attr1\">HI</c><d/></b></a>\n"
let doc = XDocument(fromSource: docSrc)
let str = doc?.string(pretty: false)
XCTAssert(str == docSrc, "\(str)")
```

### Parse HTML Source

This snippet will parse an HTML source string.

```swift
let docSrc = "<html>\n<head>\n<title>title</title></head>\n<body>\n<div>hi</div>\n</body>\n</html>\n"
let doc = HTMLDocument(fromSource: docSrc)
let nodeName = doc?.documentElement?.nodeName
XCTAssert(nodeName == "html")
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
```

## Additional APIs

Beyond the DOM + XPath surface documented above, `Sources/PerfectXML` also includes:

- **SAX push-parser** (`SAX.swift`) — event-driven parsing for large documents where building a full DOM tree isn't desirable.
- **Streaming reader** (`XMLStream.swift`) — an incremental/streaming XML reader.
- **XML encoding** (`Codable.swift`) — `XMLEncoder().encode(value, rootName:namespace:)` encodes a flat `Encodable` struct of primitive values as an XML document, one child element per property. A `namespace:` becomes the root's default namespace (`<root xmlns="…">`). Nested values, arrays (including an empty top-level array) and single values aren't supported and throw `XMLEncoderError`. There is no XML decoder.

These aren't yet covered by worked examples in this README; see the source files and `Tests/PerfectXMLTests/PerfectXMLTests.swift` for usage.

## Migrating from 3.x

4.0.0 is a major release; the [release notes](../../releases/tag/4.0.0) list every change. The ones most likely to need attention:

* **Toolchain and platforms.** Swift tools 6.2 is required. The package declares macOS 12+ and iOS 15+ (3.x declared no platforms).
* **No more `Perfect-libxml2` dependency.** libxml2 is wrapped inside this package. The C module is still named `perfectxml2`. On macOS, the SDK's libxml2 is used; a Homebrew libxml2 is no longer needed.
* **`Sendable`.** The node, document and parser classes are `@unchecked Sendable`. They have no internal locking: use each document, `SAXParser` or `XMLStream` from one task at a time.
* **`XNode.ownerDocument` is read-only** (`private(set)`).
* **`XMLStream` no longer loads external DTDs.** 3.x enabled DTD loading by mistake.
* **External entities stay unloaded even if the libxml2 global says otherwise.** `XDocument` and `XMLStream` force entity substitution off, so even in a process that called `xmlSubstituteEntitiesDefault(1)`, `file://` entity contents don't appear in `nodeValue`. 3.x's `xmlParseDoc` honoured the global.
* **`XMLEncoder`.** It throws instead of crashing on an unsupported shape, and also throws for a top-level array (an empty one used to encode as `<root/>`). `namespace:` now writes `<root xmlns="…">`; 3.x wrote the malformed `<root:namespace>…</root>`. `XMLDecoderError`, which nothing threw, is removed.

## Testing

Run the test suite with:

```
swift test
```

See `Tests/PerfectXMLTests/PerfectXMLTests.swift` for the full suite, including the DOM/XPath examples shown throughout this README.
