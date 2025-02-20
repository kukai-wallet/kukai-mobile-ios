//
//  UserDefaultBackedValue.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 19/02/2025.
//
// Based off of: https://www.swiftbysundell.com/articles/property-wrappers-in-swift/

import Foundation
import KukaiCoreSwift

private protocol AnyOptional {
	var isNil: Bool { get }
}

extension Optional: AnyOptional {
	var isNil: Bool { self == nil }
}

/**
 A property wrapper that stores and retreives the given value in user defaults, so its automatically persisteted when ever set.
 Primary purpose for this feature was storing node URLs for different networks in user defaults, and URL is not a supported type.
 So the code was extended to examine the generic value and check if its URL or [URL] and switch to strings.
 Couldn't find an easy way to support enums with a base type, currently only using one of them anyway, so just added explicit support for NetworkType,
 will revisit this later if more are needed
 */
@propertyWrapper struct UserDefaultsBacked<Value> {
	var wrappedValue: Value {
		get {
			
			if Value.self == [URL].self, let storage = storage.value(forKey: key) as? [String] {
			   return (storage.compactMap({ URL(string: $0) }) as? Value) ?? defaultValue
			   
			} else if (Value.self == URL.self || Value.self == Optional<URL>.self), let storage = storage.value(forKey: key) as? String, let newVal = URL(string: storage) {
				return (newVal as? Value) ?? defaultValue
				
			} else if Value.self == TezosNodeClientConfig.NetworkType.self, let storage = storage.value(forKey: key) as? String, let newVal = TezosNodeClientConfig.NetworkType(rawValue: storage) {
				return (newVal as? Value) ?? defaultValue
				
			} else {
				let value = storage.value(forKey: key) as? Value
				return value ?? defaultValue
			}
		}
		
		set {
			if let optional = newValue as? AnyOptional, optional.isNil {
				storage.removeObject(forKey: key)
				
			} else if Value.self == [URL].self, let stringArray = (newValue as? [URL])?.map({ $0.absoluteString }) {
				storage.setValue(stringArray, forKey: key)
				
			} else if Value.self == URL.self || Value.self == Optional<URL>.self, let url = newValue as? URL {
				storage.setValue(url.absoluteString, forKey: key)
				
			} else if Value.self == TezosNodeClientConfig.NetworkType.self, let string = (newValue as? KukaiCoreSwift.TezosNodeClientConfig.NetworkType)?.rawValue {
				storage.setValue(string, forKey: key)
				
			} else {
				storage.setValue(newValue, forKey: key)
			}
		}
	}

	private let key: String
	private let defaultValue: Value
	private let storage: UserDefaults

	init(wrappedValue defaultValue: Value, key: String, storage: UserDefaults = .standard) {
		self.defaultValue = defaultValue
		self.key = key
		self.storage = storage
	}
}

extension UserDefaultsBacked where Value: ExpressibleByNilLiteral {
	init(key: String, storage: UserDefaults = .standard) {
		self.init(wrappedValue: nil, key: key, storage: storage)
	}
}
