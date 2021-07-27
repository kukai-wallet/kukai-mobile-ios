//
//  UIStoryboard+extensions.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 27/07/2021.
//

import UIKit

extension UIStoryboard {
	
	static func multitaskingCoverViewController() -> UIViewController {
		return UIStoryboard(name: "Login", bundle: nil).instantiateViewController(withIdentifier: "MultitaskingCoverViewController")
	}
	
	static func loginViewController() -> UIViewController {
		return UIStoryboard(name: "Login", bundle: nil).instantiateViewController(withIdentifier: "LoginViewController")
	}
}
