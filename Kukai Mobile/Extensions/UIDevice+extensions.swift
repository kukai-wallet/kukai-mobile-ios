//
//  UIDevice+extensions.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 12/09/2023.
//

import UIKit

extension UIDevice {
	
	var modelName: String {
		var systemInfo = utsname()
		uname(&systemInfo)
		let machineMirror = Mirror(reflecting: systemInfo.machine)
		let identifier = machineMirror.children.reduce("") { identifier, element in
			guard let value = element.value as? Int8, value != 0 else { return identifier }
			return identifier + String(UnicodeScalar(UInt8(value)))
		}
		return identifier
	}
}
