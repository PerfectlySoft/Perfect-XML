//
//  Package.swift
//  PerfectXML
//
//  Created by Kyle Jessup on 2016-07-20.
//	Copyright (C) 2016 PerfectlySoft, Inc.
//
//===----------------------------------------------------------------------===//
//
// This source file is part of the Perfect.org open source project
//
// Copyright (c) 2015 - 2016 PerfectlySoft Inc. and the Perfect project authors
// Licensed under Apache License v2.0
//
// See http://perfect.org/licensing.html for license information
//
//===----------------------------------------------------------------------===//
//

import libxml2

func toNodePtr<T>(_ p: T) -> xmlNodePtr {
	return unsafeBitCast(p, to: UnsafeMutablePointer<xmlNode>.self)
}

func fromNodePtr<T>(_ nodePtr: xmlNodePtr) -> UnsafeMutablePointer<T> {
	return unsafeBitCast(nodePtr, to: UnsafeMutablePointer<T>.self)
}

private typealias ForEachFunc = (_ node: xmlNodePtr) -> Bool
private func forEach(node: xmlNodePtr, childrenOnly: Bool, continueFunc: ForEachFunc) -> Bool {
	if !childrenOnly && !continueFunc(node) {
		return false
	}
	var c = node.pointee.children
	while let cnode = c {
		guard forEach(node: cnode, childrenOnly: false, continueFunc: continueFunc) else {
			return false
		}
		c = cnode.pointee.next
	}
	return true
}

/// Supported XML node types.
public enum XNodeType {
	case elementNode, attributeNode, textNode, cDataSection, entityReferenceNode
	case entityNode, processingInstruction, commentNode, documentNode, documentTypeNode
	case documentFragmentNode, notationNode
	case unknownNodeType
}

/// Base class for all XML nodes.
/// This is intended to track the DOM Core level 2 specification as much as is practically possible.
/// http://www.w3.org/TR/DOM-Level-2-Core/core.html
public class XNode: CustomStringConvertible {
	
