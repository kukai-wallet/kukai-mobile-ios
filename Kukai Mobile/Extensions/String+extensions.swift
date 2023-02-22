//
//  String+extensions.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 18/07/2022.
//

import UIKit

extension String {
	
	public func humanReadableStringFromMichelson() -> String {
		if String(self.prefix(6)) == "050100" {
			return processString(fromIndex: 10)
			
		} else if String(self.prefix(8)) == "0x050100" {
			return processString(fromIndex: 14)
		}
		
		let d = (try? Data(hexString: self)) ?? Data()
		let readable = String(data: d, encoding: .isoLatin1)
		
		return readable ?? ""
	}
	
	private func processString(fromIndex: Int) -> String {
		let index = self.index(self.startIndex, offsetBy: fromIndex)
		let subString = String(self.suffix(from: index))
		
		let d = (try? Data(hexString: subString)) ?? Data()
		let readable = String(data: d, encoding: .isoLatin1)
		
		return readable ?? ""
	}
	
	func widthOfString(usingFont font: UIFont) -> CGFloat {
		let fontAttributes = [NSAttributedString.Key.font: font]
		let size = self.size(withAttributes: fontAttributes)
		return size.width
	}
	
	func truncateTezosAddress() -> String {
		return "\(self.prefix(6))...\(self.suffix(4))"
	}
	
	func deletingPrefix(_ prefix: String) -> String {
		guard self.hasPrefix(prefix) else { return self }
		return String(self.dropFirst(prefix.count))
	}
}
