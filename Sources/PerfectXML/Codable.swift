//
//  Codable.swift
//  PerfectXML
//
//  Created by Kyle Jessup on 2018-03-12.
//

import Foundation

func die() -> Never {
	fatalError("Unimplemented")
}

public struct XMLDecoderError: Error {
	public let msg: String
	public init(_ m: String) {
		msg = m
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

public class XMLEncoder: Encoder {
	public let codingPath: [CodingKey]
	public let userInfo: [CodingUserInfoKey : Any]
	var encoded: String = ""
	
	init(rootName: String, codingPath cp: [CodingKey] = []) {
		codingPath = cp + [XMLCodingKey(rootName)]
		userInfo = [:]
	}
	
	public init() {
		codingPath = []
		userInfo = [:]
	}
	
	public func encode<A: Encodable>(_ value: A, rootName: String, namespace: String? = nil) throws -> Data {
		encoded = ""
		try value.encode(to: self)
		let namePrefix: String
		if let ns = namespace {
			namePrefix = ":\(ns)"
		} else {
			namePrefix = ""
		}
		if encoded.isEmpty {
			encoded = "<\(rootName)\(namePrefix)/>"
		} else {
			encoded = "<\(rootName)\(namePrefix)>\(encoded)</\(rootName)>"
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
		die()
	}
	
	public func singleValueContainer() -> SingleValueEncodingContainer {
		die()
	}
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
		die()
	}
	
	func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
		die()
	}
	
	func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
		die()
	}
	
	func superEncoder() -> Encoder {
		return parent
	}
	
	func superEncoder(forKey key: K) -> Encoder {
		return parent
	}
}
