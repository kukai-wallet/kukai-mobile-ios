//
//  CKRecord+extensions.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 06/04/2022.
//

import Foundation
import CloudKit

public extension CKRecord {
	
	func stringForKey(_ key: String) -> String? {
		guard let str = self.value(forKey: key) as? String else {
			return nil
		}
		
		return str
	}
	
	func stringArrayForKey(_ key: String) -> [String]? {
		guard let str = self.value(forKey: key) as? [String] else {
			return nil
		}
		
		return str
	}
	
	func doubleStringArrayToDict(key1: String, key2: String) -> [String: String]? {
		guard let str1 = self.value(forKey: key1) as? [String], let str2 = self.value(forKey: key2) as? [String], str1.count == str2.count else {
			return nil
		}
		
		var temp: [String: String] = [:]
		for (index, key) in str1.enumerated() {
			temp[key] = str2[index]
		}
		
		return temp
	}
}
