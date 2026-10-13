//
//  Codable.swift
//  PerfectXML
//
//  Created by Kyle Jessup on 2018-03-12.
//

import Foundation

/// `XMLEncoder` only implements a flat keyed container of primitive
/// values — unkeyed (array) containers, single-value containers, and any
/// nested `Encodable` value are deliberately unimplemented pending real
/// usage evidence (nothing in this codebase's consumers needs more than
/// flat structs). `Encoder`/`KeyedEncodingContainerProtocol`'s
/// container-vending methods aren't declared `throws`, so there's no way
/// to fail immediately when one of those unsupported containers is
/// requested — instead they return one of these "poisoned" stand-ins,
/// and the *first actual attempt* to encode a value into it throws
/// `XMLEncoderError` (a real library should never `fatalError()` on
/// ordinary unsupported input from calling code).
private let unsupportedShapeMessage =
	"XMLEncoder does not support unkeyed/single-value/nested containers — only a flat keyed container of primitive values is implemented."

struct UnsupportedEncodingContainer: UnkeyedEncodingContainer, SingleValueEncodingContainer {
	let codingPath: [CodingKey]
	var count: Int { 0 }

	private func fail() throws {
		throw XMLEncoderError(unsupportedShapeMessage)
	}

	mutating func encodeNil() throws { try fail() }
	mutating func encode(_ value: Bool) throws { try fail() }
	mutating func encode(_ value: String) throws { try fail() }
	mutating func encode(_ value: Double) throws { try fail() }
	mutating func encode(_ value: Float) throws { try fail() }
	mutating func encode(_ value: Int) throws { try fail() }
	mutating func encode(_ value: Int8) throws { try fail() }
	mutating func encode(_ value: Int16) throws { try fail() }
	mutating func encode(_ value: Int32) throws { try fail() }
	mutating func encode(_ value: Int64) throws { try fail() }
	mutating func encode(_ value: UInt) throws { try fail() }
	mutating func encode(_ value: UInt8) throws { try fail() }
	mutating func encode(_ value: UInt16) throws { try fail() }
	mutating func encode(_ value: UInt32) throws { try fail() }
	mutating func encode(_ value: UInt64) throws { try fail() }
	mutating func encode<T>(_ value: T) throws where T: Encodable { try fail() }

	mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
		KeyedEncodingContainer(UnsupportedKeyedEncodingContainer<NestedKey>(codingPath: codingPath))
	}
	mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
		UnsupportedEncodingContainer(codingPath: codingPath)
	}
	mutating func superEncoder() -> Encoder {
		UnsupportedEncoder(codingPath: codingPath)
	}
}

struct UnsupportedKeyedEncodingContainer<K: CodingKey>: KeyedEncodingContainerProtocol {
	let codingPath: [CodingKey]

	private func fail() throws {
		throw XMLEncoderError(unsupportedShapeMessage)
	}

	mutating func encodeNil(forKey key: K) throws { try fail() }
	mutating func encode(_ value: Bool, forKey key: K) throws { try fail() }
	mutating func encode(_ value: String, forKey key: K) throws { try fail() }
	mutating func encode(_ value: Double, forKey key: K) throws { try fail() }
	mutating func encode(_ value: Float, forKey key: K) throws { try fail() }
	mutating func encode(_ value: Int, forKey key: K) throws { try fail() }
	mutating func encode(_ value: Int8, forKey key: K) throws { try fail() }
	mutating func encode(_ value: Int16, forKey key: K) throws { try fail() }
	mutating func encode(_ value: Int32, forKey key: K) throws { try fail() }
	mutating func encode(_ value: Int64, forKey key: K) throws { try fail() }
	mutating func encode(_ value: UInt, forKey key: K) throws { try fail() }
	mutating func encode(_ value: UInt8, forKey key: K) throws { try fail() }
	mutating func encode(_ value: UInt16, forKey key: K) throws { try fail() }
	mutating func encode(_ value: UInt32, forKey key: K) throws { try fail() }
	mutating func encode(_ value: UInt64, forKey key: K) throws { try fail() }
	mutating func encode<T>(_ value: T, forKey key: K) throws where T: Encodable { try fail() }

	mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey {
		KeyedEncodingContainer(UnsupportedKeyedEncodingContainer<NestedKey>(codingPath: codingPath))
	}
	mutating func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
		UnsupportedEncodingContainer(codingPath: codingPath)
	}
	mutating func superEncoder() -> Encoder {
		UnsupportedEncoder(codingPath: codingPath)
	}
	mutating func superEncoder(forKey key: K) -> Encoder {
		UnsupportedEncoder(codingPath: codingPath)
	}
}

struct UnsupportedEncoder: Encoder {
	let codingPath: [CodingKey]
	let userInfo: [CodingUserInfoKey: Any] = [:]

	func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
		KeyedEncodingContainer(UnsupportedKeyedEncodingContainer<Key>(codingPath: codingPath))
	}
	func unkeyedContainer() -> UnkeyedEncodingContainer {
		UnsupportedEncodingContainer(codingPath: codingPath)
	}
	func singleValueContainer() -> SingleValueEncodingContainer {
		UnsupportedEncodingContainer(codingPath: codingPath)
	}
}

public struct XMLEncoderError: Error {
	public let msg: String
	public init(_ m: String) {
		msg = m
	}
}

struct XMLCodingKey: CodingKey {
	let stringValue: String
	let intValue: Int? = nil
	init?(stringValue s: String) {
		stringValue = s
	}
	init(_ s: String) {
		stringValue = s
	}
	init?(intValue: Int) {
		return nil
	}
}

