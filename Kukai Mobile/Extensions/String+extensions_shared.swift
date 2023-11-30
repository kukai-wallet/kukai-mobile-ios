//
//  String+extensions_shared.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 01/09/2023.
//

import UIKit

extension String {
	
	func truncateTezosAddress() -> String {
		return "\(self.prefix(7))...\(self.suffix(4))"
	}
}
