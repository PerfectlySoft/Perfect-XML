//
//  XMLStream.swift
//  PerfectXML
//
//  Created by Kyle Jessup on 2018-03-12.
//

import Foundation
import perfectxml2

public protocol XMLStreamDataProvider {
	mutating func getData(maxCount: Int) throws -> Data?
	mutating func close()
}

public struct XMLStreamError: Error {
	public let description: String
	public init(_ d: String) {
		description = d
	}
}

extension String {
	init?(_ p: UnsafePointer<xmlChar>?) {
		guard let n = p else {
			return nil
		}
		guard let s = n.withMemoryRebound(to: Int8.self, capacity: 0, { String(validatingCString: $0) }) else {
			return nil
		}
		self = s
	}
	init(_ p: UnsafePointer<xmlChar>?, default: String) {
		guard let n = p else {
			self = `default`
			return
		}
		guard let s = n.withMemoryRebound(to: Int8.self, capacity: 0, { String(validatingCString: $0) }) else {
			self = `default`
			return
		}
		self = s
	}
	init(_ p: UnsafePointer<xmlChar>?, count: Int, default: String) {
		guard let n = p else {
			self = `default`
			return
		}
		// `xmlChar` is already `UInt8` — the previous `Int8(n[$0])`
		// conversion here would trap at runtime for any byte >= 0x80
		// (every UTF-8 continuation byte), so this initializer could
		// never have correctly handled non-ASCII content. Building the
		// byte array directly as `[UInt8]` and using
		// `String(validating:as:)` (the non-deprecated replacement for
		// the old null-terminated-C-string API) fixes both issues.
		let bytes = (0..<count).map { n[$0] }
		guard let s = String(validating: bytes, as: UTF8.self) else {
			self = `default`
			return
		}
		self = s
	}
}


func asContext(_ a: AnyObject) -> UnsafeMutableRawPointer {
	return Unmanaged.passUnretained(a).toOpaque()
}

func fromContext<A: AnyObject>(_ type: A.Type, _ context: UnsafeMutableRawPointer) -> A {
	return Unmanaged<A>.fromOpaque(context).takeUnretainedValue()
}

func fromContext<A: AnyObject>(_ type: A.Type, _ context: UnsafeMutableRawPointer?) -> A? {
	guard let context = context else {
		return nil
	}
	return Unmanaged<A>.fromOpaque(context).takeUnretainedValue()
}

//xmlTextReaderGetParserColumnNumber

/// `@unchecked Sendable`: wraps a raw libxml2 streaming-reader context with
/// no internal synchronization. See `XNode`'s doc comment (`XMLDOM.swift`)
/// for this package's general thread-confinement contract — the same
/// applies here: drive one `XMLStream` instance's `next`/`nextSibling`
/// calls from a single task.
public class XMLStream: @unchecked Sendable {
	public enum NodeType: Int {
		case none = 0, element, attribute, text, cdata, entityReference,
			entity, processingInstruction, comment, document, documentType, fragment,
		notation, whitespace, significantWhitespace, endElement, endEntity, xmlDeclaration
	}
	public struct NodeDescriptor {
		let readerPtr: xmlTextReaderPtr
		init(_ r: xmlTextReaderPtr) {
			readerPtr = r
		}
	}
	
