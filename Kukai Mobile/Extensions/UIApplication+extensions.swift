//
//  UIApplication+extensions.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 23/12/2021.
//

import UIKit

extension UIApplication {
	
	var currentWindow: UIWindow? {
		return UIApplication.shared.connectedScenes
			.filter { $0.activationState == .foregroundActive }
			.first(where: { $0 is UIWindowScene })
			.flatMap({ $0 as? UIWindowScene })?.windows
			.first(where: \.isKeyWindow)
	}
	
	var currentWindowIncludingSuspended: UIWindow? {
		return UIApplication.shared.connectedScenes
			.first(where: { $0 is UIWindowScene })
			.flatMap({ $0 as? UIWindowScene })?.windows
			.first(where: \.isKeyWindow)
	}
}
