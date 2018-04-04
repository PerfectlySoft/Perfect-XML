//
//  PerfectXPath.swift
//  PerfectXML
//
//  Created by Kyle Jessup on 2016-07-21.
//
//

import perfectxml2

/// An XPath result object type.
public enum XPathObject {
	case none
	case nodeSet([XNode])
	case boolean(Bool)
	case number(Double)
	case string(String)
	case invalidExpression
}

/// XPath related functions.
public extension XNode {
	
	private var xPathTargetNode: xmlNodePtr {
		if case .documentNode = self.nodeType {
			return xmlDocGetRootElement(fromNodePtr(nodePtr))
		}
		return nodePtr
	}
	
	private func initializeContext() -> xmlXPathContextPtr! {
		let targetNode = xPathTargetNode
		guard let ctx = xmlXPathNewContext(targetNode.pointee.doc) else {
			return nil
		}
		ctx.pointee.node = targetNode
		return ctx
	}
	
	private func translateXPath(result: xmlXPathObjectPtr) -> XPathObject {
		switch result.pointee.type {
		case XPATH_BOOLEAN:
			return .boolean(1 == xmlXPathCastToBoolean(result))
		case XPATH_NUMBER:
			return .number(xmlXPathCastToNumber(result))
		case XPATH_NODESET:
			var ary = [XNode]()
			guard let nodeSet = result.pointee.nodesetval else {
				return .nodeSet(ary)
			}
			for index in 0..<Int(nodeSet.pointee.nodeNr) {
				let nodeTst = nodeSet.pointee.nodeTab.advanced(by: index)
				guard let node = nodeTst.pointee else {
					continue
				}
				if node.pointee.type == XML_NAMESPACE_DECL {
					let ns: xmlNsPtr = UnsafeMutableRawPointer(node).assumingMemoryBound(to: xmlNs.self)
					var element: xmlNodePtr?
					if nil != ns.pointee.next && ns.pointee.next.pointee.type == XML_ELEMENT_NODE {
						element = UnsafeMutableRawPointer(ns.pointee.next)?.assumingMemoryBound(to: xmlNode.self)
					} else {
						element = xmlDocGetRootElement(node.pointee.doc)
					}
					if let fnd = xmlSearchNs(node.pointee.doc, element, ns.pointee.prefix) {
						ary.append(asConcreteNode(UnsafeMutableRawPointer(fnd).assumingMemoryBound(to: xmlNode.self)))
					}
				} else {
					ary.append(asConcreteNode(node))
				}
			}
			return .nodeSet(ary)
		default:
			guard let chars = xmlXPathCastToString(result) else {
				return .none
			}
			defer {
				xmlFree(chars)
			}
			return .string(String(validatingUTF8: UnsafeRawPointer(chars).assumingMemoryBound(to: Int8.self)) ?? "")
		}
	}
	/// Execute the XPath and return the result(s).
	/// Accepts and array of tuples holding namespace prefixes and uris.
	public func extract(path: String, namespaces: [(String, String)] = [(String, String)]()) -> XPathObject {
		guard let ctx = initializeContext() else {
			return .none
		}
		defer {
			xmlXPathFreeContext(ctx)
		}
		
		let errorTracker = XErrorTracker()
		ctx.pointee.userData = Unmanaged.passUnretained(errorTracker).toOpaque()
		ctx.pointee.error = {
			userData, error in
			guard let userData = userData else {
				return
			}
			let errorTracker: XErrorTracker = Unmanaged.fromOpaque(userData).takeUnretainedValue()
			
			print("help")
		}
		
		for (prefix, uri) in namespaces {
			xmlXPathRegisterNs(ctx, prefix, uri)
		}
		
		if let result = xmlXPathEval(path, ctx) {
			defer {
				xmlXPathFreeObject(result)
			}
			return translateXPath(result: result)
		}
		return .none
	}
	/// Execute the XPath and return a single resul tnode or nil.
	/// Accepts and array of tuples holding namespace prefixes and uris.
	public func extractOne(path: String, namespaces: [(String, String)] = [(String, String)]()) -> XNode? {
		guard case .nodeSet(let nodes) = extract(path: path, namespaces: namespaces) else {
			return nil
		}
		return nodes.first
	}
}
