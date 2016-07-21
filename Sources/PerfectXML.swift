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

public class XMLNode: CustomStringConvertible {
	private let nodePtr: xmlNodePtr
	public func string(pretty: Bool = false) -> String {
		let buff = xmlBufferCreate()
		defer { xmlBufferFree(buff) }
		var newNodePtr = self.nodePtr.pointee
		_ = xmlNodeDump(buff, self.nodePtr.pointee.doc, &newNodePtr, 0, pretty ? 1 : 0)
		guard let content = xmlBufferContent(buff) else {
			return ""
		}
		return String(validatingUTF8: UnsafeMutablePointer(content)) ?? ""
	}
	public var description: String {
		return self.string()
	}
	
	public var childNodes: [XMLNode] {
		var c = nodePtr.pointee.children
		var ary = [XMLNode]()
		while let child = c {
			ary.append(XMLNode(child))
			c = c?.pointee.next
		}
		return ary
	}
	
	init(_ node: xmlNodePtr) {
		self.nodePtr = node
	}
	
	deinit {
		if nodePtr.pointee.type == XML_DOCUMENT_NODE {
			xmlFreeDoc(nodePtr.pointee.doc)
		}
	}
}

public class XMLDocument: XMLNode {
	
	static var initialize: Bool = {
		xmlInitParser()
		return true
	}()
	
	public init?(fromSource: String) {
		_ = XMLDocument.initialize
		guard let doc = xmlParseDoc(fromSource) else {
			return nil
		}
		super.init(unsafeBitCast(doc, to: UnsafeMutablePointer<xmlNode>.self))
	}
}