/// Encodes a flat `Encodable` struct of primitive values as an XML
/// document: one child element per property, inside a root element.
///
/// Not `Sendable`: an encoder holds its output while encoding, so use one
/// instance per task (or a new one per call).
public class XMLEncoder: Encoder {
	public let codingPath: [CodingKey]
	public let userInfo: [CodingUserInfoKey : Any]
	var encoded: String = ""
	/// Set when an unsupported container is vended. Encoding something
	/// into one throws, but an empty one (a top-level empty array, say)
	/// is never written to, so `encode` checks this afterwards.
	var vendedUnsupportedContainer = false
	
	init(rootName: String, codingPath cp: [CodingKey] = []) {
		codingPath = cp + [XMLCodingKey(rootName)]
		userInfo = [:]
	}
	
	public init() {
		codingPath = []
		userInfo = [:]
	}
	
	/// Encodes `value` as `<rootName>…</rootName>`. If `namespace` is
	/// given, it becomes the default namespace of the root element and
	/// its children (`<rootName xmlns="namespace">`).
	///
	/// Throws `XMLEncoderError` for anything but a flat keyed container of
	/// primitive values, including top-level arrays (even empty ones),
	/// single values and nested `Encodable` properties.
	public func encode<A: Encodable>(_ value: A, rootName: String, namespace: String? = nil) throws -> Data {
		encoded = ""
		vendedUnsupportedContainer = false
		try value.encode(to: self)
		guard !vendedUnsupportedContainer else {
			throw XMLEncoderError(unsupportedShapeMessage)
		}
		let namespaceAttribute: String
		if let ns = namespace {
			namespaceAttribute = " xmlns=\"\(escapeAttributeValue(ns))\""
		} else {
			namespaceAttribute = ""
		}
		if encoded.isEmpty {
			encoded = "<\(rootName)\(namespaceAttribute)/>"
		} else {
			encoded = "<\(rootName)\(namespaceAttribute)>\(encoded)</\(rootName)>"
		}
		guard let data = encoded.data(using: .utf8) else {
			throw XMLEncoderError("Invalid encoding was generated.")
		}
		return data
	}
	
	public func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
		return KeyedEncodingContainer<Key>(XMLEncodingContainer<Key>(codingPath: codingPath, parent: self))
	}
	
	public func unkeyedContainer() -> UnkeyedEncodingContainer {
		vendedUnsupportedContainer = true
		return UnsupportedEncodingContainer(codingPath: codingPath)
	}

	public func singleValueContainer() -> SingleValueEncodingContainer {
		vendedUnsupportedContainer = true
		return UnsupportedEncodingContainer(codingPath: codingPath)
	}
}

private func escapeAttributeValue(_ s: String) -> String {
	s.replacingOccurrences(of: "&", with: "&amp;")
		.replacingOccurrences(of: "<", with: "&lt;")
		.replacingOccurrences(of: "\"", with: "&quot;")
}

class XMLEncodingContainer<K : CodingKey>: KeyedEncodingContainerProtocol {
	typealias Key = K
	let codingPath: [CodingKey]
	let parent: XMLEncoder
	
	init(codingPath c: [CodingKey], parent p: XMLEncoder) {
		codingPath = c
		parent = p
	}
	
	private func escapeEntities(_ s: String) -> String {
		return s.replacingOccurrences(of: "&", with: "&amp;")
			.replacingOccurrences(of: "<", with: "&lt;")
			.replacingOccurrences(of: ">", with: "&gt;")
	}
	
	private func append(_ s: String) {
		parent.encoded.append(s)
	}
	
	private func append(_ key: K, _ value: CustomStringConvertible) {
		append("<\(key.stringValue)>\(value)</\(key.stringValue)>")
	}
	
	func encodeNil(forKey key: K) throws {
		append("<\(key.stringValue)/>")
	}
	
	func encode(_ value: Bool, forKey key: K) throws {
		append(key, value)
	}
	
	func encode(_ value: Int, forKey key: K) throws {
		append(key, value)
	}
	
	func encode(_ value: Int8, forKey key: K) throws {
		append(key, value)
	}
	
	func encode(_ value: Int16, forKey key: K) throws {
		append(key, value)
	}
	
	func encode(_ value: Int32, forKey key: K) throws {
		append(key, value)
	}
	
	func encode(_ value: Int64, forKey key: K) throws {
		append(key, value)
	}
	
	func encode(_ value: UInt, forKey key: K) throws {
		append(key, value)
	}
	
	func encode(_ value: UInt8, forKey key: K) throws {
		append(key, value)
	}
	
	func encode(_ value: UInt16, forKey key: K) throws {
		append(key, value)
	}
	
	func encode(_ value: UInt32, forKey key: K) throws {
		append(key, value)
	}
	
	func encode(_ value: UInt64, forKey key: K) throws {
		append(key, value)
	}
	
	func encode(_ value: Float, forKey key: K) throws {
		append(key, value)
	}
	
	func encode(_ value: Double, forKey key: K) throws {
		append(key, value)
	}
	
	func encode(_ value: String, forKey key: K) throws {
		append(key, escapeEntities(value))
	}
	
	func encode<T>(_ value: T, forKey key: K) throws where T : Encodable {
		throw XMLEncoderError(unsupportedShapeMessage)
	}

	func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
		parent.vendedUnsupportedContainer = true
		return KeyedEncodingContainer(UnsupportedKeyedEncodingContainer<NestedKey>(codingPath: codingPath))
	}

	func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
		parent.vendedUnsupportedContainer = true
		return UnsupportedEncodingContainer(codingPath: codingPath)
	}
	
	func superEncoder() -> Encoder {
		return parent
	}
	
	func superEncoder(forKey key: K) -> Encoder {
		return parent
	}
}