	let nodePtr: xmlNodePtr
	/// The name of this node, depending on its type.
	public var nodeName: String {
		guard let name = nodePtr.pointee.name else {
			return ""
		}
		return String(validatingUTF8: UnsafeRawPointer(name).assumingMemoryBound(to: Int8.self)) ?? ""
	}
	/// The value of this node, depending on its type. When it is defined to be null, setting it has no effect.
	public var nodeValue: String? {
		guard let content = xmlNodeGetContent(nodePtr) else {
			return nil
		}
		defer {
			xmlFree(content)
		}
		return String(validatingUTF8: UnsafeMutableRawPointer(content).assumingMemoryBound(to: Int8.self))
	}
	/// A code representing the type of the underlying object.
	public var nodeType: XNodeType {
		switch nodePtr.pointee.type {
		case XML_ELEMENT_NODE: return .elementNode
		case XML_ATTRIBUTE_NODE: return .attributeNode
		case XML_TEXT_NODE: return .textNode
		case XML_CDATA_SECTION_NODE: return .cDataSection
		case XML_ENTITY_REF_NODE: return .entityReferenceNode
		case XML_ENTITY_NODE: return .entityNode
		case XML_PI_NODE: return .processingInstruction
		case XML_COMMENT_NODE: return .commentNode
		case XML_DOCUMENT_NODE: return .documentNode
		case XML_DOCUMENT_TYPE_NODE: return .documentTypeNode
		case XML_DOCUMENT_FRAG_NODE: return .documentFragmentNode
		case XML_NOTATION_NODE: return .notationNode
		default: return .unknownNodeType
//			XML_HTML_DOCUMENT_NODE = 13
//			XML_DTD_NODE = 14
//			XML_ELEMENT_DECL = 15
//			XML_ATTRIBUTE_DECL = 16
//			XML_ENTITY_DECL = 17
//			XML_NAMESPACE_DECL = 18
//			XML_XINCLUDE_START = 19
//			XML_XINCLUDE_END = 20
//			XML_DOCB_DOCUMENT_NODE
		}
	}
	/// The parent of this node. All nodes, except Attr, Document, DocumentFragment, Entity, and Notation may have a parent. However, if a node has just been created and not yet added to the tree, or if it has been removed from the tree, this is null.
	public var parentNode: XNode? {
		guard let parentNode = nodePtr.pointee.parent else {
			return nil
		}
		return asConcreteNode(parentNode)
	}
	/// A NodeList that contains all children of this node. If there are no children, this is a NodeList containing no nodes.
	public var childNodes: [XNode] {
		var c = nodePtr.pointee.children
		var ary = [XNode]()
		while let child = c {
			let concrete = asConcreteNode(child)
			ary.append(concrete)
			c = c?.pointee.next
		}
		return ary
	}
	/// The first child of this node. If there is no such node, this returns null.
	public var firstChild: XNode? {
		guard let child = nodePtr.pointee.children else {
			return nil
		}
		return asConcreteNode(child)
	}
	/// The last child of this node. If there is no such node, this returns null.
	public var lastChild: XNode? {
		guard let child = xmlGetLastChild(nodePtr) else {
			return nil
		}
		return asConcreteNode(child)
	}
	/// The node immediately preceding this node. If there is no such node, this returns null.
	public var previousSibling: XNode? {
		guard let sib = nodePtr.pointee.prev else {
			return nil
		}
		return asConcreteNode(sib)
	}
	/// The node immediately following this node. If there is no such node, this returns null.
	public var nextSibling: XNode? {
		guard let sib = nodePtr.pointee.next else {
			return nil
		}
		return asConcreteNode(sib)
	}
	/// The Document object associated with this node. This is also the Document object used to create new nodes. When this node is a Document or a DocumentType which is not used with any Document yet, this is null.
	public var ownerDocument: XDocument?
	/// A NamedNodeMap containing the attributes of this node (if it is an Element) or null otherwise.
	public var attributes: XNamedNodeMap? {
		guard case .elementNode = nodeType else {
			return nil
		}
		return XNamedNodeMapAttr(node: self)
	}
	/// The namespace URI of this node, or null if it is unspecified.
	/// This is not a computed value that is the result of a namespace lookup based on an examination of the namespace declarations in scope. It is merely the namespace URI given at creation time.
	/// For nodes of any type other than ELEMENT_NODE and ATTRIBUTE_NODE and nodes created with a DOM Level 1 method, such as createElement from the Document interface, this is always null.
	public var namespaceURI: String? {
		guard let ns = nodePtr.pointee.ns else {
			return nil
		}
		guard let chars = ns.pointee.href else {
			return nil
		}
		return String(validatingUTF8: UnsafeRawPointer(chars).assumingMemoryBound(to: Int8.self))
	}
	/// The namespace prefix of this node, or null if it is unspecified.
	public var prefix: String? {
		guard let ns = nodePtr.pointee.ns else {
			return nil
		}
		guard let chars = ns.pointee.prefix else {
			return nil
		}
		return String(validatingUTF8: UnsafeRawPointer(chars).assumingMemoryBound(to: Int8.self))
	}
	/// Returns the local part of the qualified name of this node.
	/// For nodes of any type other than ELEMENT_NODE and ATTRIBUTE_NODE and nodes created with a DOM Level 1 method, such as createElement from the Document interface, this is always null.
	public var localName: String? {
		guard let name = nodePtr.pointee.name else {
			return nil
		}
		var prefix = UnsafeMutablePointer<xmlChar>(nil as OpaquePointer?)
		guard let localPart = xmlSplitQName2(name, &prefix) else {
			return nodeName
		}
		defer {
			xmlFree(localPart)
			if nil != prefix {
				xmlFree(prefix)
			}
		}
		return String(validatingUTF8: UnsafeRawPointer(localPart).assumingMemoryBound(to: Int8.self))
	}
	
	init(_ node: xmlNodePtr, document: XDocument?) {
		self.nodePtr = node
		self.ownerDocument = document
	}
	
	deinit {
		if nodePtr.pointee.type == XML_DOCUMENT_NODE {
			xmlFreeDoc(nodePtr.pointee.doc)
		}
	}
	
