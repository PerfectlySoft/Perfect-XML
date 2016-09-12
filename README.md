# Perfect-XML

<p align="center">
    <a href="http://perfect.org/get-involved.html" target="_blank">
        <img src="http://perfect.org/assets/github/perfect_github_2_0_0.jpg" alt="Get Involed with Perfect!" width="854" />
    </a>
</p>

<p align="center">
    <a href="https://github.com/PerfectlySoft/Perfect" target="_blank">
        <img src="http://www.perfect.org/github/Perfect_GH_button_1_Star.jpg" alt="Star Perfect On Github" />
    </a>  
    <a href="https://gitter.im/PerfectlySoft/Perfect" target="_blank">
        <img src="http://www.perfect.org/github/Perfect_GH_button_2_Git.jpg" alt="Chat on Gitter" />
    </a>  
    <a href="https://twitter.com/perfectlysoft" target="_blank">
        <img src="http://www.perfect.org/github/Perfect_GH_button_3_twit.jpg" alt="Follow Perfect on Twitter" />
    </a>  
    <a href="http://perfect.ly" target="_blank">
        <img src="http://www.perfect.org/github/Perfect_GH_button_4_slack.jpg" alt="Join the Perfect Slack" />
    </a> 
</p>

<p align="center">
    <a href="https://developer.apple.com/swift/" target="_blank">
        <img src="https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat" alt="Swift 3.0">
    </a>
    <a href="https://developer.apple.com/swift/" target="_blank">
        <img src="https://img.shields.io/badge/Platforms-OS%20X%20%7C%20Linux%20-lightgray.svg?style=flat" alt="Platforms OS X | Linux">
    </a>
    <a href="http://perfect.org/licensing.html" target="_blank">
        <img src="https://img.shields.io/badge/License-Apache-lightgrey.svg?style=flat" alt="License Apache">
    </a>
    <a href="http://twitter.com/PerfectlySoft" target="_blank">
        <img src="https://img.shields.io/badge/Twitter-@PerfectlySoft-blue.svg?style=flat" alt="PerfectlySoft Twitter">
    </a>
    <a href="https://gitter.im/PerfectlySoft/Perfect?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge" target="_blank">
        <img src="https://img.shields.io/badge/Gitter-Join%20Chat-brightgreen.svg" alt="Join the chat at https://gitter.im/PerfectlySoft/Perfect">
    </a>
    <a href="http://perfect.ly" target="_blank">
        <img src="http://perfect.ly/badge.svg" alt="Slack Status">
    </a>
</p>
XML support for Perfect

It currently contains most of the DOM Core level 2 *read-only* APIs and includes XPath support.

## Issues

We are transitioning to using JIRA for all bugs and support related issues, therefore the GitHub issues has been disabled.

If you find a mistake, bug, or any other helpful suggestion you'd like to make on the docs please head over to [http://jira.perfect.org:8080/servicedesk/customer/portal/1](http://jira.perfect.org:8080/servicedesk/customer/portal/1) and raise it.

A comprehensive list of open issues can be found at [http://jira.perfect.org:8080/projects/ISS/issues](http://jira.perfect.org:8080/projects/ISS/issues)

## Building

Add this project as a dependency in your Package.swift file.

```
.Package(url:"https://github.com/PerfectlySoft/Perfect-XML.git", majorVersion: 2, minor: 0)
```

## macOS Build Notes

If you receive a compile error that says the following, you need to install and link libxml2

```
note: you may be able to install libxml-2.0 using your system-packager:

    brew install libxml2

Compile Swift Module 'PerfectXML' (2 sources)
<module-includes>:1:9: note: in file included from <module-includes>:1:
#import "libxml2.h"
```

To install and link libxml2 with homebrew, use the following two commands

```
brew install libxml2
brew link --force libxml2
```

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

Now you can get the root node of the XML structure by using the documentElement property

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
