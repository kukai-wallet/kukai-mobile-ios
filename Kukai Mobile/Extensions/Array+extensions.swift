//
//  Array+extensions.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 28/03/2023.
//

import Foundation

extension Array {
	
	mutating func appendIfPresent(_ element: Element?) {
		if let el = element {
			self.append(el)
		}
	}
}
