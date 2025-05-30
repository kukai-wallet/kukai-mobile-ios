//
//  String+extensions.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 18/07/2022.
//

import UIKit

extension String {
	
	var firstUppercased: String {
		return prefix(1).uppercased() + dropFirst()
	}
	
	/*
	 05 = micheline expression
	 01 = string
	 00000042 = number of characters (66 in this example)
	 */
	public func humanReadableStringFromMichelson() -> String {
		if String(self.prefix(4)) == "0501" {
			return processString(fromIndex: 12)
			
		} else if String(self.prefix(6)) == "0x0501" {
			return processString(fromIndex: 14)
		}
		
		let d = Data(hexString: self) ?? Data()
		let readable = String(data: d, encoding: .isoLatin1)
		
		return readable ?? ""
	}
	
	public func isMichelsonEncodedString() -> Bool {
		if String(self.prefix(2)) == "05" || String(self.prefix(4)) == "0x05"  {
			return true
		}
		
		return false
	}
	
	private func processString(fromIndex: Int) -> String {
		let index = self.index(self.startIndex, offsetBy: fromIndex)
		let subString = String(self.suffix(from: index))
		
		let d = Data(hexString: subString) ?? Data()
		let readable = String(data: d, encoding: .isoLatin1)
		
		return readable ?? ""
	}
	
	func widthOfString(usingFont font: UIFont) -> CGFloat {
		let fontAttributes = [NSAttributedString.Key.font: font]
		let size = self.size(withAttributes: fontAttributes)
		return size.width
	}
	
	func deletingPrefix(_ prefix: String) -> String {
		guard self.hasPrefix(prefix) else { return self }
		return String(self.dropFirst(prefix.count))
	}
	
	func versionCompare(_ otherVersion: String) -> ComparisonResult {
		return self.compare(otherVersion, options: .numeric)
	}
	
	/**
	 - Check not all the same number
	 - Check no more than 3 digits in a row
	 - Used 3 or more unique digits
	 */
	func passcodeComplexitySufficient() -> Bool {
		let digits = self.map({ Int(String($0)) ?? 0 })
		
		let uniqueDigitCount = Set(digits).count
		var hasTooManySequentialDigits = false
		
		for (index, digit) in digits.enumerated() {
			if index <= 1 {
				continue
			}
			
			if digit-1 == digits[index-1] && digit-2 == digits[index-2] {
				hasTooManySequentialDigits = true
				break
			}
		}
		
		return (uniqueDigitCount > 3) && !hasTooManySequentialDigits
	}
	
	
	
	// MARK: - Localization
	
	static func localized(_ key: String) -> String {
		return NSLocalizedString(key, comment: "")
	}
	
	static func localized(_ key: String, withArguments: CVarArg...) -> String {
		return String(format: String.localized(key), withArguments)
	}
	
	func localized() -> String {
		return NSLocalizedString(self, comment: "")
	}
}
