//
//  DefaultUUID.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 24/07/2023.
//

import Foundation

@propertyWrapper
public struct DefaultUUID: Hashable, Equatable {
	public var wrappedValue: UUID
	
	public init(wrappedValue: UUID) {
		self.wrappedValue = wrappedValue
	}
}

extension DefaultUUID: Decodable {
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		wrappedValue = try container.decode(UUID.self)
	}
}

extension KeyedDecodingContainer {
	public func decode(_ type: DefaultUUID.Type, forKey key: Key) throws -> DefaultUUID {
		try decodeIfPresent(type, forKey: key) ?? .init(wrappedValue: UUID())
	}
}

extension DefaultUUID: Encodable {
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(wrappedValue)
	}
}

extension KeyedEncodingContainer {
	public mutating func encode(_ value: DefaultUUID, forKey key: Key) throws {
		try encode(value.wrappedValue, forKey: key)
	}
}
