//
//  UINavigationController+extensions.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 01/03/2022.
//

import Foundation
import UIKit

public extension UINavigationController {
	
	func homeTabBarController() -> HomeTabBarController? {
		guard let htb = self.viewControllers.first(where: { $0 is HomeTabBarController }) as? HomeTabBarController else {
			print("Can't find `HomeTabBarController` in \(self.viewControllers)")
			return nil
		}
		
		return htb
	}
	
	func popToHome() {
		guard let homeTabController = homeTabBarController() else {
			print("Can't find `HomeTabBarController` in \(self.viewControllers)")
			return
		}
		
		self.popToViewController(homeTabController, animated: true)
	}
	
	func popToDetails() {
		if let tokenDetails = self.viewControllers.first(where: { $0 is TokenDetailsViewController }) {
			self.popToViewController(tokenDetails, animated: true)
			
		} else if let collectibleDetails = self.viewControllers.first(where: { $0 is CollectiblesDetailsViewController }) {
			self.popToViewController(collectibleDetails, animated: true)
			
		} else {
			popToHome()
		}
	}
	
	func previousViewController() -> UIViewController? {
		if self.viewControllers.count-2 < 0 {
			return nil
		}
		
		return self.viewControllers[self.viewControllers.count-2]
	}
	
	func isInSideMenuSecurityFlow() -> Bool {
		if let _ = self.viewControllers.first(where: { $0 is SideMenuSecurityViewController }) {
			return true
		}
		
		return false
	}
	
	func popToSecuritySettings() {
		if let vc = self.viewControllers.first(where: { $0 is SideMenuSecurityViewController }) {
			self.popToViewController(vc, animated: true)
		}
	}
}
