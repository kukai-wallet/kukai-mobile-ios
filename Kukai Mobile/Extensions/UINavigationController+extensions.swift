//
//  UINavigationController+extensions.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 01/03/2022.
//

import Foundation
import UIKit

public extension UINavigationController {
	
	func popToHome() {
		guard let homeTabController = self.viewControllers.first(where: { $0 is HomeTabBarController }) else {
			print("Can't find `HomeTabBarController` in \(self.viewControllers)")
			return
		}
		
		self.popToViewController(homeTabController, animated: true)
	}
	
	func previousViewController() -> UIViewController? {
		if self.viewControllers.count-2 < 0 {
			return nil
		}
		
		return self.viewControllers[self.viewControllers.count-2]
	}
}