	var dataProvider: XMLStreamDataProvider
	var readerPtr: xmlTextReaderPtr?
	public init(provider: XMLStreamDataProvider) {
		dataProvider = provider
	}
	deinit {
		if let r = readerPtr {
			xmlFreeTextReader(r)
		}
	}
	private func getReaderPtr() throws -> xmlTextReaderPtr {
		if let r = readerPtr {
			return r
		}
		let readCallback: xmlInputReadCallback = {
			context, buffer, bufferSize -> Int32 in
			guard let context = context, let buffer = buffer else {
				return -1
			}
			let me = fromContext(XMLStream.self, context)
			do {
				guard let data = try me.dataProvider.getData(maxCount: Int(bufferSize)) else {
					return 0
				}
				data.withUnsafeBytes { (rawBuffer: UnsafeRawBufferPointer) in
					if let base = rawBuffer.baseAddress {
						memcpy(buffer, base, data.count)
					}
				}
				return Int32(data.count)
			} catch {
				return -1
			}
		}
		let closeCallback: xmlInputCloseCallback = {
			context in
			guard let context = context else {
				return -1
			}
			let me = fromContext(XMLStream.self, context)
			me.dataProvider.close()
			return 0
		}
		// Options bitmask must only contain real xmlParserOption values.
		// A previous version of this code also OR'd in
		// XML_PARSER_SUBST_ENTITIES — that constant belongs to the
		// unrelated xmlParserProperties enum (for
		// xmlTextReaderSetParserProp), and its raw value (4) collides
		// with XML_PARSE_DTDLOAD in the actual xmlParserOption enum —
		// i.e. it was accidentally enabling external DTD loading, not
		// hardening anything. XML_PARSE_NONET blocks network-based
		// external entity/DTD resolution (the classic XXE/SSRF vector);
		// entity substitution (XML_PARSE_NOENT) is deliberately left at
		// its default-off behavior to avoid billion-laughs-style
		// expansion DoS.
		guard let reader = xmlReaderForIO(readCallback,
										  closeCallback,
										  asContext(self),
										  "/",
										  "utf8",
										  Int32(XML_PARSE_NONET.rawValue | XML_PARSE_NOCDATA.rawValue)) else {
											throw XMLStreamError("Unable to allocate XML reader.")
		}
		readerPtr = reader
		return reader
	}
	
	public func next() throws -> NodeDescriptor? {
		let reader = try getReaderPtr()
		let readRes = xmlTextReaderRead(reader)
		switch readRes {
		case 0:
			return nil
		case -1:
			throw XMLStreamError("Error calling xmlTextReaderRead.")
		default:
			return NodeDescriptor(reader)
		}
	}
	public func nextSibling() throws -> NodeDescriptor? {
		let reader = try getReaderPtr()
		let readRes = xmlTextReaderNext(reader)
		switch readRes {
		case 0:
			return nil
		case -1:
			throw XMLStreamError("Error calling xmlTextReaderNext.")
		default:
			return NodeDescriptor(reader)
		}
	}
	public func namespaceURI(prefix: String) -> String? {
		return String(xmlTextReaderLookupNamespace(readerPtr, prefix))
	}
}

public extension XMLStream.NodeDescriptor {
	var type: XMLStream.NodeType? {
		return XMLStream.NodeType(rawValue: Int(xmlTextReaderNodeType(readerPtr)))
	}
	var localName: String? {
		return String(xmlTextReaderConstLocalName(readerPtr))
	}
	var name: String? {
		return String(xmlTextReaderConstName(readerPtr))
	}
	var namespaceURI: String? {
		return String(xmlTextReaderConstNamespaceUri(readerPtr))
	}
	var prefix: String? {
		return String(xmlTextReaderConstPrefix(readerPtr))
	}
	var value: String? {
		return String(xmlTextReaderConstValue(readerPtr))
	}
	var content: String? {
		guard let n = xmlTextReaderReadString(readerPtr) else {
			return nil
		}
		defer {
			libxmlFree(n)
		}
		return n.withMemoryRebound(to: Int8.self, capacity: 0) {
			return String(validatingCString: $0)
		}
	}
	var isEmpty: Bool {
		return xmlTextReaderIsEmptyElement(readerPtr) == 1
	}
	var attributeCount: Int {
		return Int(xmlTextReaderAttributeCount(readerPtr))
	}
	var depth: Int {
		return Int(xmlTextReaderDepth(readerPtr))
	}
}

public extension XMLStream.NodeDescriptor {
	func getAttribute(_ name: String, namespaceURI: String? = nil) -> String? {
		if let ns = namespaceURI {
			return String(xmlTextReaderGetAttributeNs(readerPtr, name, ns))
		}
		return String(xmlTextReaderGetAttribute(readerPtr, name))
	}
}