	func asConcreteNode(_ ptr: xmlNodePtr) -> XNode {
		switch ptr.pointee.type {
		case XML_ELEMENT_NODE: return XElement(fromNodePtr(ptr), document: self.ownerDocument)
		case XML_ATTRIBUTE_NODE: return XAttr(fromNodePtr(ptr), document: self.ownerDocument)
		case XML_TEXT_NODE: return XText(ptr, document: self.ownerDocument)
		case XML_CDATA_SECTION_NODE: return XCData(ptr, document: self.ownerDocument)
//		case XML_ENTITY_REF_NODE:
//		case XML_ENTITY_NODE:
//		case XML_PI_NODE:
		case XML_COMMENT_NODE: return XComment(ptr, document: self.ownerDocument)
//		case XML_DOCUMENT_NODE:
//		case XML_DOCUMENT_TYPE_NODE:
//		case XML_DOCUMENT_FRAG_NODE:
//		case XML_NOTATION_NODE:
//		case XML_HTML_DOCUMENT_NODE:
//		case XML_DTD_NODE:
//		case XML_ELEMENT_DECL:
//		case XML_ATTRIBUTE_DECL:
//		case XML_ENTITY_DECL:
//		case XML_NAMESPACE_DECL:
//		case XML_XINCLUDE_START:
//		case XML_XINCLUDE_END:
//		case XML_DOCB_DOCUMENT_NODE:
		default: ()
//			print("Unhandled node type \(ptr.pointee.type)")
			return XNode(ptr, document: self.ownerDocument)
		}
	}
	/// Convert the node tree to String. Optionally pretty-print.
	public func string(pretty: Bool = false) -> String {
		let buff = xmlBufferCreate()
		defer { xmlBufferFree(buff) }
		var newNodePtr = self.nodePtr.pointee
		_ = xmlNodeDump(buff, self.nodePtr.pointee.doc, &newNodePtr, 0, pretty ? 1 : 0)
		guard let content = xmlBufferContent(buff) else {
			return ""
		}
		return String(validatingUTF8: UnsafeRawPointer(content).assumingMemoryBound(to: Int8.self)) ?? ""
	}
	/// The non-pretty printed string value.
	public var description: String {
		return self.string()
	}
}

/// An XML document.
public class XDocument: XNode {
	
	static var initialize: Bool = {
		xmlInitParser()
		xmlXPathInit()
		return true
	}()
	
	override public var nodeName: String {
		return "#document"
	}
	
	/// This is a convenience attribute that allows direct access to the child node that is the root element of the document.
	public var documentElement: XElement? {
		guard let e = xmlDocGetRootElement(fromNodePtr(nodePtr)) else {
			return nil
		}
		return XElement(fromNodePtr(e), document: self)
	}
	
	/// Parse the XML source string and create the document, if possible.
	public init?(fromSource: String) {
		_ = XDocument.initialize
		guard let doc = xmlParseDoc(fromSource) else {
			return nil
		}
		super.init(toNodePtr(doc), document: nil)
	}
	
	init(_ ptr: xmlDocPtr) {
		super.init(toNodePtr(ptr), document: nil)
	}
	
	/// Returns a NodeList of all the Elements with a given tag name in the order in which they are encountered in a preorder traversal of the Document tree.
	public func getElementsByTagName(_ name: String) -> [XElement] {
		guard let element = documentElement else {
			return [XElement]()
		}
		return element.getElementsByTagName(name, childrenOnly: false)
	}
	
	/// Returns a NodeList of all the Elements with a given local name and namespace URI in the order in which they are encountered in a preorder traversal of the Document tree.
	public func getElementsByTagNameNS(namespaceURI: String, localName: String) -> [XElement] {
		guard let element = documentElement else {
			return [XElement]()
		}
		return element.getElementsByTagNameNS(namespaceURI: namespaceURI, localName: localName, childrenOnly: false)
	}
	
	/// Returns the Element whose ID is given by elementId. If no such element exists, returns null. Behavior is not defined if more than one element has this ID.
	/// Note that this implimentation looks explicitly for an "id" attribute.
	public func getElementById(_ elementId: String) -> XElement? {
		guard let element = documentElement else {
			return nil
		}
		return element.getElementById(elementId, childrenOnly: false)
	}
}

public class HTMLDocument: XDocument {
	/// Parse the HTML source string and create the document, if possible.
	public init?(fromSource: String, encoding: String = "UTF-8") {
		_ = XDocument.initialize
		let src = Array(fromSource.utf8)
		let p = UnsafeMutablePointer<UInt8>(mutating: UnsafePointer(src))
		guard let doc = htmlParseDoc(p, encoding) else {
			return nil
		}
		super.init(doc)
	}
}

/// An XML element node.
public class XElement: XNode {
	/// The name of the element.
	public var tagName: String {
		return nodeName
	}
	
