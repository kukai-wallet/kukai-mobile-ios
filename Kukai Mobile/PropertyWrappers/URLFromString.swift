//
//  URLFromString.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 24/07/2023.
//

import Foundation

@propertyWrapper
public struct URLFromString: Hashable, Equatable {
	public var wrappedValue: URL?
	
	public init(wrappedValue: URL?) {
		self.wrappedValue = wrappedValue
	}
}

extension URLFromString: Decodable {
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		
		if let temp = try? container.decode(String.self) {
			wrappedValue = URL(string: temp)
			
		} else if let temp = try? container.decode(URL.self) {
			wrappedValue = temp
		}
		
	}
}

extension KeyedDecodingContainer {
	func decode(_ type: URLFromString.Type, forKey key: Key) throws -> URLFromString {
		try decodeIfPresent(type, forKey: key) ?? URLFromString(wrappedValue: nil)
	}
}

extension URLFromString: Encodable {
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		
		if let temp = wrappedValue {
			try? container.encode(temp.absoluteString)
		}
	}
}

extension KeyedEncodingContainer {
	public mutating func encode(_ value: URLFromString, forKey key: Key) throws {
		if let temp = value.wrappedValue {
			try encode(temp.absoluteString, forKey: key)
		}
	}
}