	init(_ node: xmlElementPtr, document: XDocument?) {
		super.init(toNodePtr(node), document: document)
	}
	/// Retrieves an attribute value by name.
	public func getAttribute(name: String) -> String? {
		guard let node = getAttributeNode(name: name) else {
			return nil
		}
		return node.value
	}
	/// Retrieves an attribute node by name.
	/// To retrieve an attribute node by qualified name and namespace URI, use the getAttributeNodeNS method.
	public func getAttributeNode(name: String) -> XAttr? {
		var n = nodePtr.pointee.properties
		while let attr = n {
			guard let namePtr = attr.pointee.name else {
				continue
			}
			if String(validatingUTF8: UnsafeRawPointer(namePtr).assumingMemoryBound(to: Int8.self)) == name {
				return asConcreteNode(UnsafeMutableRawPointer(attr).assumingMemoryBound(to: xmlNode.self)) as? XAttr
			}
			n = n?.pointee.next
		}
		return nil
	}
	/// Retrieves an Attr node by local name and namespace URI. HTML-only DOM implementations do not need to implement this method.
	public func getAttributeNodeNS(namespaceURI: String, localName: String) -> XAttr? {
		var n = nodePtr.pointee.properties
		while let attr = n {
			defer {
				n = n?.pointee.next
			}
			guard let cname = attr.pointee.name else {
				continue
			}
			guard let ns = attr.pointee.ns else {
				continue
			}
			guard let nameTest = String(validatingUTF8: UnsafeRawPointer(cname).assumingMemoryBound(to: Int8.self)),
				let href = ns.pointee.href,
				let nsNameTest = String(validatingUTF8: UnsafeRawPointer(href).assumingMemoryBound(to: Int8.self)) else {
					continue
			}
			
			if nameTest == localName && nsNameTest == namespaceURI {
				return asConcreteNode(UnsafeMutableRawPointer(attr).assumingMemoryBound(to: xmlNode.self)) as? XAttr
			}
		}
		return nil
	}
	/// Returns true when an attribute with a given name is specified on this element or has a default value, false otherwise.
	public func hasAttribute(name: String) -> Bool {
		return nil != getAttributeNode(name: name)
	}
	/// Returns true when an attribute with a given local name and namespace URI is specified on this element or has a default value, false otherwise.
	public func hasAttributeNS(namespaceURI: String, localName: String) -> Bool {
		return nil != getAttributeNodeNS(namespaceURI: namespaceURI, localName: localName)
	}
	/// Returns a NodeList of all descendant Elements with a given tag name, in the order in which they are encountered in a preorder traversal of this Element tree.
	public func getElementsByTagName(_ name: String) -> [XElement] {
		return getElementsByTagName(name, childrenOnly: true)
	}
	/// Returns a NodeList of all the descendant Elements with a given local name and namespace URI in the order in which they are encountered in a preorder traversal of this Element tree.
	public func getElementsByTagNameNS(namespaceURI: String, localName: String) -> [XElement] {
		return getElementsByTagNameNS(namespaceURI: namespaceURI, localName: localName, childrenOnly: true)
	}
	
	func getElementsByTagNameNS(namespaceURI: String, localName: String, childrenOnly: Bool) -> [XElement] {
		var ret = [XElement]()
		_ = forEach(node: nodePtr, childrenOnly: childrenOnly) {
			node in
			
			guard let name = node.pointee.name else {
				return true
			}
			guard localName == "*" || String(validatingUTF8: UnsafeRawPointer(name).assumingMemoryBound(to: Int8.self)) == localName else {
				return true
			}
			guard let ns = node.pointee.ns else {
				return true
			}
			guard let chars = ns.pointee.href else {
				return true
			}
			guard namespaceURI == "*" || String(validatingUTF8: UnsafeRawPointer(chars).assumingMemoryBound(to: Int8.self)) == namespaceURI else {
				return true
			}
			guard let element = self.asConcreteNode(node) as? XElement else {
				return true
			}
			ret.append(element)
			return true
		}
		return ret
	}
	
	func getElementById(_ elementId: String, childrenOnly: Bool) -> XElement? {
		var ret: XElement?
		_ = forEach(node: nodePtr, childrenOnly: childrenOnly) {
			node in
			guard node.pointee.type == XML_ELEMENT_NODE else {
				return true
			}
			let element = XElement(fromNodePtr(node), document: self.ownerDocument)
			guard let attrVal = element.getAttribute(name: "id") else {
				return true
			}
			if attrVal == elementId {
				ret = element
			}
			return nil == ret
		}
		return ret
	}
	
	func getElementsByTagName(_ name: String, childrenOnly: Bool) -> [XElement] {
		var ret = [XElement]()
		_ = forEach(node: nodePtr, childrenOnly: childrenOnly) {
			node in
			
			guard let namePtr = node.pointee.name else {
				return true
			}
			guard name == "*" || String(validatingUTF8: UnsafeRawPointer(namePtr).assumingMemoryBound(to: Int8.self)) == name else {
				return true
			}
			guard let element = self.asConcreteNode(node) as? XElement else {
				return true
			}
			ret.append(element)
			return true
		}
		return ret
	}
}

/// A single XML element attribute node.
public class XAttr: XNode {
	/// Returns the name of this attribute.
	public var name: String {
		return nodeName
	}
	/// On retrieval, the value of the attribute is returned as a string. Character and general entity references are replaced with their values. See also the method getAttribute on the Element interface.
	public var value: String {
		return nodeValue ?? ""
	}
	/// The Element node this attribute is attached to or null if this attribute is not in use.
	public var ownerElement: XElement? {
		return parentNode as? XElement
	}
	
	init(_ node: xmlAttrPtr, document: XDocument?) {
		super.init(toNodePtr(node), document: document)
	}
}

/// An XML text node.
public class XText: XNode {
	override public var nodeName: String {
		return "#text"
	}
}

/// An XML CData node.
public class XCData: XText {
	override public var nodeName: String {
		return "#cdata-section"
	}
}

/// An XML comment node.
public class XComment: XText {
	override public var nodeName: String {
		return "#comment"
	}
}

/// A NamedNodeMap protocol.
public protocol XNamedNodeMap {
	var length: Int { get }
	func getNamedItem(name: String) -> XNode?
	func getNamedItemNS(namespaceURI: String, localName: String) -> XNode?
	func item(index: Int) -> XNode?
}

/// Subscript operators for NamedNodeMap
public extension XNamedNodeMap {
	subscript(index: Int) -> XNode? {
		return item(index: index)
	}
	subscript(name: String) -> XNode? {
		return getNamedItem(name: name)
	}
}

struct XNamedNodeMapAttr: XNamedNodeMap {
	let node: XNode
	
	var length: Int {
		var c = 0
		var n = node.nodePtr.pointee.properties
		while let _ = n {
			c += 1
			n = n?.pointee.next
		}
		return c
	}
	
	func getNamedItem(name: String) -> XNode? {
		var n = node.nodePtr.pointee.properties
		while let attr = n {
			defer {
				n = n?.pointee.next
			}
			guard let cname = attr.pointee.name else {
				continue
			}
			guard let nameTest = String(validatingUTF8: UnsafeRawPointer(cname).assumingMemoryBound(to: Int8.self)) else {
				continue
			}
			if nameTest == name {
				return node.asConcreteNode(UnsafeMutableRawPointer(attr).assumingMemoryBound(to: xmlNode.self))
			}
		}
		return nil
	}
	
	func getNamedItemNS(namespaceURI: String, localName: String) -> XNode? {
		var n = node.nodePtr.pointee.properties
		while let attr = n {
			defer {
				n = n?.pointee.next
			}
			guard let cname = attr.pointee.name else {
				continue
			}
			guard let ns = attr.pointee.ns else {
				continue
			}
			guard let nameTest = String(validatingUTF8: UnsafeRawPointer(cname).assumingMemoryBound(to: Int8.self)),
				let href = ns.pointee.href,
				let nsNameTest = String(validatingUTF8: UnsafeRawPointer(href).assumingMemoryBound(to: Int8.self)) else {
				continue
			}
			
			if nameTest == localName && nsNameTest == namespaceURI {
				return node.asConcreteNode(UnsafeMutableRawPointer(attr).assumingMemoryBound(to: xmlNode.self))
			}
		}
		return nil
	}
	
	func item(index: Int) -> XNode? {
		var c = index
		var n = node.nodePtr.pointee.properties
		while let attr = n {
			if c == 0 {
				return node.asConcreteNode(UnsafeMutableRawPointer(attr).assumingMemoryBound(to: xmlNode.self))
			}
			c -= 1
			n = n?.pointee.next
		}
		return nil
	}
}



